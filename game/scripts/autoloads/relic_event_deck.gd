extends Node
# Autoload name: RelicEventDeck — shared deck construction, draw, and relic slots (HLD 4.9).
# Empty singleton scaffold (HLD Section 13, step 2). Implemented in LLD-relic-event-deck.md.


func build_deck(_p1_culture: String, _p2_culture: String, _deck_seed: int) -> void:
	# Placeholder so SetupFlow.start_match can call it; real logic in LLD-relic-event-deck.md.
	pass


func draw_for(_player_id: String) -> void:
	# Placeholder so TurnManager.start_turn can call it; real logic in LLD-relic-event-deck.md.
	pass
