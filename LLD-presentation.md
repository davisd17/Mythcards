# MythCards Low-Level Design — Presentation Layer (`BoardView`, `CharacterView`, `HUD`)

**Document Control**

| Field | Value |
| --- | --- |
| Source document(s) | HLD.md (v3, 2026-09-07), BRD.md (v3, 2026-08-14), LLD-content-board.md (v3), LLD-match-setup.md (v4), LLD-rules-engine.md (v6), LLD-combat-mount.md (v5), LLD-ability-system.md (v1), LLD-leveling.md (v1), LLD-relic-event-deck.md (v1), LLD-victory-checker.md (v1), LLD-debug-panel.md (v1) |
| Module/flow scope | Presentation Layer (`BoardView`, `CharacterView`, `HUD` — HLD Section 4.12). HLD build-order step 16, the last module in the HLD's own sequence. |
| Target stack | Godot 4.7.x, GDScript |
| Version | 1 |
| Date | 2026-09-08 |
| Status | Draft |
| Prepared by | Drew Davis (solo developer/designer, acting as own PM) |

## 1. Purpose & Scope

This LLD specs the player-facing rendering and input layer: the board and character views, tap-to-select/tap-to-act interaction, legal-move/attack/danger-zone highlighting, and the HUD (turn indicator, AP, relic/event panel, end-turn control, status badges). Per HLD Section 4.12, this layer is "deliberately thin: it reads `MatchState` and `EventBus` signals and requests actions through `RulesEngine` — it holds no game-rule logic itself." Unlike `DebugPanel` (LLD-09), this layer is *not* constrained to a pure-listener design — HLD explicitly says it "reads `MatchState`" directly — so it may query `GameState.match_state`/`BoardModel` freely for rendering, and specifically uses `RulesEngine.get_legal_move_tiles`/`get_legal_attack_target_ids`/`AbilitySystem.get_legal_ability_targets` (LLD-rules-engine.md v6, LLD-ability-system.md) for highlight previews rather than ever re-deriving legality itself.

**Explicitly out of scope**: any new game-rule logic — every action this layer initiates goes through `RulesEngine.request_action` unchanged; final art/animation (BRD Section 6.1 explicitly excludes this from the prototype tier; placeholder art only, per AS-005).

## 2. File Layout

```
D:\mythcards\
├── scenes/
│   ├── Board.tscn                  (new — Node2D, holds 49 Tile children generated at runtime)
│   ├── Tile.tscn                   (new — one board square, tap target + highlight overlay)
│   ├── CharacterView.tscn          (new — one per CharacterInstance)
│   └── HUD.tscn                    (new — CanvasLayer child, per HLD Section 5.2)
├── scripts/
│   └── ui/
│       ├── board_view.gd           (script on Board.tscn)
│       ├── tile_view.gd            (script on Tile.tscn)
│       ├── character_view.gd       (script on CharacterView.tscn)
│       └── hud.gd                  (script on HUD.tscn)
└── tests/
    └── unit/
        └── test_board_view.gd      (new — extends GutTest; tests input-to-action-request
                                      translation logic in isolation, not real rendering —
                                      see Section 8)
```

## 3. Class & Function Specs

### 3.1 `BoardView` (`res://scripts/ui/board_view.gd`)

