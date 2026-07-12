import { test } from 'node:test';
import assert from 'node:assert/strict';
import { computeRiskLevel, mergeIntegrity } from './examIntegrityService.js';

// ── B1: boundary công thức riskLevel (spec §5) ──────────────────────────────

test('computeRiskLevel — tab switch boundaries', () => {
  assert.equal(computeRiskLevel({ tabSwitchCount: 0 }), 'low');
  assert.equal(computeRiskLevel({ tabSwitchCount: 1 }), 'low');
  assert.equal(computeRiskLevel({ tabSwitchCount: 2 }), 'medium');
  assert.equal(computeRiskLevel({ tabSwitchCount: 4 }), 'medium');
  assert.equal(computeRiskLevel({ tabSwitchCount: 5 }), 'high');
  assert.equal(computeRiskLevel({ tabSwitchCount: 9 }), 'high');
});

test('computeRiskLevel — focus loss boundaries', () => {
  assert.equal(computeRiskLevel({ focusLossSeconds: 44 }), 'low');
  assert.equal(computeRiskLevel({ focusLossSeconds: 45 }), 'medium');
  assert.equal(computeRiskLevel({ focusLossSeconds: 119 }), 'medium');
  assert.equal(computeRiskLevel({ focusLossSeconds: 120 }), 'high');
});

test('computeRiskLevel — copy-paste boundaries', () => {
  assert.equal(computeRiskLevel({ copyPasteAttempts: 0 }), 'low');
  assert.equal(computeRiskLevel({ copyPasteAttempts: 1 }), 'medium');
  assert.equal(computeRiskLevel({ copyPasteAttempts: 2 }), 'medium');
  assert.equal(computeRiskLevel({ copyPasteAttempts: 3 }), 'high');
});

test('computeRiskLevel — fullscreenExited alone => medium (A2 spec fix)', () => {
  assert.equal(
    computeRiskLevel({ tabSwitchCount: 0, focusLossSeconds: 0, copyPasteAttempts: 0, fullscreenExited: true }),
    'medium',
  );
  // fullscreen không kéo lên high nếu counter chưa chạm ngưỡng high
  assert.equal(computeRiskLevel({ tabSwitchCount: 1, fullscreenExited: true }), 'medium');
  // nhưng vẫn high nếu 1 counter chạm ngưỡng high
  assert.equal(computeRiskLevel({ tabSwitchCount: 5, fullscreenExited: true }), 'high');
});

test('computeRiskLevel — empty/undefined => low', () => {
  assert.equal(computeRiskLevel(), 'low');
  assert.equal(computeRiskLevel({}), 'low');
});

// ── B2: mergeIntegrity monotonic + latch + delta accumulation (A1) ──────────

test('mergeIntegrity — delta accumulation', () => {
  let s = mergeIntegrity({}, { tabSwitchDelta: 1 });
  assert.equal(s.tabSwitchCount, 1);
  s = mergeIntegrity(s, { tabSwitchDelta: 1 });
  assert.equal(s.tabSwitchCount, 2);
  s = mergeIntegrity(s, { focusLossDelta: 30 });
  assert.equal(s.focusLossSeconds, 30);
  s = mergeIntegrity(s, { focusLossDelta: 20 });
  assert.equal(s.focusLossSeconds, 50);
  s = mergeIntegrity(s, { copyPasteDelta: 1 });
  assert.equal(s.copyPasteAttempts, 1);
  // tab=2, focus=50, copy=1 => medium
  assert.equal(s.riskLevel, 'medium');
});

test('mergeIntegrity — negative deltas are clamped to >= 0', () => {
  const s = mergeIntegrity({ tabSwitchCount: 3 }, { tabSwitchDelta: -5 });
  assert.equal(s.tabSwitchCount, 3); // +max(0,-5)=+0
});

test('mergeIntegrity — absolute value cannot LOWER a counter (A1 anti-reset)', () => {
  const prev = { tabSwitchCount: 3, focusLossSeconds: 100, copyPasteAttempts: 2 };
  const s = mergeIntegrity(prev, { tabSwitchCount: 0, focusLossSeconds: 0, copyPasteAttempts: 0 });
  assert.equal(s.tabSwitchCount, 3);
  assert.equal(s.focusLossSeconds, 100);
  assert.equal(s.copyPasteAttempts, 2);
});

test('mergeIntegrity — absolute value CAN raise a counter (monotonic max)', () => {
  const s = mergeIntegrity({ tabSwitchCount: 3 }, { tabSwitchCount: 7 });
  assert.equal(s.tabSwitchCount, 7);
});

test('mergeIntegrity — fullscreenExited latches true and cannot be cleared', () => {
  let s = mergeIntegrity({}, { fullscreenExited: true });
  assert.equal(s.fullscreenExited, true);
  assert.equal(s.riskLevel, 'medium'); // A2
  s = mergeIntegrity(s, { fullscreenExited: false });
  assert.equal(s.fullscreenExited, true); // latched
  s = mergeIntegrity(s, { tabSwitchDelta: 1 });
  assert.equal(s.fullscreenExited, true); // preserved across unrelated patches
});

test('mergeIntegrity — reaching high threshold sets high and stays high', () => {
  let s = mergeIntegrity({}, { tabSwitchDelta: 5 });
  assert.equal(s.riskLevel, 'high');
  // cố gắng reset về 0 không hạ được
  s = mergeIntegrity(s, { tabSwitchCount: 0 });
  assert.equal(s.riskLevel, 'high');
  assert.equal(s.tabSwitchCount, 5);
});

test('mergeIntegrity — lastEventAt is set when not provided', () => {
  const s = mergeIntegrity({}, { tabSwitchDelta: 1 });
  assert.ok(typeof s.lastEventAt === 'string' && s.lastEventAt.length > 0);
});
