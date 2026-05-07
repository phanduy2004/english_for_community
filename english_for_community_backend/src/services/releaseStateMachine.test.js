import test from 'node:test';
import assert from 'node:assert/strict';
import { canTransition, assertTransition, ReleaseStatus } from './releaseStateMachine.js';

test('allows valid transitions in release lifecycle', () => {
  assert.equal(canTransition(ReleaseStatus.pendingApproval, ReleaseStatus.approved), true);
  assert.equal(canTransition(ReleaseStatus.approved, ReleaseStatus.scheduled), true);
  assert.equal(canTransition(ReleaseStatus.scheduled, ReleaseStatus.published), true);
  assert.equal(canTransition(ReleaseStatus.published, ReleaseStatus.archived), true);
});

test('rejects invalid transitions in release lifecycle', () => {
  assert.equal(canTransition(ReleaseStatus.pendingApproval, ReleaseStatus.published), false);
  assert.equal(canTransition(ReleaseStatus.rejected, ReleaseStatus.published), false);
  assert.equal(canTransition(ReleaseStatus.archived, ReleaseStatus.published), false);
});

test('assertTransition throws on invalid transition', () => {
  assert.throws(
    () => assertTransition(ReleaseStatus.pendingApproval, ReleaseStatus.published),
    /Invalid transition/,
  );
});
