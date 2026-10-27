extends AbilityHandler
# Irina Vasilievna Karpova (Closed City Leader) — LLD-closed-city-flood-roster.md 4.
# L1 Access Granted (AP): an ally within 3 in an orthogonal line gains +1 ATK this turn (every
#    attack this turn). Ignores line of sight (designer 2026-10-26).
#    Payload: {"target": id}.
# L2 Private Favors: +1 HP; Access Granted may target any ally on the board, ignoring range
#    and line of sight (balance pass 2026-10-19, replacing 2 targets and Leak immunity).
# L3 The Price of Access: +1 HP. Once per game, delivering an Ember offers a free
# direct defeat of one enemy anywhere on the board.

const TAG := "price_of_access"
const REACH := 3
const ATK := 1


func level_bonuses() -> Dictionary:
	return {2: {"hp": 1}, 3: {"hp": 1}}


func ability_label(_instance: CharacterInstance, _ability_id: String) -> String:
	return "Access Granted"


func can_use(_sys, _instance: CharacterInstance, _ability_id: String) -> bool:
	return true


func get_legal_targets(sys, instance: CharacterInstance, _ability_id: String) -> Array:
	if instance.level < 2:
		return sys.characters_in_reach(instance, instance.position, sys.ability_reach(instance, REACH), true, true)
	# Anywhere: every ally on the board, one per tile (a ridden Mount is its rider's tile).
	var result := []
	for ally in sys.allies_of(instance):
		if sys.occupant(ally.position) == ally:
			result.append(ally.instance_id)
	return result


func next_step(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if payload.has("target"):
		return {}
	return target_step("target", "Access Granted: which ally gets +1 ATK this turn?", get_legal_targets(sys, instance, ability_id))


func execute(sys, instance: CharacterInstance, _ability_id: String, payload: Dictionary) -> Dictionary:
	sys.add_status(sys.find(str(payload.target)), "temp_atk", ATK, "this_turn", instance)
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


func ai_value(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary, ai) -> float:
	if ability_id == "bonus:" + TAG:
		var enemy: CharacterInstance = sys.find(str(payload.get("target", "")))
		return ai.damage_value(instance, enemy, enemy.current_hp) if enemy != null else 0.0
	var id := str(payload.get("target", ""))
	var ally: CharacterInstance = GameState.match_state.find_character(id)
	if ally != null and ally.character_ap_remaining > 0 and not RulesEngine.get_legal_attack_target_ids(id).is_empty():
		return 1.0   # +1 ATK on an attack it can still make
	return 0.15
