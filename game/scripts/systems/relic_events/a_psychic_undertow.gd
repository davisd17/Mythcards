extends RelicEventHandler
# Psychic Undertow (Event, 1 turn): the active player's first attack this turn may push
# or pull the target 1 tile (attack payload {"undertow": "push"|"pull"}).


func on_activate(sys, player_id: String) -> Dictionary:
	sys.state().get_player(player_id).player_flags_this_turn["psychic_undertow_pending"] = true
	return {}


func on_expire(sys, player_id: String, _data: Dictionary) -> void:
	sys.state().get_player(player_id).player_flags_this_turn.erase("psychic_undertow_pending")
