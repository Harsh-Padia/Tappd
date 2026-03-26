# Tappd — Smart NFC Business Cards

> One tap. Every connection.

Tappd is a smart NFC business card platform built for professionals, founders, freelancers, and businesses across India. Each client receives a physical card — when tapped against any smartphone, it instantly opens a mobile-optimised digital profile. No app. No friction. One tap shares your entire professional identity.

**Live demo:** https://harsh-padia.github.io/Tappd

---

## The Problem

Paper business cards are a ₹3,000 crore industry in India — and almost entirely broken. They go straight into drawers, get thrown away, and become outdated the moment you print them. Professionals waste money reprinting cards every time they change jobs, numbers, or titles. And there's no way to know if anyone ever actually used one.

The digital alternative — typing out a LinkedIn URL, sharing a QR screenshot, airdropping a vCard — is fragmented, slow, and forgettable.

---

## What Is Tappd?

Tappd replaces the paper card with a single smart card that works forever:

- **Always current** — update your number, title, or links online anytime. The physical card never needs to change.
- **Zero friction** — tap the card against any modern Android or iPhone. Profile opens in 2 seconds. No app download. No signup.
- **Complete identity** — visitors can save your contact, call, WhatsApp, email, visit your website, or follow your socials — all from one page.
- **Two-way** — a built-in lead capture form lets visitors share their own contact details back to you, delivered straight to your WhatsApp.
- **One-time purchase** — the card is bought once. The digital profile is updated free, forever.

---

## How It Works

**For the card owner:**
1. Order a Tappd card — Campus, Professional, or Executive tier
2. Tappd sets up a personal profile page at `tappd.cc/u/your-name/`
3. The NFC chip in the card is programmed with that URL
4. Hand the card to anyone — they tap it, your profile opens instantly

**For the person who receives the card:**
1. Tap the card (or scan the QR code printed on the back)
2. Profile opens in the browser — no download, no signup required
3. Save the contact, WhatsApp the owner, visit their website, or share the link
4. Optionally leave their own name and phone — it goes directly to the card owner's WhatsApp

---

## Pricing

Three card tiers targeting different customer segments:

| Tier | Price | Card | Target |
|------|-------|------|--------|
| **Campus** | ₹299 | White PVC | Students, freshers, first-time networkers |
| **Professional** | ₹799 | Custom matte/glossy PVC | Freelancers, agents, growing professionals |
| **Executive** | ₹1,299 | Metal, laser engraved, velvet box | Founders, senior professionals, corporate gifting |

All tiers include: custom design, programmed NFC chip, QR fallback, digital profile, and lifetime free updates.

---

## Roadmap

Tappd currently operates as a **managed service** — the team personally creates and maintains every client profile. This is the right model at early scale: zero infrastructure cost, full quality control, and near-zero running expenses.

As client volume grows, the platform evolves in three phases:

### Phase 1 — Client Self-Service Portal
- Card owners log in (phone OTP or email) to manage their own profile
- Dashboard: view live profile, see tap count, access leads received
- Profile editor: update name, title, phone, links, photo — changes go live instantly
- Lead inbox: all visitor contacts received via lead form, exportable as CSV
- QR code download for email signatures and presentations

### Phase 2 — Full Product
- Self-service ordering with Razorpay payment integration — no manual intervention after purchase
- Automated profile creation on payment confirmation
- Analytics: tap history, device types, geographic distribution
- Multi-card support: one account managing multiple cards (for teams and businesses)
- Admin dashboard for Tappd: manage all clients and view platform-wide stats

### Phase 3 — Scale
- Custom subdomains per client: `name.tappd.cc`
- White-label option for corporate clients: their own branding on the platform
- NFC chip programming tool via Web NFC API — clients program replacement chips themselves
- Enterprise API integrations: CRM sync, Salesforce, HubSpot
- Subscription tiers for teams and businesses with shared dashboards and analytics

---

## Active Clients

> Currently live at `harsh-padia.github.io/Tappd` — will move to `tappd.cc` on domain purchase.

| Client | Profile | Type |
|--------|---------|------|
| Jignesh Shah — CEO, Veer Cooker & Cookware LLP | `tappd.cc/u/jignesh/` | Person |
| Dr. Kalim Khan — Managing Director, Brains Trust India | `tappd.cc/u/kalim/` | Person |
| SubscriptionLoot | `tappd.cc/b/subscriptionloot/` | Brand |

---

## Current Operations

Tappd runs as a **zero-cost managed service**:

- Client orders via WhatsApp → team creates the profile → NFC chip programmed → card shipped
- Profile updates are requested by the client and made by the team
- Entire platform runs as static files — no server, no database, no hosting bill
- Running cost: ₹0/month

This keeps the product lean, fast, and reliable at the current scale while the client base grows.

---

## Built By

