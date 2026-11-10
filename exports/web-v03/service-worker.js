const cacheName = 'trang-an-v031-4';
const files = new Set(['/','/index.html','/index.js','/index.pck','/index.wasm',
  '/index.audio.worklet.js','/index.audio.position.worklet.js','/manifest.webmanifest','/icon-192.png','/icon-512.png']);

self.addEventListener('install', event => {
  event.waitUntil(caches.open(cacheName).then(cache => cache.addAll(['/','/manifest.webmanifest','/icon-192.png','/icon-512.png'])));
});

self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys
    .filter(key => key.startsWith('trang-an-') && key !== cacheName)
    .map(key => caches.delete(key)))).then(() => self.clients.claim()));
});

self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  if (event.request.method !== 'GET' || url.origin !== self.location.origin || !files.has(url.pathname)) return;
  event.respondWith(fetch(event.request).then(response => {
    if (response.ok && response.status === 200) {
      const copy = response.clone();
      event.waitUntil(caches.open(cacheName).then(cache => cache.put(event.request, copy)).catch(() => {}));
    }
    return response;
  }).catch(async () => (await caches.match(event.request)) || Response.error()));
});
