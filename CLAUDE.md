# JHG — CLAUDE.md

## Project Overview

Personal portfolio site for Jordon H Griffin — Telecom & Systems Professional.
Live at: `https://jordonhgriffin.com` (canonical: `https://www.jordonhgriffin.com/`)
GitHub repo: `https://github.com/jordonhgriffin/jhg`

Hosted on **Cloudflare Pages**. Push to `main` triggers deploy.
Config: `wrangler.toml` — project name `jordonhgriffin-com`, build output dir `.`

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

Only Cloudflare Pages. Push to `main` triggers deploy.
To manually deploy: `npx wrangler pages deploy .`

Custom domain is managed in Cloudflare dashboard → Pages → jordonhgriffin-com → Custom domains.
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
