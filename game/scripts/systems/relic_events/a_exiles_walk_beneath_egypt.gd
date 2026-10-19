extends RelicEventHandler


func _eligible(sys, player_id: String) -> Array:
	var result := []
	for c in own_live(sys, player_id):
		if sys.occupant(c.position) != c or _destinations(sys, c).is_empty():
			continue
		for n in sys.neighbors(c.position):
			if sys.board.get_placed_object(n) != null:
				result.append(c.instance_id)
				break
	return result


func _destinations(sys, c: CharacterInstance) -> Array:
	return sys.moves_for(c, 1).filter(func(pos): return sys.is_empty_tile(pos))


func resolve_immediate(sys, player_id: String) -> Dictionary:
	var eligible := _eligible(sys, player_id)
	return {"needs_choice": true, "eligible": eligible, "moved": []} if not eligible.is_empty() else {}


func choice_spec(sys, _player_id: String, pending: Dictionary) -> Dictionary:
	var choices := {}
	for id in pending.get("eligible", []):
		var c: CharacterInstance = sys.find(id)
		if c != null and not pending.get("moved", []).has(id):
			var tiles := _destinations(sys, c)
			if not tiles.is_empty():
				choices[id] = tiles
	return {"prompt": "Exiles Walk Beneath Egypt: move an ally (up to two), or skip.",
		"pick": "character_tile", "optional": true, "characters": choices.keys(), "tiles_by_character": choices}


func resolve_choice(sys, player_id: String, payload: Dictionary) -> Dictionary:
	if not payload.has("target_id"):
		return {"success": true}
	var pending := RelicEventDeck.get_pending_choice(player_id)
	var spec := choice_spec(sys, player_id, pending)
	var id := str(payload.target_id)
	if not spec.characters.has(id) or not spec.tiles_by_character[id].has(payload.get("to")):
		return {"success": false, "reason": "choose an eligible ally and an empty adjacent tile"}
	sys.move_character(sys.find(id), payload.to)
	var moved: Array = pending.get("moved", []).duplicate()
	moved.append(id)
	var next := pending.duplicate()
	next["moved"] = moved
	if moved.size() < 2 and not choice_spec(sys, player_id, next).characters.is_empty():
		return {"success": true, "pending": next}
	return {"success": true}
