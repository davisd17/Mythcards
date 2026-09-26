# MythCards Low-Level Design — Debug/Inspection UI (`DebugPanel`)

**Document Control**

| Field | Value |
| --- | --- |
| Source document(s) | HLD.md (v3, 2026-09-07), BRD.md (v3, 2026-08-14), LLD-match-setup.md (v4), LLD-rules-engine.md (v5), LLD-combat-mount.md (v5), LLD-ability-system.md (v1), LLD-leveling.md (v1), LLD-relic-event-deck.md (v1), LLD-victory-checker.md (v1) |
| Module/flow scope | Debug/Inspection UI (`DebugPanel` — HLD Section 4.11). HLD build-order step 14. |
| Target stack | Godot 4.7.x, GDScript |
| Version | 1 |
| Date | 2026-09-08 |
| Status | Draft |
| Prepared by | Drew Davis (solo developer/designer, acting as own PM) |

## 1. Purpose & Scope

This LLD specs the playtesting overlay HLD Section 4.11 calls for: board state, AP (pool and per-character), HP, level, Spirit Ember status, and active relic/event effects — built, per that section's own stated intent, as "a pure `EventBus` listener specifically so it never reaches into other modules' internals, keeping the event-bus contract honest." This module is also, per HLD Section 2's own architecture-goals table, "the first consumer of the event bus... which validates the architecture" — if `DebugPanel` can render a coherent picture of the match from signals alone, that is itself evidence the signal set (HLD Section 5.3) is sufficient.

**Explicitly out of scope**: the polished `HUD`/`BoardView` presentation layer (HLD Section 4.12, a later LLD) — `DebugPanel` is deliberately plain-text/debug-grade, not the mobile-first player-facing UI.

## 2. File Layout

```
D:\mythcards\
├── scenes/
│   └── DebugPanel.tscn             (new — Control, child of Match.tscn's UILayer CanvasLayer,
│                                     per HLD Section 5.2's scene tree)
├── scripts/
│   └── ui/
│       └── debug_panel.gd          (new — script attached to DebugPanel.tscn)
└── tests/
    └── unit/
        └── test_debug_panel.gd     (new — extends GutTest; instantiates the script directly,
                                      not the full scene, and feeds it signals synthetically)
```

## 3. Class & Function Specs

### 3.1 `DebugPanel` (`res://scripts/ui/debug_panel.gd`)

