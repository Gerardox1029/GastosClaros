const CACHE_NAME = 'gastosclaros-__BUILD_VERSION__';
const APP_SHELL = [
  '/', '/index.html', '/flutter_bootstrap.js', '/main.dart.js',
  '/manifest.json', '/pwa.js', '/icons/Icon-192.png', '/icons/Icon-512.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL)));
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(Promise.all([
    caches.keys().then((keys) => Promise.all(keys
      .filter((key) => key.startsWith('gastosclaros-') && key !== CACHE_NAME)
      .map((key) => caches.delete(key)))),
    self.clients.claim()
  ]));
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== 'GET' || url.origin !== self.location.origin ||
      url.pathname.startsWith('/api/') || url.pathname.startsWith('/.netlify/')) return;

  if (request.mode === 'navigate') {
    event.respondWith(fetch(request).then((response) => {
      if (response.ok) {
        const copy = response.clone();
        event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.put('/index.html', copy)));
      }
      return response;
    }).catch(() => caches.match('/index.html')));
    return;
  }

  event.respondWith(caches.match(request).then((cached) => cached ||
    fetch(request).then((response) => {
      if (response.ok) {
        const copy = response.clone();
        event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.put(request, copy)));
      }
      return response;
    })));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const target = new URL(event.notification.data?.url || '/', self.location.origin);
  if (target.origin !== self.location.origin) return;
  event.waitUntil(self.clients.matchAll({ type: 'window', includeUncontrolled: true })
    .then(async (clients) => {
      const existing = clients.find((client) => new URL(client.url).origin === target.origin);
      if (existing) {
        if ('navigate' in existing) await existing.navigate(target.href);
        return existing.focus();
      }
      return self.clients.openWindow(target.href);
    }));
});

self.addEventListener('push', (event) => {
  let notice;
  try { notice = event.data?.json() || {}; } catch { notice = {}; }
  const target = new URL(notice.url || '/', self.location.origin);
  if (target.origin !== self.location.origin) return;
  event.waitUntil(self.registration.showNotification(
    typeof notice.title === 'string' ? notice.title : 'GastosClaros', {
      body: typeof notice.body === 'string' ? notice.body : 'Tienes un nuevo registro.',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: typeof notice.tag === 'string' ? notice.tag : 'registro',
      data: { url: target.pathname + target.search }
    }
  ));
});
