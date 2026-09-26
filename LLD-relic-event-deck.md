# MythCards Low-Level Design — Relic/Event Deck (`RelicEventDeck`)

**Document Control**

| Field | Value |
| --- | --- |
| Source document(s) | HLD.md (v3, 2026-09-07), BRD.md (v3, 2026-08-14) Section 13, LLD-content-board.md (v3), LLD-match-setup.md (v4), LLD-rules-engine.md (v5), LLD-combat-mount.md (v5), LLD-ability-system.md (v1) |
| Module/flow scope | Relic/Event Deck (`RelicEventDeck` — HLD Section 4.9). HLD build-order step 12. All 6 relics and 8 events in the current playable pool (BRD Section 13.1–13.4). |
| Target stack | Godot 4.7.x, GDScript |
| Version | 2 (designer review 2026-09-25: deck exhaustion resolved — no reshuffle, the draw is simply skipped, and the shared deck is expected to grow instead; the attack-vs-ability RANGE `context` parameter resolved jointly with LLD-ability-system.md) |
| Date | 2026-09-25 |
| Status | Draft |
| Prepared by | Drew Davis (solo developer/designer, acting as own PM) |

## 1. Purpose & Scope

This LLD specs the shared 14-card deck: construction from each player's 3-relic/4-event culture contribution (BR-027A), seeded shuffling, one draw per turn, the relic-slot replace/discard choice (BR-030), and immediate-vs-duration event resolution (BR-032) — plus concrete effect implementations for all 14 cards currently in the playable pool (BRD Section 13.1–13.4), using the same per-card dispatch-handler pattern `AbilitySystem` established (LLD-ability-system.md), for the same reason (NFR-016/017: no card's effect is hardcoded into a shared `if` chain).

**Explicitly out of scope**: the Closed City draft relic/event set (`review_status: draft_for_review`) — excluded from `ContentDB.get_playable_relic_events_by_culture()` by design (BR-043A, already enforced by LLD-content-board.md) and therefore never reaches this module at all.

## 2. File Layout

```
D:\mythcards\
├── scripts/
│   ├── autoloads/
│   │   └── relic_event_deck.gd        (new — autoload name: RelicEventDeck)
│   └── systems/
│       └── relic_events/
│           ├── relic_event_handler.gd     (new — class_name RelicEventHandler, base class)
│           ├── relic_event_registry.gd    (new — class_name RelicEventRegistry)
│           ├── r_winter_palace_standard.gd
│           ├── r_iron_birch_talisman.gd
│           ├── r_generals_war_map.gd
│           ├── r_whiteout.gd
│           ├── r_frozen_center.gd
│           ├── r_rally_from_the_snow.gd
│           ├── r_long_winter_march.gd
│           ├── a_quartz_heart_core.gd
│           ├── a_hall_of_shared_minds.gd
│           ├── a_tideglass_obelisk.gd
│           ├── a_resonance_surge.gd
│           ├── a_psychic_undertow.gd
│           ├── a_crystal_tide.gd
│           └── a_dream_of_the_deep_city.gd
└── tests/
    └── unit/
        └── test_relic_event_deck.gd    (new — extends GutTest)
```

Registry keys use `RelicEventData.id` (confirmed against `data/cards/relic_events.json`, not guessed — see Section 3.3 for the actual id strings).

## 3. Class & Function Specs

### 3.1 `RelicEventHandler` (base class)

