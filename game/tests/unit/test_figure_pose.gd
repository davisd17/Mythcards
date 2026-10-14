extends GutTest
# Figure animation (LLD-figure-animation.md 5): poses are bounded, out of phase, settle
# back to rest, follow the Motion setting, and never move the labels.

const Fixture := preload("res://tests/helpers/match_fixture.gd")

var fx: BoardFx
var _motion := true


func before_each() -> void:
	autofree(Fixture.start_teams_match())
	Fixture.state().shared_deck.clear()
	fx = BoardFx.new()
	fx.connect_signals()
	_motion = Settings.motion


func after_each() -> void:
	Settings.motion = _motion
	Fixture.teardown()


func _pose(c: CharacterInstance, spent := false, selected := false, motion := true) -> Dictionary:
	return FigurePose.pose(c, fx, spent, selected, motion)


func _is_rest(p: Dictionary) -> bool:
	return is_equal_approx(p.lift, 0.0) and is_equal_approx(p.scale_y, 1.0) and is_equal_approx(p.lean, 0.0)


func test_idle_breathing_is_bounded() -> void:
	var c := Fixture.character("p1_r-yuri-volkov")
	for i in 80:
		fx.advance(0.11)
		var p := _pose(c)
		assert_between(p.scale_y, 1.0, 1.0 + FigurePose.IDLE_STRETCH + 0.0001)
		assert_between(p.lean, -FigurePose.IDLE_SWAY - 0.0001, FigurePose.IDLE_SWAY + 0.0001)
		assert_eq(p.lift, 0.0)


func test_two_figures_breathe_out_of_phase() -> void:
	fx.advance(1.0)
	var a := _pose(Fixture.character("p1_r-yuri-volkov"))
	var b := _pose(Fixture.character("p1_r-zoya-miranova"))
	assert_ne(a.scale_y, b.scale_y, "the board doesn't pulse in unison")


func test_a_spent_figure_rests_still_and_a_little_lower() -> void:
	var c := Fixture.character("p1_r-yuri-volkov")
	fx.advance(0.7)
	var p := _pose(c, true)
	assert_eq([p.scale_y, p.lean], [1.0, 0.0])
	assert_almost_eq(p.lift, -FigurePose.SPENT_SINK, 0.0001)


func test_motion_off_stops_idle_but_not_action_animations() -> void:
	var c := Fixture.character("p1_r-yuri-volkov")
	fx.advance(0.7)
	assert_true(_is_rest(_pose(c, false, true, false)), "no breathing, no selected bob")
	EventBus.character_moved.emit(c.instance_id, c.position + Vector2i(0, 1), c.position)
	fx.advance(BoardFx.SLIDE * 0.5)
	assert_gt(_pose(c, false, false, false).lift, 0.05, "the move hop still plays")


func test_the_hop_peaks_mid_slide_and_lands_with_a_squash() -> void:
	var c := Fixture.character("p1_r-yuri-volkov")
	EventBus.character_moved.emit(c.instance_id, c.position + Vector2i(0, 2), c.position)
	assert_almost_eq(_pose(c, true).lift, -FigurePose.SPENT_SINK, 0.001, "starts on the ground")
	fx.advance(BoardFx.SLIDE * 0.5)
	assert_almost_eq(_pose(c, true).lift, FigurePose.HOP_HEIGHT - FigurePose.SPENT_SINK, 0.001, "peak")
	fx.advance(BoardFx.SLIDE * 0.33)
	assert_lt(_pose(c, true).scale_y, 1.0, "squash on landing")
	fx.advance(BoardFx.SLIDE)
	assert_true(_is_rest(_pose(c, false, false, false)))


func test_the_wind_up_leans_away_before_striking() -> void:
	var attacker := Fixture.put("p1_r-yuri-volkov", Vector2i(2, 3))
	var target := Fixture.put("p2_a-flood-survivor-naia", Vector2i(4, 3))   # to the right
	EventBus.attack_resolved.emit(attacker.instance_id, target.instance_id, 1, false)
	fx.advance(BoardFx.LUNGE * 0.28)
	assert_lt(_pose(attacker, false, false, false).lean, -2.0, "leaning back, away from the target")
	assert_lt(fx.offset_tiles(attacker).x, 0.0, "a small step back")
	fx.advance(BoardFx.LUNGE * 0.24)
	assert_gt(_pose(attacker, false, false, false).lean, 0.0, "into the strike")
	assert_gt(fx.offset_tiles(attacker).x, 0.1)


func test_a_wind_up_straight_up_the_board_crouches() -> void:
	var attacker := Fixture.put("p1_r-yuri-volkov", Vector2i(3, 1))
	var target := Fixture.put("p2_a-flood-survivor-naia", Vector2i(3, 3))
	EventBus.attack_resolved.emit(attacker.instance_id, target.instance_id, 1, false)
	fx.advance(BoardFx.LUNGE * 0.28)
	var p := _pose(attacker, false, false, false)
	assert_eq(p.lean, 0.0)
	assert_lt(p.scale_y, 1.0)


