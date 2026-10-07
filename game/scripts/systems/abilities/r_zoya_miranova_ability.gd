extends AbilityHandler
# Zoya Miranova (Closed City Mystic) — LLD-closed-city-flood-roster.md 4.
# L1 Voice Under Static (AP): an enemy within 3 is pulled 1 tile toward Zoya if that tile
#    can be entered (a Leak there is triggered; "can't be moved" effects stop it).
#    Payload: {"target": enemy id}.
# L2 Subject Three: +1 RANGE; an enemy Voice Under Static moved becomes Marked.
# L3 Too Many Names: +1 HP. Once per match, after Voice Under Static moves an enemy, Zoya
#    may use it again without spending AP (the "too_many_names" bonus, {"target": id}).

const REACH := 3
const TAG := "too_many_names"


func level_bonuses() -> Dictionary:
	return {2: {"range": 1}, 3: {"hp": 1}}


func ability_label(_instance: CharacterInstance, _ability_id: String) -> String:
	return "Voice Under Static"


func can_use(_sys, _instance: CharacterInstance, _ability_id: String) -> bool:
	return true


func get_legal_targets(sys, instance: CharacterInstance, _ability_id: String) -> Array:
	return sys.characters_in_reach(instance, instance.position, sys.ability_reach(instance, REACH), false)


func next_step(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if payload.has("target"):
		return {}
	return target_step("target", "Voice Under Static: pull which enemy?", get_legal_targets(sys, instance, ability_id))


func execute(sys, instance: CharacterInstance, _ability_id: String, payload: Dictionary) -> Dictionary:
	return _voice(sys, instance, sys.find(str(payload.target)))


func bonus_label(tag: String) -> String:
	return "Too Many Names (again)" if tag == TAG else super(tag)


func bonus_step(sys, instance: CharacterInstance, tag: String, payload: Dictionary) -> Dictionary:
	if tag != TAG or payload.has("target"):
		return {}
	return target_step("target", "Too Many Names: pull which enemy?", get_legal_targets(sys, instance, ""))


func execute_reactive_bonus(sys, instance: CharacterInstance, tag: String, payload: Dictionary) -> Dictionary:
	if tag != TAG:
		return super(sys, instance, tag, payload)
	if not get_legal_targets(sys, instance, "").has(str(payload.get("target", ""))):
		return {"success": false, "reason": "needs an enemy in range"}
	sys.consume_bonus(instance, TAG)
	return _voice(sys, instance, sys.find(str(payload.target)))


func _voice(sys, instance: CharacterInstance, enemy: CharacterInstance) -> Dictionary:
	var before := enemy.position
	var after: Vector2i = sys.combat().apply_pull(enemy, instance.position, 1)
	var moved := after != before
	if moved and instance.level >= 2 and not enemy.defeated:
		sys.add_status(enemy, "marked", 1, "until_used", instance)
	if moved and instance.level >= 3 and not sys.used_this_match(instance, "too_many_names_used"):
		instance.ability_uses_this_match["too_many_names_used"] = true
		sys.offer_bonus(instance, TAG)
	return {"success": true, "moved": moved}
