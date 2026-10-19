extends RelicEventHandler


func get_max_hp_bonus(_sys, owner_id: String, target: CharacterInstance) -> int:
	return 1 if target.player_id == owner_id and ["Mount", "Warrior"].has(target.data.type) else 0


func on_equipped(sys, owner_id: String) -> void:
	for c in own_live(sys, owner_id):
		if ["Mount", "Warrior"].has(c.data.type):
			sys.remove_status(c, "marked")
