/* ── Tappd Copy Link + Toast ── */
function copyProfileLink(url) {
  if (navigator.clipboard) {
    navigator.clipboard.writeText(url).then(showToast);
  } else {
    var ta = document.createElement('textarea');
    ta.value = url;
    document.body.appendChild(ta);
    ta.select();
    document.execCommand('copy');
    document.body.removeChild(ta);
    showToast();
  }
}

function showToast(msg) {
  var t = document.getElementById('toast');
  if (!t) return;
  if (msg) t.textContent = msg;
  t.classList.add('show');
  setTimeout(function() { t.classList.remove('show'); }, 2500);
}
