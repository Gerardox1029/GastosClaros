jest.mock('../lib/db', () => ({ connectToDatabase: jest.fn() }));
jest.mock('../models/Ingreso', () => ({ findByIdAndUpdate: jest.fn(), findByIdAndDelete: jest.fn() }));
jest.mock('../models/Gasto', () => ({ findByIdAndUpdate: jest.fn(), findByIdAndDelete: jest.fn() }));
const Ingreso = require('../models/Ingreso');
const Gasto = require('../models/Gasto');
const { decryptDocument } = require('../lib/encryption');
const { handler } = require('../netlify/functions/record');
const id = '0123456789abcdef01234567';
beforeEach(() => { jest.clearAllMocks(); process.env.ENCRYPTION_KEY = 'test-key'; });
test('updates only selected income with encrypted fields', async () => {
  Ingreso.findByIdAndUpdate.mockResolvedValue({ _id: id });
  const response = await handler({ httpMethod: 'PATCH', body: JSON.stringify({ id, type: 'ingreso',
    monto: 20.5, nombre: 'Juan', descripcion: 'Pago', fecha: '2026-10-16T14:00:00Z', tipo_registro: 'bad' }) });
  expect(response.statusCode).toBe(200);
  const update = Ingreso.findByIdAndUpdate.mock.calls[0][1].$set;
  expect(update.descripcion).not.toBe('Pago');
  expect(decryptDocument(update).descripcion).toBe('Pago');
  expect(update).not.toHaveProperty('tipo_registro');
  expect(Gasto.findByIdAndUpdate).not.toHaveBeenCalled();
});
test('deletes selected expense and returns 404 for missing record', async () => {
  Gasto.findByIdAndDelete.mockResolvedValueOnce({ _id: id }).mockResolvedValueOnce(null);
  const event = { httpMethod: 'DELETE', body: JSON.stringify({ id, type: 'gasto' }) };
  expect((await handler(event)).statusCode).toBe(200);
  expect((await handler(event)).statusCode).toBe(404);
  expect(Gasto.findByIdAndDelete).toHaveBeenCalledWith(id);
});
test('rejects injection and invalid values before accessing storage', async () => {
  for (const body of [{ id: { $ne: null }, type: 'gasto' },
    { id, type: 'gasto', monto: -1, descripcion: 'x', fecha: 'bad' }]) {
    expect((await handler({ httpMethod: 'PATCH', body: JSON.stringify(body) })).statusCode).toBe(400);
  }
  expect(Gasto.findByIdAndUpdate).not.toHaveBeenCalled();
});
