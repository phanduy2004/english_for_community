/** In-memory TTL cache for short-lived read-heavy aggregates (per-process only). */
export function createTtlCache(defaultTtlMs = 10_000) {
  const store = new Map();

  function get(key) {
    const entry = store.get(key);
    if (!entry) return undefined;
    if (Date.now() > entry.expiresAt) {
      store.delete(key);
      return undefined;
    }
    return entry.value;
  }

  function set(key, value, ttlMs = defaultTtlMs) {
    store.set(key, { value, expiresAt: Date.now() + ttlMs });
  }

  function del(key) {
    store.delete(key);
  }

  return { get, set, del };
}
