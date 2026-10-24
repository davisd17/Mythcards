# MythCards coming-soon website

Universe-first site centered on the MythCards tactical game and its lore. The
first tarot deck is promoted upfront under its approved marketing title
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
The gameplay image is an actual development prototype capture from
`e2e/test-results/readability-1280.png`, not a finished-release image. Its web copy
is committed in `dist/assets/gameplay.webp`. The page frames the complete board
from source coordinates x402, y114, width476, height476 using CSS, removing empty
outer margins without repainting, inventing or changing gameplay. This board-detail
view is shared across desktop and phones. If the capture changes, remeasure the
board framing rather than reusing those coordinates blindly. To regenerate assets, first
produce that screenshot with the project's existing readability tests.

`node prepare-assets.mjs [fronts-directory]` refreshes these copies from the
canonical assets and guidebook. Requires Sharp; set `SHARP_MODULE` to its installed
module path outside the bundled desktop runtime. Original art is not modified.

## Launch checklist

- Owner reviews imagery, public story copy, and release wording.
- Connect `mythcards.io` and `www.mythcards.io` to the selected public host.
- Web Analytics was enabled in Cloudflare with automatic setup. On the public
  custom domain, verify the beacon is injected and actual test visits appear.
  Do not mistake the Site dashboard tag for an analytics beacon token.
- Check social image URL and canonical metadata after DNS goes live.
- Do not add a purchase button until physical deck details and fulfillment exist.
