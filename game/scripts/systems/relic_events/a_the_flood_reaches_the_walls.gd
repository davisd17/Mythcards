extends RelicEventHandler
# The Flood Reaches The Walls (Event, Immediate): each character on an outer edge tile
# becomes Marked until the end of the round. (No source: any attacker benefits.)


func resolve_immediate(sys, _player_id: String) -> Dictionary:
	var last := BoardModel.BOARD_SIZE - 1
	for c in sys.live_characters():
		var p: Vector2i = c.position
		if p.x == 0 or p.y == 0 or p.x == last or p.y == last:
			sys.add_status(c, "marked", 1, "this_round")
	return {}
