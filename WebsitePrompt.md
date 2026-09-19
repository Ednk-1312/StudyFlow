# Build the StudyOS Website, Complete Brief

You are building a **product website for StudyOS**, a native iOS app. This document contains everything you need: what the app does, what the site must contain, exact design direction, real download/install instructions, a 19-point production-readiness checklist, and hard rules about what not to do. Follow it precisely. **Do not invent features, statistics, testimonials, or claims that are not in this document.**

---

## 1. Product identity

- **Name:** StudyOS
- **Tagline:** Your school, organized automatically.
- **One-liner:** A privacy-first, offline-capable study command center for iPhone, assignments, scanning, materials, AI study tools, a smart timer, and a utility toolbox, all stored on your device.
- **Bundle ID:** `com.Study-Tracking-AIO`
- **Platform:** iOS (iPhone + iPad). No Android. No web app. No account required.
- **Distribution today:** direct download of a signed `.ipa` (sideload), not the App Store. The install section must reflect this honestly.

---

## 2. What StudyOS actually does (complete, accurate feature list)

Use this list verbatim for any feature sections. Nothing may be added, exaggerated, or softened.

### Planner & assignments
- Home ("Today") answers "what should I work on right now?": today's work, a recommended next task, study-session CTA, upcoming deadlines and tests, quick add
- Fast manual entry, record an assignment in seconds via Quick Add; full editor for details
- Priority (Low → Urgent), estimated effort in minutes, notes, rescheduling
- Complete with animated checkmark; **undo completion**; delete with confirmation and **snapshot-based undo** that restores data, reminders, and Spotlight entries
- Deterministic study planner: recommended task order, study blocks, and breaks computed from due dates, effort, priority, exams, and available time, recalculates when tasks go unfinished, never changes deadlines
- Filter by Active / Today / Upcoming / Done / All; filter by class; search title, class, and notes

### Homework scanner
- Camera capture or photo-library import
- On-device text recognition (Apple Vision framework), processed off the main thread
- Editable confirmation screen before anything is saved
- Uncertain extractions are flagged visibly ("couldn't confidently identify the due date"), the app never silently accepts uncertain OCR and never invents missing information

### Materials
- Store PDFs, images, scans, notes, and imported files, organized by subject
- On-device text extraction and local search across titles, subjects, extracted text, and tags
- Associate materials with assignments
- Spotlight indexing so documents are findable system-wide

### Study AI (on-device)
- Summarizer, condense any material
- Concept Explainer, plain-language explanations of topics from your materials
- Flashcards, generate decks from content, with a deck-complete flow
- Interactive Quiz, generate practice questions and quiz yourself
- All processing happens on the device using Apple's Natural Language framework; outputs are study aids, never treated as authoritative school data; failures show real error states with retry (never silent failures, never fabricated content)

### Study timer
- Assignment-linked sessions with planned durations
- Pause/resume, breaks, interruption logging, session history
- At the end, the app **asks** whether the assignment is finished, it never marks work complete on its own

### School calendar
- School-focused day view: assignments, exams, study sessions, deadlines
- Exam countdowns with distributable preparation windows, manually overridable

### Utility toolbox (10 tools, all offline, no account)
1. Grade Calculator
2. What-If Grade Calculator (project final grade from a predicted score)
3. Weighted Grade Calculator
4. GPA Calculator (unweighted and weighted scales)
5. Percentage Calculator
6. Unit Converter
7. Word & Character Counter (with reading/speaking duration)
8. Exam & Assignment Countdown
9. Random Group Generator
10. Study Session History

### Google Classroom (optional, read-only)
- Optional integration, connect to import classes and coursework
- Real OAuth sign-in; tokens stored in the device Keychain; silent token refresh
- Read-only: course list and coursework only; never requests Gmail, Drive, Calendar, or Contacts; never writes back to Classroom
- Graceful failure everywhere: school-blocked accounts see "Your school is restricting this connection, StudyOS still works normally"; offline shows "You can still use your saved assignments"; sync state is always honest (never pretends a sync succeeded)
- **Fully optional: every other feature works without connecting anything**

