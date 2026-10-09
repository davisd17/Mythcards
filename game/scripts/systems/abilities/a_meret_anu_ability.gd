extends AbilityHandler
# Queen Meret-Anu, Keeper of the Buried Tide (Flood Survivors Leader) — LLD-closed-city-flood-roster.md 4.
# L1 Memory Discipline (AP): any allied character, anywhere, gains 1 Memory (max 1). If
#    Meret-Anu has no Memory, she gains 1 too. Payload: {"target": id} (L2 adds "target_2").
# L2 Buried Tide Order: up to 2 allies.
# L3 Tide-Sealed Archive: +1 HP. Standalone ability "a-flood-survivor-meret-anu_l3", once
#    per match (AP): until the start of your next turn, a character on your team (her
#    included) that had Memory when hit and would be defeated instead loses its Memory and
#    stays at 1 HP. (A player flag read by AbilitySystem.intercept_lethal_damage.)

const L3_ID := "a-flood-survivor-meret-anu_l3"


func level_bonuses() -> Dictionary:
	return {3: {"hp": 1}}


func ability_ids(instance: CharacterInstance) -> Array[String]:
	return [instance.data.id, L3_ID]


func ability_label(_instance: CharacterInstance, ability_id: String) -> String:
	return "Tide-Sealed Archive" if ability_id == L3_ID else "Memory Discipline"


func can_use(sys, instance: CharacterInstance, ability_id: String) -> bool:
	if ability_id == L3_ID:
		return instance.level >= 3 and not sys.used_this_match(instance, "tide_sealed_used")
	return true


func get_legal_targets(sys, instance: CharacterInstance, ability_id: String) -> Array:
	if ability_id == L3_ID:
		return []
	var result := []
	for ally in sys.allies_of(instance):
		result.append(ally.instance_id)
	return result


func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	if ability_id == L3_ID:
		return ""
	var ids := _ids(payload)
	if ids.is_empty() or ids.size() > (2 if instance.level >= 2 else 1):
		return "choose an ally" if instance.level < 2 else "choose 1 or 2 allies"
	var legal := get_legal_targets(sys, instance, ability_id)
	for id in ids:
		if not legal.has(id) or ids.count(id) > 1:
			return "illegal ability target"
	return ""


func next_step(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if ability_id == L3_ID:
		return {}
	var legal := get_legal_targets(sys, instance, ability_id)
	if not payload.has("target"):
		return target_step("target", "Memory Discipline: which ally gains Memory?", legal)
	if instance.level < 2 or payload.has("target_2"):
		return {}
	return second_step("target_2", "And a second ally?", legal, payload.target)


func execute(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if ability_id == L3_ID:
		instance.ability_uses_this_match["tide_sealed_used"] = true
		sys.state().get_player(instance.player_id).player_flags_this_turn["tide_sealed"] = true
		return {"success": true}
	for id in _ids(payload):
		sys.give_memory(sys.find(id))
	if sys.memory_count(instance) == 0:
		sys.give_memory(instance)
	return {"success": true}


static func _ids(payload: Dictionary) -> Array:
	var result := []
	for key in ["target", "target_2"]:
		if payload.get(key) != null and str(payload.get(key)) != "":
			result.append(str(payload[key]))
	return result


func ai_value(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary, ai) -> float:
	if ability_id == L3_ID:
		var protected_allies := 0
		for c in sys.allies_of(instance) + [instance]:
			if sys.memory_count(c) > 0 and ai.danger(c, c.position) > 0:
				protected_allies += 1
		return 0.5 * protected_allies
	var v := 0.3 if sys.memory_count(instance) == 0 else 0.0
	for id in _ids(payload):
		var ally: CharacterInstance = sys.find(id)
		if sys.memory_count(ally) < sys.handler_for(ally).memory_max(ally):
			v += 0.3 + 0.3 * ai.danger(ally, ally.position)
	return v
