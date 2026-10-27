extends GutTest

const Fixture := preload("res://tests/helpers/match_fixture.gd")
var _saved_sound := true
var _saved_music := true


func before_each() -> void:
	_saved_sound = Settings.sound
	_saved_music = Settings.music
	Settings.sound = true
	Settings.music = true
	MusicManager.stop()
	MusicManager.apply_settings()


func after_each() -> void:
	Fixture.teardown()
	MusicManager.stop()
	Settings.sound = _saved_sound
	Settings.music = _saved_music
	MusicManager.apply_settings()


func test_setup_starts_irinas_leader_theme_with_full_loop() -> void:
	autofree(Fixture.start_teams_match())
	assert_eq(MusicManager.current_sub_area, "Closed City")
	assert_eq(MusicManager.current_leader_id, "r-irina-karpova")
	assert_eq(MusicManager.current_theme_path, MusicManager.LEADER_THEMES["r-irina-karpova"])
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
	_replace_leader(state, "p2", "test-unscored-leader", "First Mind")
	GameState.start_match(state)
	assert_eq(MusicManager.current_sub_area, "First Mind")
	var player := MusicManager.get_node("MatchMusic") as AudioStreamPlayer
	assert_false(player.playing)
	assert_null(player.stream)


func _replace_leader(state: MatchState, player_id: String, id: String, area: String) -> void:
	for character in state.get_player(player_id).characters:
		if character.data.type == "Leader":
			var data := CharacterData.new()
			data.id = id
			data.type = "Leader"
			data.sub_area = area
			character.data = data
			return


func test_flood_survivors_start_with_the_queens_theme_and_keep_it_across_turns() -> void:
	autofree(Fixture.start_teams_match())
	var state := GameState.match_state
	state.first_player_id = "p2"
	GameState.start_match(state)
	var player := MusicManager.get_node("MatchMusic") as AudioStreamPlayer
	assert_eq(MusicManager.current_leader_id, "a-flood-survivor-meret-anu")
	assert_eq(MusicManager.current_sub_area, "Flood Survivors")
	assert_eq(MusicManager.current_theme_path, MusicManager.LEADER_THEMES["a-flood-survivor-meret-anu"])
	assert_true(player.playing)
	var stream := player.stream as AudioStreamWAV
	assert_not_null(stream)
	if stream == null:
		return
	assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	assert_eq(stream.loop_end, 2671304)
	assert_almost_eq(stream.get_length(), 83.47825, .001)
	TurnManager.start_turn("p2")
	TurnManager.end_turn("p2")
	assert_same(player.stream, stream)
	assert_eq(MusicManager.current_leader_id, "a-flood-survivor-meret-anu")


func test_flood_survivor_area_base_is_available_without_a_specific_leader_theme() -> void:
	autofree(Fixture.start_teams_match())
	var state := GameState.match_state
	state.first_player_id = "p2"
	_replace_leader(state, "p2", "test-survivor-leader", "Flood Survivors")
	GameState.start_match(state)
	assert_eq(MusicManager.current_theme_path, MusicManager.THEMES["Flood Survivors"])
	assert_true((MusicManager.get_node("MatchMusic") as AudioStreamPlayer).playing)


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
	assert_eq(MusicManager.current_leader_id, "r-irina-karpova")
	assert_true((MusicManager.get_node("MatchMusic") as AudioStreamPlayer).playing)


func test_another_closed_city_leader_falls_back_to_area_base() -> void:
	autofree(Fixture.start_teams_match())
	var state := GameState.match_state
	for character in state.get_player("p1").characters:
		if character.data.type == "Leader":
			# Use a fresh Resource so the ContentDB's shared Irina card stays unchanged.
			var data := CharacterData.new()
			data.id = "test-unscored-leader"
			data.type = "Leader"
			data.sub_area = "Closed City"
			character.data = data
			break
	GameState.start_match(state)
	assert_eq(MusicManager.current_leader_id, "test-unscored-leader")
	assert_eq(MusicManager.current_theme_path, MusicManager.THEMES["Closed City"])
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


func test_menu_loop_carries_across_team_selection() -> void:
	MusicManager.play_menu()
	var menu := MusicManager.get_node("MenuAmbience") as AudioStreamPlayer
	assert_true(menu.playing)
	var stream := menu.stream as AudioStreamWAV
	assert_not_null(stream)
	if stream == null:
		return
	assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	assert_eq(stream.loop_end, 2048000)
	assert_almost_eq(stream.get_length(), 64.0, .001)
	# Selecting a mode calls begin_setup/reset again; it must keep the ambient loop.
	GameState.reset()
	MusicManager.play_menu()
	assert_same(menu.stream, stream)
	MusicManager.close_menu()
	assert_true(menu.playing, "Closing setup's options must keep the ambience")


func test_match_start_fades_out_menu_ambience() -> void:
	MusicManager.play_menu()
	autofree(Fixture.start_teams_match())
	var menu := MusicManager.get_node("MenuAmbience") as AudioStreamPlayer
	assert_true((MusicManager.get_node("MatchMusic") as AudioStreamPlayer).playing)
	await wait_seconds(1.2)
	assert_false(menu.playing, "No menu layer remains under the match after its fade")


func test_in_match_menu_pauses_and_resumes_same_match_stream() -> void:
	autofree(Fixture.start_teams_match())
	var player := MusicManager.get_node("MatchMusic") as AudioStreamPlayer
	var stream := player.stream
	MusicManager.play_menu()
	assert_true(player.stream_paused)
	assert_true((MusicManager.get_node("MenuAmbience") as AudioStreamPlayer).playing)
	MusicManager.close_menu()
	assert_false(player.stream_paused)
	assert_same(player.stream, stream)
	# Reopening during the fade must cancel its delayed stop.
	MusicManager.play_menu()
	await wait_seconds(1.2)
	assert_true((MusicManager.get_node("MenuAmbience") as AudioStreamPlayer).playing)
	EventBus.match_ended.emit("p1", "test")
	assert_false((MusicManager.get_node("MenuAmbience") as AudioStreamPlayer).playing)


func test_music_toggle_mutes_both_music_players() -> void:
	MusicManager.play_menu()
	Settings.music = false
	MusicManager.apply_settings()
	var bus := AudioServer.get_bus_index(MusicManager.MUSIC_BUS)
	assert_true(AudioServer.is_bus_mute(bus))
	autofree(Fixture.start_teams_match())
	assert_true(AudioServer.is_bus_mute(bus), "Starting a match must respect Music: Off")
	assert_eq((MusicManager.get_node("MatchMusic") as AudioStreamPlayer).bus, MusicManager.MUSIC_BUS)
	assert_eq((MusicManager.get_node("MenuAmbience") as AudioStreamPlayer).bus, MusicManager.MUSIC_BUS)
	Settings.music = true
	MusicManager.apply_settings()
	assert_false(AudioServer.is_bus_mute(bus))


# Designer 2026-10-17: music has its own toggle; Sound: Off leaves it playing.
func test_sound_off_does_not_mute_music() -> void:
	Settings.sound = false
	MusicManager.apply_settings()
	autofree(Fixture.start_teams_match())
	assert_false(AudioServer.is_bus_mute(AudioServer.get_bus_index(MusicManager.MUSIC_BUS)))
	assert_true((MusicManager.get_node("MatchMusic") as AudioStreamPlayer).playing)
