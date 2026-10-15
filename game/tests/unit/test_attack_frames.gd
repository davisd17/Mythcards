extends GutTest
# Phase 6 (LLD-figure-animation.md 8): hand-drawn attack frames. Yuri Volkov is the pilot.
# His six frames play from wardrobe.json at their delivered holds, crossfade, mirror for
# leftward attacks, and hold the target's reaction until the shot. Everyone else keeps
# the procedural wind-up. The rules resolve at once either way.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const YURI := "p1_r-yuri-volkov"
const NAIA := "p2_a-flood-survivor-naia"

var view: GameBoardView


func before_each() -> void:
	autofree(Fixture.start_teams_match())
	Fixture.state().shared_deck.clear()
	view = GameBoardView.new()
	view.size = Vector2(700, 700)
	view.controller = GameController.new()
	add_child_autofree(view)


func after_each() -> void:
	Fixture.teardown()


func _attack(attacker: String, target: String) -> Dictionary:
	return RulesEngine.request_action("attack", attacker, {"target_id": target})


func test_yuri_has_six_frames_at_the_delivered_holds() -> void:
	var frames := FigureCatalog.attack_frames("r-yuri-volkov", "default")
	assert_eq(frames.size(), 6)
	assert_eq(frames.map(func(f): return roundi(f.seconds * 1000.0)), [100, 100, 130, 60, 90, 120])
	var timing := FigureCatalog.attack_timing("r-yuri-volkov", "default")
	assert_almost_eq(timing.length, 0.6, 0.001)
	assert_almost_eq(timing.impact, 0.33, 0.001, "the fire frame starts after ready, raise, and brace")
	var default_size := FigureCatalog.texture_for("r-yuri-volkov", "default").get_size()
	for f in frames:
		assert_eq(f.texture.get_size(), default_size, "same canvas as default.png, so one shared transform")


func test_characters_without_art_keep_the_procedural_wind_up() -> void:
	assert_eq(FigureCatalog.attack_timing("a-flood-survivor-naia", "default"), {})
	assert_eq(FigureCatalog.attack_frames("r-zoya-miranova", "aurora-rite"), [])


func test_frame_layers_crossfade_and_return_to_idle() -> void:
	var holds := [0.1, 0.1, 0.13, 0.06, 0.09, 0.12]
	assert_eq(FigurePose.frame_layers(holds, 0.0), [{"frame": -1, "alpha": 1.0}, {"frame": 0, "alpha": 0.0}])
	assert_eq(FigurePose.frame_layers(holds, 0.05), [{"frame": 0, "alpha": 1.0}], "a held pose")
	var mid_blend := FigurePose.frame_layers(holds, 0.08)
	assert_eq(mid_blend[1].frame, 1, "fading into raise at the end of ready")
	assert_between(mid_blend[1].alpha, 0.0, 1.0)
	var fire := FigurePose.frame_layers(holds, 0.34)
	assert_eq(fire[0].frame, 3, "the shot at 330-390 ms")
	var last := FigurePose.frame_layers(holds, 0.59)
	assert_eq([last[0].frame, last[1].frame], [5, -1], "the recover pose fades back to the idle figure")
	assert_eq(FigurePose.frame_layers(holds, 0.6), [{"frame": -1, "alpha": 1.0}])


func test_yuris_attack_plays_his_frames_and_the_hit_waits_for_the_shot() -> void:
	var yuri := Fixture.put(YURI, Vector2i(2, 2))
	var naia := Fixture.put(NAIA, Vector2i(4, 2))
	var hp_before := naia.current_hp
	var result := _attack(YURI, NAIA)
	assert_true(result.success, str(result))
	assert_lt(naia.current_hp, hp_before, "the rules resolved at once")
	var lunge: Dictionary = view.fx.lunges[yuri.instance_id]
	assert_true(lunge.framed)
	assert_almost_eq(lunge.duration, 0.6, 0.001)
	assert_false(FigurePose.attack_mirrored(yuri, view.fx), "Naia is to the right: frames as drawn")
	assert_eq(view.fx.hit_strength(naia.instance_id), 0.0, "no flash before the shot")
	assert_false(view.fx.effects.any(func(e): return view.fx.started(e.start)), "no damage number yet")
	assert_eq(view._figure_layers(yuri, FigureCatalog.texture_for("r-yuri-volkov", "default")).size(), 2,
			"the idle figure fading into the ready pose")
	view.fx.advance(0.34)
	assert_gt(view.fx.hit_strength(naia.instance_id), 0.5, "the flash lands with the shot")
	assert_true(view.fx.effects.any(func(e): return e.kind == "number" and view.fx.started(e.start)))
	assert_eq(FigurePose.pose(yuri, view.fx, false, false, false).lean, 0.0, "the drawn brace replaces the lean")
	view.fx.advance(0.3)
	assert_false(view.fx.lunges.has(yuri.instance_id), "back to idle after 600 ms")


func test_an_attack_to_the_left_plays_the_frames_mirrored() -> void:
	var yuri := Fixture.put(YURI, Vector2i(4, 2))
	Fixture.put(NAIA, Vector2i(2, 2))
	assert_true(_attack(YURI, NAIA).success)
	assert_true(FigurePose.attack_mirrored(yuri, view.fx))


func test_a_procedural_attacker_hits_at_once_as_before() -> void:
	Fixture.state().active_player_id = "p2"
	Fixture.state().get_player("p2").pool_ap_remaining = 4
	var naia := Fixture.put(NAIA, Vector2i(3, 3))
	var yuri := Fixture.put(YURI, Vector2i(3, 2))
	assert_true(_attack(NAIA, YURI).success)
	assert_false(view.fx.lunges[naia.instance_id].framed)
	assert_almost_eq(view.fx.lunges[naia.instance_id].duration, BoardFx.LUNGE, 0.001)
	assert_gt(view.fx.hit_strength(yuri.instance_id), 0.9, "no art, no wait")


func test_the_hit_sound_waits_for_the_shot() -> void:
	var sfx: Sfx = add_child_autofree(Sfx.new())
	var saved := [Settings.sound, Settings.haptics]
	Settings.sound = true
	Settings.haptics = false
	sfx.impact_for = func(id: String) -> float: return float(view.attack_art_for(id).get("impact", 0.0))
	Fixture.put(YURI, Vector2i(2, 2))
	Fixture.put(NAIA, Vector2i(4, 2))
	assert_true(_attack(YURI, NAIA).success)
	assert_false(sfx.played.has("hit"), "silent until the muzzle flash")
	await wait_seconds(0.45)
	assert_true(sfx.played.has("hit"))
	Settings.sound = saved[0]
	Settings.haptics = saved[1]


func test_the_board_draws_mid_attack() -> void:
	Fixture.put(YURI, Vector2i(2, 2))
	Fixture.put(NAIA, Vector2i(4, 2))
	assert_true(_attack(YURI, NAIA).success)
	for i in 8:
		view.fx.advance(0.08)
		view.queue_redraw()
		await wait_process_frames(1)
	assert_true(true, "drew every stage of the sequence without errors")
