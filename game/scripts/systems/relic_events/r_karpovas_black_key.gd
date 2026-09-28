extends RelicEventHandler
# Karpova's Black Key (Relic): your Leader and Common each gain +1 MOVE. Once each turn,
# one of them may move through 1 placed object or allied occupied tile, but must end on
# an empty tile. (The pass is granted in AbilitySystem.movement_grants and spent by
# RulesEngine when a move actually needs it.)

const TYPES := ["Leader", "Common"]


func get_move_bonus(_sys, owner_id: String, instance: CharacterInstance) -> int:
	return 1 if instance.player_id == owner_id and TYPES.has(instance.data.type) else 0
