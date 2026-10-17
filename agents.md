# GastosClaros — Arquitectura del Proyecto

## Stack Tecnológico

| Capa        | Tecnología                          | Detalle                                                    |
|-------------|-------------------------------------|------------------------------------------------------------|
| Frontend    | Flutter (Dart)                      | App móvil, state management con Riverpod                   |
| Backend     | Node.js (Serverless)                | Netlify Functions, REST API                                |
| Base de Datos | MongoDB Atlas                     | Colecciones dedicadas dentro de BD existente               |
| IA          | OpenCV + Tesseract / Gemini API          | OCR local de Yape / asistente financiero                    |
| Seguridad   | AES encryption (`crypto` de Node.js)| Cifrado de campos sensibles (`nombre`, `descripcion`)      |

---

## Flujo de Conexión Frontend ↔ Backend

```
┌──────────────────┐        HTTPS / REST         ┌──────────────────────┐
│   Flutter App    │ ──────────────────────────▶  │  Netlify Functions   │
│  (Mobile Client) │ ◀──────────────────────────  │  (Node.js Serverless)│
└──────────────────┘        JSON Responses        └──────────┬───────────┘
                                                             │
                                                    ┌────────▼────────┐
                                                    │  MongoDB Atlas   │
                                                    │  (Cloud DB)      │
                                                    └────────┬────────┘
                                                             │
                                                    ┌────────▼────────┐
                                                    │  Gemini API      │
                                                    │  (Chat / AI)   │
                                                    └─────────────────┘
```

### Flujo detallado:
1. **Flutter** envía requests HTTP (GET/POST) a los endpoints de Netlify Functions.
2. **Netlify Functions** procesa la request, conecta con MongoDB Atlas (conexión cacheada para reducir cold-start).
3. Para OCR: Backend recibe imágenes base64 → preprocesa con OpenCV → reconoce texto con Tesseract (español) → extrae y valida campos → retorna datos al Frontend → el usuario revisa y guarda en MongoDB. Las capturas no se envían a Gemini.
4. Los campos `nombre` y `descripcion` se **cifran con AES** antes de guardar y se **descifran** al leer.

---

## REST API — Endpoints

### `GET /api/balance`
- **Descripción:** Calcula el saldo actual (Total Ingresos − Total Gastos).
- **Query Params:** `filter` → `1D` | `7D` | `14D` | `1M` (período de cálculo).
- **Response:**
```json
{
  "saldo": 150.50,
  "total_ingresos": 500.00,
  "total_gastos": 349.50,
  "filtro": "7D"
}
```

### `GET /api/history/:type`
- **Descripción:** Obtiene historial reciente de ingresos o gastos.
- **Params:** `:type` → `ingresos` | `gastos`.
- **Query Params:** `limit` (default: 3).
- **Response:**
```json
{
  "data": [
    {
      "_id": "...",
      "monto": 12.50,
      "nombre": "Yape Recibido",
      "descripcion": "Pago almuerzo",
      "fecha": "2026-10-15T14:30:00-05:00",
      "tipo_registro": "manual"
    }
  ]
}
```

### `POST /api/upload-yape`
- **Descripción:** Recibe imágenes base64 y extrae datos con OpenCV y Tesseract locales, sin guardar en MongoDB.
- **Body:**
```json
{
  "images": ["base64string1", "base64string2"],
  "type": "ingreso" | "gasto"
}
```
- **Response:**
```json
{
  "results": [
    {
      "nombre": "Juan Pérez",
      "monto": 25.00,
      "descripcion": "Pago por servicio",
      "fecha": "2026-10-15T10:00:00-05:00",
      "saved": false,
      "extracted": true,
      "receiptKey": "sha256-del-comprobante"
    }
  ]
}
```

### `POST /api/manual-entry`
- **Descripción:** Guarda un registro manual (ingreso o gasto).
- **Body:**
```json
{
  "monto": 15.00,
  "nombre": "Grifo Repsol",
  "descripcion": "Gasolina 90",
  "fecha": "2026-10-15T08:00:00-05:00",
  "type": "gasto"
}
```
- **Response:**
```json
{
  "success": true,
  "id": "652f..."
}
```

---

## Esquemas de Base de Datos (MongoDB Atlas)

### Colección: `gastosclaros_ingresos`

| Campo            | Tipo      | Requerido | Descripción                                      |
|------------------|-----------|-----------|--------------------------------------------------|
| `_id`            | ObjectId  | Auto      | Identificador único                              |
| `monto`          | Number    | Sí        | Monto del ingreso                                |
| `nombre`         | String    | No        | Nombre (cifrado AES)                             |
| `descripcion`    | String    | Sí        | Descripción (cifrado AES)                        |
| `fecha`          | Date      | Sí        | Fecha y hora del ingreso (UTC-5)                 |
| `tipo_registro`  | String    | Sí        | `"manual"` o `"ai_yape"`                         |
| `createdAt`      | Date      | Auto      | Timestamp de creación                            |
| `updatedAt`      | Date      | Auto      | Timestamp de última actualización                |

### Colección: `gastosclaros_gastos`

