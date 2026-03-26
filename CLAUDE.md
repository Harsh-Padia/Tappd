# Tappd — Claude Code Context

- Codex will review your output once you are done

## Project Overview

Tappd is a static NFC smart business card platform hosted on **GitHub Pages**.
Live URL: `https://harsh-padia.github.io/Tappd`

Each NFC card links to a mobile-optimized HTML profile. Tapping opens the profile where visitors can save contact, call, WhatsApp, email, or visit a website — all without any app.

**Tech stack:** Pure HTML/CSS/JS — no frameworks, no build tools, no Node server.
**Hosting:** GitHub Pages (static only).

---

## Critical Rules

### NEVER use tappd.in
`tappd.in` is a completely different company (ibotz.in, Noida). It has no relation to this project. Before every commit run:
```
grep -r "tappd.in" . --exclude-dir=.git
```
Result MUST be zero matches.

### NEVER use absolute paths for assets
GitHub Pages serves from `/Tappd/` subpath. Absolute paths like `/assets/css/shared.css` resolve to the root domain and break. Always use **relative paths**:
- From `/u/jignesh/index.html` → `../../assets/css/shared.css`
- From `/index.html` (root) → `assets/css/shared.css`

### NEVER put CSS or JS inline in profile HTML
The only inline code allowed in a profile page is:
1. The `<style>:root { --accent: #xxx; }` accent override
2. The profile-specific data init script (contact object + `initLeadCapture()` call)

Everything else goes in shared files under `assets/`.

---

## Folder Structure

```
Tappd/
├── assets/
│   ├── css/
│   │   ├── shared.css       ← Reset, variables, grain, toast, QR modal, offline bar
│   │   ├── profile.css      ← Person profile layout (status bar, avatar, lead form, etc.)
│   │   └── brand.css        ← Brand profile layout (logo, trust bar, stats, CTA)
│   ├── js/
│   │   ├── vcard.js         ← downloadVCard(contact) — Blob approach, not data URI
│   │   ├── qr.js            ← showQRModal(url), closeQRModal(e)
│   │   ├── lead-capture.js  ← initLeadCapture(waNumber, ownerFirstName [, ownerPrefix])
│   │   ├── copy-link.js     ← copyProfileLink(url), showToast(msg)
│   │   └── offline-bar.js   ← IIFE, listens to online/offline events
│   └── img/                 ← Avatars, logos, OG images (1200x630px)
│
├── u/                        ← Person profiles
│   ├── jignesh/index.html   — Jignesh Shah (amber #f59e0b)
│   └── kalim/index.html     — Dr. Kalim Khan (blue #4f8cff)
│
├── b/                        ← Brand profiles
│   └── subscriptionloot/index.html  — SubscriptionLoot (purple #a855f7)
│
├── sw.js                     ← Service Worker at root (network-first HTML, cache-first assets)
├── index.html                ← Landing/marketing page
├── 404.html                  ← Error page
├── sitemap.xml
├── robots.txt
├── .nojekyll                 ← Prevents Jekyll from processing — REQUIRED
├── .gitignore
└── CLAUDE.md                 ← This file
```

---

## URL Structure

| URL | File | Template |
|-----|------|----------|
| `/` | `index.html` | Landing page |
| `/u/jignesh/` | `u/jignesh/index.html` | Person profile |
| `/u/kalim/` | `u/kalim/index.html` | Person profile |
| `/b/subscriptionloot/` | `b/subscriptionloot/index.html` | Brand profile |
| Anything else | `404.html` | Error |

**NFC chip programming:** Use the full `https://harsh-padia.github.io/Tappd/u/{slug}/` URL.

---

## Design System

### CSS Variables (in shared.css)
```css
--bg: #060609          /* page background */
--card: #0e0e16        /* card background */
--card2: #13131f       /* card hover / inner */
--border: rgba(255,255,255,0.06)
--border2: rgba(255,255,255,0.1)
--accent: #4f8cff      /* overridden per profile */
--accent2: #22d3ee     /* overridden per profile */
--accent-dim: rgba(79,140,255,0.15)   /* overridden per profile */
--accent-glow: rgba(79,140,255,0.05)  /* overridden per profile */
--t1: #f0ede6           /* primary text */
--t2: #9a97a0           /* secondary text */
--t3: #5a5765           /* muted text */
--green: #4ade80        /* online/available indicator */
--blue: #4f8cff         /* footer link colour */
--whatsapp: #25d366
--discord: #5865f2
--telegram: #26a5db
```

### Per-Profile Accent Colours
| Profile | --accent | --accent2 |
|---------|----------|-----------|
| Jignesh Shah | `#f59e0b` | `#d97706` |
| Dr. Kalim Khan | `#4f8cff` | `#22d3ee` |
| SubscriptionLoot | `#a855f7` | `#7c3aed` |

Override via inline `<style>` at top of each profile's `<head>`:
```html
<style>
:root {
  --accent: #f59e0b;
  --accent2: #d97706;
  --accent-dim: rgba(245,158,11,0.15);
  --accent-glow: rgba(245,158,11,0.06);
}
</style>
```

### Fonts
```
Outfit (wght 300–900) — body text
JetBrains Mono (wght 400–500) — status bar, section labels, monospace
```

---

## Key Technical Patterns

### vCard Download
Use the Blob approach — NOT `data:text/vcard` href. `data:` URIs have encoding bugs on Android Chrome with special characters (like `&` in org names).

