# Rapicosturas: arquitectura web, PWA, datos y notificaciones

Fecha: 29 de octubre de 2026. Versión examinada: `rapicostura-web` 1.2.0.

## Alcance y procedencia

Este documento describe código local de `/home/ditox/Documents/VibeCoding/Rapicostura/app`, identificado por el README como proyecto activo. La carpeta indicada inicialmente en el chat, `GastosClaros/Rapicostura`, no existe en esta sesión. No se verificó el despliegue remoto ni se consultaron credenciales. Los ejemplos reducidos no reemplazan los archivos completos de la aplicación.

## 1. Qué hace la aplicación

Rapicostura registra envíos entre sedes y usuarias, adjunta fotos, video o audio y confirma recepción en destino. La dueña dispone de supervisión, gestión de usuarias y biblioteca de tutoriales. Las trabajadoras seleccionan libremente sede o usuaria: esa selección no equivale a autenticación individual. El bot de postulantes y visitas todavía está desconectado.

## 2. Arquitectura general

```text
Navegador / PWA instalada
  ├─ HTML + CSS + JavaScript → archivos estáticos en Netlify
  ├─ /api/v1/* → Netlify Function api → servicios Node.js
  │                                    ├─ MongoDB Atlas: documentos
  │                                    ├─ R2: firma y gestión de archivos
  │                                    └─ Web Push: avisos a destinos
  ├─ URL firmada → transferencia directa al bucket privado R2
  └─ service worker → caché de interfaz y recepción de Push
Netlify Function expire-evidence → limpieza horaria MongoDB + R2
```

Frontend y backend se publican en un mismo sitio; MongoDB y R2 son servicios externos. R2 almacena archivos, no sustituye la base documental.

## 3. Estructura del proyecto

Rutas relativas a `app/`:

| Ruta | Responsabilidad |
|---|---|
| `index.html` | Documento inicial y contenedores de la interfaz |
| `src/web/app.js` | Pantallas, navegación, instalación y eventos |
| `src/web/styles.css` | Diseño adaptable |
| `src/web/api.js` | Cliente de API y modo demo |
| `src/web/model.js` | Modelo del cliente |
| `src/web/uploads.js` | Cargas de medios |
| `src/web/recording.js` | Cámara y grabación |
| `src/web/pattern.js` | Patrón de acceso de dueña |
| `src/web/push.js` | Permiso y suscripción Web Push |
| `server/service.mjs` | Rutas y operaciones de negocio |
| `server/domain.mjs` | Validaciones y reglas |
| `server/auth.mjs` | Acceso y sesiones |
| `server/infrastructure.mjs` | Conexión MongoDB y cliente S3 para R2 |
| `server/push.mjs` | Validación de suscripciones y envío Push |
| `server/cleanup.mjs` | Caducidad y eliminación |
| `netlify/functions/api.mjs` | Entrada HTTP del backend |
| `netlify/functions/expire-evidence.mjs` | Tarea horaria |
| `scripts/build-app.mjs` | Compilación y generación PWA |
| `public/` | Salida generada para publicar |

El frontend usa JavaScript modular y esbuild, sin requerir React. El backend usa Node.js, `mongodb`, AWS SDK compatible con S3 y `web-push`.

## 4. Conexiones y persistencia

### MongoDB Atlas

`database(env)` mantiene una promesa de conexión reutilizable con `MongoClient`, pool máximo de cinco conexiones y tiempo de selección de servidor de siete segundos. Reinicia esa referencia si falla la conexión. Base predeterminada: `rapicostura`.

Entre las colecciones observadas están `shipments`, `videos`, `media`, `pushSubscriptions`, `sessions` y `rateLimits`. Se crean índices por origen, destino, fecha y entidad, además de índices únicos de `requestId` en envíos y videos. Sesiones y límites de solicitudes tienen índices TTL por `expiresAt`; esto no significa que todos los documentos tengan eliminación TTL.

### Cloudflare R2

El servidor crea un `S3Client` con endpoint de la cuenta, región `auto` y bucket predeterminado `rapicosturas`. Genera URLs firmadas de carga, lectura y partes multipart; las de carga observadas duran 900 segundos. El navegador transfiere archivos mediante esas URLs. El backend comprueba metadatos y gestiona finalización, copias y borrado.

Las evidencias e historial vencen 72 horas después de confirmar recepción. La limpieza se ejecuta cada hora; el bloqueo lógico al vencer y el borrado físico pueden ocurrir en momentos distintos. Los envíos en camino se conservan. Los tutoriales permanecen hasta su eliminación por la dueña. Las cargas multipart incompletas vencen según su sesión; la documentación local indica 24 horas.

### Variables de entorno

