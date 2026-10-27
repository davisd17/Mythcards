# Handoff — 2026-10-17 (mobile playtest pass)

## State
- Pulled `ec44045` (six-pose attack animations for all 14 roster characters, tarot guidebook, `tools/serve_web_lan.mjs`). All 14 have attack entries in `wardrobe.json`, and the attack-art contract tests pass.
- Built in this session and committed (see the git log for the 2026-10-17 commit):
  - **Tap fix:** a tap on Android selected and then deselected (touch plus emulated mouse). Taps are now mouse-only and fire on release, at the press position.
  - **Wi-Fi load:** figure art imports as lossy WebP 0.85 (.pck 34 MB → 13 MB). `serve_web_lan.mjs` serves Brotli (engine 38 MB → 8 MB), with `no-cache` and ETag revalidation (304 on unchanged files).
  - **Glossary:** `data/glossary.json` → `Glossary` (links in card text), `TermPopup`, board long-press / right-click, and Menu → Glossary.
  - **Type icons:** geometry symbols (`TypeIcon`, the "Elemental set"), an Ember flame, Shield/Marked/Memory icons, and II/III levels.
  - **Pinch zoom:** up to 2.5×, one-finger pan while zoomed, the 1:1 chip or a double-tap to reset (`GameBoardView.zoom` / `_pan`).
  - **Layout tidy:** deck count in the header, a single chip row, full-card art at 380 so L1–L3 fit, and a strip with a 2×2 stat grid and a fade-out.
  - Recorded in `LLD-presentation.md` 9A ("Mobile feedback 2026-10-17").
- Tests: 550 GUT, 26 Playwright, all passing. Both builds are current (web `build/web`, exe `build/windows/MythCards.exe`).
- The phone server runs from `D:\mythcards\build\web` on https://192.168.254.38:8060 (the cert is in `C:\Users\Drew\Documents\MythCards\build\`). It doesn't restart on reboot.

## Decisions (designer, this session)
- "Build" means every export preset (web + Windows exe). Saved in memory.
- Definitions: tap an underlined term on a card, and long-press a piece on the board.
- Type symbols: the Elemental set (Leader circumpunct, Hero 8-point star, Warrior triangle, Mount spiral, Specialist square-in-circle, Mystic vesica piscis, Common ring).
- UI scope: fix and tidy now; a full HUD redesign spec comes later.
- Zoom: one-finger drag pans, and a tap still acts.

## Open questions
- `[NEED: designer review]` the glossary wording in `data/glossary.json`. Check in particular the Leak and line-of-sight conflict: the ruling says Leaks don't block line of sight, while the PRD says placed objects do.
- Should the CLAUDE.md rule "Build = all export presets; report each timestamp" be added? (Proposed, not yet approved.)
- Should lossy WebP become the project-wide importer default, so new art is compressed automatically? Currently it's set per file on the 100 figure images only.
- `C:\Users\Drew\Documents\MythCards` is a second, stale clone. Delete it or keep serving only from D:?
- Pinch, pan and long-press were verified with simulated touch only, not yet on the Android phone.

## Next steps
1. Phone retest: one-finger select, pinch, pan, long-press, term links, and the full card showing L3.
2. Review the glossary text.
3. Write the full HUD redesign spec (typography, frames, iconography) for approval.
4. Push to GitHub when ready (nothing pushed this session).
