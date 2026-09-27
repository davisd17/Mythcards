extends GutTest
# Integration: real RulesEngine + CombatResolver + MountSystem, driven only through
# request_action (LLD-rules-engine C13, minus abilities until step 10).

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const SNIPER := Fixture.SNIPER       # ATK 2, RANGE 4, HP 3
const GENERAL := Fixture.GENERAL     # Leader, HP 5
const TIGER := Fixture.TIGER       # Mount, MOVE 4
const GUARD := Fixture.GUARD         # ATK 1, HP 5
const CONDUCTOR := Fixture.CONDUCTOR # HP 4
const ATTENDANT := Fixture.ATTENDANT


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
	Fixture.put(SNIPER, Vector2i(3, 2))
	var conductor := Fixture.put(CONDUCTOR, Vector2i(3, 4))   # 2 tiles away, in RANGE 4

	assert_eq(_act("attack", SNIPER, {"target_id": CONDUCTOR}), {"success": true, "damage": 2, "defeated": false})
	assert_eq(conductor.current_hp, 2)
	assert_eq(_act("attack", SNIPER, {"target_id": CONDUCTOR}).reason, "no character AP remaining")

	_pass_round()
	assert_eq(_act("attack", SNIPER, {"target_id": CONDUCTOR}), {"success": true, "damage": 2, "defeated": true})
	assert_true(conductor.defeated)
	assert_false(Fixture.board().is_occupied_by_character(Vector2i(3, 4)))
	assert_eq(RulesEngine.get_legal_attack_target_ids(SNIPER), [] as Array[String])
	assert_signal_emitted_with_parameters(EventBus, "character_defeated", [CONDUCTOR, SNIPER, "direct"])

	_act("end_turn", "p1")
	assert_eq(_act("move", CONDUCTOR, {"to": Vector2i(3, 5)}).reason, "character defeated")


func test_defeated_tile_is_free_to_move_into() -> void:
	Fixture.put(SNIPER, Vector2i(3, 2))
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	guard.current_hp = 2
	_act("attack", SNIPER, {"target_id": GUARD})
	assert_true(guard.defeated)
	_pass_round()
	assert_true(_act("move", SNIPER, {"to": Vector2i(3, 3)}).success)


func test_mount_ride_dismount_sequence() -> void:
	var general := Fixture.put(GENERAL, Vector2i(3, 1))
	var tiger := Fixture.put(TIGER, Vector2i(3, 2))

	assert_true(_act("mount", GENERAL, {"mount_id": TIGER}).success)
	assert_true(general.is_mounted_rider)
	assert_false(Fixture.board().is_occupied_by_character(Vector2i(3, 2)))
	assert_eq(_act("move", GENERAL, {"to": Vector2i(3, 3)}).reason, "no character AP remaining",
			"mounting used Irina's action this turn")
	assert_eq(_act("move", TIGER, {"to": Vector2i(3, 3)}).reason, "carrying a rider")

	_pass_round()
	assert_true(RulesEngine.get_legal_move_tiles(GENERAL).has(Vector2i(3, 5)), "4 tiles at the Mount's MOVE")
	assert_true(_act("move", GENERAL, {"to": Vector2i(3, 5)}).success)
	assert_eq(tiger.position, Vector2i(3, 5))

	_pass_round()
	assert_true(_act("dismount", GENERAL, {"to": Vector2i(2, 5)}).success)
	assert_eq(general.position, Vector2i(3, 5))
	assert_eq(tiger.position, Vector2i(2, 5))
	assert_eq(Fixture.board().get_tile(Vector2i(2, 5)).occupant_id, TIGER)
	assert_false(general.is_mounted_rider)
	assert_eq(Fixture.state().get_player("p1").pool_ap_remaining, 3)


func test_defeating_a_mounted_pair_defeats_both() -> void:
	var general := Fixture.put(GENERAL, Vector2i(3, 3))
	general.current_hp = 2   # arranged: every Atlantean has ATK 1
	Fixture.put(TIGER, Vector2i(3, 2))
	Fixture.put(GUARD, Vector2i(3, 4))
	_act("mount", GENERAL, {"mount_id": TIGER})
	_act("end_turn", "p1")

	# The Mount has no tile of its own while ridden, so only the pair is a target.
	assert_eq(RulesEngine.get_legal_attack_target_ids(GUARD), [GENERAL] as Array[String])
	assert_eq(_act("attack", GUARD, {"target_id": TIGER}).reason, "mount is being ridden; attack the rider")
	assert_eq(_act("attack", GUARD, {"target_id": GENERAL}).damage, 1)

	_pass_round()
	assert_true(_act("attack", GUARD, {"target_id": GENERAL}).defeated)
	assert_true(general.defeated)
	assert_true(_c(TIGER).defeated)
	assert_signal_emit_count(EventBus, "character_defeated", 2)
	assert_false(Fixture.board().is_occupied_by_character(Vector2i(3, 3)))


