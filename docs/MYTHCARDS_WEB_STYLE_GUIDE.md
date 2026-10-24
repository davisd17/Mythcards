# MythCards Web Style Guide

Version 1.0 - 2026-10-23

## Scope And Authority

Shared design contract for every MythCards website, landing page, lore page,
deck page and browser-based promotional experience. New pages must follow it;
existing pages adopt it through reviewed changes, not an unrequested redesign.
This is not a claim that the current prototype meets every requirement below.

This file is the canonical master. The standalone Site repository carries an
identical `STYLE_GUIDE.md` copy so its contributors can work independently.
Update both together. Portable CSS tokens live in the Site's
`dist/mythcards-tokens.css`; reuse them rather than choosing new values per page.
The Godot game uses `docs/UI_STYLE_GUIDE.md` for logical UI units. Never copy
Godot control dimensions directly into CSS pixels.

Approved names and canonical lore outrank stylistic suggestions. PRD.md owns
game claims; approved guidebook records own public narrative. Art approval,
content approval, browser verification and publication are separate gates.

## Brand And Product Hierarchy

1. MythCards is a game and a universe first.
2. Explain the game, its characters and the convergence; make people curious.
3. Promote tarot prominently as another entrance to that universe and a future
   way to support game development, not as the site's sole purpose.

- Master brand: **MythCards**, not a different logo or capitalization per page.
- First deck: **Dreams of the North**. Subtitle: **A MythCards Tarot**.
- Future deck placeholder: **The Atlantean Chapter**, not an approved final title.
- Do not rename canonical card IDs, artwork paths or lore files for marketing.
- Keep Orlov's dream/reality ambiguity. Do not resolve it through new site copy.
- Current prototype: 7 x 7 tactics, Closed City versus Flood Survivors. Do not
  advertise unimplemented factions/features as playable or final.
- No purchase, preorder, signup, price or release-date promise until separately
  approved. Physical deck must be printed and reviewed before orders open.

## Visual Character

Atmospheric, tactile and mysterious, supported by clear information hierarchy.
Original character/card/world art provides richness. Interface chrome stays
restrained. Avoid generic fantasy-store layouts and unrelated stock imagery.

Use full-width section bands and unframed compositions, not floating section
cards. Individual cards, dialogs and framed tools are valid containers; do not
nest cards inside cards. Default corners are square; maximum radius is 8px.
No decorative gradient orbs, bokeh, synthetic hero illustrations or stock icons
standing in for actual cards, gameplay or characters.

## Palette

| Role | Token | Value |
| --- | --- | --- |
| Dark surface | `--mc-ink` | `#171b19` |
| Light surface / light text | `--mc-paper` | `#eceee9` |
| Muted text on dark | `--mc-muted` | `#adb5ad` |
| Body text on light | `--mc-text-on-light` | `#4c5850` |
| Hairline on dark | `--mc-line` | `#424b44` |
| Hairline on light | `--mc-line-on-light` | `#b9c0b8` |
| Focus / restrained accent | `--mc-mint` | `#b9d2be` |
| Oxblood accent | `--mc-oxblood` | `#873b43` |
| Deck announcement surface | `--mc-announcement` | `#41272e` |

Dark world/lore sections alternate with neutral light game/deck sections.
Oxblood distinguishes the featured deck; mint signals links and focus on dark.
Do not use mint as body text on a light background. Do not assume an accent
passes contrast in every pairing; check rendered normal/hover/disabled states.
Art can carry other colors; UI colors should not become an entirely blue,
purple, beige or orange theme. Distinguish factions by text and art, not color alone.

## Typography And Readability

- Display/headings: Georgia, Times New Roman, serif. Body/controls: Arial,
  Helvetica, sans-serif. No paid font dependency or new family per section.
- Letter spacing: zero. Never use viewport-based type scaling, tiny type to
  solve overflow, negative tracking, or arbitrary transform scaling.
- Body and ordinary interactive labels: 16px, line-height 1.6-1.75.
- Secondary explanatory copy: 14px minimum. Nonessential metadata: 12px minimum.
- Eyebrows: 12px, uppercase sparingly; never the only location for key information.
- Desktop display: 80-94px; compact display: 48-54px at explicit breakpoints.
- Section H2: 48px desktop / 36-38px compact. Item H3: 24-28px. Dialog title:
  30-36px. Do not put hero-sized headings into compact cards or toolbars.
- Constrain reading copy to about 60-70 characters per line; allow long deck
  names to wrap at word boundaries. Keep subtitles on their own line if needed.
- Use rem for reading/control type; respect browser zoom and user font settings.

The current draft still contains smaller legacy labels and captions. Those are
adoption work, not approved exceptions for future pages. Increasing them requires
layout and interaction QA; do not claim compliance from token adoption alone.

## Spacing And Responsive Layout

Spacing scale: 4, 8, 12, 16, 24, 32, 40, 48, 64, 88px. Use named tokens.
Content max-width: 1320px. Desktop page inset: 64px; tablet: 36px; phone: 20px.
Default section padding: 88px desktop / 60px compact. Breakpoints: 1000px and
640px, with 360px only for exceptional narrow layouts. Do not invent a breakpoint
for every element. Type changes are discrete, never proportional to viewport.

- Reflow columns before changing component sizes. Use `minmax(0, 1fr)` and
  `min-width: 0` on flexible text/grid children.
- Controls with the same role keep the same height across viewport sizes.
- Tarot gallery: four columns desktop, two phone; fixed 7:12 framed-card ratio
  for the existing previews, with `object-fit: contain` so artwork is not cut.
