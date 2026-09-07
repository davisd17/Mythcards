# MythCards Low-Level Design — Content Loader & Board/Grid (`ContentDB`, `BoardModel`)

**Document Control**

| Field | Value |
| --- | --- |
| Source document(s) | HLD.md (v3, 2026-09-07), BRD.md (v3, resynced 2026-09-07), PRD.md (resynced 2026-09-07) |
| Module/flow scope | Content Loader (`ContentDB` — HLD Section 4.1) and Board/Grid (`BoardModel` — HLD Section 4.2). First two modules in HLD Section 13's build order (steps 4–5). |
| Target stack | Godot 4.7.x, GDScript |
| Version | 2 (reworks `BoardTile`/placed-object design from a bare `blocks_movement` flag to an id + lookup-registry pattern; adds placed objects blocking line-of-sight by default per BR-011A; adopts GUT for unit testing; flags the `sub_area` single-value migration) |
| Date | 2026-09-07 |
| Status | Draft |
| Prepared by | Drew Davis (solo developer/designer, acting as own PM) |

## 1. Purpose & Scope

This LLD specs the two foundational modules everything else in the HLD build order depends on: the data loader that turns `data/cards/*.json` into typed in-memory resources, and the board/grid module that owns the 7x7 tile state and the shared movement/line-of-sight queries every other module (Rules Engine, Combat Resolver, Ability System, Victory Checker) will call rather than re-deriving.

