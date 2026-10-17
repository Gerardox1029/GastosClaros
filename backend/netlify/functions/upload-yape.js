const { connectToDatabase } = require('../../lib/db');
const Ingreso = require('../../models/Ingreso');
const Gasto = require('../../models/Gasto');
const { encryptDocument } = require('../../lib/encryption');
const { createReceiptReader } = require('../../lib/local-ocr');
const { reply } = require('../../lib/http');

exports.handler = async (event) => {
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
    await connectToDatabase();
    reader = await createReceiptReader();
    const Model = body.type === 'ingreso' ? Ingreso : Gasto;
    const results = [];
    for (const [index, image] of body.images.entries()) {
      try {
        const fields = await reader.read(image);
        const doc = { ...fields, fecha: new Date(fields.fecha), tipo_registro: 'ai_yape' };
        const saved = await Model.create(encryptDocument(doc));
        results.push({ ...doc, saved: true, id: saved._id.toString(), captureIndex: index + 1 });
      } catch (error) {
        results.push({ nombre: '', monto: 0, descripcion: 'Captura no procesada', fecha: new Date().toISOString(),
          saved: false, error: 'No se pudo leer la captura. Revisa monto y fecha o ingresa los datos manualmente.', captureIndex: index + 1 });
      }
    }
    return reply(200, { results });
  } catch (error) {
    console.error('[upload-yape]', error.message);
    return reply(500, { error: 'No se pudieron procesar las capturas.' });
  } finally { if (reader) await reader.close(); }
};
