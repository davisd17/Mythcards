extends RelicEventHandler
# Quartz Heart Core (Relic): your shields prevent +1 additional damage.

const BONUS := 1


func get_shield_bonus(_sys, owner_id: String, defender: CharacterInstance) -> int:
	return BONUS if defender.player_id == owner_id else 0
