const { authFailure, createToken, verifyToken, safePinMatch } = require('../lib/auth');
const { handler: check } = require('../netlify/functions/auth-check');
const { handler: balance } = require('../netlify/functions/balance');

beforeEach(() => {
  process.env.APP_PIN = '12345678';
  process.env.SESSION_SECRET = 'a-really-long-secret-for-testing-only-123456789';
});

test('every protected request needs a signed token', async () => {
  expect(authFailure({ headers: {} }).statusCode).toBe(401);
  expect((await balance({ httpMethod: 'GET', headers: {} })).statusCode).toBe(401);
  const token = createToken();
  expect(verifyToken(token)).toBe(true);
  expect((await check({ httpMethod: 'GET', headers: { authorization: `Bearer ${token}` } })).statusCode).toBe(200);
  expect(verifyToken(`${token}x`)).toBe(false);
  process.env.APP_PIN = '87654321';
  expect(verifyToken(token)).toBe(false);
});

test('PIN is numeric and configuration fails closed', () => {
  expect(safePinMatch('12345678')).toBe(true);
  expect(safePinMatch('12345679')).toBe(false);
  process.env.APP_PIN = '1234';
  expect(authFailure({ headers: {} }).statusCode).toBe(503);
});
