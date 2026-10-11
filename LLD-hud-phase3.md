# LLD: HUD and Card Moments (Visual Polish Phase 3)

| Field | Value |
| --- | --- |
| Source | `VISUAL_POLISH_PHASE_1.md` (Long-Term Visual Roadmap, Phase 3): reduce inspector weight, improve turn hierarchy, give relic/event draws a brief center-stage reveal before they dock into the HUD |
| Status | Implemented 2026-10-11 |
| Files | `game/scripts/ui/hud_fx.gd` (new), `game/scripts/ui/ap_meter.gd` (new), `game/scripts/ui/game_screen.gd`, `game/scripts/ui/card_summary.gd`, `game/tests/unit/test_hud_phase3.gd`, `e2e/tests/visual.spec.ts` |

## 1. Turn Hierarchy

- The turn line is drawn in the active player's faction color (Closed City red, Flood Survivors cyan), and a 3 px bar of that color runs under the header.
- Pool AP shows as pips (`ApMeter`): filled for AP left, hollow for AP spent. The pips are hidden during setup.
- At every turn start a banner fades in and out across the middle of the screen (0.15 s in, 0.75 s hold, 0.30 s out). It reads "Turn N · Team", with "(AI)" or "Your turn ·" in a match against the AI. It ignores input and frees itself. It sits under a drawn card's popup, so on a human turn with a draw it is mostly hidden, and the popup's "Player N drew…" line carries the turn change instead.

## 2. Card Moments

- **Human draw:** the full-size popup is unchanged (it still requires Continue), but it now opens with a 0.22 s scale-and-fade.
- **Closing any relic/event popup:** a 150×210 copy of the card flies from the popup into the HUD chip that now holds it (0.38 s). That is the player's relic chip, an active event's chip, or the Deck chip for a card that resolved or went back. Character cards don't fly.
- **AI draw:** still non-blocking with the tappable notice. The card also appears over the board, holds for 0.9 s, then docks.
- Every flyer ignores input and frees itself.

## 3. Inspector Weight

- The summary strip is lighter: its art is 96 px wide (was 120), the text 19/15/13 pt (was 22/17/15), and it has a 1 px neutral border instead of a 2 px gold one.
- In portrait the board's height share rose from a stretch ratio of 2.2 to 3.0, so the board is noticeably larger on phones.

## 4. Tests

- `test_hud_phase3.gd` (7 tests):
  - One banner per turn; it ignores taps, sits under the popup, and disappears.
  - "Your turn" in a match against the AI.
  - The pips track the active player's pool, and are hidden in setup.
  - Closing a drawn card makes one flyer, which frees itself.
  - An AI draw flies in with no popup.
  - Character cards don't fly.
- `visual.spec.ts` adds `-turn` (the popup popping in) and `-dock` (the flyer mid-flight) screenshots. Copies are in `docs/visual-polish-phase3/`.

## 5. Open

- `[NEED: designer review]` Should a human turn hold its draw popup until the banner finishes (+~1 s per turn), or is the popup note enough?
- `[NEED: designer review]` The 0.9 s hold for AI draws: long enough to register, short enough not to slow the AI?
