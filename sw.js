/* ── Tappd Service Worker v3 ── */
var CACHE_VERSION = 'tappd-v3';
var BASE = new URL('.', self.location.href).href;

var PRECACHE = [
  BASE,
  BASE + 'assets/css/shared.css',
  BASE + 'assets/css/profile.css',
  BASE + 'assets/css/brand.css',
  BASE + 'assets/js/vcard.js',
  BASE + 'assets/js/qr.js',
  BASE + 'assets/js/lead-capture.js',
  BASE + 'assets/js/copy-link.js',
  BASE + 'assets/js/offline-bar.js'
];

self.addEventListener('install', function(e) {
  e.waitUntil(
    caches.open(CACHE_VERSION).then(function(cache) {
      return cache.addAll(PRECACHE);
    }).then(function() { return self.skipWaiting(); })
  );
});

self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(
        keys.filter(function(k) { return k !== CACHE_VERSION; })
            .map(function(k) { return caches.delete(k); })
      );
    }).then(function() { return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function(e) {
  var url = e.request.url;
  // Network-first for HTML pages; cache-first for assets
  if (url.endsWith('.html') || url.endsWith('/') || (url.indexOf('?') === -1 && !url.match(/\.(css|js|png|jpg|jpeg|svg|ico|woff2?)$/))) {
    e.respondWith(
      fetch(e.request).then(function(r) {
        var rc = r.clone();
        caches.open(CACHE_VERSION).then(function(c) { c.put(e.request, rc); });
        return r;
      }).catch(function() { return caches.match(e.request); })
    );
  } else {
    e.respondWith(
      caches.match(e.request).then(function(cached) {
        return cached || fetch(e.request).then(function(r) {
          var rc = r.clone();
          caches.open(CACHE_VERSION).then(function(c) { c.put(e.request, rc); });
          return r;
        });
      })
    );
  }
});
