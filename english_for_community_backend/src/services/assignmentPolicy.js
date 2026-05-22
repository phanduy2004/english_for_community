/**
 * Per-assignment overrides (config) with fallback to exam.settings.
 */

export function resolveShowResultsPolicy(assignment, exam) {
  const fromAssignment = assignment?.config?.showResultsPolicy;
  if (fromAssignment === 'after_submit' || fromAssignment === 'after_release' || fromAssignment === 'never') {
    return fromAssignment;
  }
  const fromExam = exam?.settings?.showResultsPolicy;
  if (fromExam === 'after_submit' || fromExam === 'after_release' || fromExam === 'never') {
    return fromExam;
  }
  return 'after_release';
}

/** @returns {{ kind: 'single' } | { kind: 'unlimited' } | { kind: 'limited', max: number }} */
export function resolveAttemptPolicy(assignment, exam) {
  const cfg = assignment?.config || {};
  const policy = cfg.attemptPolicy;
  if (policy === 'unlimited') return { kind: 'unlimited' };
  if (policy === 'limited') {
    const max = Number(cfg.maxAttempts);
    if (Number.isFinite(max) && max > 1) return { kind: 'limited', max: Math.min(99, Math.floor(max)) };
  }
  if (policy === 'single') return { kind: 'single' };
  if (exam?.settings?.allowMultipleSubmissions === true) return { kind: 'unlimited' };
  return { kind: 'single' };
}

export function allowsAnotherAttemptAfterSubmit(attemptPolicy) {
  return attemptPolicy.kind === 'unlimited' || attemptPolicy.kind === 'limited';
}
