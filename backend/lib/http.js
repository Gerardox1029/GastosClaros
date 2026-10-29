const headers = {
  'Content-Type': 'application/json',
  'Cache-Control': 'no-store',
};
exports.reply = (statusCode, data) => ({ statusCode, headers, body: JSON.stringify(data) });
