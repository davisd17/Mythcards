extends RelicEventHandler
# Black Water Remembers (Event, Immediate): choose 1 allied character adjacent to a placed
# object. It gains 1 Memory marker (max 1 per character), then moves 1 tile, ending on an
# empty tile. Choice: {"target_id": id, "to": pos} ("to" omitted if it can't move).


func resolve_immediate(sys, player_id: String) -> Dictionary:
	return {"needs_choice": true} if not _eligible(sys, player_id).is_empty() else {}


func choice_spec(sys, player_id: String, _pending: Dictionary) -> Dictionary:
	var tiles_by := {}
	for id in _eligible(sys, player_id):
		tiles_by[id] = _steps(sys, sys.find(id))
	return {"prompt": "Black Water Remembers: choose an ally next to a placed object; it gains Memory, then moves 1 tile.",
			"pick": "character_tile", "characters": _eligible(sys, player_id), "tiles_by_character": tiles_by}


func resolve_choice(sys, player_id: String, payload: Dictionary) -> Dictionary:
	var target_id := str(payload.get("target_id", ""))
	if not _eligible(sys, player_id).has(target_id):
		return {"success": false, "reason": "choose an ally next to a placed object"}
	var target: CharacterInstance = sys.find(target_id)
	var steps := _steps(sys, target)
	var to = payload.get("to")
	if not steps.is_empty() and not steps.has(to):
		return {"success": false, "reason": "choose an empty tile next to it"}
	sys.give_memory(target)
	if to is Vector2i and not target.defeated:
		sys.move_character(target, to)
	return {"success": true}


func _eligible(sys, player_id: String) -> Array[String]:
	var result: Array[String] = []
	for c in own_live(sys, player_id):
		if c.mounted_with_id != "" and not c.is_mounted_rider:
			continue
		for n in sys.neighbors(c.position):
			if sys.board.get_placed_object(n) != null:
				result.append(c.instance_id)
				break
	return result


func _steps(sys, c: CharacterInstance) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for n in sys.neighbors(c.position):
		if sys.is_empty_tile(n):
			result.append(n)
	return result
