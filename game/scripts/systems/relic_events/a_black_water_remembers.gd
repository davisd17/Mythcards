extends RelicEventHandler
# Black Water Remembers (Event, Immediate): choose a character on or adjacent to the
# center tile. Give it 1 Memory marker. Choice: {"target_id": id}.


func resolve_immediate(sys, _player_id: String) -> Dictionary:
	return {"needs_choice": true} if not _eligible(sys).is_empty() else {}


func choice_spec(sys, _player_id: String, _pending: Dictionary) -> Dictionary:
	return {"prompt": "Black Water Remembers: choose a character on or adjacent to the center tile; it gains Memory.",
			"pick": "character", "characters": _eligible(sys)}


func resolve_choice(sys, _player_id: String, payload: Dictionary) -> Dictionary:
	var target_id := str(payload.get("target_id", ""))
	if not _eligible(sys).has(target_id):
		return {"success": false, "reason": "choose a character on or adjacent to the center tile"}
	sys.give_memory(sys.find(target_id))
	return {"success": true}


func _eligible(sys) -> Array[String]:
	var result: Array[String] = []
	var positions: Array[Vector2i] = [BoardModel.CENTER_TILE]
	positions.append_array(sys.neighbors(BoardModel.CENTER_TILE))
	for pos in positions:
		var target = sys.occupant(pos)
		if target != null and not target.has_status("memory"):
			result.append(target.instance_id)
	return result
