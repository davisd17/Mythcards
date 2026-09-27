extends AbilityHandler
# Manta Glider (Mount) — Glide / Phase Current (LLD-ability-system 5.9).
# L1 Glide: may move over any number of occupied tiles, ending on an empty one. A Hero
#    or Leader riding it glides too (a mounted pair uses the Mount's movement rules).
# L2: +1 MOVE; after moving over a character, its next attack this turn gains +1 ATK.
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
	if mover == instance and instance.level >= 2 and required_pass:
		sys.add_status(instance, "temp_atk", GLIDE_ATK, "this_turn", instance, true)


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


# Enemies the Glider can pass over on its way to `to`. With everything passable, a
# route through a tile exists exactly when the detour fits the MOVE budget.
func _moved_over(sys, instance: CharacterInstance, to: Vector2i) -> Array[String]:
	var result: Array[String] = []
	var budget := instance.get_effective_move()
	for enemy in sys.enemies_of(instance):
		if enemy.position == to:
			continue
		if sys.distance(instance.position, enemy.position) + sys.distance(enemy.position, to) <= budget:
			result.append(enemy.instance_id)
	return result
