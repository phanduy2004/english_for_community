/**
 * Lightweight E2E-style test for exam realtime progress event wiring.
 * Run: node --test src/tests/examRealtime.e2e.test.js
 */
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  computeAttemptProgress,
  computeCurrentFocus,
  buildAttemptLiveProgressRow,
  buildLiveScreenPayload,
  computeGrammarAnswers,
  computeSectionStatus,
  resolveLiveGrammarNavIndex,
} from '../services/examAttemptProgress.js';
import { computeAdaptiveState, isAdaptiveExamSnapshot } from '../services/examAdaptiveService.js';
import {
  listeningCueTextIsCorrect,
  readingChoiceIsCorrect,
} from '../services/examLiveSkillStrips.js';

describe('exam realtime helpers', () => {
  it('computeAttemptProgress counts answered MCQ', () => {
    const attempt = {
      examSnapshot: {
        sections: [
          {
            items: [
              { itemId: 'q1', kind: 'mcq_single', points: 1 },
              { itemId: 'q2', kind: 'mcq_single', points: 1 },
            ],
          },
        ],
      },
      answers: {
        q1: { selectedIndexes: [0] },
      },
    };
    const p = computeAttemptProgress(attempt);
    assert.equal(p.answeredCount, 1);
    assert.equal(p.totalItems, 2);
    assert.equal(p.progressPercent, 50);
  });

  it('adaptive exam snapshot is detected', () => {
    assert.equal(isAdaptiveExamSnapshot({ settings: { adaptiveEnabled: true } }), true);
    assert.equal(isAdaptiveExamSnapshot({ settings: {} }), false);
  });

  it('computeCurrentFocus returns first unanswered item', () => {
    const attempt = {
      examSnapshot: {
        sections: [
          {
            items: [
              { itemId: 'q1', kind: 'mcq_single', prompt: 'First question' },
              { itemId: 'q2', kind: 'mcq_single', prompt: 'Second question' },
            ],
          },
        ],
      },
      answers: {
        q1: { selectedIndexes: [0] },
      },
    };
    const focus = computeCurrentFocus(attempt);
    assert.equal(focus.currentItemId, 'q2');
    assert.ok(focus.currentItemLabel.includes('Second'));
  });

  it('buildAttemptLiveProgressRow includes integrity fields', () => {
    const row = buildAttemptLiveProgressRow(
      {
        _id: 'a1',
        assignmentId: 'as1',
        sessionId: 's1',
        userId: 'u1',
        status: 'in_progress',
        examSnapshot: { sections: [{ items: [{ itemId: 'q1', kind: 'mcq_single' }] }] },
        answers: {},
        integrity: { riskLevel: 'high', tabSwitchCount: 6 },
        updatedAt: new Date('2026-01-01T00:00:00Z'),
      },
      { _id: 'u1', fullName: 'Test Student', email: 't@example.com' }
    );
    assert.equal(row.fullName, 'Test Student');
    assert.equal(row.integrityRiskLevel, 'high');
    assert.equal(row.tabSwitchCount, 6);
  });

  it('readingChoiceIsCorrect compares chosen index to answer key', () => {
    const q = { correctAnswerIndex: 2 };
    assert.equal(readingChoiceIsCorrect(q, 2), true);
    assert.equal(readingChoiceIsCorrect(q, 1), false);
    assert.equal(readingChoiceIsCorrect(q, null), null);
  });

  it('listeningCueTextIsCorrect normalizes dictation text', () => {
    assert.equal(listeningCueTextIsCorrect('Hello, world.', 'hello world'), true);
    assert.equal(listeningCueTextIsCorrect('Hello', 'Hi'), false);
    assert.equal(listeningCueTextIsCorrect('Hi', ''), null);
  });

  it('computeGrammarAnswers marks correct MCQ', () => {
    const attempt = {
      examSnapshot: {
        settings: {
          grammarItems: [
            { itemId: 'g1', kind: 'mcq_single', options: ['A', 'B', 'C'], correctOptionIndexes: [1] },
          ],
        },
        sections: [],
      },
      answers: { g1: { selectedIndexes: [1] } },
    };
    const rows = computeGrammarAnswers(attempt);
    assert.equal(rows.length, 1);
    assert.equal(rows[0].isCorrect, true);
    assert.deepEqual(rows[0].selectedIndexes, [1]);
  });

  it('computeSectionStatus reflects completed flag', () => {
    const attempt = {
      examSnapshot: {
        sections: [
          { sectionId: 's1', skill: 'writing', order: 0 },
          { sectionId: 's2', skill: 'reading', order: 1 },
        ],
        settings: {},
      },
      answers: { s1: { completed: true }, s2: {} },
    };
    const rows = computeSectionStatus(attempt);
    assert.equal(rows[0].completed, true);
    assert.equal(rows[1].completed, false);
  });

  it('resolveLiveGrammarNavIndex uses currentGrammarItemId when nav index stale', () => {
    const attempt = {
      _id: 'attempt-live-grammar',
      examSnapshot: {
        settings: {
          grammarItems: [
            { itemId: 'g1', kind: 'mcq_single' },
            { itemId: 'g2', kind: 'mcq_single' },
          ],
        },
        sections: [],
      },
      answers: { g1: { selectedIndexes: [0] } },
      meta: { liveView: { grammarNavIndex: 0, currentGrammarItemId: 'g2' } },
    };
    assert.equal(resolveLiveGrammarNavIndex(attempt, attempt.meta.liveView), 1);
    const screen = buildLiveScreenPayload(attempt);
    assert.equal(screen.liveView.grammarNavIndex, 1);
  });

  it('computeAdaptiveState adjusts level from accuracy', () => {
    const attempt = {
      meta: {},
      answers: {
        q1: { selectedIndexes: [0] },
        q2: { selectedIndexes: [0] },
      },
      scores: {
        items: {
          q1: { awardedPoints: 1 },
          q2: { awardedPoints: 1 },
        },
      },
    };
    const items = [
      { itemId: 'q1', kind: 'mcq_single', points: 1 },
      { itemId: 'q2', kind: 'mcq_single', points: 1 },
    ];
    const meta = computeAdaptiveState(attempt, items);
    assert.ok(meta.adaptive);
    assert.equal(meta.adaptive.level, 'hard');
  });
});
