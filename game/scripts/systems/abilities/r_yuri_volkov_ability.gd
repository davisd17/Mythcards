extends AbilityHandler
# Major Yuri Volkov (Closed City Warrior) — LLD-closed-city-flood-roster.md 4.
# L1 Containment Shot (AP): 1 damage to an enemy within 3. If the target is adjacent to
#    a Leak marker, it also becomes Marked. Payload: {"target": enemy id}.
# L2 Pressure-Sealed Armor: +1 HP.
# L3 Seal The Breach: +1 ATK; Containment Shot may also target along diagonal lines
#    (within 3, nothing in between).

const SHOT_REACH := 3
const SHOT_DAMAGE := 1
const DIAGONALS := [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]


func level_bonuses() -> Dictionary:
	return {2: {"hp": 1}, 3: {"atk": 1}}


func ability_label(_instance: CharacterInstance, _ability_id: String) -> String:
	return "Containment Shot"


func can_use(_sys, _instance: CharacterInstance, _ability_id: String) -> bool:
	return true


func get_legal_targets(sys, instance: CharacterInstance, _ability_id: String) -> Array:
	var reach: int = sys.ability_reach(instance, SHOT_REACH)
	var result: Array = sys.characters_in_reach(instance, instance.position, reach, false)
	if instance.level >= 3:
		for id in _diagonal_targets(sys, instance, reach):
			if not result.has(id):
				result.append(id)
	return result


func next_step(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if payload.has("target"):
		return {}
	return target_step("target", "Containment Shot: which enemy?", get_legal_targets(sys, instance, ability_id))


func execute(sys, instance: CharacterInstance, _ability_id: String, payload: Dictionary) -> Dictionary:
	var target: CharacterInstance = sys.find(str(payload.target))
	var near_leak: bool = sys.neighbors(target.position).any(func(pos): return sys.has_leak(pos))
	var hit: Dictionary = sys.combat().apply_damage(instance, target, SHOT_DAMAGE,
			sys.distance(instance.position, target.position) > 1)
	if near_leak and not hit.defeated:
		sys.add_status(target, "marked", 1, "until_used", instance)
	return {"success": true, "damage": hit.damage, "defeated": hit.defeated}


# Enemies on the four diagonals within `reach`, with every tile between them empty.
func _diagonal_targets(sys, instance: CharacterInstance, reach: int) -> Array[String]:
	var result: Array[String] = []
	for dir in DIAGONALS:
		var pos: Vector2i = instance.position
		for _step in reach:
			pos += dir
			if not sys.board.is_in_bounds(pos):
				break
			var c: CharacterInstance = sys.occupant(pos)
			if c != null:
				if c.player_id != instance.player_id:
					result.append(c.instance_id)
				break
			if sys.board.blocks_line_of_sight(pos):
				break
	return result
