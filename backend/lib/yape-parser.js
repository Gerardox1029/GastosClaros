// Parse only recognizable receipt fields; never infer an amount from phone/operation numbers.
function parseYapeText(text) {
  const lines = text.split(/\r?\n/).map((l) => l.trim()).filter(Boolean);
  const amount = text.match(/S\s*\/\.?\s*(\d[\d.,]*(?:[ \t]*[.,][ \t]*\d{2})?)/i);
  let monto = 0;
  if (amount) {
    let value = amount[1].replace(/\s/g, '');
    const separator = Math.max(value.lastIndexOf(','), value.lastIndexOf('.'));
    value = separator >= 0 && value.length - separator === 3
      ? value.slice(0, separator).replace(/[.,]/g, '') + '.' + value.slice(separator + 1)
      : value.replace(/[.,]/g, '');
    monto = Number(value);
  }
  if (!Number.isFinite(monto) || monto <= 0) throw new Error('No se pudo leer el monto. Usa una captura más nítida o ingresa los datos manualmente.');
  const amountIndex = lines.findIndex((l) => /S\s*\//i.test(l));
  const nameLabel = lines.findIndex((l) => /^(?:para|de|destinatario|nombre)\s*:?\s*$/i.test(l));
  const inlineName = text.match(/^(?:para|de|destinatario|nombre)\s*:\s*(.+)$/im);
  const candidate = inlineName?.[1] || (nameLabel >= 0 ? lines[nameLabel + 1] : lines[amountIndex + 1]) || '';
  const nombre = /\p{L}/u.test(candidate) && !/fecha|operaci[oó]n|celular|destino|mensaje|yapeaste|recibiste/i.test(candidate)
    ? candidate.slice(0, 200) : '';
  const message = text.match(/^(?:mensaje|descripci[oó]n|concepto)\s*:\s*(.+)$/im);
  let fecha = '';
  const numeric = text.match(/\b(\d{1,2})[\/-](\d{1,2})[\/-](\d{4})\b/);
  const named = text.match(/\b(\d{1,2})\s*(?:de\s+)?(ene\w*|feb\w*|mar\w*|abr\w*|may\w*|jun\w*|jul\w*|ago\w*|sep\w*|set\w*|oct\w*|nov\w*|dic\w*)[ .]*(?:de\s+)?(\d{4})\b/i);
  if (numeric || named) {
    const match = numeric || named;
    const months = { ene: 1, feb: 2, mar: 3, abr: 4, may: 5, jun: 6, jul: 7, ago: 8, sep: 9, set: 9, oct: 10, nov: 11, dic: 12 };
    const day = Number(match[1]), month = numeric ? Number(match[2]) : months[match[2].slice(0, 3).toLowerCase()];
    const year = Number(match[3]);
    const time = text.match(/\b(\d{1,2}):(\d{2})(?:\s*([ap])\.?\s*m\.?)?/i);
    let hour = time ? Number(time[1]) : 0;
    const minute = time ? Number(time[2]) : 0;
    if (time?.[3]) hour = hour % 12 + (time[3].toLowerCase() === 'p' ? 12 : 0);
    const date = new Date(Date.UTC(year, month - 1, day, hour + 5, minute));
    const local = new Date(date.getTime() - 5 * 3600000);
    if (local.getUTCFullYear() === year && local.getUTCMonth() === month - 1 && local.getUTCDate() === day && hour < 24 && minute < 60) fecha = date.toISOString();
  }
  // A missing receipt date requires manual review rather than silently dating it today.
  if (!fecha) throw new Error('No se pudo leer la fecha. Revisa la captura o registra los datos manualmente.');
  const dateIndex = lines.findIndex((line) => numeric ? line.includes(numeric[0]) : line.includes(named?.[0]));
  const following = lines[dateIndex + 1] || '';
  const note = dateIndex >= 0 && !/c[oó]digo|seguridad|datos de|celular|destino|operaci[oó]n/i.test(following)
    ? following.replace(/^(?:EJ?|[■▣□]+)\s+/u, '').trim() : '';
  const operation = text.match(/Nro\.?\s*(?:de\s*)?operaci[oó]n\s*[:#]?\s*(\d{6,})/i);
  return { monto, nombre, descripcion: (message?.[1]?.trim() || note || 'Pago Yape').slice(0, 500),
    fecha, ...(operation ? { operationId: operation[1] } : {}) };
}
module.exports = { parseYapeText };
