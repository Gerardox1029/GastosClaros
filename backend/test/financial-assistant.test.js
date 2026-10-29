jest.mock('../lib/auth', () => ({ authFailure: () => null }));
jest.mock('../lib/db', () => ({ connectToDatabase: jest.fn() }));
jest.mock('../models/Ingreso', () => ({ aggregate: jest.fn(), find: jest.fn() }));
jest.mock('../models/Gasto', () => ({ aggregate: jest.fn(), find: jest.fn() }));
const mockGenerateContent = jest.fn();
jest.mock('@google/generative-ai', () => ({ GoogleGenerativeAI: jest.fn(() => ({ getGenerativeModel: () => ({ generateContent: mockGenerateContent }) })) }));
const Ingreso = require('../models/Ingreso');
const Gasto = require('../models/Gasto');
const { handler } = require('../netlify/functions/financial-assistant');
beforeEach(() => {
  jest.clearAllMocks(); process.env.GEMINI_API_KEY = 'test';
  for (const [model, total] of [[Ingreso, 500], [Gasto, 125]]) {
    model.aggregate.mockResolvedValue([{ total, count: 120 }]);
    model.find.mockReturnValue({ sort: () => ({ limit: () => ({ lean: async () => [] }) }) });
  }
});
test('queries both collections and sends server totals to Gemini for selected period', async () => {
  mockGenerateContent.mockResolvedValue({ response: { text: () => 'Saldo: S/. 375.00' } });
  const response = await handler({ httpMethod: 'POST', body: JSON.stringify({ period: '7D', message: 'Reporte' }) });
  expect(response.statusCode).toBe(200);
  const content = JSON.parse(mockGenerateContent.mock.calls[0][0]);
  expect(content.datos_financieros.saldo).toBe(375);
  expect(content.datos_financieros.ingresos.cantidad).toBe(120);
  expect(Ingreso.aggregate).toHaveBeenCalled();
  expect(Gasto.aggregate).toHaveBeenCalled();
});
test('rejects unsupported periods without Gemini calls', async () => {
  expect((await handler({ httpMethod: 'POST', body: JSON.stringify({ period: 'all', message: 'Reporte' }) })).statusCode).toBe(400);
  expect(mockGenerateContent).not.toHaveBeenCalled();
});

test('reports Gemini availability separately from rejected prompts', async () => {
  const rateLimit = Object.assign(new Error('rate limit'), { status: 429 });
  mockGenerateContent.mockRejectedValueOnce(rateLimit)
    .mockRejectedValueOnce(rateLimit).mockRejectedValueOnce(rateLimit);
  const unavailable = await handler({
    httpMethod: 'POST', body: JSON.stringify({ period: '1D', message: '¿Cuánto gasté?' }),
  });
  expect(unavailable.statusCode).toBe(503);
  expect(JSON.parse(unavailable.body)).toMatchObject({ code: 'gemini_rate_limited' });

  mockGenerateContent.mockRejectedValueOnce(Object.assign(new Error('invalid request'), { status: 400 }));
  const rejected = await handler({
    httpMethod: 'POST', body: JSON.stringify({ period: '1D', message: '¿Cuánto gasté?' }),
  });
  expect(rejected.statusCode).toBe(502);
  expect(JSON.parse(rejected.body)).toMatchObject({ code: 'gemini_request_rejected' });

  mockGenerateContent.mockRejectedValueOnce(Object.assign(new Error('forbidden'), { status: 403 }));
  const configuration = await handler({
    httpMethod: 'POST', body: JSON.stringify({ period: '1D', message: '¿Cuánto gasté?' }),
  });
  expect(configuration.statusCode).toBe(502);
  expect(JSON.parse(configuration.body)).toMatchObject({ code: 'gemini_configuration_error' });
});

test('reports saved-data connection failures separately', async () => {
  const { connectToDatabase } = require('../lib/db');
  connectToDatabase.mockRejectedValueOnce(new Error('database unavailable'));
  const response = await handler({
    httpMethod: 'POST', body: JSON.stringify({ period: '1D', message: '¿Cuánto gasté?' }),
  });
  expect(response.statusCode).toBe(503);
  expect(JSON.parse(response.body)).toMatchObject({ code: 'financial_data_unavailable' });
  expect(mockGenerateContent).not.toHaveBeenCalled();
});