Configurar en el servidor: `MONGODB_URI`, `MONGODB_DB`, `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`, `SESSION_SECRET`, `OWNER_INITIAL_PATTERN`, `APP_ORIGIN`, `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY` y `VAPID_SUBJECT`.

`SESSION_SECRET` requiere al menos 32 caracteres. `APP_ORIGIN` usa la variable `URL` de Netlify cuando no se define. Confirmar la lista en `.env.example` y `server/infrastructure.mjs`. No publicar `.env`, URI de MongoDB, secreto R2, patrón inicial ni clave VAPID privada. La clave VAPID pública se entrega deliberadamente al cliente.

## 5. Cómo está implementada la PWA

El build genera `manifest.webmanifest` y `sw.js`; no hay que buscarlos únicamente como fuentes independientes. El manifest incluye identidad `/`, nombre Rapicostura, idioma `es-PE`, `start_url: '/'`, alcance `/`, modo `standalone`, colores e iconos PNG de 192 y 512 píxeles.

El service worker precarga HTML, JavaScript, CSS, manifest, iconos y logo. Usa un nombre de caché con hash y elimina cachés anteriores de Rapicostura al activarse. Para navegación intenta red y recurre al HTML guardado si falla. Para recursos conocidos consulta caché primero. Excluye API, Functions, peticiones externas y métodos distintos de GET.

Esto permite recuperar la interfaz después de una primera carga correcta. No implementa una cola de envíos sin conexión ni garantiza trabajar con datos compartidos sin internet. Tampoco garantiza cargas cuando el teléfono suspende la aplicación. La actualización contempla un mensaje `SKIP_WAITING`.

## 6. Rescatar «Instalar app»

La opción ya existe en el menú de perfil, con `data-action="install-app"`. `installApp()` verifica primero `display-mode: standalone` o `navigator.standalone`. Si detecta instalación, informa que se abra desde el icono.

Cuando hay un evento de instalación retenido, llama a `prompt()` y revisa `userChoice`. Si no está disponible, presenta instrucciones: en dispositivos Apple, Safari → Compartir → Añadir a pantalla de inicio; en otros, menú del navegador → Instalar app o Añadir a pantalla de inicio.

Para preservar esta funcionalidad al reutilizar el proyecto, conservar conjuntamente:

1. Opción del menú y controlador `installApp()` en `src/web/app.js`.
2. Captura de `beforeinstallprompt` y tratamiento de `appinstalled` del mismo módulo.
3. Registro del service worker y generación del manifest en el build.
4. Iconos, enlaces del HTML y publicación HTTPS.

Instalar conserva la misma aplicación web y backend, añade una entrada en el dispositivo y permite abrirla en modo independiente. No produce por sí solo un APK ni una publicación en tiendas. El diálogo programático depende del navegador; `beforeinstallprompt` no tiene soporte universal. Véase [MDN: instalación PWA](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Guides/Making_PWAs_installable).

## 7. Estructura de notificaciones

### Activación

`pushSupported()` exige Service Worker, PushManager y Notification, y excluye el modo demo. `activatePush(entity)` solicita permiso, obtiene la configuración de `/push/config`, espera `navigator.serviceWorker.ready`, reutiliza o crea una suscripción con `applicationServerKey` y la registra en el backend.

Las rutas siguientes son relativas al prefijo público `/api/v1`:

| Método y ruta | Función |
|---|---|
| `GET /push/config` | Indica disponibilidad y devuelve la clave pública |
| `PUT /push/subscription` | Vincula suscripción con entidad destino |
| `DELETE /push/subscription` | Retira la suscripción registrada |

La colección `pushSubscriptions` conserva endpoint, claves `p256dh` y `auth`, entidad y fechas. El identificador es un hash SHA-256 del endpoint. Al cambiar de sede o usuaria se sincroniza el destino; seleccionar `all` elimina la vinculación registrada.

### Envío y recepción

`sendShipmentPush()` busca hasta 50 suscripciones del destino y envía mediante `web-push`, con TTL de 86400 segundos y timeout de 3500 ms. Detecta endpoints inválidos por respuestas 404 o 410. Sin las tres variables VAPID, no envía avisos.

Ejemplo de carga útil equivalente a `shipmentNotice()`:

```json
{
  "title": "Nuevo envío para ti 📦",
  "body": "Se te envió un material desde Taller A. ¡Haz la recepción! 📦✨",
  "url": "/envios?tab=recepcion&site=destino&shipment=identificador",
  "tag": "shipment-identificador"
}
```