```gdscript
extends Control

var _turn_number: int = 0
var _active_player_id: String = ""
var _pool_ap: Dictionary = {}          # String player_id -> int
var _character_ap: Dictionary = {}     # String character_id -> int
var _character_hp: Dictionary = {}     # String character_id -> int
var _character_level: Dictionary = {}  # String character_id -> int
var _character_position: Dictionary = {}  # String character_id -> Vector2i
var _character_has_ember: Dictionary = {}  # String character_id -> bool
var _active_relic: Dictionary = {}     # String player_id -> String card_id ("" if none)
var _last_event_resolved: String = ""  # most recent event card_id, "" if none yet
var _match_ended: bool = false
var _winner_id: String = ""
var _win_condition: String = ""
var _hero_capture_status: Dictionary = {}  # String player_id -> bool (has_legal_move), for
                                            # diagnostic display only (HLD Section 5.3's own
                                            # stated purpose for hero_capture_checked)

func _ready() -> void:
    EventBus.turn_started.connect(_on_turn_started)
    EventBus.turn_ended.connect(_on_turn_ended)
    EventBus.pool_ap_changed.connect(_on_pool_ap_changed)
    EventBus.character_ap_changed.connect(_on_character_ap_changed)
    EventBus.character_moved.connect(_on_character_moved)
    EventBus.attack_resolved.connect(_on_attack_resolved)
    EventBus.character_defeated.connect(_on_character_defeated)
    EventBus.character_leveled_up.connect(_on_character_leveled_up)
    EventBus.spirit_ember_picked_up.connect(_on_spirit_ember_picked_up)
    EventBus.spirit_ember_delivered.connect(_on_spirit_ember_delivered)
    EventBus.relic_drawn.connect(_on_relic_drawn)
    EventBus.relic_slot_changed.connect(_on_relic_slot_changed)
    EventBus.event_resolved.connect(_on_event_resolved)
    EventBus.hero_capture_checked.connect(_on_hero_capture_checked)
    EventBus.match_ended.connect(_on_match_ended)

func _bootstrap_from_state() -> void
    # See Section 4.1 -- the one deliberate, documented exception to "pure listener," needed
    # because no existing signal carries a full initial snapshot (Section 9).

func _on_turn_started(player_id: String) -> void
    # If this is the very first turn_started this panel has ever seen (_turn_number == 0):
    # call _bootstrap_from_state() first (Section 4.1), THEN apply this event's own data.
    # _turn_number += 1; _active_player_id = player_id; _refresh_display().
func _on_turn_ended(player_id: String) -> void
func _on_pool_ap_changed(player_id: String, remaining: int) -> void
func _on_character_ap_changed(character_id: String, remaining: int) -> void
func _on_character_moved(character_id: String, from: Vector2i, to: Vector2i) -> void
func _on_attack_resolved(attacker_id: String, target_id: String, damage: int, defeated: bool) -> void
func _on_character_defeated(character_id: String, defeated_by_id: String, cause: String) -> void
func _on_character_leveled_up(character_id: String, new_level: int) -> void
func _on_spirit_ember_picked_up(character_id: String) -> void
func _on_spirit_ember_delivered(character_id: String) -> void
func _on_relic_drawn(player_id: String, card_id: String) -> void
func _on_relic_slot_changed(player_id: String, card_id: String) -> void
func _on_event_resolved(card_id: String) -> void
func _on_hero_capture_checked(player_id: String, has_legal_move: bool) -> void
func _on_match_ended(winner_id: String, condition: String) -> void
    # Each mutates only its own directly-relevant local dictionary/field entries (Section 4.2),
    # then calls _refresh_display().

func _refresh_display() -> void
    # Rebuilds the panel's visible text from the local dictionaries/fields only -- never reads
    # GameState/MatchState/BoardModel/CharacterInstance directly (Section 4.1's bootstrap
    # exception aside). See Section 4.3 for the render layout.
```
Satisfies HLD Section 4.11 / BRD FR-084, PRD-FR-008.

## 4. Algorithms

### 4.1 Bootstrap exception

No signal in HLD's Section 5.3 map (nor any signal added by LLD-02 through LLD-08) carries a full initial snapshot of all 14 characters' starting HP/position/level, because `SetupFlow` itself emits no signals at all (LLD-match-setup.md Section 6 — setup is "a strictly synchronous, single-player-at-a-time UI flow with no concurrent state changes to broadcast"). Strictly following "pure listener" would leave `DebugPanel` blank until the first action fires. This LLD resolves that gap with one narrow, explicitly documented exception: on the *first* `turn_started` signal it ever receives (which always follows immediately after `SetupFlow.start_match()` completes, LLD-match-setup.md Section 3.6), `DebugPanel` performs a single direct read of `GameState.match_state` — iterating both players' `characters` arrays to seed `_character_hp`/`_character_level`/`_character_position`/`_character_has_ember`, and `GameState.match_state.players[*].pool_ap_remaining`/`active_relic_id` to seed `_pool_ap`/`_active_relic` — and never reads any module's internals again afterward. This is a pragmatic exception to HLD Section 4.11's stated design, not a silent violation of it; flagged in Section 9 rather than left implicit.

### 4.2 Signal handler bodies (representative — all follow the same shape)

