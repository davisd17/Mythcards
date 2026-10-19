# Closed City vs Flood Survivors Deck Review

## Approved Events

Designer decision: use two copies of each listed event for now. Each side contributes
10 event cards (5 unique events); the combined shared deck contains 20 events.

| Closed City | Copies |
| --- | --- |
| Signal Array Turns | 2 |
| Reactor Prayer | 2 |
| Closed City Incident | 2 |
| Seventeen Seconds | 2 |
| Dream Monitors Synchronize | 2 |

| Flood Survivors | Copies |
| --- | --- |
| The Causeway Breathes | 2 |
| Black Water Remembers | 2 |
| The Flood Reaches The Walls | 2 |
| The Drowned Seraph Speaks | 2 |
| Exiles Walk Beneath Egypt | 2 |

Dream Monitors Synchronize: you may swap both Common characters' positions,
regardless of distance, if both are still on the board.

The Drowned Seraph Speaks: your Mystic gains Shield until used, and +1 ATK this turn.

Exiles Walk Beneath Egypt: move up to 2 allied characters adjacent to placed objects
1 tile each, ending on empty tiles, without spending AP.

Implementation status: the approved fixed lineup is implemented in Godot. Each side
contributes 10 event copies and 5 unique relics, creating a 30-card shared deck.
Custom collection-based deck selection and owned-copy enforcement remain future work.

## Approved Relics

Each side may contribute up to 5 unique relics, with no duplicate relics within a
player's contribution. One active relic slot per player remains the rule. All five relics per side below
are implemented in the current fixed playtest.

Approved relic decisions:
- Chintamani Fragment: keep unchanged.
- Karpova's Black Key: keep unchanged.
- The Emerald Tablet: keep its trigger and targeting rules; grant only Shield,
  remaining until used. Remove the RANGE choice; implemented locally.
- Reactor Core Fragment: your Specialist and Mystic each gain +1 ATK and ignore Leak
  damage. Replaces the Leak-triggered RANGE bonus; implemented locally.
- Cosmonaut Helmet With A Second Shadow: your Mount and Warrior each gain +1 maximum
  HP and cannot be Marked. Approved as the fourth Closed City relic; implemented locally.
- Lead-Sealed Notebook: your Leader and Specialist each gain +1 RANGE, applying to
  attacks and abilities. Approved as the fifth Closed City relic; implemented locally.
- The Black Sarcophagus: keep unchanged.
- Tide-Sealed Archive: at the start of your turn, every character adjacent to a placed
  object heals 1 HP, up to maximum HP. Includes allies and enemies; implemented locally.
- Seraphic Burial Veil: keep the draft effect unchanged. Approved as the fourth Flood
  Survivor relic; implemented locally.
- Basalt Ley Compass: your Common and Specialist each gain +1 MOVE. Each may move
  through 1 allied placed object per movement, ending on an empty tile. No shared
  once-per-turn limit. Approved as the fifth Flood Survivor relic; implemented locally.
