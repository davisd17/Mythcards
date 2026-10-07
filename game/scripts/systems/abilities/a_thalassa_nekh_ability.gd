extends AbilityHandler
# Thalassa-Nekh, Vessel of the Drowned Seraph (Flood Survivors Mystic) — LLD-closed-city-flood-roster.md 4.
# L1 Black-Water Communion (AP): an ally within 3 gains 1 Memory (max 1). Payload: {"target": id}.
# L2 Drowned Judgment: +1 RANGE. When an ally within her RANGE (by distance) spends Memory
#    to prevent damage from an enemy character, that enemy becomes Marked.
# L3 The Drowned Seraph Takes Form: +1 HP. Standalone ability
#    "a-flood-survivor-thalassa-nekh_l3", once per match (AP): Seraph Form for the rest of
#    the match, +2 ATK and +1 RANGE.

const L3_ID := "a-flood-survivor-thalassa-nekh_l3"
const REACH := 3
const SERAPH_ATK := 2
const SERAPH_RANGE := 1


func level_bonuses() -> Dictionary:
	return {2: {"range": 1}, 3: {"hp": 1}}


func ability_ids(instance: CharacterInstance) -> Array[String]:
	return [instance.data.id, L3_ID]


func ability_label(_instance: CharacterInstance, ability_id: String) -> String:
	return "Seraph Form" if ability_id == L3_ID else "Black-Water Communion"


func can_use(sys, instance: CharacterInstance, ability_id: String) -> bool:
	if ability_id == L3_ID:
		return instance.level >= 3 and not sys.used_this_match(instance, "seraph_form")
	return true


func get_legal_targets(sys, instance: CharacterInstance, ability_id: String) -> Array:
	if ability_id == L3_ID:
		return []
	var result := []
	for id in sys.characters_in_reach(instance, instance.position, sys.ability_reach(instance, REACH), true):
		var c: CharacterInstance = sys.find(id)
		if sys.memory_count(c) < sys.handler_for(c).memory_max(c):
			result.append(id)
	return result


func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	if ability_id == L3_ID:
		return ""
	return super(sys, instance, ability_id, payload)


func next_step(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if ability_id == L3_ID or payload.has("target"):
		return {}
	return target_step("target", "Black-Water Communion: which ally gains Memory?", get_legal_targets(sys, instance, ability_id))


func execute(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if ability_id == L3_ID:
		instance.ability_uses_this_match["seraph_form"] = true
		instance.atk_bonus += SERAPH_ATK
		instance.range_bonus += SERAPH_RANGE
		return {"success": true}
	sys.give_memory(sys.find(str(payload.target)))
	return {"success": true}


func on_memory_spent(sys, instance: CharacterInstance, holder: CharacterInstance, attacker: CharacterInstance) -> void:
	if instance.level < 2 or holder == instance or holder.player_id != instance.player_id:
		return
	if attacker == null or attacker == holder or attacker.player_id == instance.player_id or attacker.defeated:
		return
	var reach := instance.get_effective_range("attack", sys.get_conditional_range_bonus(instance, "attack"))
	if sys.distance(holder.position, instance.position) <= reach:
		sys.add_status(attacker, "marked", 1, "until_used", instance)
