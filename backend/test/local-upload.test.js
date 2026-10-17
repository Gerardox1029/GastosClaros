jest.mock('../lib/db', () => ({ connectToDatabase: jest.fn() }));
jest.mock('../models/Ingreso', () => ({ create: jest.fn() }));
jest.mock('../models/Gasto', () => ({ create: jest.fn() }));
jest.mock('../lib/local-ocr', () => ({ createReceiptReader: jest.fn() }));
const { createReceiptReader } = require('../lib/local-ocr');
const Gasto = require('../models/Gasto');
const { handler } = require('../netlify/functions/upload-yape');
test('keeps per-image success/error results and closes local OCR worker', async () => {
  delete process.env.GEMINI_API_KEY;
  process.env.ENCRYPTION_KEY = 'test-key';
  const reader = { read: jest.fn().mockResolvedValueOnce({ nombre: 'Juan', monto: 25,
    descripcion: 'Almuerzo', fecha: '2026-10-16T19:30:00Z' }).mockRejectedValueOnce(new Error('Unreadable')), close: jest.fn() };
  createReceiptReader.mockResolvedValue(reader);
  Gasto.create.mockResolvedValue({ _id: 'saved-id' });
  const response = await handler({ httpMethod: 'POST', body: JSON.stringify({ type: 'gasto', images: ['a', 'b'] }) });
  expect(response.statusCode).toBe(200);
  const { results } = JSON.parse(response.body);
  expect(results[0]).toMatchObject({ saved: true, monto: 25, id: 'saved-id', captureIndex: 1 });
  expect(results[1]).toMatchObject({ saved: false, captureIndex: 2 });
  expect(Gasto.create).toHaveBeenCalledTimes(1);
  expect(Gasto.create.mock.calls[0][0].descripcion).not.toBe('Almuerzo');
  expect(reader.close).toHaveBeenCalledTimes(1);
});