**Explicitly out of scope for this LLD** (covered by later LLDs, per HLD's module breakdown): `MatchState`/`PlayerState`/`CharacterInstance`/`SetupFlow` (HLD Section 4.3, HLD build-order step 6), all rule-enforcement/action-validation logic (`RulesEngine`, step 8), and combat/ability/mount/leveling behavior (steps 9–11) — including *when and how* a barricade or pylon actually gets created, repaired, or destroyed (AP cost, HP changes by level, etc.), which belongs to `AbilitySystem`. This LLD specs only the generic placed-object *data shape* and the board-level blocking queries every other module reads, not the ability logic that populates it.

Because no Godot project exists yet in this repo, Section 2 proposes a file layout rather than confirming one already in use.

## 2. File Layout

Proposed convention: the Godot project root **is** the repo root (`D:\mythcards`), so `res://data/cards/*.json` resolves directly to the files that already exist — no data duplication or a second copy inside a nested Godot-project folder.

```
D:\mythcards\                          (repo root == res://)
├── project.godot                      (new — not yet created)
├── addons/
│   └── gut/                           (new — GUT unit-test addon, vendored per its own install docs)
├── data/
│   └── cards/                         (existing, unchanged)
│       ├── characters.json
│       ├── relic_events.json
│       └── review_drafts/
│           ├── closed_city_events.json
│           └── closed_city_relics.json
├── scripts/
│   ├── autoloads/
│   │   └── content_db.gd              (autoload singleton name: ContentDB)
│   ├── data_model/
│   │   ├── game_enums.gd              (class_name GameEnums — shared const lists)
│   │   ├── character_data.gd          (class_name CharacterData)
│   │   ├── relic_event_data.gd        (class_name RelicEventData)
│   │   ├── board_tile.gd              (class_name BoardTile)
│   │   ├── placed_object_def.gd       (class_name PlacedObjectDef)
│   │   ├── placed_object_registry.gd  (class_name PlacedObjectRegistry)
│   │   └── placed_object_instance.gd  (class_name PlacedObjectInstance)
│   └── systems/
│       └── board_model.gd             (class_name BoardModel)
└── tests/
    └── unit/
        ├── test_content_db.gd         (extends GutTest)
        └── test_board_model.gd        (extends GutTest)
```

`BoardModel` is a plain `class_name`, not an autoload (per HLD Section 5.1) — it will be instantiated and owned by `GameState`/`RulesEngine` once those modules exist (a later LLD). This LLD specs the class itself, not who owns the instance.

**Autoload order note:** `ContentDB` must be first in Project Settings → Autoload's ordered list. Godot initializes autoloads' `_ready()` in listed order, and every other autoload (`TurnManager`, `RulesEngine`, `RelicEventDeck`, etc., specced in later LLDs) will assume `ContentDB`'s data is already loaded and validated by the time their own `_ready()` runs.

## 3. Class & Function Specs

### 3.1 `GameEnums` (`res://scripts/data_model/game_enums.gd`)

```gdscript
class_name GameEnums

const CHARACTER_TYPES: Array[String] = [
    "Common", "Mount", "Warrior", "Leader", "Hero", "Specialist", "Mystic"
]
const RELIC_EVENT_KINDS: Array[String] = ["Relic", "Event"]
const MOVEMENT_PATTERNS: Array[String] = ["orthogonal"]  # only pattern any of the 14 prototype cards use; see Section 9 note
const PLACED_OBJECT_TYPES: Array[String] = ["barricade", "pylon"]  # the only two object types any current card creates
```
A static-const holder, not a `Resource` — pure data other classes reference for validation (`GameEnums.CHARACTER_TYPES.has(type)`). No BRD ID of its own; it exists to keep the magic strings in `ContentDB._validate()` (3.5), `BoardModel` (3.6), and `PlacedObjectRegistry` (3.4.1) from drifting apart.

### 3.2 `CharacterData` (`res://scripts/data_model/character_data.gd`)

```gdscript
class_name CharacterData
extends Resource

var id: String = ""
var faction: String = ""       # e.g. "Russian-Inspired" — display/theming only
var culture: String = ""       # e.g. "Russian-inspired" — used for culture-scoped queries
var sub_area: String = ""      # single value going forward (see Section 9 migration note —
                                # 4 committed entries still hold "X / Y" combined text)
var char_name: String = ""     # JSON key is "name"; renamed to avoid confusion with Resource.resource_name
var type: String = ""          # one of GameEnums.CHARACTER_TYPES
var hp: int = 0
var atk: int = 0
var move: int = 0
var range: int = 0
var l1: String = ""
var l2: String = ""
var l3: String = ""
var role: String = ""
```
Populated only by `ContentDB._load_characters()` (3.5) — no other code constructs a `CharacterData`. Satisfies HLD Section 4.1 / BRD FR-080.

### 3.3 `RelicEventData` (`res://scripts/data_model/relic_event_data.gd`)

```gdscript
class_name RelicEventData
extends Resource

var id: String = ""
var faction: String = ""
var sub_area: String = ""
var card_name: String = ""     # JSON key is "name"
var kind: String = ""          # one of GameEnums.RELIC_EVENT_KINDS
var duration: String = ""      # "Persistent" | "1 round" | "1 turn" | "Immediate"
var effect: String = ""
var note: String = ""
var review_status: String = "" # "" = playable; "draft_for_review" = BR-043A draft content
var raw: Dictionary = {}       # full original JSON entry; preserved so narrative-only fields
                                # (set, set_count, narrative, asset_candidates, review_notes,
                                # narrative_links — present only on draft entries) aren't lost,
                                # even though no gameplay code reads them at this tier
```
Populated only by `ContentDB._load_relic_events()` / `_load_review_drafts()` (3.5). Satisfies HLD Section 4.1 / BRD FR-081, BR-043A.

### 3.4 `BoardTile` (`res://scripts/data_model/board_tile.gd`)

```gdscript
class_name BoardTile
extends RefCounted

var position: Vector2i
var occupant_id: String = ""   # character id, or "" if empty
var object_id: String = ""    # PlacedObjectInstance id, or "" if no object occupies this tile
var terrain_type: String = "" # e.g. "frost"; "" = none. Terrain *effects* (stop-on-entry,
                               # damage, etc.) are a future TurnManager/AbilitySystem concern —
                               # BoardModel only stores the flag, never interprets it.
var is_center: bool = false
```
A tile holds at most one of `occupant_id` (a character) or `object_id` (a placed object) at a time — never both, since both movement (FR-014) and the default deployment/placement rules already require a tile to be empty before something is placed or moved onto it. Revised from an earlier draft that modeled a placed object as a bare `blocks_movement: bool` on the tile directly — that doesn't scale once more than one object type has different characteristics (a barricade blocks movement, a pylon doesn't; both now block line-of-sight). Instead, the tile stores only an id; a tile's actual blocking/HP characteristics are looked up through `PlacedObjectInstance` → `PlacedObjectRegistry` (3.4.1–3.4.2), so a third object type is a registry entry, not a new `BoardTile` field.

`RefCounted`, not `Resource` — this is live runtime board state, not static content data. Owned exclusively by `BoardModel` (3.6); no other module mutates a `BoardTile` directly. Satisfies HLD Section 4.2 / BRD FR-011, FR-016, FR-018A, BR-011A.

### 3.4.1 `PlacedObjectDef` & `PlacedObjectRegistry` (`res://scripts/data_model/placed_object_def.gd`, `placed_object_registry.gd`)

```gdscript
class_name PlacedObjectDef
extends RefCounted

var type_id: String
var blocks_movement: bool
var blocks_line_of_sight: bool
var default_max_hp: int   # 0 = no HP tracked (indestructible at this tier)

func _init(p_type_id: String, p_blocks_movement: bool, p_blocks_line_of_sight: bool, p_default_max_hp: int) -> void:
    type_id = p_type_id
    blocks_movement = p_blocks_movement
    blocks_line_of_sight = p_blocks_line_of_sight
    default_max_hp = p_default_max_hp
```

