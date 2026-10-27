# MythCards coming-soon website

Universe-first site centered on the MythCards tactical game and its lore. The
first tarot deck is promoted above the navigation as the first upcoming release,
under its approved marketing title
**Dreams of the North**, with subtitle **A MythCards Tarot**. This does not rename canonical
deck IDs, source art, or guidebook data. No purchases,
preorders, email collection, accounts, or payment integration are present.

## Edit and preview

Read [STYLE_GUIDE.md](STYLE_GUIDE.md) before every design change. This is the
standalone mirror of the parent project's `docs/MYTHCARDS_WEB_STYLE_GUIDE.md`;
update both together. Shared CSS foundations are in `dist/mythcards-tokens.css`,
loaded before page styles. Reuse them on all future MythCards web pages.
The current layout is retained; legacy small type, hit targets and phone
navigation still need a separate accessibility/layout adoption pass with browser QA.
Token adoption is not a claim of full style-guide compliance.

- Page and styling: `dist/index.html`, `dist/styles.css`.
- Card gallery and dialogs: `dist/app.js`, `dist/cards.json`.
- Run `npm run dev` and open the printed local URL.
- Run `npm test` for content and asset checks.

The self-contained `dist` directory can be hosted by any static host. Current
Sites project identity is in `.openai/hosting.json`. Keep that ID on future edits.

## Artwork sources

The eight tarot fronts were exported by the existing tarot tools to
`D:/MythCards-working-images/card-fronts/russian-tarot-deck`. Web-optimized copies
are included here so deployment does not depend on that drive. Gallery copy comes
from approved entries in `data/cards/review_drafts/russian_tarot_guidebook.json`.
Only public narrative and interpretation fields are included, not hidden threads.
The gameplay image is the user's Closed City development capture, preserved in
`source-assets/gameplay-closed-city-user.png` (uploaded 2026-10-24). Its optimized
web copy is `dist/assets/gameplay.webp`. It is shown uncropped, at no more than
760 CSS pixels wide, without enlarging source pixels. No generated gameplay or
old CSS zoom coordinates are used. It remains labeled a development prototype.

The game introduction intentionally avoids board dimensions, roster counts,
progression, ability rules and victory conditions at this early stage. Its
three-profile switcher features canonical Thalassa-Nekh, Buran and
Subject 3: Zoya profile pages from `assets/characters`. All artwork is contained,
not cropped. Quotes are transcribed into HTML for readability. Tabs support
arrow/Home/End navigation; original-scale profile dialogs support Escape and
focus return. There is no automatic slideshow. Without JavaScript all three
profiles are visible and their image links still work.

`node prepare-assets.mjs [fronts-directory]` refreshes these copies from the
canonical assets and guidebook. Requires Sharp; set `SHARP_MODULE` to its installed
module path outside the bundled desktop runtime. Original art is not modified.
Use `node prepare-assets.mjs --showcase-only` to update just the profiles and
gameplay image without regenerating the approved tarot gallery.

## Launch checklist

- Owner reviews imagery, public story copy, and release wording.
- Connected `mythcards.io` and `www.mythcards.io` to the existing Sites host,
  with user-approved public access and active HTTPS (verified 2026-10-25).
- Web Analytics was enabled in Cloudflare with automatic setup. On the public
  custom domain, verify the beacon is injected and actual test visits appear.
  Do not mistake the Site dashboard tag for an analytics beacon token.
- Check social image URL and canonical metadata after DNS goes live.
- Do not add a purchase button until physical deck details and fulfillment exist.
