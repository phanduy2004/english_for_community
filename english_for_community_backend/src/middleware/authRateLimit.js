import rateLimit from 'express-rate-limit';

// Shared base config. Per-IP windows; emits standard RateLimit-* headers.
const base = { windowMs: 15 * 60 * 1000, standardHeaders: true, legacyHeaders: false };

// Credential checks — throttles password brute-force / credential stuffing.
export const loginLimiter = rateLimit({
  ...base,
  max: 15,
  message: { message: 'Too many login attempts. Please try again in a few minutes.' },
});

// OTP & email-triggering endpoints — blocks code brute-force, account
// enumeration, and mail flooding (register, resend, verify, forgot/reset).
export const otpLimiter = rateLimit({
  ...base,
  max: 10,
  message: { message: 'Too many requests. Please wait before trying again.' },
});

// Generic guard for the rest of the auth surface (refresh, social login).
export const authLimiter = rateLimit({
  ...base,
  max: 40,
  message: { message: 'Too many requests. Please slow down.' },
});
