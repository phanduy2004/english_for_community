import { z } from 'zod';
import mongoose from 'mongoose';
import Cue from '../models/Cue.js';
import Listening from '../models/Listening.js';
import DictationAttempt from '../models/DictationAttempt.js';
import { Enrollment } from '../models/index.js';

// ===== Config (giữ WER cho thống kê, KHÔNG dùng để pass) =====
const WER_PASS_THRESHOLD = Number(process.env.WER_PASS_THRESHOLD ?? 0.25);

// ===== Text helpers =====
const normalize = (s = '') =>
  String(s)
  .toLowerCase()
  .normalize('NFKD')
  .replace(/\p{Diacritic}/gu, '')       // bỏ dấu tiếng Việt
  .replace(/[’'`]/g, "'")               // chuẩn hóa dấu nháy
  .replace(/[^a-z0-9'\s]/g, ' ')        // bỏ dấu câu/ ký tự lạ (, . ! ? …)
  .replace(/\s+/g, ' ')
  .trim();

const tokenize = (s = '') => (s ? s.split(' ').filter(Boolean) : []);

// Hoàn thành câu = hai chuỗi đã normalize khớp từng từ
function isSentenceComplete(refNorm, hypNorm) {
  const refT = tokenize(refNorm);
  const hypT = tokenize(hypNorm);
  if (refT.length === 0) return false;
  if (hypT.length !== refT.length) return false;
  for (let i = 0; i < refT.length; i++) {
    if (refT[i] !== hypT[i]) return false;
  }
  return true;
}

// Gợi ý dạng “đến từ sai + *****” (không dính input người dùng)
function buildMaskedHint(refRaw, refNorm, hypNorm) {
  const refTokens = tokenize(refNorm);
  const hypTokens = tokenize(hypNorm);

  let firstErr = -1;
  for (let i = 0; i < refTokens.length; i++) {
    const rt = refTokens[i];
    const ht = hypTokens[i] ?? '';
    const wrong = rt !== ht && !rt.startsWith(ht);
    if (wrong) { firstErr = i; break; }
  }
  if (firstErr === -1 && hypTokens.length < refTokens.length) {
    firstErr = hypTokens.length; // đang gõ dở
  }
  if (firstErr < 0) {
    // chưa sai → dẫn đến ngay sau số từ đã gõ (nếu còn)
    firstErr = Math.min(hypTokens.length, Math.max(0, refTokens.length - 1));
  }

  const rawTokens = refRaw.split(/\s+/);
  const upto = Math.min(firstErr + 1, rawTokens.length);
  const shown = rawTokens.slice(0, upto).join(' ');
  const maskedSuggestion = upto < rawTokens.length ? `${shown} *****` : shown;

  return { firstWrongIndex: Math.max(0, firstErr), maskedSuggestion: maskedSuggestion.trim() };
}

// WER để thống kê (không quyết định pass/fail)
const wordErrorRate = (refStr, hypStr) => {
  const ref = refStr ? refStr.split(' ').filter(Boolean) : [];
  const hyp = hypStr ? hypStr.split(' ').filter(Boolean) : [];
  const m = ref.length, n = hyp.length;
  if (m === 0 && n === 0) return { wer: 0, correctWords: 0, totalWords: 0 };
  if (m === 0) return { wer: n > 0 ? 1 : 0, correctWords: 0, totalWords: 0 };
  const dp = Array.from({ length: m + 1 }, (_, i) => {
    const row = Array(n + 1).fill(0);
    row[0] = i;
    return row;
  });
  for (let j = 0; j <= n; j++) dp[0][j] = j;
  for (let i = 1; i <= m; i++) {
    const ri = ref[i - 1];
    for (let j = 1; j <= n; j++) {
      const cost = ri === hyp[j - 1] ? 0 : 1;
      dp[i][j] = Math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost);
    }
  }
  const dist = dp[m][n];
  return { wer: dist / m, correctWords: Math.max(0, m - dist), totalWords: m };
};

// ===== Validation =====
const SubmitSchema = z.object({
  listeningId: z.string().min(1, 'listeningId is required'),
  cueIdx: z.number().int().nonnegative(),
  userText: z.string().default('').transform(s => s.slice(0, 5000)),
  playedMs: z.number().int().nonnegative().max(24 * 60 * 60 * 1000).optional(),
});

// ===== Controllers =====
export const submitDictation = async (req, res) => {
  try {
    const userId = req.user?._id || null;

    const parsed = SubmitSchema.safeParse({
      listeningId: String(req.body.listeningId ?? ''),
      cueIdx: Number(req.body.cueIdx),
      userText: String(req.body.userText ?? ''),
      playedMs: req.body.playedMs !== undefined && Number.isFinite(Number(req.body.playedMs))
        ? Number(req.body.playedMs)
        : undefined,
    });
    if (!parsed.success) {
      return res.status(400).json({ message: parsed.error.message });
    }

    const { listeningId, cueIdx, userText, playedMs } = parsed.data;

    const listening = await Listening.findById(listeningId, { _id: 1 }).lean();
    if (!listening) return res.status(404).json({ message: 'Listening not found' });

    const cue = await Cue.findOne(
      { listeningId, idx: cueIdx },
      { _id: 1, text: 1, textNorm: 1 }
    ).lean();
    if (!cue) return res.status(404).json({ message: 'Cue not found' });

    // ===== Scoring =====
    const refRaw = cue.text || '';
    const ref = cue.textNorm || normalize(refRaw);
    const hyp = normalize(userText);

    const { wer, correctWords, totalWords } = wordErrorRate(ref, hyp);
    const passed = isSentenceComplete(ref, hyp); // ✅ chỉ pass khi trùng khít toàn câu

    const hint = buildMaskedHint(refRaw, ref, hyp); // chỉ để hiển thị sau submit

    // ===== Save attempt =====
    const now = new Date();
    let attempt;

    if (userId) {
      attempt = await DictationAttempt.findOneAndUpdate(
        { userId, listeningId, cueIdx },
        {
          $set: {
            userId, listeningId, cueIdx,
            userText, userTextNorm: hyp,
            score: { wer, correctWords, totalWords, thresholdWer: WER_PASS_THRESHOLD, passed },
            playedMs, submittedAt: now,
          },
          $setOnInsert: { firstSubmittedAt: now },
        },
        { upsert: true, new: true }
      );
    } else {
      attempt = await DictationAttempt.create({
        userId: null, listeningId, cueIdx,
        userText, userTextNorm: hyp,
        score: { wer, correctWords, totalWords, thresholdWer: WER_PASS_THRESHOLD, passed },
        playedMs, submittedAt: now, firstSubmittedAt: now,
      });
    }

    // ===== Update enrollment only when passed =====
    if (userId && passed) {
      const enr = await Enrollment.findOneAndUpdate(
        { userId, listeningId },
        {
          $setOnInsert: { progress: 0, isCompleted: false, completedCueIds: [], createdAt: now },
          $set: { lastAccessedAt: now },
        },
        { upsert: true, new: true }
      );

      await Enrollment.updateOne({ _id: enr._id }, { $addToSet: { completedCueIds: cue._id } });

      const [totals, enr2] = await Promise.all([
        Cue.countDocuments({ listeningId }),
        Enrollment.findById(enr._id, { completedCueIds: 1 }).lean(),
      ]);
      const done = Array.isArray(enr2?.completedCueIds) ? enr2.completedCueIds.length : 0;
      const progress = totals > 0 ? Math.min(1, done / totals) : 0;
      await Enrollment.updateOne({ _id: enr._id }, { $set: { progress, isCompleted: progress >= 1 } });
    }

    return res.status(200).json({
      attemptId: attempt._id,
      passed,
      message: passed ? 'true' : 'false',
      score: { wer, correctWords, totalWords, thresholdWer: WER_PASS_THRESHOLD },
      refText: refRaw,
      refTextNorm: ref,
      userTextNorm: hyp,
      hint, // { firstWrongIndex, maskedSuggestion }
    });
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const getDictationAttempts = async (req, res) => {
  try {
    const userId = req.user?._id || null;
    const listeningId = String(req.query.listeningId || '');
    const latest = String(req.query.latest || 'true') === 'true';

    if (!listeningId) return res.status(400).json({ message: 'listeningId is required' });
    if (!userId) return res.status(200).json({ attempts: [] });

    const matchStage = {
      listeningId: new mongoose.Types.ObjectId(listeningId),
      userId: new mongoose.Types.ObjectId(userId),
    };

    let docs;
    if (latest) {
      docs = await DictationAttempt.aggregate([
        { $match: matchStage },
        { $sort: { submittedAt: -1, _id: -1 } },
        { $group: { _id: '$cueIdx', doc: { $first: '$$ROOT' } } },
        { $replaceRoot: { newRoot: '$doc' } },
        { $sort: { cueIdx: 1 } },
        {
          $project: {
            _id: 1, cueIdx: 1, userText: 1, submittedAt: 1,
            'score.wer': 1, 'score.thresholdWer': 1, 'score.passed': 1,
          },
        },
      ]);
    } else {
      docs = await DictationAttempt.find(matchStage, {
        cueIdx: 1, userText: 1, submittedAt: 1,
        'score.wer': 1, 'score.thresholdWer': 1, 'score.passed': 1,
      })
      .sort({ submittedAt: -1, _id: -1 })
      .lean();
    }

    return res.status(200).json(docs);
  } catch (e) {
    return res.status(500).json({ message: 'Server error', error: e.message });
  }
};
