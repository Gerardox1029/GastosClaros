jest.mock('../lib/db', () => ({ connectToDatabase: jest.fn() }));
const { connectToDatabase } = require('../lib/db');
const { handler } = require('../netlify/functions/auth-login');
const { verifyToken } = require('../lib/auth');

beforeEach(() => {
  process.env.APP_PIN = '12345678';
  process.env.SESSION_SECRET = 'a-really-long-secret-for-testing-only-123456789';
  let failures = 0;
  const collection = {
    createIndex: jest.fn(),
    findOneAndUpdate: jest.fn(async () => ({ failures: ++failures })),
    deleteOne: jest.fn(),
  };
  connectToDatabase.mockResolvedValue({ collection: () => collection });
});

test('correct PIN issues a signed session', async () => {
  const response = await handler({ httpMethod: 'POST', headers: {},
    body: JSON.stringify({ pin: '12345678' }) });
  expect(response.statusCode).toBe(200);
  expect(verifyToken(JSON.parse(response.body).token)).toBe(true);
});

test('sixth attempt is limited even with correct PIN', async () => {
  const event = (pin) => ({ httpMethod: 'POST', headers: {}, body: JSON.stringify({ pin }) });
  for (let i = 0; i < 5; i++) {
    expect((await handler(event('99999999'))).statusCode).toBe(401);
  }
  expect((await handler(event('12345678'))).statusCode).toBe(429);
});
