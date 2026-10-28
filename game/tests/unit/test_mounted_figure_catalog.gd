extends GutTest

const Fixture := preload("res://tests/helpers/match_fixture.gd")
var mounts: MountSystem


func before_each() -> void:
	autofree(Fixture.start_teams_match())
	Fixture.clear_board()
	mounts = MountSystem.new(Fixture.board())


func after_each() -> void:
	Fixture.teardown()


func _pair(key: String) -> CharacterInstance:
	var e: Dictionary = MountedFigureCatalog.entries()[key]
	var player := "p1_" if str(e.rider).begins_with("r-") else "p2_"
	var rider := Fixture.put(player + e.rider, Vector2i(2, 2))
	var mount_char := Fixture.put(player + e.mount, Vector2i(3, 2))
	mounts.mount(rider, mount_char)
	return rider


func test_four_playable_pairings_have_registered_transparent_six_pose_art() -> void:
	assert_eq(MountedFigureCatalog.entries().size(), 4)
	for key in MountedFigureCatalog.entries():
		var texture := MountedFigureCatalog.texture_for(key)
		assert_not_null(texture, key)
		assert_eq(texture.get_size(), Vector2(512, 768), key)
		var frames := MountedFigureCatalog.attack_frames(key)
		assert_eq(frames.size(), 6, key)
		var idle_height := texture.get_image().get_used_rect().size.y
		var impact_indices := []
		for i in frames.size():
			if frames[i].impact:
				impact_indices.append(i)
			var image: Image = frames[i].texture.get_image()
			assert_eq(image.get_size(), Vector2i(512, 768), key)
			assert_eq(image.get_pixel(0, 0).a, 0.0, key + " transparent corner")
			var used := image.get_used_rect()
			assert_between(float(used.size.y) / idle_height, 0.98, 1.02, key + " no attack shrink")
			assert_between(used.end.y - 1, 752, 760, key + " fixed mount contact")
			assert_gte(used.position.x, 24, key)
			assert_lte(used.end.x, 488, key)
			assert_gte(used.position.y, 18, key)
		assert_eq(impact_indices, [3], key)
		var timing := MountedFigureCatalog.attack_timing(key)
		assert_almost_eq(timing.length, 0.6, 0.0001, key)
		assert_almost_eq(timing.impact, 0.33, 0.0001, key)


func test_mount_selects_correct_pair_and_dismount_restores_normal_figures() -> void:
	for key in MountedFigureCatalog.entries():
		var rider := _pair(key)
		assert_eq(MountedFigureCatalog.key_for(rider), key)
		var mount_char := Fixture.character(rider.mounted_with_id)
		assert_eq(MountedFigureCatalog.key_for(mount_char), "", "mount is not a second rider")
		assert_eq(GameBoardView.draw_order([rider, mount_char]), [rider])
		assert_eq(MountedFigureCatalog.key_for(rider, "future-outfit"), "", "never substitute different clothing")
		mounts.dismount(rider, Vector2i(4, 2))
		assert_eq(MountedFigureCatalog.key_for(rider), "")
		assert_eq(GameBoardView.draw_order([rider, mount_char]).size(), 2)
		assert_not_null(FigureCatalog.texture_for(rider.data.id, "default"))
		assert_not_null(FigureCatalog.texture_for(mount_char.data.id, "default"))


func test_unknown_pair_and_unmounted_character_have_no_mounted_art() -> void:
	var rider := Fixture.character("p1_r-mikhail-orlov")
	assert_eq(MountedFigureCatalog.key_for(rider), "")
	assert_null(MountedFigureCatalog.texture_for("not-a-pair"))
	assert_eq(MountedFigureCatalog.attack_frames("not-a-pair"), [])
	assert_eq(MountedFigureCatalog.attack_timing("not-a-pair"), {})


func test_ahesu_uses_approved_giant_revision_for_both_riders() -> void:
	for key in ["sahu-ahesu", "meret-ahesu"]:
		assert_eq(MountedFigureCatalog.entries()[key].revision, "giant-ahesu-v2")
		for frame in MountedFigureCatalog.attack_frames(key):
			var used: Rect2i = frame.texture.get_image().get_used_rect()
			# The old rider-dominated upright composition was much taller than wide.
			assert_between(float(used.size.y) / used.size.x, 0.94, 1.04,
				key + " keeps the approved broad, giant-serpent composition")


