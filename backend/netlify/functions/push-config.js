const { authFailure } = require('../../lib/auth');
const { pushConfigured } = require('../../lib/push');
const { reply } = require('../../lib/http');

exports.handler = async (event) => {
  const denied = authFailure(event);
  if (denied) return denied;
  if (event.httpMethod !== 'GET') return reply(405, { error: 'Use GET.' });
  return reply(200, {
    available: pushConfigured(),
    publicKey: pushConfigured() ? process.env.VAPID_PUBLIC_KEY : null,
  });
};
