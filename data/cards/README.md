# MythCards Card Data

This folder is the start of the shared card data structure for collaborators.

- `characters.json` is the source data for prototype character cards.
- `relic_events.json` is the Closed City / Flood Survivors relic and event set. **The Godot rules prototype plays this set** (designer decision 2026-09-27, after the first playtest). Card rulings are in `LLD-relic-event-deck.md` Section 9B.
- `prototype_relic_events.json` is the original 14 relic/event cards from the PRD. The game no longer loads it; it is kept for reference.
- `teams.json` names the teams the game can field and the matchup it plays (Closed City vs Flood Survivors, decided 2026-10-07). Listing a card in a team makes it playable even when its text lives in `review_drafts/`. The original 14 teams are kept but hidden (`"offered": false`). It also holds the 2-letter board tags.
- `card_art.json` maps card ids to art under `assets/` for the game screen. Cards not listed show a text card. `tools/sync_game_content.ps1` copies small versions into the game.
- `review_drafts/` holds proposed cards that are ready for story/mechanic review but are not yet part of the playable prototype deck.
- `review_drafts/tarot_guidebook_content_standard.md` defines the approved physical-card content boundary and companion guidebook format for all tarot decks.
- `review_drafts/russian_tarot_guidebook.json` stores approved and in-review guidebook entries in canonical tarot order, including structured relationship and hidden-story threads.

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