func test_attack_never_uses_on_foot_frames_and_dismount_cancels_stale_mounted_layers() -> void:
	var rider := _pair("orlov-vera")
	var view := GameBoardView.new()
	autofree(view)
	var figure := MountedFigureCatalog.texture_for("orlov-vera")
	view.fx.lunges[rider.instance_id] = {"start": 0.0, "framed": true,
		"duration": 0.6, "toward": Vector2i(4, 2), "mounted_key": "orlov-vera"}
	var frames := MountedFigureCatalog.attack_frames("orlov-vera")
	for time in [0.06, 0.14, 0.24, 0.35, 0.42, 0.53]:
		view.fx.now = time
		for layer in view._figure_layers(rider, figure):
			assert_true(layer.texture == figure or frames.any(func(f): return f.texture == layer.texture))
	mounts.dismount(rider, Vector2i(4, 2))
	var idle := FigureCatalog.texture_for(rider.data.id, "default")
	assert_eq(view._figure_layers(rider, idle), [{"texture": idle, "alpha": 1.0}])


func test_mounted_attack_timing_and_mirroring_follow_existing_animation_contract() -> void:
	var rider := _pair("meret-ahesu")
	var enemy := Fixture.put("p1_r-reactor-worker", Vector2i(2, 2))
	var fx := BoardFx.new()
	fx.attack_art = func(_id): return MountedFigureCatalog.attack_timing("meret-ahesu")
	fx._on_attack(rider.instance_id, enemy.instance_id, 1, false)
	assert_almost_eq(fx.lunges[rider.instance_id].duration, 0.6, 0.0001)
	assert_true(FigurePose.attack_mirrored(rider, fx))
	assert_eq(fx.lunges[rider.instance_id].mounted_key, "meret-ahesu")
	fx.advance(0.61)
	assert_false(fx.lunges.has(rider.instance_id))


func test_defeat_preserves_pair_art_after_model_clears_mount_link() -> void:
	var rider := _pair("sahu-ahesu")
	var fx := BoardFx.new()
	fx._on_requested("attack", "p1_r-mikhail-orlov", {})
	mounts.handle_rider_defeated(rider)
	assert_false(rider.is_mounted_rider)
	fx._on_defeated(rider.instance_id, "p1_r-mikhail-orlov", "direct")
	fx._on_defeated("p2_a-flood-survivor-ahesu", "p1_r-mikhail-orlov", "mount_propagation")
	assert_eq(fx.ghosts.size(), 1, "one pair, not two ghosts")
	assert_eq(fx.ghosts[0].mounted_key, "sahu-ahesu")


func test_mounted_pair_fits_tile_width_without_moving_hit_target_or_labels() -> void:
	var view := GameBoardView.new()
	autofree(view)
	var tile := Rect2(100, 100, 120, 120)
	for key in MountedFigureCatalog.entries():
		var rider := _pair(key)
		var texture := MountedFigureCatalog.texture_for(key)
		var label := view.label_rect(tile)
		var r := view.figure_rect(rider, tile, texture, false)
		var used := texture.get_image().get_used_rect()
		var scale := r.size.x / texture.get_width()
		assert_lte(used.size.x * scale, tile.size.x * 0.981, key)
		assert_almost_eq(r.position.y + used.end.y * scale, view.feet_point(tile, false).y, 0.001, key)
		assert_eq(view.label_rect(tile), label)


func test_mounted_attack_on_placed_object_plays_the_pair_not_the_standing_rider() -> void:
	var rider := _pair("irina-vera")
	var fx := BoardFx.new()
	fx.attack_art = func(_id): return MountedFigureCatalog.attack_timing("irina-vera")
	fx._on_requested("attack", rider.instance_id, {"target_pos": Vector2i(4, 2)})
	fx._on_object_attacked(rider.instance_id, Vector2i(4, 2), "stone", 1, false)
	assert_eq(fx.lunges[rider.instance_id].mounted_key, "irina-vera")
	assert_almost_eq(fx.lunges[rider.instance_id].duration, 0.6, 0.0001)
	assert_almost_eq(fx.effects[0].start, 0.33, 0.0001)


func test_mounted_claim_keeps_composite_and_uses_riders_lines() -> void:
	var view := GameBoardView.new()
	autofree(view)
	for key in MountedFigureCatalog.entries():
		var rider := _pair(key)
		var figure := MountedFigureCatalog.texture_for(key)
		view.fx.claims[rider.instance_id] = {"start": 0.0, "gained": 1}
		view.fx.now = 0.2
		assert_false(view._claim_framed(rider), key)
		assert_eq(view._figure_layers(rider, figure), [{"texture": figure, "alpha": 1.0}], key)
		assert_ne(EmberLines.line_for(rider.data.id, false), "", key + " normal rider line")
		assert_ne(EmberLines.line_for(rider.data.id, true), "", key + " big rider line")
