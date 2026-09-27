extends AbilityHandler
# Sniper (Warrior) — Aim / Piercing Shot / Dead Lane (LLD-ability-system 5.3).
# L1 Aim: basic attack +1 RANGE if the Sniper hasn't moved this turn.
# L2 Piercing Shot: +1 RANGE; ignores 1 point of damage reduction; may ignore one
#    allied character for line of sight.
# L3 Dead Lane: +1 ATK; once per turn, after damaging an enemy 3+ tiles away, mark it
#    (the next allied attack against it deals +1).

const AIM_RANGE := 1
const PIERCING_IGNORE_REDUCTION := 1
const DEAD_LANE_MIN_DISTANCE := 3
const DEAD_LANE_MARK := 1


func level_bonuses() -> Dictionary:
	return {2: {"range": 1}, 3: {"atk": 1}}


func get_conditional_range_bonus(_sys, instance: CharacterInstance, context: String) -> int:
	var moved: bool = instance.ability_uses_this_turn.get("moved", false)
	return AIM_RANGE if context == "attack" and not moved else 0


func get_penetration(_sys, instance: CharacterInstance) -> Dictionary:
	return {"ignore_reduction": PIERCING_IGNORE_REDUCTION if instance.level >= 2 else 0, "ignore_shield": 0}


func get_line_of_sight_exceptions(sys, instance: CharacterInstance, target_pos: Vector2i) -> Array[String]:
	var result: Array[String] = []
	if instance.level >= 2:
		var ally: String = sys.first_ally_on_line(instance, instance.position, target_pos)
		if ally != "":
			result.append(ally)
	return result


func on_attack_resolved(sys, instance: CharacterInstance, attacker: CharacterInstance,
		target: CharacterInstance, damage: int, defeated: bool) -> void:
	if attacker != instance or instance.level < 3 or damage <= 0 or defeated:
		return
	if sys.distance(instance.position, target.position) < DEAD_LANE_MIN_DISTANCE:
		return
	if sys.used_this_turn(instance, "dead_lane_used"):
		return
	instance.ability_uses_this_turn["dead_lane_used"] = true
	sys.add_status(target, "marked", DEAD_LANE_MARK, "this_round", instance)
