extends Node
# Autoload name: GameState — holds the live MatchState (HLD 5.1, LLD-match-setup 3.7).
# A pure holder with no validation logic.

var match_state: MatchState = null   # null until SetupFlow.start_match()


func start_match(state: MatchState) -> void:
	match_state = state
	match_state.phase = "in_progress"


func is_match_active() -> bool:
	return match_state != null and match_state.phase == "in_progress"


func reset() -> void:
	match_state = null
