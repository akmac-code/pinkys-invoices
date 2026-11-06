// Offline support: keep the app's own files on the device. Sync calls to Google always go to the network.
const CACHE = 'pinkys-invoices-v2';
const FILES = ['./', './index.html', './manifest.webmanifest', './favicon.ico',
  './icons/icon-192.png', './icons/icon-512.png', './icons/icon-maskable-512.png', './icons/apple-touch-icon-180.png'];
self.addEventListener('install', e => { e.waitUntil(caches.open(CACHE).then(c => c.addAll(FILES))); self.skipWaiting(); });
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  if (e.request.method !== 'GET' || url.origin !== location.origin) return;     // never touch Google sync requests
  // Show the saved copy instantly (works offline), and fetch a fresh copy in the background for next time
  e.respondWith(caches.open(CACHE).then(async c => {
    const hit = await c.match(e.request, {ignoreSearch:true});
    const fresh = fetch(e.request).then(r => { if (r.ok) c.put(e.request, r.clone()); return r; }).catch(() => hit);
    return hit || fresh;
  }));
});
