extends RelicEventHandler
# The Causeway Breathes (Event, 1 turn): place 1 allied Stone marker on an empty tile
# within 2 of the center tile. The active player's first movement action this turn may
# move through 1 placed object without taking effects from that object, but must end on
# an empty tile. Choice: {"tiles": [pos]}.

const REACH := 2


func on_activate(sys, player_id: String) -> Dictionary:
	sys.state().get_player(player_id).player_flags_this_turn["causeway_pending"] = true
	return {"needs_choice": true} if not _candidates(sys).is_empty() else {}


func on_expire(sys, player_id: String, _data: Dictionary) -> void:
	sys.state().get_player(player_id).player_flags_this_turn.erase("causeway_pending")


func choice_spec(sys, _player_id: String, _pending: Dictionary) -> Dictionary:
	return {"prompt": "The Causeway Breathes: place your Stone marker within 2 of the center.",
			"pick": "tiles", "count": 1, "tiles": _candidates(sys)}


func resolve_choice(sys, player_id: String, payload: Dictionary) -> Dictionary:
	var tiles: Array = payload.get("tiles", [])
	if tiles.size() != 1 or not _candidates(sys).has(tiles[0]):
		return {"success": false, "reason": "choose an empty tile within 2 of the center"}
	sys.board.place_object(tiles[0], "stone", player_id)
	return {"success": true}


func _candidates(sys) -> Array[Vector2i]:
	return tiles_near_center(sys, REACH, func(pos): return sys.is_empty_tile(pos) and not sys.has_leak(pos))
