#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  Tappd — Pre-Push Test Suite
#
#  Philosophy: every test here has caught, or could catch, a real bug.
#  - Cross-validate data that appears in multiple places
#  - Verify actual values, not just that strings exist
#  - Check invariants the project rules depend on
#
#  Run: bash tests/pre-push.sh
# ══════════════════════════════════════════════════════════════════

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PASS=0; FAIL=0; WARN=0

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

pass()    { echo -e "  ${GREEN}✓${RESET} $1"; PASS=$((PASS+1)); }
fail()    { echo -e "  ${RED}✗${RESET} $1"; FAIL=$((FAIL+1)); }
warn()    { echo -e "  ${YELLOW}⚠${RESET} $1"; WARN=$((WARN+1)); }
section() { echo -e "\n${CYAN}${BOLD}▸ $1${RESET}"; }

echo -e "${BOLD}═══════════════════════════════════════${RESET}"
echo -e "${BOLD}  Tappd Pre-Push Tests${RESET}"
echo -e "${BOLD}═══════════════════════════════════════${RESET}"

PERSON_PROFILES=("u/jignesh/index.html" "u/kalim/index.html")
BRAND_PROFILES=("b/subscriptionloot/index.html")
ALL_PROFILES=("${PERSON_PROFILES[@]}" "${BRAND_PROFILES[@]}")

# ══════════════════════════════════════════════════════════════════
section "1. FORBIDDEN DOMAIN"
# tappd.in is a completely different company (ibotz.in, Noida).
# Any reference to it ships misinformation to real users.
# ══════════════════════════════════════════════════════════════════

TAPIN=$(grep -rl "tappd\.in" . \
  --include="*.html" --include="*.js" --include="*.css" --include="*.xml" \
  --exclude-dir=.git 2>/dev/null)
if [ -z "$TAPIN" ]; then
  pass "No tappd.in references in any source file"
else
  fail "tappd.in found — unrelated company, will mislead users:"
  echo "$TAPIN"
fi

# ══════════════════════════════════════════════════════════════════
section "2. REQUIRED FILES"
# ══════════════════════════════════════════════════════════════════

declare -A REQUIRED=(
  ["index.html"]="landing page"
  ["404.html"]="error page"
  ["sw.js"]="service worker"
  ["sitemap.xml"]="SEO sitemap"
  ["robots.txt"]="robots"
  [".nojekyll"]="Jekyll bypass — REQUIRED for GitHub Pages _folders"
  ["favicon.ico"]="favicon"
  ["assets/css/shared.css"]="base design system CSS"
  ["assets/css/profile.css"]="person profile CSS"
  ["assets/css/brand.css"]="brand profile CSS"
  ["assets/js/vcard.js"]="vCard download"
  ["assets/js/qr.js"]="QR code modal"
  ["assets/js/lead-capture.js"]="lead capture"
  ["assets/js/copy-link.js"]="copy link + toast"
  ["assets/js/offline-bar.js"]="offline bar"
  ["u/jignesh/index.html"]="Jignesh Shah profile"
  ["u/kalim/index.html"]="Dr. Kalim Khan profile"
  ["b/subscriptionloot/index.html"]="SubscriptionLoot brand page"
)

for file in "${!REQUIRED[@]}"; do
  [ -f "$file" ] && pass "$file" || fail "$file MISSING (${REQUIRED[$file]})"
done

# ══════════════════════════════════════════════════════════════════
section "3. OLD ROOT PROFILES DELETED"
# Flat-file versions from pre-/u/ /b/ restructure.
# If still present, NFC chips pointing to old URLs would hit these
# instead of 404ing cleanly — silently serving stale/wrong data.
# ══════════════════════════════════════════════════════════════════

for f in jignesh.html kalim.html subscriptionloot.html; do
  [ ! -f "$f" ] && pass "$f absent from root" \
                || fail "$f still at root — old NFC links will hit stale content"
done

# ══════════════════════════════════════════════════════════════════
section "4. URL TRIPLE-CONSISTENCY (canonical == og:url == PROFILE_URL)"
# All three are used in different contexts: og:url for social share,
# canonical for SEO dedup, PROFILE_URL for QR code and copy-link.
# A mismatch is a silent copy-paste error when adding new profiles.
# ══════════════════════════════════════════════════════════════════

