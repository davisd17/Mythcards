extends GutTest

const Fixture := preload("res://tests/helpers/match_fixture.gd")


func after_each() -> void:
	Fixture.teardown()


func test_setup_starts_approved_closed_city_theme_with_full_loop() -> void:
	autofree(Fixture.start_teams_match())
	assert_eq(MusicManager.current_sub_area, "Closed City")
	var player := MusicManager.get_node("MatchMusic") as AudioStreamPlayer
	assert_true(player.playing)
	var stream := player.stream as AudioStreamWAV
	assert_not_null(stream)
	if stream == null:
		return
	assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	assert_eq(stream.loop_begin, 0)
	assert_eq(stream.loop_end, 2671304)
	assert_almost_eq(stream.get_length(), 83.47825, .001)


func test_turn_change_keeps_the_starting_leaders_theme() -> void:
	autofree(Fixture.start_teams_match())
	var player := MusicManager.get_node("MatchMusic") as AudioStreamPlayer
	var stream := player.stream
	TurnManager.end_turn("p1")
	assert_eq(GameState.match_state.active_player_id, "p2")
	assert_eq(MusicManager.current_sub_area, "Closed City")
	assert_same(player.stream, stream, "Do not replace or restart music on turn changes")
	assert_true(player.playing)


func test_unscored_starting_leader_does_not_use_opponents_theme() -> void:
	autofree(Fixture.start_teams_match())
	var state := GameState.match_state
	state.first_player_id = "p2"
	GameState.start_match(state)
	assert_eq(MusicManager.current_sub_area, "Flood Survivors")
	var player := MusicManager.get_node("MatchMusic") as AudioStreamPlayer
	assert_false(player.playing)
	assert_null(player.stream)


func test_player_two_can_select_closed_city_by_leader_not_team() -> void:
	autofree(Fixture.start_teams_match())
	var state := GameState.match_state
	# Swap squads so p2 starts with the Closed City leader; team metadata stays put.
	var first_squad := state.players[0].characters
	state.players[0].characters = state.players[1].characters
	state.players[1].characters = first_squad
	state.first_player_id = "p2"
	GameState.start_match(state)
	assert_eq(MusicManager.current_sub_area, "Closed City")
	assert_true((MusicManager.get_node("MatchMusic") as AudioStreamPlayer).playing)


func test_reset_and_match_end_stop_music() -> void:
	autofree(Fixture.start_teams_match())
	var player := MusicManager.get_node("MatchMusic") as AudioStreamPlayer
	EventBus.match_ended.emit("p1", "test")
	assert_false(player.playing)
	assert_null(player.stream)
	GameState.start_match(GameState.match_state)
	assert_true(player.playing)
	GameState.reset()
	assert_false(player.playing)
	assert_null(player.stream)
	assert_eq(MusicManager.current_sub_area, "")


func test_missing_starting_leader_is_silent() -> void:
	autofree(Fixture.start_teams_match())
	var state := GameState.match_state
	state.get_player("p1").characters = []
	GameState.start_match(state)
	assert_eq(MusicManager.current_sub_area, "")
	assert_false((MusicManager.get_node("MatchMusic") as AudioStreamPlayer).playing)
