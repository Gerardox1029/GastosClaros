const { decryptDocument } = require('./encryption');

function periodRange(period, now = new Date()) {
  const local = new Date(now.getTime() - 5 * 3600000);
  const end = new Date(Date.UTC(local.getUTCFullYear(), local.getUTCMonth(), local.getUTCDate() + 1, 5));
  const start = new Date(end);
  start.setUTCDate(start.getUTCDate() - ({ '1D': 1, '7D': 7, '1M': 30 }[period]));
  return { start, end };
}
async function financialContext(Ingreso, Gasto, period, now) {
  const { start, end } = periodRange(period, now);
  async function read(Model) {
    const filter = { fecha: { $gte: start, $lt: end } };
    const [totals, records] = await Promise.all([
      Model.aggregate([{ $match: filter }, { $group: { _id: null, total: { $sum: '$monto' }, count: { $sum: 1 } } }]),
      Model.find(filter).sort({ fecha: -1 }).limit(100).lean(),
    ]);
    return { total: totals[0]?.total || 0, cantidad: totals[0]?.count || 0,
      registros: records.map((record) => {
        const d = decryptDocument(record);
        return { monto: d.monto, nombre: d.nombre, descripcion: d.descripcion, fecha: d.fecha };
      }) };
  }
  const [ingresos, gastos] = await Promise.all([read(Ingreso), read(Gasto)]);
  return { desde: start.toISOString(), hasta_exclusivo: end.toISOString(), zona: 'America/Lima',
    ingresos, gastos, saldo: ingresos.total - gastos.total,
    detalle: 'Totales de todos los registros del período; detalle de los 100 más recientes de cada tipo.' };
}
module.exports = { periodRange, financialContext };
