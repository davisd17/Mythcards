# MythCards Card Data

This folder is the start of the shared card data structure for collaborators.

- `characters.json` is the source data for prototype character cards.
- `relic_events.json` is the source data for prototype relic and event cards.
- `review_drafts/` holds proposed cards that are ready for story/mechanic review but are not yet part of the playable prototype deck.

Editing guidance:
- Keep IDs stable once referenced by code, art, or playtest notes.
- Use `sub_area` for story/mechanical grouping when known.
- Keep printed ability text concise enough for mobile inspection and physical cards.
- Level 2 should be a clear power spike.
- Level 3 should be transformative: a major stat jump, a game-changing ability, or a real shift in how the character plays.
- Use `Spirit Ember` for Level 3 progression language. Do not use older body-part terms.

Current consumers:
- `tools/generate_printable_cards_pdf.py`
- `tools/generate_relic_event_cards_pdf.py`

The static tabletop and printable HTML are still mirrored manually for browser-only use; keep them aligned until a full data-driven build step is added.