for f in "${ALL_PROFILES[@]}"; do
  [ ! -f "$f" ] && continue
  LABEL=$(basename "$(dirname "$f")")

  CANONICAL=$(grep 'rel="canonical"' "$f" | sed 's/.*href="\([^"]*\)".*/\1/')
  OG_URL=$(grep 'property="og:url"' "$f" | sed 's/.*content="\([^"]*\)".*/\1/')
  PROFILE_URL_VAL=$(grep 'var PROFILE_URL' "$f" | sed "s/.*PROFILE_URL = '\([^']*\)'.*/\1/")

  if [ -z "$CANONICAL" ]; then
    fail "$LABEL — canonical href not found"
    continue
  fi

  [ "$CANONICAL" = "$OG_URL" ] \
    && pass "$LABEL — canonical matches og:url" \
    || fail "$LABEL — canonical ($CANONICAL) ≠ og:url ($OG_URL)"

  [ "$CANONICAL" = "$PROFILE_URL_VAL" ] \
    && pass "$LABEL — canonical matches PROFILE_URL var" \
    || fail "$LABEL — canonical ($CANONICAL) ≠ PROFILE_URL var ($PROFILE_URL_VAL)"
done

# ══════════════════════════════════════════════════════════════════
section "5. PHONE CROSS-VALIDATION (tel: == wa.me/ == vCard == initLeadCapture)"
# These four phone numbers appear independently in the HTML and JS.
# A mismatch means calls go to the right person but leads go to
# the wrong WhatsApp, or the saved contact has the wrong number.
# ══════════════════════════════════════════════════════════════════

for f in "${PERSON_PROFILES[@]}"; do
  [ ! -f "$f" ] && continue
  LABEL=$(basename "$(dirname "$f")")

  TEL=$(grep -oE 'href="tel:\+[0-9]+"' "$f" | head -1 | grep -oE '[0-9]+')
  WA=$(grep -oE 'href="https://wa\.me/[0-9]+"' "$f" | head -1 | sed 's/.*wa\.me\/\([0-9]*\)".*/\1/')
  VCARD_TEL=$(grep "  tel:" "$f" | sed "s/.*tel:[[:space:]]*'+\([0-9]*\)'.*/\1/")
  ILC=$(grep "initLeadCapture(" "$f" | grep -oE "'[0-9]+'" | head -1 | tr -d "'")

  if [ -z "$TEL" ]; then
    fail "$LABEL — no tel: href found"
    continue
  fi

  [ "$TEL" = "$WA" ] \
    && pass "$LABEL — tel: matches wa.me/ ($TEL)" \
    || fail "$LABEL — tel: ($TEL) ≠ wa.me/ ($WA) — leads route to wrong WhatsApp"

  [ "$TEL" = "$VCARD_TEL" ] \
    && pass "$LABEL — tel: matches vCard tel" \
    || fail "$LABEL — tel: ($TEL) ≠ vCard tel ($VCARD_TEL) — saved contact has wrong number"

  [ "$TEL" = "$ILC" ] \
    && pass "$LABEL — tel: matches initLeadCapture number" \
    || fail "$LABEL — tel: ($TEL) ≠ initLeadCapture ($ILC) — lead form routes to wrong person"
done

# ══════════════════════════════════════════════════════════════════
section "6. EMAIL ATOB — DECODES CORRECTLY AND MATCHES vCARD"
# atob() obfuscation prevents bot scraping but it's easy to corrupt
# the base64 string during edits. Also validates the decoded address
# matches the vCard email so saved contacts don't use a different one.
# ══════════════════════════════════════════════════════════════════

if ! command -v node >/dev/null 2>&1; then
  warn "node not found — skipping email base64 validation"
