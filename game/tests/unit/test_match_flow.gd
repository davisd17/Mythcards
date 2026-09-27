extends GutTest
# Integration: real RulesEngine + CombatResolver + MountSystem, driven only through
# request_action (LLD-rules-engine C13, minus abilities until step 10).

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const YURI := Fixture.YURI       # ATK 2, RANGE 2
const IRINA := Fixture.IRINA     # Leader, HP 4
const VERA := Fixture.VERA       # Mount, MOVE 4
const NAIA := Fixture.NAIA       # ATK 2, HP 4
const LABORER := Fixture.LABORER


func before_each() -> void:
	autofree(Fixture.start_match())   # p1's first turn: 2 pool AP
	Fixture.clear_board()
	watch_signals(EventBus)


func after_each() -> void:
	Fixture.teardown()


func _act(action: String, actor: String, payload: Dictionary = {}) -> Dictionary:
	return RulesEngine.request_action(action, actor, payload)


func _pass_round() -> void:
	# The active player ends their turn, then the other player ends theirs.
	var first := Fixture.state().active_player_id
	assert_true(_act("end_turn", first).success)
	assert_true(_act("end_turn", Fixture.state().get_other_player_id(first)).success)


func _c(id: String) -> CharacterInstance:
	return Fixture.character(id)


func test_attacks_across_turns_defeat_a_character() -> void:
	Fixture.put(YURI, Vector2i(3, 2))
	var naia := Fixture.put(NAIA, Vector2i(3, 4))   # 2 tiles away, in RANGE 2

	assert_eq(_act("attack", YURI, {"target_id": NAIA}), {"success": true, "damage": 2, "defeated": false})
	assert_eq(naia.current_hp, 2)
	assert_eq(_act("attack", YURI, {"target_id": NAIA}).reason, "no character AP remaining")

	_pass_round()
	assert_eq(_act("attack", YURI, {"target_id": NAIA}), {"success": true, "damage": 2, "defeated": true})
	assert_true(naia.defeated)
	assert_false(Fixture.board().is_occupied_by_character(Vector2i(3, 4)))
	assert_eq(RulesEngine.get_legal_attack_target_ids(YURI), [] as Array[String])
	assert_signal_emitted_with_parameters(EventBus, "character_defeated", [NAIA, YURI, "direct"])

	_act("end_turn", "p1")
	assert_eq(_act("move", NAIA, {"to": Vector2i(3, 5)}).reason, "character defeated")


func test_defeated_tile_is_free_to_move_into() -> void:
	Fixture.put(YURI, Vector2i(3, 2))
	var naia := Fixture.put(NAIA, Vector2i(3, 3))
	naia.current_hp = 2
	_act("attack", YURI, {"target_id": NAIA})
	assert_true(naia.defeated)
	_pass_round()
	assert_true(_act("move", YURI, {"to": Vector2i(3, 3)}).success)


func test_mount_ride_dismount_sequence() -> void:
	var irina := Fixture.put(IRINA, Vector2i(3, 1))
	var vera := Fixture.put(VERA, Vector2i(3, 2))

	assert_true(_act("mount", IRINA, {"mount_id": VERA}).success)
	assert_true(irina.is_mounted_rider)
	assert_false(Fixture.board().is_occupied_by_character(Vector2i(3, 2)))
	assert_eq(_act("move", IRINA, {"to": Vector2i(3, 3)}).reason, "no character AP remaining",
			"mounting used Irina's action this turn")
	assert_eq(_act("move", VERA, {"to": Vector2i(3, 3)}).reason, "carrying a rider")

	_pass_round()
	assert_true(RulesEngine.get_legal_move_tiles(IRINA).has(Vector2i(3, 5)), "4 tiles at the Mount's MOVE")
	assert_true(_act("move", IRINA, {"to": Vector2i(3, 5)}).success)
	assert_eq(vera.position, Vector2i(3, 5))

	_pass_round()
	assert_true(_act("dismount", IRINA, {"to": Vector2i(2, 5)}).success)
	assert_eq(irina.position, Vector2i(3, 5))
	assert_eq(vera.position, Vector2i(2, 5))
	assert_eq(Fixture.board().get_tile(Vector2i(2, 5)).occupant_id, VERA)
	assert_false(irina.is_mounted_rider)
	assert_eq(Fixture.state().get_player("p1").pool_ap_remaining, 3)


func test_defeating_a_mounted_pair_defeats_both() -> void:
	var irina := Fixture.put(IRINA, Vector2i(3, 3))
	Fixture.put(VERA, Vector2i(3, 2))
	Fixture.put(NAIA, Vector2i(3, 4))
	_act("mount", IRINA, {"mount_id": VERA})
	_act("end_turn", "p1")

	# The Mount has no tile of its own while ridden, so only the pair is a target.
	assert_eq(RulesEngine.get_legal_attack_target_ids(NAIA), [IRINA] as Array[String])
	assert_eq(_act("attack", NAIA, {"target_id": VERA}).reason, "mount is being ridden; attack the rider")
	assert_eq(_act("attack", NAIA, {"target_id": IRINA}).damage, 2)

	_pass_round()
	assert_true(_act("attack", NAIA, {"target_id": IRINA}).defeated)
	assert_true(irina.defeated)
	assert_true(_c(VERA).defeated)
	assert_signal_emit_count(EventBus, "character_defeated", 2)
	assert_false(Fixture.board().is_occupied_by_character(Vector2i(3, 3)))


func test_moving_onto_the_opponents_edge_levels_up() -> void:
	var worker := Fixture.put(Fixture.WORKER, Vector2i(0, 5))
	assert_true(_act("move", Fixture.WORKER, {"to": Vector2i(0, 6)}).success)
	assert_eq(worker.level, 2)
	assert_signal_emitted_with_parameters(EventBus, "character_leveled_up", [Fixture.WORKER, 2])


func test_kill_then_carry_the_ember_to_the_center_for_level_3() -> void:
	var yuri := Fixture.put(YURI, Vector2i(3, 1))
	yuri.level = 2
	Fixture.put(LABORER, Vector2i(3, 2))   # HP 2, dies to one hit

	assert_true(_act("attack", YURI, {"target_id": LABORER}).defeated)
	assert_eq(yuri.spirit_ember_count, 1)

	_pass_round()
	assert_true(_act("move", YURI, {"to": Vector2i(3, 3)}).success)
	assert_eq(yuri.level, 3)
	assert_eq(yuri.spirit_ember_count, 0)
	assert_signal_emitted_with_parameters(EventBus, "spirit_ember_delivered", [YURI])


func test_levels_reset_in_a_new_match() -> void:
	var worker := Fixture.put(Fixture.WORKER, Vector2i(0, 5))
	_act("move", Fixture.WORKER, {"to": Vector2i(0, 6)})
	assert_eq(worker.level, 2)
	Fixture.teardown()
	autofree(Fixture.start_match())
	assert_eq(Fixture.character(Fixture.WORKER).level, 1)


func test_shield_absorbs_a_real_attack() -> void:
	Fixture.put(YURI, Vector2i(3, 2))
	var naia := Fixture.put(NAIA, Vector2i(3, 3))
	Fixture.shield(NAIA, 1)
	assert_eq(_act("attack", YURI, {"target_id": NAIA}).damage, 1)
	assert_eq(naia.current_hp, 3)
