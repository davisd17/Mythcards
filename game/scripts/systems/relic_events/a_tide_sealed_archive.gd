extends RelicEventHandler


func on_equipped(_sys, _owner_id: String) -> void:
	pass   # Healing occurs at turn start, not when the relic is drawn.


func on_owner_turn_started(sys, _owner_id: String) -> void:
	for c in sys.live_characters():
		for n in sys.neighbors(c.position):
			if sys.board.get_placed_object(n) != null:
				sys.heal(c, 1)
				break