```gdscript
extends Node2D

const TILE_PIXEL_SIZE := 96   # placeholder-art sizing (AS-005); mobile-first Control/anchor
                               # layout governs the HUD (Section 3.4), not raw board pixels,
                               # per BR-044 -- the board itself is drawn in Node2D world space
                               # (HLD Section 5.2's own scene-tree choice), scaled to fit the
                               # viewport by a Camera2D/container this LLD doesn't further spec
                               # (a layout-polish detail, not a rules concern)

var _tiles: Dictionary = {}          # Vector2i -> TileView node
var _selected_character_id: String = ""   # "" if nothing selected
var _highlighted_move_tiles: Array[Vector2i] = []
var _highlighted_attack_target_ids: Array[String] = []
var _pending_action_mode: String = ""   # "" | "move" | "attack" | "ability" | "mount" | "dismount"

func _ready() -> void:
    _build_tiles()   # instantiate 49 TileView children at their board positions, reading
                      # GameState.match_state.board (BoardModel) directly for is_center/terrain
                      # display (HLD Section 4.12 explicitly permits reading MatchState)
    EventBus.character_moved.connect(_on_state_changed_generic)
    EventBus.attack_resolved.connect(_on_state_changed_generic)
    EventBus.character_defeated.connect(_on_state_changed_generic)
    EventBus.character_leveled_up.connect(_on_state_changed_generic)
    EventBus.action_resolved.connect(_on_action_resolved)
    EventBus.match_ended.connect(_on_match_ended)

func _on_tile_tapped(pos: Vector2i) -> void
    # See Section 4.1 -- the core tap-input state machine.
func select_character(instance_id: String) -> void
    # See Section 4.2.
func clear_selection() -> void
    # Resets _selected_character_id, _highlighted_move_tiles, _highlighted_attack_target_ids,
    # _pending_action_mode; tells every TileView/CharacterView to clear its highlight state.
func _on_state_changed_generic(...) -> void
    # Any board-affecting signal triggers a full re-sync: for every CharacterView, read its
    # CharacterInstance's current position/HP/level/status_effects from GameState.match_state
    # and update the view (Section 4.3) -- simpler and less error-prone than hand-patching each
    # view for each specific signal's payload, at the cost of some redundant re-reads (cheap at
    # 14 characters).
func _on_action_resolved(action_type: String, actor_id: String, result: Dictionary) -> void
    # If result["success"], call clear_selection() (an action just completed -- the player's
    # next tap starts a fresh selection) and re-sync (Section 4.3). If not success, leave the
    # current selection/highlights in place (e.g. an illegal-move tap shouldn't deselect the
    # character; the player should be able to try a different tile immediately).
func _on_match_ended(winner_id: String, condition: String) -> void
    # Disables further tile taps (a simple boolean gate checked at the top of
    # _on_tile_tapped) -- HUD (Section 3.4) owns the actual victory/defeat display.
```
Satisfies HLD Section 4.12 / BRD FR-066–FR-074A.

### 3.2 `TileView` (`res://scripts/ui/tile_view.gd`)

```gdscript
extends Control   # a tappable Control even though parented under a Node2D board (HLD
                   # Section 5.2's Board (Node2D) with Tile children) -- using Control here
                   # specifically for its built-in tap/click input handling and NFR-026's
                   # tap-target-size requirement, which BoardView's own Node2D doesn't need

var position_on_board: Vector2i
var _highlight_state: String = ""   # "" | "legal_move" | "legal_attack" | "danger_zone" |
                                     # "selected" | "occupied_ally" | "occupied_enemy"

func set_highlight(state: String) -> void
    # Updates a visible overlay color/icon per NFR-024 ("important state should not be
    # communicated by color alone") -- each highlight state pairs a color with a distinct
    # icon/pattern overlay, not color alone. Exact visual choice is placeholder-art-tier
    # (AS-005) and left to implementation, not specced further here.
func _on_gui_input(event: InputEvent) -> void
    # On a tap/click release: call the parent BoardView's _on_tile_tapped(position_on_board).
```

### 3.3 `CharacterView` (`res://scripts/ui/character_view.gd`)

