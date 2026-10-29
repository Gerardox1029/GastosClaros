const { connectToDatabase } = require('../../lib/db');
const Ingreso = require('../../models/Ingreso');
const Gasto = require('../../models/Gasto');
const { encryptDocument } = require('../../lib/encryption');
const { reply } = require('../../lib/http');
const { authFailure } = require('../../lib/auth');

exports.handler = async (event) => {
  const denied = authFailure(event);
  if (denied) return denied;
  if (event.httpMethod === 'OPTIONS') return reply(200, {});
  if (!['PATCH', 'DELETE'].includes(event.httpMethod)) return reply(405, { error: 'Método no permitido.' });
  let body;
  try { body = JSON.parse(event.body); } catch { return reply(400, { error: 'JSON inválido.' }); }
  if (!body || !['ingreso', 'gasto'].includes(body.type) || typeof body.id !== 'string' || !/^[a-f\d]{24}$/i.test(body.id)) {
    return reply(400, { error: 'Tipo o identificador inválido.' });
  }
  let update;
  if (event.httpMethod === 'PATCH') {
    const { monto, nombre = '', descripcion, fecha } = body;
    if (typeof monto !== 'number' || !Number.isFinite(monto) || monto < 0.01 ||
        typeof nombre !== 'string' || typeof descripcion !== 'string' || !descripcion.trim() ||
        typeof fecha !== 'string' || !Number.isFinite(Date.parse(fecha))) {
      return reply(400, { error: 'Revisa el monto, la descripción y la fecha.' });
    }
    update = { monto: Number(monto.toFixed(2)), nombre: nombre.trim().slice(0, 200),
      descripcion: descripcion.trim().slice(0, 500), fecha: new Date(fecha) };
  }
  try {
    await connectToDatabase();
    const Model = body.type === 'ingreso' ? Ingreso : Gasto;
    const result = event.httpMethod === 'DELETE'
      ? await Model.findByIdAndDelete(body.id)
      : await Model.findByIdAndUpdate(body.id, { $set: encryptDocument(update) }, { new: true, runValidators: true });
    return result ? reply(200, { success: true }) : reply(404, { error: 'Registro no encontrado.' });
  } catch (error) {
    console.error('[record]', error.message);
    return reply(500, { error: 'No se pudo modificar el registro.' });
  }
};
