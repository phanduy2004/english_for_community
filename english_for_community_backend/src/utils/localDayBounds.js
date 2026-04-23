/**
 * Cận ngày dương lịch theo IANA timezone (không cần thêm dependency).
 * Dùng cho query Mongo theo createdAt/updatedAt khớp "hôm nay" của user.
 */

export const YMD_RE = /^\d{4}-\d{2}-\d{2}$/;

export function isPlainYmd(s) {
  return typeof s === 'string' && YMD_RE.test(s);
}

export function ymdInTimeZone(ms, timeZone) {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(new Date(ms));
}

/**
 * @param {string} ymd - YYYY-MM-DD
 * @param {string} timeZone - IANA, ví dụ Asia/Ho_Chi_Minh
 * @returns {{ start: Date, end: Date } | null}
 */
export function utcRangeForCalendarDate(ymd, timeZone) {
  if (!isPlainYmd(ymd)) return null;

  const [Y, M, D] = ymd.split('-').map(Number);
  const anchor = Date.UTC(Y, M - 1, D, 12, 0, 0);

  let low = anchor - 48 * 3600000;
  let high = anchor + 48 * 3600000;

  while (low < high) {
    const mid = Math.floor((low + high) / 2);
    const cm = ymdInTimeZone(mid, timeZone);
    if (cm >= ymd) high = mid;
    else low = mid + 1;
  }
  const startMs = low;

  let low2 = startMs;
  let high2 = startMs + 50 * 3600000;

  while (low2 < high2) {
    const mid = Math.floor((low2 + high2) / 2);
    if (ymdInTimeZone(mid, timeZone) === ymd) low2 = mid + 1;
    else high2 = mid;
  }
  const endMs = low2 - 1;

  return { start: new Date(startMs), end: new Date(endMs) };
}

/** Cộng/trừ ngày trên chuỗi YYYY-MM-DD (lịch Gregorian, không DST). */
export function addCalendarDays(ymd, deltaDays) {
  const [y, m, d] = ymd.split('-').map(Number);
  const x = new Date(Date.UTC(y, m - 1, d));
  x.setUTCDate(x.getUTCDate() + deltaDays);
  const yy = x.getUTCFullYear();
  const mm = String(x.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(x.getUTCDate()).padStart(2, '0');
  return `${yy}-${mm}-${dd}`;
}
