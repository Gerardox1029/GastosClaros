# GastosClaros — Memory & State Log

> Archivo de estado del agente: rastrea lo construido, lo pendiente, errores comunes y decisiones técnicas.
> Última actualización: 2026-10-16 (UTC-5, Perú)

---

## ✅ Archivos Completados

### 📁 Raíz del Proyecto
| Archivo | Descripción | Estado |
|---|---|---|
| `agents.md` | Arquitectura, endpoints REST, esquemas MongoDB | ✅ Listo |
| `memory.md` | Estado del agente y logs de desarrollo | ✅ Listo |
| `design_system.md` | Sistema de diseño: colores, tipografía, animaciones | ✅ Listo |

### 📁 Backend (`/backend`)
| Archivo | Descripción | Estado |
|---|---|---|
| `package.json` | Dependencias Node.js (mongoose, @google/generative-ai, dotenv) | ✅ Listo |
| `netlify.toml` | Configuración de funciones serverless Netlify | ✅ Listo |
| `.env.example` | Variables de entorno de referencia (MONGO_URI, GEMINI_API_KEY, ENCRYPTION_KEY) | ✅ Listo |
| `.gitignore` | Excluye `.env`, `node_modules` | ✅ Listo |
| `lib/db.js` | Conexión cacheada a MongoDB Atlas (patrón singleton) | ✅ Listo |
| `lib/encryption.js` | Cifrado/descifrado AES-256-CBC para campos `nombre` y `descripcion` | ✅ Listo |
| `models/Ingreso.js` | Mongoose schema para colección `gastosclaros_ingresos` | ✅ Listo |
| `models/Gasto.js` | Mongoose schema para colección `gastosclaros_gastos` | ✅ Listo |
| `netlify/functions/balance.js` | `GET /api/balance` — saldo con filtros 1D/7D/14D/1M | ✅ Listo |
| `netlify/functions/history.js` | `GET /api/history/:type` — historial ingresos/gastos | ✅ Listo |
| `netlify/functions/manual-entry.js` | `POST /api/manual-entry` — registro manual con cifrado | ✅ Listo |
| `netlify/functions/upload-yape.js` | `POST /api/upload-yape` — extracción IA con Gemini Vision | ✅ Listo |

### 📁 Frontend (`/frontend`)
| Archivo | Descripción | Estado |
|---|---|---|
| `pubspec.yaml` | Dependencias Flutter (riverpod, http, image_picker, omni_datetime_picker…) | ✅ Listo |
| `analysis_options.yaml` | Reglas de análisis estático Dart | ✅ Listo |
| `lib/main.dart` | Entry point: ProviderScope + MaterialApp con AppTheme | ✅ Listo |
| `lib/core/theme.dart` | AppColors, AppSpacing, AppRadius, TextTheme (Poppins + SpaceGrotesk) | ✅ Listo |
| `lib/core/api_config.dart` | URLs base de Netlify Functions por entorno | ✅ Listo |
| `lib/features/splash/splash_screen.dart` | Pantalla de carga con logo, subtítulo y fade-out a Dashboard | ✅ Listo |
| `lib/features/saldo/saldo_screen.dart` | Panel saldo actual, filtro tiempo, historial ingresos, botón Agregar Saldo | ✅ Listo |
| `lib/features/gastos/gastos_screen.dart` | Panel total gastos, historial gastos staggered, botón Agregar Gasto | ✅ Listo |
| `lib/features/dashboard/dashboard_screen.dart` | BottomAppBar con notch, FAB "+" central, IndexedStack, sheet de opciones | ✅ Listo |
| `lib/shared/models/registro.dart` | Modelo Dart para ingresos/gastos con helpers `nombreTruncado`, `formatFecha` | ✅ Listo |
| `lib/shared/models/balance_response.dart` | Modelo Dart de respuesta del endpoint `/balance` | ✅ Listo |
| `lib/shared/models/yape_extraction_result.dart` | Modelo Dart de resultado de extracción IA Yape | ✅ Listo |
| `lib/shared/services/api_service.dart` | Cliente HTTP: getBalance, getHistory, postManualEntry, uploadYape | ✅ Listo |
| `lib/shared/providers/app_providers.dart` | Providers Riverpod: balanceProvider, gastosHistoryProvider, selectedTabProvider… | ✅ Listo |
| `lib/shared/widgets/loading_spinner.dart` | Spinner animado reutilizable con pulso | ✅ Listo |
| `lib/shared/widgets/currency_widgets.dart` | MontoText, formatMonto, formatFecha | ✅ Listo |
| `lib/shared/widgets/add_entry_modal.dart` | Modal completo: upload Yape, progreso IA por imagen, formulario manual, omni_datetime_picker | ✅ Listo |