- Use actual asset proportions for new products; do not force every image to 7:12.
- Menus must preserve access to all primary destinations on phones. Hiding a
  destination without an equivalent accessible menu is not the target design.
- No horizontal overflow at 320px. Do not mask layout defects with hidden body
  overflow. Check 200% zoom, long titles and default system font substitution.

## Buttons, Links And Interaction

| Role | Size contract | Treatment |
| --- | --- | --- |
| Primary command | min-height 48px; 20px horizontal padding | paper on ink, ink on paper |
| Secondary command | same 48px height and 16px type | outlined or quiet fill |
| Icon command | fixed 44 x 44px | familiar symbol, accessible name, hover/focus tooltip |
| Text navigation | minimum 44px hit height | underline/focus treatment, no fake button frame |
| Two-line choice | dedicated named component, min-height 64px | never mixed into ordinary command rows |

Primary emphasis changes color, not geometry. Keep labels on one line; reflow
the action group rather than shrinking the label. Icon-only controls use Lucide
when available, otherwise the project's existing icon system. Never hand-draw a
new icon family. Color choices use swatches, binary settings use toggles, modes
use segmented controls, and option sets use menus.

Equal-role commands in a group use equal-width slots. Icon controls remain fixed.
Busy indicators reserve space; hover, focus, selection and loading must not shift
layout. Provide default, hover, pressed, focus-visible, disabled, busy and error
states when applicable. Disabled controls must not imply an available release.
Links navigate; buttons perform actions. Use native controls wherever possible.

## Page Composition

Home/universe page: brand/game hero, upfront supporting deck announcement,
actual prototype introduction, lore/factions, tarot previews, release status/FAQ.
Use the existing layout as the baseline, not a replacement Site.

Deck page: literal approved deck name as H1, subtitle and real card imagery,
preview controls, guidebook excerpts, honest print status. No fake product photos.
Lore page: specific world/character title, canonical art and readable narrative;
do not turn the page into a row of marketing cards or reveal hidden lore threads.
Utility/tool pages: compact functional UI first, not an unrelated hero.

Where a hero is appropriate, use original full-bleed art with text over it and
visible image subjects. Preserve readability with restrained overlays. Do not
put hero text inside a card or use split text/image-card layouts. Leave a hint
of the next section visible at common desktop/phone sizes; on short screens,
prioritize unclipped content and natural scrolling over fixed-height tricks.

## Artwork And Motion

- Use canonical art and optimized derived assets, never overwrite originals.
- Keep tarot fronts fully inspectable with `contain`; reserve cropping for
  atmosphere/world media where the important subject remains visible.
- Supply intrinsic dimensions/aspect ratios to avoid layout shift. Preload only
  the main hero; lazy-load lower images. Art must work without animation.
- Actual gameplay captures must be labeled development prototype, not final.
- Preserve card front/back, previous/next and close controls across screen sizes.
- Motion duration: 150-250ms for interface feedback, up to 350ms for card detail.
  Respect reduced motion. No autoplay sound, flashing, or motion-only information.

## Accessibility And Content

Use semantic landmarks, one H1, orderly headings, meaningful alt text and visible
focus. Decorative images use empty alt. Every icon command needs a real name;
tooltips are not a replacement. Dialogs must support Escape, appropriate focus,
focus return, scroll containment and keyboard controls. Errors/loading/empty
states need plain-language messages and a recovery path.

Text contrast target: 4.5:1 for normal text, 3:1 for qualifying large text and
meaningful UI boundaries. Measure actual pairings, including text over artwork.
Do not announce accessibility conformance without an audit.

Voice: evocative headlines, concrete supporting copy, calm functional labels.
Let the stranger aspects emerge through art, character choices and story details;
do not advertise explicit lists of occult/esoteric categories in promotional copy.
Avoid invented canonical events, unsupported superlatives or urgency. Do not
describe site styling, shortcuts or how the UI works in visible marketing copy.
No checkout/signup/release-date promises while launch restrictions remain.
Keep title, metadata, gallery labels, alt text, social copy and README consistent.

## Publication And Agent Handoff

Preserve the existing Sites project ID and owner-private audience. Public access,
custom-domain changes and purchases need separate user authorization. Do not
claim Cloudflare visits are tracked on a private preview; verify on the connected
public custom domain. Never put credentials in source, files, URLs or logs.

The `sites/mythcards` directory has its OWN Git repository. Do not add it to the
parent as a gitlink/embedded repository. Keep each Site's source and deployment
history separate; no `create_site` for an existing Site. Record missing checks
and permission blocks honestly, without weakening network/security controls.

Before editing any MythCards web page, read this guide, inspect its implementation,
and reuse its tokens/components. Preserve approved art/content and scope changes.

## Review Checklist

- Correct brand/deck names; game and universe remain primary.
- Shared colors, type, spacing and control sizes; no one-off button dimensions.
- Desktop 1440px, tablet 768px, phone 390px and narrow 320px reviewed.
- Also check 200% zoom, short landscape, keyboard-only and reduced motion.
- No clipped titles, overlapping text, hidden destinations or horizontal overflow.
- Artwork loaded, correctly framed, no broken links; gallery/dialog interactions work.
- No visual resizing between interaction states; focus is visible.
- Content/asset tests and JavaScript syntax checks pass.
- Browser screenshots are new, not assumed from previous versions.
- Audience/privacy preserved; publication verified separately from local tests.

Current adoption: approved layout, palette and deck name retained; shared palette
tokens wired into the Site. Full readability/control/phone-navigation compliance
remains a later scoped implementation pass with live browser verification.
