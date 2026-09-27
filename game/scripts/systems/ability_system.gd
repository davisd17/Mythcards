class_name AbilitySystem
extends RefCounted
# Baseline for HLD build step 10: every query returns the no-ability default (orthogonal
# movement, orthogonal-line attacks, no pass-through, no LOS exceptions, no stat bonus,
# no damage reduction or penetration, no lethal-damage interception), and no character
# has a usable AP ability yet. The per-character handlers from
# LLD-ability-system.md replace these answers without changing the signatures, which
# are the contract RulesEngine calls (LLD-rules-engine.md Section 9).

var board: BoardModel


func _init(p_board: BoardModel) -> void:
	board = p_board


func get_movement_pattern(_instance: CharacterInstance) -> String:
	return "orthogonal"


func get_movement_passable_predicate(_instance: CharacterInstance) -> Callable:
	return Callable()


func get_movement_object_passable_predicate(_instance: CharacterInstance) -> Callable:
	return Callable()


func get_attack_pattern(_instance: CharacterInstance) -> String:
	return "orthogonal_line"


func get_line_of_sight_exceptions(_instance: CharacterInstance, _target_pos: Vector2i,
		_board: BoardModel) -> Array[String]:
	return []


func get_conditional_range_bonus(_instance: CharacterInstance, _context: String) -> int:
	return 0


func get_conditional_atk_bonus(_instance: CharacterInstance) -> int:
	return 0


func get_passive_damage_reduction(_defender: CharacterInstance, _attacker: CharacterInstance,
		_is_ranged: bool) -> int:
	return 0


func get_penetration(_instance: CharacterInstance) -> Dictionary:
	return {"ignore_reduction": 0, "ignore_shield": 0}


func intercept_lethal_damage(_defender: CharacterInstance, _combat: CombatResolver) -> Dictionary:
	return {"triggered": false}


func can_use_ability(_instance: CharacterInstance, _ability_id: String) -> bool:
	return false


func get_legal_ability_targets(_instance: CharacterInstance, _ability_id: String) -> Array:
	return []


func execute_ability(_instance: CharacterInstance, _ability_id: String, _target) -> Dictionary:
	return {"success": false, "reason": "abilities arrive in build step 10"}


func execute_reactive_bonus(_instance: CharacterInstance, _tag: String, _payload: Dictionary) -> Dictionary:
	return {"success": false, "reason": "abilities arrive in build step 10"}
