const { connectToDatabase } = require('../../lib/db');
const Ingreso = require('../../models/Ingreso');
const Gasto = require('../../models/Gasto');
const { encryptDocument } = require('../../lib/encryption');
const { GoogleGenerativeAI } = require('@google/generative-ai');

/**
 * POST /api/upload-yape
 * Recibe imágenes base64 de capturas Yape, extrae datos con Gemini Vision,
 * guarda en MongoDB y retorna los datos parseados.
 *
 * Body: { images: [base64string, ...], type: "ingreso" | "gasto" }
 */
exports.handler = async (event) => {
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

    const { images, type } = body;

    // Validar
    if (!images || !Array.isArray(images) || images.length === 0) {
      return {
        statusCode: 400,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ error: 'Debe enviar al menos una imagen en base64.' }),
      };
    }

    if (!type || !['ingreso', 'gasto'].includes(type)) {
      return {
        statusCode: 400,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ error: 'Tipo inválido. Use "ingreso" o "gasto".' }),
      };
    }

    // Limitar a 5 imágenes por request
    if (images.length > 5) {
      return {
        statusCode: 400,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ error: 'Máximo 5 imágenes por solicitud.' }),
      };
    }

    // Inicializar Gemini
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY no está configurada.');
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });

    const Model = type === 'ingreso' ? Ingreso : Gasto;
    const results = [];

    // Procesar cada imagen
    for (let i = 0; i < images.length; i++) {
      try {
        const imageBase64 = images[i];

        // Detectar tipo MIME (asumir PNG si no se especifica)
        let mimeType = 'image/png';
        let cleanBase64 = imageBase64;

        if (imageBase64.startsWith('data:')) {
          const match = imageBase64.match(/^data:(image\/\w+);base64,/);
          if (match) {
            mimeType = match[1];
            cleanBase64 = imageBase64.replace(/^data:image\/\w+;base64,/, '');
          }
        }

        // Prompt para Gemini Vision — JSON estricto sin markdown
        const prompt = `Extract 'nombre', 'monto' (number), 'descripcion', and 'fecha' (ISO 8601) from this Yape screenshot. Return ONLY a valid JSON object without markdown formatting or code blocks. The JSON must have exactly these fields: {"nombre": "string", "monto": number, "descripcion": "string", "fecha": "ISO 8601 string"}. If a field cannot be determined, use empty string for strings or 0 for numbers.`;

        const imagePart = {
          inlineData: {
            data: cleanBase64,
            mimeType,
          },
        };

        const result = await model.generateContent([prompt, imagePart]);
        const responseText = result.response.text();

        // Parsear respuesta con sanitización
        const parsedData = safeParseGeminiResponse(responseText);

        // Preparar documento
        const docData = {
          monto: parsedData.monto || 0,
          nombre: parsedData.nombre ? String(parsedData.nombre).trim().substring(0, 200) : '',
          descripcion: parsedData.descripcion
            ? String(parsedData.descripcion).trim().substring(0, 500)
            : 'Captura Yape procesada',
          fecha: parsedData.fecha ? new Date(parsedData.fecha) : new Date(),
          tipo_registro: 'ai_yape',
        };

        // Cifrar y guardar
        const encryptedData = encryptDocument(docData);
        const saved = await Model.create(encryptedData);

        results.push({
          ...docData,
          saved: true,
          id: saved._id.toString(),
          captureIndex: i + 1,
        });
      } catch (imgError) {
        console.error(`[upload-yape] Error procesando imagen ${i + 1}:`, imgError.message);
        results.push({
          nombre: '',
          monto: 0,
          descripcion: `Error procesando captura ${i + 1}`,
          fecha: new Date().toISOString(),
          saved: false,
          error: imgError.message,
          captureIndex: i + 1,
        });
      }
    }

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({ results }),
    };
  } catch (error) {
    console.error('[upload-yape] Error:', error.message);
    return {
      statusCode: 500,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Error interno del servidor.' }),
    };
  }
};

/**
 * Parsea de forma segura la respuesta de Gemini, limpiando posibles
 * artefactos de markdown o texto extra.
 * @param {string} text - Respuesta raw de Gemini.
 * @returns {Object} - Datos parseados.
 */
function safeParseGeminiResponse(text) {
  let cleaned = text.trim();

  // Remover bloques de código markdown si existen
  cleaned = cleaned.replace(/```json\s*/gi, '').replace(/```\s*/g, '');

  // Remover cualquier texto antes del primer { y después del último }
  const firstBrace = cleaned.indexOf('{');
  const lastBrace = cleaned.lastIndexOf('}');

  if (firstBrace !== -1 && lastBrace !== -1) {
    cleaned = cleaned.substring(firstBrace, lastBrace + 1);
  }

  try {
    const parsed = JSON.parse(cleaned);

    // Asegurar tipos correctos
    return {
      nombre: typeof parsed.nombre === 'string' ? parsed.nombre : '',
      monto: typeof parsed.monto === 'number' ? parsed.monto : parseFloat(parsed.monto) || 0,
      descripcion: typeof parsed.descripcion === 'string' ? parsed.descripcion : '',
      fecha: typeof parsed.fecha === 'string' ? parsed.fecha : new Date().toISOString(),
    };
  } catch (parseError) {
    console.error('[upload-yape] Error parseando respuesta Gemini:', parseError.message);
    console.error('[upload-yape] Respuesta raw:', text);

    // Intentar extraer con regex como fallback
    return {
      nombre: extractField(text, 'nombre') || '',
      monto: parseFloat(extractField(text, 'monto')) || 0,
      descripcion: extractField(text, 'descripcion') || 'Extracción parcial',
      fecha: extractField(text, 'fecha') || new Date().toISOString(),
    };
  }
}

/**
 * Extrae un campo de un texto con regex como fallback.
 * @param {string} text - Texto fuente.
 * @param {string} field - Nombre del campo.
 * @returns {string|null}
 */
function extractField(text, field) {
  const regex = new RegExp(`"${field}"\\s*:\\s*"?([^",}]+)"?`, 'i');
  const match = text.match(regex);
  return match ? match[1].trim() : null;
}