else

  check_email() {
    local label="$1"
    local expected="mailto:$2"
    local b64="$3"
    local file="$4"

    DECODED=$(node -e "process.stdout.write(Buffer.from('$b64','base64').toString())" 2>/dev/null)
    [ "$DECODED" = "$expected" ] \
      && pass "$label — atob decodes correctly ($2)" \
      || fail "$label — atob decodes to '$DECODED', expected '$expected' — broken mailto"

    # vCard email must match the same address
    VCARD_EMAIL=$(grep "^  email:" "$file" | sed "s/.*email:[[:space:]]*'\([^']*\)'.*/\1/")
    [ "$VCARD_EMAIL" = "$2" ] \
      && pass "$label — vCard email matches atob address" \
      || fail "$label — vCard email ($VCARD_EMAIL) ≠ atob address ($2) — saved contact has different email"
  }

  check_email "Jignesh" \
    "gemrajesh16@gmail.com" \
    "bWFpbHRvOmdlbXJhamVzaDE2QGdtYWlsLmNvbQ==" \
    "u/jignesh/index.html"

  check_email "Kalim (work)" \
    "kalim@brainstrustindia.com" \
    "bWFpbHRvOmthbGltQGJyYWluc3RydXN0aW5kaWEuY29t" \
    "u/kalim/index.html"

  # Kalim personal email (not in vCard primary — just verify atob is valid)
  DECODED2=$(node -e "process.stdout.write(Buffer.from('bWFpbHRvOmthbGltLmsua2hhbkBnbWFpbC5jb20=','base64').toString())" 2>/dev/null)
  [ "$DECODED2" = "mailto:kalim.k.khan@gmail.com" ] \
    && pass "Kalim (personal) — atob decodes correctly (kalim.k.khan@gmail.com)" \
    || fail "Kalim (personal) — atob decodes to '$DECODED2', expected 'mailto:kalim.k.khan@gmail.com'"

fi

# ══════════════════════════════════════════════════════════════════
section "7. NO BARE mailto: HREFS IN PROFILE HTML"
# href="mailto:..." is scraped by bots in milliseconds.
# All profile email links must use window.location=atob(...) instead.
# ══════════════════════════════════════════════════════════════════

for f in "${PERSON_PROFILES[@]}"; do
  [ ! -f "$f" ] && continue
  LABEL=$(basename "$(dirname "$f")")
  RAW=$(grep -nE 'href="mailto:' "$f")
  if [ -z "$RAW" ]; then
    pass "$LABEL — no bare mailto: hrefs (all obfuscated)"
  else
    fail "$LABEL — raw mailto: href found — bots will harvest this address:"
    echo "$RAW"
  fi
done

# ══════════════════════════════════════════════════════════════════
section "8. DUPLICATE HTML IDs"
# Duplicate ids are invalid HTML. The second element is silently
# ignored by getElementById() — broken QR modals, toast, lead form.
# ══════════════════════════════════════════════════════════════════

for f in "${ALL_PROFILES[@]}" "index.html"; do
  [ ! -f "$f" ] && continue
  DUPES=$(grep -oE ' id="[^"]+"' "$f" | sort | uniq -d | tr -d ' ')
  if [ -z "$DUPES" ]; then
    pass "$f — no duplicate id attributes"
  else
    fail "$f — duplicate ids (JS will silently target wrong element): $DUPES"
  fi
done

# ══════════════════════════════════════════════════════════════════
section "9. SEO FIELD QUALITY"
# Checks content correctness, not just presence. A title that doesn't
# contain the person's name is a copy-paste error. A description
# under 50 chars will be ignored or rewritten by Google.
# ══════════════════════════════════════════════════════════════════

