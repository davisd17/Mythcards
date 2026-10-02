extends RelicEventHandler
# Reactor Prayer (Event, 1 turn): choose one of your characters. It takes 1 damage and
# gains +1 character AP this turn. Choice: {"target_id": id}.


func on_activate(_sys, _player_id: String) -> Dictionary:
	return {"needs_choice": true}


func choice_spec(sys, player_id: String, _pending: Dictionary) -> Dictionary:
	return {"prompt": "Reactor Prayer: one of your characters takes 1 damage and gains +1 character AP this turn.",
			"pick": "character", "characters": ids(own_live(sys, player_id))}


func resolve_choice(sys, player_id: String, payload: Dictionary) -> Dictionary:
	var target: CharacterInstance = sys.find(str(payload.get("target_id", "")))
	if target == null or target.player_id != player_id:
		return {"success": false, "reason": "choose one of your characters"}
	sys.combat().apply_hazard_damage(target, 1)
	if not target.defeated:
		target.character_ap_remaining += 1
		EventBus.character_ap_changed.emit(target.instance_id, target.character_ap_remaining)
	return {"success": true}