### System integration
- Four Home Screen widgets: Today's Assignments, Next Assignment, Study Session, Exam Countdown, showing real local data
- Local notifications: due-soon, overdue, and exam reminders with stable identifiers; contextual permission request (never at launch); reminders auto-update on edit and cancel on complete/delete; app works fine if notifications are denied
- App Intents & Shortcuts: add assignment, start study session, mark complete, search materials
- Spotlight indexing of assignments and materials

### Privacy & reliability
- Local-first: assignments, planner data, materials, and study history are stored on the device by default
- No ads, no tracking SDKs, no analytics, no account required, no data sold
- Failed syncs never erase local data; failed saves surface real errors instead of being silently swallowed
- Secrets (OAuth tokens) live only in the Keychain, never in UserDefaults or logs
- Accessibility built in: Dynamic Type, VoiceOver labels and logical focus, Reduce Motion respected, status never communicated by color alone
- Full offline functionality for everything except Google Classroom sync

---

## 3. Download & install section (must be exact and honest)

This is a sideloaded app, not an App Store app. The site must set expectations correctly.

**Download button:** a prominent `Download StudyOS (.ipa)` button linking to the actual file, the site should ship the .ipa as a downloadable asset at a path like `/downloads/StudyOS.ipa` (note the real filename if it differs; the file is ~5.8 MB).

**Install instructions (write them out as numbered steps):**

1. Download `StudyOS.ipa` to your iPhone or Mac.
2. On iPhone (direct): open the file with **Apple Configurator**-style flow, or use the **Finder** method on Mac:
   - **Mac:** connect your iPhone, open Finder, select your iPhone, and drag `StudyOS.ipa` onto the device in the sidebar. Alternatively use Xcode's Devices window.
3. **Trust the developer certificate** (first launch only): Settings → General → VPN & Device Management → tap your Apple Development certificate → **Trust**.
4. Open StudyOS.

**Callouts the page must include:**
- *Signing note:* the app is signed with a personal Apple Development certificate. Free accounts are valid for **7 days** after install; paid developer accounts last up to a year. When it expires, reinstall the latest .ipa.
- *What you need:* an iPhone or iPad on a recent iOS version, and (for the Mac install path) a cable.
- *No App Store:* explain in one calm line that StudyOS is distributed directly while in development, which is why it installs via .ipa.
- *Data note:* installing over a previous version keeps your local data (same bundle ID).

Do **not** write "one-click install" or imply over-the-air installation on the iPhone itself, a raw .ipa download on-device cannot self-install. Be honest about the Mac/Finder step.

---

## 4. Site content map (routes)

This is a **multi-page static site**. Required routes:

- `/`, Home
- `/privacy`, Website & app privacy policy
- `/terms`, Terms of use
- `/accessibility`, Accessibility statement (required; see Secondary pages)
- `/thanks`, Contact form thank-you page (noindex)
- `/404.html`, Custom not-found page (noindex)
- `/downloads/StudyOS.ipa`, the real downloadable file
- `/robots.txt`, `/sitemap.xml`, `/og-image.png`, favicon set

### Home page sections (in order)

1. **Hero**, app name, tagline, primary Download button **above the fold**, secondary "See what it does" anchor. One short honest sub-line, e.g. "Free, offline-first, no account. Your data never leaves your device unless you connect Google Classroom."
2. **Feature overview**, the six pillars: Planner, Scanner, Materials, Study AI, Timer, Widgets. Tight copy, no marketing fluff.
3. **Full feature list**, the complete list from Section 2, organized under the same headings. This can be a structured grid or accordion; keep it scannable.
4. **Privacy**, plain-language privacy section. State exactly: local storage by default, no ads/tracking/analytics, Keychain for tokens, Google Classroom is the only external service and is optional and read-only. Never say "100% on-device" without the Classroom exception.
5. **Download & install**, Section 3 above, verbatim in spirit.
6. **FAQ**, at minimum: Is it free? Does it need an account? Does it work offline? What happens if my school blocks Google Classroom? How long does signing last? Does it collect data? Is there an App Store version? (Answer: not currently, direct download while in development.)
7. **Contact**, short section (or footer block) with a simple contact form and the contact details required by checklist item 19 in Section 7.
8. **Footer**, version (1.0), platform (iOS), links to Privacy, Terms, **Accessibility**, Contact, copyright, small privacy note.

