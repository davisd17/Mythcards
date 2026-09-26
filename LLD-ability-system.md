# MythCards Low-Level Design — Ability System (`AbilitySystem`)

**Document Control**

| Field | Value |
| --- | --- |
| Source document(s) | HLD.md (v3, 2026-09-07), BRD.md (v3, 2026-08-14) Section 12, LLD-content-board.md (v3), LLD-match-setup.md (v3), LLD-rules-engine.md (v5), LLD-combat-mount.md (v4) |
| Module/flow scope | Ability System (`AbilitySystem` — HLD Section 4.6). HLD build-order step 10. All 14 prototype character abilities across their 3 levels. |
| Target stack | Godot 4.7.x, GDScript |
| Version | 2 (designer review pass, 2026-09-25: four-bucket classification confirmed and re-based on cause-not-frequency; standalone once-per-turn/match abilities confirmed to cost AP; Piercing Shot fixed at 1 point of damage reduction; Resonance Guard's Redirect removed and L2/L3 rewritten; `"next_turn"` `expires` value approved; Synchronize confirmed ally-only; `get_conditional_range_bonus` takes an attack-vs-ability `context`; pylon-equivalence joint design pass scheduled; new Section 3.6 on designing for playtest churn) |
| Date | 2026-09-25 |
| Status | Draft |
| Prepared by | Drew Davis (solo developer/designer, acting as own PM) |

## 1. Purpose & Scope

This LLD specs the dispatch-table ability system HLD Section 4.6 calls for: one handler per character, registered by id, implementing that character's printed L1 ability plus its L2/L3 upgrade text (BRD Section 12), fulfilling the forward-referenced contract already fixed by `RulesEngine` (LLD-rules-engine.md) and `CombatResolver`/`MountSystem` (LLD-combat-mount.md).

Writing this LLD surfaced a large number of real gaps in the four earlier LLDs — effective-stat routing, mount-aware movement queries, a free/AP-less action type, object-passable movement, and a damage pipeline with no room for penetration or damage amplification. Per the `lld-writer` skill's own rule ("if writing the LLD surfaces a real problem... patch first, don't design around it"), all of those were patched directly in LLD-match-setup.md (now v3), LLD-rules-engine.md (now v5), LLD-content-board.md (now v3), and LLD-combat-mount.md (now v4) *before* this document — this LLD only consumes the resulting contract, it does not re-derive it. Every reference below to a method on `CharacterInstance`, `RulesEngine`, `BoardModel`, `CombatResolver`, or `MountSystem` refers to those patched versions.

**Explicitly out of scope**: `LevelingSystem`'s own detection of *when* a character levels up or receives a Spirit Ember (LLD-06) — this LLD only specs what happens *once told* a level changed (`apply_level_up_effects`, Section 3.3), not the detection logic itself. `RelicEventDeck`'s deck/draw mechanics (LLD-07) — Oracle Sovereign's Foresight interacts with the deck, but this LLD specs only the character-ability side of that interaction, not deck internals.

## 2. File Layout

```
D:\mythcards\
├── scripts/
│   └── systems/
│       ├── ability_system.gd          (new — class_name AbilitySystem)
│       └── abilities/
│           ├── ability_handler.gd     (new — class_name AbilityHandler, base class)
│           ├── ability_registry.gd    (new — class_name AbilityRegistry)
│           ├── r_gymnast_ability.gd
│           ├── r_tiger_ability.gd
│           ├── r_sniper_ability.gd
│           ├── r_general_ability.gd
│           ├── r_hero_ability.gd
│           ├── r_engineer_ability.gd
│           ├── r_seer_ability.gd
│           ├── a_attendant_ability.gd
│           ├── a_glider_ability.gd
│           ├── a_guard_ability.gd
│           ├── a_conductor_ability.gd
│           ├── a_hero_ability.gd
│           ├── a_architect_ability.gd
│           └── a_harmonic_ability.gd
└── tests/
    └── unit/
        └── test_ability_system.gd     (new — extends GutTest)
```

One handler file per character, using the exact `id` values from `data/cards/characters.json` (confirmed by reading that file directly rather than guessing): `r-gymnast`, `r-tiger`, `r-sniper`, `r-general`, `r-hero`, `r-engineer`, `r-seer`, `a-attendant`, `a-glider`, `a-guard`, `a-conductor`, `a-hero`, `a-architect`, `a-harmonic`.

## 3. Architecture

### 3.1 Ability classification framework

BRD Section 12's card text mixes several distinct *kinds* of rules text under one "Level N" heading. This LLD sorts every character's text into exactly one of four buckets, applied consistently below rather than re-derived per character.

**Classification principle (designer-confirmed, 2026-09-25): a bucket is decided by what *causes* an ability to happen, never by how often it may be used.** "Once per turn" and "once per match" are orthogonal *usage gates* (FR-043) — tracked in `ability_uses_this_turn`/`ability_uses_this_match` and enforced on top of whichever bucket the ability belongs to. A use cap never makes an ability reactive, and a reactive trigger does not become "activated" by carrying one.

The four buckets:

- **Passive stat/rule modifier** — always on while its condition holds (e.g. Quartz Armor, Aim, Synchronize, Stand Firm). No AP cost, no player activation. Modeled as `AbilityHandler` query-hook overrides (Section 3.2).
- **Activated (AP) ability** — the character's L1-named ability (Vault, Pounce, Command, Barricade, Chill, Link Mind, Foresight, Pylon, Resonance Shield). Invoked via `RulesEngine`'s `"ability"` action (1 pool AP + 1 character AP). L2/L3 text that reads as "X becomes Y" or "also Z" modifies this *same* ability's behavior at higher levels (the handler checks `instance.level` internally) — it is never a second `ability_id`.
- **Reactive trigger** — an effect whose *cause* is a game event, hooked to an `EventBus` signal (`character_moved`, `attack_resolved`, `character_defeated`, `character_leveled_up`, `spirit_ember_delivered`). Card text reads "when/after X, Y". No AP cost, no manual activation to *offer* it — but per LLD-rules-engine.md v4's `"reactive_bonus"` action type, several of these grant a free follow-up the player still chooses whether/how to use (a target to move to, an enemy to hit). The hook sets `instance.ability_uses_this_turn["<tag>_available"] = true`; the player consumes it via `request_action("reactive_bonus", instance_id, {"tag": ..., ...})`. Where the text also carries a cap ("once each turn after Vaulting"), that cap is applied as a separate gate through the same usage dictionaries — it is not what put the ability in this bucket.
- **Standalone activated ability** — a small number of L3 upgrades that grant a genuinely new player-activated capability with no triggering event and no free-of-AP wording (Winter Engineer's Frozen Redoubt, Manta Glider's Phase Current, Oracle Sovereign's Collective Ascension). Modeled as a second `ability_id` (`"<character_id>_l3"`) going through the normal AP-costing `"ability"` action. **AP rule (designer-confirmed, 2026-09-25): these cost 1 pool AP + 1 character AP like any other ability — including the once-per-match ones such as Collective Ascension — unless the card text explicitly states the effect is free.** Use caps are enforced by `can_use_ability` (Section 3.3) *in addition to* the AP cost, never instead of it.

**Status: confirmed, not inferred (2026-09-25).** These four buckets and the classification principle above were reviewed and accepted by the designer, and are now the shared vocabulary across documents — HLD Section 4.6 and BRD BR-021A/BR-021B/FR-045I carry the same four names and the same AP rule. Each character section below states which bucket its L1/L2/L3 text was assigned to.

### 3.2 `AbilityHandler` (base class, `res://scripts/systems/abilities/ability_handler.gd`)

```gdscript
class_name AbilityHandler
extends RefCounted

# Movement
func get_movement_pattern(instance: CharacterInstance) -> String:
    return "orthogonal"
func get_movement_passable_predicate(instance: CharacterInstance, board: BoardModel) -> Callable:
    return Callable()
func get_movement_object_passable_predicate(instance: CharacterInstance, board: BoardModel) -> Callable:
    return Callable()

# Attack / targeting
func get_attack_pattern(instance: CharacterInstance) -> String:
    return "orthogonal_line"
func get_line_of_sight_exceptions(instance: CharacterInstance, target_pos: Vector2i, board: BoardModel) -> Array[String]:
    return []
func get_penetration(instance: CharacterInstance) -> Dictionary:
    return {"ignore_reduction": 0, "ignore_shield": 0}

# Damage / defense
func get_own_damage_reduction(defender: CharacterInstance, attacker: CharacterInstance, is_ranged: bool) -> int:
    return 0
func get_aura_damage_reduction(aura_source: CharacterInstance, defender: CharacterInstance, attacker: CharacterInstance, is_ranged: bool) -> int:
    return 0
func intercept_lethal_damage(instance: CharacterInstance, board: BoardModel, combat: CombatResolver) -> Dictionary:
    return {"triggered": false}

# Conditional (live-computed) stat bonuses -- NOT baked into CharacterInstance fields
func get_conditional_atk_bonus(instance: CharacterInstance, board: BoardModel, match_state: MatchState) -> int:
    return 0
func get_conditional_range_bonus(instance: CharacterInstance, board: BoardModel, match_state: MatchState,
        context: String) -> int:
    # context is "attack" or "ability" -- several bonuses apply to only one of the two (Crystal
    # Architect's Pylon boosts ability range at L1, attack AND ability range at L2; the Crystal
    # Tide event boosts abilities only). Callers pass the context they are resolving range FOR:
    # RulesEngine._handle_attack passes "attack", _handle_ability passes "ability".
    # Designer-confirmed 2026-09-25; resolves the signature gap flagged by both this LLD
    # (Section 5.13) and LLD-relic-event-deck.md Section 9 item (e) -- one change, both cases.
    return 0
func get_own_conditional_max_hp_bonus(instance: CharacterInstance, board: BoardModel) -> int:
    return 0
func get_aura_conditional_max_hp_bonus(aura_source: CharacterInstance, target: CharacterInstance, board: BoardModel) -> int:
    return 0

# Level-up
func apply_level_up_effects(instance: CharacterInstance, new_level: int) -> void:
    pass   # permanent, non-conditional stat deltas only (Section 3.5) -- writes atk_bonus/
           # move_bonus/range_bonus/base_max_hp directly

# Activated abilities
func can_use(instance: CharacterInstance, match_state: MatchState) -> bool:
    return true
func get_legal_targets(instance: CharacterInstance, board: BoardModel, match_state: MatchState) -> Array:
    return []
func execute(instance: CharacterInstance, target, board: BoardModel, match_state: MatchState,
        combat: CombatResolver) -> Dictionary:
    return {"success": false, "reason": "no AP ability defined for this character"}

# Reactive hooks -- connected once per match by AbilitySystem (Section 3.3)
func on_character_moved(instance: CharacterInstance, from: Vector2i, to: Vector2i,
        board: BoardModel, move_required_pass: bool) -> void:
    pass
func on_attack_resolved(instance: CharacterInstance, attacker_id: String, target_id: String,
        damage: int, defeated: bool, match_state: MatchState, combat: CombatResolver) -> void:
    pass
func on_character_defeated(instance: CharacterInstance, defeated_id: String,
        match_state: MatchState) -> void:
    pass
func on_character_leveled_up(instance: CharacterInstance, new_level: int,
        match_state: MatchState) -> void:
    pass

# Consumption of an offered free bonus action (Section 3.1's "Reactive trigger" bucket)
func execute_reactive_bonus(instance: CharacterInstance, tag: String, payload: Dictionary,
        board: BoardModel, match_state: MatchState, combat: CombatResolver) -> Dictionary:
    return {"success": false, "reason": "no reactive bonus defined for this tag"}
```
Each concrete handler overrides only the methods relevant to its character — most override 2–5 of the ~20 available hooks. This wide-but-shallow interface is the direct implementation of HLD Section 4.6's "registered through one dispatch table... not a chain of hardcoded `if` branches": the table is `AbilityRegistry` (Section 3.3), the branches are these virtual methods.

### 3.3 `AbilityRegistry` and `AbilitySystem` (`res://scripts/systems/ability_system.gd`, `abilities/ability_registry.gd`)

```gdscript
class_name AbilityRegistry

static func get_handler(character_id: String) -> AbilityHandler:
    match character_id:
        "r-gymnast": return RGymnastAbility.new()
        "r-tiger": return RTigerAbility.new()
        "r-sniper": return RSniperAbility.new()
        "r-general": return RGeneralAbility.new()
        "r-hero": return RHeroAbility.new()
        "r-engineer": return REngineerAbility.new()
        "r-seer": return RSeerAbility.new()
        "a-attendant": return AAttendantAbility.new()
        "a-glider": return AGliderAbility.new()
        "a-guard": return AGuardAbility.new()
        "a-conductor": return AConductorAbility.new()
        "a-hero": return AHeroAbility.new()
        "a-architect": return AArchitectAbility.new()
        "a-harmonic": return AHarmonicAbility.new()
        _:
            push_error("AbilityRegistry: no handler for character_id '%s'" % character_id)
            return AbilityHandler.new()   # base-class no-op fallback, never null -- callers
                                           # never need a null check
```
There is no separate `ability_id` distinct from `character_id` (Section 9) — this prototype's content is 1 character : 1 innate ability, so the registry keys directly on `CharacterData.id`. Standalone L3 abilities (Section 3.1's 4th bucket) use `"<character_id>_l3"` as their `ability_id` string but are still dispatched to the *same* handler instance (the handler's `execute()` branches on which `ability_id` was requested).

```gdscript
class_name AbilitySystem
extends RefCounted

var board: BoardModel
var _handler_cache: Dictionary = {}   # String character_id -> AbilityHandler, memoized per
                                       # match (handlers are stateless re: match data -- all
                                       # state lives on CharacterInstance/StatusEffect -- so one
                                       # instance per character id is safely reused all match)

func _init(p_board: BoardModel) -> void:
    board = p_board
    EventBus.character_moved.connect(_on_character_moved)
    EventBus.attack_resolved.connect(_on_attack_resolved)
    EventBus.character_defeated.connect(_on_character_defeated)
    EventBus.character_leveled_up.connect(_on_character_leveled_up)
    # AbilitySystem is a plain class (HLD Section 5.1), not an autoload, but it is instantiated
    # once by RulesEngine at match start and held for the match's lifetime -- long enough for
    # these signal connections to matter. See Section 9 for why AbilitySystem, unlike
    # BoardModel/CombatResolver/MountSystem, needs to be an EventBus listener at all.

func _get_handler(instance: CharacterInstance) -> AbilityHandler:
    if not _handler_cache.has(instance.data.id):
        _handler_cache[instance.data.id] = AbilityRegistry.get_handler(instance.data.id)
    return _handler_cache[instance.data.id]

# --- Forward-referenced contract methods (RulesEngine/CombatResolver/MountSystem callers) ---

func get_movement_pattern(instance: CharacterInstance) -> String:
    return _get_handler(instance).get_movement_pattern(instance)
func get_movement_passable_predicate(instance: CharacterInstance) -> Callable:
    return _get_handler(instance).get_movement_passable_predicate(instance, board)
func get_movement_object_passable_predicate(instance: CharacterInstance) -> Callable:
    return _get_handler(instance).get_movement_object_passable_predicate(instance, board)
func get_attack_pattern(instance: CharacterInstance) -> String:
    return _get_handler(instance).get_attack_pattern(instance)
func get_line_of_sight_exceptions(instance: CharacterInstance, target_pos: Vector2i,
        p_board: BoardModel) -> Array[String]:
    return _get_handler(instance).get_line_of_sight_exceptions(instance, target_pos, p_board)
func get_penetration(instance: CharacterInstance) -> Dictionary:
    return _get_handler(instance).get_penetration(instance)

func get_passive_damage_reduction(defender: CharacterInstance, attacker: CharacterInstance,
        is_ranged: bool) -> int:
    # See Section 4.1 for the aggregation algorithm (own + nearby-ally auras).

func intercept_lethal_damage(defender: CharacterInstance) -> Dictionary:
    return _get_handler(defender).intercept_lethal_damage(defender, board, <CombatResolver instance>)
    # CombatResolver passes itself in when calling -- see Section 9 for the resulting small
    # signature note versus LLD-combat-mount.md's original single-argument assumption.

func get_conditional_atk_bonus(instance: CharacterInstance) -> int:
    # See Section 4.1 (same aggregation shape as damage reduction, self + aura).
func get_conditional_range_bonus(instance: CharacterInstance, context: String) -> int:
    # context: "attack" | "ability". Self-only in the current roster (no aura grants
    # conditional RANGE) -- still aggregated the same way for consistency and future-proofing.
    # CharacterInstance.get_effective_range(context) threads the same argument through
    # (LLD-match-setup.md patch, same date) so attack range and ability range can diverge.
func get_effective_max_hp(instance: CharacterInstance) -> int:
    # instance.base_max_hp + self bonus + aggregated aura bonuses. See Section 4.1.

func can_use_ability(instance: CharacterInstance, ability_id: String) -> bool:
    # False if instance.data.id doesn't "own" ability_id (i.e. ability_id is neither
    # instance.data.id nor "<instance.data.id>_l3"), OR if the handler's can_use() returns
    # false (once-per-turn/match check, Section 3.5), OR instance.level is below the level a
    # standalone L3 ability requires. Otherwise delegates to _get_handler(instance).can_use().
func get_legal_ability_targets(instance: CharacterInstance, ability_id: String) -> Array:
    return _get_handler(instance).get_legal_targets(instance, board, GameState.match_state)
func execute_ability(instance: CharacterInstance, ability_id: String, target) -> Dictionary:
    return _get_handler(instance).execute(instance, target, board, GameState.match_state, <CombatResolver>)
func execute_reactive_bonus(instance: CharacterInstance, tag: String, payload: Dictionary) -> Dictionary:
    return _get_handler(instance).execute_reactive_bonus(instance, tag, payload, board,
        GameState.match_state, <CombatResolver>)

func apply_level_up_effects(instance: CharacterInstance, new_level: int) -> void:
    # Called by LevelingSystem (LLD-06, forward reference in that direction) once it decides a
    # level-up occurred. Delegates to the handler; the handler mutates atk_bonus/move_bonus/
    # range_bonus/base_max_hp/current_hp directly (Section 3.5) -- this is the ONE place those
    # fields are ever written outside of SetupFlow's initial construction.

func is_ally_of_mark_source(status_effect: StatusEffect, attacker: CharacterInstance) -> bool:
    # Resolves status_effect.source_character_id via GameState.match_state.find_character(),
    # compares its player_id to attacker.player_id. Used by CombatResolver.apply_damage
    # (LLD-combat-mount.md v4, Section 4.1 step 1) for Dead Lane's "marked" bonus.

# --- Reactive signal handlers (private) ---
func _on_character_moved(character_id: String, from: Vector2i, to: Vector2i) -> void:
    # See Section 4.2 for the "did this move require a pass" determination shared by every
    # character whose reactive trigger depends on it (Gymnast, Manta Glider).
func _on_attack_resolved(attacker_id: String, target_id: String, damage: int, defeated: bool) -> void:
func _on_character_defeated(character_id: String, defeated_by_id: String, cause: String) -> void:
    # Signature matches LLD-combat-mount.md v5's character_defeated payload (character_id,
    # defeated_by_id, cause) -- AbilitySystem's own handlers only ever need character_id for
    # their on_character_defeated() hooks (Section 3.2); defeated_by_id/cause exist for
    # LevelingSystem's benefit (LLD-06), not consumed further here.
func _on_character_leveled_up(character_id: String, new_level: int) -> void:
    # Each resolves the CharacterInstance(s) via GameState.match_state.find_character() and
    # calls the corresponding on_*() hook on that character's own handler (Section 3.2).
```
Satisfies HLD Section 4.6 / BRD FR-037–FR-045I.

### 3.4 `StatusEffect.type` vocabulary (extends LLD-match-setup.md Section 3.2)

This LLD is the first to actually populate `StatusEffect` instances, so it fixes the concrete `type` string vocabulary the HLD only sketched as examples:

| `type` | Meaning | Consumed by |
| --- | --- | --- |
| `"shield"` | `value` = remaining damage prevention | `CombatResolver.apply_damage` (existing) |
| `"temp_atk"` | `value` = flat ATK bonus this turn | `CharacterInstance.get_effective_atk()` (existing) |
| `"temp_move"` | `value` = flat MOVE delta this turn (negative for a slow) | `CharacterInstance.get_effective_move()` (existing) |
| `"marked"` | `value` = bonus damage from the next allied attack; `source_character_id` = the marking character | `CombatResolver.apply_damage` (LLD-04 v4) |
| `"no_mount_dismount"` | flag only (`value` unused) | `RulesEngine._handle_mount`/`_handle_dismount` (LLD-03 v5) |
| `"no_push"` | flag only | `CombatResolver.apply_push` (LLD-04 v4) |
| `"no_reaction"` | flag only | `RulesEngine._handle_reactive_bonus` (LLD-03 v5) |

`expires` values in active use: `"immediate"`, `"this_turn"`, `"this_round"`, and **`"next_turn"`** (designer-approved 2026-09-25, extending HLD Section 6's original three). `"next_turn"` means "in force throughout the affected character's own next turn, cleared at the start of the turn after that" — the duration Chill, Deep Freeze, and every future opponent's-next-turn effect actually need. Clearing is two-phase in `TurnManager.start_turn` (LLD-match-setup.md, same-date patch): an effect tagged `"next_turn"` records the `turn_number` it was applied on, is skipped by the first `start_turn` for its holder's owner, and is removed by the second.

### 3.5 Stat-bonus baking convention

Permanent, unconditional level-up stat changes (e.g. Tiger's L2 "+1 HP," Sniper's L2 "+1 RANGE," Gymnast's L3 "+1 ATK") are written *once*, directly, into `CharacterInstance.atk_bonus`/`move_bonus`/`range_bonus`/`base_max_hp` (and `current_hp`, increased by the same amount as any `base_max_hp` increase, so a level-up is also a partial heal — no printed card contradicts this reading) by `apply_level_up_effects()` at the moment `LevelingSystem` reports a level change. They are never recomputed from `instance.level` on the fly. Conditional bonuses (Bogatyr Champion's positional HP, Quartz Attendant's/Sniper's adjacency- or turn-history-gated bonuses) are the opposite: never baked in, always computed live via the `get_conditional_*`/`get_own_conditional_*`/`get_aura_*` hooks (Section 3.2), aggregated by `AbilitySystem` (Section 4.1). This split exists because a permanent bonus only ever needs to be computed once, while a conditional one can flip on any move, any turn, for any adjacent character — baking it in would require re-deriving and re-writing it on every relevant event anyway, so a live query is strictly simpler and cannot drift out of sync.

### 3.6 Designing for playtest churn

Ability text is expected to change repeatedly during paper and digital playtesting (designer direction, 2026-09-25) — this module is the one most likely to be rewritten card-by-card between test sessions, and the design below is built so that churn costs minutes, not a refactor:

1. **Tunable numbers live in content, not code.** Every bare magnitude a handler applies (shield value, Chill's damage, Pounce's `+2`, reflect damage, aura radius, use caps) should be read from the character's `CharacterData` ability-rules data (`data/cards/characters.json`, BRD Section 11's `ability rules data` field) rather than hardcoded in the `.gd` handler. Rebalancing a number is then a JSON edit with no code change and no recompile — the fastest possible loop between two paper matches.
2. **One handler file per character (Section 3.3's registry) is the churn boundary.** Rewriting one card's L2 touches exactly one file plus its JSON row; nothing else in the codebase names that card.
3. **The four buckets (Section 3.1) are the vocabulary for a rewrite, not just for the current text.** When a card is rewritten, re-classify it into one of the four buckets first; if the new text fits none of them, that is the signal to have the design conversation rather than to widen a handler with a special case (this is exactly how Resonance Guard's old Redirect was caught and redesigned — Section 5.10).
4. **Prefer an existing `StatusEffect` type over a new mechanism.** The Section 3.4 vocabulary is deliberately generic (`shield`/`temp_atk`/`temp_move`/flags) so most rewrites are expressible without touching `CombatResolver`/`RulesEngine`. Adding a new `type` is cheap; adding a new *hook* to `AbilityHandler` (Section 3.2) is the expensive move and should be a deliberate decision.
5. **Test cases track card text.** Section 8's per-character cases are written against observable behavior (HP after an attack, legal-target counts), not internals, so a rewritten card needs its case rewritten but nothing else in the suite re-derived.

Accepted cost: reading magnitudes from JSON means a content-authoring error surfaces at runtime rather than at compile time. `ContentDB`'s existing validation pass (LLD-content-board.md) is the place to catch that, by validating that every ability-rules key a handler expects is present for that card.

## 4. Algorithms

### 4.1 Aggregation pattern (damage reduction, conditional ATK/RANGE, conditional max HP)

All "self + nearby ally auras" queries share one shape — specced once here, referenced by name from each per-character section rather than repeated:

```
func _aggregate(target: CharacterInstance, self_method: String, aura_method: String, extra_args: Array) -> int:
    var total := _get_handler(target).call(self_method, target, *extra_args)
    for ally in GameState.match_state.get_player(target.player_id).characters:
        if ally.instance_id == target.instance_id:
            continue
        total += _get_handler(ally).call(aura_method, ally, target, *extra_args)
    return total
```
1. Start with the target's own handler's self-contribution (e.g. Resonance Guard's Quartz Armor reducing damage to itself).
2. Loop over every *other* character on the target's own team (7 max, trivial cost) and add each one's aura contribution as computed by *that ally's own handler* (e.g. Bogatyr Champion's handler decides whether it grants a reduction to the character being damaged, by checking adjacency itself).
3. `get_passive_damage_reduction(defender, attacker, is_ranged)` = `_aggregate(defender, "get_own_damage_reduction", "get_aura_damage_reduction", [attacker, is_ranged])`.
4. `get_conditional_atk_bonus(instance)` = `_aggregate(instance, "get_conditional_atk_bonus", <no aura variant exists for ATK in the current roster>, [])` — degenerates to just the self term; kept as a named `AbilitySystem` method rather than inlined for consistency and in case a future aura-ATK card is added.
5. `get_effective_max_hp(instance)` = `instance.base_max_hp + _aggregate(instance, "get_own_conditional_max_hp_bonus", "get_aura_conditional_max_hp_bonus", [])`.

Only ally auras are considered (never enemy auras) since every current aura is defensive/supportive by design — no card in the roster imposes a debuff aura on nearby enemies.

### 4.2 "Did this move require passing through something" determination

Shared by Gymnast (L3 reactive attack) and Manta Glider (L2 reactive ATK buff), both of which trigger only when the just-completed move actually used a pass-through, not on every move:

1. `var without_pass := board.get_legal_moves(from, move_budget, pattern, Callable(), Callable())` — the same move, recomputed with no pass-through predicates at all.
2. `move_required_pass := to not in without_pass`.
3. `AbilitySystem._on_character_moved` computes this once per `character_moved` signal (reusing the same `move_budget`/`pattern` the mover's handler would report — recomputed fresh from the handler rather than cached from `RulesEngine`, since the signal payload doesn't carry them) and passes the resulting bool into the mover's `on_character_moved(instance, from, to, board, move_required_pass)` hook (Section 3.2).

This sidesteps needing per-tile path metadata from `BoardModel`'s BFS (which only returns a reachable *set*, not paths) — a destination only reachable with vaulting/gliding allowed, that would not otherwise be reachable at all, necessarily required passing through something.

## 5. Per-Character Specs

### 5.1 `r-gymnast` — Gymnast (Common) — Vault / Aurora Acrobat

- **L1 (Passive, movement modifier).** `get_movement_passable_predicate`: returns a closure over a local counter capping passes at `1`; the closure returns `true` only for a tile whose occupant's `player_id == instance.player_id` (ally-only at L1), consuming the single pass on first use.
- **L2 (modifies the same passive; baked stat: `move_bonus += 1`).** The predicate closure now accepts *any* occupied tile (ally or enemy), still capped at exactly one pass ("any one occupied tile"). `[NEED]` "After Vaulting, this character may move 1 extra tile": implementing this exactly requires computing legal moves at both `move_budget` and `move_budget + 1` and accepting a `budget+1`-only destination *only if* Section 4.2's `move_required_pass` check is also true for it — this is algorithmically sound (Section 4.2 already provides the primitive) but needs a dedicated `RulesEngine._handle_move` branch to try both budgets for this one character, which this LLD flags as a required follow-up patch rather than executing inline (a narrow, single-character combinatorial case, unlike the foundational gaps already patched in Sections above). Recommended approach documented here so the follow-up patch doesn't have to rediscover it.
- **L3 "Aurora Acrobat" (Reactive trigger; baked stats: `atk_bonus += 1`, `move_bonus += 1` more).** `on_character_moved`: if `move_required_pass` and `not instance.ability_uses_this_turn.get("l3_bonus_attack_used", false)`: set `instance.ability_uses_this_turn["l3_bonus_attack_available"] = true`. `execute_reactive_bonus` for tag `"l3_bonus_attack"`: validates `payload["target_id"]` is an adjacent enemy, calls `combat.apply_damage(instance, target, 1, false)`, marks `ability_uses_this_turn["l3_bonus_attack_used"] = true` and clears the `_available` flag.

### 5.2 `r-tiger` — White Siberian Tiger (Mount) — Pounce / Aurora Predator

- **L1 (Activated ability, self-target).** `can_use`: `false` if `instance.is_mounted_rider` (n/a for a Mount itself, but a mounted-*with*-someone Mount also cannot act, BR-015) — practically, `can_use` returns `instance.mounted_with_id == ""` (Pounce only "while not mounted," meaning this Mount is not currently carrying a rider). `get_legal_targets`: `[]` (no target — self-buff). `execute`: applies `StatusEffect(type="temp_atk", value=2, expires="this_turn")` to `instance` itself.
- **L2 (baked: `base_max_hp += 1`, `move_bonus += 1`; modifies Pounce).** `execute` additionally applies `StatusEffect(type="pounce_push_pending", value=1, expires="this_turn")` to `instance`. `on_attack_resolved`: if `attacker_id == instance.instance_id` and `instance.status_effects` has `"pounce_push_pending"`: `combat.apply_push(<target>, instance.position, 1)`; remove the marker (single use — this is a one-shot flag consumed by whichever attack fires next, matching "Pounce also pushes the target," i.e. Pounce's own marked attack, not any subsequent one).
- **L3 "Aurora Predator" (Reactive trigger; baked: `atk_bonus += 1`).** `on_attack_resolved`: if `attacker_id == instance.instance_id`, `defeated == true`, and the mark being consumed this attack was the Pounce `temp_atk` mark (i.e. this was a Pounce-empowered kill) and `ability_uses_this_turn` doesn't already show `"l3_bonus_used"`: set `"l3_bonus_available" = true`. `execute_reactive_bonus` for `"l3_pounce_bonus"`: moves `instance` up to 2 tiles (via `board.get_legal_moves(instance.position, 2, ...)`, validating the requested destination), then `instance.character_ap_remaining = min(instance.character_ap_max, instance.character_ap_remaining + 1)`.

### 5.3 `r-sniper` — Sniper (Warrior) — Aim / Piercing Shot / Dead Lane

- **L1 (Passive, conditional RANGE).** `get_conditional_range_bonus(..., context)`: returns `1` if `context == "attack"` and `not instance.ability_uses_this_turn.get("moved", false)` (LLD-rules-engine.md v5's generic per-turn move marker, Section 4.2 step 7), else `0` — Aim's text says "this character's basic attack +1 RANGE," so it is attack-context only.
- **L2 (baked: `range_bonus += 1`).** `get_penetration`: returns `{"ignore_reduction": 1, "ignore_shield": 0}` — **designer-confirmed 2026-09-25: Piercing Shot ignores exactly 1 point of damage reduction, with no attacker choice and no shield interaction.** A defender with 2 points of reduction still applies 1 against this attack; shields are untouched. Card text updated to match ("ignores 1 point of damage reduction"), so `ignore_shield` stays `0` permanently and `CombatResolver`'s `ignore_shield` term (LLD-combat-mount.md Section 4.1 step 5) has no consumer in the current roster — it is retained for future cards, not dead-lettered. `get_line_of_sight_exceptions(instance, target_pos, board)`: scans the straight line from `instance.position` to `target_pos`; if exactly one tile on that line is occupied by an *ally*, returns `[<that ally's instance_id>]` (one exception, matching "may ignore one occupied allied tile").
- **L3 "Dead Lane" (Reactive trigger; baked: `atk_bonus += 1`).** `on_attack_resolved`: if `attacker_id == instance.instance_id`, `damage > 0`, and the tile distance to the target was `>= 3`, and `not instance.ability_uses_this_turn.get("dead_lane_used", false)`: apply `StatusEffect(type="marked", value=1, expires="this_round", source_character_id=instance.instance_id)` to the target; mark `ability_uses_this_turn["dead_lane_used"] = true`. This is a direct effect application (not an offered `reactive_bonus`) since the card text doesn't give the player a choice — "mark that enemy" happens automatically.

### 5.4 `r-general` — Army General (Leader) — Command / Tactical Mastery

- **L1 (Activated ability, targets 1 ally within 2 tiles).** `get_legal_targets`: allies within `get_tiles_in_range(instance.position, 2, "orthogonal_line")` filtered by `board.has_line_of_sight` (BR-011 applies to Command, FR-036C). `execute(instance, target, ..., payload={"choice": "atk"|"move"})`: if `"atk"`, applies `StatusEffect(type="temp_atk", value=1, expires="this_turn")` to the target; if `"move"`, sets `target.ability_uses_this_turn["general_free_move_available"] = true`. `execute_reactive_bonus` for tag `"general_free_move"` (on the *target* character, not General): moves that character 1 tile via the normal `board.get_legal_moves(pos, 1, ...)` check, no AP spent.
- **L2 (range 3, up to 2 targets).** `get_legal_targets`/`execute` extended to accept an array of up to 2 target ids, each independently choosing `"atk"` or `"move"`.
- **L3 "Tactical Mastery" (Reactive trigger; baked: `base_max_hp += 1`).** Requires tracking *which* allies were Commanded this turn: `execute` (L1/L2, any level) also sets `target.ability_uses_this_turn["commanded_by"] = instance.instance_id`. `on_character_defeated` (General's own handler, called for every defeat) and a new signal consumption for `spirit_ember_delivered` (forward reference to `LevelingSystem`, LLD-06 — `AbilitySystem._init` must also connect this signal, Section 9): if the acting/delivering character's `ability_uses_this_turn["commanded_by"] == instance.instance_id` and General's own `ability_uses_this_turn` doesn't show `"l3_used"`: set General's own `"l3_ap_refresh_available" = true`. `execute_reactive_bonus` for `"l3_ap_refresh"`: refreshes 1 character AP on a player-chosen ally within 2 tiles of General.

### 5.5 `r-hero` — Bogatyr Champion (Hero) — Stand Firm / Heroic Guard / Last Oath

- **L1 (Passive, conditional self max-HP).** `get_own_conditional_max_hp_bonus`: returns `1` if `instance.position == BoardModel.CENTER_TILE or <Manhattan/orthogonal distance from CENTER_TILE == 1>`, else `0`. When this bonus's value *changes* (computed by `AbilitySystem` on every `character_moved` event for this instance, Section 9), `current_hp` is adjusted by the same delta, clamped so it never exceeds the new effective max and never drops below `1` from a bonus loss alone (Section 9 — a genuine BRD-silent edge case, resolved this way as the least-surprising default).
- **L2 "Heroic Guard" (replaces L1's value, adds an aura; no baked stats).** `get_own_conditional_max_hp_bonus` returns `2` instead of `1` at level `>= 2` (not additive with L1 — the L2 text fully restates the bonus). `get_aura_damage_reduction(aura_source=self, defender, attacker, is_ranged)`: returns `1` if `defender` is an ally adjacent to `aura_source.position` (any attack type, not ranged-only, per "Adjacent allies take -1 damage from attacks").
- **L3 "Last Oath" (baked: `atk_bonus += 1`, `base_max_hp += 2`).** `intercept_lethal_damage`: if `not instance.ability_uses_this_match.get("last_oath_used", false)`: mark it used, return `{"triggered": true, "final_hp": 2}`; then (per Section 3.3's `intercept_lethal_damage` signature receiving `board`/`combat`) loop `board`'s 4 orthogonal neighbors of `instance.position`, and for each enemy found, call `combat.apply_damage(instance, <that enemy>, 1, false)` directly (this is the one place a handler calls `apply_damage` on damage it isn't itself the RulesEngine-dispatched attacker for — flagged as intentional, Section 9). Else return `{"triggered": false}`.

### 5.6 `r-engineer` — Winter Engineer (Specialist) — Barricade / Fortified Works / Frozen Redoubt

- **L1 (Activated ability, targets an adjacent empty tile or an adjacent barricade/object).** `get_legal_targets`: the 4 orthogonal neighbors of `instance.position`, each tagged as `"place"` (empty) or `"repair"` (holds a barricade/object below its max HP). `execute`: for `"place"`, `board.place_object(target_pos, "barricade", instance.player_id)`, then if `instance.level >= 2` immediately set the new `PlacedObjectInstance.current_hp`/an engineer-tracked max override to `3` instead of the registry default `2` (LLD-content-board.md Section 3.4.1's own flagged gap — this is exactly the "AbilitySystem may override `default_max_hp` per-instance at creation time" case that LLD anticipated); for `"repair"`, increment `current_hp` by `1`, capped at `3` if `instance.level >= 2` else `2`.
- **L2 "Fortified Works" (modifies the same ability; no baked stats).** `execute` accepts up to 2 target tiles per activation ("create or repair up to 2 adjacent").
- **L3 "Frozen Redoubt" (Standalone once-per-turn activated ability, `ability_id = "r-engineer_l3"`; baked: `base_max_hp += 1`).** `can_use` (for this second `ability_id`) checks `instance.level >= 3` and `not instance.ability_uses_this_turn.get("frozen_redoubt_used", false)`. `get_legal_targets`: any tile within 2 (not just adjacent). `execute`: either places a barricade (as above) or sets `board.get_tile(pos).terrain_type = "frost"` directly (`BoardTile`'s fields are public per LLD-content-board.md Section 3.4 — no new `BoardModel` setter needed); marks `ability_uses_this_turn["frozen_redoubt_used"] = true`. Also `get_aura_damage_reduction`: `1`, ranged-only, for allies adjacent to *any* placed object (own or ally-created) — `[NEED]` frost-tile movement semantics ("a character entering frost stops moving," from the Frozen Center event, BRD Section 13.2) are not implemented by `BoardModel.get_legal_moves()`'s BFS (LLD-content-board.md), which currently ignores `terrain_type` entirely. This is a real, cross-cutting gap (frost is created by both this ability and a future `RelicEventDeck` event) flagged here for a dedicated follow-up patch to that LLD's BFS, not solved inline.

### 5.7 `r-seer` — Frost Seer (Mystic) — Chill / Winter Veil / Deep Freeze

- **L1 (Activated ability, targets an enemy within range 3).** `get_legal_targets`: `get_tiles_in_range(instance.position, 3, "orthogonal_line")` filtered by LOS and enemy occupancy. `execute`: `combat.apply_damage(instance, target, 1, true)`; applies `StatusEffect(type="temp_move", value=-1, expires="next_turn")` and `StatusEffect(type="no_mount_dismount", expires="next_turn")` to the target. **Designer-approved 2026-09-25:** `"next_turn"` is now a real `expires` value (Section 3.4), with the two-phase clearing rule applied to `TurnManager.start_turn` in LLD-match-setup.md (same-date patch) — the card text's "on its next turn" is expressed directly instead of being approximated by `"this_turn"`/`"this_round"`.
- **L2 "Winter Veil" (modifies the same ability; no baked stats).** `execute` additionally applies `StatusEffect(type="shield", value=1, expires="this_turn")` and `StatusEffect(type="no_push", expires="this_turn")` to a player-chosen ally within 3 tiles.
- **L3 "Deep Freeze" (baked: `range_bonus += 1`).** `execute` additionally applies `StatusEffect(type="no_reaction", expires="next_turn")` to the target; "if the target already has a slow marker, it cannot move next turn" — implemented as: if the target already carries a `"temp_move"` effect with negative value from a prior Chill, apply a much larger negative `temp_move` (e.g. `-99`, clamped to `0` by `get_effective_move()`, whose floor at `0` is now stated explicitly in LLD-match-setup.md, same-date patch) instead of stacking.

### 5.8 `a-attendant` — Quartz Attendant (Common) — Synchronize / Shared Pulse / Collective Node

- **L1 (Passive, conditional self ATK).** `get_conditional_atk_bonus`: `1` if any other character adjacent to `instance.position` has `data.culture == "Atlantean"` **and** `player_id == instance.player_id` — **designer-confirmed 2026-09-25: Synchronize is ally-only.** An adjacent *enemy* Atlantean (possible in a mirror match, which `SetupFlow.select_culture` permits — LLD-match-setup.md Section 3.6) never triggers it. Both halves of the check are kept: the culture half is what the card text says, the ally half is what it means.
- **L2 "Shared Pulse" (baked: `base_max_hp += 1`).** `get_aura_damage_reduction(aura_source=self, defender, ...)`: `1` if `defender` is an adjacent Atlantean ally and `not aura_source.ability_uses_this_turn.get("shared_pulse_used", false)`; marks it used as a side effect of this query (Section 9 — a query with a mutating side effect, flagged as an accepted but slightly unusual pattern, necessary because "first damage each turn" has no other natural hook point).
- **L3 "Collective Node" (baked: `base_max_hp += 1`).** "Counts as a pylon and as adjacent to Atlanteans within 2 tiles" — **designer-approved 2026-09-25: this and Crystal Architect's pylon-adjacency (Section 5.13) get one joint design pass and one shared query, rather than two independently-invented mechanisms.** The shared query this LLD reserves for that pass: `AbilitySystem.is_pylon_source(pos: Vector2i, player_id: String) -> bool` — true if the tile holds a `"pylon"` placed object owned by `player_id`, OR a Level 3 Quartz Attendant belonging to `player_id`. Every "within N tiles of a pylon" check (Section 5.13's RANGE boost, Relay Gate's teleport endpoints, and Synchronize's own 2-tile adjacency at L3) calls this one predicate. The joint pass must settle two things this LLD does not decide alone: (a) whether a Collective Node counts as a pylon for the *enemy* Architect's Relay Gate (recommended: no — `player_id`-scoped, as the signature above assumes), and (b) whether a Collective Node can be targeted/destroyed the way a real pylon can (recommended: no — it is a character with its own HP, not an object). Tracked in Section 11 as a scheduled task, not an open blocker.

### 5.9 `a-glider` — Manta Glider (Mount) — Glide / Phase Current

- **L1 (Passive, movement modifier).** `get_movement_passable_predicate`: returns a closure that always returns `true` (unlimited passes, any occupied tile) — no per-move cap, unlike Gymnast's Vault. "If carrying a Hero/Leader, the mounted pair may also glide" is already satisfied structurally: `MountSystem.get_effective_movement_pattern`/movement queries resolve to the Mount's own handler (LLD-rules-engine.md v5, Section 4.2 step 1's `mover` redirection) — no extra logic needed here.
- **L2 (baked: `move_bonus += 1`; Reactive trigger).** `on_character_moved`: if `Section 4.2`'s `move_required_pass` is true for this move: apply `StatusEffect(type="temp_atk", value=1, expires="this_turn")` to `instance` directly (not an offered bonus — the card text doesn't give a choice, "next attack this turn gains +1 ATK" is automatic once earned).
- **L3 "Phase Current" (Standalone once-per-turn activated ability, `ability_id = "a-glider_l3"`; baked: `base_max_hp += 1`, `atk_bonus += 1`).** `get_movement_object_passable_predicate`: returns an always-`true` closure, but only when this specific ability is the active move mode (Section 9 — `AbilitySystem` needs a per-move "is Phase Current active for this move" flag, set by `execute` and consumed once by the next `_handle_move` call; flagged as needing a small additional coordination field, likely `instance.ability_uses_this_turn["phase_current_move_pending"]`, checked by `get_movement_object_passable_predicate` and cleared after one move). `execute`: no direct board effect itself — it arms the flag; the actual move happens through the normal `"move"` action next, and a reactive hook on that `character_moved` event (if the armed flag was set) deals `combat.apply_damage(instance, <one enemy moved over>, 1, false)` to a player-chosen enemy that was passed over, then clears the flag and marks `ability_uses_this_turn["phase_current_used"] = true`.

### 5.10 `a-guard` — Resonance Guard (Warrior) — Quartz Armor / Resonant Bastion

**Card text revised by the designer on 2026-09-25**: L2's former "Redirect" (a once-per-turn player choice to take damage for an adjacent ally) is removed outright, along with its choice mechanism, and L3 is rewritten. The old text was the one card in the roster that fit none of Section 3.1's four buckets — it needed a pre-damage interception with a live mid-resolution player decision, and a UI prompt no other card required. The replacement text expresses the same "protective anchor" role entirely through passives and one reactive trigger, with no new hook, no new decision point, and no `CombatResolver` pipeline change. Updated text: **L2 "+1 ATK. Adjacent allies also have Quartz Armor." / L3 "Resonant Bastion: When a character with Quartz Armor is attacked, deal 1 damage to the attacker."**

- **L1 (Passive, self damage reduction).** `get_own_damage_reduction(defender=self, attacker, is_ranged)`: `1` if `is_ranged`, else `0`.
- **L2 (Passive aura; baked: `atk_bonus += 1`).** `get_aura_damage_reduction(aura_source=self, defender, attacker, is_ranged)`: `1` if `is_ranged` and `aura_source.level >= 2` and `defender` is an ally orthogonally adjacent to `aura_source.position`, else `0`. "Adjacent allies *also have Quartz Armor*" means they gain the same effect Quartz Armor has — ranged damage reduced by 1 — so this composes through Section 4.1's existing self-plus-aura aggregation with no new hook and no new mechanism.
- **Quartz Armor as a queryable condition.** L3 keys off "a character with Quartz Armor," so `AbilitySystem` exposes one predicate rather than tracking a status effect that would need re-syncing on every move: `has_quartz_armor(character) -> bool` = `character.data.id == "a-guard"` (a Guard always has its own armor) OR (an allied Guard at `level >= 2` is orthogonally adjacent to `character`). Computed live from the board, exactly like every other adjacency-conditional bonus in this module (Section 3.5's rationale). The presentation layer reads the same predicate for a status badge (LLD-presentation.md) instead of polling for a `StatusEffect`.
- **L3 "Resonant Bastion" (Reactive trigger; no baked stats).** `on_attack_resolved` where `has_quartz_armor(<the defender>)` is true, the armor's source is this Guard (itself, or an adjacency it grants), and `instance.level >= 3`: `combat.apply_damage(instance, <attacker>, 1, false)`. Five rulings this LLD fixes, since the revised text is terse:
  1. **Any attack triggers it**, melee or ranged — unlike Quartz Armor's own reduction, the trigger text says "is attacked," not "ranged."
  2. **The attack does not need to have actually been reduced.** The old text's "after this character reduces damage" condition is gone, which also removes the awkward requirement to thread "was reduction applied" back out of `CombatResolver`.
  3. **No range condition on the attacker.** The old "within range 2" clause is gone; a Sniper at range 4 takes the reflect.
  4. **At most 1 reflect damage per attack**, even if the defender is adjacent to more than one armor source (not reachable in the current 1-Guard-per-side prototype, but fixed now so a future duplicate-Warrior squad doesn't silently double it).
  5. **Reflect damage is not an attack**, so it can never re-trigger another character's reflect, and cannot chain or recurse. It goes through `combat.apply_damage` with the Guard as source, so it *can* defeat the attacker — and if it does, the Guard receives a Spirit Ember per BR-023A, which is intended.

### 5.11 `a-conductor` — Divine Conductor (Leader) — Link Mind / Perfect Chord

- **L1 (Activated ability, targets 1 ally within 3 tiles).** `execute`: applies a `StatusEffect(type="los_ignore_ally_granted", value=1, expires="this_turn")` and a conceptual "may use Conductor's RANGE" grant — implemented as `StatusEffect(type="range_override", value=<Conductor's own get_effective_range("ability")>, expires="this_turn")` on the target, consumed by that target's own `get_conditional_range_bonus(..., context)` **only when `context == "ability"`** (Link Mind's text grants the Conductor's RANGE "for its ability," not for basic attacks — now expressible thanks to the same-date `context` parameter, Section 3.2). When it applies, the hook returns `override_value - instance.get_effective_range("ability")` so the *net* effective range becomes the override value rather than stacking. `get_line_of_sight_exceptions` (generic, checked for *every* character, Section 9): also scans for a `"los_ignore_ally_granted"` status effect and includes one blocking ally's id if present — this generalizes the same mechanism Sniper's innate L2 uses (Section 5.3), confirming the earlier design intent that LOS exceptions aggregate from both handler-innate and status-effect-granted sources.
- **L2 (2 targets within 3 tiles; no baked stats).**
- **L3 "Perfect Chord" (Reactive trigger; baked: `range_bonus += 1`).** Same shape as General's Tactical Mastery (Section 5.4) — tracks "linked this turn" via `target.ability_uses_this_turn["linked_by"] = instance.instance_id`, refreshes character AP (not a move) on `character_defeated`/`spirit_ember_delivered` for a linked ally, once per turn.

### 5.12 `a-hero` — Oracle Sovereign (Hero) — Foresight / Spirit Mantle / Collective Ascension

- **L1 (Activated ability, no board target — deck interaction).** `execute`: calls a forward-referenced `RelicEventDeck.peek_next() -> String` and `RelicEventDeck.move_peeked_to_bottom()` (LLD-07 contract this LLD defines the expectation for) based on a `payload["keep_on_top"]` choice; then applies a `"shield"` StatusEffect to a chosen adjacent ally.
- **L2 "Spirit Mantle" (Reactive trigger; no baked stats).** Hooks `turn_started` (a new `EventBus` subscription — since Resonant Bastion's start-of-turn shield was removed in the 2026-09-25 revision, Spirit Mantle is now the *only* consumer of it, Section 6) for `instance.player_id`'s own turn: applies `"shield"` to `instance` and one chosen adjacent ally. Also changes Foresight's default choice availability (`"leave on top"` becomes a valid `payload["keep_on_top"]` value at `L2+`; not available at `L1` per the text's phrasing "may instead leave... on top" as an L2 unlock).
- **L3 "Collective Ascension" (Standalone once-per-match activated ability, `ability_id = "a-hero_l3"`; baked: `base_max_hp += 1`, `range_bonus += 1`).** `can_use`: `instance.level >= 3` and `not instance.ability_uses_this_match.get("collective_ascension_used", false)`. `execute`: for every character in `GameState.match_state.get_player(instance.player_id).characters`: `current_hp = min(effective_max_hp, current_hp + 2)`, apply `"shield"` (value 1), apply `StatusEffect(type="temp_move", value=1, expires="this_turn")`; marks `ability_uses_this_match["collective_ascension_used"] = true`.

### 5.13 `a-architect` — Crystal Architect (Specialist) — Pylon / Relay Gate

- **L1 (Activated ability, targets an adjacent empty tile or moves an existing allied pylon).** `execute`: `board.place_object(pos, "pylon", instance.player_id)` or relocates one (clear old tile's object, place at new adjacent tile, preserving `current_hp`). Grants "+1 RANGE on abilities" to allies within 2 tiles of any owned pylon — implemented as `get_conditional_range_bonus(instance, board, match_state, context)` returning `1` when `context == "ability"` and `AbilitySystem.is_pylon_source(<a tile within 2>, instance.player_id)` is true (Section 5.8's shared predicate), else `0`. **Designer-approved 2026-09-25**: the hook now takes a `context` parameter (Section 3.2), so L1's abilities-only boost and L2's abilities-and-attacks boost are expressible directly instead of being collapsed together. The same parameter resolves LLD-relic-event-deck.md Section 9 item (e) (Crystal Tide) — one signature change, both cases.
- **L2 (pylon range 2, HP 2; extends to attacks too).** At `level >= 2` the same hook returns `1` for `context == "attack"` as well as `"ability"`. `place_object`'s created pylon gets `current_hp = 2` (per-instance override, same pattern as Winter Engineer's barricades, Section 5.6).
- **L3 "Relay Gate" (Standalone once-per-turn activated ability, `ability_id = "a-architect_l3"`; baked: `base_max_hp += 1`).** `get_legal_targets`: an ally adjacent to any owned pylon, teleporting to an empty tile adjacent to another owned pylon within 4 tiles. `execute`: relocates the target's `position` directly (`board.clear_occupant`/`set_occupant`, bypassing `get_legal_moves` entirely since this is a teleport, not a move — BR-010's "teleport... require[s] explicit rules text," which this ability has), then applies a `"shield"`.

### 5.14 `a-harmonic` — Astral Harmonic (Mystic) — Resonance Shield / Harmonic Bind / Astral Echo

- **L1 (Activated ability, targets an ally within 3 tiles).** `execute`: applies `StatusEffect(type="shield", value=<2 if target.is_mounted_rider else 1>, expires="this_round")` — "if that ally is mounted, the shield prevents 2 damage instead" reads as a property of the shield's size at grant time, not a live check, so it's baked into `value` once at application.
- **L2 "Harmonic Bind" (modifies the same ability; no baked stats).** Shield `value` becomes `2` unconditionally (superseding the mount check); also applies `StatusEffect(type="no_push", expires="this_turn")` to the target (reusing the same flag Winter Veil uses, Section 5.7 — confirms the flag is meant to be shared across characters, not Frost-Seer-specific).
- **L3 "Astral Echo" (Reactive trigger, immediate; baked: `range_bonus += 1`).** `execute` (extending L1/L2's own `execute`, not a separate reactive hook — the text describes an optional follow-up to the *same* activation, "after shielding an ally, may... "): after applying the shield, if `payload` includes an `"echo_target_id"` (an enemy within 2 tiles of the shielded ally), `combat.apply_damage(instance, <that enemy>, 1, false)`; the shielded ally additionally receives `StatusEffect(type="temp_move", value=1, expires="this_turn")` in lieu of a true "move without spending AP" grant (`[NEED]` a literal free-move grant would need the same `"<tag>_available"` + `reactive_bonus` pattern as General's Command, Section 5.4 — flagged as the more faithful implementation; the `temp_move` shortcut here is a simplification this LLD chose to avoid yet another per-character `reactive_bonus` tag, since the practical effect — one extra tile of movement available this turn — is very close, though not identical for a character that also gets a MOVE-affecting ability elsewhere).

## 6. Signal/Payload Specs

New `EventBus` subscriptions this module adds (beyond the four listed in `AbilitySystem._init`, Section 3.3): `turn_started` (Spirit Mantle only, Section 5.12 — Resonant Bastion's start-of-turn shield was removed in the 2026-09-25 card revision, Section 5.10) and, once `RelicEventDeck`/`LevelingSystem` exist, `spirit_ember_delivered` (Tactical Mastery, Perfect Chord — Section 5.4, 5.11). None of these are new signals — all are already defined in HLD Section 5.3; this LLD is simply the first to consume several of them.

`AbilitySystem` itself emits no new signals — every effect it causes goes through `CombatResolver`'s existing signals (`attack_resolved`, `character_defeated`) or through direct state mutation (`StatusEffect` application, `BoardModel` object placement) that the presentation layer (a later LLD) is expected to pick up by polling `CharacterInstance.status_effects`/`BoardModel` state after any `action_resolved`, the same way it already must for every other module's effects.

## 7. Error Handling & Edge Cases

| Scenario | Expected behavior | Source |
| --- | --- | --- |
| `execute_ability`/`execute_reactive_bonus` called for a character/tag combination its handler doesn't recognize | Base-class default `{"success": false, "reason": "no ... defined"}` (Section 3.2) — `RulesEngine` surfaces this as a normal action failure, not a crash | Section 3.2 |
| `can_use_ability` called with an `ability_id` that isn't `instance.data.id` or `"<id>_l3"` | Returns `false` (Section 3.3) — prevents a UI bug from invoking another character's ability through a mismatched id | Section 3.3 |
| A reactive hook fires for a character whose handler has no override for it | No-op (base class default, Section 3.2) — the overwhelming majority of (character, hook) pairs are exactly this, by design | Section 3.2 |
| Two characters' auras both try to grant a conditional bonus to the same target in the same query | Both contributions sum via `_aggregate` (Section 4.1) — no current card combination triggers this in the 14-card roster, but the aggregation is additive by construction, not exclusive | Section 4.1 |
| `AbilitySystem._get_handler` called for a `character_id` not in `AbilityRegistry`'s `match` | `push_error`, returns a base-class `AbilityHandler` (all-default, all no-ops) rather than `null` — every caller can treat the result as always-valid | Section 3.3 |
| A `StatusEffect` with `expires == "next_turn"` (Section 9's flagged gap) is never actually cleared because the required `TurnManager` patch hasn't landed yet | Effect persists indefinitely — a known, explicitly flagged limitation until the follow-up patch (Section 9) lands, not a silent bug | Section 9 |

## 8. Test Plan

Unit tests use **GUT**, one `test_*` per character's L1 behavior at minimum, plus targeted cases for the trickiest level-gated/reactive mechanics. `CombatResolver`/`MountSystem`/`RelicEventDeck`/`LevelingSystem` are doubled where this module calls into them.

| Case | Given | When | Then | BRD ID |
| --- | --- | --- | --- | --- |
| C1 | `r-gymnast` L1, ally at `(3,4)`, character at `(3,3)`, `move=3` | `get_movement_passable_predicate` used in `get_legal_moves` | Exactly one ally-occupied tile is passable; an enemy-occupied tile is not | BR-010 |
| C2 | `r-gymnast` L2 | Same, enemy-occupied tile | Now passable (any-occupied-tile rule) | Section 5.1 |
| C3 | `r-gymnast` L3, a move where `move_required_pass == true`, adjacent enemy present | `_on_character_moved` fires, then `request_action("reactive_bonus", ..., {"tag": "l3_bonus_attack", "target_id": ...})` | Doubled `combat.apply_damage` called with `(instance, target, 1, false)`; flag cleared after use | Section 5.1 |
| C4 | `r-tiger` L1, `is_mounted_rider... mounted_with_id == ""` (not carrying) | `can_use(instance, ...)` | Returns `true`; if `mounted_with_id != ""` (has a rider) — `[NEED]` confirm this doesn't block Pounce (text says "while not mounted" referring to the Tiger being ridden, not carrying — Section 9) | Section 5.2 |
| C5 | `r-tiger` L2, Pounce executed then the marked attack resolves | `on_attack_resolved` fires | `combat.apply_push` called with distance `1` | Section 5.2 |
| C6 | `r-sniper`, `ability_uses_this_turn["moved"]` unset | `get_conditional_range_bonus(instance, "attack")` | Returns `1` | Section 5.3 |
| C7 | `r-sniper`, `ability_uses_this_turn["moved"] == true` | Same | Returns `0` | Section 5.3 |
| C7A | `r-sniper` L1, not moved this turn | `get_conditional_range_bonus(instance, "ability")` | Returns `0` — Aim is attack-context only | Section 5.3 |
| C8 | `r-sniper` L2, one allied tile on the line to target | `get_line_of_sight_exceptions(instance, target_pos, board)` | Returns exactly that ally's `instance_id` | Section 5.3 |
| C9 | `r-general` L1, target chooses `"atk"` | `execute` | Target gains a `temp_atk` status effect, `value == 1` | Section 5.4 |
| C10 | `r-hero` L1, `instance.position` adjacent to center | `get_own_conditional_max_hp_bonus(instance, board)` | Returns `1` | Section 5.5 |
| C11 | `r-hero` L3, lethal damage incoming, not yet used this match | `intercept_lethal_damage(instance, board, combat_double)` | `{"triggered": true, "final_hp": 2}`; doubled `combat.apply_damage` called once per adjacent enemy | Section 5.5 |
| C12 | `r-hero` L3, already used this match | Same | `{"triggered": false}` | Section 5.5 |
| C13 | `r-engineer` L1, adjacent empty tile | `execute` | `board.place_object` called with `type_id == "barricade"` | Section 5.6 |
| C14 | `r-engineer` L2 | Same | Created barricade's effective max HP is `3`, not the registry default `2` | Section 5.6 |
| C15 | `r-seer` L1, enemy at range 3, clear LOS | `execute` | Doubled `combat.apply_damage(instance, target, 1, true)` called; target gains `temp_move` value `-1` | Section 5.7 |
| C16 | `a-attendant` L1, adjacent Atlantean ally present | `get_conditional_atk_bonus(instance)` | Returns `1` | Section 5.8 |
| C16A | `a-attendant` L1, the only adjacent Atlantean belongs to the *opponent* (mirror match) | Same | Returns `0` — Synchronize is ally-only | Section 5.8 |
| C17 | `a-glider` L1 | `get_movement_passable_predicate` | Returns a closure that accepts an arbitrary number of occupied tiles (no cap), unlike Gymnast's | Section 5.9 |
| C18 | `a-guard` L1, ranged attack incoming | `get_own_damage_reduction(defender, attacker, is_ranged=true)` | Returns `1` | Section 5.10 |
| C18A | `a-guard` L2, an ally orthogonally adjacent to it, ranged attack incoming at that ally | `get_aura_damage_reduction(guard, ally, attacker, is_ranged=true)` | Returns `1`; returns `0` for a melee (`is_ranged=false`) attack and `0` for a non-adjacent ally | Section 5.10 |
| C18B | `a-guard` L3, an adjacent ally (armored by the Guard) is attacked in melee by an enemy 1 tile away | `on_attack_resolved` fires | Doubled `combat.apply_damage(guard, attacker, 1, false)` called exactly once; no second reflect fires from the reflect damage itself | Section 5.10 |
| C18C | `a-guard` L2 (not yet L3), same setup as C18B | `on_attack_resolved` fires | No reflect damage — the reflect is an L3 effect | Section 5.10 |
| C19 | `a-conductor` L1, ally linked | `execute`, then that ally's `get_conditional_range_bonus(ally, "ability")` | Reflects the Conductor's own `get_effective_range("ability")` as an override, not an addition; the same query with `"attack"` is unaffected by the link | Section 5.11 |
| C20 | `a-hero` L1, `payload["keep_on_top"] == false` | `execute` | Doubled `RelicEventDeck.move_peeked_to_bottom` called | Section 5.12 |
| C21 | `a-hero` L3, once per match | `execute` twice in the same match | Second call's `can_use` returns `false` | Section 5.12 |
| C22 | `a-architect` L1, pylon within 2 tiles of an ally | `get_conditional_range_bonus(ally, "ability")` | Returns `1` | Section 5.13 |
| C22A | Same board state | `get_conditional_range_bonus(ally, "attack")` | Returns `0` at Architect L1, `1` at Architect L2 | Section 5.13 |
| C22B | `r-sniper` with a doubled defender carrying 2 points of damage reduction | Sniper L2 attacks it | `CombatResolver` applies exactly 1 point of reduction (2 − 1 ignored); shields are unaffected | Section 5.3 |
| C23 | `a-harmonic` L1, target not mounted | `execute` | Applied shield `value == 1` | Section 5.14 |
| C24 | `a-harmonic` L1, target mounted (`is_mounted_rider == true`) | `execute` | Applied shield `value == 2` | Section 5.14 |
| C25 | `a-harmonic` L2 | `execute` | Shield `value == 2` regardless of mount status; target also gains `no_push` | Section 5.14 |

## 9. Open Implementation Questions

This module surfaced more genuine ambiguities than any other so far, consistent with it covering the entire hand-authored card text corpus. The designer review of 2026-09-25 closed seven of them; those are recorded below as resolutions (not deleted, so the reasoning behind each ruling stays traceable), followed by the items still open.

**Resolved 2026-09-25:**

- **Ability classification framework (Section 3.1) — confirmed.** The four buckets are accepted as the shared vocabulary, with one correction applied: a bucket is determined by what *causes* an ability, not by its use cap. The old fourth bucket name ("standalone once-per-turn/match activated ability") embedded the cap in the bucket name and is renamed to **standalone activated ability**. HLD Section 4.6 and BRD BR-021A/BR-021B/FR-045I updated to match.
- **AP cost of standalone abilities — confirmed: they cost AP.** A once-per-match ability (Collective Ascension) still costs 1 pool AP + 1 character AP, as do Frozen Redoubt and Phase Current, unless a card explicitly says the effect is free. The use cap is an additional gate, not a substitute for the cost.
- **Sniper's Piercing Shot (Section 5.3) — resolved: it ignores exactly 1 point of damage reduction.** No attacker choice, no shield interaction, and no "ignore all reduction": a defender with 2 points of reduction still applies 1. Card text updated across PRD/BRD/`characters.json` to "ignores 1 point of damage reduction" so the rules text and the implementation agree.
- **Resonance Guard's Redirect (Section 5.10) — resolved by removing it.** The card is rewritten (L2 "+1 ATK. Adjacent allies also have Quartz Armor." / L3 "When a character with Quartz Armor is attacked, deal 1 damage to the attacker."), which deletes the only card in the roster needing a mid-resolution player decision. No pre-damage interception hook, no `get_redirect_target`, and no reactive UI prompt concept is needed anywhere in the codebase.
- **`StatusEffect.expires` gap — resolved: `"next_turn"` is approved.** Added to the vocabulary (Section 3.4) with two-phase clearing in `TurnManager.start_turn`, patched into LLD-match-setup.md the same day. Chill, Deep Freeze, and every future opponent's-next-turn effect now say what they mean.
- **Quartz Attendant's Synchronize (Section 5.8) — resolved: ally-only.** The check is `culture == "Atlantean"` AND `player_id == instance.player_id`.
- **`get_conditional_range_bonus` `context` parameter — approved and applied** (Section 3.2). Pylon's L1-vs-L2 distinction, Link Mind's ability-only RANGE grant, Aim's attack-only bonus, and the Crystal Tide event (LLD-relic-event-deck.md Section 9 item (e)) all resolve through this one signature change.

**Scheduled, not blocking:**

- **Pylon-equivalence joint design pass (Sections 5.8, 5.13) — approved as a single pass with a single shared predicate** (`AbilitySystem.is_pylon_source`). Two sub-decisions are deferred into that pass and named in Section 5.8 (does a Collective Node count as a pylon for the *enemy* Architect; is it destructible the way a pylon is). Tracked in Section 11.
- **Ability text is expected to churn during playtesting** (designer direction, 2026-09-25). Section 3.6 records the design commitments that keep that cheap — tunable magnitudes in `characters.json` rather than in handler code, one handler file per card, and re-classifying into the four buckets as the first step of any rewrite.

**Still open:**

- **`AbilitySystem` as an `EventBus` listener is a new architectural pattern** relative to `BoardModel`/`CombatResolver`/`MountSystem` (all pure query/mutation surfaces with no signal subscriptions). This is a deliberate, HLD-compatible choice (HLD Section 5.3's signals are broadcast for exactly this kind of consumption, and `LevelingSystem` already does the same) rather than a violation of any stated module boundary — flagged for visibility, not as a problem.
- **Several handler methods (`get_own_conditional_max_hp_bonus` for Bogatyr Champion's HP-change-on-move, Shared Pulse's once-per-turn reduction) have side effects inside what reads as a query method.** Accepted as necessary given the game's actual trigger points, but worth a second look during implementation in case a cleaner split between "query" and "apply" emerges once real code is written.
- *(Closed 2026-09-25)* `get_effective_move()`'s floor at `0` is now stated explicitly in LLD-match-setup.md.
- **This LLD assumes `CombatResolver`'s `apply_damage`/`apply_push` accept being called directly by an `AbilityHandler` outside of the normal `RulesEngine → CombatResolver` path** (Chill's direct damage, Last Oath's counter-damage, Phase Current's move-over damage, Astral Echo's follow-up damage) — already anticipated and allowed by LLD-combat-mount.md Section 3.1's own doc comment ("used by `resolve_attack()` above AND by `AbilitySystem`"), so no further patch needed, just confirming the usage matches that stated intent.

## 10. Traceability

| LLD Section | HLD Section | BRD/PRD IDs |
| --- | --- | --- |
| 3.1–3.3 Architecture | HLD 4.6 | FR-037, FR-043, FR-045I |
| 5.1–5.14 Per-character specs | HLD 4.6, BRD Section 12 | FR-038–FR-045A |
| 4.1 Aggregation pattern | HLD 4.5, 4.6 | FR-036, NFR-012 |
| Section 9 open questions | BRD Section 14 (risk-equivalent) | R-003 (leveling worth pursuing), NFR-013 |

## 11. Next Steps

1. Add `scripts/systems/abilities/ability_handler.gd`, `ability_registry.gd`, and all 14 per-character handler files (Section 3.2–3.3, Section 5).
2. Add `scripts/systems/ability_system.gd`; wire it to be instantiated by `RulesEngine` alongside `CombatResolver`/`MountSystem` at match start, connected to `EventBus` per Section 3.3's `_init`.
3. Apply the remaining follow-up patches before relying on them in playtesting: (a) Gymnast's L2 "+1 extra tile after vaulting" `RulesEngine` branch (Section 5.1), (b) frost-tile movement semantics in `BoardModel.get_legal_moves()` (Section 5.6). Items (c) `"next_turn"` and (d) Resonance Guard's Redirect from the v1 list are closed — (c) is applied in LLD-match-setup.md, (d) no longer exists as a mechanic (Section 5.10).
4. Thread the `context` parameter through the two call sites that resolve range: `RulesEngine._handle_attack` passes `"attack"`, `_handle_ability` passes `"ability"` (LLD-rules-engine.md follow-up), and `CharacterInstance.get_effective_range(context)` (LLD-match-setup.md, patched same day).
5. Run the pylon-equivalence joint design pass (Sections 5.8, 5.13) before implementing either Collective Node or Relay Gate; settle the two sub-decisions named in Section 5.8, then implement `is_pylon_source` once.
6. Write `tests/unit/test_ability_system.gd`; confirm C1–C25 plus C7A/C16A/C18A–C18C/C22A/C22B with doubles for `CombatResolver`/`MountSystem`/`RelicEventDeck`/`LevelingSystem`.
7. Before the next balance pass, move the magnitudes the handlers currently hardcode into `characters.json` ability-rules data (Section 3.6) — this is what makes a between-playtest rebalance a content edit instead of a code change.
