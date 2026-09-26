# MythCards Low-Level Design — Export & Test Harness (`TestBridge`)

**Document Control**

| Field | Value |
| --- | --- |
| Source document(s) | HLD.md (v3, 2026-09-07), BRD.md (v3, 2026-08-14), LLD-match-setup.md (v4), LLD-rules-engine.md (v5), LLD-combat-mount.md (v5), LLD-ability-system.md (v1), LLD-relic-event-deck.md (v1), LLD-victory-checker.md (v1) |
| Module/flow scope | Export & Test Harness (`TestBridge` — HLD Section 4.13). HLD build-order step 15. This is the module Playwright actually drives, once a Web export exists. |
| Target stack | Godot 4.7.x, GDScript, `JavaScriptBridge` (Web export only) |
| Version | 1 |
| Date | 2026-09-08 |
| Status | Draft |
| Prepared by | Drew Davis (solo developer/designer, acting as own PM) |

## 1. Purpose & Scope

This LLD specs `mythcards_get_state()` and `mythcards_dispatch_action()` — the two JS-callable hooks HLD Section 4.13 defines so Playwright can read exact match state and drive a full match deterministically through `RulesEngine`'s real validation path, without simulating canvas taps. This LLD's job is the **exact JSON schema** both hooks use and the **exact serialization/deserialization algorithm** — the precise `JavaScriptBridge` API call shapes (`create_callback`/`get_interface`/etc.) remain the `[NEED]` HLD Section 4.13 already flagged ("confirm the exact call shape against the Godot 4.7 docs at implementation time... API has been stable since 4.0 but exact signatures should be verified, not assumed from memory") — this LLD does not re-attempt to resolve that from memory either, since doing so risks presenting a guessed API shape as decided.

**Explicitly out of scope**: the Web export preset's build settings themselves (a Godot project-configuration task, not a code module); any Playwright-side test code (that lives in the separate Playwright project, not this repo, though Section 8's schema is exactly the contract that code will assert against).

## 2. File Layout

```
D:\mythcards\
├── scripts/
│   └── autoloads/
│       └── test_bridge.gd         (new — autoload name: TestBridge)
└── tests/
    └── unit/
        └── test_test_bridge.gd    (new — extends GutTest; tests serialization/deserialization
                                     logic directly, NOT the actual JavaScriptBridge calls,
                                     since GUT runs inside the editor/headless Godot, not a
                                     browser — see Section 8)
```

## 3. Class & Function Specs

### 3.1 `TestBridge` (autoload, `res://scripts/autoloads/test_bridge.gd`)

```gdscript
extends Node
# Autoload name: TestBridge

const FEATURE_TAG := "mythcards_testbridge"
# A custom Godot export feature tag (Project Settings -> Export -> the Web preset's Custom
# Features field) added ONLY to a development/testing Web export preset -- deliberately
# distinct from Godot's built-in "web" tag, so a future separate "web production/store" export
# preset can be Web without ever including this bridge (HLD-R-008). Checking a custom tag
# rather than OS.has_feature("web") is what makes that future distinction possible at all.

func _ready() -> void:
    if not OS.has_feature(FEATURE_TAG):
        return   # inert on every export target except the one preset carrying this tag --
                 # never registers JS callbacks, never touches JavaScriptBridge
    _register_js_callbacks()

func _register_js_callbacks() -> void:
    # [NEED: verify against Godot 4.7 JavaScriptBridge docs at implementation time -- HLD
    # Section 4.13's own flagged gap, carried forward unresolved rather than guessed]. Expected
    # shape: use JavaScriptBridge.create_callback() to bind _js_get_state/_js_dispatch_action
    # as callables reachable from JS as window.mythcards_get_state()/
    # window.mythcards_dispatch_action(json_string).

func _js_get_state(_args: Array) -> String:
    return JSON.stringify(serialize_state())

func _js_dispatch_action(args: Array) -> String:
    return JSON.stringify(dispatch_action(args[0]))

func serialize_state() -> Dictionary
    # Pure, testable (no JavaScriptBridge dependency) -- see Section 4.1 for the exact schema.
    # Callable directly by GUT tests without needing a browser.

func dispatch_action(action_json: String) -> Dictionary
    # Pure, testable -- see Section 4.2. Parses action_json, converts JSON-safe payload values
    # (e.g. {"x":3,"y":1} back to Vector2i) into what RulesEngine.request_action() expects,
    # calls it, and returns its result Dictionary (itself JSON-safe already, per Section 4.2
    # step 4's own conversion on the way out).
```
Satisfies HLD Section 4.13 / BRD FR-090A, NFR-031A.

## 4. Algorithms

### 4.1 `serialize_state` — exact JSON schema

