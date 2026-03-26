/* ── Tappd vCard Download ── */
function downloadVCard(contact) {
  var lines = ['BEGIN:VCARD', 'VERSION:3.0'];
  if (contact.n)      lines.push('N:' + contact.n);
  if (contact.fn)     lines.push('FN:' + contact.fn);
  if (contact.org)    lines.push('ORG:' + contact.org);
  if (contact.title)  lines.push('TITLE:' + contact.title);
  if (contact.tel)    lines.push('TEL;TYPE=CELL:' + contact.tel);
  if (contact.email)  lines.push('EMAIL;TYPE=WORK:' + contact.email);
  if (contact.email2) lines.push('EMAIL;TYPE=HOME:' + contact.email2);
  if (contact.url)    lines.push('URL:' + contact.url);
  if (contact.twitter) lines.push('X-SOCIALPROFILE;type=twitter:' + contact.twitter);
  if (contact.tappd) lines.push('X-TAPPD:' + contact.tappd);
  lines.push('END:VCARD');

  var vcf = lines.join('\r\n');
  var blob = new Blob([vcf], { type: 'text/vcard;charset=utf-8' });
  var url = URL.createObjectURL(blob);
  var a = document.createElement('a');
  a.href = url;
  a.download = (contact.filename || 'contact') + '.vcf';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  setTimeout(function() { URL.revokeObjectURL(url); }, 1000);
  if (typeof showToast === 'function') showToast('✓ Contact saved to your phone!');
}
