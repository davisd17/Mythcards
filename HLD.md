# MythCards High-Level Design — Digital Rules Prototype

**Document Control**

| Field | Value |
| --- | --- |
| Source document(s) | BRD.md (v3, resynced 2026-08-28), PRD.md (resynced 2026-08-28) |
| Scope tier | Digital Rules Prototype — PRD-MILESTONE-002 / BRD Section 9.12 (FR-085–FR-090A) |
| Target stack | Godot 4.7.x (latest stable minor as of 2026-08; currently patch 4.7.2 — re-verify exact patch version at implementation time), GDScript |
| Version | 3 (adds GUT as the chosen unit-test framework; reflects BR-011A — placed objects block line-of-sight by default) |
| Date | 2026-09-07 |
| Status | Draft |
| Prepared by | Drew Davis (solo developer/designer, acting as own PM) |

## 1. Purpose & Scope

This HLD covers the architecture for the first playable Godot build: local hotseat matches between two fixed 7-character squads (Russian-inspired vs. Atlantean), implementing movement, attacks, character abilities, mount/dismount, the checkmate-style Hero capture rule, army defeat, the shared 14-card relic/event deck, and match-based leveling through Spirit Ember delivery — with debug-level UI, not final mobile UX.

Explicitly excluded at this tier (deferred to later milestones per BRD Section 6.2 and PRD's own milestone sequence): networked/asynchronous PvP, an AI opponent, final art and animation, cosmetic/account progression, analytics collection, save/profile persistence, and polished mobile UX (Milestone 003). Section 9 marks the seams for each of these so the prototype doesn't need a rewrite to grow into them.

## 2. Architecture Goals & Constraints

| Driver | Source | Architectural implication |
| --- | --- | --- |
| Solo developer, prototype-first | CLAUDE.md, BRD §1 | No infra, no networking, no multi-service split. One Godot project, local execution only. |
| Data-driven content, editable without rewriting logic | BRD FR-080, FR-081, NFR-016, NFR-017 | Character and relic/event data stay in `data/cards/*.json`; a dedicated content-loader module is the only thing that reads them. Rules code never hardcodes a card's stats. |
| Sub-100ms highlight/target response | BRD NFR-002 | Legal-move/legal-target queries must be synchronous, in-memory graph walks over a 49-tile board — no async I/O in the hot path. Board size makes this trivial computationally; the constraint is architectural (don't introduce I/O or network calls into query paths), not algorithmic. |
| Mobile-first from this prototype onward | BRD BR-044, NFR-009A | UI layer built on `Control` nodes with anchors/containers from the start, even though the prototype runs on a desktop window — not a fixed-pixel desktop layout ported later. |
| Internal debug visibility required | BRD FR-084, PRD-FR-008 | A debug/inspection UI is first-class scope for this tier, not an afterthought — it doubles as the first consumer of the event bus (Section 5), which validates the architecture. |
| Content system must support future cultures/sub-areas without rewriting board/turn systems | BRD NFR-018, FR-082, FR-082A | No module may hardcode "2 cultures" or "14 cards" as a structural assumption — those are current data facts, not architecture limits. |
| Automated testing via Playwright requires a Web (HTML5) export target, from this tier onward | BRD FR-090A, NFR-031A (2026-08-28) | The project maintains a Web export preset alongside the desktop preset from the start, not bolted on later. `ContentDB` already reads bundled JSON via `res://` at boot, which is Web-export-safe by default — no file-system access pattern needs to change. See Section 4.13 for the concrete test-hook design this implies. |
| Rules must be centrally, consistently enforced (line-of-sight, AP gating, mount legality) | BRD NFR-020, NFR-021 | One authoritative action-validation gate (Section 4.4), not per-feature ad hoc checks scattered across UI code. |

## 3. System Context

```
┌───────────────────────────────────────────────────────────┐
│                    Player Device (local)                   │
│                                                              │
│   ┌────────────────────────────────────────────────────┐   │
│   │              Godot Client (single process)           │   │
│   │                                                        │   │
│   │   Player 1 input ──┐                    ┌── Player 2 input   │
│   │                    ▼                    ▼               │   │
│   │            [ MythCards game — hotseat, same screen ]     │   │
│   │                                                        │   │
│   │   reads at boot ──► data/cards/characters.json         │   │
│   │                 ──► data/cards/relic_events.json       │   │
│   └────────────────────────────────────────────────────┘   │
│                                                              │
│   No network calls. No backend. No account/save system.     │
│   (See Section 9 for where these attach later, not now.)    │
└───────────────────────────────────────────────────────────┘
```

Everything lives inside one Godot process. The only external I/O at this tier is reading the two JSON content files at startup — there is no server, no account system, and no persistence between sessions (Section 8).

## 4. Module Breakdown

### 4.1 Content Loader (`ContentDB`)
Parses `characters.json` and `relic_events.json` at boot into typed in-memory resources (Section 6). Owns nothing about rules or state — it is a pure data source other modules query by ID or filter (by culture, type, `review_status`). Also loads `data/cards/review_drafts/*.json` but keeps it tagged and excluded from the playable deck (BR-043A) — it exists so a future promotion step doesn't need a new loader.
**Satisfies:** FR-080, FR-081, FR-082, FR-082A, FR-082B, NFR-016, NFR-017.

### 4.2 Board/Grid (`BoardModel`)
Owns the 7x7 tile grid, tile occupancy, terrain/placed-object state, and the center-tile flag. Provides the shared legal-move and line-of-sight query functions every other module relies on: `get_legal_moves(character, pattern)`, `has_line_of_sight(from, to)`, `get_tiles_in_range(origin, range, pattern)`. This is the *one* place movement pattern and line-of-sight rules (BR-008, BR-009, BR-011, BR-011A) are implemented — nothing else re-derives them. Placed objects block both movement and line-of-sight by default (BR-011A), the same as an occupied character tile, unless the specific card/object states otherwise — the per-object-type characteristics (blocks movement? blocks line-of-sight? HP?) are looked up from a small object-type registry rather than hardcoded per tile, so a future object type is a data addition, not a `BoardModel` code change.
**Satisfies:** FR-010–FR-018A, BR-008, BR-009, BR-010, BR-011, BR-011A, FR-036D.

### 4.3 Match Setup (`SetupFlow`)
Culture selection, fixed-squad loading (exactly one of each type, BR-005), and player-controlled back-row deployment (BR-007A/BR-007B): validates that placement stays within the player's own back row and that all 7 types are placed before starting. Builds the initial `MatchState` (Section 6) and hands off to `TurnManager`.
**Satisfies:** FR-001–FR-009A, BR-001–BR-007B.

### 4.4 Rules Engine (`RulesEngine`)
The single authoritative gate for every player action: move, attack, ability, mount, dismount. Validates pool AP + character AP availability (BR-020) and delegates legality checks to `BoardModel` (movement/LOS) and `AbilitySystem` (ability-specific rules), then applies the resulting state change. UI and any future AI/network layer only ever request actions through this module — no code path mutates `MatchState` directly.
**Satisfies:** FR-021–FR-024, FR-027A, NFR-020, NFR-021.

### 4.5 Combat Resolution (`CombatResolver`)
Attack targeting via RANGE and attack pattern, line-of-sight blocking applied uniformly to damage *and* non-damage ranged targeting (BR-011, FR-036C — this is the 2026-08-14 rule change; there is deliberately no separate "support ability" LOS path), damage application, shields/damage reduction/redirection, push/displacement, and defeat detection.
**Satisfies:** FR-028–FR-036C.

### 4.6 Ability System (`AbilitySystem`)
Executes printed character abilities (passive / AP Ability / Activated, BR-013 timing labels), resolves once-per-turn/once-per-match limits, and reports legal targets/ranges to the UI before confirmation. Abilities are implemented individually (14 prototype abilities × 3 levels) but registered through one dispatch table keyed by ability ID from `CharacterData`, not a chain of hardcoded `if character.name == "..."` branches.
**Satisfies:** FR-037–FR-045I.

### 4.7 Mounted Pair (`MountSystem`)
Mount/dismount as AP-gated actions (BR-012, BR-017 — both cost 1 pool AP + 1 character AP), combined-tile representation, stat inheritance (rider HP/ATK/RANGE/level/abilities, Mount's MOVE/pattern), and defeat propagation (rider HP → 0 defeats both).
**Satisfies:** FR-045B–FR-045H, BR-012–BR-017.

### 4.8 Leveling & Spirit Ember (`LevelingSystem`)
Tracks each character's level (1–3), detects opponent-edge crossing for Level 2, tracks Spirit Ember as a status/counter on the carrying character (not a board object, per FR-047A), detects center-tile delivery for Level 3, and applies the printed Level 2/Level 3 upgrade text from `CharacterData`.

Spirit Ember pickup is automatic and immediate (BR-023A, resolved 2026-08-28): `LevelingSystem` grants the Ember to the defeating character as part of handling `character_defeated` from `CombatResolver` — there is no separate "move onto the tile" pickup step, and no pickup UI. Because pickup no longer depends on movement, the Level 3 completion check (carrier is Level 2, holds the Ember, and is on the center tile) must be evaluated on *every* event that could complete it, not just movement: `character_moved`, `spirit_ember_picked_up`, and `character_leveled_up` (reaching Level 2 while already standing on the center tile with an Ember). See Flow D (Section 7).
**Satisfies:** FR-046–FR-052, BR-022–BR-026, BR-023A.

### 4.9 Relic/Event Deck (`RelicEventDeck`)
Builds the match's shared 14-card deck from each player's 3-relic/4-event culture contribution (BR-027A), shuffles it with a stored seed (Section 9 — needed for future networked sync), draws one card per turn for the active player, and manages the one-active-relic-slot-per-player replace/discard choice through UI (BR-030, BR-031 — no native popups) versus immediate/duration event resolution (BR-032).
**Satisfies:** FR-009A, FR-053–FR-059C, BR-027–BR-033.

### 4.10 Victory Checker (`VictoryChecker`)
Runs the end-of-turn Hero-capture check (BR-034): when a player ends their own turn, queries `BoardModel.get_legal_moves()` for their own Hero (or its mounted pair) and, if empty, ends the match immediately in the opponent's favor. Separately watches for army defeat (all characters on one side removed, BR-035). Deliberately reuses `BoardModel`'s move-legality function rather than a second implementation (see R-002 in Section 11).
**Satisfies:** FR-060–FR-065, BR-034, BR-034A, BR-035.

### 4.11 Debug/Inspection UI (`DebugPanel`)
A standalone overlay subscribing to `EventBus` (Section 5) to display board state, AP (pool and per-character), HP, level, Spirit Ember status, and active relic/event effects — the playtesting surface required at this tier. Built as a pure event-bus listener specifically so it never reaches into other modules' internals, keeping the event-bus contract honest.
**Satisfies:** FR-084, PRD-FR-008.

### 4.12 Presentation Layer (`BoardView`, `CharacterView`, `HUD`)
Renders board/character state, handles tap input, and shows legal-move/attack/danger-zone highlights, turn indicator, relic/event panel, and status badges. Deliberately thin: it reads `MatchState` and `EventBus` signals and requests actions through `RulesEngine` — it holds no game-rule logic itself. Built mobile-first (Control/anchors) even at prototype tier (BR-044).
**Satisfies:** FR-066–FR-074A.

### 4.13 Export & Test Harness (`TestBridge`)
Supports BRD FR-090A/NFR-031A: the project builds a Web (HTML5) export preset alongside the desktop preset from this tier onward, specifically so Playwright can drive and verify matches in a real browser without manual play.

A canvas-only Web export gives Playwright screenshots and coordinate-based clicks, which is enough for UI smoke tests but weak for verifying rules correctness in a tactics game where "the right tile highlighted" matters more than "a pixel is a certain color." `TestBridge` closes that gap: a thin autoload, active only in Web exports, that uses Godot's `JavaScriptBridge` singleton to expose two JS-callable hooks on `window`:
- `mythcards_get_state()` → returns the current `MatchState` (Section 6) serialized to JSON, so Playwright assertions can read exact game state (positions, HP, AP, level, Spirit Ember, active relic/event) instead of inferring it from pixels.
- `mythcards_dispatch_action(action_json)` → forwards directly to `RulesEngine`'s `action_requested` handling (Section 4.4), so Playwright can drive a full match deterministically (movement, attacks, abilities, mount/dismount, end-turn) without simulating canvas clicks at all, while still exercising the real rules-validation path.

Coordinate-based canvas clicks remain available for the smaller set of true UI smoke tests (tap targets, highlight rendering). `TestBridge` is excluded from non-Web export presets via a Godot custom feature tag, so the JS bridge never ships in a build that isn't meant for automated testing. `[NEED: confirm the exact `JavaScriptBridge.create_callback()`/`eval()` call shape against the Godot 4.7 docs at implementation time — the API has been stable since 4.0 but exact signatures should be verified, not assumed from memory.]`
**Satisfies:** BRD FR-090A, NFR-031A.

**Unit-level testing (decided 2026-09-07):** module-level logic (e.g., `BoardModel` queries, `ContentDB` parsing/validation) is tested with **GUT** (Gut Unit Test, the standard GDScript testing addon), independent of the Web export — GUT runs inside the editor/headless Godot, not a browser. `TestBridge`/Playwright is reserved for full-match browser integration coverage; GUT covers everything a browser isn't needed for. Per-module LLDs specify their own GUT test cases (see the Content Loader & Board/Grid LLD for the first example).

## 5. Engine-Specific Structure

### 5.1 Autoload singletons

| Autoload | Responsibility |
| --- | --- |
| `ContentDB` | Parses and holds `CharacterData`/`RelicEventData` resources (Section 4.1). |
| `EventBus` | Global signal relay — the only cross-module communication channel besides direct calls into `RulesEngine`. |
| `GameState` | Holds the live `MatchState` (Section 6) for the current session — single source of truth. |
| `TurnManager` | Turn alternation, pool/character AP refresh, start/end-of-turn effect hooks (Section 4.3's counterpart at runtime). |
| `RulesEngine` | Action validation/execution gate (Section 4.4). |
| `RelicEventDeck` | Shared deck construction, draw, and slot management (Section 4.9). |
| `VictoryChecker` | End-of-turn Hero-capture and army-defeat checks (Section 4.10). |
| `TestBridge` | Web-export-only JS interop for Playwright (Section 4.13); no-ops on other export targets via feature tag. |

`BoardModel`, `CombatResolver`, `AbilitySystem`, `MountSystem`, and `LevelingSystem` are plain GDScript classes (`class_name`, not autoloads) owned and called by `RulesEngine`/`TurnManager` — they don't need to be globally addressable, which keeps the autoload list from becoming a God-object list itself.

### 5.2 Scene tree overview

```
Main.tscn
├── SetupFlow.tscn        (culture select, back-row placement — §4.3)
└── Match.tscn
    ├── Board (Node2D)
    │   └── Tile × 49 (generated at runtime from BoardModel)
    ├── Characters (Node2D)
    │   └── CharacterView × 14 (one per CharacterInstance, §6)
    └── UILayer (CanvasLayer)
        ├── HUD.tscn          (turn indicator, AP, relic/event panel, end-turn — §4.12)
        └── DebugPanel.tscn   (§4.11, toggled independently of HUD)
```

### 5.3 Signal map (`EventBus`)

| Signal | Emitted by | Payload | Listened by |
| --- | --- | --- | --- |
| `turn_started(player_id)` | `TurnManager` | player id | HUD, DebugPanel |
| `turn_ended(player_id)` | `TurnManager` | player id | `VictoryChecker`, HUD |
| `pool_ap_changed(player_id, remaining)` | `TurnManager` | int | HUD, DebugPanel |
| `character_ap_changed(character_id, remaining)` | `TurnManager` | int | HUD, DebugPanel |
| `action_requested(action_type, actor_id, payload)` | UI / future AI | enum, id, dict | `RulesEngine` |
| `action_resolved(action_type, actor_id, result)` | `RulesEngine` | enum, id, dict | HUD, DebugPanel |
| `character_moved(character_id, from, to)` | `RulesEngine` | id, Vector2i×2 | `LevelingSystem`, BoardView |
| `attack_resolved(attacker_id, target_id, damage, defeated)` | `CombatResolver` | ids, int, bool | HUD, BoardView |
| `character_defeated(character_id)` | `CombatResolver` | id | `VictoryChecker`, BoardView |
| `character_leveled_up(character_id, new_level)` | `LevelingSystem` | id, int | HUD, CharacterView |
| `spirit_ember_picked_up(character_id)` | `LevelingSystem` | id | HUD, CharacterView |
| `spirit_ember_delivered(character_id)` | `LevelingSystem` | id | `LevelingSystem` (self, triggers L3), HUD |
| `relic_drawn(player_id, card_id)` | `RelicEventDeck` | id, id | HUD |
| `relic_slot_changed(player_id, card_id_or_null)` | `RelicEventDeck` | id, id? | HUD, DebugPanel |
| `event_resolved(card_id)` | `RelicEventDeck` | id | HUD, DebugPanel |
| `hero_capture_checked(player_id, has_legal_move)` | `VictoryChecker` | id, bool | DebugPanel (diagnostic only) |
| `match_ended(winner_id, condition)` | `VictoryChecker` | id, enum(`hero_capture`\|`army_defeat`) | HUD, all modules (stop accepting actions) |

`action_requested` → `RulesEngine` is deliberately a request/response pair, not a fire-and-forget signal chain — this is the seam future AI and networking attach to (Section 9).

### 5.4 Resource/class definitions

```gdscript
# CharacterData.gd — mirrors data/cards/characters.json exactly
class_name CharacterData
extends Resource
var id: String
var faction: String
var culture: String
var sub_area: String
var char_name: String
var type: String            # Common | Mount | Warrior | Leader | Hero | Specialist | Mystic
var hp: int
var atk: int
var move: int
var range: int
var l1: String
var l2: String
var l3: String
var role: String

# RelicEventData.gd — mirrors data/cards/relic_events.json exactly
class_name RelicEventData
extends Resource
var id: String
var faction: String
var sub_area: String
var card_name: String
var kind: String             # Relic | Event
var duration: String         # Persistent | 1 round | 1 turn | Immediate
var effect: String
var note: String
var review_status: String    # "" for playable cards; "draft_for_review" for BR-043A content
```

`CharacterInstance` and `MatchState` (runtime, mutable) are defined in Section 6 — they reference `CharacterData`/`RelicEventData` by ID rather than embedding them, keeping static content data separate from live match state (this separation is also what makes save/load a Section-9 add rather than a rewrite).

## 6. Data Model

| Object | Key fields | Notes |
| --- | --- | --- |
| `MatchState` | `players: [PlayerState, PlayerState]`, `board: Array[BoardTile]` (49), `turn_number`, `active_player_id`, `shared_deck: Array[String]` (card IDs), `deck_seed: int`, `phase` | Single live-state root, held by `GameState` autoload. |
| `PlayerState` | `id`, `culture`, `characters: Array[CharacterInstance]` (7), `active_relic_id`, `pool_ap_remaining` | |
| `CharacterInstance` | `data: CharacterData` (ref), `current_hp`, `level` (1–3), `position: Vector2i`, `character_ap_remaining`, `status_effects: Array[StatusEffect]`, `has_spirit_ember: bool`, `mounted_with_id`, `is_mounted_rider: bool` | Runtime state layered on top of static `CharacterData`. |
| `BoardTile` | `position: Vector2i`, `occupant_id`, `terrain_type`, `placed_object` (barricade/pylon/frost), `is_center: bool` | Owned by `BoardModel`. |
| `StatusEffect` | `type` (Shield, TempAtk, TempMove, Pounce mark, Slow, Marked, …), `value`, `expires` (immediate / this-turn / this-round) | Generic enough to cover every prototype card's temporary effects without a new type per card. |

All IDs (`character_id`, `player_id`, `card_id`) are plain `String`/`int` values, never Node references — this keeps `MatchState` trivially serializable, which matters directly for the Section 9 save/load extension point.

## 7. Core Flows

**A. Turn start → action → turn end**
1. `TurnManager.start_turn(player)`: refresh pool AP (2 on the match's first turn, else 4 — BR-018), refresh each of that player's characters' AP (BR-019), `RelicEventDeck.draw_for(player)` (BR-028), emit `turn_started`.
2. UI emits `action_requested`; `RulesEngine` validates pool AP + character AP (BR-020), delegates legality to `BoardModel`/`AbilitySystem`, applies the change, emits `action_resolved` plus the specific signal (`character_moved`, `attack_resolved`, …).
3. Player ends turn → `TurnManager.end_turn(player)` → `VictoryChecker.check_hero_capture(player)` runs first (see Flow C) → end-of-turn effects resolve → `turn_ended` → active player flips.

**B. Attack resolution with line-of-sight**
1. Actor selects a target within RANGE and the attack pattern (orthogonal by default, BR-009).
2. `BoardModel.has_line_of_sight(from, to)` walks the intervening tiles; any occupied tile (ally or enemy) or tile holding a placed object blocks the action unless the specific card/ability/object states an exception (BR-011, BR-011A) — this check applies identically whether the action deals damage or is a non-damage support/utility targeting effect (FR-036C, FR-036D; there is no separate code path for the two, by design, since the 2026-08-14 and 2026-09-07 rules resolved them to the same behavior).
3. If legal, `CombatResolver` applies ATK damage, shields/reductions, defeat check; on defeat, `CombatResolver` emits `character_defeated`, which `LevelingSystem` handles by immediately granting the Spirit Ember to the attacking character (BR-023A) — no separate pickup step.

**C. End-of-turn Hero capture check**
1. On `end_turn(player)`, `VictoryChecker` fetches `player`'s Hero (or the mounted pair carrying it) and calls the *same* `BoardModel.get_legal_moves()` used for ordinary movement — including any active status effects (Slow, frost tiles) at that moment.
2. If the result is empty, `match_ended(winner=opponent, condition="hero_capture")` fires immediately (BR-034) and no further end-of-turn processing occurs.
3. Otherwise the turn ends normally.

**D. Level up**
1. On `character_moved`, `LevelingSystem` checks: Level 1 character now on the opponent's edge row → level to 2, apply `l2` text/stat deltas (BR-022).
2. On `character_defeated`, `LevelingSystem` grants the Spirit Ember to the attacker immediately (BR-023A) and emits `spirit_ember_picked_up`.
3. Because pickup no longer requires movement, the Level 3 completion check (Level 2 + holding an Ember + on the center tile) runs on every event that could complete it — `character_moved`, `spirit_ember_picked_up`, and `character_leveled_up` (in case a character reaches Level 2 while already on the center tile already holding an Ember) — not movement alone. When satisfied: level to 3, apply `l3` text/stat deltas (BR-023).
4. `character_leveled_up` emitted; UI refreshes the card display.

**E. Relic/event draw and replacement**
1. At match setup, `RelicEventDeck` builds the 14-card deck from each player's 3 relics + 4 events (BR-027A), shuffles with a stored `deck_seed`.
2. Each `start_turn`, one card is drawn for the active player (BR-028).
3. If it's a relic and the player's slot is already occupied, UI presents a replace-or-discard choice (BR-030) rendered in-game (BR-031, not a native popup); if it's an event, it resolves immediately or registers a duration-based `StatusEffect`/board effect (BR-032).

## 8. State Management & Persistence

`MatchState` lives entirely in memory in the `GameState` autoload for the duration of one Godot process session. There is no save/load, no account, and no cross-session persistence at this tier — level-ups are match-scoped and intentionally reset (BR-025), and local hotseat play doesn't require resuming an interrupted match. This is a deliberate scope decision, not a gap: Section 9 covers exactly what would need to be added (a `SaveManager` autoload) and why the current data model (plain-value `MatchState`, no Node references) makes that additive rather than a rewrite.

## 9. Extension Points For MVP

| Growth vector (BRD §6.2) | Prototype tier (now) | MVP seam (later, not built now) |
| --- | --- | --- |
| More cultures (4+) | `ContentDB` parses whatever cultures exist in `characters.json`; no module hardcodes "2 cultures" or "14 cards." | Add culture entries to the JSON; `SetupFlow`'s culture list is already data-driven, so no code change is expected — only verify no accidental hardcoding creeps in during prototype build. |
| Networked/async PvP | Single process, both players on one screen; `RulesEngine` is already the sole mutator of `MatchState`, reached only via `action_requested` → `action_resolved`. | A network layer intercepts `action_requested`, round-trips it to the authoritative peer/server, and only applies `RulesEngine`'s result locally — the request/response signal shape was chosen specifically so this doesn't require restructuring `RulesEngine` itself. Requires the `deck_seed` (Section 6) to be synced, since shuffle order must match. |
| AI opponent | N/A — both sides are human input. | AI is just another producer of `action_requested`. Requires exposing a `RulesEngine.get_legal_actions(character_id)` query (not yet built) so AI doesn't need to guess-and-check against validation failures. |
| Analytics | Not collected. | An `AnalyticsLogger` autoload subscribes to `EventBus` (Section 5.3) — every event already needed for UI/debug (`character_moved`, `match_ended`, etc.) is exactly what analytics needs; no gameplay code changes. |
| Save/profile data | Not persisted (Section 8). | A `SaveManager` autoload serializes `MatchState` — feasible without a rewrite specifically because `CharacterInstance`/`MatchState` already avoid embedding Node references (Section 6). |
| Ranked/Timer PvP modes | No timer. | `TurnManager.start_turn`/`end_turn` are the natural hook for a countdown — no restructuring of turn flow needed, only an additive timer check. |
| Cosmetic/mastery progression | No cosmetics. | `CharacterView` (presentation) is already separate from `CharacterData`/`CharacterInstance` (state) — skinning is a presentation-layer swap, not a data-model change. |
| Sub-area content (21 cards/culture) | 14-card representative roster only. | `ContentDB` and `RelicEventDeck` already treat `sub_area` as a data field, not a structural assumption — adding sub-area cards to the JSON (once they clear review, BR-043A) doesn't require new code, only content and deck-construction-rule updates if the 3-relic/4-event contribution model changes at larger pool sizes (BRD D-011, still `[NEED]`). |

## 10. Non-Functional Considerations

- **Performance (NFR-002):** `BoardModel` queries are synchronous graph walks over 49 tiles — no measurable perf risk at this board size; the constraint that matters is keeping I/O (content loading) confined to boot time, out of the per-action hot path.
- **Mobile-first (BR-044, NFR-009A):** `BoardView`/`HUD` built on `Control` + anchors/containers from the first prototype build, not ported later from a fixed desktop layout.
- **Testability/debug visibility (FR-084):** `DebugPanel` is a first-class `EventBus` listener (Section 4.11) — its existence also acts as a running integration check that every module actually emits the signals it's supposed to.
- **Maintainability (NFR-016, NFR-017):** Rules logic (`RulesEngine`, `BoardModel`, `CombatResolver`, `AbilitySystem`) never embeds card stats or text — everything comes from `ContentDB`, so a balance change is a JSON edit, not a code change.
- **Testability (BRD FR-090A, NFR-031A):** The Web export target plus `TestBridge`'s state/action JS hooks (Section 4.13) let Playwright verify exact rules outcomes (positions, HP, AP, level, Spirit Ember, active relic/event) deterministically, rather than relying on pixel comparison — directly reusing `RulesEngine`'s real validation path instead of a separate test-only code path.

## 11. Risks & Technical Open Questions

| ID | Risk / Open Question | Impact | Mitigation |
| --- | --- | --- | --- |
| HLD-R-001 | *(Resolved 2026-08-28)* Spirit Ember pickup trigger was unspecified. | Would have blocked `LevelingSystem` pickup logic. | Resolved: pickup is automatic and immediate on defeating an enemy character (BR-023A). No move-onto-tile step. Retained here for traceability only. |
| HLD-R-002 | The end-of-turn Hero-capture check (BR-034) must use *exactly* the same movement-legality logic as ordinary moves, including active status effects (Slow, frost) at that moment — a second, drifted implementation would create rules bugs where a Hero is "trapped" by one code path but "free" by another. | Incorrect match endings — the most severe possible bug class for this rule. | `VictoryChecker` calls `BoardModel.get_legal_moves()` directly (Section 4.10, Flow C) — no duplicate logic. Add a dedicated test/playtest case for this specifically. |
| HLD-R-003 | Player-chosen back-row deployment (BR-007A) could leave a Hero immobile at the start of play, without necessarily being an intentional trap. | Confusing early loss once that Hero's controller ends a turn with it still immobile (BRD R-012). | `SetupFlow` should warn (not block) if a placement leaves a character with zero legal moves at setup time — a UX nicety, not a rules requirement. |
| HLD-R-004 | Relic/event deck shuffle needs a reproducible, syncable seed for the future networked-PvP extension point (Section 9), but the prototype has no networking to force this discipline now. | Retrofitting seeded shuffling later touches `RelicEventDeck` and `MatchState` together. | Store `deck_seed` explicitly in `MatchState` (Section 6) from the start, even though the prototype only ever runs it locally. |
| HLD-R-005 | *(Resolved 2026-08-28)* Godot version was not pinned in PRD/BRD. | Would have left autoload/signal syntax and `Resource` semantics ambiguous between Godot 3.x/4.x. | Resolved: latest stable Godot 4.7.x (currently 4.7.2). Re-verify exact patch at implementation time since maintenance releases continue. Retained here for traceability only. |
| HLD-R-006 | MVP-scale relic/event contribution model is undecided (BRD D-011) — still 3+4 per player from a larger pool, or different. | `RelicEventDeck`'s deck-construction logic (BR-027A) may need to change shape, not just data, at MVP. | Not a prototype blocker; flagged so `RelicEventDeck`'s construction step isn't hardcoded to "player's entire culture set" in a way that can't accept an actual selection UI later. |
| HLD-R-007 | Godot Web (HTML5) export has platform constraints (e.g., multithreading requires cross-origin-isolation headers from whatever serves the page; some native/GDExtension features are unavailable) that could surface late if the export target isn't exercised until the rules engine is mostly built. | Late-discovered incompatibilities are expensive to unwind (e.g., a threading assumption baked into `RulesEngine`). | Stand up a minimal Web export ("empty board scene loads and renders") as an early build step (Section 13, step 2/3), not after the rules engine is complete. |
| HLD-R-008 | `TestBridge`'s JS interop (Section 4.13) exposes internal match state and a direct action-dispatch path — if it ever shipped in a non-test build, it would be a way to fully script/cheat a match. | Trust/fairness risk if the test hook leaks into a real build (relevant once any competitive mode exists). | Gate `TestBridge` behind a Godot custom feature tag scoped to test/Web-export builds only (Section 4.13); confirm the tag is excluded from any future mobile/store export presets before those exist. |

## 12. Traceability

| HLD Section | BRD/PRD Source |
| --- | --- |
| 4.1 Content Loader | BRD FR-080–FR-082B, NFR-016, NFR-017, NFR-019 |
| 4.2 Board/Grid | BRD FR-010–FR-018A, BR-008–BR-011, BR-011A, FR-036D |
| 4.3 Match Setup | BRD FR-001–FR-009A, BR-001–BR-007B |
| 4.4 Rules Engine | BRD FR-021–FR-024, FR-027A, NFR-020, NFR-021 |
| 4.5 Combat Resolution | BRD FR-028–FR-036C |
| 4.6 Ability System | BRD FR-037–FR-045I |
| 4.7 Mounted Pair | BRD FR-045B–FR-045H, BR-012–BR-017 |
| 4.8 Leveling & Spirit Ember | BRD FR-046–FR-052, BR-022–BR-026 |
| 4.9 Relic/Event Deck | BRD FR-009A, FR-053–FR-059C, BR-027–BR-033 |
| 4.10 Victory Checker | BRD FR-060–FR-065, BR-034, BR-034A, BR-035 |
| 4.11 Debug/Inspection UI | BRD FR-084, PRD-FR-008 |
| 4.12 Presentation Layer | BRD FR-066–FR-074A, BR-044 |
| 4.13 Export & Test Harness | BRD FR-090A, NFR-031A |
| 9. Extension Points | BRD Section 6.2 (MVP Scope) |
| 11. Risks | BRD Section 14 (R-004, R-012), Section 15 (D-011) |

## 13. Next Steps

1. Install Godot 4.7.x (latest stable minor; verify exact patch at that time).
2. Scaffold the autoloads (`ContentDB`, `EventBus`, `GameState`, `TurnManager`, `RulesEngine`, `RelicEventDeck`, `VictoryChecker`, `TestBridge`) as empty singletons wired in Project Settings.
3. Stand up the Web export preset immediately and verify a minimal scene (empty board) exports and loads in a browser (HLD-R-007) — before deeper rules work, not after. Install the GUT addon alongside it for unit-level testing.
4. Implement `ContentDB`: parse `characters.json`/`relic_events.json` into `CharacterData`/`RelicEventData`; add a basic data-validation check (NFR-019), covered by GUT tests.
5. Build `BoardModel` and the `Tile` scene; implement `get_legal_moves`/`has_line_of_sight`/`get_tiles_in_range`.
6. Define `MatchState`/`PlayerState`/`CharacterInstance`/`BoardTile`/`StatusEffect`; build `SetupFlow` for culture selection and back-row placement (BR-007A).
7. Implement `TurnManager` (pool/character AP refresh, turn alternation).
8. Implement `RulesEngine` action validation/execution for move and attack first; wire `action_requested`/`action_resolved`.
9. Implement `CombatResolver` (damage, shields, defeat) and `MountSystem`.
10. Implement `AbilitySystem` for the 14 prototype character abilities, starting with the simplest passives before AP abilities.
11. Implement `LevelingSystem`, including automatic Spirit Ember pickup on defeat (BR-023A).
12. Implement `RelicEventDeck` draw/replace flow.
13. Implement `VictoryChecker` (Hero-capture check reusing `BoardModel`, plus army-defeat check).
14. Build `DebugPanel` subscribing to `EventBus`; play a full match start-to-finish through it before touching presentation polish.
15. Implement `TestBridge`'s `mythcards_get_state()`/`mythcards_dispatch_action()` hooks (Section 4.13); write the first Playwright test driving a full match through them.
16. Layer in `BoardView`/`HUD` (highlights, turn indicator, relic/event panel) on mobile-first `Control` anchoring.
