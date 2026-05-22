/** Shared score extraction for gradebook + exports (aligned with Flutter grading hub). */

export function isIntegratedScores(scores) {
  if (!scores || typeof scores !== 'object') return false;
  const fmt = scores.examFormat;
  return (
    fmt === 'integrated_four_skills' ||
    fmt === 'skills_exam' ||
    scores.finalScore != null ||
    scores.finalMax != null
  );
}

export function scoreOfAttempt(att) {
  if (!att) return null;
  const scores = att.scores || {};

  if (isIntegratedScores(scores)) {
    const awarded = scores.finalScore;
    const max = Number(scores.finalMax ?? 10);
    if (awarded == null) return { awarded: null, max, scale: 'ten' };
    return { awarded: Number(awarded), max, scale: 'ten' };
  }

  let awarded = scores.totalAwarded;
  let max = scores.totalMax;
  if ((awarded == null && max == null) || (Number(max ?? 0) <= 0 && scores.finalScore != null)) {
    if (scores.finalScore != null) {
      return {
        awarded: Number(scores.finalScore),
        max: Number(scores.finalMax ?? 10),
        scale: 'ten',
      };
    }
    return null;
  }
  return { awarded: Number(awarded ?? 0), max: Number(max ?? 0), scale: 'points' };
}

export function percentFromScore(score) {
  if (!score || score.awarded == null || score.max <= 0) return null;
  return Math.round((score.awarded / score.max) * 1000) / 10;
}
