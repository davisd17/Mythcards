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
	var view := GameBoardView.new()
	add_child_autofree(view)
	view.size = Vector2(700, 700)
	view.controller = GameController.new()
	var original_tiles := []
	for y in 7:
		for x in 7:
			original_tiles.append(view.tile_rect(Vector2i(x, y)))
	Fixture.state().first_player_id = "p2"
	assert_eq(BattlefieldTheme.area_for(Fixture.state()), "Flood Survivors")
	assert_false(BattlefieldTheme.is_closed_city())
	assert_true(BattlefieldTheme.has_theme())
	assert_eq(BattlefieldTheme.current_art().backdrop, BattlefieldTheme.SANCTUARY)
	assert_eq(BattlefieldTheme.current_art().surface, BattlefieldTheme.TIDE_STONE)
	for y in 7:
		for x in 7:
			var tile := view.tile_rect(Vector2i(x, y))
			assert_eq(tile, original_tiles[y * 7 + x], "theme does not reflow the board")
			assert_eq(view.tile_at(tile.get_center()), Vector2i(x, y))
	TurnManager.end_turn("p1")
	TurnManager.end_turn("p2")
	assert_eq(BattlefieldTheme.current_art().surface, BattlefieldTheme.TIDE_STONE)


func test_theme_follows_leader_not_player_number_or_team_metadata() -> void:
	var state := Fixture.state()
	var squad := state.players[0].characters
	state.players[0].characters = state.players[1].characters
	state.players[1].characters = squad
	state.first_player_id = "p2"
	assert_true(BattlefieldTheme.is_closed_city())
	state.first_player_id = "p1"
	assert_eq(BattlefieldTheme.current_art().surface, BattlefieldTheme.TIDE_STONE)


func test_missing_or_unknown_starter_is_neutral() -> void:
	assert_eq(BattlefieldTheme.area_for(null), "")
	Fixture.state().first_player_id = "missing"
	assert_false(BattlefieldTheme.is_closed_city())
	Fixture.state().first_player_id = "p1"
	Fixture.state().players[0].characters = []
	assert_eq(BattlefieldTheme.area_for(Fixture.state()), "")
	assert_false(BattlefieldTheme.has_theme())


func test_assets_load_and_cover_crop_stays_within_texture() -> void:
	for path in [BattlefieldTheme.CHAMBER, BattlefieldTheme.SURFACE, BattlefieldTheme.SANCTUARY, BattlefieldTheme.TIDE_STONE,
			BattlefieldTheme.BOUNDARY_VILLAGE, BattlefieldTheme.FROSTBOUND_STONE]:
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


func _far_north_leader(player_id: String) -> void:
	for c in Fixture.state().get_player(player_id).characters:
		if c.data.type == "Leader":
			c.data = ContentDB._build_character(c.data.raw.duplicate(true), "far-north theme fixture")
			c.data.sub_area = BattlefieldTheme.FAR_NORTH
			c.data.char_name = "Vera Kargina (theme fixture)"


func test_far_north_starter_uses_village_and_frostbound_surface_for_whole_match() -> void:
	_far_north_leader("p1")
	assert_true(BattlefieldTheme.has_theme())
	assert_false(BattlefieldTheme.is_closed_city())
	assert_eq(BattlefieldTheme.current_art().backdrop, BattlefieldTheme.BOUNDARY_VILLAGE)
	assert_eq(BattlefieldTheme.current_art().surface, BattlefieldTheme.FROSTBOUND_STONE)
	TurnManager.end_turn("p1")
	assert_eq(BattlefieldTheme.current_art().surface, BattlefieldTheme.FROSTBOUND_STONE)
	TurnManager.end_turn("p2")
	assert_eq(BattlefieldTheme.area_for(Fixture.state()), BattlefieldTheme.FAR_NORTH)
	assert_eq(ContentDB.get_character("r-irina-karpova").sub_area, "Closed City", "shared card data unchanged")


func test_far_north_does_not_override_the_other_starting_leader() -> void:
	_far_north_leader("p2")
	assert_true(BattlefieldTheme.is_closed_city())
	Fixture.state().first_player_id = "p2"
	assert_eq(BattlefieldTheme.current_art().backdrop, BattlefieldTheme.BOUNDARY_VILLAGE)


func test_far_north_does_not_change_grid_or_input_targets() -> void:
	var view := GameBoardView.new()
	add_child_autofree(view)
	view.size = Vector2(700, 700)
	view.controller = GameController.new()
	var before := []
	for y in 7:
		for x in 7:
			before.append(view.tile_rect(Vector2i(x, y)))
	_far_north_leader("p1")
	for y in 7:
		for x in 7:
			var rect := view.tile_rect(Vector2i(x, y))
			assert_eq(rect, before[y * 7 + x])
			assert_eq(view.tile_at(rect.get_center()), Vector2i(x, y))