| Campo            | Tipo      | Requerido | Descripción                                      |
|------------------|-----------|-----------|--------------------------------------------------|
| `_id`            | ObjectId  | Auto      | Identificador único                              |
| `monto`          | Number    | Sí        | Monto del gasto                                  |
| `nombre`         | String    | No        | Nombre (cifrado AES)                             |
| `descripcion`    | String    | Sí        | Descripción (cifrado AES)                        |
| `fecha`          | Date      | Sí        | Fecha y hora del gasto (UTC-5)                   |
| `tipo_registro`  | String    | Sí        | `"manual"` o `"ai_yape"`                         |
| `createdAt`      | Date      | Auto      | Timestamp de creación                            |
| `updatedAt`      | Date      | Auto      | Timestamp de última actualización                |

---

## Convenciones del Proyecto

- **Localización:** Todas las fechas en UTC-5 (Perú), moneda `S/.`, idioma `es-419`.
- **Seguridad:** Variables sensibles en `.env` (excluido vía `.gitignore`). Cifrado AES para `nombre` y `descripcion`.
- **Estado (Flutter):** Riverpod para state management. Widgets modulares, sin anidamiento profundo.
- **Loading:** Todo proceso asíncrono muestra spinner dinámico con transiciones suaves.

## Funciones nuevas — 16/10/2026

- **OCR local en el backend:** OpenCV.js (WebAssembly) transforma la imagen a escala de grises, reduce ruido y aplica umbral de Otsu. Sharp decodifica PNG/JPEG/WebP; Tesseract.js reconoce español con datos incluidos en el paquete. No requiere binarios Python ni descargar modelos al atender solicitudes. La interfaz conserva la selección de capturas, progreso y tarjetas. Si monto o fecha no se pueden leer, esa captura muestra un error para su revisión manual; no se guarda con datos inventados.
- **Asistente financiero:** `POST /api/financial-assistant`, body `{ message, period, history? }`. `period`: `1D` (hoy), `7D` o `1M` (últimos 30 días), incluyendo el día actual según UTC-5. Consulta ambas colecciones; agrega todos los registros del período y envía a Gemini los totales y hasta 100 movimientos recientes por tipo. `history`: hasta 20 mensajes `{role: "user" | "model", text}`. Respuesta: `{ answer, desde, hasta }`, con fin exclusivo. La burbuja lateral abre el chat y permite elegir período y generar reportes. Cambiar período inicia una conversación nueva.
- **Editar/eliminar:** `PATCH /api/record`, body `{ id, type, monto, nombre, descripcion, fecha }`; `DELETE /api/record`, body `{ id, type }`. `type`: `ingreso` o `gasto`. Valida ObjectId y campos, cifra datos sensibles y conserva el origen del registro. Responde 404 si ya no existe. Ambos historiales tienen lápiz y abren el formulario actual, con eliminación dentro del modal.
- **Evitar duplicados:** subir una captura no modifica el saldo; el guardado explícito usa una identidad estable y una inserción atómica que impide repetir el comprobante.

### Configuración y verificación

`GEMINI_API_KEY` se usa exclusivamente para el chat. `GEMINI_MODEL` permite elegir modelo (predeterminado `gemini-3.8-flash`). MongoDB y cifrado conservan `MONGO_URI` y `ENCRYPTION_KEY`. En Netlify se externalizan OpenCV, Tesseract, los datos españoles y Sharp para incluir los archivos WASM, workers y recursos nativos. Instalar con `npm install` en `backend/`. OCR es local al servidor; la aplicación sigue subiendo las capturas a su backend.

Pruebas: `cd backend && npm test -- --runInBand`; `cd frontend && flutter test`. Las pruebas del asistente y de persistencia usan servicios simulados; la disponibilidad real depende de las credenciales y servicios configurados.

## Corrección OCR y guardado — captura real de Yape

El modo de segmentación de bloque único (PSM 6) omitía el monto en tipografía grande. OpenCV ahora detecta la tarjeta clara del comprobante para excluir el encabezado decorativo; Tesseract usa segmentación automática (PSM 3), con una segunda lectura de texto disperso (PSM 11) sobre escala de grises si la primera no se puede interpretar. Se lee también la nota sin etiqueta situada después de la fecha y el número de operación.

`POST /api/upload-yape` **solo extrae**; ya no conecta con MongoDB ni modifica el saldo. Devuelve `{ extracted: true, saved: false, receiptKey, ...campos }` por captura válida. La app autocompleta el formulario con `extracted`, sin confundir reconocimiento con persistencia. Cada captura se revisa y guarda individualmente; al guardar una, se muestra la siguiente pendiente si hay varias.

`POST /api/manual-entry` acepta `receiptKey` opcional (SHA-256 hexadecimal): el ID del registro se deriva de esa identidad y se usa una inserción atómica con `$setOnInsert`. Reintentar guardar el mismo comprobante no agrega dinero otra vez. La identidad utiliza número de operación, fecha y monto cuando están disponibles, o la imagen como respaldo. Sin `receiptKey`, el formulario manual mantiene su flujo habitual. Los duplicados históricos no se eliminan automáticamente.
