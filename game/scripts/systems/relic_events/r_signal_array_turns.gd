extends RelicEventHandler
# Signal Array Turns (Event, Immediate): if a placed object is on the board, move one of
# your characters to an empty tile adjacent to it, if possible.


func resolve_immediate(sys, player_id: String) -> Dictionary:
	return {"needs_choice": true} if not _characters(sys, player_id).is_empty() \
			and not _destinations(sys).is_empty() else {}


func choice_spec(sys, player_id: String, _pending: Dictionary) -> Dictionary:
	var characters := _characters(sys, player_id)
	var destinations := _destinations(sys)
	var tiles_by_character := {}
	for id in characters:
		tiles_by_character[id] = destinations
	return {"prompt": "Signal Array Turns: move one of your characters next to a placed object.",
			"pick": "character_tile", "characters": characters,
			"tiles_by_character": tiles_by_character}


func resolve_choice(sys, player_id: String, payload: Dictionary) -> Dictionary:
	var target_id := str(payload.get("target_id", ""))
	var to = payload.get("to")
	if not _characters(sys, player_id).has(target_id):
		return {"success": false, "reason": "choose one of your characters"}
	if not to is Vector2i or not _destinations(sys).has(to):
		return {"success": false, "reason": "choose an empty tile adjacent to a placed object"}
	sys.move_character(sys.find(target_id), to)
	return {"success": true}


func _characters(sys, player_id: String) -> Array[String]:
	var result: Array[String] = []
	for c in own_live(sys, player_id):
		if c.is_placed() and (c.mounted_with_id == "" or c.is_mounted_rider):
			result.append(c.instance_id)
	return result


func _destinations(sys) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			var object_pos := Vector2i(x, y)
			if sys.board.get_placed_object(object_pos) == null:
				continue
			for pos in sys.neighbors(object_pos):
				if sys.is_empty_tile(pos) and not result.has(pos):
					result.append(pos)
	return result
