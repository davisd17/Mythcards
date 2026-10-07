extends RelicEventHandler
# Closed City Incident (Event, Immediate): place 2 Leak markers on different empty tiles
# within 2 of the center tile. The active player picks: {"tiles": [pos, pos]}.

const REACH := 2
const COUNT := 2


func resolve_immediate(sys, _player_id: String) -> Dictionary:
	return {"needs_choice": true} if not _candidates(sys).is_empty() else {}


func choice_spec(sys, _player_id: String, _pending: Dictionary) -> Dictionary:
	var tiles := _candidates(sys)
	var count := mini(COUNT, tiles.size())
	return {"prompt": "Closed City Incident: place %d Leak markers within 2 of the center." % count,
			"pick": "tiles", "count": count, "tiles": tiles}


func resolve_choice(sys, _player_id: String, payload: Dictionary) -> Dictionary:
	var tiles: Array = payload.get("tiles", [])
	var candidates := _candidates(sys)
	var needed := mini(COUNT, candidates.size())
	if tiles.size() != needed:
		return {"success": false, "reason": "choose %d tiles" % needed}
	for pos in tiles:
		if not candidates.has(pos) or tiles.count(pos) > 1:
			return {"success": false, "reason": "choose different empty tiles within 2 of the center"}
	for pos in tiles:
		sys.place_leak(pos)
	return {"success": true}


func _candidates(sys) -> Array[Vector2i]:
	return tiles_near_center(sys, REACH, func(pos): return sys.can_place_leak(pos))
