extends GutTest
# RulesEngine — LLD-rules-engine.md Section 8, cases C0a–C12b. CombatResolver,
# AbilitySystem, and MountSystem are faked where the case needs their behavior.

const SetupFlowScript := preload("res://scripts/scenes/setup_flow.gd")

# Closed City (p1)
const WORKER := "p1_r-reactor-worker"   # Common  MOVE 2 RANGE 1
const VERA := "p1_r-vera-7"             # Mount   MOVE 4
const YURI := "p1_r-yuri-volkov"        # Warrior MOVE 2 RANGE 2
const IRINA := "p1_r-irina-karpova"     # Leader  MOVE 2 RANGE 3
const ORLOV := "p1_r-mikhail-orlov"     # Hero    MOVE 2 RANGE 3
# Flood Survivors (p2)
const NAIA := "p2_a-flood-survivor-naia"
const LABORER := "p2_a-flood-survivor-stone-line-laborer"


class FakeCombat:
	var calls: Array = []
	func resolve_attack(attacker, defender) -> Dictionary:
		calls.append([attacker.instance_id, defender.instance_id])
		return {"damage": 2, "defeated": false}


class FakeAbility extends AbilitySystem:
	var usable := true
	var targets: Array = [Vector2i(3, 3)]
	var executed: Array = []
	var execute_result := {"success": true, "placed": "obj_0"}
	var bonus_calls: Array = []
	func can_use_ability(_i, _id) -> bool:
		return usable
	func get_legal_ability_targets(_i, _id) -> Array:
		return targets
	func execute_ability(instance, ability_id, target) -> Dictionary:
		executed.append([instance.instance_id, ability_id, target])
		return execute_result
	func execute_reactive_bonus(instance, tag, _payload) -> Dictionary:
		bonus_calls.append([instance.instance_id, tag])
		return {"success": true}


class FakeMount extends MountSystem:
	var mounted: Array = []
	var dismounted: Array = []
	func mount(rider, mount_char) -> void:
		mounted.append([rider.instance_id, mount_char.instance_id])
	func dismount(rider, to) -> void:
		dismounted.append([rider.instance_id, to])


var combat: FakeCombat
var ability: FakeAbility
var mounts: FakeMount


func before_each() -> void:
	TurnManager.relic_event_deck = _NullDeck.new()
	TurnManager.victory_checker = _NullChecker.new()
	var setup = autofree(SetupFlowScript.new())
	setup.select_culture("p1", "Russian-inspired")
	setup.select_culture("p2", "Atlantean")
	for id in ["p1", "p2"]:
		var x := 0
		for c in setup.get_player(id).characters:
			setup.place_character(id, c.instance_id, Vector2i(x, 0 if id == "p1" else 6))
			x += 1
	setup.start_match()
	_clear_board()
	_state().get_player("p1").pool_ap_remaining = 4   # most cases want room to act
	combat = FakeCombat.new()
	ability = FakeAbility.new(_board())
	mounts = FakeMount.new(_board())
	RulesEngine.use_systems(combat, ability, mounts)
	watch_signals(EventBus)


func after_each() -> void:
	GameState.reset()
	TurnManager.relic_event_deck = null
	TurnManager.victory_checker = null


class _NullDeck:
	func build_deck(_a, _b, _c) -> void:
		pass
	func draw_for(_p) -> void:
		pass


class _NullChecker:
	func check_hero_capture(_p) -> void:
		pass


# --- Arrangement helpers -----------------------------------------------------

func _state() -> MatchState:
	return GameState.match_state


func _board() -> BoardModel:
	return GameState.match_state.board


func _char(id: String) -> CharacterInstance:
	return _state().find_character(id)


func _clear_board() -> void:
	for p in _state().players:
		for c in p.characters:
			if c.is_placed():
				_board().clear_occupant(c.position)
				c.position = CharacterInstance.UNPLACED


func _put(id: String, pos: Vector2i) -> CharacterInstance:
	var c := _char(id)
	if c.is_placed():
		_board().clear_occupant(c.position)
	_board().set_occupant(pos, id)
	c.position = pos
	return c


func _mount_pair(rider_id: String, mount_id: String) -> void:
	# Arranges a mounted pair directly (MountSystem.mount lands in step 9).
	var rider := _char(rider_id)
	var mount_char := _char(mount_id)
	rider.mounted_with_id = mount_id
	rider.is_mounted_rider = true
	mount_char.mounted_with_id = rider_id
	if mount_char.is_placed():
		_board().clear_occupant(mount_char.position)
	mount_char.position = rider.position


