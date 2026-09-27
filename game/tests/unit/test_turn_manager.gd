extends GutTest
# TurnManager — LLD-match-setup.md Section 8, cases C8–C13.

const SetupFlowScript := preload("res://scripts/scenes/setup_flow.gd")


class FakeDeck:
	var draws: Array[String] = []
	func build_deck(_a, _b, _c) -> void:
		pass
	func draw_for(player_id: String) -> void:
		draws.append(player_id)


class NoCapture:
	var checked: Array[String] = []
	func check_hero_capture(player_id: String) -> void:
		checked.append(player_id)


class AlwaysCapture:
	func check_hero_capture(player_id: String) -> void:
		GameState.match_state.phase = "ended"
		GameState.match_state.winner_id = GameState.match_state.get_other_player_id(player_id)
		GameState.match_state.win_condition = "hero_capture"


var deck: FakeDeck
var checker: NoCapture


func before_each() -> void:
	deck = FakeDeck.new()
	checker = NoCapture.new()
	TurnManager.relic_event_deck = deck
	TurnManager.victory_checker = checker
	var setup = autofree(SetupFlowScript.new())
	setup.select_culture("p1", "Russian-inspired")
	setup.select_culture("p2", "Atlantean")
	for id in ["p1", "p2"]:
		var row := 0 if id == "p1" else 6
		var x := 0
		for c in setup.get_player(id).characters:
			setup.place_character(id, c.instance_id, Vector2i(x, row))
			x += 1
	watch_signals(EventBus)
	setup.start_match()   # starts p1's first turn (turn_number 1)


func after_each() -> void:
	GameState.reset()
	TurnManager.relic_event_deck = null
	TurnManager.victory_checker = null


func _state() -> MatchState:
	return GameState.match_state


func _player(id: String) -> PlayerState:
	return _state().get_player(id)


# --- AP refresh ----------------------------------------------------------------

func test_c8_first_turn_of_match_gets_2_pool_ap() -> void:
	assert_eq(_player("p1").pool_ap_max, 2)
	assert_eq(_player("p1").pool_ap_remaining, 2)
	for c in _player("p1").characters:
		assert_eq(c.character_ap_remaining, c.character_ap_max, c.instance_id)


func test_c8a_second_players_opening_turn_gets_4() -> void:
	TurnManager.end_turn("p1")
	assert_eq(_state().turn_number, 2)
	assert_eq(_player("p2").pool_ap_remaining, 4)


func test_c8b_c9_first_players_second_turn_gets_4() -> void:
	TurnManager.end_turn("p1")
	TurnManager.end_turn("p2")
	assert_eq(_state().turn_number, 3)
	assert_eq(_player("p1").pool_ap_remaining, 4)


func test_spent_ap_and_turn_limits_refresh_at_turn_start() -> void:
	var c: CharacterInstance = _player("p1").characters[0]
	c.character_ap_remaining = 0
	c.ability_uses_this_turn["service_route"] = 1
	c.ability_uses_this_match["slumber"] = 1
	_player("p1").pool_ap_remaining = 0
	_player("p1").player_flags_this_turn["first_move_bonus"] = true
	TurnManager.end_turn("p1")
	TurnManager.end_turn("p2")
	assert_eq(c.character_ap_remaining, 1)
	assert_eq(_player("p1").pool_ap_remaining, 4)
	assert_true(c.ability_uses_this_turn.is_empty())
	assert_eq(c.ability_uses_this_match, {"slumber": 1}, "per-match limits survive")
	assert_true(_player("p1").player_flags_this_turn.is_empty())


func test_only_the_active_players_characters_refresh() -> void:
	var enemy: CharacterInstance = _player("p2").characters[0]
	enemy.character_ap_remaining = 0
	TurnManager.end_turn("p1")   # p2's turn starts: refreshes p2
	assert_eq(enemy.character_ap_remaining, 1)
	var own: CharacterInstance = _player("p1").characters[0]
	own.character_ap_remaining = 0
	enemy.character_ap_remaining = 0
	TurnManager.end_turn("p2")   # p1's turn: refreshes p1, leaves p2 alone
	assert_eq(own.character_ap_remaining, 1)
	assert_eq(enemy.character_ap_remaining, 0)


func test_each_turn_start_draws_for_the_active_player() -> void:
	TurnManager.end_turn("p1")
	TurnManager.end_turn("p2")
	assert_eq(deck.draws, ["p1", "p2", "p1"] as Array[String])


