export function normalize(s = '') {
  return String(s)
    .toLowerCase()
    .replace(/[’'`]/g, "'")
    .replace(/[^a-z0-9'\s]/g, ' ')
    .replace(/\b(i)\s+am\b/g, "i'm") // ví dụ tuỳ chọn
    .replace(/\s+/g, ' ')
    .trim();
}

export function wordErrorRate(refStr, hypStr) {
  const ref = refStr.split(' ').filter(Boolean);
  const hyp = hypStr.split(' ').filter(Boolean);
  const m = ref.length, n = hyp.length;
  const dp = Array.from({ length: m + 1 }, (_, i) => {
    const row = Array(n + 1).fill(0);
    row[0] = i;
    return row;
  });
  for (let j = 0; j <= n; j++) dp[0][j] = j;

  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      const cost = ref[i - 1] === hyp[j - 1] ? 0 : 1;
      dp[i][j] = Math.min(
        dp[i - 1][j] + 1,      // deletion
        dp[i][j - 1] + 1,      // insertion
        dp[i - 1][j - 1] + cost // substitution
      );
    }
  }
  const dist = dp[m][n];
  return {
    wer: m ? dist / m : 0,
    correctWords: Math.max(0, m - dist),
    totalWords: m,
  };
}

export function charErrorRate(refStr, hypStr) {
  const ref = refStr.split('');
  const hyp = hypStr.split('');
  const m = ref.length, n = hyp.length;
  const dp = Array.from({ length: m + 1 }, (_, i) => {
    const row = Array(n + 1).fill(0);
    row[0] = i;
    return row;
  });
  for (let j = 0; j <= n; j++) dp[0][j] = j;

  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      const cost = ref[i - 1] === hyp[j - 1] ? 0 : 1;
      dp[i][j] = Math.min(
        dp[i - 1][j] + 1,
        dp[i][j - 1] + 1,
        dp[i - 1][j - 1] + cost
      );
    }
  }
  const dist = dp[m][n];
  return { cer: m ? dist / m : 0 };
}
