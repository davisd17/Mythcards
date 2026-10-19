extends RelicEventHandler
# The Mystic keeps Shield until used; only the +1 ATK expires this turn.


func on_activate(sys, player_id: String) -> Dictionary:
	var grants := []
	for c in own_live(sys, player_id):
		if c.data.type == "Mystic":
			sys.add_status(c, "shield", 1, "until_used")
			grants.append({"character": c,
				"atk": sys.add_status(c, "temp_atk", 1, "this_turn")})
	return {"grants": grants}


func on_expire(_sys, _player_id: String, data: Dictionary) -> void:
	# Remove only this event's attack bonus; Shield persists until consumed.
	for grant in data.get("grants", []):
		grant.character.status_effects.erase(grant.atk)