---

## ⏳ Archivos Pendientes

### 📁 Frontend — Verificar / Completar

| Archivo | Descripción | Prioridad |
|---|---|---|
| `lib/main.dart` | Verificar que navega a `DashboardScreen` tras splash | 🔴 Alta |
| `frontend/assets/` | Carpeta `assets/fonts/` con Poppins y SpaceGrotesk (si se descargan localmente) | 🟡 Media |
| `frontend/android/` | Configuración Android mínima generada por `flutter create` | 🟡 Media |
| `frontend/ios/` | Configuración iOS mínima generada por `flutter create` | 🟡 Media |
| `frontend/test/` | Tests unitarios básicos (widget tests para screens críticas) | 🟢 Baja |

### 📁 Backend — Verificar / Completar

| Archivo | Descripción | Prioridad |
|---|---|---|
| `backend/.env` | Archivo `.env` real con credenciales del usuario (no commitable) | 🔴 Alta |
| `backend/node_modules/` | Instalar dependencias con `npm install` dentro de `/backend` | 🔴 Alta |

### 📁 Deployment

| Tarea | Descripción | Prioridad |
|---|---|---|
| Configurar Netlify | Conectar repo a Netlify, definir env vars en el panel | 🔴 Alta |
| MongoDB Atlas | Crear cluster, obtener URI, crear collections `gastosclaros_ingresos` y `gastosclaros_gastos` | 🔴 Alta |
| Gemini API Key | Obtener API key desde Google AI Studio y añadirla al `.env` | 🔴 Alta |

---

## 🔄 Secciones Frecuentemente Modificadas

| Sección / Archivo | Razón | Última Modificación |
|---|---|---|
| `app_providers.dart` | Agregar nuevos providers o ajustar lógica de estado | 2026-10-15 |
| `add_entry_modal.dart` | Modal con lógica compleja (upload + IA + formulario) — más propenso a bugs | 2026-10-15 |
| `theme.dart` | Ajustes de colores, radios o tipografía según feedback visual | 2026-10-15 |
| `upload-yape.js` | Lógica de Gemini Vision + parsing JSON — área sensible | 2026-10-15 |

---

## 🐛 Errores Comunes / Riesgos

| # | Descripción | Archivo(s) | Estado | Solución |
|---|---|---|---|---|
| 1 | `ENCRYPTION_KEY` debe ser exactamente 32 chars en Base64/hex | `encryption.js`, `.env` | ⚠️ Pendiente verificar | Documentado en `.env.example` |
| 2 | Cold-start en Netlify Functions puede tardar 1-3s en primer request | `db.js` | ⚠️ Mitigado | Conexión cacheada con `cachedDb` |
| 3 | `omni_datetime_picker` puede requerir ajuste de versión en `pubspec.yaml` | `pubspec.yaml` | ⚠️ Pendiente probar | Revisar compatibilidad con Flutter 3.x |
| 4 | Gemini Vision puede devolver JSON malformado — necesita fallback | `upload-yape.js` | ⚠️ Implementado parcialmente | Regex + JSON.parse con try/catch |

---

## ⚙️ Variables de Entorno Requeridas