func test_moving_onto_the_opponents_edge_levels_up() -> void:
	var gymnast := Fixture.put(Fixture.GYMNAST, Vector2i(0, 5))
	assert_true(_act("move", Fixture.GYMNAST, {"to": Vector2i(0, 6)}).success)
	assert_eq(gymnast.level, 2)
	assert_signal_emitted_with_parameters(EventBus, "character_leveled_up", [Fixture.GYMNAST, 2])


func test_kill_then_carry_the_ember_to_the_center_for_level_3() -> void:
	var sniper := Fixture.put(SNIPER, Vector2i(3, 1))
	sniper.level = 2
	Fixture.put(ATTENDANT, Vector2i(3, 2))   # HP 2, dies to one hit

	assert_true(_act("attack", SNIPER, {"target_id": ATTENDANT}).defeated)
	assert_eq(sniper.spirit_ember_count, 1)

	_pass_round()
	assert_true(_act("move", SNIPER, {"to": Vector2i(3, 3)}).success)
	assert_eq(sniper.level, 3)
	assert_eq(sniper.spirit_ember_count, 0)
	assert_signal_emitted_with_parameters(EventBus, "spirit_ember_delivered", [SNIPER])


func test_dismounting_onto_the_opponents_edge_levels_the_mount() -> void:
	var general := Fixture.put(GENERAL, Vector2i(3, 5))
	Fixture.mount_pair(GENERAL, TIGER)
	assert_true(_act("dismount", GENERAL, {"to": Vector2i(3, 6)}).success)
	assert_eq(_c(TIGER).level, 2)
	assert_eq(general.level, 1, "the rider stayed on row 5")


func test_mounting_a_rider_on_the_edge_levels_the_mount() -> void:
	Fixture.put(GENERAL, Vector2i(3, 6))
	Fixture.put(TIGER, Vector2i(3, 5))
	assert_true(_act("mount", GENERAL, {"mount_id": TIGER}).success)
	assert_eq(_c(TIGER).level, 2)


func test_being_pushed_onto_the_edge_levels_up() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 1))   # p2's opponent edge is row 0
	RulesEngine.get_legal_move_tiles(GUARD)          # builds this match's systems
	RulesEngine.combat_resolver.apply_push(guard, Vector2i(3, 2), 1)
	assert_eq(guard.position, Vector2i(3, 0))
	assert_eq(guard.level, 2)


func test_levels_reset_in_a_new_match() -> void:
	var gymnast := Fixture.put(Fixture.GYMNAST, Vector2i(0, 5))
	_act("move", Fixture.GYMNAST, {"to": Vector2i(0, 6)})
	assert_eq(gymnast.level, 2)
	Fixture.teardown()
	autofree(Fixture.start_match())
	assert_eq(Fixture.character(Fixture.GYMNAST).level, 1)


func test_ending_a_turn_with_a_trapped_hero_loses() -> void:
	TurnManager.victory_checker = null   # the real VictoryChecker
	Fixture.put(Fixture.BOGATYR, Vector2i(0, 0))
	Fixture.put(Fixture.GYMNAST, Vector2i(1, 0))
	Fixture.put(GUARD, Vector2i(0, 1))
	assert_true(_act("end_turn", "p1").success)
	assert_eq(Fixture.state().phase, "ended")
	assert_eq(Fixture.state().winner_id, "p2")
	assert_eq(Fixture.state().active_player_id, "p1", "the turn never passed")
	assert_signal_not_emitted(EventBus, "turn_ended")
	assert_eq(_act("end_turn", "p1").reason, "match not active")


func test_trapped_hero_is_fine_if_freed_before_turn_end() -> void:
	TurnManager.victory_checker = null
	Fixture.put(Fixture.BOGATYR, Vector2i(0, 0))
	Fixture.put(Fixture.GYMNAST, Vector2i(1, 0))
	Fixture.put(GUARD, Vector2i(0, 1))
	assert_true(_act("move", Fixture.GYMNAST, {"to": Vector2i(2, 1)}).success)   # opens (1, 0)
	assert_true(_act("end_turn", "p1").success)
	assert_eq(Fixture.state().phase, "in_progress")
	assert_eq(Fixture.state().active_player_id, "p2")


func test_defeating_the_last_enemy_wins_immediately() -> void:
	for c in Fixture.state().get_player("p2").characters:
		if c.instance_id != ATTENDANT:
			c.defeated = true
	Fixture.put(SNIPER, Vector2i(3, 1))
	Fixture.put(ATTENDANT, Vector2i(3, 3))   # HP 2
	assert_true(_act("attack", SNIPER, {"target_id": ATTENDANT}).defeated)
	assert_signal_emitted_with_parameters(EventBus, "match_ended", ["p1", "army_defeat"])
	assert_eq(_act("move", Fixture.GYMNAST, {"to": Vector2i(0, 1)}).reason, "match not active")


func test_shield_absorbs_a_real_attack() -> void:
	Fixture.put(SNIPER, Vector2i(3, 2))
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	Fixture.shield(GUARD, 1)
	assert_eq(_act("attack", SNIPER, {"target_id": GUARD}).damage, 1)
	assert_eq(guard.current_hp, 4)
