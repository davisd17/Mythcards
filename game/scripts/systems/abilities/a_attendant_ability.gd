extends AbilityHandler
# Quartz Attendant (Common) — Synchronize / Shared Pulse / Collective Node (LLD 5.8).
# L1 Synchronize: +1 ATK while adjacent to another Atlantean ally (never an enemy
#    Atlantean in a mirror match).
# L2 Shared Pulse: +1 HP; the first damage each turn to one adjacent Atlantean ally is
#    reduced by 1.
# L3 Collective Node: +1 HP; counts as a pylon (AbilitySystem.is_pylon_source) and as
#    adjacent to Atlanteans within 2 tiles for Synchronize.

const SYNCHRONIZE_ATK := 1
const SHARED_PULSE_REDUCTION := 1
const COLLECTIVE_NODE_REACH := 2


func level_bonuses() -> Dictionary:
	return {2: {"hp": 1}, 3: {"hp": 1}}


func get_conditional_atk_bonus(sys, instance: CharacterInstance) -> int:
	var reach := COLLECTIVE_NODE_REACH if instance.level >= 3 else 1
	for ally in sys.allies_of(instance):
		if ally.data.culture == "Atlantean" and sys.distance(ally.position, instance.position) <= reach:
			return SYNCHRONIZE_ATK
	return 0


func get_aura_damage_reduction(sys, source: CharacterInstance, defender: CharacterInstance,
		_attacker: CharacterInstance, _is_ranged: bool) -> int:
	if source.level < 2 or defender.data.culture != "Atlantean":
		return 0
	if not sys.is_adjacent(source.position, defender.position) or sys.used_this_turn(source, "shared_pulse_used"):
		return 0
	# "First damage each turn": asking is spending (LLD 9 accepts this query side effect).
	source.ability_uses_this_turn["shared_pulse_used"] = true
	return SHARED_PULSE_REDUCTION
