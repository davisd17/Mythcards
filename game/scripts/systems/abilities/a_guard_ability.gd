extends AbilityHandler
# Resonance Guard (Warrior) — Quartz Armor / Resonant Bastion (LLD-ability-system 5.10,
# card text as revised 2026-09-25).
# L1 Quartz Armor: ranged attack damage against it is reduced by 1.
# L2: +1 ATK; adjacent allies also have Quartz Armor.
# L3 Resonant Bastion: when a character with this Guard's Quartz Armor is attacked (melee
#    or ranged), the attacker takes 1 damage. Not an attack, so it never chains.

const QUARTZ_ARMOR_REDUCTION := 1
const BASTION_DAMAGE := 1


func level_bonuses() -> Dictionary:
	return {2: {"atk": 1}}


func get_own_damage_reduction(_sys, _defender: CharacterInstance, _attacker: CharacterInstance, is_ranged: bool) -> int:
	return QUARTZ_ARMOR_REDUCTION if is_ranged else 0


func get_aura_damage_reduction(sys, source: CharacterInstance, defender: CharacterInstance,
		_attacker: CharacterInstance, is_ranged: bool) -> int:
	if is_ranged and source.level >= 2 and sys.is_adjacent(source.position, defender.position):
		return QUARTZ_ARMOR_REDUCTION
	return 0


# Whether `character` currently wears this Guard's Quartz Armor. Also read by the UI badge.
func grants_quartz_armor(sys, guard: CharacterInstance, character: CharacterInstance) -> bool:
	if character == guard:
		return true
	return guard.level >= 2 and character.player_id == guard.player_id \
			and sys.is_adjacent(guard.position, character.position)


func on_attack_resolved(sys, instance: CharacterInstance, attacker: CharacterInstance,
		target: CharacterInstance, _damage: int, _defeated: bool) -> void:
	if instance.level < 3 or instance.defeated or attacker.defeated:
		return
	if attacker.player_id == instance.player_id or not grants_quartz_armor(sys, instance, target):
		return
	sys.combat().apply_damage(instance, attacker, BASTION_DAMAGE, false)