```
{
  "phase": String,                  // one of GameEnums.MATCH_PHASES
  "turn_number": int,
  "active_player_id": String,
  "winner_id": String,              // "" if match not yet ended
  "win_condition": String,          // "" | "hero_capture" | "army_defeat"
  "players": {
    "p1": { ...PlayerBlock },
    "p2": { ...PlayerBlock }
  }
}

PlayerBlock = {
  "culture": String,
  "pool_ap_remaining": int,
  "pool_ap_max": int,
  "active_relic_id": String,        // "" if none
  "characters": [ ...CharacterBlock, ... ]   // exactly 7
}

CharacterBlock = {
  "instance_id": String,
  "character_id": String,           // CharacterInstance.data.id
  "type": String,                   // CharacterData.type
  "position": {"x": int, "y": int}, // Vector2i has no native JSON representation --
                                     // always serialized as this fixed two-key object,
                                     // both directions (Section 4.2 mirrors this on the way in)
  "current_hp": int,
  "level": int,
  "character_ap_remaining": int,
  "spirit_ember_count": int,
  "mounted_with_id": String,        // "" if not mounted
  "is_mounted_rider": bool,
  "status_effects": [
    {"type": String, "value": int, "expires": String, "source_character_id": String}, ...
  ]
}
```
Built by iterating `GameState.match_state.players` and, per player, `player.characters` — a direct, un-cached read of live state (unlike `DebugPanel`, `TestBridge` has no "pure listener" constraint from HLD; it exists specifically to expose ground truth, so reading `GameState`/`MatchState`/`CharacterInstance` directly is exactly its job, not an exception to anything).

### 4.2 `dispatch_action` — request/response schema

