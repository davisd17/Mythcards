extends RelicEventHandler
# Reactor Core Fragment (Relic): your Specialist and Mystic each gain +1 ATK. When one of
# them takes Leak damage, it gains +1 RANGE on its next AP ability this turn.

const TYPES := ["Specialist", "Mystic"]


func get_atk_bonus(_sys, owner_id: String, instance: CharacterInstance) -> int:
	return 1 if instance.player_id == owner_id and TYPES.has(instance.data.type) else 0


func on_leak_triggered(sys, owner_id: String, character_id: String, _pos: Vector2i) -> void:
	var c: CharacterInstance = sys.find(character_id)
	if c != null and c.player_id == owner_id and TYPES.has(c.data.type):
		var se: StatusEffect = sys.add_status(c, "temp_ability_range", 1, "this_turn")
		se.consume_on_ability = true
