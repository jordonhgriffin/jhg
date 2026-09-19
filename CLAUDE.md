# JHG — CLAUDE.md

## Project Overview

Personal portfolio site for Jordon H Griffin — Telecom & Systems Professional.
Live at: `https://jordonhgriffin.com` (canonical: `https://www.jordonhgriffin.com/`)
GitHub repo: `https://github.com/jordonhgriffin/jhg`

Hosted on **Cloudflare Pages**. Push to `main` triggers deploy (the Pages project is git-connected).
Config: `wrangler.toml` — project name `jhg`, build output dir `.`

Pages project `jhg` serves `jordonhgriffin.com` and `www.jordonhgriffin.com`.
Preview URL pattern: `https://<deployment-id>.jhg-dhc.pages.dev`

Do not re-add `wrangler.jsonc` (Workers config) — it conflicts with Pages and was intentionally removed.

---

## Structure

```
/
├── index.html          # Single-page portfolio (primary file)
├── template.html       # Layout/style reference template
├── grid-only.html      # Grid layout test file
├── img/                # All images (same folder as HTML — intentional)
├── robots.txt
├── sitemap.xml
├── wrangler.toml
├── vscode-settings/    # VS Code profiles and theme (intentionally committed)
│   ├── profile-3-6-2026.code-profile
│   ├── profile-3-11-2026.code-profile
│   └── vscode-workbench-theme
└── .vscode/
```

---

## Versioning

Format: `YY.M.D.revision` — example: `26.4.8.3`

Every release updates two places in `index.html`:
1. HTML comment on line 2: `<!-- Version YY.M.D.revision - description of change -->`
2. Footer: `<footer>Version YY.M.D.revision</footer>`

Descriptions summarize what changed in that session. Keep them concise.

---

## Material Layer (page background / paper surfaces)

Added 26.9.18.3, converted to all-tile 26.9.18.4. Textures in `img/`:

| Light | Dark | Applied to |
|---|---|---|
| `light_wood_tile.jpg` | `dark_stars_tile.jpg` | Page background (behind everything) |
| `light_paper_tile.jpg` | `dark_paper_tile.jpg` | `.section-island`, `#navigation ul`, `#nav-buttons`, `#mobile-navigation`, `footer` |

Every surface is now a **seamless repeating tile**, not a `cover` image — including
the light-mode wood and paper, which originally used `cover`/`no-repeat` on the raw
`light_wood.jpg`/`light_paper.jpg`. Those raw (non-tile) files are kept in `img/` as
sources; only the `_tile.jpg` variants are referenced from CSS.

CSS custom properties (defined at the END of `index.html`'s stylesheet, after all
the historical duplicate rules so they win on order):

```
--wood-image     /* page backdrop image (tile)   */
--wood-size      /* backdrop tile size — differs per theme */
--wood-repeat    /* always `repeat` now */
--paper-image    /* paper surface image (tile)   */
--paper-size     /* paper tile size, e.g. 384px 384px */
--paper-wash     /* translucent tint laid over the paper via linear-gradient */
--wood-fallback  /* solid color shown before/without the backdrop image */
```

Implementation notes:

- **Both light and dark backdrops are tiles**, not cover images. Displaying a tile
  smaller than its native pixel size keeps grain/stars from looking magnified —
  `dark_stars_tile.jpg` (658×986) renders at `--wood-size: 493px 739px`;
  `light_wood_tile.jpg` (512×512) renders at `384px 384px`.
  **Why tiles at all:** a `cover` image gets scaled up on wide/tall viewports,
  which visibly magnifies fine texture (wood grain, stars) past their natural
  scale. A tile displayed below its native resolution sidesteps this regardless
  of viewport size.
- **Generating a new tile**: crop a square (or the target aspect) region from the
  source photo, downscale to the working tile size, flatten the image's
  low-frequency brightness gradient (Gaussian-blur the image, subtract
  `blurred - mean` from the original) — that gradient is what makes a naive tile
  grid visibly repeat — then make it seamless with an offset+blend: `np.roll` the
  image by half its width/height so the original edges land at the center, then
  blend a feathered band symmetrically around that new center seam (average each
  row/column with its mirror across the center). This offset+blend approach
  produced cleaner seams than mirror-padding the raw edges, especially on
  low-contrast textures (the dark paper tile needed `blur_radius=64, feather=250`
  to fully hide its seam — low-contrast/near-black source images need much wider
  feathering than higher-contrast ones like wood grain).
  Verify with a 3×3 tiling before wiring into CSS.
  `dark_stars.jpeg`/`.jpg`, `light_wood.jpg`, `light_paper.jpg`, `dark_paper.jpg`
  are kept in `img/` as sources for regeneration.
