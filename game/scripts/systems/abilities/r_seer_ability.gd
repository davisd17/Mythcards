extends AbilityHandler
# Frost Seer (Mystic) — Chill / Winter Veil / Deep Freeze (LLD-ability-system 5.7).
# L1 Chill: 1 damage to an enemy in range (the Seer's RANGE, 3). On its next turn the
#    target has -1 MOVE and can't mount or dismount. Payload: {"target": id}.
# L2 Winter Veil: Chill also gives one ally within 3 a 1-damage shield, and that ally
#    can't be pushed this turn. Payload adds optional {"ally_id": id}.
# L3 Deep Freeze: +1 RANGE; the target also can't use reactions or bonus movement next
#    turn; a target that was already slowed can't move at all next turn.

const CHILL_DAMAGE := 1
const CHILL_SLOW := -1
const WINTER_VEIL_REACH := 3
const WINTER_VEIL_SHIELD := 1
const DEEP_FREEZE_SLOW := -99   # floored to 0 MOVE by get_effective_move()


func level_bonuses() -> Dictionary:
	return {3: {"range": 1}}


func can_use(_sys, _instance: CharacterInstance, _ability_id: String) -> bool:
	return true


func get_legal_targets(sys, instance: CharacterInstance, _ability_id: String) -> Array:
	return sys.characters_in_reach(instance, instance.position, sys.ability_reach(instance, instance.data.range), false)


func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	var reason := super(sys, instance, ability_id, payload)
	if reason != "" or not payload.has("ally_id"):
		return reason
	if instance.level < 2:
		return "Winter Veil needs Level 2"
	if not _veil_targets(sys, instance).has(str(payload.ally_id)):
		return "needs an ally within 3"
	return ""


func execute(sys, instance: CharacterInstance, _ability_id: String, payload: Dictionary) -> Dictionary:
	var target: CharacterInstance = sys.find(str(payload.target))
	var already_slowed := false
	for se in target.status_effects:
		if se.type == "temp_move" and se.value < 0:
			already_slowed = true
	var hit: Dictionary = sys.combat().apply_damage(instance, target, CHILL_DAMAGE,
			sys.distance(instance.position, target.position) > 1)
	if not hit.defeated:
		sys.add_status(target, "temp_move", CHILL_SLOW, "next_turn", instance)
		sys.add_status(target, "no_mount_dismount", 0, "next_turn", instance)
		if instance.level >= 3:
			sys.add_status(target, "no_reaction", 0, "next_turn", instance)
			if already_slowed:
				sys.add_status(target, "temp_move", DEEP_FREEZE_SLOW, "next_turn", instance)
	if instance.level >= 2 and payload.has("ally_id"):
		var ally: CharacterInstance = sys.find(str(payload.ally_id))
		sys.add_status(ally, "shield", WINTER_VEIL_SHIELD, "this_turn", instance)
		sys.add_status(ally, "no_push", 0, "this_turn", instance)
	return {"success": true, "damage": hit.damage, "defeated": hit.defeated}


func ability_label(_instance: CharacterInstance, _ability_id: String) -> String:
	return "Chill"


func next_step(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if not payload.has("target"):
		return target_step("target", "Chill which enemy?", get_legal_targets(sys, instance, ability_id))
	if instance.level < 2 or payload.has("ally_id"):
		return {}
	var allies := _veil_targets(sys, instance)
	return {} if allies.is_empty() else target_step("ally_id", "Winter Veil: shield which ally?", allies, true)


func _veil_targets(sys, instance: CharacterInstance) -> Array[String]:
	return sys.characters_in_reach(instance, instance.position, sys.ability_reach(instance, WINTER_VEIL_REACH), true)