```gdscript
class_name PlacedObjectRegistry

static func get_def(type_id: String) -> PlacedObjectDef:
    match type_id:
        "barricade":
            return PlacedObjectDef.new("barricade", true, true, 2)   # BRD Section 12: "Barricades block movement and have 2 HP"
        "pylon":
            return PlacedObjectDef.new("pylon", false, true, 0)      # no movement block or base HP stated for L1 Pylon
        _:
            push_error("PlacedObjectRegistry: unknown type_id '%s'" % type_id)
            return null
```
Every current object type blocks line-of-sight by default (BR-011A) — there is no per-type opt-out yet because no committed card grants one; adding a card that *does* grant an exception is a `PlacedObjectDef` field addition (e.g., `blocks_line_of_sight` becomes overridable per-instance), not a redesign. `default_max_hp` is a starting point only — `AbilitySystem` (a later LLD) may override it per-instance at creation time, since e.g. Crystal Architect's Level 2 upgrade text ("Pylons have 2 HP") implies HP can depend on the creating character's level, not just the object type; this registry does not attempt to model that yet (Section 9).
**Satisfies:** BRD BR-011A, FR-016, FR-036D.

### 3.4.2 `PlacedObjectInstance` (`res://scripts/data_model/placed_object_instance.gd`)

```gdscript
class_name PlacedObjectInstance
extends RefCounted

var id: String = ""              # unique instance id, e.g. "obj_3"
var type_id: String = ""         # key into PlacedObjectRegistry
var owner_player_id: String = "" # which player created it
var current_hp: int = 0          # meaningful only if PlacedObjectRegistry.get_def(type_id).default_max_hp > 0
```
Runtime state for one placed object on the board. Owned by `BoardModel` (3.6), keyed by `id` in a private dictionary; a `BoardTile.object_id` references one of these. Satisfies HLD Section 4.2 / BRD FR-016.

### 3.5 `ContentDB` (autoload, `res://scripts/autoloads/content_db.gd`)

```gdscript
extends Node
# Autoload name: ContentDB

const CHARACTERS_PATH := "res://data/cards/characters.json"
const RELIC_EVENTS_PATH := "res://data/cards/relic_events.json"
const REVIEW_DRAFTS_DIR := "res://data/cards/review_drafts/"

var characters: Dictionary = {}         # String id -> CharacterData
var relic_events: Dictionary = {}       # String id -> RelicEventData (review_status == "")
var draft_relic_events: Dictionary = {} # String id -> RelicEventData (review_status == "draft_for_review")

func _ready() -> void:
    _load_characters()
    _load_relic_events()
    _load_review_drafts()
    var errors := _validate()
    for e in errors:
        push_error("ContentDB validation: %s" % e)
    assert(errors.is_empty(), "ContentDB: %d validation error(s); see Output log" % errors.size())

func get_character(id: String) -> CharacterData
    # Returns characters.get(id, null). No fallback/default — callers must handle null
    # (an unknown id is a caller bug, not a recoverable runtime state).

func get_characters_by_culture(culture: String) -> Array[CharacterData]
    # Linear filter over characters.values() where .culture == culture (14 entries total;
    # no indexing needed at this data size — see Section 9 perf note).

func get_relic_event(id: String) -> RelicEventData
    # Returns relic_events.get(id, null) — draft-only ids are NOT found here by design
    # (BR-043A); callers needing drafts use get_draft_relic_event() explicitly.

func get_draft_relic_event(id: String) -> RelicEventData
    # Returns draft_relic_events.get(id, null).

func get_playable_relic_events_by_culture(culture: String) -> Array[RelicEventData]
    # Filter over relic_events.values() where .faction/.culture matches — this is what a
    # future RelicEventDeck (HLD Section 4.9, later LLD) calls to build each player's
    # 3-relic/4-event contribution (BR-027A).

func _load_characters() -> void
func _load_relic_events() -> void
func _load_review_drafts() -> void
    # See Section 4 for the shared parse algorithm all three follow.

func _validate() -> Array[String]
    # Returns a list of human-readable error strings; see Section 4.5 for exact checks.
```
Satisfies HLD Section 4.1 / BRD FR-080, FR-081, FR-082, FR-082A, FR-082B, NFR-016, NFR-017, NFR-019, BR-043A.

### 3.6 `BoardModel` (`res://scripts/systems/board_model.gd`)

