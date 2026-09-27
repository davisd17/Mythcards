extends AbilityHandler
# Army General (Leader) — Command / Tactical Mastery (LLD-ability-system 5.4).
# L1 Command: an ally within 2 gains +1 ATK on its next attack this turn, or may move
#    1 tile without spending an action. Payload: {"target": id, "choice": "atk"|"move"}.
# L2: range 3, up to 2 allies, each choosing. Payload: {"targets": [{"id", "choice"}, ...]}.
# L3 Tactical Mastery: +1 HP; once per turn, when a Commanded ally defeats an enemy or
#    delivers a Spirit Ember, refresh 1 character AP on an ally within 2 ("tactical_mastery").

const COMMAND_REACH := [0, 2, 3, 3]     # by level
const COMMAND_TARGETS := [0, 1, 2, 2]
const COMMAND_ATK := 1
const TACTICAL_MASTERY_REACH := 2


func level_bonuses() -> Dictionary:
	return {3: {"hp": 1}}


func can_use(_sys, _instance: CharacterInstance, _ability_id: String) -> bool:
	return true


func get_legal_targets(sys, instance: CharacterInstance, _ability_id: String) -> Array:
	return sys.characters_in_reach(instance, instance.position, sys.ability_reach(instance, COMMAND_REACH[instance.level]), true)


func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	var orders := _orders(payload)
	if orders.is_empty():
		return "choose an ally to command"
	if orders.size() > COMMAND_TARGETS[instance.level]:
		return "too many targets"
	var legal := get_legal_targets(sys, instance, ability_id)
	var seen := {}
	for order in orders:
		if not legal.has(order.id) or seen.has(order.id):
			return "illegal ability target"
		if not ["atk", "move"].has(order.choice):
			return "choose atk or move"
		seen[order.id] = true
	return ""


func execute(sys, instance: CharacterInstance, _ability_id: String, payload: Dictionary) -> Dictionary:
	for order in _orders(payload):
		var ally: CharacterInstance = sys.find(order.id)
		if order.choice == "atk":
			sys.add_status(ally, "temp_atk", COMMAND_ATK, "this_turn", instance, true)
		else:
			sys.offer_bonus(ally, "free_move")
		ally.ability_uses_this_turn["commanded_by"] = instance.instance_id
	return {"success": true}


func on_character_defeated(sys, instance: CharacterInstance, _fallen: CharacterInstance,
		defeated_by: CharacterInstance) -> void:
	_maybe_offer_tactical_mastery(sys, instance, defeated_by)


func on_spirit_ember_delivered(sys, instance: CharacterInstance, carrier: CharacterInstance) -> void:
	_maybe_offer_tactical_mastery(sys, instance, carrier)


func execute_reactive_bonus(sys, instance: CharacterInstance, tag: String, payload: Dictionary) -> Dictionary:
	if tag != "tactical_mastery":
		return super(sys, instance, tag, payload)
	var target_id := str(payload.get("target_id", ""))
	if not sys.characters_in_reach(instance, instance.position, TACTICAL_MASTERY_REACH, true).has(target_id):
		return {"success": false, "reason": "needs an ally within 2"}
	var ally: CharacterInstance = sys.find(target_id)
	sys.consume_bonus(instance, "tactical_mastery")
	instance.ability_uses_this_turn["tactical_mastery_used"] = true
	ally.character_ap_remaining = mini(ally.character_ap_max, ally.character_ap_remaining + 1)
	EventBus.character_ap_changed.emit(ally.instance_id, ally.character_ap_remaining)
	return {"success": true}


func _maybe_offer_tactical_mastery(sys, instance: CharacterInstance, actor: CharacterInstance) -> void:
	if instance.level < 3 or actor == null or sys.used_this_turn(instance, "tactical_mastery_used"):
		return
	if actor.ability_uses_this_turn.get("commanded_by", "") == instance.instance_id:
		sys.offer_bonus(instance, "tactical_mastery")


static func _orders(payload: Dictionary) -> Array:
	var raw: Array = payload.get("targets", [])
	if raw.is_empty() and payload.has("target"):
		raw = [{"id": payload.target, "choice": payload.get("choice", "")}]
	var result := []
	for entry in raw:
		if entry is Dictionary:
			result.append({"id": str(entry.get("id", "")), "choice": str(entry.get("choice", ""))})
	return result
