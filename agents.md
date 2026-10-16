# GastosClaros — Arquitectura del Proyecto

## Stack Tecnológico

| Capa        | Tecnología                          | Detalle                                                    |
|-------------|-------------------------------------|------------------------------------------------------------|
| Frontend    | Flutter (Dart)                      | App móvil, state management con Riverpod                   |
| Backend     | Node.js (Serverless)                | Netlify Functions, REST API                                |
| Base de Datos | MongoDB Atlas                     | Colecciones dedicadas dentro de BD existente               |
| IA          | Google Gemini API (Vision)          | Extracción de datos desde capturas Yape                    |
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
                                                    │  (Vision / AI)   │
                                                    └─────────────────┘
```

### Flujo detallado:
1. **Flutter** envía requests HTTP (GET/POST) a los endpoints de Netlify Functions.
2. **Netlify Functions** procesa la request, conecta con MongoDB Atlas (conexión cacheada para reducir cold-start).
3. Para extracción IA: Backend recibe imágenes base64 → las envía a **Gemini Vision API** → parsea JSON estricto → guarda en MongoDB → retorna datos al Frontend.
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
- **Descripción:** Recibe imágenes (base64/multipart), extrae datos con Gemini Vision, guarda en MongoDB.
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
      "saved": true
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