| Variable | Servicio | Archivo | Estado |
|---|---|---|---|
| `MONGO_URI` | MongoDB Atlas | `.env` | ⏳ Usuario debe configurar |
| `GEMINI_API_KEY` | Google Gemini AI | `.env` | ⏳ Usuario debe configurar |
| `ENCRYPTION_KEY` | Cifrado AES-256 (32 chars) | `.env` | ⏳ Usuario debe configurar |

---

## 📌 Decisiones Técnicas

| Decisión | Razón | Fecha |
|---|---|---|
| Riverpod sobre Provider | Más type-safe, mejor testabilidad, compile-time safety | 2026-10-15 |
| Netlify Functions sobre Express | Serverless = zero infra management, auto-scaling | 2026-10-15 |
| AES-256-CBC para cifrado | Simplicidad, rendimiento, adecuado para campos de texto cortos | 2026-10-15 |
| Conexión MongoDB cacheada | Reusar conexión entre invocaciones warm de Lambda | 2026-10-15 |
| IndexedStack para navegación | Preserva el estado de cada tab sin rebuild | 2026-10-15 |
| BottomAppBar con notch circular | FAB "+" integrado visualmente como acción principal | 2026-10-15 |

---

## 📋 Próximos Pasos (Orden de Ejecución)

1. **Verificar `main.dart`** → confirmar navegación SplashScreen → DashboardScreen.
2. **Verificar `add_entry_modal.dart`** → revisar integración completa con providers.
3. **Ejecutar `flutter pub get`** en `/frontend` para verificar dependencias.
4. **Ejecutar `npm install`** en `/backend` para instalar dependencias Node.
5. **Configurar `.env`** real con credenciales (MongoDB, Gemini, ENCRYPTION_KEY).
6. **Deploy a Netlify** → conectar repo + configurar env vars en el panel.
7. **Prueba end-to-end** → Splash → Dashboard → Agregar entrada manual → Ver historial.

## Actualización — 16/10/2026

Se reemplazó Gemini Vision por OpenCV/Tesseract locales en el backend. Gemini se reutiliza en el asistente financiero con selector de período y consulta de datos almacenados. Se añadieron edición y eliminación desde ambos historiales, conservando cifrado AES y actualizando saldo e historiales. El formulario de una captura ya guardada actualiza su registro para evitar duplicados. Los requisitos históricos sobre Gemini Vision quedan sustituidos por esta implementación.

## Verificación de APK — 16/10/2026

Se corrigió el permiso INTERNET de Android y la URL de producción a `https://gastosclaross.netlify.app/api`, confirmada por el usuario. El modelo `gemini-2.5-flash` respondió 404 por no estar disponible para esta cuenta; se actualizó a `gemini-3.8-flash`, verificado contra Gemini y MongoDB con respuesta correcta del asistente. Las 15 pruebas del backend y 11 de Flutter pasan. Se preparan APK release y vista previa web local. La firma release usa la clave debug ya configurada por el proyecto, adecuada para instalación directa y pruebas.

## Corrección con comprobante real — 16/10/2026

Se reprodujo que PSM 6 omitía el monto de gran tamaño. Se corrigió mediante detección de la tarjeta clara con OpenCV y Tesseract PSM 3/11; la captura aportada se leyó con todos los campos y la nota sin etiqueta. Extracción separada de persistencia: subir imágenes no altera el saldo; Guardar usa identidad del comprobante y upsert atómico para prevenir duplicados por reintentos. La UI bloquea el doble envío y mantiene la revisión individual de múltiples capturas. Las imágenes privadas de prueba no se incluyen en Git.

## Cambios — 29/10/2026

Asistente con modelo fijo `gemini-3.8-flash`. Navegación Saldo / + / Gastos fija arriba. Historial inicia en 3 y aumenta de 5 en 5, conservando la lista durante la carga y bloqueando clics simultáneos. Orden estable por fecha e ID.
