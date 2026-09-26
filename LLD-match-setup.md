# MythCards Low-Level Design — Match State, Setup & Turn Management (`MatchState`, `SetupFlow`, `GameState`, `TurnManager`)

**Document Control**

| Field | Value |
| --- | --- |
| Source document(s) | HLD.md (v3, 2026-09-07), BRD.md (v3, 2026-08-14), LLD-content-board.md (v2, 2026-09-07) |
| Module/flow scope | Match Setup (`SetupFlow` — HLD Section 4.3), plus the `MatchState`/`PlayerState`/`CharacterInstance`/`StatusEffect` data model (HLD Section 6) and the `GameState`/`TurnManager` autoloads (HLD Section 5.1). HLD build-order steps 6–7. |
| Target stack | Godot 4.7.x, GDScript |
| Version | 5 (v2/v3 added `CharacterInstance` ability-usage/stat-bonus fields; v4 adds `PlayerState.player_flags_this_turn` and `temp_range`; v5 — designer review 2026-09-25: the 2-AP opening pool now belongs to the match's first turn only, `MatchState.first_player_id` added ahead of a coin flip, `has_spirit_ember` becomes `spirit_ember_count`, `"next_turn"` `expires` value plus the first real status-effect clearing pass, `get_effective_range(context)`, `get_effective_move()` floor stated, and an `instance_id` minting rule for characters created after setup) |
| Date | 2026-09-25 |
| Status | Draft |
| Prepared by | Drew Davis (solo developer/designer, acting as own PM) |

## 1. Purpose & Scope

This LLD specs the runtime state root everything downstream mutates (`MatchState` and its nested `PlayerState`/`CharacterInstance`/`StatusEffect` shapes), the setup flow that builds that state from culture selection and player-chosen back-row deployment (BR-007A), and the two autoloads (`GameState`, `TurnManager`) that hold that state and drive turn alternation with AP refresh.

**Explicitly out of scope for this LLD** (covered by later LLDs, per HLD's module breakdown): all action validation/execution (`RulesEngine`, LLD-03), combat and mount/dismount behavior (`CombatResolver`/`MountSystem`, LLD-04), ability execution (`AbilitySystem`, LLD-05), leveling/Spirit Ember detection (`LevelingSystem`, LLD-06), relic/event deck construction and draw (`RelicEventDeck`, LLD-07), and the Hero-capture/army-defeat checks (`VictoryChecker`, LLD-08). This LLD defines the data those modules operate on and the turn scaffolding they hook into, not the rules those modules enforce.

This LLD depends on `ContentDB` and `BoardModel` (LLD-content-board.md), both already specced and buildable independently.

## 2. File Layout

Extends the layout established in LLD-content-board.md (Section 2):

```
D:\mythcards\
├── scripts/
│   ├── autoloads/
│   │   ├── content_db.gd          (existing)
│   │   ├── game_state.gd          (new — autoload name: GameState)
│   │   └── turn_manager.gd        (new — autoload name: TurnManager)
│   ├── data_model/
│   │   ├── game_enums.gd          (existing — extended, Section 3.1)
│   │   ├── status_effect.gd       (new — class_name StatusEffect)
│   │   ├── character_instance.gd  (new — class_name CharacterInstance)
│   │   ├── player_state.gd        (new — class_name PlayerState)
│   │   └── match_state.gd         (new — class_name MatchState)
│   └── scenes/
│       └── setup_flow.gd          (new — script attached to SetupFlow.tscn, HLD Section 5.2)
└── tests/
    └── unit/
        ├── test_setup_flow.gd     (new — extends GutTest)
        └── test_turn_manager.gd   (new — extends GutTest)
```

`SetupFlow` lives under `scripts/scenes/` rather than `scripts/systems/` because it is a scene-attached script (`SetupFlow.tscn`, HLD Section 5.2), not a plain `class_name` instantiated by another system — it directly drives UI-adjacent flow (culture pick, tap-to-place) even though this LLD specs only its state-mutation surface, not its visuals (HLD Section 4.12 owns rendering).

## 3. Class & Function Specs

### 3.1 `GameEnums` extension (`res://scripts/data_model/game_enums.gd`)

```gdscript
# Additions to the existing GameEnums (LLD-content-board.md Section 3.1)
const MATCH_PHASES: Array[String] = ["setup", "in_progress", "ended"]
const WIN_CONDITIONS: Array[String] = ["", "hero_capture", "army_defeat"]
```
Extending the existing shared-const holder rather than introducing a second enum source, per that LLD's own stated purpose (Section 3.1: "keep the magic strings ... from drifting apart").

### 3.2 `StatusEffect` (`res://scripts/data_model/status_effect.gd`)

```gdscript
class_name StatusEffect
extends RefCounted

var type: String = ""       # "shield" | "temp_atk" | "temp_move" | "pounce_mark" | "slow" |
                             # "marked" | "no_mount_dismount" | "no_reaction" -- see Section 9
var value: int = 0          # meaning depends on type (e.g. shield: damage prevention remaining;
                             # temp_atk/temp_move: stat delta); 0 for flag-only types (e.g. slow)
var expires: String = ""    # "immediate" | "this_turn" | "this_round" | "next_turn"
                             # "next_turn" (added 2026-09-25, designer-approved): the effect is
                             # in force throughout the HOLDER's own next turn and is removed at
                             # the start of the turn after that -- the duration Frost Seer's
                             # Chill and Deep Freeze actually need ("on its next turn"), which
                             # "this_turn" (clears too early, before the target has even acted)
                             # and "this_round" (ambiguous) could not express. See Section 4.3.
var applied_on_turn: int = -1  # MatchState.turn_number when this effect was applied. Written by
                                # whoever applies the effect; read by the "this_round" clearing
                                # rule (Section 4.3).
var ticks: int = 0             # how many of the holder's own turn-starts this effect has
                                # survived. Used only by "next_turn" two-phase clearing.
var source_character_id: String = ""  # instance_id of whoever applied it, for debug/attribution only
```
Populated and consumed only by `AbilitySystem`/`CombatResolver` (later LLDs) and `LevelingSystem`'s own status reads; this LLD defines only the shape, per HLD Section 6. Satisfies HLD Section 6 (generic-enough status representation), supporting FR-074A (status badges).

### 3.3 `CharacterInstance` (`res://scripts/data_model/character_instance.gd`)

```gdscript
class_name CharacterInstance
extends RefCounted

var instance_id: String = ""     # unique per match: "%s_%s" % [player_id, data.id] -- see Section 9
                                  # (data.id alone is not match-unique in a same-culture mirror match)
var data: CharacterData = null   # static content ref (LLD-content-board.md Section 3.2)
var player_id: String = ""       # "p1" | "p2" -- owning player
var current_hp: int = 0
var base_max_hp: int = 0         # starts at data.hp; permanent Level 2/3 upgrades that flatly
                                  # raise max HP (e.g. Last Oath's +2) add here. Deliberately
                                  # separate from any *conditional* positional/aura HP bonus
                                  # (e.g. Stand Firm/Heroic Guard's "+1 while on/adjacent to
                                  # center") -- those are computed live by AbilitySystem
                                  # (LLD-ability-system.md), never baked into this field, so a
                                  # character's effective max HP is always
                                  # base_max_hp + AbilitySystem.get_conditional_max_hp_bonus(...)
var level: int = 1               # 1-3 (FR-046, FR-050)
var position: Vector2i = Vector2i(-1, -1)  # sentinel "not yet placed" until SetupFlow places it
var character_ap_remaining: int = 0
var character_ap_max: int = 1    # BR-019 default; some effects raise it (FR-025) -- not modeled
                                  # by any prototype card yet, but the field exists per HLD Section 6
var status_effects: Array[StatusEffect] = []
var spirit_ember_count: int = 0  # number of Spirit Embers this character is carrying (BR-023A).
                                  # An int, not a bool, since 2026-09-25: defeating a mounted
                                  # pair defeats two characters and grants two Embers. Level 3
                                  # delivery spends one (LLD-leveling.md Section 4.2).
var mounted_with_id: String = "" # instance_id of the other half of a mounted pair, "" if unmounted
var is_mounted_rider: bool = false
var ability_uses_this_turn: Dictionary = {}   # String effect_tag -> int count; cleared every
                                               # start_turn for this character (Section 3.8 patch
                                               # below). Added for AbilitySystem's once-per-turn
                                               # limits (FR-043) -- see LLD-ability-system.md.
var ability_uses_this_match: Dictionary = {}  # same shape, never cleared mid-match (once-per-
                                               # match limits, e.g. Oracle Sovereign's L3)
var atk_bonus: int = 0    # permanent flat ATK granted by a level-up (BR-026); written once by
                           # AbilitySystem.apply_level_up_effects() (LLD-ability-system.md) at
                           # the moment LevelingSystem processes a level change -- never mutated
                           # elsewhere. Excludes temporary per-turn bonuses (see get_effective_atk).
var move_bonus: int = 0   # same pattern, for MOVE (e.g. Gymnast's L2 +1 MOVE)
var range_bonus: int = 0  # same pattern, for RANGE (e.g. Sniper's L2 +1 RANGE)

func get_effective_atk() -> int
    # data.atk + atk_bonus + sum(se.value for se in status_effects where se.type == "temp_atk").
    # The single place ATK is ever read for combat/ability math -- callers (CombatResolver,
    # AbilitySystem) never read data.atk directly. Pure function of this instance's own fields;
    # needs no board/match_state access.

func get_effective_move() -> int
    # max(0, data.move + move_bonus + sum(se.value for se in status_effects where
    # se.type == "temp_move")). The floor at 0 is explicit (v5): a stacked slow can push the
    # raw sum negative (Frost Seer's Deep Freeze applies a large negative temp_move to express
    # "cannot move next turn", LLD-ability-system.md Section 5.7), and a negative MOVE has no
    # meaning for BoardModel's BFS. Used only for an UNMOUNTED character's own movement -- a
    # mounted rider's movement instead uses MountSystem.get_effective_move_stat()
    # (LLD-combat-mount.md), which reads the Mount's own get_effective_move() in turn (BR-014)
    # rather than the rider's.

func get_effective_range(context: String) -> int
    # context: "attack" | "ability" -- which kind of range is being resolved. Returns
    # max(1, data.range + range_bonus + sum(se.value for se in status_effects where se.type ==
    # "temp_range") + AbilitySystem.get_conditional_range_bonus(self, context) +
    # MatchState.global_range_modifier). (v4: a "temp_range" StatusEffect type was added for
    # relic/event-granted RANGE bonuses -- e.g. Crystal Tide, General's War Map -- see
    # LLD-relic-event-deck.md. v5, 2026-09-25: the context argument was added so an ability-only
    # or attack-only bonus can be expressed -- Crystal Architect's Pylon at L1 boosts ability
    # range only, Sniper's Aim boosts attack range only, Link Mind grants the Conductor's range
    # for abilities only. Callers pass what they are resolving: RulesEngine._handle_attack
    # passes "attack", _handle_ability passes "ability". The floor at 1 matches the Whiteout
    # event's own "minimum 1" wording, BRD Section 13.2.)
```
Constructed only by `SetupFlow._build_squad()` (Section 3.6). No other code constructs a `CharacterInstance`. Satisfies HLD Section 6; traces to FR-011 (position), FR-028 (HP/level/AP), FR-046–FR-052 (leveling fields), FR-045B–FR-045H (mount fields), FR-074A (status_effects).

### 3.4 `PlayerState` (`res://scripts/data_model/player_state.gd`)

```gdscript
class_name PlayerState
extends RefCounted

var id: String = ""                  # "p1" | "p2"
var culture: String = ""             # e.g. "Russian-inspired" -- set at culture selection
var characters: Array[CharacterInstance] = []  # exactly 7 once SetupFlow completes (BR-005)
var active_relic_id: String = ""     # RelicEventData id, "" if no active relic (BR-029) --
                                      # mutated only by RelicEventDeck (LLD-07)
var pool_ap_remaining: int = 0
var pool_ap_max: int = 0             # 2 or 4 -- set each start_turn (Section 3.8). 2 applies to
                                      # the match's FIRST turn only, i.e. only to whichever player
                                      # goes first; every other turn, including the second
                                      # player's opening turn, is 4 (BR-018, designer ruling
                                      # 2026-09-25 -- the reduced pool exists purely to offset
                                      # going first, so only the player who goes first pays it)
var player_flags_this_turn: Dictionary = {}   # String tag -> bool/int; cleared every start_turn
                                               # (Section 3.8 patch below). Holds relic/event
                                               # bonuses that belong to the player as a whole
                                               # rather than one character (e.g. Long Winter
                                               # March's "first movement action this turn gains
                                               # +1 MOVE" -- no specific character is the target
                                               # until whichever one actually moves first) --
                                               # see LLD-relic-event-deck.md.
```
Constructed only by `SetupFlow.select_culture()` (Section 3.6). Satisfies HLD Section 6; traces to FR-001 (culture), BR-018/BR-019 (AP fields), BR-029 (active relic).

### 3.5 `MatchState` (`res://scripts/data_model/match_state.gd`)

```gdscript
class_name MatchState
extends RefCounted

var players: Array[PlayerState] = []   # exactly 2, index 0 = "p1", index 1 = "p2"
var board: BoardModel = null           # composition, not a duplicated Array[BoardTile] --
                                        # see Section 9 note reconciling this with HLD Section 6's
                                        # literal "board: Array[BoardTile] (49)" phrasing
var turn_number: int = 0               # increments once per individual turn taken, not per round
                                        # (p1's turn 1 = 1, p2's turn 1 = 2, p1's turn 2 = 3, ...)
var active_player_id: String = ""
var first_player_id: String = ""       # who took the match's first turn. Fixed to "p1" today
                                        # (SetupFlow.start_match); a coin flip will set it later
                                        # (Section 9). Recorded rather than inferred so the
                                        # 2-AP opening turn, match logs, and a future coin-flip
                                        # UI all read the same field.
var next_instance_serial: int = 1      # monotonic counter minting unique instance_ids for
                                        # characters created AFTER setup (copies -- Section 9)
var shared_deck: Array[String] = []    # RelicEventData ids, remaining draw order -- construction
                                        # and shuffling owned by RelicEventDeck (LLD-07); this LLD
                                        # only reserves the field per HLD Section 6
var deck_seed: int = 0                 # reserved per HLD Section 9 (networked-PvP seam); not
                                        # consumed by any module this LLD specs
var phase: String = ""                 # one of GameEnums.MATCH_PHASES
var winner_id: String = ""             # "" until match_ended; set by VictoryChecker (LLD-08)
var win_condition: String = ""         # one of GameEnums.WIN_CONDITIONS

func get_player(player_id: String) -> PlayerState
    # Linear search over players (2 entries -- no indexing needed). Returns null if not found;
    # callers passing an id that isn't "p1"/"p2" have a bug, not a recoverable state.

func get_other_player_id(player_id: String) -> String
    # "p2" if player_id == "p1", else "p1". Asserts on any other input.

func find_character(instance_id: String) -> CharacterInstance
    # Searches both players' characters arrays (14 entries total -- no indexing needed at this
    # data size, matching ContentDB's own linear-filter precedent). Returns null if not found.

func mint_instance_id(player_id: String, data_id: String) -> String
    # "%s_%s#%d" % [player_id, data_id, next_instance_serial], then next_instance_serial += 1.
    # Used ONLY for characters created after the setup phase (copies -- Section 9). Setup-phase
    # characters keep the plain "%s_%s" form, which is guaranteed unique by BR-005A.
```
Held exclusively by the `GameState` autoload (Section 3.7). Satisfies HLD Section 6; traces to FR-060–FR-065 (winner/win_condition), BR-018 (turn_number/active_player_id).

### 3.6 `SetupFlow` (`res://scripts/scenes/setup_flow.gd`)

```gdscript
extends Node
# Attached to SetupFlow.tscn (HLD Section 5.2)

var _pending_players: Dictionary = {}  # String player_id -> PlayerState, in-progress during setup

func select_culture(player_id: String, culture: String) -> void
    # Creates a PlayerState (Section 3.4) with id=player_id, culture=culture, and calls
    # _build_squad() (below) to populate its 7 CharacterInstances. Asserts culture exists in
    # ContentDB (i.e. ContentDB.get_characters_by_culture(culture).size() == 7) -- an unknown
    # culture is a caller/UI bug, not a recoverable runtime state. Stores into _pending_players.
    # Nothing prevents both players selecting the same culture (a mirror match) -- BR-005 is
    # enforced per-side independently and neither BRD nor HLD forbids this combination.

func _build_squad(player_id: String, culture: String) -> Array[CharacterInstance]
    # For each CharacterData in ContentDB.get_characters_by_culture(culture) (7 entries,
    # pre-validated one-per-type by ContentDB._validate check 5): construct a CharacterInstance
    # with instance_id = "%s_%s" % [player_id, data.id], data=data, player_id=player_id,
    # current_hp=data.hp, base_max_hp=data.hp, level=1, position=Vector2i(-1,-1) (unplaced
    # sentinel), character_ap_max=1, character_ap_remaining=1, status_effects=[],
    # spirit_ember_count=0, mounted_with_id="", is_mounted_rider=false,
    # ability_uses_this_turn={}, ability_uses_this_match={}.

func place_character(player_id: String, instance_id: String, pos: Vector2i) -> bool
    # See Section 4.1 for the exact validation algorithm. Returns true and mutates state
    # (CharacterInstance.position, BoardModel.set_occupant) on success; returns false and
    # mutates nothing on failure (caller/UI is responsible for surfacing why via a separate
    # query, get_placement_error() below, rather than this function throwing).

func get_placement_error(player_id: String, instance_id: String, pos: Vector2i) -> String
    # Re-runs the same checks as place_character() but returns a human-readable reason string
    # ("" if the placement would succeed) instead of mutating anything -- lets the UI show a
    # rejection reason before the player commits the tap.

func is_player_ready(player_id: String) -> bool
    # True iff all 7 of that player's CharacterInstances have position != Vector2i(-1, -1).

func start_match() -> void
    # Preconditions: is_player_ready() true for both "p1" and "p2" (asserts otherwise -- the UI
    # must not offer a "start match" control until both are ready). Builds the MatchState
    # (Section 3.5): players = [_pending_players["p1"], _pending_players["p2"]], board = a new
    # BoardModel with set_occupant() already called for all 14 placed characters (done
    # incrementally by place_character(), not redone here), turn_number = 0, phase = "setup"
    # transitioning to "in_progress", winner_id/win_condition left at their defaults. Calls
    # GameState.start_match(state), then RelicEventDeck.build_deck(p1_culture, p2_culture,
    # randi()) (forward reference -- LLD-relic-event-deck.md; populates shared_deck/deck_seed
    # on the just-started MatchState per BR-027A), then sets first_player_id = "p1" and calls
    # TurnManager.start_turn(first_player_id). "p1" always goes first today; a coin flip is the
    # planned replacement (BR-018A) and will do nothing but write a different value into
    # first_player_id before this call -- see Section 9.
```
Satisfies HLD Section 4.3 / BRD FR-001–FR-009A, BR-001–BR-007B.

### 3.7 `GameState` (autoload, `res://scripts/autoloads/game_state.gd`)

```gdscript
extends Node
# Autoload name: GameState

var match_state: MatchState = null   # null before SetupFlow.start_match() runs

func start_match(state: MatchState) -> void
    match_state = state
    match_state.phase = "in_progress"

func is_match_active() -> bool
    return match_state != null and match_state.phase == "in_progress"
```
Single source of truth per HLD Section 5.1. No validation logic of its own — a pure holder, matching the same "thin" precedent set by `ContentDB` being the sole owner of static content. Satisfies HLD Section 5.1, Section 8 (state management).

### 3.8 `TurnManager` (autoload, `res://scripts/autoloads/turn_manager.gd`)

```gdscript
extends Node
# Autoload name: TurnManager

func start_turn(player_id: String) -> void
    var player := GameState.match_state.get_player(player_id)
    # BR-018 (designer ruling 2026-09-25): the 2-AP pool applies to the match's FIRST turn only.
    # turn_number is still 0 at this point on that one turn (it is incremented at the end of
    # this function), so this single check both identifies the first turn and guarantees only
    # the first player ever gets it -- the second player's opening turn is turn_number 1 and
    # gets the normal 4.
    player.pool_ap_max = 2 if GameState.match_state.turn_number == 0 else 4
    player.pool_ap_remaining = player.pool_ap_max
    for character in player.characters:
        character.character_ap_remaining = character.character_ap_max
        character.ability_uses_this_turn.clear()  # FR-043 once-per-turn limits reset here;
                                                    # ability_uses_this_match is never cleared
        _clear_expired_status_effects(character)  # v5 -- two-phase "next_turn" clearing, below
    player.player_flags_this_turn.clear()  # v4 addition -- see PlayerState, Section 3.4
    GameState.match_state.active_player_id = player_id
    GameState.match_state.turn_number += 1
    RelicEventDeck.draw_for(player_id)  # forward reference -- LLD-07; see Section 9
    EventBus.turn_started.emit(player_id)
    EventBus.pool_ap_changed.emit(player_id, player.pool_ap_remaining)

func _clear_expired_status_effects(character: CharacterInstance) -> void
    # See Section 4.3. Runs at the start of the owning player's turn, for each of that player's
    # characters, before any action can be taken.

func end_turn(player_id: String) -> void
    # See Section 4.2 for the exact sequencing rationale (why VictoryChecker runs before the
    # active player flips).
    VictoryChecker.check_hero_capture(player_id)  # forward reference -- LLD-08; see Section 9
    if GameState.match_state.phase == "ended":
        return  # the capture check ended the match; no further turn processing (HLD Flow C)
    EventBus.turn_ended.emit(player_id)
    var next_player_id := GameState.match_state.get_other_player_id(player_id)
    start_turn(next_player_id)
```
`TurnManager` owns AP *refresh* only (BR-018, BR-019) — AP *spending* during an action is `RulesEngine`'s responsibility (LLD-03), which mutates `PlayerState.pool_ap_remaining`/`CharacterInstance.character_ap_remaining` directly and emits its own `pool_ap_changed`/`character_ap_changed`. No end-of-turn effect hook is implemented here (HLD Flow A step 3 mentions one) because no prototype card currently needs one — see Section 9. Satisfies HLD Section 4.3 (turn handoff)/Section 5.1/Flow A; traces to FR-019, FR-020, FR-020A, BR-018, BR-019, BR-021.

## 4. Algorithms

### 4.1 `SetupFlow.place_character` validation

1. If `player_id` not in `_pending_players`, return `false` (culture not yet selected — caller bug).
2. Find the `CharacterInstance` with `instance_id` among that player's characters; if not found, return `false`.
3. If that instance's `position != Vector2i(-1, -1)` already (already placed), return `false` — a placement is a one-time action per character during setup, not a move (moving happens via `RulesEngine` once the match starts).
4. Determine `player_side` (1 for `"p1"`, 2 for `"p2"`) and call `board.get_edge_row(player_side)` (LLD-content-board.md Section 3.6). If `pos.y != that row`, return `false` (BR-007A — placement restricted to the player's own back row).
5. If `not board.is_in_bounds(pos)`, return `false`.
6. If `board.is_occupied_by_character(pos)` or `board.get_placed_object(pos) != null`, return `false` — tile already occupied (setup-time placement, not an ability, so there's never a placed object yet at this stage, but the check costs nothing and defends against future setup-flow reordering).
7. All checks pass: set `character.position = pos`, call `board.set_occupant(pos, instance_id)`, return `true`.

`get_placement_error()` runs the same six checks but returns the specific failure reason as a string instead of a boolean, so the UI can tell a player *why* a tap was rejected (e.g., "outside your back row" vs. "tile occupied").

### 4.2 `TurnManager.end_turn` sequencing

`VictoryChecker.check_hero_capture(player_id)` must run **before** `turn_ended` fires and **before** the active player flips, because BR-034 defines the check as happening "at the end of a turn taken by that Hero's own controller" — i.e., against the player who *just acted*, using board state exactly as it stood at the moment their turn ends (HLD Flow C, HLD-R-002). Running it after flipping `active_player_id` would check the wrong player's Hero. If the check ends the match (`GameState.match_state.phase` set to `"ended"` by `VictoryChecker`), `end_turn` returns immediately without emitting `turn_ended` or starting the next turn — per HLD Flow C step 2, "no further end-of-turn processing occurs."

### 4.3 `_clear_expired_status_effects` (two-phase `"next_turn"` clearing)

Called from `start_turn` for every character belonging to the player whose turn is starting, before that player may act. For each `se` in `character.status_effects`:

| `se.expires` | Action at this character's owner's `start_turn` |
| --- | --- |
| `"immediate"` | Already removed by whoever applied it — if one is still present, remove it (defensive; an `"immediate"` effect should never persist past its own resolution). |
| `"this_turn"` | Remove. It was applied during a turn that has now ended. |
| `"this_round"` | Remove if `GameState.match_state.turn_number - se.applied_on_turn >= 2` (a "round" is both players having taken one turn — LLD-relic-event-deck.md Section 4.2 uses the same two-turn reading). |
| `"next_turn"` | **Two-phase, counted rather than computed.** If `se.ticks == 0`, set `se.ticks = 1` and keep the effect — this is the holder's own next turn, the one the card text means. If `se.ticks >= 1`, remove it. Because this function only ever runs on the holder's owner's turn start, one tick is exactly one owned turn spent under the effect, regardless of when in the turn order it was applied (an enemy applying it on their own turn and a self-buff applied on the holder's turn both behave correctly). |

This is the mechanism approved on 2026-09-25 for LLD-ability-system.md Section 5.7's flagged gap. Two properties matter and are worth asserting in tests: a `"next_turn"` effect applied by an enemy on the holder's *opponent's* turn is still active when the holder actually gets to act, and it is gone before the holder's following turn.

This function is also the first place *any* `expires` value is honored — v1–v4 of this LLD reserved the field and left clearing to "whoever applies it," which in practice meant nothing cleared `"this_turn"`/`"this_round"` effects at all. Fixing the `"next_turn"` case surfaced that gap, so all four values are now handled in one place.

## 5. Data Structures

Covered inline in Section 3. No additional shapes beyond `StatusEffect`, `CharacterInstance`, `PlayerState`, `MatchState`, and the `GameEnums` extension.

## 6. Signal/Payload Specs

| Signal | Emitted by | Payload | Notes |
| --- | --- | --- | --- |
| `turn_started(player_id: String)` | `TurnManager.start_turn` | player id | Matches HLD Section 5.3 exactly. |
| `turn_ended(player_id: String)` | `TurnManager.end_turn` | player id | Only emitted if the match did not just end (Section 4.2). |
| `pool_ap_changed(player_id: String, remaining: int)` | `TurnManager.start_turn` (refresh) and `RulesEngine` (spend, LLD-03) | player id, int | This LLD only covers the refresh-time emission. |

`SetupFlow` emits no `EventBus` signals — per HLD's signal map (Section 5.3), no setup-phase signal is defined, and the presentation layer (a later LLD) is expected to poll `SetupFlow`'s query methods (`is_player_ready`, `get_placement_error`) directly rather than listen for events, since setup is a strictly synchronous, single-player-at-a-time UI flow with no concurrent state changes to broadcast.

## 7. Error Handling & Edge Cases

| Scenario | Expected behavior | Source |
| --- | --- | --- |
| `select_culture()` called twice for the same `player_id` | Overwrites the previous `PlayerState` and rebuilds the squad from scratch — treated as "the player changed their mind before placing," not an error, since no placement work is lost if it happens before any `place_character()` call for that player | Section 3.6 |
| `place_character()` called for a tile outside the player's own back row | Returns `false` (Section 4.1, step 4); `get_placement_error()` reports "outside your back row" | BR-007A |
| `place_character()` called for an already-occupied tile | Returns `false` (Section 4.1, step 6) | Section 4.1 |
| `place_character()` called for an instance already placed | Returns `false` (Section 4.1, step 3) — re-placing requires a separate "undo placement" affordance, not modeled by this LLD (Section 9) | Section 4.1 |
| `start_match()` called while either player has fewer than 7 characters placed | Asserts (programmer/UI error — the "start match" control must be gated by `is_player_ready()` for both players before it's ever shown) | Section 3.6 |
| A player's back-row placement leaves a character with zero legal moves (e.g., boxed-in Hero) | Not blocked by this LLD — `SetupFlow` does not call `BoardModel.get_legal_moves()` during placement. HLD-R-003/BRD R-012 flag this as a UX nicety, not a rules requirement; deferred to Section 9 | HLD-R-003 |
| `TurnManager.end_turn` called for a player who is not `GameState.match_state.active_player_id` | Undefined by this LLD — callers (`RulesEngine`'s end-turn action handling, LLD-03) are responsible for only ever calling this for the actual active player | Flagged, not solved, here |
| `MatchState.get_player`/`find_character` called with an id that doesn't exist | Returns `null`; callers must handle it (a caller bug, not recoverable runtime state), consistent with `ContentDB.get_character`'s precedent | Section 3.5 |

## 8. Test Plan

Unit tests use **GUT** (HLD Section 4.13). Cases map to `tests/unit/test_setup_flow.gd` (C1–C7) and `tests/unit/test_turn_manager.gd` (C8–C13).

| Case | Given | When | Then | BRD ID |
| --- | --- | --- | --- | --- |
| C1 | A fresh `SetupFlow` | `select_culture("p1", "Russian-inspired")` called | `_pending_players["p1"].characters.size() == 7`, one of each `GameEnums.CHARACTER_TYPES` | FR-001, FR-003 |
| C2 | Both players' cultures selected | `place_character("p1", "p1_r-hero", Vector2i(3, 0))` called (row 0 = P1's back row) | Returns `true`; `board.is_occupied_by_character(Vector2i(3,0))` is `true` | BR-007A |
| C3 | Same setup | `place_character("p1", "p1_r-hero", Vector2i(3, 3))` called (center tile, not P1's back row) | Returns `false`; `get_placement_error(...)` is non-empty | BR-007A |
| C4 | A tile already holding a placed P1 character | `place_character("p1", <different instance_id>, <same tile>)` called | Returns `false` | Section 4.1 |
| C5 | P1 has placed 6 of 7 characters | `is_player_ready("p1")` called | Returns `false` | BR-007 |
| C6 | Both players have placed all 7 characters | `is_player_ready("p1")` and `is_player_ready("p2")` called | Both return `true` | BR-007 |
| C7 | Both players ready | `start_match()` called | `GameState.match_state != null`, `phase == "in_progress"`, `active_player_id == "p1"`, `turn_number == 1` | FR-007, FR-009 |
| C8 | A fresh match (`turn_number == 0`), P1 goes first | `TurnManager.start_turn("p1")` called | `pool_ap_remaining == 2`; every P1 character's `character_ap_remaining == character_ap_max` | BR-018, BR-019 |
| C8A | Immediately after C8, P1 ends their turn | `TurnManager.start_turn("p2")` runs (`turn_number == 1`) | P2's `pool_ap_remaining == 4` — the reduced pool belongs to the first turn of the match, not to each player's own first turn | BR-018 |
| C8B | P1's second turn (`turn_number == 2`) | `TurnManager.start_turn("p1")` | `pool_ap_remaining == 4` | BR-018 |
| C8C | A character carries a `"next_turn"` effect applied on turn 3 (the opponent's turn); its owner's turns are 4 and 6 | `start_turn` runs for turn 4, then turn 6 | Effect still present during turn 4 (the turn it is meant to affect); removed at the start of turn 6 | Section 4.3 |
| C9 | P1 has already taken one turn | `TurnManager.start_turn("p1")` called again | `pool_ap_remaining == 4` | BR-018 |
| C10 | Active player is P1, match not ending | `TurnManager.end_turn("p1")` called | `active_player_id == "p2"`; `turn_number` incremented by 1 (via the nested `start_turn` call) | FR-019 |
| C11 | Same as C10 | — | `turn_started` signal fired for `"p2"` (GUT signal-watch) | FR-019 |
| C12 | `start_turn` called | — | `pool_ap_changed` signal fired with the correct `remaining` value | FR-020 |
| C13 | A GUT double/stub for `VictoryChecker.check_hero_capture` that sets `phase = "ended"` | `TurnManager.end_turn("p1")` called | `turn_ended` signal NOT fired; `active_player_id` remains `"p1"` (no flip) | HLD Flow C, HLD-R-002 |

## 9. Open Implementation Questions

- **(v2/v3 patch notes)** `CharacterInstance.base_max_hp`, `ability_uses_this_turn`/`ability_uses_this_match`, and `atk_bonus`/`move_bonus`/`range_bonus` (plus their `get_effective_*` accessors) were all added while writing LLD-ability-system.md (LLD-05) — this LLD only reserves the fields, the per-turn reset point, and the accessor methods; LLD-05 owns the logic that decides *how much* bonus each character's level-ups grant and *when* once-per-turn/match limits gate an effect. Conditional/positional bonuses (e.g. Bogatyr Champion's "+1 HP while on/adjacent to center") are deliberately NOT modeled as instance fields — they're computed live by `AbilitySystem.get_conditional_max_hp_bonus()` (LLD-05) since they fluctuate on every move, not just at a discrete level-up moment. `RulesEngine`/`CombatResolver` were themselves patched (LLD-rules-engine.md v3, LLD-combat-mount.md v2) to read `get_effective_atk()`/`get_effective_move()`/`get_effective_range()` instead of raw `CharacterData` fields once these existed.

- **BR-018's "first turn" — resolved 2026-09-25: global, not per-player.** Only the player who takes the match's *first turn overall* gets the 2-AP pool; the second player's opening turn is a normal 4 AP. The reduced pool exists for exactly one purpose — to pay for the advantage of moving first (BR-021) — so giving it to the player who *doesn't* move first would tax the disadvantaged side. Implemented as a single `turn_number == 0` check in `start_turn` (Section 3.8); `PlayerState.has_taken_first_turn` is removed, since it encoded the per-player reading and now has no other reader.
- **Who takes the match's first turn — `"p1"` for now, a coin flip later (BR-018A).** `SetupFlow.start_match` writes `MatchState.first_player_id = "p1"` and starts that player's turn. The designer's stated intent (2026-09-25) is to replace this with a coin flip; the field exists now precisely so that change touches one assignment and nothing else — the AP rule keys off `turn_number`, and match logs/debug UI read `first_player_id` rather than assuming `"p1"`. A coin flip will also want to be seeded for replay (`MatchState.deck_seed` already sets that precedent, HLD Section 9).
- **`instance_id` uniqueness — resolved 2026-09-25, in two parts.** (a) *During setup*, a player can never field two copies of the same character (BR-005A), so `"%s_%s" % [player_id, data.id]` is unique by construction; the opposing player fielding the *same* character is fine and always was, because the `player_id` prefix disambiguates it — a mirror match produces `"p1_a-guard"` and `"p2_a-guard"`, not a collision. (b) *After setup*, copies of a character may be created (designer direction, 2026-09-25 — a future card or mode may duplicate a character mid-match), which the setup-time scheme cannot express. Any character created after the setup phase must therefore take its id from `MatchState.mint_instance_id()` (Section 3.5), which appends a monotonic serial: `"p1_a-guard#7"`. No current card creates a copy, so nothing calls it yet — but the minting function and the `next_instance_serial` field exist now so the first card that does has a correct id scheme to use instead of inventing one, and so no code anywhere is allowed to assume `instance_id` can be re-derived from `player_id + data.id`. Two consequences to respect: never parse an `instance_id` to recover a character's `data.id` (read `instance.data.id`), and never use an `instance_id` as a dictionary key that outlives the match.
- **`MatchState.board` as a `BoardModel` reference, not a literal `Array[BoardTile]`.** HLD Section 6 describes `MatchState.board` as `Array[BoardTile] (49)`; LLD-content-board.md already established `BoardModel` as the sole owner of tile state, to be "instantiated and owned by `GameState`/`RulesEngine`" (that LLD's Section 2). This LLD resolves that forward reference by making `MatchState.board` hold the `BoardModel` instance itself rather than a duplicated raw tile array — avoiding two sources of truth for the same 49 tiles. This is a type-level pin-down of an HLD field description, not a new architectural decision (no module boundary or signal shape changes).
- **No end-of-turn effect hook is implemented in `TurnManager.end_turn`.** HLD Flow A step 3 mentions "end-of-turn effects resolve" between the capture check and `turn_ended`. No current prototype card needs one (checked against Section 12/13's full card and relic/event text) — adding the hook now would be speculative. If a future card needs one, it's an additive step in `end_turn`, not a restructure.
- **`RelicEventDeck.draw_for(player_id)` and `VictoryChecker.check_hero_capture(player_id)` are forward references** to autoloads specced in LLD-07 and LLD-08 respectively. Per HLD Section 13 step 2, all autoloads are scaffolded as empty singletons before any module's real logic is built — this LLD's Next Steps (below) calls out that those two stub singletons need a no-op placeholder method matching these exact signatures from the start, so `TurnManager` doesn't crash calling into a not-yet-implemented module.
- **Setup-time immobility warning (HLD-R-003/BRD R-012)** — a UX nicety, not modeled here. If added later, it would be an additional (non-mutating) query on `SetupFlow`, not a change to `place_character`'s validation.

## 10. Traceability

| LLD Section | HLD Section | BRD/PRD IDs |
| --- | --- | --- |
| 3.2 `StatusEffect` | HLD 6 | FR-074A |
| 3.3 `CharacterInstance` | HLD 4.3, 6 | FR-011, FR-028, FR-046–FR-052, FR-045B–FR-045H |
| 3.4 `PlayerState` | HLD 4.3, 6 | FR-001, BR-018, BR-019, BR-029 |
| 3.5 `MatchState` | HLD 6 | FR-060–FR-065, BR-018 |
| 3.6 `SetupFlow` | HLD 4.3 | FR-001–FR-009A, BR-001–BR-007B |
| 3.7 `GameState` | HLD 5.1, 8 | — (infrastructure) |
| 3.8 `TurnManager` | HLD 4.3, 5.1, Flow A | FR-019, FR-020, FR-020A, BR-018, BR-019, BR-021 |
| 4.2 End-turn sequencing | HLD Flow C, HLD-R-002 | BR-034 |

## 11. Next Steps

1. Add `scripts/data_model/status_effect.gd`, `character_instance.gd`, `player_state.gd`, `match_state.gd` (Section 3.2–3.5); extend `game_enums.gd` (Section 3.1).
2. Register `GameState` and `TurnManager` as autoloads (Project Settings), after `ContentDB` in load order. Add placeholder no-op `check_hero_capture(player_id)` (on the `VictoryChecker` stub) and `draw_for(player_id)` (on the `RelicEventDeck` stub) so `TurnManager` has something to call against before LLD-07/LLD-08 land.
3. Implement `SetupFlow` (Section 3.6, Section 4.1); write `tests/unit/test_setup_flow.gd`, confirm C1–C7.
4. Implement `TurnManager` (Section 3.8); write `tests/unit/test_turn_manager.gd`, confirm C8–C13 (C13 requires a GUT double for `VictoryChecker`).
5. Resolve the BR-018 "first turn" open question (Section 9) with the designer before relying on the per-player interpretation in playtesting.
