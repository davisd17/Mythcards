extends RelicEventHandler
# Iron Birch Talisman (Relic): your Common and Warrior each gain +1 maximum HP.

const BONUS := 1


func get_max_hp_bonus(_sys, owner_id: String, target: CharacterInstance) -> int:
	return BONUS if target.player_id == owner_id and ["Common", "Warrior"].has(target.data.type) else 0
