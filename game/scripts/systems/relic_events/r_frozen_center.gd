extends RelicEventHandler
# Frozen Center (Event, 1 round): the center row and center tile count as frost; a
# character entering frost stops moving. Only tiles this event froze thaw afterwards
# (frost from Frozen Redoubt stays).


func on_activate(sys, _player_id: String) -> Dictionary:
	var frozen := []
	for x in BoardModel.BOARD_SIZE:
		var tile: BoardTile = sys.board.get_tile(Vector2i(x, BoardModel.CENTER_TILE.y))
		if tile.terrain_type != "frost":
			tile.terrain_type = "frost"
			frozen.append(tile.position)
	return {"frozen": frozen}


func on_expire(sys, _player_id: String, data: Dictionary) -> void:
	for pos in data.get("frozen", []):
		sys.board.get_tile(pos).terrain_type = ""
