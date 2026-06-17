# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

COMAYFA is a static multilingual PWA (FR/NL/EN) for a military camp lodging building. No build tool, no bundler, no npm — edit HTML files directly and open in a browser.

- `index.html` — Public info panel (~1150 lines). Served to residents.
- `admin.html` — Admin interface (~2100+ lines). Requires Supabase auth login.
- `sw.js` / `admin-sw.js` — Service workers for offline caching.
- Hosted on GitHub Pages. No server-side logic.

## Data persistence

All app state lives in a single `DATA` object:
- Saved to `localStorage` key `panneau_v4` (offline-first)
- Synced to Supabase table `panneau_data`, row `id=1`, column `data` (JSON blob)
- `SCHEMA_VERSION = 4` — if stored version doesn't match, DEFAULT is used instead
- **When adding new fields to DEFAULT**, bump `SCHEMA_VERSION` in both files and update the migration logic in `loadFromSupabase()`

`DATA.customContent[tabId]` stores content for `libre` and `plan` tab types.

## Tab system

Tabs are defined in `DEFAULT.tabs` and in the user's saved DATA. Each tab has a `type` field. **Adding a new tab type requires changes in both files:**

| Location | What to add |
|----------|-------------|
| `admin.html` `<select id="new-tab-type">` | New `<option value="mytype">` |
| `admin.html` `loadContentEditor()` | `else if(tab.type==='mytype')` dispatcher |
| `admin.html` `buildAdminMyType(tabId)` | Admin editor HTML builder |
| `admin.html` `saveAll()` | Collector that reads DOM into DATA |
| `index.html` `openContent()` | `else if(tab.type==='mytype')` dispatcher |
| `index.html` | `buildMyType(tabId)` render function |

Current types: `regles`, `contacts`, `horaires`, `annonces`, `evenements`, `libre`, `plan`.

## Three-language pattern

Every user-visible string must exist in `{fr, nl, en}` form:
- `tl(obj)` — translates a `{fr,nl,en}` object using the current `LANG`
- `t(key)` — looks up a key in the `I18N` translation table
- `LANG` is `'fr'|'nl'|'en'`, stored in `localStorage` key `panneau_lang`

## Rich text editor (admin only)

`libre` tab type uses TipTap loaded via ESM from `esm.sh`. It loads asynchronously:
- `window.__TipTap` is set when ready, then `tiptap-ready` event fires
- `_tiptapQueue[]` queues `initLibreTipTap(tabId)` calls that arrive before TipTap is ready
- Each editor container stores its instance as `container.__tiptap`
- Hidden `<textarea>` holds the HTML value that gets collected by `saveAll()`

## Known bugs (documented in DEBUG_PROMPT.md)

1. `renderAll()` in `index.html` should call `renderNavGrid()` — currently missing
2. `changeLang()` doesn't re-render sub-menu content when a content panel is open
3. SortableJS drag-handle may not work if the library failed to load from CDN
4. Mobile grid can produce a lone orphan card (fix is documented)

## CDN dependencies

| Library | Used in | Purpose |
|---------|---------|---------|
| `@supabase/supabase-js@2` | both | Cloud sync + auth |
| `SortableJS@1.15.0` | admin | Drag-and-drop tab reorder |
| `mammoth@1.8.0` | admin | DOCX→HTML import |
| `@tiptap/core@2` + extensions | admin | Rich text editor (ESM via esm.sh) |

**`admin-sw.js`** must list the same CDN scripts that are in `admin.html` — keep them in sync when adding/removing CDN libraries.

## Constraints

- Single-file architecture: CSS, JS, and HTML are all inline. No external `.css` or `.js` files.
- Mobile-first design with CSS variables (`--accent`, `--border`, `--text`, etc.).
- `DEFAULT` object must be identical in both `index.html` and `admin.html` — they share the same data schema.
- The admin password is stored in `DATA.pwd` (legacy) and also in Supabase Auth. `changePwd()` updates both.
- `FULL_TABS` in `index.html` lists tab IDs that should always span the full grid width.
- `RED_TABS` in `index.html` lists tab IDs that use the red color scheme (fire/emergency).