```gdscript
class_name BoardModel
extends RefCounted

const BOARD_SIZE := 7
const CENTER_TILE := Vector2i(3, 3)
const PLAYER_A_EDGE_ROW := 0   # coordinate convention decided in this LLD — see Section 9
const PLAYER_B_EDGE_ROW := 6

var _tiles: Array[BoardTile] = []           # size 49; index = y * BOARD_SIZE + x
var _objects: Dictionary = {}               # String object_id -> PlacedObjectInstance
var _next_object_id: int = 0                # simple monotonic counter for object_id generation

func _init() -> void
    # Allocates 49 BoardTile entries at their (x, y) positions; sets is_center = true
    # only on CENTER_TILE.

func is_in_bounds(pos: Vector2i) -> bool
func get_tile(pos: Vector2i) -> BoardTile
    # Returns null if pos is out of bounds — callers must check is_in_bounds() first or
    # handle null; get_tile() never auto-clamps.

func is_occupied_by_character(pos: Vector2i) -> bool
    # get_tile(pos).occupant_id != "".

func get_placed_object(pos: Vector2i) -> PlacedObjectInstance
    # Returns _objects.get(get_tile(pos).object_id, null); null if the tile has no object.

func is_blocked_for_movement(pos: Vector2i) -> bool
    # True if is_occupied_by_character(pos), OR the tile has an object whose
    # PlacedObjectRegistry def has blocks_movement == true. Used by get_legal_moves().

func blocks_line_of_sight(pos: Vector2i) -> bool
    # True if is_occupied_by_character(pos), OR the tile has an object whose
    # PlacedObjectRegistry def has blocks_line_of_sight == true (BR-011A — true for every
    # object type currently registered). Used by has_line_of_sight().

func set_occupant(pos: Vector2i, character_id: String) -> void
func clear_occupant(pos: Vector2i) -> void

func place_object(pos: Vector2i, type_id: String, owner_player_id: String) -> String
    # Creates a PlacedObjectInstance (id = "obj_%d" % _next_object_id, incrementing the
    # counter), current_hp = PlacedObjectRegistry.get_def(type_id).default_max_hp, stores it
    # in _objects, sets get_tile(pos).object_id, and returns the new id. Asserts the target
    # tile is empty (no occupant_id and no existing object_id) — this function does not
    # decide *whether* placing an object here is a legal AP-ability action (that's
    # AbilitySystem's job); it only enforces the tile-level invariant that a tile can't hold
    # two things at once.

func remove_object(pos: Vector2i) -> void
    # Erases the object_id from _objects and clears it from the tile. No-op if the tile has
    # no object.

func get_edge_row(player_side: int) -> int
    # player_side: 1 -> PLAYER_A_EDGE_ROW, 2 -> PLAYER_B_EDGE_ROW. Asserts on any other value.

func is_center(pos: Vector2i) -> bool
    # pos == CENTER_TILE.

func get_legal_moves(from: Vector2i, move_budget: int, pattern: String = "orthogonal",
        passable_predicate: Callable = Callable()) -> Array[Vector2i]
    # See Section 4.1 for the exact BFS algorithm. `passable_predicate`, if supplied, is
    # `func(pos: Vector2i) -> bool` — true means "may move through this occupied tile but
    # not stop on it" (models Vault/Glide-style abilities per BR-010; BoardModel has no
    # knowledge of which ability this is, only the yes/no the caller supplies). Applies only
    # to character-occupied tiles, not object-blocked ones — no current ability passes
    # through placed objects (Section 4.1, step 4c).

func has_line_of_sight(from: Vector2i, to: Vector2i, ignore_ids: Array[String] = []) -> bool
    # See Section 4.2. Returns false immediately if from/to don't share a row or column
    # (out of the default orthogonal-line attack pattern, BR-009) — callers are expected to
    # have already confirmed `to` is a valid ranged target before asking about line of sight.
    # `ignore_ids` applies to character occupants only (e.g. Link Mind's ally exception);
    # no current card grants a placed-object LOS exception, so there is no equivalent
    # ignore-list for object_ids yet (Section 9).

func get_tiles_in_range(origin: Vector2i, range: int, pattern: String = "orthogonal_line") -> Array[Vector2i]
    # See Section 4.3. Purely geometric — does NOT apply line-of-sight blocking; callers
    # filter the result through has_line_of_sight() per candidate tile.
```
Satisfies HLD Section 4.2 / BRD FR-010–FR-018A, BR-008, BR-009, BR-010, BR-011, BR-011A, FR-036D.

## 4. Algorithms

### 4.1 `get_legal_moves` (BFS)

