extends AbilityHandler
# White Siberian Tiger (Mount) — Pounce / Aurora Predator (LLD-ability-system 5.2).
# L1 Pounce (activated, only while not carrying a rider): marks the Tiger's next attack
#    after moving for +2 ATK. Every character has 1 AP a turn, so the mark lasts until
#    the Tiger attacks on a turn it has moved (e.g. after a Command free move).
# L2: +1 HP, +1 MOVE; Pounce also pushes the target 1 tile.
# L3 Aurora Predator: +1 ATK; once per turn, when a Pounce attack defeats its target,
#    the Tiger may move up to 2 tiles and refresh 1 character AP ("aurora_predator").

const POUNCE_ATK := 2
const POUNCE_PUSH := 1
const AURORA_PREDATOR_MOVE := 2


func level_bonuses() -> Dictionary:
	return {2: {"hp": 1, "move": 1}, 3: {"atk": 1}}


func can_use(_sys, instance: CharacterInstance, _ability_id: String) -> bool:
	return instance.mounted_with_id == "" and not instance.has_status("pounce_mark")


func validate(_sys, _instance: CharacterInstance, _ability_id: String, _payload: Dictionary) -> String:
	return ""   # self-targeted


func execute(sys, instance: CharacterInstance, _ability_id: String, _payload: Dictionary) -> Dictionary:
	sys.add_status(instance, "pounce_mark", POUNCE_ATK, "until_used", instance)
	return {"success": true}


func get_conditional_atk_bonus(_sys, instance: CharacterInstance) -> int:
	return POUNCE_ATK if _pounce_ready(instance) else 0


func on_attack_resolved(sys, instance: CharacterInstance, attacker: CharacterInstance,
		target: CharacterInstance, _damage: int, defeated: bool) -> void:
	if attacker != instance or not _pounce_ready(instance):
		return
	sys.remove_status(instance, "pounce_mark")
	if instance.level >= 2 and not defeated:
		sys.combat().apply_push(target, instance.position, POUNCE_PUSH)
	if instance.level >= 3 and defeated and not sys.used_this_turn(instance, "aurora_predator_used"):
		sys.offer_bonus(instance, "aurora_predator")


func execute_reactive_bonus(sys, instance: CharacterInstance, tag: String, payload: Dictionary) -> Dictionary:
	if tag != "aurora_predator":
		return super(sys, instance, tag, payload)
	var to = payload.get("to")
	if to != null and not (to is Vector2i and sys.moves_for(instance, AURORA_PREDATOR_MOVE).has(to)):
		return {"success": false, "reason": "illegal move"}
	sys.consume_bonus(instance, "aurora_predator")
	instance.ability_uses_this_turn["aurora_predator_used"] = true
	if to != null:
		sys.move_character(instance, to)
	instance.character_ap_remaining = mini(instance.character_ap_max, instance.character_ap_remaining + 1)
	EventBus.character_ap_changed.emit(instance.instance_id, instance.character_ap_remaining)
	return {"success": true}


static func _pounce_ready(instance: CharacterInstance) -> bool:
	return instance.has_status("pounce_mark") and instance.ability_uses_this_turn.get("moved", false)
