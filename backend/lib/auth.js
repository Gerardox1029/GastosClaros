const { createHmac, createHash, timingSafeEqual } = require('crypto');
const { reply } = require('./http');
require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const SESSION_SECONDS = 30 * 24 * 60 * 60;

function configured() {
  return /^\d{6,12}$/.test(process.env.APP_PIN || '') &&
    (process.env.SESSION_SECRET || '').length >= 32;
}

function signature(payload) {
  return createHmac('sha256', process.env.SESSION_SECRET)
    .update(`${payload}.${process.env.APP_PIN}`).digest('base64url');
}

function sessionRevision() {
  return createHash('sha256').update(`${process.env.SESSION_SECRET}:${process.env.APP_PIN}`).digest('hex');
}

function createToken() {
  const payload = Buffer.from(JSON.stringify({
    v: 1, exp: Math.floor(Date.now() / 1000) + SESSION_SECONDS,
  })).toString('base64url');
  return `${payload}.${signature(payload)}`;
}

function verifyToken(token) {
  if (!configured() || typeof token !== 'string' || token.length > 500) return false;
  const parts = token.split('.');
  if (parts.length !== 2) return false;
  const expected = Buffer.from(signature(parts[0]));
  const actual = Buffer.from(parts[1]);
  if (expected.length !== actual.length || !timingSafeEqual(expected, actual)) return false;
  try {
    const data = JSON.parse(Buffer.from(parts[0], 'base64url').toString('utf8'));
    return data.v === 1 && Number.isInteger(data.exp) && data.exp > Date.now() / 1000;
  } catch { return false; }
}

function authFailure(event) {
  if (!configured()) return reply(503, { error: 'Configura APP_PIN (6 a 12 dígitos) y SESSION_SECRET (32 caracteres mínimo).' });
  const header = event.headers?.authorization || event.headers?.Authorization || '';
  return verifyToken(header.startsWith('Bearer ') ? header.slice(7) : '')
    ? null : reply(401, { error: 'Debes ingresar tu PIN para continuar.' });
}

function safePinMatch(input) {
  if (!configured() || typeof input !== 'string') return false;
  const a = createHash('sha256').update(input).digest();
  const b = createHash('sha256').update(process.env.APP_PIN).digest();
  return timingSafeEqual(a, b);
}

module.exports = { configured, createToken, verifyToken, authFailure, safePinMatch, sessionRevision };
