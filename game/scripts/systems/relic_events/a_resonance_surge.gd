extends RelicEventHandler
# Resonance Surge (Event, 1 turn): the active player's first ability this turn has
# +1 RANGE (AbilitySystem adds it; RulesEngine spends the flag on the first ability).


func on_activate(sys, player_id: String) -> Dictionary:
	sys.state().get_player(player_id).player_flags_this_turn["resonance_surge_pending"] = true
	return {}


func on_expire(sys, player_id: String, _data: Dictionary) -> void:
	sys.state().get_player(player_id).player_flags_this_turn.erase("resonance_surge_pending")