# --- Turn handoff ------------------------------------------------------------

func test_c10_end_turn_flips_active_player() -> void:
	TurnManager.end_turn("p1")
	assert_eq(_state().active_player_id, "p2")
	assert_eq(_state().turn_number, 2)
	assert_eq(checker.checked, ["p1"] as Array[String], "capture check ran for the player who just acted")


func test_c11_end_turn_emits_turn_ended_then_turn_started() -> void:
	TurnManager.end_turn("p1")
	assert_signal_emitted_with_parameters(EventBus, "turn_ended", ["p1"])
	assert_signal_emitted_with_parameters(EventBus, "turn_started", ["p2"])


func test_c12_start_turn_emits_pool_ap_changed() -> void:
	assert_signal_emitted_with_parameters(EventBus, "pool_ap_changed", ["p1", 2])
	TurnManager.end_turn("p1")
	assert_signal_emitted_with_parameters(EventBus, "pool_ap_changed", ["p2", 4])


func test_start_turn_emits_character_ap_changed_for_each_character() -> void:
	assert_signal_emit_count(EventBus, "character_ap_changed", 7)


func test_c13_capture_ends_match_without_flipping() -> void:
	TurnManager.victory_checker = AlwaysCapture.new()
	TurnManager.end_turn("p1")
	assert_eq(_state().phase, "ended")
	assert_eq(_state().active_player_id, "p1")
	assert_eq(_state().turn_number, 1)
	assert_signal_not_emitted(EventBus, "turn_ended")


# --- Status-effect expiry (LLD 4.3) ------------------------------------------

func _p1_char() -> CharacterInstance:
	return _player("p1").characters[0]


func _effect(expires: String, applied_on_turn: int) -> StatusEffect:
	var se := StatusEffect.new("slow", 0, expires, applied_on_turn)
	_p1_char().status_effects.append(se)
	return se


func test_this_turn_effect_is_gone_at_owners_next_turn() -> void:
	_effect("this_turn", 1)
	TurnManager.end_turn("p1")
	assert_true(_p1_char().has_status("slow"), "owner-turn clearing only; still present on p2's turn")
	TurnManager.end_turn("p2")
	assert_false(_p1_char().has_status("slow"))


func test_c8c_next_turn_effect_lasts_through_holders_next_turn() -> void:
	TurnManager.end_turn("p1")                 # turn 2: p2 acts...
	_effect("next_turn", 2)                    # ...and slows a p1 character
	TurnManager.end_turn("p2")                 # turn 3: p1's next turn — the one the card means
	assert_true(_p1_char().has_status("slow"), "active during the holder's next turn")
	TurnManager.end_turn("p1")                 # turn 4
	TurnManager.end_turn("p2")                 # turn 5: p1's following turn
	assert_false(_p1_char().has_status("slow"), "gone by the turn after")


func test_next_turn_self_buff_applied_on_own_turn() -> void:
	_effect("next_turn", 1)                    # p1 buffs own character on turn 1
	TurnManager.end_turn("p1")
	TurnManager.end_turn("p2")                 # turn 3: p1's next turn
	assert_true(_p1_char().has_status("slow"))
	TurnManager.end_turn("p1")
	TurnManager.end_turn("p2")                 # turn 5
	assert_false(_p1_char().has_status("slow"))


func test_this_round_effect_clears_after_both_players_act() -> void:
	_effect("this_round", 1)                   # applied on turn 1; round = turns 1 and 2
	TurnManager.end_turn("p1")
	TurnManager.end_turn("p2")                 # turn 3: 3 - 1 >= 2
	assert_false(_p1_char().has_status("slow"))


func test_this_round_effect_applied_by_opponent_survives_owners_next_turn() -> void:
	TurnManager.end_turn("p1")
	_effect("this_round", 2)                   # applied on p2's turn 2; round = turns 2 and 3
	TurnManager.end_turn("p2")                 # turn 3: 3 - 2 = 1, keep
	assert_true(_p1_char().has_status("slow"))
	TurnManager.end_turn("p1")
	TurnManager.end_turn("p2")                 # turn 5
	assert_false(_p1_char().has_status("slow"))


func test_immediate_effect_is_removed_defensively() -> void:
	_effect("immediate", 1)
	TurnManager.end_turn("p1")
	TurnManager.end_turn("p2")
	assert_false(_p1_char().has_status("slow"))
