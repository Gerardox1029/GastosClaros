jest.mock('../lib/db', () => ({ connectToDatabase: jest.fn() }));
jest.mock('../models/Ingreso', () => ({ create: jest.fn() }));
jest.mock('../models/Gasto', () => ({ create: jest.fn() }));
jest.mock('../lib/local-ocr', () => ({ createReceiptReader: jest.fn() }));
const { createReceiptReader } = require('../lib/local-ocr');
const { connectToDatabase } = require('../lib/db');
const Gasto = require('../models/Gasto');
const { handler } = require('../netlify/functions/upload-yape');

test('extracts each image without changing storage and returns an idempotent receipt key', async () => {
  delete process.env.GEMINI_API_KEY;
  const fields = { nombre: 'Persona', monto: 25, descripcion: 'Almuerzo',
    fecha: '2026-10-16T19:30:00Z', operationId: '12345678' };
  const reader = { read: jest.fn().mockResolvedValueOnce(fields)
    .mockRejectedValueOnce(new Error('Unreadable')).mockResolvedValueOnce(fields), close: jest.fn() };
  createReceiptReader.mockResolvedValue(reader);
  const response = await handler({ httpMethod: 'POST', body: JSON.stringify({ type: 'gasto', images: ['a', 'b', 'c'] }) });
  expect(response.statusCode).toBe(200);
  const { results } = JSON.parse(response.body);
  expect(results[0]).toMatchObject({ saved: false, extracted: true, monto: 25, captureIndex: 1 });
  expect(results[0].receiptKey).toMatch(/^[a-f0-9]{64}$/);
  expect(results[2].receiptKey).toBe(results[0].receiptKey);
  expect(results[1]).toMatchObject({ saved: false, extracted: false, captureIndex: 2 });
  expect(Gasto.create).not.toHaveBeenCalled();
  expect(connectToDatabase).not.toHaveBeenCalled();
  expect(reader.close).toHaveBeenCalledTimes(1);
});
