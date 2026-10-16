const { connectToDatabase } = require('../../lib/db');
const Ingreso = require('../../models/Ingreso');
const Gasto = require('../../models/Gasto');
const { decryptDocument } = require('../../lib/encryption');

/**
 * GET /api/balance
 * Calcula el saldo actual: Total Ingresos - Total Gastos.
 * Query params: filter = 1D | 7D | 14D | 1M
 */
exports.handler = async (event) => {
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

    // Obtener filtro de tiempo
    const filter = event.queryStringParameters?.filter || '1M';
    const dateFilter = getDateFilter(filter);

    // Calcular totales en paralelo
    const [totalIngresos, totalGastos] = await Promise.all([
      Ingreso.aggregate([
        { $match: { fecha: { $gte: dateFilter } } },
        { $group: { _id: null, total: { $sum: '$monto' } } },
      ]),
      Gasto.aggregate([
        { $match: { fecha: { $gte: dateFilter } } },
        { $group: { _id: null, total: { $sum: '$monto' } } },
      ]),
    ]);

    const ingresos = totalIngresos[0]?.total || 0;
    const gastos = totalGastos[0]?.total || 0;
    const saldo = parseFloat((ingresos - gastos).toFixed(2));

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        saldo,
        total_ingresos: parseFloat(ingresos.toFixed(2)),
        total_gastos: parseFloat(gastos.toFixed(2)),
        filtro: filter,
      }),
    };
  } catch (error) {
    console.error('[balance] Error:', error.message);
    return {
      statusCode: 500,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Error interno del servidor.' }),
    };
  }
};

/**
 * Calcula la fecha de inicio según el filtro.
 * @param {string} filter - 1D | 7D | 14D | 1M
 * @returns {Date}
 */
function getDateFilter(filter) {
  const now = new Date();

  switch (filter) {
    case '1D':
      return new Date(now.getFullYear(), now.getMonth(), now.getDate());
    case '7D':
      return new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    case '14D':
      return new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000);
    case '1M':
    default:
      return new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
  }
}
