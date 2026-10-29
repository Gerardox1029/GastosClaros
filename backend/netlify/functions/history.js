const { connectToDatabase } = require('../../lib/db');
const Ingreso = require('../../models/Ingreso');
const Gasto = require('../../models/Gasto');
const { decryptDocument } = require('../../lib/encryption');
const { authFailure } = require('../../lib/auth');

/**
 * GET /api/history/:type
 * Obtiene historial reciente de ingresos o gastos.
 * Path param: type = ingresos | gastos
 * Query params: limit (default: 3)
 */
exports.handler = async (event) => {
  const denied = authFailure(event);
  if (denied) return denied;
  // Solo permitir GET
  if (event.httpMethod !== 'GET') {
    return {
      statusCode: 405,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Método no permitido. Use GET.' }),
    };
  }

  try {
    await connectToDatabase();

    // Extraer tipo del path: /api/history/ingresos o /api/history/gastos
    const pathParts = event.path.split('/');
    const type = pathParts[pathParts.length - 1];

    if (!['ingresos', 'gastos'].includes(type)) {
      return {
        statusCode: 400,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          error: 'Tipo inválido. Use "ingresos" o "gastos".',
        }),
      };
    }

    // Obtener límite
    const limit = parseInt(event.queryStringParameters?.limit) || 3;
    const sanitizedLimit = Math.min(Math.max(limit, 1), 1000);

    // Seleccionar modelo
    const Model = type === 'ingresos' ? Ingreso : Gasto;

    // Consultar documentos ordenados por fecha descendente
    const documents = await Model.find()
      .sort({ fecha: -1 })
      .limit(sanitizedLimit + 1)
      .lean();

    const hasMore = documents.length > sanitizedLimit;
    if (hasMore) documents.pop();

    // Descifrar campos sensibles
    const decryptedDocs = documents.map((doc) => decryptDocument(doc));

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({ data: decryptedDocs, has_more: hasMore }),
    };
  } catch (error) {
    console.error('[history] Error:', error.message);
    return {
      statusCode: 500,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Error interno del servidor.' }),
    };
  }
};
