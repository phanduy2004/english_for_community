export function notFoundHandler(req, res) {
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
  if (status >= 500) console.error('💥 Unhandled error:', err);
  res.status(status).json({ message });
}