func _act(action: String, actor: String, payload: Dictionary = {}) -> Dictionary:
	return RulesEngine.request_action(action, actor, payload)


# --- Move ----------------------------------------------------------------------

func test_c1_move_updates_position_and_spends_ap() -> void:
	var worker := _put(WORKER, Vector2i(3, 3))
	var result := _act("move", WORKER, {"to": Vector2i(3, 5)})
	assert_eq(result, {"success": true})
	assert_eq(worker.position, Vector2i(3, 5))
	assert_true(_board().is_occupied_by_character(Vector2i(3, 5)))
	assert_false(_board().is_occupied_by_character(Vector2i(3, 3)))
	assert_eq(_state().get_player("p1").pool_ap_remaining, 3)
	assert_eq(worker.character_ap_remaining, 0)
	assert_true(worker.ability_uses_this_turn.get("moved", false))
	assert_signal_emitted_with_parameters(EventBus, "character_moved", [WORKER, Vector2i(3, 3), Vector2i(3, 5)])


func test_c0a_legal_move_preview_matches_board_and_mutates_nothing() -> void:
	var worker := _put(WORKER, Vector2i(3, 3))
	_put(YURI, Vector2i(3, 4))
	var tiles := RulesEngine.get_legal_move_tiles(WORKER)
	assert_eq(tiles, _board().get_legal_moves(Vector2i(3, 3), 2))
	assert_false(tiles.has(Vector2i(3, 5)), "blocked by the ally")
	assert_eq(worker.position, Vector2i(3, 3))
	assert_eq(worker.character_ap_remaining, 1)
	assert_signal_not_emitted(EventBus, "action_requested")


func test_c0b_unknown_actor_has_no_moves() -> void:
	assert_eq(RulesEngine.get_legal_move_tiles("nobody"), [] as Array[Vector2i])


func test_c1a_mounted_rider_moves_with_mounts_move() -> void:
	var irina := _put(IRINA, Vector2i(3, 1))    # Leader MOVE 2 riding VERA-7 (MOVE 4)
	_mount_pair(IRINA, VERA)
	assert_true(_act("move", IRINA, {"to": Vector2i(3, 5)}).success, "4 tiles is only reachable at the Mount's MOVE")
	assert_eq(irina.position, Vector2i(3, 5))
	assert_eq(_char(VERA).position, Vector2i(3, 5), "mount position kept in sync")
	assert_eq(_char(VERA).character_ap_remaining, 1, "the Mount spends no AP")


func test_c2_illegal_move_changes_nothing() -> void:
	var worker := _put(WORKER, Vector2i(3, 3))
	var result := _act("move", WORKER, {"to": Vector2i(3, 6)})   # 3 tiles, MOVE 2
	assert_eq(result, {"success": false, "reason": "illegal move"})
	assert_eq(worker.position, Vector2i(3, 3))
	assert_eq(worker.character_ap_remaining, 1)
	assert_eq(_state().get_player("p1").pool_ap_remaining, 4)


func test_move_without_destination_fails() -> void:
	_put(WORKER, Vector2i(3, 3))
	assert_eq(_act("move", WORKER, {}).reason, "missing destination")


# --- Common validation -------------------------------------------------------

func test_c3_not_your_turn() -> void:
	_put(NAIA, Vector2i(3, 3))
	assert_eq(_act("move", NAIA, {"to": Vector2i(3, 4)}), {"success": false, "reason": "not your turn"})


func test_c4_no_character_ap() -> void:
	_put(WORKER, Vector2i(3, 3)).character_ap_remaining = 0
	assert_eq(_act("move", WORKER, {"to": Vector2i(3, 4)}).reason, "no character AP remaining")


func test_no_pool_ap() -> void:
	_put(WORKER, Vector2i(3, 3))
	_state().get_player("p1").pool_ap_remaining = 0
	assert_eq(_act("move", WORKER, {"to": Vector2i(3, 4)}).reason, "no pool AP remaining")


func test_first_turn_2_ap_pool_allows_only_2_actions() -> void:
	_state().get_player("p1").pool_ap_remaining = 2
	_put(WORKER, Vector2i(1, 3))
	_put(YURI, Vector2i(3, 3))
	_put(ORLOV, Vector2i(5, 3))
	assert_true(_act("move", WORKER, {"to": Vector2i(1, 4)}).success)
	assert_true(_act("move", YURI, {"to": Vector2i(3, 4)}).success)
	assert_eq(_act("move", ORLOV, {"to": Vector2i(5, 4)}).reason, "no pool AP remaining")


