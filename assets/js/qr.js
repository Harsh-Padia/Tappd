/* ── Tappd QR Code Modal ── */
function showQRModal(profileUrl) {
  var modal = document.getElementById('qrModal');
  var img   = document.getElementById('qrImg');
  var urlEl = document.getElementById('qrUrl');
  if (!img.getAttribute('data-loaded')) {
    img.src = 'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data='
      + encodeURIComponent(profileUrl) + '&color=000000&bgcolor=ffffff&margin=10';
    img.setAttribute('data-loaded', '1');
  }
  if (urlEl) urlEl.textContent = profileUrl.replace(/^https?:\/\//, '');
  modal.classList.add('open');
}

function closeQRModal(e) {
  if (!e || e.target === document.getElementById('qrModal')) {
    document.getElementById('qrModal').classList.remove('open');
  }
}
