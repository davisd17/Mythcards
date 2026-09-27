extends AbilityHandler
# Astral Harmonic (Mystic) — Resonance Shield / Harmonic Bind / Astral Echo (LLD 5.14).
# L1 Resonance Shield: shield an ally within 3 for 1 (2 if that ally is a mounted rider).
#    Payload: {"target": ally id}.
# L2 Harmonic Bind: the shield is 2; the ally can't be pushed, pulled, or displaced this turn.
# L3 Astral Echo: +1 RANGE; after shielding, may deal 1 damage to an enemy within 2 of
#    that ally ({"echo_target_id": id}), and the ally may move 1 tile without AP
#    ("free_move" reactive bonus, the same one Command grants).

const SHIELD := [0, 1, 2, 2]   # by level
const MOUNTED_SHIELD := 2
const ECHO_REACH := 2
const ECHO_DAMAGE := 1


func level_bonuses() -> Dictionary:
	return {3: {"range": 1}}


func can_use(_sys, _instance: CharacterInstance, _ability_id: String) -> bool:
	return true


func get_legal_targets(sys, instance: CharacterInstance, _ability_id: String) -> Array:
	return sys.characters_in_reach(instance, instance.position, sys.ability_reach(instance, instance.data.range), true)


func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	var reason := super(sys, instance, ability_id, payload)
	if reason != "" or not payload.has("echo_target_id"):
		return reason
	if instance.level < 3:
		return "Astral Echo needs Level 3"
	var ally: CharacterInstance = sys.find(str(payload.target))
	if not sys.characters_in_reach(ally, ally.position, ECHO_REACH, false).has(str(payload.echo_target_id)):
		return "needs an enemy within 2 of the shielded ally"
	return ""


func execute(sys, instance: CharacterInstance, _ability_id: String, payload: Dictionary) -> Dictionary:
	var ally: CharacterInstance = sys.find(str(payload.target))
	var value: int = SHIELD[instance.level]
	if instance.level == 1 and ally.is_mounted_rider:
		value = MOUNTED_SHIELD
	sys.add_status(ally, "shield", value, "this_round", instance)
	if instance.level >= 2:
		sys.add_status(ally, "no_push", 0, "this_turn", instance)
	var result := {"success": true}
	if instance.level >= 3:
		sys.offer_bonus(ally, "free_move")
		if payload.has("echo_target_id"):
			var enemy: CharacterInstance = sys.find(str(payload.echo_target_id))
			var hit: Dictionary = sys.combat().apply_damage(instance, enemy, ECHO_DAMAGE,
					sys.distance(instance.position, enemy.position) > 1)
			result["damage"] = hit.damage
			result["defeated"] = hit.defeated
	return result
