function requestContext(req) {
  const userId = req.user?._id ?? req.user?.id;
  return `${req.method} ${req.originalUrl}${userId ? ` user=${userId}` : ''}`;
}

export function notFoundHandler(req, res) {
  if (process.env.NODE_ENV !== 'production') {
    console.warn(`⚠️ [404] ${requestContext(req)}`);
  }
  res.status(404).json({ message: 'Not found' });
}

export function errorHandler(err, req, res, _next) {
  let status = err.statusCode || 500;
  if (err.name === 'MulterError') {
    status = 400;
  } else if (err.message === 'Unsupported file type') {
    status = 400;
  }
  const message =
    status < 500
      ? err.message
      : 'Server error';
  const ctx = requestContext(req);
  if (status >= 500) {
    console.error(`💥 [${ctx}]`, err);
  } else if (process.env.NODE_ENV !== 'production') {
    console.warn(`⚠️ [${ctx}] ${status} ${err.message}`);
  }
  res.status(status).json({ message });
}
