class_name AbilityHandler
extends RefCounted
# One subclass per character (LLD-ability-system.md 3.2). Every hook defaults to "no
# effect", so a handler overrides only what its card text needs. Every hook receives the
# match's AbilitySystem (`sys`), which carries the board, combat, and shared helpers.
#
# Buckets (LLD 3.1): passive modifiers are query hooks; activated abilities go through
# can_use/get_legal_targets/validate/execute and cost AP; reactive triggers are the on_*
# hooks; a free follow-up they offer is consumed by execute_reactive_bonus.


# Permanent stat increases per level, baked into the instance at level-up (LLD 3.5).
# Shape: {2: {"hp": 1, "atk": 0, "move": 1, "range": 0}, 3: {...}}.
func level_bonuses() -> Dictionary:
	return {}


# Level-up side effects beyond the stat bonuses (e.g. raising existing barricades' max HP).
func on_level_up(_sys, _instance: CharacterInstance, _new_level: int) -> void:
	pass


# --- Movement ------------------------------------------------------------------

func get_movement_passable_predicate(_sys, _instance: CharacterInstance) -> Callable:
	return Callable()


func get_movement_object_passable_predicate(_sys, _instance: CharacterInstance) -> Callable:
	return Callable()


func get_movement_max_passes(_sys, _instance: CharacterInstance) -> int:
	return -1


# Cap on characters passed in one move, on top of get_movement_max_passes (-1 = no extra
# cap). Ahesu L2 passes any number of allied Stones but only 1 ally.
func get_movement_max_char_passes(_sys, _instance: CharacterInstance) -> int:
	return -1


# Extra destinations beyond the normal move (Gymnast L2: 1 extra tile after vaulting).
func get_bonus_move_tiles(_sys, _instance: CharacterInstance, _from: Vector2i, _budget: int) -> Array[Vector2i]:
	return []


# --- Attack / targeting --------------------------------------------------------

func get_line_of_sight_exceptions(_sys, _instance: CharacterInstance, _target_pos: Vector2i) -> Array[String]:
	return []


func get_penetration(_sys, _instance: CharacterInstance) -> Dictionary:
	return {"ignore_reduction": 0, "ignore_shield": 0}


# --- Damage / defense ----------------------------------------------------------

func get_own_damage_reduction(_sys, _defender: CharacterInstance, _attacker: CharacterInstance, _is_ranged: bool) -> int:
	return 0


func get_aura_damage_reduction(_sys, _source: CharacterInstance, _defender: CharacterInstance,
		_attacker: CharacterInstance, _is_ranged: bool) -> int:
	return 0


func intercept_lethal_damage(_sys, _instance: CharacterInstance, _combat) -> Dictionary:
	return {"triggered": false}


# --- Conditional (live) stat bonuses — never baked into the instance -------------

func get_conditional_atk_bonus(_sys, _instance: CharacterInstance) -> int:
	return 0


func get_conditional_range_bonus(_sys, _instance: CharacterInstance, _context: String) -> int:
	return 0


func get_aura_range_bonus(_sys, _source: CharacterInstance, _target: CharacterInstance, _context: String) -> int:
	return 0


func get_own_conditional_max_hp_bonus(_sys, _instance: CharacterInstance) -> int:
	return 0


# --- Activated abilities -------------------------------------------------------

# Ability ids this character owns: its own id for the L1 ability, "<id>_l3" for a
# standalone Level 3 ability.
func ability_ids(instance: CharacterInstance) -> Array[String]:
	return [instance.data.id]


func can_use(_sys, _instance: CharacterInstance, _ability_id: String) -> bool:
	return false


# Primary targets, for UI previews. Tiles or character ids depending on the ability.
func get_legal_targets(_sys, _instance: CharacterInstance, _ability_id: String) -> Array:
	return []


# "" if the payload is a legal use, else the reason. Default: payload.target must be one
# of get_legal_targets.
func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	if not get_legal_targets(sys, instance, ability_id).has(payload.get("target")):
		return "illegal ability target"
	return ""


func execute(_sys, _instance: CharacterInstance, _ability_id: String, _payload: Dictionary) -> Dictionary:
	return {"success": false, "reason": "no AP ability defined for this character"}


# --- Closed City / Flood Survivors hooks (LLD-closed-city-flood-roster.md 3) ------------

# Never triggers Leaks: no damage, and the Leak stays (Reactor Worker).
func ignores_leaks(_sys, _instance: CharacterInstance) -> bool:
	return false


# Max HP this Mount gives whoever rides it (VERA-7: Protected Passenger).
func get_rider_max_hp_bonus(_sys, _mount: CharacterInstance, _rider: CharacterInstance) -> int:
	return 0


# How many Memory markers this character may hold (Sahu-Ren: 3).
func memory_max(_instance: CharacterInstance) -> int:
	return 1