check_seo() {
  local file="$1"
  local label="$2"
  local expected_name="$3"
  [ ! -f "$file" ] && return

  TITLE=$(grep -oE '<title>[^<]+</title>' "$file" | sed 's/<[^>]*>//g')
  if [ -z "$TITLE" ]; then
    fail "$label — <title> is empty"
  elif echo "$TITLE" | grep -qi "$expected_name"; then
    pass "$label — <title> contains '$expected_name'"
  else
    fail "$label — <title> '$TITLE' does not contain '$expected_name' (likely a copy-paste leftover)"
  fi

  DESC=$(grep 'name="description"' "$file" | sed 's/.*content="\([^"]*\)".*/\1/')
  DESC_LEN=${#DESC}
  if [ -z "$DESC" ]; then
    fail "$label — meta description is empty (Google will generate its own)"
  elif [ "$DESC_LEN" -lt 50 ]; then
    warn "$label — meta description only $DESC_LEN chars — too short (aim 120–160)"
  else
    pass "$label — meta description is $DESC_LEN chars"
  fi

  OG_TITLE=$(grep 'og:title' "$file" | sed 's/.*content="\([^"]*\)".*/\1/')
  echo "$OG_TITLE" | grep -qi "$expected_name" \
    && pass "$label — og:title contains '$expected_name'" \
    || fail "$label — og:title '$OG_TITLE' does not contain '$expected_name'"
}

check_seo "u/jignesh/index.html"          "Jignesh"          "Jignesh"
check_seo "u/kalim/index.html"            "Kalim"            "Kalim"
check_seo "b/subscriptionloot/index.html" "SubscriptionLoot" "SubscriptionLoot"
check_seo "index.html"                    "Landing"          "Tappd"

# ══════════════════════════════════════════════════════════════════
section "10. PER-PROFILE ACCENT — ALL 4 CSS VARS DEFINED"
# Missing --accent-dim or --accent-glow means buttons/glows silently
# use the default blue (#4f8cff) regardless of the profile's colour.
# ══════════════════════════════════════════════════════════════════

for f in "${ALL_PROFILES[@]}"; do
  [ ! -f "$f" ] && continue
  LABEL=$(basename "$(dirname "$f")")
  for var in "--accent:" "--accent2:" "--accent-dim:" "--accent-glow:"; do
    grep -qFe "$var" "$f" \
      && pass "$LABEL — $var present in accent override" \
      || fail "$LABEL — $var missing from <style>:root block (falls back to default blue)"
  done
done

# ══════════════════════════════════════════════════════════════════
section "11. NO ABSOLUTE /assets PATHS IN PROFILE HTML"
# GitHub Pages serves from /Tappd/ — a path like /assets/css/shared.css
# resolves to harsh-padia.github.io/assets/ which is a 404.
# Profiles must use ../../assets/ relative paths.
# ══════════════════════════════════════════════════════════════════

for f in "${ALL_PROFILES[@]}"; do
  [ ! -f "$f" ] && continue
  LABEL=$(basename "$(dirname "$f")")
  ABS=$(grep -nE '(href|src)="/(assets|Tappd)' "$f")
  if [ -z "$ABS" ]; then
    pass "$LABEL — no absolute /assets paths"
  else
    fail "$LABEL — absolute asset paths will 404 on GitHub Pages:"
    echo "$ABS"
  fi
done

# ══════════════════════════════════════════════════════════════════
section "12. LOCAL ASSET REFERENCES RESOLVE"
# Checks that every local .css/.js file referenced in <link>/<script>
# tags actually exists on disk. A missing file silently breaks layout
# or functionality with no error in most browsers.
# ══════════════════════════════════════════════════════════════════

check_asset_refs() {
  local file="$1"
  local base_dir
  base_dir=$(dirname "$file")
  local failed=0

  while IFS= read -r ref; do
    [[ "$ref" == http* ]] && continue  # skip external URLs
    # Resolve ../../ relative to file's directory
    local resolved
    resolved=$(cd "$base_dir" 2>/dev/null && realpath -m "$ref" 2>/dev/null)
    if [ -z "$resolved" ]; then
      # Fallback for systems without realpath -m
      resolved="${ROOT}/${base_dir}/${ref}"
    fi
    if [ ! -f "$resolved" ]; then
      fail "$file — broken reference: $ref"
      failed=1
    fi
  done < <(grep -oE '(href|src)="[^"#?]+"' "$file" \
    | sed 's/.*="\([^"]*\)".*/\1/' \
    | grep -E '\.(css|js)$' \
    | grep -v '^http')

  [ "$failed" -eq 0 ] && pass "$file — all local CSS/JS references resolve"
}

for f in "${ALL_PROFILES[@]}" "index.html"; do
  [ ! -f "$f" ] && continue
  check_asset_refs "$f"
done

# ══════════════════════════════════════════════════════════════════
section "13. BRAND/PERSON PROFILE SEPARATION"
# Brand profiles must not load person-only scripts (vcard, lead capture).
# Person profiles must not load brand-only CSS (brand.css).
# Wrong scripts on the wrong template break functionality silently.
# ══════════════════════════════════════════════════════════════════

for f in "${BRAND_PROFILES[@]}"; do
  [ ! -f "$f" ] && continue
  LABEL=$(basename "$(dirname "$f")")
  grep -q 'vcard.js'           "$f" && fail "$LABEL — brand profile must not load vcard.js" \
                                     || pass "$LABEL — vcard.js absent (brand profile)"
  grep -q 'lead-capture.js'    "$f" && fail "$LABEL — brand profile must not load lead-capture.js" \
                                     || pass "$LABEL — lead-capture.js absent (brand profile)"
  grep -q 'initLeadCapture'    "$f" && fail "$LABEL — initLeadCapture() must not appear in brand profile" \
                                     || pass "$LABEL — initLeadCapture not called"
  grep -q 'class="status-bar"' "$f" && fail "$LABEL — status-bar is person-only HTML, not for brand profiles" \
                                     || pass "$LABEL — no status-bar (brand profile)"
done

for f in "${PERSON_PROFILES[@]}"; do
  [ ! -f "$f" ] && continue
  LABEL=$(basename "$(dirname "$f")")
  grep -q 'brand.css'  "$f" && fail "$LABEL — person profile must not load brand.css" \
                             || pass "$LABEL — brand.css absent (person profile)"
  grep -q 'stats-row'  "$f" && fail "$LABEL — stats-row is brand-only HTML" \
                             || pass "$LABEL — no stats-row (person profile)"
done

# ══════════════════════════════════════════════════════════════════
section "14. SERVICE WORKER CORRECTNESS"
# ══════════════════════════════════════════════════════════════════

if [ ! -f "sw.js" ]; then
  fail "sw.js missing"
else
  # Dynamic BASE URL — hardcoded /Tappd/ breaks on custom domain migration
  grep -q 'new URL.*self.location' "sw.js" \
    && pass "sw.js — dynamic BASE URL (safe for domain migration)" \
    || fail "sw.js — hardcoded base path will break when moving to custom domain"

  # skipWaiting/clients.claim inside waitUntil — fire-and-forget means
  # the browser can terminate the SW before the promise resolves
  grep -q 'skipWaiting' "sw.js" \
    && pass "sw.js — skipWaiting() present (new SW activates immediately)" \
    || fail "sw.js — skipWaiting() missing — users won't get updated SW on next visit"

  grep -q 'clients.claim' "sw.js" \
    && pass "sw.js — clients.claim() present (open tabs use new SW without reload)" \
    || fail "sw.js — clients.claim() missing — open tabs won't get new SW until reload"

  grep -q 'CACHE_VERSION\|CACHE_NAME' "sw.js" \
    && pass "sw.js — cache version string present (bump this when pushing content changes)" \
    || fail "sw.js — no cache version — users may be served stale cached files indefinitely"

  # Each profile must register SW with scope: '../../' — a narrower scope
  # means the SW won't intercept requests for shared assets
  for f in "${ALL_PROFILES[@]}"; do
    [ ! -f "$f" ] && continue
    LABEL=$(basename "$(dirname "$f")")
    grep -q "scope: '../../'" "$f" \
      && pass "$LABEL — SW registered with correct scope (../../)" \
      || fail "$LABEL — SW scope wrong — SW won't intercept asset requests"
  done
fi

# ══════════════════════════════════════════════════════════════════
section "15. SITEMAP & ROBOTS.TXT"
# ══════════════════════════════════════════════════════════════════

# Profiles must appear as proper <loc> entries — not just text anywhere in the file
for path in "u/jignesh/" "u/kalim/" "b/subscriptionloot/"; do
  grep -q "<loc>.*${path}" "sitemap.xml" \
    && pass "sitemap.xml — $path inside a <loc> tag" \
    || fail "sitemap.xml — $path not found inside <loc> tag (Google won't index it)"
done

grep -q 'harsh-padia.github.io/Tappd' "sitemap.xml" \
  && pass "sitemap.xml — correct base URL" \
  || fail "sitemap.xml — wrong base URL"

grep -qi 'sitemap' "robots.txt" \
  && pass "robots.txt — Sitemap: directive present (Googlebot auto-discovers sitemap)" \
  || fail "robots.txt — Sitemap: directive missing (Googlebot won't auto-discover sitemap)"

# ══════════════════════════════════════════════════════════════════
section "16. NO PLACEHOLDER / DEVELOPMENT LEFTOVERS"
# These strings in production mean features are silently broken.
# YOUR_GOOGLE_SCRIPT_URL_HERE means order form submissions go nowhere.
# ══════════════════════════════════════════════════════════════════

PLACEHOLDERS=(
  "YOUR_GOOGLE_SCRIPT_URL_HERE"
  "REPLACE_THIS"
  "INSERT_YOUR"
  "TODO:"
  "FIXME:"
)
found_placeholder=0
for pattern in "${PLACEHOLDERS[@]}"; do
  MATCHES=$(grep -rl "$pattern" . \
    --include="*.html" --include="*.js" --include="*.css" \
    --exclude-dir=.git --exclude-dir=tests 2>/dev/null)
  if [ -n "$MATCHES" ]; then
    warn "Placeholder '$pattern' found — feature may be silently broken: $MATCHES"
    found_placeholder=1
  fi
done
[ "$found_placeholder" -eq 0 ] && pass "No placeholder strings in source files"

# ══════════════════════════════════════════════════════════════════
section "17. JS FILE SYNTAX (node --check)"
# Catches syntax errors before they silently break features in production.
# A syntax error in lead-capture.js means the lead form never works.
# ══════════════════════════════════════════════════════════════════

if ! command -v node >/dev/null 2>&1; then
  warn "node not found — skipping JS syntax checks"
else
  for f in assets/js/*.js; do
    [ ! -f "$f" ] && continue
    if [ ! -s "$f" ]; then
      fail "$f — file is empty"
      continue
    fi
    node --check "$f" 2>/dev/null \
      && pass "$f — syntax valid" \
      || fail "$f — syntax error (would silently break at runtime):"
  done
fi

# ══════════════════════════════════════════════════════════════════
section "18. QR MODAL URL ELEMENT"
# qr.js populates the URL display by targeting id="qrUrl".
# Without this id the URL text is blank in the QR modal.
# ══════════════════════════════════════════════════════════════════

for f in "${ALL_PROFILES[@]}"; do
  [ ! -f "$f" ] && continue
  LABEL=$(basename "$(dirname "$f")")
  grep -q 'id="qrUrl"' "$f" \
    && pass "$LABEL — qr-url element has id=\"qrUrl\"" \
    || fail "$LABEL — qr-url div missing id=\"qrUrl\" — URL will be blank in QR modal"
done

# ══════════════════════════════════════════════════════════════════
section "19. OG IMAGE FILES EXIST"
# Missing OG images show as blank thumbnails on WhatsApp, Twitter,
# LinkedIn when the profile link is shared — first impression failure.
# ══════════════════════════════════════════════════════════════════

declare -A OG_IMAGES=(
  ["assets/img/og-home.png"]="index.html social preview"
  ["assets/img/og-profile.png"]="person profile social preview"
  ["assets/img/og-brand.png"]="brand profile social preview"
)
for img in "${!OG_IMAGES[@]}"; do
  [ -f "$img" ] && pass "$img — present (${OG_IMAGES[$img]})" \
               || warn "$img — MISSING — ${OG_IMAGES[$img]} will show no image on social share"
done

# ══════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════

TOTAL=$((PASS + FAIL + WARN))
echo ""
echo -e "${BOLD}═══════════════════════════════════════${RESET}"
echo -e "${BOLD}  Results: $TOTAL checks run${RESET}"
echo -e "  ${GREEN}✓ Passed:${RESET}  $PASS"
echo -e "  ${RED}✗ Failed:${RESET}  $FAIL"
echo -e "  ${YELLOW}⚠ Warned:${RESET}  $WARN"
echo -e "${BOLD}═══════════════════════════════════════${RESET}"

if [ "$FAIL" -gt 0 ]; then
  echo -e "\n${RED}${BOLD}  PUSH BLOCKED — Fix $FAIL failing check(s).${RESET}\n"
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo -e "\n${YELLOW}${BOLD}  PUSH ALLOWED — $WARN warning(s) need attention.${RESET}\n"
  exit 0
else
  echo -e "\n${GREEN}${BOLD}  ALL CHECKS PASSED — Safe to push.${RESET}\n"
  exit 0
fi
