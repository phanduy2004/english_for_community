import { z } from 'zod';
import Cue from '../models/Cue.js';
import Listening from '../models/Listening.js';
import DictationAttempt from '../models/DictationAttempt.js';

// === Scoring helpers ===
const normalize = (s = '') => String(s)
  .toLowerCase()
  .replace(/[’'`]/g, "'")
  .replace(/[^a-z0-9'\s]/g, ' ')
  .replace(/\s+/g, ' ')
  .trim();

const wordErrorRate = (refStr, hypStr) => {
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
        dp[i - 1][j] + 1,
        dp[i][j - 1] + 1,
        dp[i - 1][j - 1] + cost
      );
    }
  }
  const dist = dp[m][n];
  return {
    wer: m ? dist / m : 0,
    correctWords: Math.max(0, m - dist),
    totalWords: m,
  };
};

const charErrorRate = (refStr, hypStr) => {
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
};

// === Validation ===
const SubmitSchema = z.object({
  listeningId: z.string().min(1),
  cueIdx: z.number().int().nonnegative(),
  userText: z.string().default(''),
  playedMs: z.number().int().nonnegative().optional(),
});

// POST /api/dictation/submit
export const submitDictation = async (req, res) => {
  try {
    // auth middleware should set req.user._id when authenticated
    const userId = req.user?._id || null;

    const parsed = SubmitSchema.safeParse({
      listeningId: req.body.listeningId,
      cueIdx: Number(req.body.cueIdx),
      userText: String(req.body.userText ?? ''),
      playedMs: req.body.playedMs !== undefined ? Number(req.body.playedMs) : undefined,
    });
    if (!parsed.success) {
      return res.status(400).json({ message: parsed.error.message });
    }
    const { listeningId, cueIdx, userText, playedMs } = parsed.data;

    // Ensure listening exists
    const listening = await Listening.findById(listeningId, { _id: 1 }).lean();
    if (!listening) return res.status(404).json({ message: 'Listening not found' });

    // Find cue
    const cue = await Cue.findOne({ listeningId, idx: cueIdx }).lean();
    if (!cue) return res.status(404).json({ message: 'Cue not found' });

    // Score
    const ref = cue.textNorm || normalize(cue.text || '');
    const hyp = normalize(userText);

    const { wer, correctWords, totalWords } = wordErrorRate(ref, hyp);
    const { cer } = charErrorRate(ref, hyp);

    const attempt = await DictationAttempt.create({
      userId,
      listeningId,
      cueIdx,
      userText,
      userTextNorm: hyp,
      score: { wer, cer, correctWords, totalWords },
      playedMs,
      submittedAt: new Date(),
    });

    return res.status(200).json({
      attemptId: attempt._id,
      score: { wer, cer, correctWords, totalWords },
      // ref: cue.text, // reveal answer only when desired
    });
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};