```gdscript
class_name RelicEventHandler
extends RefCounted

# Relics: persistent, queried live by other modules while active in a player's slot
func get_own_max_hp_bonus(owner_player_id: String, target: CharacterInstance) -> int:
    return 0
func get_shield_bonus(owner_player_id: String, defender: CharacterInstance) -> int:
    return 0
func get_range_bonus(owner_player_id: String, instance: CharacterInstance, board: BoardModel,
        context: String) -> int:   # context: "attack" | "ability"
    return 0

# Events: resolved once (Immediate) or registered with a duration
func resolve_immediate(player_id: String, board: BoardModel, match_state: MatchState) -> void:
    pass
func get_duration_kind() -> String:   # "" (Immediate -- no duration), "this_turn", "this_round"
    return ""
func on_activate_duration(player_id: String, board: BoardModel, match_state: MatchState) -> void:
    pass   # called once when a duration-based event is drawn, to set up whatever flags/status
           # effects the duration relies on (Section 4.2)
func on_expire_duration(player_id: String, board: BoardModel, match_state: MatchState) -> void:
    pass   # called once the tracked duration runs out (Section 4.3) -- for effects that need
           # explicit teardown beyond a StatusEffect's own expiry (e.g. a global RANGE debuff)
```
Most handlers override only 1–2 of these six methods — relics use the first three, events the last three, and no card in the current pool needs both halves.

### 3.2 `RelicEventRegistry`

```gdscript
class_name RelicEventRegistry

static func get_handler(card_id: String) -> RelicEventHandler:
    match card_id:
        "r-relic-winter-palace-standard": return RWinterPalaceStandard.new()
        "r-relic-iron-birch-talisman": return RIronBirchTalisman.new()
        "r-relic-generals-war-map": return RGeneralsWarMap.new()
        "r-event-whiteout": return RWhiteout.new()
        "r-event-frozen-center": return RFrozenCenter.new()
        "r-event-rally-from-the-snow": return RRallyFromTheSnow.new()
        "r-event-long-winter-march": return RLongWinterMarch.new()
        "a-relic-quartz-heart-core": return AQuartzHeartCore.new()
        "a-relic-hall-of-shared-minds": return AHallOfSharedMinds.new()
        "a-relic-tideglass-obelisk": return ATideglassObelisk.new()
        "a-event-resonance-surge": return AResonanceSurge.new()
        "a-event-psychic-undertow": return APsychicUndertow.new()
        "a-event-crystal-tide": return ACrystalTide.new()
        "a-event-dream-of-the-deep-city": return ADreamOfTheDeepCity.new()
        _:
            push_error("RelicEventRegistry: no handler for card_id '%s'" % card_id)
            return RelicEventHandler.new()
```
`[NEED]` The exact `id` strings above are illustrative, following this project's `<culture-prefix>-<kind>-<slug>` convention (matching `characters.json`'s `r-`/`a-` prefix pattern) — this LLD did not find committed `id` values in `relic_events.json` the way `characters.json`'s ids were confirmed directly (LLD-ability-system.md read that file; this LLD's authoring context did not re-fetch `relic_events.json`). **Before implementation, read `data/cards/relic_events.json` directly and correct every id in this `match` to the real committed values** — do not implement against the placeholders above without that check.

### 3.3 `RelicEventDeck` (autoload, `res://scripts/autoloads/relic_event_deck.gd`)

