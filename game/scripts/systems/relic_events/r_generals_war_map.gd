extends RelicEventHandler
# General's War Map (Relic): once each turn, one of your characters gains +1 RANGE on its
# next attack or ability. Offered at each of the owner's turn starts as the player-level
# "generals_war_map" reactive bonus; the chosen character is the action's actor.


func on_owner_turn_started(sys, owner_id: String) -> void:
	sys.state().get_player(owner_id).player_flags_this_turn["generals_war_map_available"] = true
