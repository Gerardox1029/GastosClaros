const { connectToDatabase } = require('../../lib/db');
const Ingreso = require('../../models/Ingreso');
const Gasto = require('../../models/Gasto');
const { encryptDocument } = require('../../lib/encryption');
const { authFailure } = require('../../lib/auth');
const { sendSavedPush } = require('../../lib/push');

/**
 * POST /api/manual-entry
 * Guarda un registro manual (ingreso o gasto).
 * Body: { monto, nombre, descripcion, fecha, type }
 */
exports.handler = async (event) => {
  const denied = authFailure(event);
  if (denied) return denied;
  // CORS preflight
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      },
      body: '',
    };
  }

  // Solo permitir POST
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Método no permitido. Use POST.' }),
    };
  }

  try {
    await connectToDatabase();

    // Parsear body
    let body;
    try {
      body = JSON.parse(event.body);
    } catch {
      return {
        statusCode: 400,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ error: 'Body JSON inválido.' }),
      };
    }

    // Validar campos requeridos
    const { monto, nombre, descripcion, fecha, type, receiptKey } = body;

    if (receiptKey !== undefined && (typeof receiptKey !== 'string' || !/^[a-f0-9]{64}$/.test(receiptKey))) {
      return { statusCode: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        body: JSON.stringify({ error: 'Identificador de captura inválido.' }) };
    }

    if (!monto || typeof monto !== 'number' || !Number.isFinite(monto) || monto < 0.01) {
      return {
        statusCode: 400,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ error: 'Monto inválido. Debe ser un número positivo.' }),
      };
    }

    if (!descripcion || typeof descripcion !== 'string' || descripcion.trim().length === 0) {
      return {
        statusCode: 400,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ error: 'La descripción es requerida.' }),
      };
    }

    if (!type || !['ingreso', 'gasto'].includes(type)) {
      return {
        statusCode: 400,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ error: 'Tipo inválido. Use "ingreso" o "gasto".' }),
      };
    }

    // Sanitizar strings (anti-injection)
    const sanitizedNombre = nombre ? String(nombre).trim().substring(0, 200) : '';
    const sanitizedDescripcion = String(descripcion).trim().substring(0, 500);

    // Preparar documento
    const docData = {
      monto: parseFloat(monto.toFixed(2)),
      nombre: sanitizedNombre,
      descripcion: sanitizedDescripcion,
      fecha: fecha ? new Date(fecha) : new Date(),
      tipo_registro: receiptKey ? 'ai_yape' : 'manual',
    };

    // Cifrar campos sensibles
    const encryptedData = encryptDocument(docData);

    // Seleccionar modelo y guardar
    const Model = type === 'ingreso' ? Ingreso : Gasto;
    // The same receipt (including retries) always targets the same primary key.
    // OCR itself never writes: only this explicit save inserts a record.
    const result = receiptKey
      ? await Model.findOneAndUpdate(
          { _id: receiptKey.slice(0, 24) }, { $setOnInsert: encryptedData },
          { upsert: true, new: true, runValidators: true, includeResultMetadata: true },
        )
      : await Model.create(encryptedData);
    const saved = result.value || result;
    const created = !receiptKey || result.lastErrorObject?.updatedExisting !== true;
    if (created) await sendSavedPush(type, docData.monto, docData.descripcion);

    return {
      statusCode: 201,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        success: true,
        id: saved._id.toString(),
        created,
      }),
    };
  } catch (error) {
    console.error('[manual-entry] Error:', error.message);

    // Manejar errores de validación de Mongoose
    if (error.name === 'ValidationError') {
      const messages = Object.values(error.errors).map((e) => e.message);
      return {
        statusCode: 400,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ error: messages.join(', ') }),
      };
    }

    return {
      statusCode: 500,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Error interno del servidor.' }),
    };
  }
};