func test_mounted_mount_cannot_act_on_its_own() -> void:
	_put(IRINA, Vector2i(3, 1))
	_mount_pair(IRINA, VERA)
	assert_eq(_act("move", VERA, {"to": Vector2i(3, 2)}).reason, "carrying a rider")


func test_defeated_character_cannot_act() -> void:
	_put(WORKER, Vector2i(3, 3)).defeated = true
	assert_eq(_act("move", WORKER, {"to": Vector2i(3, 4)}).reason, "character defeated")


func test_unknown_actor() -> void:
	assert_eq(_act("move", "p1_nobody", {"to": Vector2i(0, 0)}).reason, "unknown actor")


func test_no_actions_when_match_not_active() -> void:
	_put(WORKER, Vector2i(3, 3))
	_state().phase = "ended"
	assert_eq(_act("move", WORKER, {"to": Vector2i(3, 4)}).reason, "match not active")


func test_unknown_action_type_is_a_caller_error() -> void:
	var result := _act("teleport", WORKER)
	assert_eq(result.reason, "unknown action type")
	assert_push_error("teleport")
	assert_signal_not_emitted(EventBus, "action_requested")
	assert_signal_not_emitted(EventBus, "action_resolved")


func test_c11_requested_and_resolved_fire_once_on_success_and_failure() -> void:
	_put(WORKER, Vector2i(3, 3))
	_act("move", WORKER, {"to": Vector2i(3, 4)})
	assert_signal_emit_count(EventBus, "action_requested", 1)
	assert_signal_emit_count(EventBus, "action_resolved", 1)
	_act("move", WORKER, {"to": Vector2i(3, 5)})   # fails: no character AP left
	assert_signal_emit_count(EventBus, "action_requested", 2)
	assert_signal_emit_count(EventBus, "action_resolved", 2)
	assert_signal_emitted_with_parameters(EventBus, "action_resolved",
			["move", WORKER, {"success": false, "reason": "no character AP remaining"}])


# --- Attack --------------------------------------------------------------------

func test_c0c_legal_attack_targets_are_enemies_in_range_with_los() -> void:
	_put(YURI, Vector2i(3, 2))            # RANGE 2
	_put(NAIA, Vector2i(3, 4))            # in range
	_put(LABORER, Vector2i(1, 2))         # in range
	_put(WORKER, Vector2i(4, 2))          # ally — never a target
	_put("p2_a-flood-survivor-sahu-ren", Vector2i(3, 5))   # out of range
	var ids := RulesEngine.get_legal_attack_target_ids(YURI)
	ids.sort()
	assert_eq(ids, [NAIA, LABORER] as Array[String])   # sorted: "...naia" < "...stone-line-laborer"


func test_c5_attack_in_range_resolves_and_spends_ap() -> void:
	var yuri := _put(YURI, Vector2i(3, 2))
	_put(NAIA, Vector2i(3, 4))
	var result := _act("attack", YURI, {"target_id": NAIA})
	assert_eq(result, {"success": true, "damage": 2, "defeated": false})
	assert_eq(combat.calls, [[YURI, NAIA]])
	assert_eq(yuri.character_ap_remaining, 0)
	assert_eq(_state().get_player("p1").pool_ap_remaining, 3)


func test_c6_out_of_range() -> void:
	_put(YURI, Vector2i(3, 1))
	_put(NAIA, Vector2i(3, 4))            # distance 3, RANGE 2
	assert_eq(_act("attack", YURI, {"target_id": NAIA}), {"success": false, "reason": "out of range"})
	assert_eq(combat.calls, [])


func test_c6_diagonal_is_out_of_range() -> void:
	_put(YURI, Vector2i(3, 3))
	_put(NAIA, Vector2i(4, 4))
	assert_eq(_act("attack", YURI, {"target_id": NAIA}).reason, "out of range")


func test_c7_blocked_line_of_sight() -> void:
	_put(ORLOV, Vector2i(3, 1))           # RANGE 3
	_put(WORKER, Vector2i(3, 2))          # ally in the lane
	_put(NAIA, Vector2i(3, 4))
	var result := _act("attack", ORLOV, {"target_id": NAIA})
	assert_eq(result, {"success": false, "reason": "blocked line of sight"})
	assert_eq(_char(ORLOV).character_ap_remaining, 1, "no AP spent")