```gdscript
extends Node2D

var instance_id: String
var _status_badge_container: Node   # holds small icon nodes, one per active StatusEffect

func sync_from_instance(instance: CharacterInstance) -> void
    # Reads instance.position (converted to pixel coordinates via BoardView's TILE_PIXEL_SIZE
    # convention), current_hp/AbilitySystem.get_effective_max_hp(instance) (for an HP bar),
    # level (for a level badge), status_effects (Section 4.4 -- FR-074A's board-level status
    # badges), spirit_ember_count (a distinct badge, per FR-052 -- shown when > 0, with the
    # count rendered on the badge when > 1, since a mounted-pair kill grants two Embers),
    # AbilitySystem.has_quartz_armor(instance) (a passive-aura badge, LLD-ability-system.md
    # Section 5.10 -- a live predicate, not a StatusEffect, so it is read here rather than
    # found in status_effects). Called by BoardView's
    # _on_state_changed_generic (Section 3.1) for every character on every relevant signal.
func _on_gui_input(event: InputEvent) -> void
    # On a tap: call the parent BoardView.select_character(instance_id) if it belongs to the
    # active player, else (an enemy tap while something friendly is selected and in "attack"
    # mode) forward to _on_tile_tapped(instance's position) instead, since attacking targets a
    # tile/character interchangeably (Section 4.1 step 4).
```

### 3.4 `HUD` (`res://scripts/ui/hud.gd`)

```gdscript
extends Control   # Control/anchor-based per BR-044 (mobile-first from this prototype onward,
                   # not ported later from a fixed desktop layout) -- the one place in this LLD
                   # where that constraint is directly load-bearing, since HUD is exactly the
                   # kind of UI that's easy to accidentally build pixel-fixed first

var _end_turn_button: Button
var _turn_label: Label
var _pool_ap_label: Label
var _relic_panel: Control
var _character_inspect_panel: Control   # shown when a character is selected (FR-067)
var _relic_choice_dialog: Control       # shown only when RelicEventDeck has a pending
                                         # replace-or-discard choice (BR-030) -- see Section 4.5

func _ready() -> void:
    EventBus.turn_started.connect(_on_turn_started)
    EventBus.pool_ap_changed.connect(_on_pool_ap_changed)
    EventBus.character_ap_changed.connect(_on_character_ap_changed)
    EventBus.relic_drawn.connect(_on_relic_drawn)
    EventBus.relic_slot_changed.connect(_on_relic_slot_changed)
    EventBus.event_resolved.connect(_on_event_resolved)
    EventBus.match_ended.connect(_on_match_ended)
    _end_turn_button.pressed.connect(_on_end_turn_pressed)

func _on_end_turn_pressed() -> void
    RulesEngine.request_action("end_turn", GameState.match_state.active_player_id, {})
func _on_turn_started(player_id: String) -> void
    # Updates _turn_label; per FR-070, also refreshes which characters "still have action
    # points" -- delegated to BoardView's CharacterViews showing/hiding an AP-remaining badge
    # rather than duplicated here, since CharacterView already owns per-character rendering.
func _on_relic_drawn(player_id: String, card_id: String) -> void
func _on_relic_slot_changed(player_id: String, card_id: String) -> void
    # Updates _relic_panel (FR-057, FR-059C).
func _on_event_resolved(card_id: String) -> void
    # Shows a transient "event resolved: <card name>" notice (FR-059C's "currently drawn or
    # active event" display).
func show_relic_choice(player_id: String, card_id: String) -> void
    # Called when RelicEventDeck records a pending choice (Section 4.5) -- renders
    # _relic_choice_dialog (an in-game Control, never a native popup, per BR-031) with
    # "Replace"/"Discard" buttons, each calling RelicEventDeck.resolve_relic_choice() directly.
func _on_match_ended(winner_id: String, condition: String) -> void
    # Shows a victory/defeat panel distinguishing "hero_capture" from "army_defeat" text
    # (FR-064's explicit requirement).
```
Satisfies HLD Section 4.12 / BRD FR-066–FR-074A, BR-044.

## 4. Algorithms

### 4.1 Tap-input state machine (`BoardView._on_tile_tapped`)

