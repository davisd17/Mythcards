extends GutTest
# Attacking placed objects (designer ruling 2026-09-27: attacks may target objects
# unless a card says otherwise). Payload {"target_pos": Vector2i}.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const SNIPER := Fixture.SNIPER       # ATK 2 RANGE 4
const GYMNAST := Fixture.GYMNAST     # ATK 1
const GENERAL := Fixture.GENERAL
const TIGER := Fixture.TIGER
const GUARD := Fixture.GUARD


func before_each() -> void:
	autofree(Fixture.start_match())
	Fixture.clear_board()
	Fixture.state().get_player("p1").pool_ap_remaining = 4
	watch_signals(EventBus)


func after_each() -> void:
	Fixture.teardown()


func _act(action: String, actor: String, payload: Dictionary = {}) -> Dictionary:
	return RulesEngine.request_action(action, actor, payload)


func _barricade(pos: Vector2i, owner: String = "p2") -> PlacedObjectInstance:
	Fixture.board().place_object(pos, "barricade", owner)   # 2 HP
	return Fixture.board().get_placed_object(pos)


func test_attack_destroys_an_enemy_barricade() -> void:
	Fixture.put(SNIPER, Vector2i(3, 1))
	_barricade(Vector2i(3, 3))
	assert_eq(_act("attack", SNIPER, {"target_pos": Vector2i(3, 3)}), {"success": true, "damage": 2, "destroyed": true})
	assert_null(Fixture.board().get_placed_object(Vector2i(3, 3)))
	assert_false(Fixture.board().is_blocked_for_movement(Vector2i(3, 3)), "no longer blocks")
	assert_signal_emitted_with_parameters(EventBus, "object_attacked", [SNIPER, Vector2i(3, 3), "barricade", 2, true])
	assert_eq(Fixture.character(SNIPER).character_ap_remaining, 0)


func test_partial_damage_leaves_the_object() -> void:
	Fixture.put(GYMNAST, Vector2i(3, 2))
	var obj := _barricade(Vector2i(3, 3))
	assert_eq(_act("attack", GYMNAST, {"target_pos": Vector2i(3, 3)}).destroyed, false)
	assert_eq(obj.current_hp, 1)


func test_objects_without_hp_cannot_be_damaged() -> void:
	# A Level 1 pylon has no printed HP.
	Fixture.put(SNIPER, Vector2i(3, 1))
	Fixture.board().place_object(Vector2i(3, 3), "pylon", "p2")
	assert_eq(_act("attack", SNIPER, {"target_pos": Vector2i(3, 3)}).reason, "object can't be damaged")


func test_own_objects_are_not_targets() -> void:
	Fixture.put(SNIPER, Vector2i(3, 1))
	_barricade(Vector2i(3, 3), "p1")
	assert_eq(_act("attack", SNIPER, {"target_pos": Vector2i(3, 3)}).reason, "cannot attack your own object")


func test_object_attacks_need_range_and_line_of_sight() -> void:
	Fixture.put(GYMNAST, Vector2i(3, 1))                 # RANGE 1
	_barricade(Vector2i(3, 3))
	assert_eq(_act("attack", GYMNAST, {"target_pos": Vector2i(3, 3)}).reason, "out of range")
	Fixture.put(SNIPER, Vector2i(3, 0))
	Fixture.put(GUARD, Vector2i(3, 2))
	assert_eq(_act("attack", SNIPER, {"target_pos": Vector2i(3, 3)}).reason, "blocked line of sight")
	assert_eq(_act("attack", SNIPER, {"target_pos": Vector2i(5, 5)}).reason, "no object there")


func test_preview_lists_attackable_objects() -> void:
	Fixture.put(SNIPER, Vector2i(3, 1))
	_barricade(Vector2i(3, 3))
	_barricade(Vector2i(1, 1), "p1")
	Fixture.board().place_object(Vector2i(5, 1), "pylon", "p2")
	assert_eq(RulesEngine.get_legal_attack_object_tiles(SNIPER), [Vector2i(3, 3)] as Array[Vector2i])


func test_an_object_attack_spends_next_attack_buffs() -> void:
	var sniper := Fixture.put(SNIPER, Vector2i(3, 1))
	_barricade(Vector2i(3, 3))
	RulesEngine.systems().ability.add_status(sniper, "temp_atk", 1, "this_turn", null, true)
	assert_eq(_act("attack", SNIPER, {"target_pos": Vector2i(3, 3)}).damage, 3)
	assert_eq(sniper.sum_status("temp_atk"), 0)


func test_an_object_attack_uses_up_a_ready_pounce() -> void:
	var tiger := Fixture.put(TIGER, Vector2i(3, 2))
	_barricade(Vector2i(3, 3))
	tiger.status_effects.append(StatusEffect.new("pounce_mark", 2, "until_used"))
	tiger.ability_uses_this_turn["moved"] = true
	assert_eq(_act("attack", TIGER, {"target_pos": Vector2i(3, 3)}).damage, 4)
	assert_false(tiger.has_status("pounce_mark"))


func test_breaking_a_barricade_frees_a_trapped_hero() -> void:
	# Capture is positional, so destroying the wall matters.
	TurnManager.victory_checker = null
	Fixture.put(Fixture.BOGATYR, Vector2i(0, 0))
	_barricade(Vector2i(1, 0))
	_barricade(Vector2i(0, 1))
	Fixture.put(SNIPER, Vector2i(3, 0))
	assert_true(_act("attack", SNIPER, {"target_pos": Vector2i(1, 0)}).destroyed)
	assert_true(_act("end_turn", "p1").success)
	assert_eq(Fixture.state().phase, "in_progress")
