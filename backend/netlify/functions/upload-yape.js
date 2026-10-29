const { createHash } = require('crypto');
const { createReceiptReader } = require('../../lib/local-ocr');
const { reply } = require('../../lib/http');
const { authFailure } = require('../../lib/auth');

exports.handler = async (event) => {
  const denied = authFailure(event);
  if (denied) return denied;
  if (event.httpMethod === 'OPTIONS') return reply(200, {});
  if (event.httpMethod !== 'POST') return reply(405, { error: 'Use POST.' });
  let body;
  try { body = JSON.parse(event.body); } catch { return reply(400, { error: 'JSON inválido.' }); }
  if (!body || !Array.isArray(body.images) || !body.images.length || body.images.length > 5 ||
      body.images.some((image) => typeof image !== 'string' || image.length > 7000000) ||
      !['ingreso', 'gasto'].includes(body.type)) {
    return reply(400, { error: 'Envía entre 1 y 5 imágenes y un tipo válido.' });
  }
  let reader;
  try {
    reader = await createReceiptReader();
    const results = [];
    for (const [index, image] of body.images.entries()) {
      try {
        const fields = await reader.read(image);
        const identity = fields.operationId
          ? `yape|${fields.operationId}|${fields.fecha}|${fields.monto}`
          : image.replace(/^data:image\/[^;]+;base64,/, '');
        const receiptKey = createHash('sha256').update(identity).digest('hex');
        results.push({ ...fields, receiptKey, extracted: true, saved: false, captureIndex: index + 1 });
      } catch (error) {
        results.push({ nombre: '', monto: 0, descripcion: 'Captura no procesada', fecha: new Date().toISOString(),
          saved: false, extracted: false, error: /^No se pudo leer (el monto|la fecha)/.test(error.message)
            ? error.message : 'No se pudo procesar la imagen. Usa una captura PNG o JPG nítida.', captureIndex: index + 1 });
      }
    }
    return reply(200, { results });
  } catch (error) {
    console.error('[upload-yape]', error.message);
    return reply(500, { error: 'No se pudieron procesar las capturas.' });
  } finally { if (reader) await reader.close(); }
};