1. If the match has ended (Section 3.1's gate) or it isn't rendering for the active player's own turn in a hotseat sense (Section 9 — this prototype has no per-device player separation, both players share one screen, so this check is really just "is the game accepting input at all," not a permission check), ignore the tap.
2. If `_selected_character_id == ""`: if the tapped tile is occupied by a character belonging to the active player, call `select_character(that instance_id)` (Section 4.2). Else, no-op (tapping an empty tile or an enemy with nothing selected does nothing — FR-073's "avoid hiding critical board state behind menus" doesn't require every empty tap to do something).
3. If `_selected_character_id != ""` and `_pending_action_mode == "move"`: if the tapped tile is in `_highlighted_move_tiles`, call `RulesEngine.request_action("move", _selected_character_id, {"to": tapped_pos})`. Else if the tap is on the already-selected character's own tile, treat it as a deselect (`clear_selection()`). Else if it's a different friendly character, re-select it (Section 4.2, replacing the prior selection — FR-066's tap-friendly selection implies re-selecting is always available, not requiring an explicit deselect first).
4. If `_pending_action_mode == "attack"`: if the tapped tile/character is in `_highlighted_attack_target_ids`, call `RulesEngine.request_action("attack", _selected_character_id, {"target_id": <that character's instance_id>})`.
5. `_pending_action_mode == "ability"`/`"mount"`/`"dismount"` follow the same shape: check the tap against the corresponding pre-computed legal-target set (Section 4.2) and call `request_action` with that action type's exact payload (LLD-rules-engine.md Sections 4.4–4.6).
6. `[NEED]` how the player *switches* `_pending_action_mode` (e.g. from "move" to "attack" for the same selected character, to attack instead of moving) is a UI-affordance detail — likely a small action-type toggle/button row shown alongside the character-inspect panel (Section 3.4) once a character is selected — not fully specced here since it's an interaction-design choice, not a rules one; flagged for a UI-design pass rather than left silently assumed.

### 4.2 `select_character`

1. `_selected_character_id = instance_id`; `_pending_action_mode = "move"` (the default mode on selection — a player most commonly moves first; switching to "attack"/"ability"/etc. is the Section 4.1 step 6 affordance).
2. `_highlighted_move_tiles = RulesEngine.get_legal_move_tiles(instance_id)` (LLD-rules-engine.md v6) — every tile in this set gets `TileView.set_highlight("legal_move")`.
3. `_highlighted_attack_target_ids = RulesEngine.get_legal_attack_target_ids(instance_id)` (same LLD) — precomputed alongside move tiles (not only when the player switches to "attack" mode) so switching modes is instant, no re-query needed; each target's `CharacterView`/underlying `TileView` gets highlighted as `"legal_attack"` once that mode is active.
4. "Danger zone" highlighting (tiles from which an *enemy* could legally attack the selected character next turn, per FR-068) is computed by calling `RulesEngine.get_legal_attack_target_ids`/`get_legal_move_tiles`-equivalent reasoning *for each enemy character*, checking whether the selected character's tile would be reachable — `[NEED]` this requires either a new `RulesEngine` query (`would_be_attackable_by(defender_id) -> bool`, not yet specced anywhere) or `BoardView` composing the existing per-character queries itself across all enemy characters (looping `GameState.match_state`'s other player's characters and calling `get_legal_attack_target_ids` for each, checking if the selected character's id appears) — the latter is achievable with existing methods and no further `RulesEngine` patch, so this LLD adopts it as the concrete approach rather than flagging a new query as required.

### 4.3 Full re-sync (`_on_state_changed_generic`)

For every `CharacterInstance` in `GameState.match_state.players[0].characters + players[1].characters`: find its `CharacterView` (keyed by `instance_id` in a `BoardView`-held dictionary, not shown above for brevity) and call `sync_from_instance(instance)`. If `_selected_character_id != ""`, also re-run Section 4.2 steps 2–3 (the selected character's own legal-move/attack sets may have changed, e.g. after an ability changed its position or AP) — cheap at 14 characters, not worth a more surgical incremental update at this scale (NFR-002's 100ms budget is trivially met).

### 4.4 Status badge rendering (`CharacterView.sync_from_instance`)

For each `StatusEffect` in `instance.status_effects`: render one small icon in `_status_badge_container`, using a fixed icon-per-`type` mapping (`"shield"` → shield icon, `"temp_atk"`/`"temp_move"`/`"temp_range"` → an up-arrow-with-stat-letter icon, `"marked"` → a target icon, `"no_mount_dismount"`/`"no_push"`/`"no_reaction"` → a small lock/prohibition icon) — satisfies FR-074A's "shield, temporary attack/movement bonus, Pounce mark" examples directly, generalized to every `StatusEffect.type` in LLD-ability-system.md Section 3.4's vocabulary rather than hardcoding only the three FR-074A happens to name.

### 4.5 Relic-choice prompt wiring

`RelicEventDeck.draw_for` (LLD-relic-event-deck.md Section 4.5) records a pending choice internally but does not itself notify the presentation layer — there is no dedicated "relic choice pending" signal in HLD's Section 5.3 map. This LLD's `HUD` bridges the gap by also listening to `relic_drawn` (Section 3.4) and, on receiving it, checking whether the drawn card's `kind == "Relic"` and the drawing player's `active_relic_id` was already non-empty *before* this draw (tracked via `HUD`'s own last-known `_active_relic` cache, mirroring the same pattern `DebugPanel` already uses, LLD-debug-panel.md Section 4.2) — if so, calls `show_relic_choice(player_id, card_id)`. `[NEED]` this is a presentation-layer inference from two existing signals rather than a clean single trigger; flagged as a candidate for a future dedicated `relic_choice_pending(player_id, card_id)` signal if this inference proves fragile in practice.

## 5. Data Structures

No new persistent data structures — this layer holds only transient UI state (`_selected_character_id`, highlight sets, dialog visibility) alongside references to the `CharacterView`/`TileView` nodes it manages. All gameplay data is read live from `GameState.match_state`/`BoardModel` or received via signal payloads.

## 6. Signal/Payload Specs

This layer emits no new `EventBus` signals — it only calls `RulesEngine.request_action` (mutating state, which then triggers the usual signals other modules already emit) and listens to the full existing HLD Section 5.3 signal set relevant to rendering (enumerated across Sections 3.1/3.4 above).

## 7. Error Handling & Edge Cases

| Scenario | Expected behavior | Source |
| --- | --- | --- |
| Player taps a tile while `request_action` is somehow still processing a prior tap (not possible in this single-threaded synchronous flow, but defended against) | `request_action` is a plain synchronous function call — there is no way for a second tap's input event to be processed mid-call in Godot's single-threaded main loop, so no lock/debounce is needed | Section 1 |
| An action fails (`result["success"] == false`) | Selection and highlights are preserved (Section 3.1's `_on_action_resolved`) so the player can immediately try a different target without re-selecting | FR-074, NFR-009 |
| A character the player has selected is defeated by some other effect before they act again (not currently possible with any card — no card damages allies — but defended against) | `_on_state_changed_generic`'s re-sync (Section 4.3) would find the character missing from `GameState.match_state`; `select_character`'s cached `_selected_character_id` should be cleared if `GameState.match_state.find_character(_selected_character_id) == null` at the start of any re-sync | NFR-020 |
| The match ends while a relic-choice dialog (Section 4.5) is open | `HUD._on_match_ended` should force-close any open dialog before showing the victory/defeat panel, rather than layering both | FR-064 |
| A tap lands exactly on the boundary between two `TileView`s (a rendering/hit-testing concern, not a rules one) | Handled by Godot's own `Control` input hit-testing (each `TileView` occupies an exclusive, non-overlapping rect) — no game-logic handling needed | Section 3.2 |

## 8. Test Plan

Unit tests use **GUT**, testing `BoardView`'s tap-to-action-request translation logic (Section 4.1) with a doubled `RulesEngine` (verifying the exact `request_action` call made for a given tap sequence) rather than real rendering or real Godot input events — this is a UI-logic module, and its correctness is "does the right `request_action` call happen for this input," not pixel-perfect rendering, which GUT/unit-testing tools aren't suited to verify anyway (that's what a manual playthrough, or Playwright once a Web export exists, is for).

| Case | Given | When | Then | BRD ID |
| --- | --- | --- | --- | --- |
| C1 | Nothing selected, tile tapped is an active-player character | `_on_tile_tapped(pos)` | `select_character` called with that character's id | FR-066 |
| C2 | Nothing selected, tile tapped is empty | `_on_tile_tapped(pos)` | No-op — no `request_action` call | Section 4.1 |
| C3 | Character selected, `_pending_action_mode == "move"`, tapped tile in `_highlighted_move_tiles` | `_on_tile_tapped(pos)` | Doubled `RulesEngine.request_action` called with `("move", <id>, {"to": pos})` | FR-021 |
| C4 | Same, but tapped tile NOT in `_highlighted_move_tiles` and isn't the selected character's own tile or another friendly | `_on_tile_tapped(pos)` | No `request_action` call | NFR-021 |
| C5 | Character selected, `_pending_action_mode == "attack"`, tapped enemy in `_highlighted_attack_target_ids` | `_on_tile_tapped(pos)` | `request_action` called with `("attack", <id>, {"target_id": ...})` | FR-022 |
| C6 | An action's `result["success"] == false` | `_on_action_resolved(...)` fires | Selection/highlights unchanged | NFR-009 |
| C7 | An action's `result["success"] == true` | `_on_action_resolved(...)` fires | `clear_selection()` called | Section 3.1 |
| C8 | `match_ended` fires | Any subsequent `_on_tile_tapped` call | No-op regardless of tap position | FR-064 |
| C9 | A character with an active `"shield"` `StatusEffect` | `CharacterView.sync_from_instance(instance)` | A shield badge is added to `_status_badge_container` | FR-074A |

## 9. Open Implementation Questions

- **`[NEED]` Action-mode switching UI (Section 4.1 step 6)** is an interaction-design detail this LLD flags rather than fully specs — needs a concrete UI affordance (buttons, a radial menu, etc.) decided during implementation, not a rules question.
- **`[NEED]` Danger-zone highlighting (Section 4.2 step 4)** is implemented by composing existing per-character queries across every enemy character rather than a new dedicated `RulesEngine` method — flagged as a design choice made here (not escalated) since it required no new contract, only composition of already-specced queries.
- **`[NEED]` Relic-choice prompt trigger (Section 4.5)** infers "a choice is pending" from two signals rather than a dedicated one — flagged as a candidate for a future signal addition if this proves unreliable.
- **This is the only LLD in the series with no `[NEED]` items requiring a patch to an earlier module** — every gap here is a UI/interaction-design decision, not a rules-engine gap, which is expected: by build step 16, every rules-affecting contract (movement, combat, abilities, leveling, deck, victory) was already nailed down by the ten LLDs before it.

## 10. Traceability

| LLD Section | HLD Section | BRD/PRD IDs |
| --- | --- | --- |
| 3.1, 4.1–4.2 Tap input | HLD 4.12 | FR-066, FR-068, FR-072, FR-074 |
| 3.2 `TileView` highlights | HLD 4.12 | FR-017, FR-018, FR-018A, NFR-024, NFR-026 |
| 3.3, 4.4 `CharacterView` | HLD 4.12 | FR-067, FR-074A, FR-052 |
| 3.4, 4.5 `HUD` | HLD 4.12, BR-044 | FR-057, FR-059A–FR-059C, FR-064, FR-069–FR-071 |

## 11. Next Steps

1. Build `Tile.tscn`/`Board.tscn`/`CharacterView.tscn`/`HUD.tscn` and their scripts (Section 3); wire `Board`/`Characters`/`UILayer` under `Match.tscn` per HLD Section 5.2.
2. Write `tests/unit/test_board_view.gd`; confirm C1–C9 with a doubled `RulesEngine`.
3. Resolve the three flagged interaction-design questions (Section 9) during implementation — none block starting the work, all are refinable once something is on screen.
4. Play a full match start-to-finish through this layer (not just `DebugPanel`) — this is the last item in HLD Section 13's own build order, closing out the digital rules prototype milestone.
