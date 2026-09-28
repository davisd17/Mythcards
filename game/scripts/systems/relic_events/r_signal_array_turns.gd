extends RelicEventHandler
# Signal Array Turns (Event, 1 turn): the active player's first ranged attack or ranged
# AP ability this turn gains +1 RANGE if the acting character is adjacent to a placed
# object or Leak marker. (AbilitySystem adds the RANGE; RulesEngine spends the flag.)


func on_activate(sys, player_id: String) -> Dictionary:
	sys.state().get_player(player_id).player_flags_this_turn["signal_array_pending"] = true
	return {}


func on_expire(sys, player_id: String, _data: Dictionary) -> void:
	sys.state().get_player(player_id).player_flags_this_turn.erase("signal_array_pending")