func test_placed_object_blocks_attack_los() -> void:
	_put(ORLOV, Vector2i(3, 1))
	_board().place_object(Vector2i(3, 2), "stone", "p2")
	_put(NAIA, Vector2i(3, 3))
	assert_eq(_act("attack", ORLOV, {"target_id": NAIA}).reason, "blocked line of sight")


func test_cannot_attack_an_ally() -> void:
	_put(YURI, Vector2i(3, 2))
	_put(WORKER, Vector2i(3, 3))
	assert_eq(_act("attack", YURI, {"target_id": WORKER}).reason, "cannot attack an ally")


func test_attack_unknown_or_defeated_target() -> void:
	_put(YURI, Vector2i(3, 2))
	assert_eq(_act("attack", YURI, {"target_id": "nobody"}).reason, "unknown target")
	_put(NAIA, Vector2i(3, 3)).defeated = true
	assert_eq(_act("attack", YURI, {"target_id": NAIA}).reason, "target already defeated")


func test_attack_range_uses_temp_range_and_ability_bonus() -> void:
	var yuri := _put(YURI, Vector2i(3, 1))   # RANGE 2
	_put(NAIA, Vector2i(3, 4))               # distance 3
	yuri.status_effects.append(StatusEffect.new("temp_range", 1))
	assert_true(RulesEngine.get_legal_attack_target_ids(YURI).has(NAIA))


# --- Ability -------------------------------------------------------------------

func test_c8_ability_unavailable() -> void:
	_put(ORLOV, Vector2i(3, 3))
	ability.usable = false
	assert_eq(_act("ability", ORLOV, {"ability_id": "r-mikhail-orlov", "target": Vector2i(3, 3)}).reason,
			"ability unavailable")


func test_baseline_ability_system_has_no_usable_abilities_yet() -> void:
	RulesEngine.use_systems(combat, AbilitySystem.new(_board()), mounts)
	_put(ORLOV, Vector2i(3, 3))
	assert_eq(_act("ability", ORLOV, {"ability_id": "r-mikhail-orlov", "target": Vector2i(3, 4)}).reason,
			"ability unavailable")


func test_ability_success_spends_ap_and_merges_result() -> void:
	var orlov := _put(ORLOV, Vector2i(3, 3))
	var result := _act("ability", ORLOV, {"ability_id": "r-mikhail-orlov", "target": Vector2i(3, 3)})
	assert_eq(result, {"success": true, "placed": "obj_0"})
	assert_eq(ability.executed, [[ORLOV, "r-mikhail-orlov", Vector2i(3, 3)]])
	assert_eq(orlov.character_ap_remaining, 0)


func test_ability_illegal_target() -> void:
	_put(ORLOV, Vector2i(3, 3))
	assert_eq(_act("ability", ORLOV, {"ability_id": "r-mikhail-orlov", "target": Vector2i(0, 0)}).reason,
			"illegal ability target")
	assert_eq(ability.executed, [])


func test_failed_ability_execution_spends_nothing() -> void:
	var orlov := _put(ORLOV, Vector2i(3, 3))
	ability.execute_result = {"success": false, "reason": "no empty tile"}
	assert_eq(_act("ability", ORLOV, {"ability_id": "r-mikhail-orlov", "target": Vector2i(3, 3)}),
			{"success": false, "reason": "no empty tile"})
	assert_eq(orlov.character_ap_remaining, 1)


# --- Mount / dismount ----------------------------------------------------------

func test_mount_adjacent_mount_calls_mount_system_and_spends_ap() -> void:
	var irina := _put(IRINA, Vector2i(3, 3))
	_put(VERA, Vector2i(3, 4))
	assert_true(_act("mount", IRINA, {"mount_id": VERA}).success)
	assert_eq(mounts.mounted, [[IRINA, VERA]])
	assert_eq(irina.character_ap_remaining, 0)


func test_c9_mount_not_adjacent() -> void:
	_put(IRINA, Vector2i(3, 3))
	_put(VERA, Vector2i(3, 5))
	assert_eq(_act("mount", IRINA, {"mount_id": VERA}).reason, "not adjacent")
	assert_eq(mounts.mounted, [])