El evento `push` del service worker muestra la notificación con icono, cuerpo, etiqueta y URL. Rechaza URLs de otro origen. `notificationclick` cierra el aviso y navega/enfoca una ventana existente o abre una nueva en Recepción. El permiso de avisos es independiente de instalar la app; instalarla no lo concede automáticamente.

El servidor valida los proveedores de endpoints admitidos. Los fallos Push no deben confundirse con un fallo del envío registrado: la documentación local recoge pruebas que comprueban esa separación.

### Otros avisos

Los indicadores de almacenamiento de tutoriales a 10, 50 y 80 GB son avisos de interfaz sobre una referencia de 100 GB. No son una cuota gratuita garantizada ni evidencia de una campaña Push de almacenamiento. Los mensajes temporales de interfaz tampoco equivalen a notificaciones del sistema.

## 8. Index inicial y publicación en Netlify

El HTML fuente real es `app/index.html`; incluye contenedores y diálogos específicos que necesita `app.js`. El siguiente esqueleto ilustra sus enlaces iniciales, pero no sustituye todo el DOM de la aplicación:

```html
<!doctype html>
<html lang="es-PE">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="theme-color" content="#20152c">
  <meta name="description" content="Envíos y recepción entre talleres de Rapicostura">
  <title>Rapicostura</title>
  <link rel="manifest" href="/manifest.webmanifest">
  <link rel="icon" href="/icons/icon.svg">
  <link rel="apple-touch-icon" href="/icons/icon-192.png">
  <link rel="stylesheet" href="/src/web/styles.css">
  <script type="module" src="/src/web/app.js"></script>
</head>
<body>
  <!-- Mantener aquí los contenedores y diálogos del index.html original. -->
  <noscript>Activa JavaScript para usar Rapicostura.</noscript>
</body>
</html>
```

El build reemplaza las referencias fuente por archivos `app.<hash>.js` y `app.<hash>.css`, copia recursos y genera manifest y worker. Para alojar la aplicación completa debe publicarse el resultado del build con sus Functions; subir solamente el HTML no configura backend, bases ni notificaciones.

Configuración que documenta el repositorio:

| Opción | Valor |
|---|---|
| Directorio base | `app` |
| Comando de build | `npm run build` |
| Directorio publicado | `public` |
| Functions | `netlify/functions` |
| Node | 22; package exige >=22.13 |

`app/netlify.toml` redirige `/api/v1/*` a `/.netlify/functions/api/:splat` antes del fallback de navegación `/*` → `/index.html`. Esto permite abrir directamente rutas como `/envios` o `/videos`.

También fija API con `no-store`, HTML y worker con `no-cache`, y una política CSP que autoriza los recursos propios y las conexiones necesarias a R2. Conservar el archivo completo, no solamente las redirecciones.

Pasos de despliegue:

1. Conectar el repositorio correcto y seleccionar la rama que se publicará.
2. Aplicar los directorios y comando anteriores.
3. Añadir variables privadas en Netlify.
4. Permitir el acceso del backend a Atlas y ajustar CORS del bucket al origen HTTPS final.
5. Publicar y comprobar estáticos, API y función horaria.
6. Probar instalación y notificaciones en dispositivos reales.

## 9. Qué está comprobado y qué queda por validar

Esta revisión inspeccionó archivos; no ejecutó pruebas ni modificó producción. `docs/VERIFICACION.md` registra verificaciones anteriores de build, API, R2 y navegador, con sus propios límites.

Ese documento señala que sigue pendiente validar entrega Push entre dos dispositivos reales tras configurar VAPID en Netlify. No se puede afirmar desde esta revisión que esté funcionando en producción. Comprobar además instalación Android/iPhone, permisos de cámara y micrófono reales, apertura desde notificación, cambio de destino y ejecuciones horarias de limpieza.

Para aceptar el despliegue: la aplicación abre por enlace y por icono; las rutas profundas cargan; crea y recibe un envío entre destinos; la evidencia se almacena en R2; el aviso llega sólo al destino seleccionado; al pulsarlo abre Recepción; y el vencimiento respeta las 72 horas posteriores a recepción.

## 10. Fuentes de mantenimiento

Las fuentes principales son `README.md`, `app/package.json`, `app/netlify.toml`, `app/index.html`, `app/scripts/build-app.mjs`, `app/src/web/app.js`, `app/src/web/push.js`, `app/server/infrastructure.mjs`, `app/server/service.mjs`, `app/server/push.mjs` y `app/netlify/functions/expire-evidence.mjs` del proyecto inspeccionado.

Complementar con `app/docs/DESPLIEGUE_NETLIFY.md`, `MAPA_DEL_PROYECTO.md` y `VERIFICACION.md`. Para compatibilidad de instalación, consultar [MDN: diálogo de instalación](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/How_to/Trigger_install_prompt).
