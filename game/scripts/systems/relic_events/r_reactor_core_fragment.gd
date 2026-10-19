extends RelicEventHandler
# Leak immunity is checked by AbilitySystem when entering Leak tiles.

const TYPES := ["Specialist", "Mystic"]


func get_atk_bonus(_sys, owner_id: String, instance: CharacterInstance) -> int:
	return 1 if instance.player_id == owner_id and TYPES.has(instance.data.type) else 0