func test_mount_rules() -> void:
	_put(WORKER, Vector2i(2, 3))
	_put(IRINA, Vector2i(3, 3))
	_put(VERA, Vector2i(3, 4))
	_put("p2_a-flood-survivor-ahesu", Vector2i(4, 3))
	assert_eq(_act("mount", WORKER, {"mount_id": VERA}).reason, "only a Hero or Leader may mount")
	assert_eq(_act("mount", IRINA, {"mount_id": "p2_a-flood-survivor-ahesu"}).reason, "invalid mount target")
	assert_eq(_act("mount", IRINA, {"mount_id": WORKER}).reason, "invalid mount target")
	assert_eq(_act("mount", IRINA, {"mount_id": "nobody"}).reason, "unknown mount")
	_char(IRINA).status_effects.append(StatusEffect.new("no_mount_dismount", 0, "next_turn"))
	assert_eq(_act("mount", IRINA, {"mount_id": VERA}).reason, "cannot mount right now")


func test_already_mounted() -> void:
	_put(IRINA, Vector2i(3, 3))
	_put(ORLOV, Vector2i(2, 3))
	_mount_pair(IRINA, VERA)
	assert_eq(_act("mount", ORLOV, {"mount_id": VERA}).reason, "already mounted")


func test_dismount_to_empty_adjacent_tile() -> void:
	var irina := _put(IRINA, Vector2i(3, 3))
	_mount_pair(IRINA, VERA)
	assert_true(_act("dismount", IRINA, {"to": Vector2i(3, 4)}).success)
	assert_eq(mounts.dismounted, [[IRINA, Vector2i(3, 4)]])
	assert_eq(irina.character_ap_remaining, 0)


func test_c10_dismount_with_no_empty_adjacent_tile() -> void:
	_put(IRINA, Vector2i(0, 0))
	_mount_pair(IRINA, VERA)
	_put(WORKER, Vector2i(1, 0))
	_put(YURI, Vector2i(0, 1))
	assert_eq(_act("dismount", IRINA, {"to": Vector2i(1, 0)}).reason, "no empty adjacent tile")
	assert_eq(_act("dismount", IRINA, {"to": Vector2i(-1, 0)}).reason, "no empty adjacent tile")
	assert_eq(mounts.dismounted, [])


func test_dismount_rules() -> void:
	_put(ORLOV, Vector2i(3, 3))
	assert_eq(_act("dismount", ORLOV, {"to": Vector2i(3, 4)}).reason, "not mounted")
	_put(IRINA, Vector2i(5, 3))
	_mount_pair(IRINA, VERA)
	assert_eq(_act("dismount", IRINA, {"to": Vector2i(5, 5)}).reason, "not adjacent")


# --- End turn ------------------------------------------------------------------

func test_c12_end_turn_hands_over() -> void:
	assert_eq(_act("end_turn", "p1"), {"success": true})
	assert_eq(_state().active_player_id, "p2")
	assert_eq(_state().get_player("p2").pool_ap_remaining, 4)


func test_end_turn_only_by_active_player() -> void:
	assert_eq(_act("end_turn", "p2").reason, "not your turn")
	assert_eq(_state().active_player_id, "p1")


# --- Reactive bonus ------------------------------------------------------------

func test_c12a_reactive_bonus_is_free() -> void:
	var worker := _put(WORKER, Vector2i(3, 3))
	worker.ability_uses_this_turn["l3_bonus_available"] = true
	var result := _act("reactive_bonus", WORKER, {"tag": "l3_bonus", "target_id": NAIA})
	assert_true(result.success)
	assert_eq(ability.bonus_calls, [[WORKER, "l3_bonus"]])
	assert_eq(worker.character_ap_remaining, 1)
	assert_eq(_state().get_player("p1").pool_ap_remaining, 4)


func test_reactive_bonus_works_with_zero_ap() -> void:
	var worker := _put(WORKER, Vector2i(3, 3))
	worker.character_ap_remaining = 0
	worker.ability_uses_this_match["l3_bonus_available"] = true
	assert_true(_act("reactive_bonus", WORKER, {"tag": "l3_bonus"}).success)


func test_c12b_reactive_bonus_needs_an_offer() -> void:
	_put(WORKER, Vector2i(3, 3))
	assert_eq(_act("reactive_bonus", WORKER, {"tag": "l3_bonus"}).reason, "no bonus action available")


func test_reactive_bonus_blocked_by_no_reaction() -> void:
	var worker := _put(WORKER, Vector2i(3, 3))
	worker.ability_uses_this_turn["l3_bonus_available"] = true
	worker.status_effects.append(StatusEffect.new("no_reaction", 0, "next_turn"))
	assert_eq(_act("reactive_bonus", WORKER, {"tag": "l3_bonus"}).reason, "reactions disabled")
