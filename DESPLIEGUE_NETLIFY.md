# GastosClaros: una PWA y una API en un sitio de Netlify

El mismo despliegue sirve `frontend/build/web` y las Functions de `backend/netlify/functions` mediante `/api/*`. MongoDB Atlas sigue siendo externo. No hace falta publicar un segundo sitio para el backend.

## Preparar secretos

En desarrollo, crea `backend/.env` y añade estos nombres. El archivo está ignorado por Git. En Netlify configura **los mismos valores** en **Project configuration → Environment variables**, disponibles para Functions. Netlify no carga `backend/.env` al desplegar.

| Variable | Uso |
|---|---|
| `MONGO_URI` | Cadena de conexión a MongoDB Atlas. |
| `ENCRYPTION_KEY` | Clave de cifrado ya usada por los registros. Conserva la clave existente para poder leer datos antiguos. |
| `APP_PIN` | PIN personal de **6 a 12 dígitos**. No se incluye en el frontend. |
| `SESSION_SECRET` | Secreto aleatorio de al menos 32 caracteres para firmar sesiones. `openssl rand -hex 32` genera uno. Cambiarlo cierra las sesiones existentes. |
| `VAPID_PUBLIC_KEY` | Clave pública Web Push. |
| `VAPID_PRIVATE_KEY` | Clave privada Web Push; solo en Netlify. |
| `VAPID_SUBJECT` | Contacto VAPID, por ejemplo `mailto:tu-correo@ejemplo.com`. |
| `GEMINI_API_KEY` | Opcional, para el asistente financiero. |
| `GEMINI_MODEL` | Opcional, modelo del asistente. |

Genera el par VAPID una sola vez con `cd backend && npx web-push generate-vapid-keys`. Conserva ambos valores para futuros despliegues: cambiar el par obliga a volver a activar avisos en cada dispositivo.

### VAPID y Firebase

GastosClaros utiliza Web Push con la biblioteca `web-push`, igual que la implementación revisada de Rapicostura. La clave VAPID pública permite registrar una suscripción en el navegador y la privada permite al servidor firmar los envíos. Chrome puede utilizar Firebase Cloud Messaging como servicio de entrega, pero esta integración no requiere crear un proyecto Firebase ni configurar su SDK. En iPhone, Web Push utiliza el servicio de Apple.

## Publicar desde Git

1. Este proyecto ya tiene `origin` en GitHub y rama `main`. Desde la raíz, sube los cambios sin incluir el ZIP de referencia ni `.env`:

   ```bash
   git add .gitignore netlify.toml scripts backend frontend DESPLIEGUE_NETLIFY.md
   git commit -m "Unificar PWA y API en Netlify"
   git push origin main
   ```
2. En Netlify, abre el **sitio existente `gastosclaross.netlify.app`**. En **Project configuration → Developer settings → Continuous deployment → Repository**, usa **Link repository** si aún no está conectado o **Manage repository → Link to a different repository** si apunta a otro. Elige este repositorio y la rama de publicación. Así conservas la URL y usas un solo sitio.
3. Deja **Base directory** y **Package directory** vacíos. El `netlify.toml` de la raíz fija `bash scripts/netlify-build.sh` como comando, `frontend/build/web` como directorio publicado y `backend/netlify/functions` como directorio de Functions.
4. Configura las variables de la tabla anterior antes de publicar. Revisa **Project configuration → Developer settings → Continuous deployment → Build settings**: no debe quedar `backend` como base ni `backend/public` como publicación. Si ya habías creado un segundo sitio de frontend, deja de publicarlo después de verificar este despliegue único.
5. En Atlas, permite conexiones desde el entorno de Netlify según la política de red de tu proyecto. Comprueba que el usuario de MongoDB tiene permisos de lectura y escritura sobre la base que usa `MONGO_URI`.
6. Inicia el despliegue. El script instala dependencias Node, descarga Flutter 3.47.7 si no está presente y compila Flutter Web. El despliegue incluye el service worker y las Functions.
7. Comprueba el sitio HTTPS: el PIN debe aparecer primero. `/api/auth-check` sin sesión debe responder 401; con la app abierta debe cargar saldo e historiales.
8. Abre el menú de la esquina superior derecha y prueba **Descargar app**. En iPhone, usa Safari → Compartir → Añadir a pantalla de inicio. En Android, sigue el diálogo del navegador o su menú de instalación.
9. En **dos dispositivos**, inicia sesión con el PIN y toca **Activar avisos** en ambos. Registra un gasto en uno y comprueba que el otro recibe el aviso con la app cerrada. Repite con un saldo. En iPhone/iPad, abre la PWA desde el icono de inicio antes de activar avisos.

## Comportamiento y límites

- El guardado de movimientos funciona aunque falle Web Push. La confirmación dentro de la app aparece después de guardar.
- Los avisos del sistema muestran en el título `+ S/ monto · descripción` para saldo y `− S/ monto · descripción` para gasto. **Estos datos pueden aparecer en la pantalla bloqueada**, como elegiste. Cada dispositivo debe conceder permiso por separado. En iOS/iPadOS, Web Push requiere una PWA añadida a la pantalla de inicio.
- El service worker guarda la interfaz tras la primera carga, pero no guarda movimientos sin conexión. La API siempre requiere internet y PIN.
- El PIN se limita a cinco intentos fallidos por origen durante 15 minutos. Las sesiones firmadas y las suscripciones Push duran 30 días; al volver a abrir la app con una sesión válida se renueva la suscripción. Cambiar `APP_PIN` o `SESSION_SECRET` invalida también los avisos de los dispositivos anteriores. **Cerrar sesión** retira la suscripción Push de ese dispositivo.
- El APK anterior, si existe, deberá actualizarse para enviar la sesión al backend protegido. Esta implementación se centra en la PWA.

Para verificar localmente: `cd backend && npm test -- --runInBand`; `cd frontend && flutter test`; `cd frontend && flutter build web --release --pwa-strategy=none`. En producción, prueba Push real en dos dispositivos, porque un build local no confirma entrega por los proveedores de Android o Apple.
