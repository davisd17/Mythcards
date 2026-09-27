extends AbilityHandler
# Bogatyr Champion (Hero) — Stand Firm / Heroic Guard / Last Oath (LLD-ability-system 5.5).
# L1 Stand Firm: +1 max and current HP while on or adjacent to the center tile.
# L2 Heroic Guard: that bonus becomes +2 (not +3); adjacent allies take -1 damage from attacks.
# L3 Last Oath: +1 ATK, +2 max HP; the first time it would be defeated this match, it
#    stays at 2 HP and every adjacent enemy takes 1 damage.

const STAND_FIRM_HP := [0, 1, 2, 2]   # by level
const HEROIC_GUARD_REDUCTION := 1
const LAST_OATH_HP := 2
const LAST_OATH_DAMAGE := 1


func level_bonuses() -> Dictionary:
	return {3: {"atk": 1, "hp": 2}}


func get_own_conditional_max_hp_bonus(sys, instance: CharacterInstance) -> int:
	if not instance.is_placed() or sys.distance(instance.position, BoardModel.CENTER_TILE) > 1:
		return 0
	return STAND_FIRM_HP[instance.level]


func get_aura_damage_reduction(sys, source: CharacterInstance, defender: CharacterInstance,
		_attacker: CharacterInstance, _is_ranged: bool) -> int:
	if source.level >= 2 and sys.is_adjacent(source.position, defender.position):
		return HEROIC_GUARD_REDUCTION
	return 0


func intercept_lethal_damage(sys, instance: CharacterInstance, combat) -> Dictionary:
	if instance.level < 3 or sys.used_this_match(instance, "last_oath_used"):
		return {"triggered": false}
	instance.ability_uses_this_match["last_oath_used"] = true
	for pos in sys.neighbors(instance.position):
		var enemy: CharacterInstance = sys.occupant(pos)
		if enemy != null and enemy.player_id != instance.player_id:
			combat.apply_damage(instance, enemy, LAST_OATH_DAMAGE, false)
	return {"triggered": true, "final_hp": LAST_OATH_HP}
