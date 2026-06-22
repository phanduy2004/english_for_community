// Neutralizes MongoDB operator injection in user input.
//
// Without this, a JSON body like { "email": { "$ne": null } } reaches a query
// such as User.findOne(req.body) and matches the first user — classic NoSQL
// auth bypass. We strip any key starting with "$" (e.g. $ne, $gt, $where,
// $regex). "$"-prefixed keys are never legitimate in client input, so removing
// them is safe and does not break normal payloads.

function scrub(obj, depth = 0) {
  // Guard against pathological/deeply-nested payloads.
  if (!obj || typeof obj !== 'object' || depth > 6) return;
  for (const key of Object.keys(obj)) {
    if (key.startsWith('$')) {
      delete obj[key];
      continue;
    }
    const value = obj[key];
    if (value && typeof value === 'object') scrub(value, depth + 1);
  }
}

export function mongoSanitize(req, _res, next) {
  scrub(req.body);
  scrub(req.query); // Express 4: req.query is a mutable plain object.
  scrub(req.params);
  next();
}
