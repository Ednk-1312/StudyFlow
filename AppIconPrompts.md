# StudyOS App Icon — AI Image Prompts

Paste these into any image generator (ChatGPT/GPT-Image, Midjourney, Ideogram, etc.).
Generate at **1024×1024, square**. The project's `AppIcon.appiconset` already has the
light/dark/tinted slots wired for iOS 18 — it just needs the three PNGs.

## Rules every variant must follow (baked into the prompts)

- **Light (default):** full color, opaque background edge-to-edge, no transparency.
- **Dark:** same composition, but a *darker ground with a brighter glyph* — not the light icon dimmed.
- **Tinted:** pure grayscale. iOS recolors it with the user's tint, so it must read as a bold silhouette.
- All three must share **the same glyph and composition** — only the color treatment changes.
- No text, no letters, no numbers. No rounded corners (iOS applies its own mask).
- No gradients-for-style, no glass, no photorealism, no drop shadows, no decorative clutter.

## Palette (matches the app's calm, non-"AI-startup" direction)

- **Primary:** deep evergreen / ink-teal glyph on warm off-white ground (`#F6F4EF`), dark ground `#0E1416`.
- **Alternate:** ink-indigo glyph on paper-white ground, dark ground `#101019`.

---

## Concept A — Book + Checkmark (recommended)

The pages of an open book curve up into a checkmark: study, done, trustworthy.

**Light:**
```
Flat minimal iOS app icon, square 1024x1024. A single centered glyph: an open book seen from the front, its two pages curving upward to form a subtle bold checkmark. Deep evergreen-teal glyph (#14665C) on a solid warm off-white background (#F6F4EF). Flat vector style, crisp edges, generous padding around the glyph (about 15% margin on all sides), background fills the entire canvas edge to edge, opaque. Calm scholarly Apple-system aesthetic. No text, no letters, no border, no rounded corners, no drop shadow, no gradient, no glassmorphism, no photorealism.
```

**Dark:**
```
Flat minimal iOS app icon, square 1024x1024, dark mode variant of the same design: a single centered glyph of an open book seen from the front, its two pages curving upward to form a subtle bold checkmark. Soft pale sage-green glyph (#9FD8CB) on a solid very dark ink-teal background (#0E1416). Flat vector style, crisp edges, generous padding, background fills the entire canvas, opaque, glyph clearly brighter than the ground. Calm scholarly Apple-system aesthetic. No text, no letters, no border, no rounded corners, no drop shadow, no gradient, no glassmorphism, no photorealism.
```

**Tinted:**
```
Flat minimal iOS app icon, square 1024x1024, pure grayscale monochrome version of this design: a single centered glyph of an open book seen from the front, its two pages curving upward to form a subtle bold checkmark. Light gray glyph on a solid near-black background, high contrast, reads clearly as a bold silhouette. Flat vector style, crisp edges, generous padding, opaque background filling the entire canvas. Absolutely no color, no text, no border, no rounded corners, no drop shadow, no gradient.
```

---

## Concept B — Stack of Cards + Bookmark (planning/organization)

**Light:**
```
Flat minimal iOS app icon, square 1024x1024. A single centered glyph: two overlapping rounded index cards stacked at a slight angle, with a bold bookmark ribbon descending from the top card. Deep evergreen-teal glyph (#14665C) on a solid warm off-white background (#F6F4EF). Flat vector style, crisp edges, generous padding (15% margin), background fills the entire canvas, opaque. Calm scholarly Apple-system aesthetic. No text, no letters, no border, no rounded corners, no drop shadow, no gradient, no glassmorphism, no photorealism.
```

**Dark:**
```
Flat minimal iOS app icon, square 1024x1024, dark mode variant of the same design: two overlapping rounded index cards stacked at a slight angle with a bold bookmark ribbon descending from the top card. Soft pale sage-green glyph (#9FD8CB) on a solid very dark ink-teal background (#0E1416). Flat vector style, crisp edges, generous padding, opaque background, glyph clearly brighter than the ground. Calm scholarly Apple-system aesthetic. No text, no letters, no border, no rounded corners, no drop shadow, no gradient, no glassmorphism.
```

**Tinted:**
```
Flat minimal iOS app icon, square 1024x1024, pure grayscale monochrome version of this design: two overlapping rounded index cards stacked at a slight angle with a bold bookmark ribbon descending from the top card. Light gray glyph on a solid near-black background, high contrast, reads clearly as a bold silhouette. Flat vector style, crisp edges, generous padding, opaque background. Absolutely no color, no text, no border, no rounded corners, no drop shadow, no gradient.
```

---

## Concept C — Book + Study-Timer Dial (study sessions)

**Light:**
```
Flat minimal iOS app icon, square 1024x1024. A single centered glyph: a closed book in profile with a small circular timer dial overlapping its lower corner, the dial showing a single bold progress arc. Deep evergreen-teal glyph (#14665C) on a solid warm off-white background (#F6F4EF). Flat vector style, crisp edges, generous padding (15% margin), background fills the entire canvas, opaque. Calm scholarly Apple-system aesthetic. No text, no letters, no border, no rounded corners, no drop shadow, no gradient, no glassmorphism, no photorealism.
```

**Dark:**
```
Flat minimal iOS app icon, square 1024x1024, dark mode variant of the same design: a closed book in profile with a small circular timer dial overlapping its lower corner, the dial showing a single bold progress arc. Soft pale sage-green glyph (#9FD8CB) on a solid very dark ink-teal background (#0E1416). Flat vector style, crisp edges, generous padding, opaque background, glyph clearly brighter than the ground. Calm scholarly Apple-system aesthetic. No text, no letters, no border, no rounded corners, no drop shadow, no gradient, no glassmorphism.
```

**Tinted:**
```
Flat minimal iOS app icon, square 1024x1024, pure grayscale monochrome version of this design: a closed book in profile with a small circular timer dial overlapping its lower corner, the dial showing a single bold progress arc. Light gray glyph on a solid near-black background, high contrast, reads clearly as a bold silhouette. Flat vector style, crisp edges, generous padding, opaque background. Absolutely no color, no text, no border, no rounded corners, no drop shadow, no gradient.
```

---

## Tips

- **Keep all three consistent:** in tools that accept a reference image (ChatGPT, Midjourney
  `--sref`), attach the light icon when generating dark and tinted so the glyph matches exactly.
- Midjourney: append `--v 6 --style raw` and use a 1:1 canvas; avoid `--stylize` above 50.
- If the model draws rounded corners or adds a border, regenerate — iOS masks the square itself.
- Want the alternate palette? Swap the two hex pairs in the prompt:
  glyph `#2E3A8C`, light ground `#F7F7FA`, dark ground `#101019`.

## After you generate

Save the three picks as `AppIcon-light.png`, `AppIcon-dark.png`, `AppIcon-tinted.png`
(1024×1024) and I'll place them in the asset catalog, wire `Contents.json`, and rebuild the .ipa.
