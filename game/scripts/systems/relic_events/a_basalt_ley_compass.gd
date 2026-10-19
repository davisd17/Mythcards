extends RelicEventHandler


func get_move_bonus(_sys, owner_id: String, instance: CharacterInstance) -> int:
	return 1 if instance.player_id == owner_id and ["Common", "Specialist"].has(instance.data.type) else 0
