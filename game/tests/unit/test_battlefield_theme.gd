extends GutTest

const Fixture := preload("res://tests/helpers/match_fixture.gd")


func before_each() -> void:
	autofree(Fixture.start_teams_match())
	Fixture.state().shared_deck.clear()


func after_each() -> void:
	Fixture.teardown()


func test_theme_matches_starting_leader_music_and_survives_turn_changes() -> void:
	assert_eq(BattlefieldTheme.area_for(Fixture.state()), MusicManager.current_sub_area)
	assert_true(BattlefieldTheme.is_closed_city())
	TurnManager.end_turn("p1")
	assert_true(BattlefieldTheme.is_closed_city())
	assert_eq(Fixture.state().first_player_id, "p1")


func test_starting_flood_survivors_do_not_borrow_closed_city() -> void:
	Fixture.state().first_player_id = "p2"
	assert_eq(BattlefieldTheme.area_for(Fixture.state()), "Flood Survivors")
	assert_false(BattlefieldTheme.is_closed_city())


func test_theme_follows_leader_not_player_number_or_team_metadata() -> void:
	var state := Fixture.state()
	var squad := state.players[0].characters
	state.players[0].characters = state.players[1].characters
	state.players[1].characters = squad
	state.first_player_id = "p2"
	assert_true(BattlefieldTheme.is_closed_city())


func test_missing_or_unknown_starter_is_neutral() -> void:
	assert_eq(BattlefieldTheme.area_for(null), "")
	Fixture.state().first_player_id = "missing"
	assert_false(BattlefieldTheme.is_closed_city())
	Fixture.state().first_player_id = "p1"
	Fixture.state().players[0].characters = []
	assert_eq(BattlefieldTheme.area_for(Fixture.state()), "")


func test_assets_load_and_cover_crop_stays_within_texture() -> void:
	for path in [BattlefieldTheme.CHAMBER, BattlefieldTheme.SURFACE]:
		var texture := BattlefieldTheme.texture(path)
		assert_not_null(texture)
		if texture == null:
			continue
		assert_gte(texture.get_width(), 1024)
		for target in [Vector2(390, 844), Vector2(1440, 960)]:
			var crop := BattlefieldTheme.cover(texture.get_size(), target)
			assert_gte(crop.position.x, 0.0)
			assert_gte(crop.position.y, 0.0)
			assert_lte(crop.end.x, float(texture.get_width()) + 0.001)
			assert_lte(crop.end.y, float(texture.get_height()) + 0.001)
			assert_almost_eq(crop.size.x / crop.size.y, target.x / target.y, 0.001)


func test_backdrop_cannot_intercept_game_input() -> void:
	var backdrop := BattlefieldBackdrop.new()
	add_child_autofree(backdrop)
	assert_eq(backdrop.mouse_filter, Control.MOUSE_FILTER_IGNORE)
