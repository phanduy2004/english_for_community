import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { computeFinal, patchIntegratedSkillScores } from './examIntegratedScoring.js';

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

  it('skips no_content skills', () => {
    const skillScores = {
      a: { skill: 'listening', score: 10, status: 'finalized' },
      b: { skill: 'speaking', score: null, status: 'no_content' },
    };
    const r = computeFinal(skillScores, null);
    assert.equal(r.finalScore, 10);
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
