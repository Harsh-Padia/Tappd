/* ── Tappd Offline Bar ── */
(function() {
  var bar = document.getElementById('offlineBar');
  if (!bar) return;
  function show() { bar.style.display = 'block'; }
  function hide() { bar.style.display = 'none'; }
  window.addEventListener('online',  hide);
  window.addEventListener('offline', show);
  if (!navigator.onLine) show();
})();
