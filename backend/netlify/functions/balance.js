const { connectToDatabase } = require('../../lib/db');
const Ingreso = require('../../models/Ingreso');
const Gasto = require('../../models/Gasto');
const { decryptDocument } = require('../../lib/encryption');
const { authFailure } = require('../../lib/auth');

/**
 * GET /api/balance
 * Calcula el saldo disponible acumulado y, por separado, los totales del período.
 * Query params: filter = 1D | 7D | 14D | 1M
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

    // Obtener filtro de tiempo
    const requestedFilter = event.queryStringParameters?.filter || '1M';
    const filter = ['1D', '7D', '14D', '1M'].includes(requestedFilter)
      ? requestedFilter
      : '1M';
    const dateFilter = getDateFilter(filter);

    const sumAmounts = (Model, match = {}) => Model.aggregate([
      { $match: match },
      { $group: { _id: null, total: { $sum: '$monto' } } },
    ]);

    // El filtro afecta los indicadores del período; el saldo siempre representa
    // lo disponible desde el inicio, no el flujo neto de un solo día/semana.
    const [balanceIngresos, balanceGastos, periodIngresos, periodGastos] =
      await Promise.all([
        sumAmounts(Ingreso),
        sumAmounts(Gasto),
        sumAmounts(Ingreso, { fecha: { $gte: dateFilter } }),
        sumAmounts(Gasto, { fecha: { $gte: dateFilter } }),
      ]);

    const ingresos = periodIngresos[0]?.total || 0;
    const gastos = periodGastos[0]?.total || 0;
    const saldo = (balanceIngresos[0]?.total || 0) - (balanceGastos[0]?.total || 0);

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        saldo: parseFloat(saldo.toFixed(2)),
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
      // Inicio del día en Lima (UTC-5), independiente de la zona del servidor.
      return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1) - 5 * 60 * 60 * 1000);
    case '7D':
      return new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    case '14D':
      return new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000);
    case '1M':
    default:
      return new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
  }
}