**Input** (`action_json`, matching `RulesEngine.request_action`'s three parameters exactly, LLD-rules-engine.md Section 3.1):
```
{
  "action_type": String,   // one of RulesEngine.ACTION_TYPES
  "actor_id": String,
  "payload": { ... }        // action-specific; any Vector2i-shaped field (e.g. "to") is
                             // supplied as {"x": int, "y": int} and converted per step 2
}
```
1. `var parsed: Dictionary = JSON.parse_string(action_json)`; if parsing fails (`null` result) or required keys are missing, return `{"success": false, "reason": "malformed action JSON"}` without calling `RulesEngine` at all.
2. Walk `parsed["payload"]` and convert any value shaped like `{"x": <int>, "y": <int>}` (exactly two keys, both integers) into a `Vector2i` — this covers every current action payload's positional field (`"to"` for move/dismount, coordinate-shaped ability targets) without needing a per-action-type conversion table; a payload field that happens to be a two-key int dictionary for a non-positional reason would be misconverted, but no current action payload has one (Section 9).
3. `var result := RulesEngine.request_action(parsed["action_type"], parsed["actor_id"], <converted payload>)`.
4. Convert `result` back to a JSON-safe `Dictionary` — walk it for any `Vector2i` value (e.g. a future handler might return one) and convert to `{"x":.., "y":..}`; every current `result` shape (LLD-rules-engine.md Sections 4.2–4.8) is already JSON-safe (`bool`/`int`/`String` only), so this step is a defensive no-op today, not dead code removed, since a future action easily could return one.
5. Return the converted `result`.

**Output**: exactly `RulesEngine.request_action`'s own return shape (`{"success": bool, "reason": String, ...action-specific keys}`), JSON-stringified — Playwright reads this directly to assert on action outcomes, the same `result` a same-process caller would receive.

## 5. Data Structures

No new persistent data structures — `serialize_state`/`dispatch_action` are pure transformation functions over existing `MatchState`/`CharacterInstance`/`StatusEffect` (read) and `RulesEngine.request_action`'s existing parameter/return shapes (read/write), respectively.

## 6. Signal/Payload Specs

`TestBridge` neither emits nor listens to any `EventBus` signal — it is a request/response bridge only, activated per-call from JS, not reactive to match events. (Playwright, if it needs to wait for a specific state change rather than polling `mythcards_get_state()` in a loop, is expected to poll — no push-based JS notification mechanism is specced here, since HLD Section 4.13 only ever describes the two pull-based hooks.)

## 7. Error Handling & Edge Cases

| Scenario | Expected behavior | Source |
| --- | --- | --- |
| `mythcards_get_state()` called before any match has started (`GameState.match_state == null`) | `serialize_state()` returns `{"phase": "", "turn_number": 0, "active_player_id": "", "winner_id": "", "win_condition": "", "players": {}}` rather than crashing — a defensive empty-state shape, since Playwright driving a fresh page load may legitimately call this before `SetupFlow.start_match()` runs | Section 4.1 |
| `mythcards_dispatch_action` called with malformed JSON | `{"success": false, "reason": "malformed action JSON"}` (Section 4.2 step 1) — never reaches `RulesEngine`, so no partial state mutation is possible from a bad request | NFR-020 |
| `mythcards_dispatch_action` called with a well-formed but semantically invalid action (unknown actor, illegal move, etc.) | Passed straight through to `RulesEngine.request_action`, which already handles every such case with its own `{"success": false, "reason": ...}` shape (LLD-rules-engine.md Section 4) — `TestBridge` adds no additional validation of its own beyond JSON well-formedness | Section 4.2 |
| `TestBridge._ready()` runs in a non-Web, non-tagged export (desktop, or a future mobile/store build) | Returns immediately at the feature-tag check (Section 3.1) — `JavaScriptBridge` itself is only available in Web exports regardless, so this check is what prevents even *attempting* to call an unavailable API on those platforms, not just a policy preference | HLD-R-008 |
| `serialize_state()`/`dispatch_action()` called directly (not through the JS bridge) — e.g. from a GUT test | Work identically — both are pure functions with no `JavaScriptBridge` dependency (Section 3.1's own doc comments); only `_js_get_state`/`_js_dispatch_action` (the actual JS-facing wrappers) touch `JavaScriptBridge`, and only to JSON-stringify what these two already produce | Section 8 |

## 8. Test Plan

Unit tests use **GUT**, run inside the editor/headless Godot — **not** a browser, and **not** through `JavaScriptBridge` at all (that API doesn't exist outside a Web export runtime). This is exactly why `serialize_state()`/`dispatch_action()` are specced as pure functions separate from the `_js_*` wrappers (Section 3.1): GUT can exercise the actual logic directly. Verifying the real `window.mythcards_get_state()`/`window.mythcards_dispatch_action()` JS-facing surface is Playwright's job, once a Web export exists — that is an integration-level check outside GUT's reach, not a gap in this test plan.

| Case | Given | When | Then | BRD ID |
| --- | --- | --- | --- | --- |
| C1 | A populated `GameState.match_state` (14 characters, both players) | `serialize_state()` | Returned `Dictionary` matches Section 4.1's schema exactly — `players["p1"]["characters"].size() == 7`, each `position` is a `{"x":.., "y":..}` dict, not a raw `Vector2i` | FR-090A |
| C2 | `GameState.match_state == null` | `serialize_state()` | Returns the defensive empty shape (Section 7), no crash | Section 7 |
| C3 | Valid move action JSON: `'{"action_type":"move","actor_id":"p1_r-gymnast","payload":{"to":{"x":3,"y":2}}}'` | `dispatch_action(...)` | `RulesEngine.request_action` called with `payload["to"]` as an actual `Vector2i(3,2)`, not a dict | Section 4.2 |
| C4 | Malformed JSON string | `dispatch_action(...)` | `{"success": false, "reason": "malformed action JSON"}`; `RulesEngine.request_action` never called (spy/double verifies zero calls) | Section 7 |
| C5 | A `result` from `RulesEngine` containing a `Vector2i` value in some future action's extra keys (simulated via a GUT double) | `dispatch_action(...)`'s output-conversion step (Section 4.2 step 4) | That value is converted to `{"x":.., "y":..}` in the returned `Dictionary` | Section 4.2 |
| C6 | A full round-trip: `dispatch_action` a legal move, then `serialize_state()` | — | The moved character's `position` in the resulting state matches the requested destination | FR-090A, NFR-031A |

## 9. Open Implementation Questions

- **`[NEED, carried forward from HLD Section 4.13, not resolved here]`** the exact `JavaScriptBridge.create_callback()`/`get_interface()` call shape must be verified against the actual Godot 4.7.x docs at implementation time — this LLD deliberately does not guess a specific signature, per the `lld-writer` skill's rule against presenting a guessed detail as decided.
- **Vector2i-shaped-dict heuristic (Section 4.2 step 2)** — converting any `{"x": int, "y": int}` payload value assumes no current action payload has a legitimately non-positional two-key-int field. True for every action type in LLD-rules-engine.md Sections 4.2–4.8 today; flag if a future action's payload violates this coincidentally.
- **No push-based test notification mechanism** (Section 6) — Playwright must poll `mythcards_get_state()` rather than await an event. Acceptable for a synchronous, single-process hotseat prototype; would need revisiting if test scenarios ever require awaiting something slower than immediate (nothing in the current ruleset has async delay).
- **Feature-tag gating (Section 3.1) assumes the Web export preset used for automated testing is configured with `mythcards_testbridge` as a Custom Feature** — a project-settings step, not code; flagged in Next Steps rather than assumed already done.

## 10. Traceability

| LLD Section | HLD Section | BRD/PRD IDs |
| --- | --- | --- |
| 4.1 `serialize_state` | HLD 4.13 | FR-090A, NFR-031A |
| 4.2 `dispatch_action` | HLD 4.13, Section 4.4 (via `RulesEngine`) | FR-090A, NFR-031A |
| 3.1 Feature-tag gating | HLD 4.13, HLD-R-008 | NFR-031A |

## 11. Next Steps

1. Add `scripts/autoloads/test_bridge.gd` (Section 3.1); register as an autoload (order doesn't matter — it's only ever called externally, never by another autoload's `_ready()`).
2. Configure the Web export preset's Custom Features field to include `mythcards_testbridge` (Section 9) — verify via a build that the tag is present in that export and absent from any other.
3. Verify the exact `JavaScriptBridge` API shape against Godot 4.7.x docs (Section 9) before implementing `_register_js_callbacks`.
4. Write `tests/unit/test_test_bridge.gd`; confirm C1–C6.
5. Write the first Playwright test driving a full match through `window.mythcards_dispatch_action()`/`window.mythcards_get_state()` once a Web export build exists (HLD Section 13 step 15) — this is the point where the standalone Playwright learning project already set up in `D:\auto` becomes directly relevant to this project.
