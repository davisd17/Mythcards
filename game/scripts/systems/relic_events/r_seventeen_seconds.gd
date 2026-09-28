extends RelicEventHandler
# Seventeen Seconds (Event, 1 turn): the active player's first movement action this turn
# may move through 1 occupied tile, placed object, or Leak marker, but must end on an
# empty tile. (AbilitySystem.movement_grants; RulesEngine spends it on the first move.)


func on_activate(sys, player_id: String) -> Dictionary:
	sys.state().get_player(player_id).player_flags_this_turn["seventeen_seconds_pending"] = true
	return {}


func on_expire(sys, player_id: String, _data: Dictionary) -> void:
	sys.state().get_player(player_id).player_flags_this_turn.erase("seventeen_seconds_pending")
