extends RelicEventHandler
# Dream Of The Deep City (Event, Immediate): reveal the next shared relic/event card; the
# active player leaves it on top or puts it on the bottom: deck_choice {"to_bottom": bool}.


func resolve_immediate(_sys, _player_id: String) -> Dictionary:
	var next := RelicEventDeck.peek_next()
	return {"needs_choice": true, "revealed": next} if next != "" else {}


func resolve_choice(_sys, _player_id: String, payload: Dictionary) -> Dictionary:
	if payload.get("to_bottom", false):
		RelicEventDeck.move_top_to_bottom()
	return {"success": true}