**Harsh Padia** — Mumbai, India
padia.harsh@gmail.com · [@Tappd](https://instagram.com/Tappd)

---

---

## Technical Reference

> The sections below are for developers contributing to the codebase.

---

### Platform Architecture

Tappd has three distinct layers:

| Layer | Purpose | Audience |
|-------|---------|----------|
| **Marketing site** (`/`) | Explains Tappd, pricing, how it works. Converts visitors into buyers. | Potential customers |
| **Public profiles** (`/u/[slug]/`, `/b/[slug]/`) | The live digital card — what someone sees when they tap. | Anyone who receives a card |
| **Client portal** (`/login`) *(Phase 1)* | Login, edit profile, view leads, see analytics. | Card owners |

---

### Tech Stack

- **Pure HTML / CSS / JS** — no frameworks, no build tools, no dependencies
- **GitHub Pages** — static hosting, zero cost
- **Service Worker** — offline support, network-first HTML, cache-first assets
- **Web App Manifest** — installable as PWA on Android and iOS
- **No backend** — lead capture works via WhatsApp pre-fill URL; no server, no database

---

### Project Structure

```
Tappd/
├── assets/
│   ├── css/
│   │   ├── shared.css        ← Variables, reset, toast, QR modal, offline bar, animations
│   │   ├── profile.css       ← Person profile layout (status bar, avatar, lead form, etc.)
│   │   └── brand.css         ← Brand profile layout (logo, trust bar, stats, CTA)
│   ├── js/
│   │   ├── vcard.js          ← Save Contact (.vcf Blob download)
│   │   ├── qr.js             ← QR code modal (lazy-loads from api.qrserver.com)
│   │   ├── lead-capture.js   ← Lead form → opens WhatsApp with pre-filled message
│   │   ├── copy-link.js      ← Copy profile link to clipboard + showToast()
│   │   └── offline-bar.js    ← IIFE, shows offline indicator on network loss
│   └── img/
│       ├── favicon.ico / favicon-16x16.png / favicon-32x32.png
│       ├── apple-touch-icon.png / android-chrome-192x192.png / android-chrome-512x512.png
│       ├── site.webmanifest
│       ├── og-home.png       ← OG image for landing page (1200×630px)
│       ├── og-profile.png    ← OG image for person profiles (1200×630px)
│       └── og-brand.png      ← OG image for brand profiles (1200×630px)
├── u/                        ← Person profiles
│   ├── jignesh/index.html
│   └── kalim/index.html
├── b/                        ← Brand profiles
│   └── subscriptionloot/index.html
├── tests/
│   └── pre-push.sh           ← 151-check test suite, run before every push
├── sw.js                     ← Service Worker at root (GitHub Pages compatible)
├── index.html                ← Landing / marketing page
├── 404.html                  ← Error page with active profile links
├── sitemap.xml
├── robots.txt
└── CLAUDE.md                 ← Full project context for AI-assisted development
```

---

### Adding a New Client

**Person profile**
1. Create `u/{slug}/` folder
2. Copy `u/jignesh/index.html` as template
3. Replace all contact data and accent colour
4. Encode email as base64: `btoa('mailto:name@example.com')`
5. Add entry to `sitemap.xml`, `index.html` (profiles section), and `404.html`
6. Run `bash tests/pre-push.sh` — all checks must pass before pushing

**Brand profile**
1. Create `b/{slug}/` folder
2. Copy `b/subscriptionloot/index.html` as template
3. Update brand data, accent colour, and links
4. Do **not** include `vcard.js` or `lead-capture.js`
5. Add entry to `sitemap.xml`, `index.html`, and `404.html`
6. Run `bash tests/pre-push.sh` — all checks must pass before pushing

---

### Pre-Push Tests

```bash
bash tests/pre-push.sh
```

151 automated checks across 18 categories — file structure, SEO meta tags, email encoding, phone number format, vCard completeness, Service Worker integrity, sitemap, security, and more. Push is blocked if any check fails.

---

### Design System

**CSS Variables**

| Token | Value | Use |
|-------|-------|-----|
| `--bg` | `#060609` | Page background |
| `--card` | `#0e0e16` | Card / element background |
| `--card2` | `#13131f` | Inner card / hover state |
| `--accent` | per-profile | Primary accent colour |
| `--accent2` | per-profile | Secondary accent colour |
| `--t1` | `#f0ede6` | Primary text |
| `--t2` | `#9a97a0` | Secondary / muted text |
| `--t3` | `#5a5765` | Dim text (labels, captions) |
| `--green` | `#4ade80` | Online indicator, success states |

**Per-Profile Accent Colours**

| Profile | `--accent` | `--accent2` |
|---------|-----------|------------|
| Jignesh Shah | `#f59e0b` (amber) | `#d97706` |
| Dr. Kalim Khan | `#4f8cff` (blue) | `#22d3ee` |
| SubscriptionLoot | `#a855f7` (purple) | `#7c3aed` |

**Fonts:** Outfit (300–900) for all UI text · JetBrains Mono (400–500) for labels and status text

---

## License

Private — All rights reserved. Tappd, India.
