extends RelicEventHandler
# Reactor Prayer (Event, 1 turn): choose one of your characters. It takes 1 damage, then
# its next attack or AP ability this turn gains +1 ATK or +1 RANGE.
# Choice: {"target_id": id, "boost": "atk"|"range"}.


func on_activate(_sys, _player_id: String) -> Dictionary:
	return {"needs_choice": true}


func choice_spec(sys, player_id: String, _pending: Dictionary) -> Dictionary:
	return {"prompt": "Reactor Prayer: one of your characters takes 1 damage, then gets +1 ATK or +1 RANGE on its next attack or ability.",
			"pick": "character", "characters": ids(own_live(sys, player_id)),
			"options": [{"label": "+1 ATK", "payload": {"boost": "atk"}},
					{"label": "+1 RANGE", "payload": {"boost": "range"}}]}


func resolve_choice(sys, player_id: String, payload: Dictionary) -> Dictionary:
	var target: CharacterInstance = sys.find(str(payload.get("target_id", "")))
	if target == null or target.player_id != player_id:
		return {"success": false, "reason": "choose one of your characters"}
	if not ["atk", "range"].has(payload.get("boost")):
		return {"success": false, "reason": "choose +1 ATK or +1 RANGE"}
	sys.combat().apply_hazard_damage(target, 1)
	if not target.defeated:
		var kind := "temp_atk" if payload.boost == "atk" else "temp_range"
		var se: StatusEffect = sys.add_status(target, kind, 1, "this_turn", null, true)
		se.consume_on_ability = true
	return {"success": true}
