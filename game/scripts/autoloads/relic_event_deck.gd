extends Node
# Autoload name: RelicEventDeck — shared deck construction, draw, and relic slots (HLD 4.9).
# Empty singleton scaffold (HLD Section 13, step 2). Implemented in LLD-relic-event-deck.md.


func build_deck(_p1_culture: String, _p2_culture: String, _deck_seed: int) -> void:
	# Placeholder so SetupFlow.start_match can call it; real logic in LLD-relic-event-deck.md.
	pass


func draw_for(_player_id: String) -> void:
	# Placeholder so TurnManager.start_turn can call it; real logic in LLD-relic-event-deck.md.
	pass


# Deck-top access for Foresight / Dream Of The Deep City (LLD-ability-system 5.12).
# Operates on MatchState.shared_deck, where index 0 is the next card drawn.
func peek_next() -> String:
	var state := GameState.match_state
	return state.shared_deck[0] if state != null and not state.shared_deck.is_empty() else ""


func move_top_to_bottom() -> void:
	var state := GameState.match_state
	if state != null and state.shared_deck.size() > 1:
		state.shared_deck.append(state.shared_deck.pop_front())
