extends GutTest
# Phase 2 action feedback (LLD-board-fx.md): BoardFx turns EventBus signals into short
# presentation-only animations that always finish, and never touch the model.

const Fixture := preload("res://tests/helpers/match_fixture.gd")

var fx: BoardFx


func before_each() -> void:
	autofree(Fixture.start_teams_match())
	Fixture.state().shared_deck.clear()
	fx = BoardFx.new()
	fx.connect_signals()


func after_each() -> void:
	Fixture.teardown()


func _run_out() -> void:
	for i in 40:
		fx.advance(0.05)


func test_a_move_slides_from_the_old_tile_and_settles_on_the_new_one() -> void:
	var c := Fixture.character("p1_r-yuri-volkov")
	var from := c.position
	var to := from + Vector2i(0, 2)
	Fixture.board().clear_occupant(from)
	c.position = to
	EventBus.character_moved.emit(c.instance_id, from, to)
	assert_almost_eq(fx.offset_tiles(c), Vector2(0, -2), Vector2(0.001, 0.001), "starts drawn on the old tile")
	fx.advance(BoardFx.SLIDE * 0.5)
	assert_between(fx.offset_tiles(c).y, -1.0, 0.0, "partway there, ease-out")
	fx.advance(BoardFx.SLIDE)
	assert_eq(fx.offset_tiles(c), Vector2.ZERO, "settled")


func test_a_real_move_action_starts_a_slide() -> void:
	var c := Fixture.character("p1_r-reactor-worker")
	var to := c.position + Vector2i(0, 1)
	var result: Dictionary = RulesEngine.request_action("move", c.instance_id, {"to": to})
	assert_true(result.success, str(result))
	assert_true(fx.slides.has(c.instance_id))
	assert_eq(c.position, to, "the model moved at once; only the drawing catches up")


func test_a_mounted_pair_slides_whichever_id_moved() -> void:
	Fixture.mount_pair("p1_r-irina-karpova", "p1_r-vera-7")
	var rider := Fixture.character("p1_r-irina-karpova")
	EventBus.character_moved.emit("p1_r-vera-7", rider.position - Vector2i(1, 0), rider.position)
	assert_almost_eq(fx.offset_tiles(rider).x, -1.0, 0.001)


func test_damage_flashes_the_target_and_floats_a_number() -> void:
	var target := Fixture.character("p2_a-flood-survivor-naia")
	EventBus.damage_resolved.emit("p1_r-yuri-volkov", target.instance_id, 2, [])
	assert_gt(fx.hit_strength(target.instance_id), 0.9)
	assert_eq(fx.effects.back().text, "-2")
	EventBus.damage_resolved.emit("p1_r-yuri-volkov", target.instance_id, 0, [])
	assert_eq(fx.effects.back().text, "Blocked", "fully prevented damage says so")


func test_an_attack_lunges_toward_the_target_and_returns() -> void:
	var attacker := Fixture.put("p1_r-yuri-volkov", Vector2i(3, 2))
	var target := Fixture.put("p2_a-flood-survivor-naia", Vector2i(3, 3))
	EventBus.attack_resolved.emit(attacker.instance_id, target.instance_id, 1, false)
	fx.advance(BoardFx.LUNGE * 0.5)
	assert_gt(fx.offset_tiles(attacker).y, 0.1, "leaning up the board toward the target")
	fx.advance(BoardFx.LUNGE)
	assert_eq(fx.offset_tiles(attacker), Vector2.ZERO)


func test_a_defeat_leaves_a_fading_ghost_but_not_for_the_mount_under_a_rider() -> void:
	var c := Fixture.character("p2_a-flood-survivor-naia")
	EventBus.character_defeated.emit(c.instance_id, "p1_r-yuri-volkov", "direct")
	EventBus.character_defeated.emit("p2_a-flood-survivor-ahesu", "p1_r-yuri-volkov", "mount_propagation")
	assert_eq(fx.ghosts.size(), 1)
	assert_eq(fx.ghosts[0].pos, c.position)


func test_level_up_shields_and_embers_get_their_own_flourish() -> void:
	var id := "p1_r-mikhail-orlov"
	EventBus.character_leveled_up.emit(id, 2)
	EventBus.status_added.emit(id, "shield", 1, "")
	EventBus.status_added.emit(id, "marked", 1, "")
	EventBus.spirit_ember_picked_up.emit(id)
	var kinds := fx.effects.map(func(e): return e.kind)
	assert_eq(kinds, ["level", "ring", "burst"], "a mark gets no ring")
	assert_eq(fx.effects[0].text, "LEVEL 2")


func test_every_effect_finishes_within_a_second() -> void:
	var c := Fixture.character("p2_a-flood-survivor-naia")
	EventBus.character_moved.emit(c.instance_id, c.position, c.position + Vector2i(1, 0))
	EventBus.damage_resolved.emit("p1_r-yuri-volkov", c.instance_id, 1, [])
	EventBus.character_leveled_up.emit(c.instance_id, 3)
	EventBus.character_defeated.emit(c.instance_id, "p1_r-yuri-volkov", "direct")
	assert_true(fx.active())
	fx.advance(1.0)
	assert_false(fx.active(), "nothing lingers past a second")


func test_effects_do_not_touch_the_model() -> void:
	var c := Fixture.character("p2_a-flood-survivor-naia")
	var before := [c.position, c.current_hp, c.defeated, c.level]
	EventBus.damage_resolved.emit("p1_r-yuri-volkov", c.instance_id, 3, [])
	EventBus.character_leveled_up.emit(c.instance_id, 2)
	_run_out()
	assert_eq([c.position, c.current_hp, c.defeated, c.level], before)
