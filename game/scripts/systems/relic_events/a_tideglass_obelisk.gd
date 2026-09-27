extends RelicEventHandler
# Tideglass Obelisk (Relic): your characters adjacent to a placed object (anyone's) gain
# +1 RANGE on attacks and abilities.

const BONUS := 1


func get_range_bonus(sys, owner_id: String, instance: CharacterInstance, _context: String) -> int:
	if instance.player_id != owner_id:
		return 0
	for pos in sys.neighbors(instance.position):
		if sys.board.get_placed_object(pos) != null:
			return BONUS
	return 0
