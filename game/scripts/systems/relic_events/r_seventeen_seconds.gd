extends RelicEventHandler
# Seventeen Seconds (Event, 1 turn): each of your characters may move through 1 occupied
# tile or placed object this turn, but must end on an empty tile.


func on_activate(sys, player_id: String) -> Dictionary:
	sys.state().get_player(player_id).player_flags_this_turn["seventeen_seconds_active"] = true
	return {}


func on_expire(sys, player_id: String, _data: Dictionary) -> void:
	sys.state().get_player(player_id).player_flags_this_turn.erase("seventeen_seconds_active")