1. If `pattern != "orthogonal"`, `push_error` and return `[]` — no other pattern is implemented yet (Section 9 note; BR-010 patterns are added per-card later without changing this signature).
2. `directions := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]`.
3. `visited := {from: 0}`, `frontier := [from]`, `result := []`.
4. While `frontier` is not empty:
   a. Pop `current` from `frontier`; `cost := visited[current]`.
   b. If `cost >= move_budget`, continue to the next frontier item (don't expand further from a tile at the budget's edge).
   c. For each `dir` in `directions`:
      - `next := current + dir`.
      - If `not is_in_bounds(next)`, skip.
      - If `next` in `visited` with a cost `<= cost + 1`, skip (already reached at least as cheaply).
      - If `is_occupied_by_character(next)` (a character, not an object):
        - If `passable_predicate.is_valid() and passable_predicate.call(next)`: mark `visited[next] = cost + 1`, add `next` to `frontier` (may continue through), **do not** add `next` to `result` (cannot stop here — BR-010/FR-014).
        - Else: dead end — do not visit further in this direction.
      - Elif `get_placed_object(next) != null and PlacedObjectRegistry.get_def(get_placed_object(next).type_id).blocks_movement`: dead end — no ability in the current 14-card roster passes through placed objects, so there is no predicate override for this case yet (unlike the character case above).
      - Else (empty, or an object present whose def has `blocks_movement == false`, e.g. a pylon): mark `visited[next] = cost + 1`, add to both `frontier` and `result` (a valid stop — a non-blocking object doesn't prevent standing on its tile, since no current card says otherwise).
5. Return `result` (already deduplicated by the `visited` cost-gate).

### 4.2 `has_line_of_sight`

1. If `from == to`, return `true` (degenerate case; callers should not call this with identical tiles, but it's not an error).
2. If `from.x != to.x and from.y != to.y`, return `false` (not on a shared row/column — outside the default orthogonal-line pattern, BR-009).
3. `step := Vector2i(sign(to.x - from.x), sign(to.y - from.y))`.
4. `cursor := from + step`.
5. While `cursor != to`:
   a. If `is_occupied_by_character(cursor) and cursor's occupant_id not in ignore_ids`: return `false` (BR-011).
   b. Elif `get_placed_object(cursor) != null and PlacedObjectRegistry.get_def(get_placed_object(cursor).type_id).blocks_line_of_sight`: return `false` (BR-011A — placed objects block line-of-sight by default; there is no ignore-list parameter for object ids because no current card needs one).
   c. `cursor += step`.
6. Return `true`.

This supersedes an earlier draft of this algorithm that deliberately excluded placed objects from line-of-sight blocking — that reading is reversed as of BR-011A (2026-09-07): objects now block line-of-sight by default, the same as characters, unless a specific card/object states otherwise.

### 4.3 `get_tiles_in_range` (orthogonal line, 4 rays)

1. `result := []`.
2. For each `dir` in `[Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]`:
   a. `cursor := origin`.
   b. For `step in range(1, range + 1)`:
      - `cursor += dir`.
      - If `not is_in_bounds(cursor)`, break (stop this ray at the board edge).
      - Append `cursor` to `result`.
3. Return `result`. (Line-of-sight is **not** applied here — see the function's own doc comment in Section 3.6.)

### 4.4 `ContentDB._load_characters` / `_load_relic_events` / `_load_review_drafts` (shared parse shape)

1. `var file := FileAccess.open(path, FileAccess.READ)`; if `file == null`, `push_error` with `FileAccess.get_open_error()` and return (fail loud — a missing content file is a build-config bug, not a recoverable state).
2. `var text := file.get_as_text()`.
3. `var parsed = JSON.parse_string(text)`; if not a valid `Array`, `push_error` and return.
4. For each `entry: Dictionary` in `parsed`:
   - Character entries: build a `CharacterData`, mapping `entry["stats"][0..3]` to `hp, atk, move, range` in that fixed order (matches the BRD Section 12 column order — HP, ATK, MOVE, RANGE — and is confirmed against every current entry's known stat line, e.g. Gymnast `[2,1,3,1]` → HP2/ATK1/MOVE3/RANGE1). `char_name = entry.get("name", "")`. Store at `characters[data.id] = data`.
   - Relic/event entries: build a `RelicEventData`, `card_name = entry.get("name", "")`, `review_status = entry.get("review_status", "")`, `raw = entry`. For `_load_relic_events` (main file), store into `relic_events`. For `_load_review_drafts`, force `review_status = "draft_for_review"` regardless of the source value, and if the source value was present but different, `push_error` (a draft file with an unexpected status is a content-authoring mistake worth surfacing, not silently overriding) — then store into `draft_relic_events`.
5. `_load_review_drafts` additionally lists every `*.json` file under `REVIEW_DRAFTS_DIR` via `DirAccess.open(REVIEW_DRAFTS_DIR).get_files()` rather than hardcoding `closed_city_events.json`/`closed_city_relics.json` by name — a future additional draft set (a different sub-area) needs no `ContentDB` code change, only a new file in that directory (BR-043A's own intent).

### 4.5 `ContentDB._validate`

Returns an `Array[String]` of error messages; checks performed (all findings collected, not fail-fast on the first):
1. No duplicate `id` across `characters` and, separately, across `relic_events` (drafts checked separately from playable — a draft may reuse an id pattern from a different set without conflict, but not within the same map).
2. Every `CharacterData.type` is in `GameEnums.CHARACTER_TYPES`.
3. Every `RelicEventData.kind` (both `relic_events` and `draft_relic_events`) is in `GameEnums.RELIC_EVENT_KINDS`.
4. Every character's source `stats` array had exactly 4 numeric entries (checked during `_load_characters`, reported here).
5. Per BR-005: for each distinct `culture` value present in `characters`, exactly one `CharacterData` exists for each of the 7 `GameEnums.CHARACTER_TYPES` — no more, no fewer.
6. Every `CharacterData.sub_area` contains no `" / "` separator (single value only). **This check will fail against the currently-committed `characters.json`** until the four dual-tagged entries are migrated (Section 9) — that's intentional: it surfaces the gap rather than silently accepting it. Do not relax this check; fix the data instead (see Next Steps, item 0).

## 5. Data Structures

Covered inline in Section 3 (field-level types are the spec; no additional shapes beyond `CharacterData`, `RelicEventData`, `BoardTile`, `PlacedObjectDef`, `PlacedObjectInstance`, and the plain `Dictionary`/`Array` collections in `ContentDB`/`BoardModel`).

## 6. Signal/Payload Specs

Neither module emits or listens to `EventBus` signals. `ContentDB` finishes all loading synchronously in `_ready()`, before any other autoload's `_ready()` runs (Section 2's autoload-order note) — there is nothing to signal because nothing consumes it asynchronously. `BoardModel` is a plain class with no autoload lifecycle at all; the future owner that instantiates it (`RulesEngine`/`GameState`, a later LLD) is responsible for emitting movement/combat signals *after* calling into `BoardModel` — `BoardModel` itself stays a pure query/mutation surface. This includes `place_object`/`remove_object`: they mutate board state silently; `AbilitySystem` (a later LLD) emits whatever signal is appropriate (e.g., a future `object_placed`) *after* calling them, the same pattern already used for movement/combat.

## 7. Error Handling & Edge Cases

| Scenario | Expected behavior | Source |
| --- | --- | --- |
| `characters.json` or `relic_events.json` missing/unreadable at boot | `push_error` with the `FileAccess` error code; loading aborts for that file (empty map) rather than crashing silently | Section 4.4 |
| A character/relic-event JSON entry has an unrecognized `type`/`kind` | Loaded as-is (fields kept verbatim), but flagged by `_validate()` and surfaced via `push_error` + `assert` at boot | NFR-019 |
| A culture is missing one of the 7 character types, or has a duplicate | `_validate()` reports it; `assert` halts a debug build rather than silently allowing an incomplete squad to reach `SetupFlow` | BR-005 |
| A character's `sub_area` still contains a `" / "` combined value | `_validate()` reports it (Section 4.5, check 6) — expected to fail today; resolved once the content migration (Section 9) lands | Section 9 |
| A draft file's own `review_status` isn't `"draft_for_review"` | Loader overrides it to `"draft_for_review"` for safety and `push_error`s the mismatch, rather than trusting a possibly-stale content-authoring field | BR-043A |
| `get_legal_moves()` called with `move_budget <= 0` | Returns `[]` immediately (the BFS loop's budget check prevents any expansion) — not an error, just no legal moves | FR-012 |
| `get_legal_moves()`/`has_line_of_sight()`/`get_tiles_in_range()` called with a `from`/`origin` that is itself out of bounds | Undefined by this LLD — callers (a later `RulesEngine` LLD) are responsible for only ever passing a character's actual, already-valid board position | Flagged, not solved, here |
| `has_line_of_sight(from, to)` where `from` and `to` are not on a shared row/column | Returns `false` (Section 4.2, step 2) rather than asserting — callers filtering `get_tiles_in_range()` results will never hit this case, but a defensive caller passing an arbitrary pair gets a safe answer, not a crash | BR-009 |
| `place_object()` called on a tile that already has an occupant or object | Asserts (programmer error — `AbilitySystem` must check emptiness itself before calling, the same way `RulesEngine` is expected to for character movement) | Section 3.6 |
| `PlacedObjectRegistry.get_def()` called with an unregistered `type_id` | `push_error`, returns `null` — callers must handle `null` (an unknown type is a caller bug, not runtime state) | Section 3.4.1 |
| Two characters occupy the same tile (should never happen if `RulesEngine` is correct) | `BoardModel` does not defend against this — `set_occupant()` simply overwrites `occupant_id`. This is a deliberate non-goal: enforcing "no double occupancy" is `RulesEngine`'s validation responsibility, not `BoardModel`'s (see Anti-Patterns in the `lld-writer` skill re: not widening a module's responsibility) | — |

## 8. Test Plan

Unit tests use **GUT** (decided 2026-09-07 — see HLD Section 4.13). Cases below map to `tests/unit/test_content_db.gd` (C1–C6) and `tests/unit/test_board_model.gd` (C7–C16), each a `GutTest`-extending script with one `test_*` method per case.

FR-082, FR-082A, FR-082B, NFR-016, and NFR-017 (future cultures/sub-areas, draft-content tracking, data/logic separation) are satisfied structurally rather than by a dedicated test: `ContentDB` never enumerates cultures or sub-areas in code (only `GameEnums.CHARACTER_TYPES`, which BRD itself fixes at exactly 7 — cultures are just whatever `culture` values appear in the data). C1/C2 already exercise this indirectly by querying the real committed data through the same culture-scoped path a third culture would use.

| Case | Given | When | Then | BRD ID |
| --- | --- | --- | --- | --- |
| C1 | `characters.json` as currently committed (14 entries) | `ContentDB._ready()` runs | `characters.size() == 14`; `get_character("r-gymnast").hp == 2` | FR-080 |
| C2 | Same | — | `get_characters_by_culture("Russian-inspired").size() == 7`, one of each `GameEnums.CHARACTER_TYPES` | BR-005 |
| C3 | A fixture culture missing its Hero entry | `_validate()` runs | Returns a non-empty error list mentioning the missing type | BR-005 |
| C4 | `relic_events.json` as committed (14 entries, no `review_status` key) | `ContentDB._ready()` runs | Every entry's `review_status == ""`; `get_relic_event()` finds all 14 | FR-081 |
| C5 | `review_drafts/closed_city_events.json` (8 entries) + `closed_city_relics.json` (6 entries), all `review_status: "draft_for_review"` | `ContentDB._ready()` runs | `draft_relic_events.size() == 14`; none of those 14 ids appear in `get_playable_relic_events_by_culture()` results | BR-043A |
| C6 | A fixture with two entries sharing the same `id` | `_validate()` runs | Returns an error naming the duplicate id | NFR-019 |
| C6a | `characters.json` as currently committed (pre-migration: 4 entries still hold a combined `"X / Y"` `sub_area`) | `_validate()` runs | Returns 4 errors, one per affected character id (expected to fail until Section 9's migration lands — this case documents the current, known-failing state, not a bug) | Section 9 |
| C7 | Empty 7x7 board, character at `(3,3)`, `move=2`, `pattern="orthogonal"` | `get_legal_moves()` called | Result is exactly the 12 tiles reachable by ≤2 orthogonal steps (no diagonals) | BR-008 |
| C8 | Ally occupying `(3,4)`, character at `(3,3)`, `move=2`, no predicate | `get_legal_moves()` called | `(3,4)` and `(3,5)` both absent from result (dead end at the occupied tile) | FR-014 |
| C9 | Same as C8, but with a `passable_predicate` returning `true` for `(3,4)` | `get_legal_moves()` called | `(3,4)` absent (can't stop), `(3,5)` present (reachable by passing through) | FR-015 |
| C10 | Enemy at `(3,4)`, attacker at `(3,3)`, target at `(3,5)` | `has_line_of_sight((3,3), (3,5))` called | Returns `false` | BR-011 |
| C11 | Same as C10 | `has_line_of_sight((3,3), (3,5), ["enemy_id"])` called | Returns `true` | BR-011 (card-specific exception path) |
| C12 | Empty board, `origin=(3,3)`, `range=2` | `get_tiles_in_range()` called | Result is exactly 8 tiles (2 per orthogonal direction) | FR-029 (consumer requirement — this function is the query it relies on) |
| C13 | `origin=(0,0)`, `range=3` | `get_tiles_in_range()` called | Result contains no out-of-bounds coordinates | FR-013 |
| C14 | A barricade placed at `(3,4)` (`place_object`), no character present, attacker at `(3,3)`, target at `(3,5)` | `has_line_of_sight((3,3), (3,5))` called | Returns `false` | BR-011A |
| C15 | A pylon placed at `(3,4)`, character at `(3,3)`, `move=2`, no predicate | `get_legal_moves()` called | `(3,4)` present in result (pylon doesn't block movement) but `has_line_of_sight((3,3),(3,5))` still returns `false` (pylon does block LOS) | BR-011A, FR-016 |
| C16 | Empty tile at `(3,4)` | `place_object((3,4), "barricade", "p1")` called, then `place_object((3,4), "pylon", "p2")` called again on the same tile | Second call asserts (tile already occupied by an object) | Section 7 |

## 9. Open Implementation Questions

- **`sub_area` single-value migration (content dependency, not code).** Per 2026-09-07 direction, every character will have exactly one `sub_area` going forward. Four committed `characters.json` entries currently hold a combined value: `r-hero` (Bogatyr Champion, `"Winter Front / Far North"`), `r-engineer` (Winter Engineer, `"Winter Front / Far North"`), `a-attendant` (Quartz Attendant, `"First Mind / Crystal Dominion"`), `a-harmonic` (Astral Harmonic, `"First Mind / Crystal Dominion"`). Picking which single sub-area each keeps is a content/narrative decision for the designer, not made in this LLD — `_validate()`'s new check (4.5.6) is written to fail against the current data specifically so this isn't silently dropped. See Next Steps, item 0.
- **Movement pattern extensibility.** `GameEnums.MOVEMENT_PATTERNS` currently lists only `"orthogonal"` because no prototype card needs anything else (BR-010's diagonal/jump/teleport exceptions are all specific to cards not yet built in `AbilitySystem`). `get_legal_moves()`'s `pattern` parameter exists now so adding a second pattern later is a new `match` branch in Section 4.1, not a signature change — but no second pattern is implemented yet, by design (YAGNI).
- **Board orientation convention (new decision made at this LLD tier, not previously specified).** Neither the BRD nor the HLD assigns a physical row to either player — deployment (BR-007A) only requires "each player's own back row," and leveling (BR-022) only requires "the opponent's edge," both of which are symmetric regardless of which row is which. This LLD fixes `PLAYER_A_EDGE_ROW := 0` and `PLAYER_B_EDGE_ROW := 6` purely as an internal coordinate convention with no gameplay effect — it does not change any rule, so it's decided here rather than escalated to an `hld-writer`/`brd-writer` patch. If that assumption is wrong (some future rule *does* care which physical side is which), that would be a real gameplay decision belonging in the BRD/PRD, not a fix to this LLD.
- **Placed-object registry is code, not data.** Unlike characters and relic/events, `PlacedObjectRegistry` (3.4.1) is a hardcoded `match` in GDScript rather than a JSON file, because only two object types exist and neither is player-selectable content the way cards are. Worth revisiting if a future sub-area introduces enough object types that hand-editing GDScript for balance changes becomes the kind of friction `NFR-017` (easy rebalancing) is meant to avoid.
- **Per-level HP variation on placed objects (e.g., Crystal Architect's Level 2 "Pylons have 2 HP") is not modeled by `PlacedObjectDef.default_max_hp`.** `AbilitySystem` (a later LLD) will need to pass an explicit HP value into a variant of `place_object()` (or override `current_hp` after creation) rather than relying on the registry default — flagged here so that LLD doesn't have to rediscover the gap.
- **No object-id equivalent to `ignore_ids` for line-of-sight exceptions.** `has_line_of_sight()`'s `ignore_ids` parameter (Section 3.6) only ever applies to character occupants (modeling Link Mind's exception). No current card grants a placed-object LOS exception, so this LLD doesn't add a parallel mechanism for objects — if one is ever needed, it's an additive parameter, not a redesign.

## 10. Traceability

| LLD Section | HLD Section | BRD/PRD IDs |
| --- | --- | --- |
| 3.2–3.3 Data classes | HLD 4.1, 5.4 | FR-080, FR-081, BR-043A |
| 3.4 `BoardTile` | HLD 4.2, 6 | FR-011, FR-016, FR-018A, BR-011A |
| 3.4.1–3.4.2 Placed-object classes | HLD 4.2 | BR-011A, FR-016, FR-036D |
| 3.5 `ContentDB` | HLD 4.1 | FR-080, FR-081, FR-082, FR-082A, FR-082B, NFR-016, NFR-017, NFR-019 |
| 3.6 `BoardModel` | HLD 4.2, 6 | FR-010–FR-018A, BR-008, BR-009, BR-010, BR-011, BR-011A, FR-036D |
| 4.1 `get_legal_moves` | HLD Flow (implicit, movement) | BR-008, BR-010, FR-012, FR-014, FR-015 |
| 4.2 `has_line_of_sight` | HLD Flow B (attack resolution) | BR-011, BR-011A, FR-036C, FR-036D |
| 4.3 `get_tiles_in_range` | HLD Flow B | FR-029 |
| 4.5 `_validate` | HLD 4.1 | NFR-019, BR-005 |

## 11. Next Steps

0. **Content dependency, not code:** update `characters.json` — `r-hero`, `r-engineer`, `a-attendant`, `a-harmonic` — to a single `sub_area` value each (designer decision; see Section 9). `_validate()`'s check 4.5.6 is expected to fail until this lands.
1. Create `project.godot` at the repo root; register `ContentDB` as the first autoload. Install the GUT addon under `addons/gut/`.
2. Add `scripts/data_model/game_enums.gd`, `character_data.gd`, `relic_event_data.gd`, `board_tile.gd`, `placed_object_def.gd`, `placed_object_registry.gd`, `placed_object_instance.gd` (Section 3.1–3.4.2).
3. Implement `ContentDB` (Section 3.5, Section 4.4–4.5); write `tests/unit/test_content_db.gd` and confirm C1–C6a (Section 8) pass (C6a will fail until step 0 lands — expected).
4. Implement `BoardModel` (Section 3.6, Section 4.1–4.3); write `tests/unit/test_board_model.gd` and confirm C7–C16.
5. Stand up the Web export preset (HLD Section 13, step 3) against this minimal state if not already done, to catch any export-target incompatibility (HLD-R-007) before the next LLD (`MatchState`/`SetupFlow`, HLD build-order step 6) adds more surface area.
