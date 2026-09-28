extends AbilityHandler
# Manta Glider (Mount) — Glide / Phase Current (LLD-ability-system 5.9).
# L1 Glide: may move over any number of occupied tiles, ending on an empty one. A Hero
#    or Leader riding it glides too (a mounted pair uses the Mount's movement rules).
# L2: +1 MOVE; after moving over a character, its next attack gains +1 ATK (lasts until
#    that attack, not just this turn — designer ruling 2026-09-27).
# L3 Phase Current: +1 HP, +1 ATK. Standalone ability "a-glider_l3", once per turn: a
#    move that ignores terrain, barricades, and occupied tiles, dealing 1 damage to one
#    enemy moved over. The ability IS the move (1 AP covers both; every character has
#    1 AP a turn). Payload: {"to": pos, "over_id": optional enemy id}.

const L3_ID := "a-glider_l3"
const GLIDE_ATK := 1
const PHASE_CURRENT_DAMAGE := 1


func level_bonuses() -> Dictionary:
	return {2: {"move": 1}, 3: {"hp": 1, "atk": 1}}


func get_movement_passable_predicate(_sys, _instance: CharacterInstance) -> Callable:
	return func(_pos: Vector2i) -> bool: return true


func on_character_moved(sys, instance: CharacterInstance, mover: CharacterInstance,
		_from: Vector2i, _to: Vector2i, required_pass: bool) -> void:
	if mover != instance or instance.level < 2 or not required_pass:
		return
	# Lasts until the Glider's next attack, even on a later turn (designer ruling
	# 2026-09-27); gliding again before attacking doesn't stack it.
	for se in instance.status_effects:
		if se.type == "temp_atk" and se.expires == "until_used" and se.source_character_id == instance.instance_id:
			return
	sys.add_status(instance, "temp_atk", GLIDE_ATK, "until_used", instance, true)


func ability_ids(instance: CharacterInstance) -> Array[String]:
	return [L3_ID]


func can_use(sys, instance: CharacterInstance, _ability_id: String) -> bool:
	return instance.level >= 3 and not sys.used_this_turn(instance, "phase_current_used")


func get_legal_targets(sys, instance: CharacterInstance, _ability_id: String) -> Array:
	var anything := func(_pos: Vector2i) -> bool: return true
	return sys.board.get_legal_moves(instance.position, instance.get_effective_move(), "orthogonal",
			anything, anything, -1, true)


func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	if not get_legal_targets(sys, instance, ability_id).has(payload.get("to")):
		return "illegal move"
	if payload.has("over_id") and not _moved_over(sys, instance, payload.to).has(str(payload.over_id)):
		return "that enemy isn't on the way"
	return ""


func execute(sys, instance: CharacterInstance, _ability_id: String, payload: Dictionary) -> Dictionary:
	instance.ability_uses_this_turn["phase_current_used"] = true
	var over: CharacterInstance = sys.find(str(payload.get("over_id", "")))
	var plain: Array[Vector2i] = sys.board.get_legal_moves(instance.position, instance.get_effective_move())
	sys.move_character(instance, payload.to)
	instance.ability_uses_this_turn["last_move_required_pass"] = not plain.has(payload.to)
	var result := {"success": true}
	if over != null:
		var hit: Dictionary = sys.combat().apply_damage(instance, over, PHASE_CURRENT_DAMAGE, false)
		result["damage"] = hit.damage
		result["defeated"] = hit.defeated
	return result


# Enemies on the tiles the Glider crosses on its straight line to `to`.
func _moved_over(sys, instance: CharacterInstance, to: Vector2i) -> Array[String]:
	var result: Array[String] = []
	for pos in BoardModel.tiles_between(instance.position, to):
		var c: CharacterInstance = sys.occupant(pos)
		if c != null and c.player_id != instance.player_id:
			result.append(c.instance_id)
	return result


func ability_label(_instance: CharacterInstance, _ability_id: String) -> String:
	return "Phase Current"


func next_step(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if not payload.has("to"):
		return target_step("to", "Phase Current: move to which tile?", get_legal_targets(sys, instance, ability_id))
	if payload.has("over_id"):
		return {}
	var over := _moved_over(sys, instance, payload.to)
	return {} if over.is_empty() else target_step("over_id", "Deal 1 damage to which enemy you passed?", over, true)
