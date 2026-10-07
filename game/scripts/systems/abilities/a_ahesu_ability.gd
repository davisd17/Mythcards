extends AbilityHandler
# Ahesu, the Stone-Current Serpent (Flood Survivors Mount) — LLD-closed-city-flood-roster.md 4.
# L1 Stone-Current: may move through allied Stone markers, ending on an empty tile. A
#    mounted pair moves with Ahesu's rules, so it uses Stone-Current too.
# L2 Living Causeway: +1 MOVE. If Ahesu starts a move adjacent to a Stone (any), it may
#    also pass 1 occupied allied tile on that move.
# L3 The Deep Remembers Its Teeth: +2 ATK and +1 HP.


func level_bonuses() -> Dictionary:
	return {2: {"move": 1}, 3: {"atk": 2, "hp": 1}}


func get_movement_object_passable_predicate(sys, instance: CharacterInstance) -> Callable:
	return func(pos: Vector2i) -> bool:
		var obj: PlacedObjectInstance = sys.board.get_placed_object(pos)
		return obj != null and obj.type_id == "stone" and obj.owner_player_id == instance.player_id


func get_movement_passable_predicate(sys, instance: CharacterInstance) -> Callable:
	if not _causeway_ready(sys, instance):
		return Callable()
	return func(pos: Vector2i) -> bool:
		var c: CharacterInstance = sys.occupant(pos)
		return c != null and c.player_id == instance.player_id


func get_movement_max_passes(_sys, _instance: CharacterInstance) -> int:
	return -1   # any number of allied Stones


func get_movement_max_char_passes(_sys, _instance: CharacterInstance) -> int:
	return 1    # but only 1 ally (Living Causeway)


func _causeway_ready(sys, instance: CharacterInstance) -> bool:
	if instance.level < 2:
		return false
	for pos in sys.neighbors(instance.position):
		var obj: PlacedObjectInstance = sys.board.get_placed_object(pos)
		if obj != null and obj.type_id == "stone":
			return true
	return false
