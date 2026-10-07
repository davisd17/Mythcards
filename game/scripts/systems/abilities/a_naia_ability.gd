extends AbilityHandler
# Naia of the Black Sarcophagus (Flood Survivors Warrior) — LLD-closed-city-flood-roster.md 4.
# L1 Tomb Sentinel: while adjacent to a placed object (any, Leaks included), the first
#    damage Naia takes each turn is reduced by 1. "Each turn" counts both players' turns.
# L2 Sarcophagus Oath: +1 HP; while adjacent to a placed object, her basic attacks Mark
#    the enemies they damage.
# L3 Open the Black Sarcophagus: +1 ATK. Once per match, when she would be defeated she
#    stays at 1 HP; if she is then adjacent to a placed object, an adjacent enemy becomes
#    Marked: the attacker if adjacent, otherwise the adjacent enemy with the lowest HP
#    (chosen automatically, since it can happen on the opponent's turn).

const SENTINEL_REDUCTION := 1


func level_bonuses() -> Dictionary:
	return {2: {"hp": 1}, 3: {"atk": 1}}


func get_own_damage_reduction(sys, defender: CharacterInstance, _attacker: CharacterInstance, _is_ranged: bool) -> int:
	if int(defender.ability_uses_this_match.get("damaged_on_turn", -1)) == sys.state().turn_number:
		return 0   # not her first damage this turn
	return SENTINEL_REDUCTION if _near_object(sys, defender) else 0


func on_character_damaged(sys, instance: CharacterInstance, damaged: CharacterInstance,
		_attacker: CharacterInstance, incoming: int, _final: int) -> void:
	if damaged == instance and incoming > 0:
		instance.ability_uses_this_match["damaged_on_turn"] = sys.state().turn_number


func on_attack_resolved(sys, instance: CharacterInstance, attacker: CharacterInstance,
		target: CharacterInstance, damage: int, defeated: bool) -> void:
	if attacker != instance or instance.level < 2 or damage <= 0 or defeated or target == null:
		return
	if _near_object(sys, instance):
		sys.add_status(target, "marked", 1, "until_used", instance)


func intercept_lethal_damage(sys, instance: CharacterInstance, combat) -> Dictionary:
	if instance.level < 3 or sys.used_this_match(instance, "sarcophagus_used"):
		return {"triggered": false}
	instance.ability_uses_this_match["sarcophagus_used"] = true
	if _near_object(sys, instance):
		var mark := _mark_choice(sys, instance, combat.current_attacker)
		if mark != null:
			sys.add_status(mark, "marked", 1, "until_used", instance)
	return {"triggered": true, "final_hp": 1}


func _mark_choice(sys, instance: CharacterInstance, attacker: CharacterInstance) -> CharacterInstance:
	var best: CharacterInstance = null
	for pos in sys.neighbors(instance.position):
		var c: CharacterInstance = sys.occupant(pos)
		if c == null or c.player_id == instance.player_id:
			continue
		if c == attacker:
			return c
		if best == null or c.current_hp < best.current_hp:
			best = c
	return best


static func _near_object(sys, instance: CharacterInstance) -> bool:
	for pos in sys.neighbors(instance.position):
		if sys.board.get_placed_object(pos) != null:
			return true
	return false
