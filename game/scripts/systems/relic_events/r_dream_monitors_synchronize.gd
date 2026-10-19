extends RelicEventHandler


func _commons(sys) -> Array:
	var result := []
	for player in sys.state().players:
		var common: CharacterInstance = null
		for c in player.characters:
			if c.data.type == "Common" and not c.defeated and c.is_placed():
				common = c
		if common == null:
			return []
		result.append(common)
	return result


func resolve_immediate(sys, _player_id: String) -> Dictionary:
	return {"needs_choice": true} if _commons(sys).size() == 2 else {}


func choice_spec(_sys, _player_id: String, _pending: Dictionary) -> Dictionary:
	return {"prompt": "Dream Monitors Synchronize: swap both Commons?", "pick": "option", "options": [
		{"label": "Swap Commons", "payload": {"swap": true}},
		{"label": "Keep positions", "payload": {"swap": false}}]}


func resolve_choice(sys, _player_id: String, payload: Dictionary) -> Dictionary:
	if not payload.get("swap") is bool:
		return {"success": false, "reason": "choose whether to swap"}
	var commons := _commons(sys)
	if payload.swap and commons.size() == 2:
		sys.swap_characters(commons[0], commons[1], "dream_monitors")
	return {"success": true}
