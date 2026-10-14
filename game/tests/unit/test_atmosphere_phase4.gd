extends GutTest
# Visual Polish Phase 4 and side palettes (LLD-atmosphere-phase4.md): each side's colors
# and atmosphere come from its Leader's area and sub-area, a same-sub-area match inverts
# Player 2, the ambience draws, and sound is synthesized and follows the settings.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const SetupFlowScript := preload("res://scripts/scenes/setup_flow.gd")

var _saved := []


func before_each() -> void:
	_saved = [Settings.sound, Settings.motion, Settings.haptics]
	Settings.haptics = false   # never buzz a test machine


func after_each() -> void:
	Settings.sound = _saved[0]
	Settings.motion = _saved[1]
	Settings.haptics = _saved[2]
	Fixture.teardown()


func _setup(p1_team: String, p2_team: String) -> Node:
	var setup: Node = autofree(SetupFlowScript.new())
	setup.select_team("p1", p1_team)
	setup.select_team("p2", p2_team)
	return setup


# --- Palettes ---------------------------------------------------------------------------

func test_the_playtest_matchup_takes_each_leaders_sub_area() -> void:
	var setup := _setup("closed-city", "flood-survivors")
	var p := SidePalette.for_players(setup.get_player("p1"), setup.get_player("p2"))
	assert_eq([p.p1.area, p.p2.area], ["Closed City", "Flood Survivors"])
	assert_eq([p.p1.atmosphere, p.p2.atmosphere], ["ash", "caustics"])
	assert_false(p.p1.inverted or p.p2.inverted)


func test_the_original_leaders_bring_their_own_sub_areas() -> void:
	autofree(Fixture.start_match())
	var p := SidePalette.for_players(Fixture.state().get_player("p1"), Fixture.state().get_player("p2"))
	assert_eq([p.p1.area, p.p2.area], ["Winter Front", "First Mind"], "Army General and Divine Conductor")
	assert_eq([p.p1.inlay, p.p2.inlay], ["city", "flood"], "inlay style follows the culture, not the seat")


func test_a_mirror_match_gives_player_2_the_inverse_set() -> void:
	var setup := _setup("closed-city", "closed-city")
	var p := SidePalette.for_players(setup.get_player("p1"), setup.get_player("p2"))
	assert_eq(p.p2.area, "Closed City")
	assert_true(p.p2.inverted)
	assert_false(p.p1.inverted)
	assert_almost_eq(fposmod(p.p2.primary.h - p.p1.primary.h, 1.0), 0.5, 0.01, "complementary hue")
	assert_almost_eq(p.p2.primary.v, p.p1.primary.v, 0.01, "same brightness")
	assert_eq(p.p2.atmosphere, p.p1.atmosphere, "same atmosphere, only the colors flip")


func test_inverting_twice_returns_the_original_colors() -> void:
	var p := SidePalette.of_area("Far North")
	var back := p.inverse().inverse()
	assert_false(back.inverted)
	assert_almost_eq(back.primary.h, p.primary.h, 0.01)


func test_an_unknown_sub_area_falls_back_to_its_culture() -> void:
	assert_eq(SidePalette.of_area("Somewhere New", "Atlantean").area, "Flood Survivors")
	assert_eq(SidePalette.of_area("", "Russian-inspired").area, "Closed City")


func test_every_sub_area_reads_differently_from_the_rest() -> void:
	var colors := SidePalette.SUB_AREAS.values().map(func(e): return Color(e.primary))
	for i in colors.size():
		for j in range(i + 1, colors.size()):
			var dh := absf(colors[i].h - colors[j].h)
			assert_gt(minf(dh, 1.0 - dh), 0.04, "hues %d and %d are too close" % [i, j])


func test_the_board_draws_with_the_mirror_palette() -> void:
	var view := GameBoardView.new()
	view.size = Vector2(700, 700)
	view.controller = GameController.new()
	add_child_autofree(view)
	view.controller.begin_setup("closed-city", "closed-city", "")
	view.refresh_palettes()
	assert_ne(view.faction_color("p1"), view.faction_color("p2"))
	assert_true(view.side_palette("p2").inverted)
	await wait_process_frames(2)
	view.controller.setup.free()
	view.controller.setup = null


# --- Atmosphere ------------------------------------------------------------------------

func test_atmosphere_fades_from_the_outer_edge_to_nothing() -> void:
	var region := Rect2(0, 0, 100, 300)
	assert_almost_eq(BoardAtmosphere.fade(region, true, 300.0), 1.0, 0.001, "Player 1's outer edge is the bottom")
	assert_almost_eq(BoardAtmosphere.fade(region, true, 0.0), 0.0, 0.001)
	assert_almost_eq(BoardAtmosphere.fade(region, false, 0.0), 1.0, 0.001, "Player 2's outer edge is the top")


func test_every_atmosphere_draws() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(400, 400)
	add_child_autofree(canvas)
	var drawn := []
	canvas.draw.connect(func():
		for area in SidePalette.SUB_AREAS:
			var palette := SidePalette.of_area(area)
			BoardAtmosphere.draw_side(canvas, palette, Rect2(0, 0, 400, 170), true, 57.0, 3.3)
			BoardAtmosphere.draw_side(canvas, palette.inverse(), Rect2(0, 230, 400, 170), false, 57.0, 3.3)
			drawn.append(palette.atmosphere)
		BoardAtmosphere.draw_frost_drift(canvas, Rect2(0, 0, 57, 57), 1.0, 3)
		BoardAtmosphere.draw_convergence(canvas, Vector2(200, 200), 57.0, 1.0, Color.ORANGE))
	canvas.queue_redraw()
	await wait_process_frames(2)
	assert_eq(drawn.size(), SidePalette.SUB_AREAS.size())


# --- Sound ------------------------------------------------------------------------------

func test_every_sound_is_synthesized_and_short() -> void:
	var streams := Sfx.build_streams()
	for name in Sfx.VOLUME_DB:
		assert_true(streams.has(name), name)
		var wav: AudioStreamWAV = streams[name]
		assert_gt(wav.data.size(), 0, name)
		assert_lte(wav.get_length(), 1.5, "%s stays short" % name)


func test_signals_play_sounds_only_while_sound_is_on() -> void:
	var sfx: Sfx = add_child_autofree(Sfx.new())
	Settings.sound = true
	EventBus.damage_resolved.emit("a", "b", 2, [])
	EventBus.damage_resolved.emit("a", "b", 0, [])
	EventBus.status_added.emit("b", "marked", 1, "")
	EventBus.character_defeated.emit("b", "a", "mount_propagation")
	assert_eq(sfx.played, ["hit", "blocked"] as Array[String], "no sound for a mark or a Mount under its rider")
	Settings.sound = false
	sfx.play("turn")
	assert_eq(sfx.played.size(), 2, "muted")


func test_the_convergence_drone_loops_and_follows_the_setting() -> void:
	var sfx: Sfx = add_child_autofree(Sfx.new())
	assert_eq(sfx._drone.stream.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	Settings.sound = false
	sfx.apply_settings()
	assert_false(sfx._drone.playing)
	Settings.sound = true
	sfx.apply_settings()
	assert_true(sfx._drone.playing)


func test_settings_toggle_by_name() -> void:
	var before := Settings.motion
	Settings.toggle("motion")
	assert_eq(Settings.value("motion"), not before)
	Settings.toggle("motion")
	assert_eq(Settings.value("motion"), before)
