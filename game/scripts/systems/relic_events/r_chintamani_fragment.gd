extends RelicEventHandler
# Chintamani Fragment (Rare Relic): once each turn, you may reveal the top card of the
# shared relic/event deck. You may leave it on top or place it on the bottom.

const CARD := "r-chintamani-fragment"


func power_available(sys, owner_id: String) -> bool:
	var used: int = RelicEventDeck.relic_state(owner_id, CARD).get("used_turn", -1)
	return used != sys.state().turn_number and RelicEventDeck.peek_next() != ""


func power_spec(_sys, _owner_id: String) -> Dictionary:
	return {"prompt": "Chintamani Fragment: reveal the top card of the deck?", "pick": "option",
			"options": [{"label": "Reveal", "payload": {}}]}


func use_power(sys, owner_id: String, _payload: Dictionary) -> Dictionary:
	RelicEventDeck.relic_state(owner_id, CARD)["used_turn"] = sys.state().turn_number
	var revealed := RelicEventDeck.peek_next()
	return {"success": true, "revealed": revealed, "pending": {"revealed": revealed}}


func choice_spec(_sys, _player_id: String, pending: Dictionary) -> Dictionary:
	var card := ContentDB.get_relic_event(pending.get("revealed", ""))
	var card_name: String = card.card_name if card != null else "the card"
	return {"prompt": "Next card: %s. Leave it on top or put it on the bottom?" % card_name,
			"pick": "option", "revealed": pending.get("revealed", ""),
			"options": [{"label": "Leave on top", "payload": {"to_bottom": false}},
					{"label": "Put on bottom", "payload": {"to_bottom": true}}]}


func resolve_choice(_sys, _player_id: String, payload: Dictionary) -> Dictionary:
	if payload.get("to_bottom", false):
		RelicEventDeck.move_top_to_bottom()
	return {"success": true}


# AI: keep its own culture's cards on top, bury the opponent's.
func ai_choice_value(sys, player_id: String, payload: Dictionary, _ai) -> float:
	if not payload.has("to_bottom"):
		return 0.5   # the Reveal step itself
	var pending: Dictionary = RelicEventDeck.get_pending_choice(player_id)
	var card := ContentDB.get_relic_event(str(pending.get("revealed", "")))
	if card == null:
		return 0.0
	var culture: String = sys.state().get_player(player_id).culture.to_lower().left(6)
	var ours := card.faction.to_lower().begins_with(culture)
	return 1.0 if ours != bool(payload.to_bottom) else 0.0
