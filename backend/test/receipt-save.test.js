jest.mock('../lib/db', () => ({ connectToDatabase: jest.fn() }));
jest.mock('../models/Ingreso', () => ({ create: jest.fn(), findOneAndUpdate: jest.fn() }));
jest.mock('../models/Gasto', () => ({ create: jest.fn(), findOneAndUpdate: jest.fn() }));
const Gasto = require('../models/Gasto');
const { decryptDocument } = require('../lib/encryption');
const { handler } = require('../netlify/functions/manual-entry');

test('saving the same receipt twice inserts once and keeps encryption', async () => {
  process.env.ENCRYPTION_KEY = 'test-key';
  const records = new Map();
  Gasto.findOneAndUpdate.mockImplementation(async (filter, update) => {
    if (!records.has(filter._id)) records.set(filter._id, { _id: filter._id, ...update.$setOnInsert });
    return records.get(filter._id);
  });
  const entry = { type: 'gasto', monto: 25, nombre: 'Persona', descripcion: 'Almuerzo',
    fecha: '2026-10-16T19:30:00Z', receiptKey: 'a'.repeat(64) };
  const event = { httpMethod: 'POST', body: JSON.stringify(entry) };
  const first = await handler(event);
  const retry = await handler(event);
  expect(first.statusCode).toBe(201);
  expect(JSON.parse(retry.body).id).toBe(JSON.parse(first.body).id);
  expect(records.size).toBe(1);
  const stored = [...records.values()][0];
  expect(stored.descripcion).not.toBe('Almuerzo');
  expect(decryptDocument(stored).descripcion).toBe('Almuerzo');
  expect(stored.tipo_registro).toBe('ai_yape');
  expect(Gasto.create).not.toHaveBeenCalled();
  await handler({ ...event, body: JSON.stringify({ ...entry, receiptKey: 'b'.repeat(64) }) });
  expect(records.size).toBe(2);
});