- `_on_pool_ap_changed(player_id, remaining)`: `_pool_ap[player_id] = remaining`.
- `_on_character_ap_changed(character_id, remaining)`: `_character_ap[character_id] = remaining`.
- `_on_character_moved(character_id, from, to)`: `_character_position[character_id] = to`.
- `_on_attack_resolved(attacker_id, target_id, damage, defeated)`: decrement `_character_hp[target_id]` by `damage` (clamped at `0`) — this is a *local* re-derivation from the signal's own `damage` field, not a query back to `CombatResolver`, keeping the panel's data purely signal-sourced.
- `_on_character_defeated(character_id, defeated_by_id, cause)`: `_character_hp[character_id] = 0`.
- `_on_character_leveled_up(character_id, new_level)`: `_character_level[character_id] = new_level`.
- `_on_spirit_ember_picked_up(character_id)`: `_character_has_ember[character_id] = true`.
- `_on_spirit_ember_delivered(character_id)`: `_character_has_ember[character_id] = false` (the Ember is spent, LLD-leveling.md Section 4.2 step 3).
- `_on_relic_slot_changed(player_id, card_id)`: `_active_relic[player_id] = card_id`.
- `_on_event_resolved(card_id)`: `_last_event_resolved = card_id`.
- `_on_hero_capture_checked(player_id, has_legal_move)`: `_hero_capture_status[player_id] = has_legal_move`.
- `_on_match_ended(winner_id, condition)`: `_match_ended = true`; `_winner_id = winner_id`; `_win_condition = condition`.

Every handler ends with `_refresh_display()`.

### 4.3 `_refresh_display` layout

Renders a single scrollable text block (one `RichTextLabel` is sufficient for a debug overlay — no need for per-field UI controls at this tier), in this fixed order: match status line (`_match_ended` ? "MATCH OVER — <winner_id> wins by <win_condition>" : "Turn <_turn_number> — active: <_active_player_id>"); per-player section (pool AP, active relic id, Hero-capture diagnostic from `_hero_capture_status`); per-character rows (id, position, HP, level, AP, Ember status) grouped by player. `[NEED]` exact text formatting/layout is a cosmetic detail this LLD leaves to implementation-time judgment, per the `lld-writer` skill's solo-dev-scale guidance against padding process into a document that doesn't need it — the *data* driving the display (Section 4.2) is what needs to be precise, not its pixel layout.

## 5. Data Structures

