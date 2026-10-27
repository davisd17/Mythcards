extends AbilityHandler
# Thalassa-Nekh, Vessel of the Drowned Seraph (Flood Survivors Mystic) — LLD-closed-city-flood-roster.md 4.
# L1: a character that deals HP damage to Nekh becomes Marked without stacking Marks.
# L2 Drowned Judgment: +1 RANGE, +1 MOVE.
# L3 The Drowned Seraph Takes Form: +1 HP. Standalone ability
#    "a-flood-survivor-thalassa-nekh_l3", once per match (AP): Seraph Form for the rest of
#    the match, +2 ATK and +1 RANGE.

const L3_ID := "a-flood-survivor-thalassa-nekh_l3"
const SERAPH_ATK := 2
const SERAPH_RANGE := 1


func level_bonuses() -> Dictionary:
	return {2: {"range": 1, "move": 1}, 3: {"hp": 1}}


func ability_ids(_instance: CharacterInstance) -> Array[String]:
	return [L3_ID]


func ability_label(_instance: CharacterInstance, _ability_id: String) -> String:
	return "Seraph Form"


func can_use(sys, instance: CharacterInstance, ability_id: String) -> bool:
	return ability_id == L3_ID and instance.level >= 3 and not sys.used_this_match(instance, "seraph_form")


func validate(_sys, _instance: CharacterInstance, _ability_id: String, _payload: Dictionary) -> String:
	return ""


func next_step(_sys, _instance: CharacterInstance, _ability_id: String, _payload: Dictionary) -> Dictionary:
	return {}


func execute(_sys, instance: CharacterInstance, _ability_id: String, _payload: Dictionary) -> Dictionary:
	instance.ability_uses_this_match["seraph_form"] = true
	instance.atk_bonus += SERAPH_ATK
	instance.range_bonus += SERAPH_RANGE
	return {"success": true}


func on_character_damaged(sys, instance: CharacterInstance, damaged: CharacterInstance,
		attacker: CharacterInstance, _incoming: int, final: int) -> void:
	if damaged != instance or final <= 0 or attacker == null or attacker == instance or attacker.defeated:
		return
	if not attacker.has_status("marked"):
		sys.add_status(attacker, "marked", 1, "until_used", instance)


func ai_value(_sys, _instance: CharacterInstance, _ability_id: String, _payload: Dictionary, _ai) -> float:
	return 2.0
