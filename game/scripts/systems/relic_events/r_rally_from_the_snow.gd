extends RelicEventHandler
# Rally From The Snow (Event, Immediate): the active player heals 1 HP on one damaged
# character. The player picks it: deck_choice {"target_id": id}.

const HEAL := 1


func resolve_immediate(sys, player_id: String) -> Dictionary:
	return {"needs_choice": true} if not _damaged(sys, player_id).is_empty() else {}


func resolve_choice(sys, player_id: String, payload: Dictionary) -> Dictionary:
	var target_id := str(payload.get("target_id", ""))
	if not _damaged(sys, player_id).has(target_id):
		return {"success": false, "reason": "choose one of your damaged characters"}
	sys.heal(sys.find(target_id), HEAL)
	return {"success": true}


static func _damaged(sys, player_id: String) -> Array[String]:
	var result: Array[String] = []
	for c in sys.live_characters():
		if c.player_id == player_id and c.current_hp < sys.get_effective_max_hp(c):
			result.append(c.instance_id)
	return result