All state is local to this script (Section 3.1's dictionaries/fields) — deliberately not derived from `MatchState`/`CharacterInstance` types directly, to keep this module decoupled from those classes' internal shapes (a change to `CharacterInstance`'s fields, for instance, would not require touching `DebugPanel` unless it also changed a signal payload).

## 6. Signal/Payload Specs

`DebugPanel` emits no signals — it is a pure sink. It listens to every signal in HLD Section 5.3's map except `action_requested`/`action_resolved` (redundant with the more specific signals already listed, which already cover every outcome those two report) and `spirit_ember_delivered`'s… no, `spirit_ember_delivered` is listened to (Section 4.2). The two intentionally *not* subscribed are `action_requested` and `action_resolved` themselves — every effect they announce is already captured by a more specific signal (`character_moved`, `attack_resolved`, etc.), so subscribing to both would double-count nothing observable but add unused noise to this module's signal surface.

## 7. Error Handling & Edge Cases

| Scenario | Expected behavior | Source |
| --- | --- | --- |
| A signal fires for a `character_id` this panel has never seen before `_bootstrap_from_state()` ran (should not happen given bootstrap runs on the very first `turn_started`, before any action can occur) | Dictionary `[]=` assignment creates the entry on demand — no crash either way, since GDScript dictionaries don't require pre-declared keys | Section 4.1 |
| `_bootstrap_from_state()` is somehow triggered twice (e.g. `_turn_number` guard logic has a bug) | Re-reads `GameState.match_state` and overwrites the same keys with the same values — idempotent, not harmful, though the guard (Section 3.1's `_on_turn_started`) is intended to prevent this | Section 4.1 |
| `DebugPanel` is toggled off (hidden) mid-match and back on later | Continues accumulating signal-driven state regardless of visibility (`_refresh_display()` still runs; only the `Control`'s `visible` property, toggled independently per HLD Section 5.2, gates whether it's drawn) — no data loss from being hidden | HLD Section 5.2 |
| `attack_resolved`'s `damage` reduces `_character_hp[target_id]` below what `character_defeated` later reports (e.g. due to a shield consumed between signals in a way this panel doesn't model in detail) | Not a concern — `_on_character_defeated` unconditionally sets HP to exactly `0` (Section 4.2), overriding any drift from the simpler `attack_resolved`-based subtraction, so the displayed HP is always correct at the moment of defeat regardless of intermediate rounding | Section 4.2 |

## 8. Test Plan

Unit tests use **GUT**, instantiating `debug_panel.gd` directly (not the full scene) and calling its `_on_*` handlers directly rather than routing through real `EventBus` signal emission (faster, and this module's own logic is what's under test, not `EventBus` itself).

| Case | Given | When | Then | BRD ID |
| --- | --- | --- | --- | --- |
| C1 | Fresh panel | `_on_pool_ap_changed("p1", 3)` called | `_pool_ap["p1"] == 3` | FR-084 |
| C2 | Fresh panel | `_on_character_moved("p1_r-gymnast", Vector2i(3,0), Vector2i(3,1))` | `_character_position["p1_r-gymnast"] == Vector2i(3,1)` | FR-084 |
| C3 | `_character_hp["x"] == 3` | `_on_attack_resolved("y", "x", 2, false)` | `_character_hp["x"] == 1` | FR-084 |
| C4 | Any HP value | `_on_character_defeated("x", "y", "direct")` | `_character_hp["x"] == 0` | FR-084 |
| C5 | Fresh panel | `_on_spirit_ember_picked_up("x")` then `_on_spirit_ember_delivered("x")` | `_character_has_ember["x"] == false` after both | FR-052 |
| C6 | Fresh panel | `_on_match_ended("p2", "hero_capture")` | `_match_ended == true`, `_winner_id == "p2"`, `_win_condition == "hero_capture"` | FR-064 |
| C7 | `_turn_number == 0`, a real `GameState.match_state` populated with 14 characters | `_on_turn_started("p1")` | `_character_hp`/`_character_position`/`_character_level` all populated for all 14 characters (bootstrap ran); `_turn_number == 1` | Section 4.1 |
| C8 | `_turn_number == 1` already (bootstrap already ran) | `_on_turn_started("p2")` | Bootstrap does NOT re-run (verified via a spy on `GameState.match_state` access, or simply that pre-seeded values from C7 aren't stomped by a second full re-read after other signals have since changed them) | Section 4.1 |

## 9. Open Implementation Questions

- **The Section 4.1 bootstrap exception is a deliberate, narrow departure from HLD Section 4.11's "pure listener" framing** — flagged explicitly rather than silently implemented, since it's the one place this module reaches into another module's internals. If a future `match_started`-style full-snapshot signal is ever added for another consumer's benefit (none currently need one), this bootstrap could be replaced with a subscription to it instead.
- **Exact render layout/formatting (Section 4.3)** is left to implementation-time judgment as a cosmetic, not a rules, detail.
- **No signal exists for "the shared deck's remaining card count" or similar meta-state** — not needed by any current display requirement (FR-084 lists board state/AP/HP/level/effects, not deck size), so not modeled.

## 10. Traceability

| LLD Section | HLD Section | BRD/PRD IDs |
| --- | --- | --- |
| 3.1, 4.1–4.2 Signal consumption | HLD 4.11, 5.3 | FR-084 |
| 4.3 Display | HLD 4.11 | PRD-FR-008 |

## 11. Next Steps

1. Create `scenes/DebugPanel.tscn` (a `Control` with one `RichTextLabel`) and `scripts/ui/debug_panel.gd` (Section 3.1); add it under `Match.tscn`'s `UILayer` per HLD Section 5.2, toggled independently of `HUD`.
2. Write `tests/unit/test_debug_panel.gd`; confirm C1–C8.
3. Play a full match start-to-finish through this panel alone (no `HUD`/`BoardView` yet) before touching presentation polish — this is explicitly HLD Section 13 step 14's own stated purpose for building `DebugPanel` before the presentation layer.
