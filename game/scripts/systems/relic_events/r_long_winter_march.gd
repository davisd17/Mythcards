extends RelicEventHandler
# Long Winter March (Event, 1 turn): the active player's first movement action this turn
# gains +1 MOVE (RulesEngine reads and spends the flag).


func on_activate(sys, player_id: String) -> Dictionary:
	sys.state().get_player(player_id).player_flags_this_turn["long_winter_march_pending"] = true
	return {}


func on_expire(sys, player_id: String, _data: Dictionary) -> void:
	sys.state().get_player(player_id).player_flags_this_turn.erase("long_winter_march_pending")
