extends AbilityHandler
# Irina Vasilievna Karpova (Closed City Leader) — LLD-closed-city-flood-roster.md 4.
# L1 Access Granted (AP): an ally within 3 gains +1 ATK this turn (every attack this turn).
#    Payload: {"target": id} (L2 adds "target_2").
# L2 Private Favors: up to 2 allies; each also ignores Leak damage during its next move
#    this turn (it doesn't trigger Leaks on that move).
# L3 The Price of Access: +1 HP. Once per game, delivering an Ember offers a free
# direct defeat of one enemy anywhere on the board.

const TAG := "price_of_access"
const REACH := 3
const ATK := 1


func level_bonuses() -> Dictionary:
	return {3: {"hp": 1}}


func ability_label(_instance: CharacterInstance, _ability_id: String) -> String:
	return "Access Granted"


func can_use(_sys, _instance: CharacterInstance, _ability_id: String) -> bool:
	return true


func get_legal_targets(sys, instance: CharacterInstance, _ability_id: String) -> Array:
	return sys.characters_in_reach(instance, instance.position, sys.ability_reach(instance, REACH), true)


func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	var ids := _ids(payload)
	var limit := 2 if instance.level >= 2 else 1
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
	var verb := "Access Granted: which ally gets +1 ATK this turn?"
	if not payload.has("target"):
		return target_step("target", verb, legal)
	if instance.level < 2 or payload.has("target_2"):
		return {}
	return second_step("target_2", "And a second ally?", legal, payload.target)


func execute(sys, instance: CharacterInstance, _ability_id: String, payload: Dictionary) -> Dictionary:
	for id in _ids(payload):
		var ally: CharacterInstance = sys.find(id)
		sys.add_status(ally, "temp_atk", ATK, "this_turn", instance)
		if instance.level >= 2:
			sys.add_status(ally, "ignore_leak_move", 1, "this_turn", instance)
	return {"success": true}


func on_spirit_ember_delivered(sys, instance: CharacterInstance, carrier: CharacterInstance) -> void:
	if carrier == instance and instance.level >= 3 and not sys.used_this_match(instance, TAG + "_used"):
		if not _defeat_targets(sys, instance).is_empty():
			sys.offer_bonus(instance, TAG)


func _defeat_targets(sys, instance: CharacterInstance) -> Array:
	var result := []
	for enemy in sys.enemies_of(instance):
		if sys.occupant(enemy.position) == enemy:
			result.append(enemy.instance_id)
	return result


func bonus_label(tag: String) -> String:
	return "The Price of Access" if tag == TAG else super(tag)


func bonus_step(sys, instance: CharacterInstance, tag: String, payload: Dictionary) -> Dictionary:
	if tag != TAG or payload.has("target"):
		return {}
	return target_step("target", "The Price of Access: defeat which enemy?", _defeat_targets(sys, instance))


func execute_reactive_bonus(sys, instance: CharacterInstance, tag: String, payload: Dictionary) -> Dictionary:
	if tag != TAG:
		return super(sys, instance, tag, payload)
	if sys.used_this_match(instance, TAG + "_used"):
		return {"success": false, "reason": "already used this game"}
	if not _defeat_targets(sys, instance).has(str(payload.get("target", ""))):
		return {"success": false, "reason": "choose an enemy on the board"}
	# Consume before defeat signals: a defeat on the center immediately delivers again.
	instance.ability_uses_this_match[TAG + "_used"] = true
	sys.consume_bonus(instance, TAG)
	var enemy: CharacterInstance = sys.find(str(payload.target))
	sys.combat().defeat_character(instance, enemy)
	return {"success": true, "defeated": true, "target": enemy.instance_id}


static func _ids(payload: Dictionary) -> Array:
	var result := []
	for key in ["target", "target_2"]:
		if payload.get(key) != null and str(payload.get(key)) != "":
			result.append(str(payload[key]))
	return result


func ai_value(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary, ai) -> float:
	if ability_id == "bonus:" + TAG:
		var enemy: CharacterInstance = sys.find(str(payload.get("target", "")))
		return ai.damage_value(instance, enemy, enemy.current_hp) if enemy != null else 0.0
	var v := 0.0
	for id in _ids(payload):
		var ally: CharacterInstance = GameState.match_state.find_character(id)
		if ally.character_ap_remaining > 0 and not RulesEngine.get_legal_attack_target_ids(id).is_empty():
			v += 1.0   # +1 ATK on an attack it can still make
		else:
			v += 0.15
	return v
