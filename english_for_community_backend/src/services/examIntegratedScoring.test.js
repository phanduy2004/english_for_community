import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  applyListeningScoreMerge,
  computeFinal,
  LISTENING_MERGED_KEY,
  patchIntegratedSkillScores,
} from './examIntegratedScoring.js';

describe('computeFinal', () => {
  it('averages finalized skill scores and grammar', () => {
    const skillScores = {
      a: { skill: 'listening', score: 8, status: 'finalized' },
      b: { skill: 'reading', score: 6, status: 'finalized' },
      c: { skill: 'writing', score: null, status: 'pending_ai' },
    };
    const grammarScore = { score: 10, max: 10, status: 'finalized' };
    const r = computeFinal(skillScores, grammarScore);
    assert.equal(r.finalScore, 8);
    assert.equal(r.finalStatus, 'partial');
  });

  it('counts finalized zero scores toward average', () => {
    const skillScores = {
      a: { skill: 'listening', score: 0, status: 'finalized', rawCorrect: 0, rawTotal: 12 },
      b: { skill: 'reading', score: 6, status: 'finalized' },
    };
    const r = computeFinal(skillScores, null);
    assert.equal(r.finalScore, 3);
    assert.equal(r.finalStatus, 'finalized');
  });

  it('still skips no_content skills without scorable items', () => {
    const skillScores = {
      a: { skill: 'listening', score: 10, status: 'finalized' },
      b: { skill: 'speaking', score: null, status: 'no_content' },
    };
    const r = computeFinal(skillScores, null);
    assert.equal(r.finalScore, 10);
    assert.equal(r.finalStatus, 'finalized');
  });

  it('merges dictation + comprehension into one listening score for final average', () => {
    const skillScores = {
      dict: {
        skill: 'listening',
        score: 5,
        rawCorrect: 6,
        rawTotal: 12,
        status: 'finalized',
      },
      comp: {
        skill: 'listening',
        score: 8,
        rawCorrect: 4,
        rawTotal: 5,
        status: 'finalized',
      },
      read: { skill: 'reading', score: 6, status: 'finalized' },
    };
    const sections = [
      { sectionId: 'dict', skill: 'listening', sectionConfig: { listeningType: 'dictation' } },
      { sectionId: 'comp', skill: 'listening', sectionConfig: { listeningType: 'comprehension' } },
    ];
    applyListeningScoreMerge(skillScores, sections);
    assert.equal(skillScores.dict.includeInFinal, false);
    assert.equal(skillScores.comp.includeInFinal, false);
    assert.ok(skillScores[LISTENING_MERGED_KEY]);
    assert.equal(skillScores[LISTENING_MERGED_KEY].rawCorrect, 10);
    assert.equal(skillScores[LISTENING_MERGED_KEY].rawTotal, 17);
    const r = computeFinal(skillScores, null);
    assert.equal(skillScores[LISTENING_MERGED_KEY].score, 5.9);
    assert.equal(r.finalScore, 6);
    assert.equal(r.finalStatus, 'finalized');
  });
});

describe('patchIntegratedSkillScores', () => {
  it('updates speaking score and recalculates average', () => {
    const current = {
      examFormat: 'skills_exam',
      skillScores: {
        L: { skill: 'listening', score: 8, max: 10, status: 'finalized' },
        W: { skill: 'writing', score: null, max: 10, status: 'pending_ai' },
      },
      grammarScore: null,
      finalScore: 8,
      finalMax: 10,
      finalStatus: 'partial',
    };
    const updated = patchIntegratedSkillScores(current, {
      W: { score: 9, note: 'Good' },
    });
    assert.equal(updated.skillScores.W.score, 9);
    assert.equal(updated.finalScore, 8.5);
    assert.equal(updated.finalStatus, 'finalized');
  });
});