func test_a_hit_recoils_away_from_the_attacker_and_a_block_only_flinches() -> void:
	var attacker := Fixture.put("p1_r-yuri-volkov", Vector2i(2, 3))
	var target := Fixture.put("p2_a-flood-survivor-naia", Vector2i(4, 3))
	EventBus.damage_resolved.emit(attacker.instance_id, target.instance_id, 2, [])
	fx.advance(BoardFx.RECOIL * 0.25)
	var hit: float = _pose(target, false, false, false).lean
	assert_almost_eq(hit, FigurePose.RECOIL_LEAN, 0.01, "leans right, away from an attacker on the left")
	EventBus.damage_resolved.emit(attacker.instance_id, target.instance_id, 0, [])
	fx.advance(BoardFx.RECOIL * 0.25)
	assert_almost_eq(_pose(target, false, false, false).lean, FigurePose.FLINCH_LEAN, 0.01)


func test_cast_and_level_up_stretch_then_settle() -> void:
	var c := Fixture.character("p1_r-mikhail-orlov")
	EventBus.action_resolved.emit("ability", c.instance_id, {"success": true})
	EventBus.character_leveled_up.emit(c.instance_id, 2)
	fx.advance(BoardFx.CAST_TIME * 0.5)
	var p := _pose(c, false, false, false)
	assert_gt(p.lift, 0.04)
	assert_gt(p.scale_y, 1.05)


func test_a_defeat_topples_away_from_the_attacker() -> void:
	var attacker := Fixture.put("p1_r-yuri-volkov", Vector2i(4, 3))
	var c := Fixture.put("p2_a-flood-survivor-naia", Vector2i(3, 3))   # attacker on the right
	EventBus.character_defeated.emit(c.instance_id, attacker.instance_id, "direct")
	fx.advance(BoardFx.DEFEAT * 0.9)
	assert_lt(FigurePose.topple(fx.ghosts[0], fx), -20.0, "tips left, away from the attacker")


func test_every_animation_returns_exactly_to_rest_within_a_second() -> void:
	var attacker := Fixture.put("p1_r-yuri-volkov", Vector2i(2, 3))
	var c := Fixture.put("p2_a-flood-survivor-naia", Vector2i(4, 3))
	EventBus.character_moved.emit(c.instance_id, Vector2i(4, 4), c.position)
	EventBus.attack_resolved.emit(c.instance_id, attacker.instance_id, 1, false)
	EventBus.damage_resolved.emit(attacker.instance_id, c.instance_id, 1, [])
	EventBus.action_resolved.emit("ability", c.instance_id, {"success": true})
	EventBus.character_leveled_up.emit(c.instance_id, 2)
	fx.advance(1.0)
	assert_true(_is_rest(_pose(c, false, false, false)), str(_pose(c, false, false, false)))
	assert_eq(fx.offset_tiles(c), Vector2.ZERO)
	assert_false(fx.active())


func test_poses_never_move_the_labels() -> void:
	var view := GameBoardView.new()
	view.size = Vector2(700, 700)
	view.controller = GameController.new()
	add_child_autofree(view)
	var tile := view.tile_rect(Vector2i(3, 3))
	var before := view.label_rect(tile)
	EventBus.character_leveled_up.emit("p1_r-mikhail-orlov", 2)
	view.fx.advance(0.1)
	assert_eq(view.label_rect(tile), before, "the HP pill depends only on the tile")
	assert_almost_eq(view.feet_point(tile, false).y, tile.position.y + GameBoardView.FEET_LINE * tile.size.x, 0.01)


func test_the_side_whose_turn_starts_does_a_rippling_ready_bob() -> void:
	var left := Fixture.put("p1_r-yuri-volkov", Vector2i(0, 2))
	var right := Fixture.put("p1_r-zoya-miranova", Vector2i(6, 2))
	var enemy := Fixture.character("p2_a-flood-survivor-naia")
	EventBus.turn_started.emit("p1")
	fx.advance(BoardFx.READY * 0.5)
	assert_gt(_pose(left, false, false, false).lift, 0.04, "the left column bobs first")
	assert_eq(_pose(right, false, false, false).lift, 0.0, "the right column hasn't started yet")
	assert_true(_is_rest(_pose(enemy, false, false, false)), "only the side whose turn it is")
	fx.advance(BoardFx.READY_STAGGER * 6)
	assert_gt(_pose(right, false, false, false).lift, 0.04, "then the ripple reaches the right")
	fx.advance(1.0)
	assert_true(_is_rest(_pose(right, false, false, false)))
	assert_false(fx.active())