```js
var blob = new Blob([vcf], { type: 'text/vcard;charset=utf-8' });
var url = URL.createObjectURL(blob);
var a = document.createElement('a');
a.href = url; a.download = 'Name.vcf';
document.body.appendChild(a); a.click(); document.body.removeChild(a);
setTimeout(function() { URL.revokeObjectURL(url); }, 1000);
```

### Email Obfuscation
Use `atob()` base64 decode to prevent bot scraping:
```js
window.location = atob('bWFpbHRvOm5hbWVAZXhhbXBsZS5jb20=');
```
Never use split-string concatenation for email addresses.

### Lead Capture (No Backend)
Visitor fills name + phone → JS builds WhatsApp pre-fill URL → `window.open(wa.me/[owner]?text=...)`. Card owner receives the lead on their WhatsApp. Zero infrastructure needed.

`initLeadCapture(waNumber, ownerFirstName [, ownerPrefix])` — `ownerPrefix` is optional (e.g. `'Dr.'`, `'Mr.'`, `'Ar.'`, `'Er.'`). Greeting becomes `"Hi Dr. Kalim!"` when prefix is supplied. Also accepts an object: `{ number, name, prefix }`.

### QR Code
Uses `api.qrserver.com` external API (lazy-loaded only when modal opens). Set `data-loaded` attribute to prevent re-fetching on subsequent opens.

### Service Worker
Real `/sw.js` at project root — NOT the Blob URL hack from old versions. Uses `new URL('.', self.location.href).href` for dynamic base URL computation to handle GitHub Pages subpath correctly.

When updating profile content, bump the cache version string in `sw.js`.

### Offline Bar
Simple IIFE in `assets/js/offline-bar.js` that shows/hides `#offlineBar` based on `navigator.onLine`.

---

## Active Profiles

### Jignesh Shah — `/u/jignesh/`
- CEO, Veer Cooker & Cookware LLP
- Mumbai · Manufacturing
- Tel: +919082612990
- Email: gemrajesh16@gmail.com (obfuscated: `bWFpbHRvOmdlbXJhamVzaDE2QGdtYWlsLmNvbQ==`)
- Website: https://www.gemrajesh.com
- WA lead number: 919082612990

### Dr. Kalim Khan — `/u/kalim/`
- Managing Director, Brains Trust India
- Mumbai · Education
- Tel: +919820283973
- Work email: kalim@brainstrustindia.com (obfuscated: `bWFpbHRvOmthbGltQGJyYWluc3RydXN0aW5kaWEuY29t`)
- Personal email: kalim.k.khan@gmail.com (obfuscated: `bWFpbHRvOmthbGltLmsuaGhhbkBnbWFpbC5jb20=`)
- Twitter: @DrKalimK
- Website: https://www.brainstrustindia.com
- WA lead number: 919820283973
- Has real base64-encoded photo in avatar img tag

### SubscriptionLoot — `/b/subscriptionloot/`
- Brand profile — no vCard, no lead capture, no status bar
- Store: https://subscriptionloot.com
- Trustpilot, Discord (https://discord.gg/nAZT7JgcCM), Telegram (https://t.me/cheapsubscript)

---

## Adding a New Client

### Person profile
1. Create `u/{slug}/` folder
2. Copy `u/jignesh/index.html` as template
3. Replace all contact data and accent colour
4. Update `atob()` base64 strings for email links
5. Add to `sitemap.xml`
6. Add profile card to `index.html` "See It Live" section
7. Add to `404.html` Active Profiles list

### Brand profile
1. Create `b/{slug}/` folder
2. Copy `b/subscriptionloot/index.html` as template
3. Update brand data, logo emoji/image, accent colour, links
4. Do NOT include `vcard.js` or `lead-capture.js` script tags
5. Add to `sitemap.xml`, `index.html`, `404.html`

---

## Domain Migration

When a custom domain is purchased:

1. Replace all `https://harsh-padia.github.io/Tappd` with `https://yourdomain.com` across all files
2. Create a `CNAME` file at project root containing just the domain: `yourdomain.com`
3. Switch `../../assets/...` relative paths to `/assets/...` absolute paths in all HTML `<link>` and `<script>` tags
4. Update `sitemap.xml` and `robots.txt`
5. Submit new sitemap to Google Search Console
6. Reprogram NFC chips with new URLs (or set up 301 redirects from old GitHub Pages URL)

---

## Quality Checklist Before Every Push

**Domain & URLs**
- [ ] `grep -r "tappd.in" . --exclude-dir=.git` → zero matches
- [ ] All OG `og:url` and `og:image` tags point to `harsh-padia.github.io/Tappd`
- [ ] Copy link function copies correct URL
- [ ] sitemap.xml and robots.txt use correct base URL

**File structure**
- [ ] `.nojekyll` exists at root
- [ ] No inline CSS/JS in profile pages beyond accent override + data init
- [ ] Old root-level `jignesh.html`, `kalim.html`, `subscriptionloot.html` are deleted (done)

**Functionality**
- [ ] Save Contact downloads valid `.vcf` (test special characters like `&`)
- [ ] QR modal opens, generates, closes
- [ ] Lead capture opens WhatsApp with pre-filled message
- [ ] Copy link shows toast and copies correct URL
- [ ] Offline bar appears when network disconnected

**Visual**
- [ ] Each profile's accent colour renders correctly
- [ ] No horizontal scroll on mobile (375px width)
- [ ] fadeUp entrance animations play

**SEO**
- [ ] Every page has unique `<title>`
- [ ] Every page has `<meta name="description">`
- [ ] Every profile has OG tags
- [ ] Landing page has JSON-LD structured data

**Git hygiene**
- [ ] No API keys, tokens, or passwords in any file
- [ ] Commit message is descriptive
