extends RelicEventHandler


func get_range_bonus(_sys, owner_id: String, instance: CharacterInstance, _context: String) -> int:
	return 1 if instance.player_id == owner_id and ["Leader", "Specialist"].has(instance.data.type) else 0