Optional but valuable: a small "Made for students" strip listing the 10 utility tools by name.

### Secondary pages

- **/privacy**, Honest website + app privacy policy. Website side: static pages, what the server does and does not log, whether analytics runs (see checklist, if enabled, name the provider and exactly what it collects; if disabled, say "this site collects nothing"). App side: local storage by default, Keychain for tokens, Google Classroom as the only external service (optional, read-only), notifications behavior, data deletion (delete the app → data is gone). No fabricated legal guarantees, no "we take privacy seriously" filler, concrete statements only.
- **/terms**, Plain-language terms: app provided as-is for personal/educational use, no warranty, distribution method (direct .ipa, not App Store), signing/expiry reality (free accounts: 7 days), user responsible for complying with school device policies, Google Classroom usage governed by Google's terms, content the user creates remains theirs, limitation of liability. Short, readable, honest.
- **/accessibility**, A real accessibility statement for the website, following the W3C/WAI recommended structure (not a three-line pledge). Required contents:
  - **Commitment**: one plain sentence that the site is intended to be usable by everyone, including people using screen readers, keyboard-only navigation, magnification, and reduced-motion settings.
  - **Conformance status**: "Designed to conform to WCAG 2.2 Level AA." State honestly that this is a target for the site's design and markup, not a certified audit. Never claim conformance the site hasn't verified.
  - **Measures taken**: semantic HTML landmarks and heading order; visible keyboard focus; skip-to-content link; 44px+ tap targets; text alternatives for meaningful images; contrast-checked dark palette; `prefers-reduced-motion` respected; forms with real labels, inline error messages announced via `aria-live`.
  - **Known limitations**: a short honest list, e.g. the downloadable app file itself cannot be described in full from the web page; any third-party embeds (analytics) are kept cookieless and minimal. If the owner later adds content types the statement doesn't cover, the statement must be updated, leave it editable, not hardcoded prose.
  - **Feedback**: the same real contact email from checklist item 19, with a stated response expectation (e.g. "within 5 business days") and an invitation: "If any part of this site is difficult for you to use, tell me and it will be fixed."
  - **Technical specifications**: site relies on HTML, CSS, and progressive JavaScript; statement of which browsers/platforms were checked (latest Chrome, Safari, Firefox on desktop and iOS).
  - **Assessment approach**: self-evaluation (manual review with keyboard-only navigation, screen reader spot-check, automated checks with axe or Lighthouse), name the actual method, dated. Include the date of the statement so updates are visible.
  - Meta title "Accessibility | StudyOS", noindex not required (this page is indexable and is a trust signal).
- **/thanks**: shown after a successful contact form submission. Reinforces what happens next ("Message sent. I'll reply at the email you provided."), links back home. Never reachable as a fake success for a failed submission.
- **/404.html**: custom 404 matching the site design. "Page not found", one line of help, links to Home and Download. Never a default server error page.

---

## 5. Design direction, dark mode

The site is **dark mode only**. It should feel like a calm, premium Apple-adjacent product page: think a quieter Apple.com dark page, not a gaming site or a neon SaaS template.

