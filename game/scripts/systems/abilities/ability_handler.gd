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


func on_character_defeated(_sys, _instance: CharacterInstance, _fallen: CharacterInstance,
		_defeated_by: CharacterInstance) -> void:
	pass


func on_spirit_ember_delivered(_sys, _instance: CharacterInstance, _carrier: CharacterInstance) -> void:
	pass


func on_turn_started(_sys, _instance: CharacterInstance, _player_id: String) -> void:
	pass


func execute_reactive_bonus(_sys, _instance: CharacterInstance, _tag: String, _payload: Dictionary) -> Dictionary:
	return {"success": false, "reason": "no reactive bonus defined for this tag"}