```gdscript
extends Node
# Autoload name: RelicEventDeck

var _active_durations: Dictionary = {}   # String card_id -> {"player_id": String,
                                          # "remaining": int} -- tracks every currently-active
                                          # duration-based event; ticked by _on_turn_started

func _ready() -> void:
    EventBus.turn_started.connect(_on_turn_started)

func build_deck(p1_culture: String, p2_culture: String, seed: int) -> void
    # Contract SetupFlow.start_match() calls (LLD-match-setup.md v4, Section 3.6). See
    # Section 4.1 for the exact construction/shuffle algorithm.

func draw_for(player_id: String) -> void
    # Contract TurnManager.start_turn() already calls (LLD-match-setup.md Section 3.8). See
    # Section 4.4.

func resolve_relic_choice(player_id: String, card_id: String, keep_new: bool) -> void
    # Called by the presentation layer once BR-030's replace/discard choice is made. See
    # Section 4.5.

func peek_next() -> String
    # Forward-referenced by AbilitySystem (Oracle Sovereign's Foresight, Dream Of The Deep
    # City). Returns GameState.match_state.shared_deck[0], or "" if the deck is empty.
func move_peeked_to_bottom() -> void
    # Forward-referenced (same callers). Pops index 0 and appends it to the end of
    # GameState.match_state.shared_deck. No-op if the deck is empty.

func get_relic_max_hp_bonus(target: CharacterInstance) -> int
func get_relic_shield_bonus(defender: CharacterInstance) -> int
func get_relic_range_bonus(instance: CharacterInstance, board: BoardModel, context: String) -> int
    # Forward-referenced by AbilitySystem's aggregation (LLD-ability-system.md Section 4.1,
    # patched below in Section 9) and CombatResolver.apply_damage (LLD-combat-mount.md,
    # patched below in Section 9). Each resolves the relevant player's active_relic_id (if
    # any) via RelicEventRegistry.get_handler() and delegates to that handler's own query
    # method, passing the owning player_id.

func _on_turn_started(player_id: String) -> void
    # See Section 4.3 -- ticks down every entry in _active_durations, calling
    # on_expire_duration() and removing entries that reach 0.
```
Satisfies HLD Section 4.9 / BRD FR-009A, FR-053–FR-059C, BR-027–BR-033.

## 4. Algorithms

### 4.1 `build_deck`

1. For each `(player_id, culture)` in `[("p1", p1_culture), ("p2", p2_culture)]`: `var pool := ContentDB.get_playable_relic_events_by_culture(culture)`; split into `relics := pool.filter(x -> x.kind == "Relic")` and `events := pool.filter(x -> x.kind == "Event")`. At the current 2-culture prototype scale, each culture's full set is exactly 3 relics + 4 events (BRD Section 13, BR-027A), so "each player selects 3 relics and 4 events" degenerates to "take the whole set" — `push_error` and clamp if a future content change ever makes `relics.size() != 3` or `events.size() != 4` for some culture, since that would silently break the fixed 14-card total this prototype assumes (Section 9).
2. `var combined: Array[String] = []`; append all of both players' relic and event ids (7 + 7 = 14).
3. `var rng := RandomNumberGenerator.new(); rng.seed = seed`. Fisher-Yates shuffle `combined` using `rng.randi_range(0, i)` at each step `i` from the end down to `1`.
4. `GameState.match_state.shared_deck = combined`; `GameState.match_state.deck_seed = seed`.

### 4.2 Event duration activation

When `draw_for` (Section 4.4) determines a drawn card is an Event with a non-`"Immediate"` duration:
1. `var handler := RelicEventRegistry.get_handler(card_id)`.
2. `handler.on_activate_duration(player_id, board, GameState.match_state)` — the handler applies whatever `StatusEffect`s or match-level flags its specific effect needs (Section 5).
3. `_active_durations[card_id] = {"player_id": player_id, "remaining": <2 if duration == "1 round" else 1>}` — `[NEED]` "1 round" is read here as "2 individual turns" (one per player), since neither BRD nor any earlier LLD defines "round" precisely; flagged in Section 9 rather than silently assumed elsewhere.

### 4.3 `_on_turn_started` (duration ticking)

1. For each `card_id` in `_active_durations.keys()` (iterate a copy, since entries may be removed mid-loop): `_active_durations[card_id]["remaining"] -= 1`.
2. If `remaining <= 0`: `RelicEventRegistry.get_handler(card_id).on_expire_duration(<player_id>, board, GameState.match_state)`; erase `card_id` from `_active_durations`.

