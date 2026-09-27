extends GutTest
# VictoryChecker — LLD-victory-checker.md Section 8, cases C1–C7, on a real board
# (the checker asks RulesEngine for legal moves, so no doubles are needed).

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const BOGATYR := Fixture.BOGATYR   # p1 Hero, MOVE 2
const TIGER := Fixture.TIGER       # MOVE 4
const GYMNAST := Fixture.GYMNAST
const SNIPER := Fixture.SNIPER
const GUARD := Fixture.GUARD
const ATTENDANT := Fixture.ATTENDANT


func before_each() -> void:
	autofree(Fixture.start_match())
	Fixture.clear_board()
	watch_signals(EventBus)


func after_each() -> void:
	Fixture.teardown()


func _c(id: String) -> CharacterInstance:
	return Fixture.character(id)


# Hero in the corner, walled in by an ally and an enemy.
func _box_in_hero() -> void:
	Fixture.put(BOGATYR, Vector2i(0, 0))
	Fixture.put(GYMNAST, Vector2i(1, 0))
	Fixture.put(GUARD, Vector2i(0, 1))


# --- Hero capture --------------------------------------------------------------

func test_c1_hero_with_a_legal_move_is_not_captured() -> void:
	Fixture.put(BOGATYR, Vector2i(3, 0))
	VictoryChecker.check_hero_capture("p1")
	assert_signal_emitted_with_parameters(EventBus, "hero_capture_checked", ["p1", true])
	assert_signal_not_emitted(EventBus, "match_ended")
	assert_eq(Fixture.state().phase, "in_progress")


func test_c2_boxed_in_hero_is_captured() -> void:
	_box_in_hero()
	VictoryChecker.check_hero_capture("p1")
	assert_signal_emitted_with_parameters(EventBus, "hero_capture_checked", ["p1", false])
	assert_signal_emitted_with_parameters(EventBus, "match_ended", ["p2", "hero_capture"])
	assert_eq(Fixture.state().phase, "ended")
	assert_eq(Fixture.state().winner_id, "p2")
	assert_eq(Fixture.state().win_condition, "hero_capture")


func test_placed_objects_can_trap_a_hero() -> void:
	Fixture.put(BOGATYR, Vector2i(0, 0))
	Fixture.board().place_object(Vector2i(1, 0), "barricade", "p2")
	Fixture.board().place_object(Vector2i(0, 1), "barricade", "p2")
	VictoryChecker.check_hero_capture("p1")
	assert_eq(Fixture.state().winner_id, "p2")


func test_c3_combat_defeated_hero_is_not_a_capture() -> void:
	_box_in_hero()
	_c(BOGATYR).defeated = true
	VictoryChecker.check_hero_capture("p1")
	assert_signal_not_emitted(EventBus, "hero_capture_checked")
	assert_signal_not_emitted(EventBus, "match_ended")


func test_c6_no_check_after_the_match_ended() -> void:
	_box_in_hero()
	Fixture.state().phase = "ended"
	VictoryChecker.check_hero_capture("p1")
	assert_signal_not_emitted(EventBus, "hero_capture_checked")
	assert_signal_not_emitted(EventBus, "match_ended")


func test_c7_a_hero_slowed_to_zero_move_is_captured() -> void:
	# Open neighbors don't help if the Hero can't move at all right now.
	Fixture.put(BOGATYR, Vector2i(3, 3))
	_c(BOGATYR).status_effects.append(StatusEffect.new("temp_move", -2, "next_turn"))
	VictoryChecker.check_hero_capture("p1")
	assert_eq(Fixture.state().win_condition, "hero_capture")


func test_c7_a_mounted_hero_moves_with_the_mounts_move() -> void:
	# Same slow on the rider, but a mounted pair uses the Mount's MOVE (BR-014).
	Fixture.put(BOGATYR, Vector2i(3, 3))
	_c(BOGATYR).status_effects.append(StatusEffect.new("temp_move", -2, "next_turn"))
	Fixture.mount_pair(BOGATYR, TIGER)
	VictoryChecker.check_hero_capture("p1")
	assert_signal_emitted_with_parameters(EventBus, "hero_capture_checked", ["p1", true])
	assert_eq(Fixture.state().phase, "in_progress")


func test_only_the_checked_players_hero_matters() -> void:
	_box_in_hero()                       # p1's Hero is trapped...
	Fixture.put(Fixture.ORACLE, Vector2i(3, 6))
	VictoryChecker.check_hero_capture("p2")   # ...but it's p2's turn ending
	assert_eq(Fixture.state().phase, "in_progress")


func test_opening_position_never_captures() -> void:
	# Straight from setup, full back rows: each Hero can still step forward.
	autofree(Fixture.start_match())
	TurnManager.victory_checker = null
	for i in 4:
		RulesEngine.request_action("end_turn", Fixture.state().active_player_id, {})
	assert_eq(Fixture.state().phase, "in_progress")
	assert_eq(Fixture.state().turn_number, 5)


# --- Army defeat ---------------------------------------------------------------

func _defeat_all_but(player_id: String, survivor_id: String) -> void:
	for c in Fixture.state().get_player(player_id).characters:
		if c.instance_id != survivor_id:
			c.defeated = true


func test_c4_a_survivor_keeps_the_match_going() -> void:
	_defeat_all_but("p2", ATTENDANT)
	EventBus.character_defeated.emit(GUARD, SNIPER, "direct")
	assert_signal_not_emitted(EventBus, "match_ended")


func test_c5_last_defeat_ends_the_match() -> void:
	_defeat_all_but("p2", ATTENDANT)
	_c(ATTENDANT).defeated = true
	EventBus.character_defeated.emit(ATTENDANT, SNIPER, "direct")
	assert_signal_emitted_with_parameters(EventBus, "match_ended", ["p1", "army_defeat"])
	assert_eq(Fixture.state().winner_id, "p1")
	assert_eq(Fixture.state().win_condition, "army_defeat")


func test_mount_propagation_can_be_the_last_defeat() -> void:
	for c in Fixture.state().get_player("p1").characters:
		c.defeated = true
	EventBus.character_defeated.emit(TIGER, GUARD, "mount_propagation")
	assert_signal_emitted_with_parameters(EventBus, "match_ended", ["p2", "army_defeat"])


func test_match_ends_only_once() -> void:
	for c in Fixture.state().get_player("p2").characters:
		c.defeated = true
	EventBus.character_defeated.emit(ATTENDANT, SNIPER, "direct")
	EventBus.character_defeated.emit(GUARD, SNIPER, "direct")
	assert_signal_emit_count(EventBus, "match_ended", 1)