# After every damage instance, including fully prevented ones. `incoming` is the amount
# before reductions, shields, and Memory; `final` is what was taken. attacker == damaged
# for hazard damage (Leaks).
func on_character_damaged(_sys, _instance: CharacterInstance, _damaged: CharacterInstance,
		_attacker: CharacterInstance, _incoming: int, _final: int) -> void:
	pass


# A character spent Memory to prevent damage.
func on_memory_spent(_sys, _instance: CharacterInstance, _holder: CharacterInstance,
		_attacker: CharacterInstance) -> void:
	pass


# Free bonuses offered by live state rather than a stored flag (checked on demand).
func offered_bonuses(_sys, _instance: CharacterInstance) -> Array[String]:
	return []


# An off-board character returning (Slumber, Missing In The Signal): steps after the
# return tile is chosen, and what happens once it's back.
func return_step(_sys, _instance: CharacterInstance, _payload: Dictionary) -> Dictionary:
	return {}


func on_returned(_sys, _instance: CharacterInstance, _payload: Dictionary) -> void:
	pass


# --- AI (LLD-ai-opponent.md 4) -------------------------------------------------------

# What one use is worth to the AI, in AIEvaluator points. `ability_id` is the ability, or
# "bonus:<tag>" for a free bonus. `ai` is the AIEvaluator (value_of, danger, preview,
# damage_value, enemies_near, personality). The default keeps every card playable by the
# AI: a modest flat value, plus the damage it would deal if the payload names an enemy.
func ai_value(sys, instance: CharacterInstance, _ability_id: String, payload: Dictionary, ai) -> float:
	var v: float = ai.personality.w("ability_default", 0.5)
	var target: CharacterInstance = sys.find(str(payload.get("target", payload.get("target_id", ""))))
	if target != null and target.player_id != instance.player_id:
		v += ai.damage_value(instance, target, ai.preview(instance, target, 1)) * 0.5
	return v


# --- Targeting steps, for the tap-driven game screen ------------------------------
# The game screen builds a payload one pick at a time. next_step returns the next thing
# to pick given the picks so far, or {} when `payload` is ready to send. A step is
# {key, prompt, pick: "tile"|"character"|"option", tiles | characters | options
# ([{label, value}]), optional}. The screen stores the pick at payload[key], or null when
# an optional step is skipped (so has(key) means "decided"); nulls are dropped before
# the action is sent.

func ability_label(_instance: CharacterInstance, _ability_id: String) -> String:
	return "Ability"


func next_step(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if payload.has("target"):
		return {}
	var legal := get_legal_targets(sys, instance, ability_id)
	return {} if legal.is_empty() else target_step("target", "Choose a target.", legal)


func bonus_label(tag: String) -> String:
	return tag.capitalize()


func bonus_step(_sys, _instance: CharacterInstance, _tag: String, _payload: Dictionary) -> Dictionary:
	return {}


# A tile or character pick, whichever `legal` holds.
static func target_step(key: String, prompt: String, legal: Array, optional: bool = false) -> Dictionary:
	var tiles := not legal.is_empty() and legal[0] is Vector2i
	var step := {"key": key, "prompt": prompt, "pick": "tile" if tiles else "character", "optional": optional}
	step["tiles" if tiles else "characters"] = legal
	return step


static func option_step(key: String, prompt: String, options: Array, optional: bool = false) -> Dictionary:
	return {"key": key, "prompt": prompt, "pick": "option", "options": options, "optional": optional}


# A second optional pick of the same kind (L2 "up to 2" abilities), or {} if none is left.
static func second_step(key: String, prompt: String, legal: Array, first) -> Dictionary:
	var rest := legal.filter(func(v): return v != first)
	return {} if rest.is_empty() else target_step(key, prompt, rest, true)


# --- Reactive triggers -----------------------------------------------------------

# Every live character's handler hears these; check ids against `instance` yourself.
func on_character_moved(_sys, _instance: CharacterInstance, _mover: CharacterInstance,
		_from: Vector2i, _to: Vector2i, _required_pass: bool) -> void:
	pass


func on_character_repositioned(_sys, _instance: CharacterInstance, _moved: CharacterInstance) -> void:
	pass


func on_attack_resolved(_sys, _instance: CharacterInstance, _attacker: CharacterInstance,
		_target: CharacterInstance, _damage: int, _defeated: bool) -> void:
	pass


# A basic attack on a placed object (no character target).
func on_object_attacked(_sys, _instance: CharacterInstance, _attacker: CharacterInstance,
		_pos: Vector2i, _destroyed: bool) -> void:
	pass


func on_character_defeated(_sys, _instance: CharacterInstance, _fallen: CharacterInstance,
		_defeated_by: CharacterInstance) -> void:
	pass


func on_spirit_ember_delivered(_sys, _instance: CharacterInstance, _carrier: CharacterInstance) -> void:
	pass


func on_turn_started(_sys, _instance: CharacterInstance, _player_id: String) -> void:
	pass


func execute_reactive_bonus(_sys, _instance: CharacterInstance, _tag: String, _payload: Dictionary) -> Dictionary:
	return {"success": false, "reason": "no reactive bonus defined for this tag"}
