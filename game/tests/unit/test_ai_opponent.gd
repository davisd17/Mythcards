extends GutTest
# The opponent AI (LLD-ai-opponent.md 6). It acts only through RulesEngine, so a rejected
# action anywhere is a bug: AIPlayer push_errors it, which fails the test.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const SetupFlowScript := preload("res://scripts/scenes/setup_flow.gd")
const YURI := "p1_r-yuri-volkov"
const ORLOV := "p1_r-mikhail-orlov"
const WORKER := "p1_r-reactor-worker"
const VERA := "p1_r-vera-7"
const NAIA := "p2_a-flood-survivor-naia"
const LABORER := "p2_a-flood-survivor-stone-line-laborer"


func after_each() -> void:
	Fixture.teardown()


func _arranged() -> AIPlayer:
	autofree(Fixture.start_teams_match())
	Fixture.state().shared_deck.clear()
	Fixture.clear_board()
	Fixture.state().get_player("p1").pool_ap_remaining = 4
	return AIPlayer.new("p1")


func test_takes_an_available_defeat() -> void:
	var ai := _arranged()
	Fixture.put(ORLOV, Vector2i(0, 0))
	Fixture.put(YURI, Vector2i(3, 2))
	var laborer := Fixture.put(LABORER, Vector2i(3, 3))
	laborer.current_hp = 1
	Fixture.put(NAIA, Vector2i(6, 6))
	var action := ai.next_action()
	assert_eq([action.action_type, action.payload.get("target_id", action.payload.get("target"))],
			["attack", LABORER], str(action))


func test_frees_a_trapped_hero_before_ending_the_turn() -> void:
	var ai := _arranged()
	var orlov := Fixture.put(ORLOV, Vector2i(0, 0))
	Fixture.put(WORKER, Vector2i(1, 0))
	Fixture.put(VERA, Vector2i(0, 1))
	Fixture.put(NAIA, Vector2i(6, 6))
	assert_true(RulesEngine.get_legal_move_tiles(ORLOV).is_empty(), "arranged: Orlov can't move")
	ai.take_turn()
	TurnManager.victory_checker = null
	assert_eq(Fixture.state().phase, "in_progress")
	assert_false(RulesEngine.get_legal_move_tiles(ORLOV).is_empty() and orlov.is_placed(),
			"a blocker stepped aside before the turn ended")


func test_answers_a_drawn_card_and_returns_off_board_characters() -> void:
	var ai := _arranged()
	var orlov := Fixture.put(ORLOV, Vector2i(3, 2))
	Fixture.put(NAIA, Vector2i(6, 6))
	RulesEngine.systems().ability.remove_from_board(orlov, {"kind": "within", "reach": 2})
	TurnManager.relic_event_deck = null
	RulesEngine.request_action("end_turn", "p1", {})
	Fixture.state().shared_deck = ["r-closed-city-incident"] as Array[String]   # Player 1 draws it next
	RulesEngine.request_action("end_turn", "p2", {})
	assert_true(RelicEventDeck.has_pending_choice("p1"))
	assert_eq(ai.next_action().action_type, "deck_choice")
	ai.take_turn()
	assert_true(orlov.is_placed(), "returned to the board")
	assert_false(RelicEventDeck.has_pending_choice("p1"))


func test_every_candidate_names_a_real_action() -> void:
	_arranged()
	Fixture.put(ORLOV, Vector2i(3, 0))
	Fixture.put("p1_r-elena-morozova", Vector2i(2, 0))
	Fixture.put(NAIA, Vector2i(3, 4))
	var candidates := ActionGenerator.new("p1").generate()
	var kinds := {}
	for c in candidates:
		kinds[c.kind] = true
	assert_true(kinds.has("move") and kinds.has("ability"), str(kinds.keys()))
	assert_true(candidates.any(func(c): return c.payload.get("ability_id") == "r-mikhail-orlov"), "Reactor Leak")


# Two AIs play Closed City vs Flood Survivors with the real deck and victory checker.
func _ai_match(seed_value: int, max_turns: int) -> Dictionary:
	TurnManager.relic_event_deck = null
	TurnManager.victory_checker = null
	GameState.reset()
	var setup: Node = autofree(SetupFlowScript.new())
	setup.select_team("p1", "closed-city")
	setup.select_team("p2", "flood-survivors")
	var players := {"p1": AIPlayer.new("p1", null, seed_value), "p2": AIPlayer.new("p2", null, seed_value + 100)}
	players.p1.place_squad(setup)
	players.p2.place_squad(setup)
	setup.start_match(seed_value)
	var actions := 0
	var state := GameState.match_state
	var guard := 0   # a broken AI fails the test instead of hanging the run
	while state.phase == "in_progress" and state.turn_number <= max_turns and guard < max_turns * 2:
		actions += players[state.active_player_id].take_turn().size()
		guard += 1
	return {"phase": state.phase, "winner": state.winner_id, "how": state.win_condition, "turns": state.turn_number,
			"actions": actions}


func test_ai_vs_ai_matches_play_out() -> void:
	var finished := 0
	for seed_value in [1, 2, 3, 4]:
		var result := _ai_match(seed_value, 120)
		gut.p("seed %d: %s" % [seed_value, result])
		assert_gt(result.actions, result.turns, "more than just ending turns")
		if result.phase == "ended":
			finished += 1
	# A stalling AI is a bug (seed 2 once stalled 120 turns between two cautious Heroes).
	assert_gte(finished, 3, "matches reach a win instead of stalling")


func test_drawn_card_choices_use_judgment() -> void:
	# Reactor Prayer: 1 damage to one of your characters. Never the one about to fall.
	var ai := _arranged()
	var laborer_side := AIPlayer.new("p1")
	Fixture.put(ORLOV, Vector2i(3, 0))
	var worker := Fixture.put(WORKER, Vector2i(0, 0))
	worker.current_hp = 1
	Fixture.put(NAIA, Vector2i(6, 6))
	TurnManager.relic_event_deck = null
	Fixture.state().shared_deck = ["r-reactor-prayer"] as Array[String]
	RelicEventDeck.draw_for("p1")
	var action := ai.next_action()
	assert_eq(action.action_type, "deck_choice")
	assert_eq(action.payload.target_id, ORLOV, "not the 1-HP Reactor Worker")
	assert_not_null(laborer_side)


func test_never_walls_in_its_own_hero_with_a_card_choice() -> void:
	# Found by the AI-vs-AI run (seed 2): The Causeway Breathes' Stones trapped the AI's Hero.
	var ai := AIPlayer.new("p2")
	autofree(Fixture.start_teams_match())
	Fixture.state().shared_deck.clear()
	Fixture.clear_board()
	RulesEngine.request_action("end_turn", "p1", {})
	var sahu := Fixture.put("p2_a-flood-survivor-sahu-ren", Vector2i(3, 6))
	Fixture.put("p2_a-flood-survivor-naia", Vector2i(2, 6))
	Fixture.put("p2_a-flood-survivor-meret-anu", Vector2i(4, 6))
	Fixture.put(ORLOV, Vector2i(0, 0))
	TurnManager.relic_event_deck = null
	# A Stone on (3,5) would leave Sahu-Ren with nowhere to go.
	assert_true(ai.evaluator.score({"kind": "deck_choice", "actor_id": "p2",
			"payload": {"tiles": [Vector2i(3, 5), Vector2i(2, 4)]}}).score <= AIEvaluator.VETO)
	assert_false(RulesEngine.get_legal_move_tiles(sahu.instance_id).is_empty())
