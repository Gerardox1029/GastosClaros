const { authFailure } = require('../../lib/auth');
const { reply } = require('../../lib/http');

exports.handler = async (event) => {
  if (event.httpMethod !== 'GET') return reply(405, { error: 'Use GET.' });
  return authFailure(event) || reply(200, { authenticated: true });
};