### Palette
- **Background:** near-black, slightly warm: `#0A0B0A` to `#0E100E`
- **Surface:** `#151815` (cards, panels, used sparingly)
- **Border/hairline:** `#262B26` at ~1px
- **Text primary:** `#F2F3F0`
- **Text secondary:** `#9BA19B`
- **Accent:** the StudyOS evergreen, **light variant `#63BB8F` / deep variant `#1E6E5A`** (match the app icon's green). Accent used for CTAs, links, and small highlights only.
- **Danger/warning accents** only where honest (e.g., signing-expiry note): muted amber `#D9A441`.

No purple, no neon cyan, no rainbow coloring, no harsh gradients, no glow effects, no blobs, no glassmorphism or liquid-glass panels, no radial orbs or background light sources of any kind, no pastel accents, no pure white surfaces. Depth comes from flat surface color and 1px hairlines only.

### Typography
- System font stack: `-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Segoe UI", Roboto, sans-serif`
- **Do not use Inter, Geist, Space Grotesk, or similar trendy web fonts.** The system stack above is the entire typography system; no display font paired on top
- Hero: large, tight tracking, semibold, not giant; restrained
- Clear hierarchy: section titles (semibold, ~28–34px), body (16–17px, secondary color for support text), metadata (13–14px)
- No novelty fonts, no all-caps walls, no gradient text

### Layout & components
- Generous but purposeful whitespace; content column ~1100px max, readable measure
- Feature sections: text + visual alternation, NOT uniform card grids. **Never three (or any fixed count of) feature cards in a row; never bento grids.** Where a grid is needed (utility tools list), use a simple, tight, hairline-divided list, not floating rounded cards
- **No drop shadows anywhere**, on any element, at any blur radius. Borders and surface color do the work
- **Corner radius: minimal.** 8px max on buttons and inputs; no pill-shaped soft cards, no oversized rounded containers
- **No colored left-edge stripes** on cards, rows, or callouts
- Buttons: solid accent primary ("Download StudyOS"), quiet bordered secondary. Comfortable hit areas
- **Hover behavior: color or background change only.** No hover animations, transforms, lifts, scales, or transitions that move pixels
- Subtle scroll-triggered reveals allowed (fade/translate 12–16px, once, fast); respect `prefers-reduced-motion`. **No animated arrows, no looping or decorative motion**
- **No dot-grid or graph-paper background patterns, no decorative sparkle/AI icons (✨), no terminal-window styling anywhere on the site**
- Phone mockup in hero showing the Home screen is welcome, use a real screenshot when available, keep it tasteful and abstract if not (do not fabricate a fake detailed UI screenshot that misrepresents the app). The site must show the real app somewhere; abstract placeholder art standing in for the product is a failure
- Section transitions: hairline dividers, not colored bands

### Copy tone
- Calm, concrete, confident. No exclamation marks. No emoji anywhere in copy or UI. No "Unleash your potential."
- **Never use the "It's not X. It's Y." rhetorical construction.** Say what the product is, directly
- **No em dashes in page copy.** Use periods, commas, or colons instead
- **No checkmark-bullet lists.** Feature lists are plain rows (hairline-divided) or prose; no ✓/✦/• decoration spam
- **No pricing tiers or pricing tables.** The app is free; one quiet line says so ("Free. No account required.")
- Write like an experienced product team: short declarative sentences, real specifics ("Reminders update when an assignment changes and cancel when it's deleted.")
- Every claim must trace to Section 2. Nothing invented: no user counts, no ratings, no testimonials, no awards.

---

## 6. Technical requirements

- **Responsive:** desktop, tablet, mobile; content reflows cleanly at 360px width
- **Semantic HTML** with proper landmarks (`header`, `nav`, `main`, `section`, `footer`), heading order, alt text
- **Accessibility:** WCAG AA contrast on dark background, visible focus states, keyboard navigable, `prefers-reduced-motion` respected, sufficient link/button affordances
- **Performance:** no heavy frameworks required, plain HTML/CSS/JS or a lightweight static build; hero must render fast; lazy-load any images; total JS minimal
- **SEO/meta:** title "StudyOS | Your school, organized automatically", meta description matching the one-liner, Open Graph tags, favicon (green book/checkmark motif), theme-color `#0A0B0A`
- **Download link** must point at the real .ipa with a `download` attribute; show file size (~5.8 MB) next to it
- Analytics (if enabled per checklist) must be a cookieless privacy-preserving provider; if a cookie-setting provider is used instead, the cookie banner is mandatory. No newsletter modals, no popups
- **Sticky mobile CTA**: a slim fixed bottom bar on mobile (below ~768px) with "Download StudyOS", appears after scrolling past the hero, hides over the download section itself (no redundant CTA), never covers footer text, respects safe-area insets
- **Loading states**: any async element (contact form submit, analytics-independent lazy images) shows a real state, skeleton or inline spinner on the submit button ("Sending…", disabled), never a fake progress bar
- **Form error states**: the contact form validates inline per-field (name, valid email format, message length) with specific messages under each field ("Enter a valid email"), an aria-live error summary, red hairline on invalid fields plus an icon (never color alone), and preserved input on failure. Success redirects to /thanks

---

## 7. Backend & security requirements (mandatory)

The site is static-first. The only dynamic surface is the **contact form** (and, if used, a download counter). That backend must be engineered to real security standards, the following three requirements are hard, not optional:

### 7.1 Keep keys off the front end (absolute rule)

- **No secret may ever ship to the browser.** No API keys, mail-provider tokens, database service-role keys, or signing secrets in client JS, HTML, localStorage, or `NEXT_PUBLIC_*` / `VITE_*` style variables
- All third-party credentials (mail provider, analytics if server-side, database service role) live **only in server-side environment variables** of the serverless function/host, never in the repo
- `.env*` files are gitignored from commit one; the build must fail the leak scan if a known secret pattern reaches the client bundle
- The **only** credentials a browser may hold are explicitly-public anonymous keys (e.g., a Supabase `anon` key), and those are safe **only because** the RLS policies in 7.2 make them harmless. Every such key must be documented as public-by-design
- The contact form posts to a serverless function; the function holds the mail API key and sends server-side. The client never talks to the mail provider directly

### 7.2 Row-Level Security (RLS) on every table

If any database is used (e.g., Supabase/Postgres for contact submissions):

- **RLS enabled on every table, default-deny**, no table is ever readable or writable by the anonymous role unless a policy explicitly allows it
- The `contact_messages` table exposes exactly one policy: `anon` may **INSERT** (with column restrictions). No SELECT, UPDATE, or DELETE for anon or authenticated-web roles, ever
- Reading/administering messages happens only with the **service role, server-side only** (e.g., a protected admin route or direct DB access), never through the client
- Every other table (download counters, aggregates) follows the same pattern: anon can at most increment via an RPC that validates input; raw table access denied
- If the finished site uses **no database at all**, state that explicitly on an architecture note, and any future database must adopt this default-deny posture before launch

### 7.3 Rate limiting on all routes (server-side only)

- **Contact form:** aggressive limits per IP, e.g., 5 submissions/hour, burst of 2/minute, plus a honeypot field and minimum-fill-time check. 429 responses include `Retry-After` and a calm user-facing message ("Too many messages from this connection. Try again in a few minutes.")
- **Download route:** per-IP cap (e.g., 30/hour) to stop scripted abuse without affecting real users; serve the file with correct headers so normal downloads are never throttled below that
- **Page routes:** rate-limited at the edge/host level (Cloudflare, Vercel WAF, or equivalent), reasonable baseline to absorb scrapers/bots
- **All limits are enforced server-side or at the edge.** Client-side throttling is UX polish, never security, an implementation that only limits in JavaScript fails this requirement
- Rate-limit state must survive function restarts (use the platform's edge KV/rate-limit primitive, not in-memory counters)

### 7.4 Baseline hardening (comes with the above)

- **Security headers on every response:** strict Content-Security-Policy (no `unsafe-inline` for scripts where practical), `X-Frame-Options: DENY` or CSP `frame-ancestors 'none'`, HSTS, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy` minimal
- Server-side validation of every input (length, format, type), client validation is UX only
- **No PII in logs:** function logs must never contain message bodies, emails, or IP addresses beyond what the host requires
- CORS: the API function accepts requests only from the site's own origin
- Dependencies minimal and audited (`npm audit` clean at handoff)

## 8. Production-readiness checklist (all 19 required)

Every item below must actually be implemented and verifiable in the finished site, not planned, not stubbed:

1. **Custom 404 page**, designed `/404.html`, consistent with site styling, links Home + Download; configured as the host's error page
2. **CTA above the fold**, Download button visible at 100% viewport height on desktop *and* mobile without scrolling
3. **Meta title per page**, unique per route ("Privacy | StudyOS", "Terms | StudyOS", etc.), ≤60 chars
4. **Meta description per page**, unique, accurate, ≤155 chars per route
5. **Open Graph image**, real `/og-image.png` (1200×630): StudyOS name, tagline, evergreen accent on the dark background; referenced with absolute URL + width/height/alt meta on every page
6. **Favicon set**, ICO/PNG fallbacks (16, 32, 180 apple-touch, 192, 512) + SVG favicon, all referencing the green book/checkmark motif
7. **robots.txt**, allows all, references sitemap, disallows `/thanks`
8. **sitemap.xml**, every indexable route (`/`, `/privacy`, `/terms`, `/accessibility`) with correct `lastmod`; `/thanks` and `/404.html` excluded
9. **Alt text on every image**, meaningful, specific ("StudyOS Today screen showing two assignments due tomorrow"); decorative images get empty alt; OG image described in meta
10. **Mobile breakpoints**, verified at 360, 390, 768, 1024, 1440px; no horizontal scroll, no clipped text, tap targets ≥44px
11. **Sticky mobile CTA**, as specified in Section 6
12. **Loading states**, as specified in Section 6
13. **Form error states**, as specified in Section 6
14. **Thank-you page**, `/thanks` reached only after real successful submission, noindex
15. **Privacy policy page**, `/privacy` covering both the website and the app, per Section 4
16. **Terms page**, `/terms` per Section 4
17. **Cookie banner**, only if analytics sets cookies. **Default recommendation: use a cookieless provider (Plausible or Fathom), declare that choice on /privacy, and skip the banner entirely.** If a cookie-based provider is chosen instead, implement a real consent banner (accept/decline, actually gates the script, remembers choice), never a fake banner
18. **Analytics installed**, one privacy-preserving provider configured and verified receiving pageviews on the deployed site; name it on /privacy ("This site uses Plausible Analytics, which collects no personal data and sets no cookies"). If the user opts for no analytics, this line becomes "This site collects no analytics" and items 17–18 are satisfied by that declaration
19. **Real contact address**, a contact block the owner fills in before launch: email plus one of (mailing address OR city/region OR a working contact form with response-time expectation). Ship with clearly marked placeholders the user replaces, do not invent a fake address and do not launch with placeholders in place

---

## 9. Things that would get the site rejected in review

- Any feature not in Section 2 (especially: no cloud sync claims, no Android, no web app, no AI chat, no "unlimited AI" claims)
- Fake statistics, fake testimonials, fake screenshots that misrepresent the app
- "100% on-device" stated without the Google Classroom exception
- Claiming App Store availability or one-click iPhone install
- Promise of notification reliability that overstates iOS behavior, say "local reminders," not "guaranteed push"
- A two-paragraph fake accessibility pledge instead of the structured statement specified in Section 4; an accessibility statement that claims verified AA conformance with no assessment described
- Enthusiasm-stuffed copy, emoji in headings, exclamation marks
- Any AI-site visual tell, including: Inter/Geist/Space Grotesk typography, drop shadows, bento grids, three-cards-in-a-row layouts, colored left stripes, terminal windows, radial orbs, dot-grid backgrounds, sparkle icons, animated arrows, liquid glass, hover animations, checkmark bullet spam, oversized soft corner radii, pastel accents, purple-and-black color schemes, pricing tiers
- Copy tells: em dashes, "It's not X, it's Y" constructions, fake testimonials
- Abstract placeholder art standing in for the real product (the site must show actual StudyOS screens)
- Purple/blue AI gradients, glass cards, neon glows, decorative blobs
- A fake cookie banner that doesn't gate anything, fake analytics claims, or a fabricated contact address
- **Any secret in client-sent code, missing RLS on a live table, or rate limiting that exists only in JavaScript**, automatic rejection
- Checkbox theater: any of the 19 checklist items present as a stub (empty 404, placeholder OG image, banner that never fires) counts as missing
