extends RelicEventHandler
# Winter Palace Standard (Relic): your Hero and Leader each gain +1 maximum HP.

const BONUS := 1


func get_max_hp_bonus(_sys, owner_id: String, target: CharacterInstance) -> int:
	return BONUS if target.player_id == owner_id and ["Hero", "Leader"].has(target.data.type) else 0
