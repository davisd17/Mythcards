extends RelicEventHandler
# Hall Of Shared Minds (Relic): your characters adjacent to another friendly character
# gain +1 RANGE on abilities (designer ruling 2026-09-27: a formation bonus).

const BONUS := 1


func get_range_bonus(sys, owner_id: String, instance: CharacterInstance, context: String) -> int:
	if context != "ability" or instance.player_id != owner_id:
		return 0
	for ally in sys.allies_of(instance):
		if sys.is_adjacent(ally.position, instance.position):
			return BONUS
	return 0
