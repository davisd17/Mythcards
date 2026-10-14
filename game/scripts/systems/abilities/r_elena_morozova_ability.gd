extends AbilityHandler
# Dream Link swaps a nearby ally with a character anywhere on the board.
# At Level 3 the second character may be an enemy. Mounted pairs travel together.


func level_bonuses() -> Dictionary:
	return {3: {"hp": 1}}


func ability_label(_instance: CharacterInstance, _ability_id: String) -> String:
	return "Dream Link"


func can_use(_sys, _instance: CharacterInstance, _ability_id: String) -> bool:
	return true


func get_legal_targets(sys, instance: CharacterInstance, _ability_id: String) -> Array:
	var reach: int = sys.ability_reach(instance, 2 if instance.level == 1 else 4)
	return sys.characters_in_reach(instance, instance.position, reach, true)


func _partners(sys, instance: CharacterInstance, first: CharacterInstance) -> Array:
	var result := []
	for c in sys.live_characters():
		if c == first or sys.occupant(c.position) != c:
			continue
		if c.player_id == instance.player_id or (instance.level >= 3 and not c.has_status("no_push")):
			result.append(c.instance_id)
	return result


func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	if not get_legal_targets(sys, instance, ability_id).has(str(payload.get("target", ""))):
		return "choose an allied character in range"
	if not _partners(sys, instance, sys.find(str(payload.target))).has(str(payload.get("other", ""))):
		return "choose a different allied character" if instance.level < 3 else "choose a different movable character"
	return ""


func next_step(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if not payload.has("target"):
		return target_step("target", "Dream Link: choose a nearby ally", get_legal_targets(sys, instance, ability_id))
	if not payload.has("other"):
		var first: CharacterInstance = sys.find(str(payload.target))
		return target_step("other", "Dream Link: swap with which character?", _partners(sys, instance, first)) if first != null else {}
	return {}


func execute(sys, _instance: CharacterInstance, _ability_id: String, payload: Dictionary) -> Dictionary:
	sys.swap_characters(sys.find(str(payload.target)), sys.find(str(payload.other)), "dream_link")
	return {"success": true}


func ai_value(sys, instance: CharacterInstance, _ability_id: String, payload: Dictionary, ai) -> float:
	var first: CharacterInstance = sys.find(str(payload.get("target", "")))
	var other: CharacterInstance = sys.find(str(payload.get("other", "")))
	if first == null or other == null:
		return 0.0
	var value: float = ai.danger(first, first.position) - ai.danger(first, other.position)
	if other.player_id == instance.player_id:
		value += ai.danger(other, other.position) - ai.danger(other, first.position)
	else:
		value += ai.danger(other, first.position) - ai.danger(other, other.position)
	return value