- **Paper** uses two stacked `background-image` layers: `linear-gradient(--paper-wash)`
  on top of the tile photo. The wash is what keeps body text readable — light mode uses a
  strong `rgba(255,252,245,0.42)` over warm beige paper, dark mode a subtle
  `rgba(255,255,255,0.07)`. The wash layer stays `background-size: cover` (it's a
  flat gradient, not a texture); only the photo layer uses `var(--paper-size)` + `repeat`.
- Paper uses `background-attachment: fixed` so every island samples the *same* paper
  region (consistent look, no per-island cropping). A `@media (max-width: 768px)`
  block overrides this to `scroll` with a `320px 320px` tile — iOS Safari mishandles
  `fixed` on non-root elements. Only the photo layer's size changes on mobile; the
  wash layer stays `cover` there too.
- Tron canvas (`z-index: 0`) and the grid (`body::before`, `z-index: -1`) still sit
  above the backdrop and below the content. Dark-mode Tron remains visible over the stars.
- The rules are appended **after** the existing `.section-island` / nav / footer
  declarations on purpose — the stylesheet has many historical duplicate background
  rules and this block must win on cascade order. **Do not move it above them.**

The same block is mirrored at the end of `template.html`'s stylesheet so new pages
built from the template inherit the material layer. If the sister
Mind of Jordon site should match, port the same block there (it uses the same
Roboto/theme conventions).

### Duplicate-rule cascade trap (read before editing nav/theme CSS)

This stylesheet has many historical duplicate selectors for the same element
(CLAUDE.md has always called this out — see "Structure" above). Editing the
*losing* (earlier) copy of a rule has no visible effect and is easy to think you've
fixed something when you haven't. Two bugs hit this directly in the 26.9.18.4 session:

- **`--border-color` in dark mode** was silently redefined by a second,
  later `[data-theme="dark"] { --border-color: var(--glow-color); }` block
  (an opaque `#f3f3f3`) that shadowed the correct, earlier
  `--border-color: rgba(255, 255, 255, 0.2)`. This made `#nav-buttons`'s border
  render solid white instead of subtle. **Removed** — don't reintroduce a
  `--border-color` override outside the single root theme block.
- **`transform: translateX(-5px)` on `#navigation a:hover`** was set in an
  *earlier* duplicate rule. A later "fix" rule removed the hover's horizontal
  shift by simply *omitting* `transform` from the winning rule — but CSS cascades
  per-property, not per-rule-block, so the earlier rule's `transform` was still
  the only declared value and kept applying. The fix had to explicitly set
  `transform: none` on the winning rule, not just leave it out.

**Lesson: when neutralizing a property from a duplicate rule, always set it
explicitly (e.g. `transform: none`) on the winning rule — never just omit it**,
or an earlier duplicate can still win that one property.

Also: a stale one-off patch block (`/* Nav menu alignment... */`, previously near
the end of `index.html`'s stylesheet) was added in an earlier session to fix this
same nav-hover-alignment issue via `padding-left/right/bottom: 10px` on
`#navigation ul` and an `::before` pseudo-element active-marker. It was removed
26.9.18.4 because it conflicted with the real fix (zero `ul` padding, `li` margins
removed, `width: 100%` + `box-sizing: border-box` on `#navigation a`). If nav
alignment issues resurface, check for reintroduced padding/margin on
`#navigation ul`/`li` before adding a new patch on top.

---

## Sister Site — Mind of Jordon

`mind-of.jordonhgriffin.com` — repo at `/Users/jordonhgriffin/Documents/GitHub/jordonhgriffin/Mind-of/`

Both sites share the **same domain** (jordonhgriffin.com subdomain) and the **same layout conventions**:
- Font: Roboto (100, 300, 400, 700) from Google Fonts
- Light/dark mode via `[data-theme="dark"]` and CSS custom properties
- Same versioning format
- Same nav structure pattern

**When making layout, style, or structural changes to one site, check whether the same change should apply to the other.** Ask if unsure.

---

## Theme

Light and dark mode via `[data-theme="dark"]` CSS selector and CSS custom properties (`--dark-bg`, `--text-color`, `--border-color`, `--grid-color`, etc.).

Font: Roboto (100, 300, 400, 700) from Google Fonts.

---

## Deployment

Only Cloudflare Pages. Push to `main` triggers deploy (git-connected Pages project `jhg`).
To manually deploy: `npx wrangler pages deploy . --project-name jhg --branch main`

Note: `wrangler.toml` in the repo root is read by Pages, but `npx wrangler pages deploy`
does NOT reliably pick the project name up from it — pass `--project-name jhg` explicitly.

Custom domain is managed in Cloudflare dashboard → Pages → jhg → Custom domains.
DNS is handled by Cloudflare automatically when the custom domain is added there.

---

## .gitignore

```
.wrangler
.dev.vars*
.env*
.claude/
.playwright-mcp/
```
