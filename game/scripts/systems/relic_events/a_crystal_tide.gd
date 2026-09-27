extends RelicEventHandler
# Crystal Tide (Event, 1 turn): the active player's characters have +1 RANGE on
# abilities this turn (abilities only; attacks unaffected).


func on_activate(sys, player_id: String) -> Dictionary:
	sys.state().get_player(player_id).player_flags_this_turn["crystal_tide"] = true
	return {}


func on_expire(sys, player_id: String, _data: Dictionary) -> void:
	sys.state().get_player(player_id).player_flags_this_turn.erase("crystal_tide")