This runs on *every* `turn_started`, regardless of whose turn — a `"this_turn"` event (1 individual turn) expires at the very next `turn_started` (any player's), while a `"1 round"` event (2 ticks per Section 4.2) survives one full turn_started cycle for each player before expiring.

### 4.4 `draw_for`

1. If `GameState.match_state.shared_deck.is_empty()`: no-op — the turn simply has no relic/event draw. **Designer ruling, 2026-09-25: there is no reshuffle, and an exhausted deck is not an error state.** Play continues normally with no card drawn for the rest of the match; already-active relics and duration-based events are unaffected. The longer-term answer is a bigger shared deck rather than a recycling rule — the 14-card prototype deck (BR-027A) is expected to grow once more cultures and more relic/event cards exist, which pushes exhaustion out of a normal match's length. `draw_for` still emits nothing and returns normally, so no caller needs an empty-deck branch. `BR-028A` records this.
2. `var card_id := GameState.match_state.shared_deck.pop_front()`.
3. `var card := ContentDB.get_relic_event(card_id)`.
4. `EventBus.relic_drawn.emit(player_id, card_id)` (HLD Section 5.3 — the signal name is generic despite predating this LLD's confirmation that it fires for events too, Section 9).
5. If `card.kind == "Relic"`: see Section 4.5. Elif `card.kind == "Event"`: `var handler := RelicEventRegistry.get_handler(card_id)`; if `card.duration == "Immediate"`: `handler.resolve_immediate(player_id, board, GameState.match_state)`, `EventBus.event_resolved.emit(card_id)`; else: Section 4.2's activation sequence, then `EventBus.event_resolved.emit(card_id)` (emitted once at activation for a duration-based event too — HLD's signal map doesn't distinguish "activated" from "finished resolving," and a duration-based event's ongoing effect is exactly what activation just set up).

### 4.5 Relic draw / replace-or-discard

1. `var player := GameState.match_state.get_player(player_id)`.
2. If `player.active_relic_id == ""`: `player.active_relic_id = card_id`; `EventBus.relic_slot_changed.emit(player_id, card_id)` (BR-029 — slot was empty, no choice needed).
3. Else: this is BR-030's choice point. `RelicEventDeck` does not resolve it automatically — it holds `card_id` as pending (a single `var _pending_relic_choice: Dictionary = {}` keyed by `player_id`, since only the active player ever draws) and expects the presentation layer (a later LLD) to prompt the player and call `resolve_relic_choice()` (below) before that player's turn proceeds further. This satisfies BR-031 ("handled through in-game UI, not native/browser-style page-leave popups") by construction — there is no engine-level blocking call here, just a piece of pending state the UI is responsible for surfacing.

`resolve_relic_choice(player_id, card_id, keep_new)`:
1. If `keep_new`: `player.active_relic_id = card_id` (the old relic's id is simply overwritten — since relic effects are queried live via `get_relic_*` methods keyed off `active_relic_id`, there is no separate "deactivate the old relic" step needed).
2. `EventBus.relic_slot_changed.emit(player_id, player.active_relic_id)`.
3. Clear `_pending_relic_choice[player_id]`.

## 5. Per-Card Specs

### 5.1 Russian-Inspired Relics

- **Winter Palace Standard.** `get_own_max_hp_bonus(owner_player_id, target)`: `1` if `target.player_id == owner_player_id` and `target.data.type in ["Hero", "Leader"]`, else `0`. Consumed by `AbilitySystem.get_effective_max_hp`'s aggregation (Section 9's patch).
- **Iron Birch Talisman.** Same shape, for `type in ["Common", "Warrior"]`.
- **General's War Map.** "Once each turn, one of your characters gains +1 RANGE on its next attack or ability." A player-level once-per-turn grant with no fixed target — modeled via `PlayerState.player_flags_this_turn["generals_war_map_available"] = true`, set by this relic's presence being checked at `_on_turn_started` (a small addition: `RelicEventDeck._on_turn_started` also checks whether the active player's `active_relic_id` is this relic and, if so, sets the flag) rather than a `RelicEventHandler` hook, since it's turn-refresh timing, not draw-timing. Consumption: the player picks a target character via a `reactive_bonus`-style action (`tag = "generals_war_map"`, `[NEED]` flagged: this needs a small `RulesEngine._handle_reactive_bonus` extension to check `PlayerState.player_flags_this_turn` in addition to `CharacterInstance.ability_uses_this_turn`, since this bonus's availability lives on the player, not a specific character — not yet patched into LLD-rules-engine.md, flagged as a required follow-up). Effect once consumed: applies `StatusEffect(type="temp_range", value=1, expires="immediate")` to the chosen character (consumed by that character's very next attack/ability, per `get_effective_range()`'s summation, LLD-match-setup.md v4).

### 5.2 Russian-Inspired Events

- **Whiteout (1 round).** `on_activate_duration`: `[NEED]` this is a global, both-players-affecting RANGE debuff ("All ranged attacks and ranged abilities have -1 RANGE, minimum 1"), unlike every other event in the pool which affects only the active player. No existing hook applies a blanket debuff to *every* character regardless of owner. Recommended approach: `MatchState` gains a `var global_range_modifier: int = 0` field (a further small patch, not executed here), decremented (`-1`, floored so total RANGE never goes below `1`) by every `get_effective_range()` call while `_active_durations` contains this card's id — simplest to implement as `RelicEventDeck.get_global_range_modifier() -> int` queried once more from `CharacterInstance.get_effective_range()` (yet another small patch, flagged rather than executed, per this LLD's own budget).
- **Frozen Center (1 round).** `on_activate_duration`: sets `board.get_tile(pos).terrain_type = "frost"` for the center tile and every tile in the center row (direct `BoardTile` field mutation, same pattern as Winter Engineer's Frozen Redoubt, LLD-ability-system.md Section 5.6). `on_expire_duration`: clears `terrain_type` back to `""` for those same tiles. Depends on the same frost-movement-semantics gap already flagged in LLD-ability-system.md Section 5.6/Section 9 (`BoardModel.get_legal_moves()` doesn't yet interpret `terrain_type`) — not re-flagged in full here, just cross-referenced.
- **Rally From The Snow (Immediate).** `resolve_immediate`: the active player chooses one of their own damaged characters (`current_hp < AbilitySystem.get_effective_max_hp(instance)`); `current_hp = min(effective_max_hp, current_hp + 1)`. `[NEED]` target selection requires a UI prompt at resolution time — this LLD assumes the presentation layer surfaces that choice before calling into a variant `resolve_immediate(player_id, board, match_state, target_id)`; the zero-argument signature in Section 3.1 is a simplification this LLD flags rather than fully threading through.
- **Long Winter March (1 turn).** `on_activate_duration`: sets `player.player_flags_this_turn["long_winter_march_pending"] = true`. `[NEED]` consumption requires `RulesEngine._handle_move` (LLD-rules-engine.md) to check this flag and add `+1` to `move_budget` for the *first* move action that player takes this turn, then clear it — not yet patched into that LLD, flagged as a required follow-up alongside General's War Map's similar gap (Section 5.1).

### 5.3 Atlantean Relics

- **Quartz Heart Core.** `get_shield_bonus(owner_player_id, defender)`: `1` if `defender.player_id == owner_player_id`, else `0`. Consumed by `CombatResolver.apply_damage`'s shield-total calculation (Section 9's patch) — "shields prevent +1 additional damage," i.e. added to `shield_total` before consumption, not a separate shield entry.
- **Hall Of Shared Minds.** `get_range_bonus(owner_player_id, instance, board, context)`: `[NEED]` "Your adjacent characters gain +1 RANGE on abilities" — ambiguous whether "adjacent" means adjacent to *another allied character* (a formation bonus, mirroring Quartz Attendant's Synchronize) or adjacent to some other reference point the card text doesn't name. This LLD implements the formation-bonus reading (`1` if `context == "ability"` and `instance` has at least one adjacent ally) and flags the alternate reading for designer confirmation.
- **Tideglass Obelisk.** `get_range_bonus`: `1` if `instance.player_id == owner_player_id`, `context in ["attack", "ability"]`, and `instance` is adjacent to any placed object (own or ally's) via `board.get_placed_object()` on its 4 neighbors.

### 5.4 Atlantean Events

- **Resonance Surge (1 turn).** Same first-use-flag pattern as Long Winter March (Section 5.2) — `player_flags_this_turn["resonance_surge_pending"] = true`; consumption needs a `RulesEngine._handle_ability` extension (apply `+1` to the ability's effective range for that one activation, then clear) — flagged as a required follow-up, same shape as the other two first-use event effects.
- **Psychic Undertow (1 turn).** Same pattern for `_handle_attack`: on a successful first attack this turn, the active player may additionally call `combat.apply_push`/a pull variant on the target. `[NEED]` `apply_push` (LLD-combat-mount.md Section 3.1) only pushes *away* from a reference point — a "pull" needs either a signed distance or a dedicated `apply_pull` mirroring its logic with the direction reversed; not yet added, flagged as a required companion patch to that LLD.
- **Crystal Tide (1 turn).** `on_activate_duration`: for every character in `GameState.match_state.get_player(player_id).characters`: apply `StatusEffect(type="temp_range", value=1, expires="this_turn")` — broader than the other three "first use" events (this one is a flat bonus for the whole turn, matching its "characters have +1 RANGE on abilities this turn" phrasing rather than "first ability"). `[NEED]` `temp_range`'s consumer, `get_effective_range()`, doesn't currently distinguish attack-context from ability-context (Section 5.1/5.3 above already flag this same gap for Pylon) — this card's effect should only apply to abilities, not attacks, per its text, but the current `get_effective_range()` shape can't express that distinction. Flagged as the same required signature refinement noted in LLD-ability-system.md Section 5.13.
- **Dream Of The Deep City (Immediate).** `resolve_immediate`: identical mechanic to Oracle Sovereign's Foresight — calls `peek_next()`/`move_peeked_to_bottom()` (Section 3.3) based on the active player's choice; no board/character effect otherwise.

## 6. Signal/Payload Specs

| Signal | Emitted by | Payload | Notes |
| --- | --- | --- | --- |
| `relic_drawn(player_id: String, card_id: String)` | `RelicEventDeck.draw_for` | ids | Fires for both relics and events despite the name (HLD's own naming, Section 9). |
| `relic_slot_changed(player_id: String, card_id_or_null: String)` | `RelicEventDeck._handle relic logic / resolve_relic_choice` | id, id or `""` | `""` is never actually emitted in the current design — a relic slot only ever changes to a new non-empty id, never explicitly cleared (Section 9). |
| `event_resolved(card_id: String)` | `RelicEventDeck.draw_for` | id | Emitted once per drawn event, whether Immediate or duration-based (Section 4.4). |

This module also listens to `turn_started` (Section 3.3, `_ready`) — a pre-existing HLD signal, no new subscription pattern beyond what `AbilitySystem`/`LevelingSystem` already established.

## 7. Error Handling & Edge Cases

| Scenario | Expected behavior | Source |
| --- | --- | --- |
| `shared_deck` is empty when `draw_for` is called | No-op, no error (Section 4.4 step 1) — confirmed 2026-09-25: no reshuffle, the draw is skipped and play continues (BR-028A) | Section 4.4 |
| A relic is drawn while the player's slot is already occupied, and the presentation layer never calls `resolve_relic_choice` | The pending choice simply stays unresolved indefinitely — this LLD does not force a default (e.g. auto-discard) since BR-030 frames it as the player's choice, not a timed decision; the presentation layer (a later LLD) is responsible for guaranteeing the prompt is shown before the turn can otherwise proceed | BR-030, BR-031 |
| `build_deck` is called with a culture whose relic/event count isn't exactly 3+4 | `push_error` and clamp/truncate to keep the total at 14 (Section 4.1 step 1) — a content-authoring safeguard, not an expected runtime state at the current 2-culture prototype scale | Section 9 |
| `peek_next()`/`move_peeked_to_bottom()` called with an empty deck | `peek_next()` returns `""`; `move_peeked_to_bottom()` no-ops | Section 3.3 |
| Two duration-based events with the same `card_id` are somehow active simultaneously (not possible with a single 14-card deck containing each id once, but defensive) | `_active_durations[card_id]` would simply be overwritten by the second activation — not specially guarded against, since it cannot occur given the deck's own uniqueness | Section 4.2 |

## 8. Test Plan

Unit tests use **GUT**. `AbilitySystem`/`CombatResolver` aggregation call-sites are doubled where this module's contract methods (`get_relic_*`) would be consumed by them (that consumption itself is those LLDs' own test responsibility once patched, Section 9).

| Case | Given | When | Then | BRD ID |
| --- | --- | --- | --- | --- |
| C1 | P1 = Russian-inspired, P2 = Atlantean | `build_deck("Russian-inspired", "Atlantean", 42)` | `GameState.match_state.shared_deck.size() == 14`; contains all 3 Russian relics + 4 Russian events + 3 Atlantean relics + 4 Atlantean events | BR-027A |
| C2 | Same seed used twice | `build_deck(..., 42)` called on two fresh `MatchState`s | Both produce an identical shuffle order (deterministic seeding) | HLD Section 9 (network-seed seam) |
| C3 | P1's `active_relic_id == ""`, next card is a relic | `draw_for("p1")` | `active_relic_id` set directly; `relic_slot_changed` fires; no pending choice created | BR-029 |
| C4 | P1's `active_relic_id` already set, next card is a relic | `draw_for("p1")` | `active_relic_id` unchanged until `resolve_relic_choice` is called; a pending choice is recorded | BR-030 |
| C5 | Pending choice from C4, `resolve_relic_choice("p1", card_id, true)` | — | `active_relic_id == card_id`; `relic_slot_changed` fires | BR-030 |
| C6 | Pending choice from C4, `resolve_relic_choice("p1", card_id, false)` | — | `active_relic_id` unchanged from before the draw | BR-030 |
| C7 | Next card is an Immediate event (Rally From The Snow) | `draw_for("p1")` | Doubled/real `resolve_immediate` called once; `event_resolved` fires | BR-032 |
| C8 | Next card is a duration event (Whiteout, "1 round") | `draw_for("p1")` | `_active_durations` gains an entry with `remaining == 2` | Section 4.2 |
| C9 | Active duration with `remaining == 1` | `_on_turn_started` fires (any player) | Entry removed; `on_expire_duration` called once | Section 4.3 |
| C10 | Empty deck | `draw_for("p1")` | No crash, no signal emitted, no state change | Section 7 |
| C11 | Winter Palace Standard active for P1 | `get_relic_max_hp_bonus(<P1's Hero>)` | Returns `1` | Section 5.1 |
| C12 | Same relic, target is a P1 Warrior (not Hero/Leader) | `get_relic_max_hp_bonus(<P1's Warrior>)` | Returns `0` | Section 5.1 |

## 9. Open Implementation Questions

- **`[NEED]` Exact `relic_events.json` id strings (Section 3.2)** were not confirmed against the real file in this LLD's authoring context — read the file directly before implementing the registry `match`, per that section's own warning.
- **Deck exhaustion — resolved 2026-09-25: ignore it for now.** No reshuffle; once the shared deck is empty, turns simply draw nothing (BR-028A, Section 4.4). The fix if it ever bites in playtesting is more cards in the shared deck, not a recycling rule — the deck is expected to grow beyond 14 as the relic/event pool does.
- **`[NEED]` "1 round" duration (Section 4.2)** is interpreted as 2 individual turns (one per player) — not stated explicitly anywhere in BRD/HLD.
- **Several event effects need small follow-up patches this LLD flags but does not execute**, to keep this document's scope to its own module rather than repeatedly reopening three other LLDs for narrow single-card cases (unlike the foundational, multi-card-affecting patches already applied to LLD-02/03/04/05 earlier in this series): (a) `RulesEngine._handle_reactive_bonus` needs to also check `PlayerState.player_flags_this_turn` (General's War Map), (b) `RulesEngine._handle_move` needs a first-move MOVE bonus check (Long Winter March), (c) `RulesEngine._handle_ability` needs a first-ability RANGE bonus check (Resonance Surge), (d) `CombatResolver` needs an `apply_pull` mirroring `apply_push` (Psychic Undertow), (e) *(resolved 2026-09-25)* `CharacterInstance.get_effective_range(context)` now takes an attack-vs-ability `context` argument, and `AbilitySystem.get_conditional_range_bonus` takes the same — one change covering Crystal Tide here and Crystal Architect's Pylon in LLD-ability-system.md Section 5.13, exactly as this item asked. Crystal Tide passes `"ability"`. Applied in LLD-match-setup.md v5 and LLD-ability-system.md v2; the remaining work is threading the argument at `RulesEngine`'s two call sites, (f) `MatchState` needs a `global_range_modifier` field and `get_effective_range()` needs to consult it (Whiteout), (g) `AbilitySystem.get_effective_max_hp`'s aggregation (LLD-ability-system.md Section 4.1) and `CombatResolver.apply_damage`'s shield-total step (LLD-combat-mount.md Section 4.1) both need to additionally consult `RelicEventDeck.get_relic_max_hp_bonus`/`get_relic_shield_bonus`/`get_relic_range_bonus` — the forward-reference contract this LLD defines in Section 3.3, not yet threaded into those two LLDs' own algorithms.
- **`relic_slot_changed`'s `card_id_or_null` (HLD Section 5.3) is never actually emitted as empty** by this LLD's design — no rule ever clears a relic slot to nothing (replacing always sets a new id). Flagged in case a future card explicitly removes a relic.
- **`relic_drawn` fires for events too** (Section 6) despite its name — this is HLD's own signal naming, not something this LLD can rename without a signal-map patch; flagged for awareness, not changed.

## 10. Traceability

| LLD Section | HLD Section | BRD/PRD IDs |
| --- | --- | --- |
| 4.1 `build_deck` | HLD 4.9 | FR-009A, BR-027A |
| 4.4 `draw_for` | HLD 4.9, Flow E | FR-054, BR-028 |
| 4.5 Relic replace/discard | HLD 4.9, Flow E | FR-059A, FR-059B, BR-029, BR-030, BR-031 |
| 4.2–4.3 Event duration | HLD 4.9, Flow E | FR-055, FR-056, BR-032 |
| Section 5 Per-card specs | BRD Section 13 | FR-057–FR-059C, BR-033 |

## 11. Next Steps

1. Read `data/cards/relic_events.json` directly and correct `RelicEventRegistry`'s `match` ids (Section 3.2) before writing any handler code.
2. Add `scripts/autoloads/relic_event_deck.gd` and all 14 handler files (Section 3.1–3.2, Section 5); register `RelicEventDeck` as an autoload.
3. Apply the six/seven flagged required follow-up patches (Section 9) to `RulesEngine`, `CombatResolver`, `CharacterInstance`, `MatchState`, `AbilitySystem` before relying on the affected cards (Whiteout, Long Winter March, Resonance Surge, Psychic Undertow, Crystal Tide, General's War Map, and the two relic-aggregation hooks) in playtesting.
4. Write `tests/unit/test_relic_event_deck.gd`; confirm C1–C12.
5. Resolve the deck-exhaustion and "1 round" definition questions (Section 9) with the designer.
