/* ── Tappd Lead Capture via WhatsApp ── */

/*
 * initLeadCapture(waNumber, ownerFirstName [, ownerPrefix])
 *
 * ownerPrefix (optional) — honorific before the name.
 * Examples: 'Dr.', 'Mr.', 'Ms.', 'Ar.', 'Er.', 'CA', 'Adv.'
 * If omitted, greeting uses first name only.
 *
 * Config object form also accepted:
 *   initLeadCapture({ number: '919...', name: 'Kalim', prefix: 'Dr.' })
 */
function initLeadCapture(waNumber, ownerFirstName, ownerPrefix) {
  // Support object-style config
  if (typeof waNumber === 'object' && waNumber !== null) {
    var cfg = waNumber;
    waNumber      = cfg.number;
    ownerFirstName = cfg.name;
    ownerPrefix   = cfg.prefix;
  }

  var form = document.getElementById('lead-form');
  if (!form) return;

  var displayName = ownerPrefix
    ? ownerPrefix + ' ' + ownerFirstName
    : ownerFirstName;

  form.addEventListener('submit', function(e) {
    e.preventDefault();
    var name  = document.getElementById('lcName').value.trim();
    var phone = document.getElementById('lcPhone').value.trim();
    if (!name || !phone) {
      if (typeof showToast === 'function') showToast('⚠️ Please enter your name and phone number.');
      return;
    }
    // Disable to prevent double-submit
    var btn = form.querySelector('button[type="submit"]');
    if (btn) { btn.disabled = true; btn.textContent = 'Opening WhatsApp...'; }
    var msg = 'Hi ' + displayName + '! I just tapped your Tappd card.\n\n'
      + 'Here are my details:\nName: ' + name + '\nPhone: ' + phone
      + '\n\nLooking forward to connecting!';
    window.open('https://wa.me/' + waNumber + '?text=' + encodeURIComponent(msg), '_blank');
    document.getElementById('lcName').value = '';
    document.getElementById('lcPhone').value = '';
    var sent = document.getElementById('leadSent');
    if (sent) sent.style.display = 'block';
    form.style.display = 'none';
  });
}
