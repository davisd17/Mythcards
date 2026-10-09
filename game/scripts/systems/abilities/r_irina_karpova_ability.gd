extends AbilityHandler
# Irina Vasilievna Karpova (Closed City Leader) — LLD-closed-city-flood-roster.md 4.
# L1 Access Granted (AP): an ally within 3 gains +1 ATK this turn (every attack this turn).
#    Payload: {"target": id} (L2 adds "target_2").
# L2 Private Favors: up to 2 allies; each also ignores Leak damage during its next move
#    this turn (it doesn't trigger Leaks on that move).
# L3 The Door Was Always There: +1 HP. Standalone ability "r-irina-karpova_l3", once per
#    match (AP): up to 2 allies within 3 may each move 1 tile without spending AP.
#    Payload: {"target": id, "target_2": optional id}.

const L3_ID := "r-irina-karpova_l3"
const REACH := 3
const ATK := 1


func level_bonuses() -> Dictionary:
	return {3: {"hp": 1}}


func ability_ids(instance: CharacterInstance) -> Array[String]:
	return [instance.data.id, L3_ID]


func ability_label(_instance: CharacterInstance, ability_id: String) -> String:
	return "The Door Was Always There" if ability_id == L3_ID else "Access Granted"


func can_use(sys, instance: CharacterInstance, ability_id: String) -> bool:
	if ability_id == L3_ID:
		return instance.level >= 3 and not sys.used_this_match(instance, "door_used")
	return true


func get_legal_targets(sys, instance: CharacterInstance, _ability_id: String) -> Array:
	return sys.characters_in_reach(instance, instance.position, sys.ability_reach(instance, REACH), true)


func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	var ids := _ids(payload)
	var limit := 2 if (ability_id == L3_ID or instance.level >= 2) else 1
	if ids.is_empty():
		return "choose an ally"
	if ids.size() > limit:
		return "too many targets"
	var legal := get_legal_targets(sys, instance, ability_id)
	for id in ids:
		if not legal.has(id) or ids.count(id) > 1:
			return "illegal ability target"
	return ""


func next_step(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	var legal := get_legal_targets(sys, instance, ability_id)
	var verb := "Who may move 1 tile for free?" if ability_id == L3_ID else "Access Granted: which ally gets +1 ATK this turn?"
	if not payload.has("target"):
		return target_step("target", verb, legal)
	if (ability_id != L3_ID and instance.level < 2) or payload.has("target_2"):
		return {}
	return second_step("target_2", "And a second ally?", legal, payload.target)


func execute(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if ability_id == L3_ID:
		instance.ability_uses_this_match["door_used"] = true
	for id in _ids(payload):
		var ally: CharacterInstance = sys.find(id)
		if ability_id == L3_ID:
			sys.offer_bonus(ally, "free_move")
			continue
		sys.add_status(ally, "temp_atk", ATK, "this_turn", instance)
		if instance.level >= 2:
			sys.add_status(ally, "ignore_leak_move", 1, "this_turn", instance)
	return {"success": true}


static func _ids(payload: Dictionary) -> Array:
	var result := []
	for key in ["target", "target_2"]:
		if payload.get(key) != null and str(payload.get(key)) != "":
			result.append(str(payload[key]))
	return result


func ai_value(_sys, _instance: CharacterInstance, ability_id: String, payload: Dictionary, _ai) -> float:
	var v := 0.0
	for id in _ids(payload):
		var ally: CharacterInstance = GameState.match_state.find_character(id)
		if ability_id == L3_ID:
			v += 0.6
		elif ally.character_ap_remaining > 0 and not RulesEngine.get_legal_attack_target_ids(id).is_empty():
			v += 1.0   # +1 ATK on an attack it can still make
		else:
			v += 0.15
	return v
