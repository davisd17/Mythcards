extends RelicEventHandler


func get_max_hp_bonus(_sys, owner_id: String, target: CharacterInstance) -> int:
	return 1 if target.player_id == owner_id and target.data.type == "Mystic" else 0


func ai_choice_value(_sys, _player_id: String, payload: Dictionary, _ai) -> float:
	return 2.0 if payload.get("protect", false) else 0.0
