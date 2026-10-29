const { createHash } = require('crypto');
const { connectToDatabase } = require('../../lib/db');
const { configured, createToken, safePinMatch } = require('../../lib/auth');
const { reply } = require('../../lib/http');

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') return reply(405, { error: 'Use POST.' });
  if (!configured()) return reply(503, { error: 'Configura APP_PIN (6 a 12 dígitos) y SESSION_SECRET (32 caracteres mínimo).' });
  let body;
  try { body = JSON.parse(event.body); } catch { return reply(400, { error: 'JSON inválido.' }); }
  if (typeof body?.pin !== 'string' || !/^\d{6,12}$/.test(body.pin)) {
    return reply(400, { error: 'Ingresa un PIN de 6 a 12 dígitos.' });
  }

  try {
    const db = await connectToDatabase();
    const source = event.headers?.['x-nf-client-connection-ip'] || 'unknown';
    const key = createHash('sha256').update(`${process.env.SESSION_SECRET}:${source}`).digest('hex');
    const attempts = db.collection('gastosclaros_auth_attempts');
    await attempts.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
    const now = new Date();
    const state = await attempts.findOneAndUpdate({ _id: key }, [{ $set: {
      failures: { $cond: [
        { $gt: ['$expiresAt', now] },
        { $add: [{ $ifNull: ['$failures', 0] }, 1] },
        1,
      ] },
      expiresAt: new Date(now.getTime() + 15 * 60 * 1000),
    } }], { upsert: true, returnDocument: 'after' });
    if (state.failures > 5) {
      return reply(429, { error: 'Demasiados intentos. Espera 15 minutos.' });
    }
    if (!safePinMatch(body.pin)) {
      return reply(401, { error: 'PIN incorrecto.' });
    }
    await attempts.deleteOne({ _id: key });
    return reply(200, { token: createToken() });
  } catch (error) {
    console.error('[auth-login]', error.message);
    return reply(503, { error: 'No se pudo verificar el acceso. Intenta de nuevo.' });
  }
};
