import rateLimit from 'express-rate-limit';

export const examStandardLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 120,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Too many requests, slow down.' },
});

export const examStrictLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 40,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Too many requests for this action.' },
});

/** Tighter cap for unscoped public join (token in URL) — discourages brute-force token scanning. */
export const examPublicJoinLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 24,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Too many public exam requests. Try again shortly.' },
});
