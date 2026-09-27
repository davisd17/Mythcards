extends GutTest
# LevelingSystem — LLD-leveling.md Section 8, cases C1–C9, driven by emitting the
# EventBus signals it listens to.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const WORKER := Fixture.WORKER   # p1; opponent's edge is row 6
const YURI := Fixture.YURI
const IRINA := Fixture.IRINA
const VERA := Fixture.VERA
const NAIA := Fixture.NAIA       # p2; opponent's edge is row 0
const LABORER := Fixture.LABORER
const CENTER := Vector2i(3, 3)


class SpyAbility extends AbilitySystem:
	var level_ups: Array = []
	func apply_level_up_effects(instance, new_level) -> void:
		level_ups.append([instance.instance_id, new_level])


var ability: SpyAbility
var leveling: LevelingSystem


func before_each() -> void:
	autofree(Fixture.start_match())
	Fixture.clear_board()
	ability = SpyAbility.new(Fixture.board())
	leveling = LevelingSystem.new(Fixture.board(), ability)
	watch_signals(EventBus)


func after_each() -> void:
	leveling = null
	Fixture.teardown()


func _moved(id: String, to: Vector2i) -> void:
	var c := Fixture.put(id, to)
	EventBus.character_moved.emit(id, to, c.position)


func _defeated(victim: String, by: String, cause: String = "direct") -> void:
	EventBus.character_defeated.emit(victim, by, cause)


func _c(id: String) -> CharacterInstance:
	return Fixture.character(id)


# --- Level 2 -------------------------------------------------------------------

func test_c1_reaching_opponents_edge_gives_level_2() -> void:
	_moved(WORKER, Vector2i(2, 6))
	assert_eq(_c(WORKER).level, 2)
	assert_eq(ability.level_ups, [[WORKER, 2]])
	assert_signal_emitted_with_parameters(EventBus, "character_leveled_up", [WORKER, 2])


func test_c1_player_2_levels_on_row_0() -> void:
	_moved(NAIA, Vector2i(4, 0))
	assert_eq(_c(NAIA).level, 2)


func test_own_back_row_and_midboard_do_not_level() -> void:
	_moved(WORKER, Vector2i(2, 0))
	_moved(WORKER, Vector2i(2, 5))
	assert_eq(_c(WORKER).level, 1)
	assert_signal_not_emitted(EventBus, "character_leveled_up")


func test_c9_level_3_character_never_retriggers() -> void:
	_c(WORKER).level = 3
	_moved(WORKER, Vector2i(2, 6))
	assert_eq(_c(WORKER).level, 3)
	assert_signal_not_emitted(EventBus, "character_leveled_up")


func test_c8_ridden_mount_levels_when_carried_across() -> void:
	Fixture.put(IRINA, Vector2i(3, 5))
	Fixture.mount_pair(IRINA, VERA)
	Fixture.put(IRINA, Vector2i(3, 6))
	_c(VERA).position = Vector2i(3, 6)   # RulesEngine keeps the Mount's position in sync
	EventBus.character_moved.emit(IRINA, Vector2i(3, 5), Vector2i(3, 6))
	assert_eq(_c(IRINA).level, 2)
	assert_eq(_c(VERA).level, 2)


# --- Spirit Embers -------------------------------------------------------------

func test_c3_defeat_grants_the_attacker_an_ember() -> void:
	_defeated(NAIA, YURI)
	assert_eq(_c(YURI).spirit_ember_count, 1)
	assert_signal_emit_count(EventBus, "spirit_ember_picked_up", 1)
	assert_signal_emitted_with_parameters(EventBus, "spirit_ember_picked_up", [YURI])


func test_c4_mounted_pair_kill_grants_two_embers() -> void:
	_defeated(Fixture.MERET, YURI, "direct")
	_defeated(Fixture.AHESU, YURI, "mount_propagation")
	assert_eq(_c(YURI).spirit_ember_count, 2)
	assert_signal_emit_count(EventBus, "spirit_ember_picked_up", 2)


func test_unknown_attacker_is_ignored() -> void:
	_defeated(NAIA, "nobody")
	assert_signal_not_emitted(EventBus, "spirit_ember_picked_up")


# --- Level 3 -------------------------------------------------------------------

func test_c2_center_without_ember_stays_level_2() -> void:
	_c(YURI).level = 2
	_moved(YURI, CENTER)
	assert_eq(_c(YURI).level, 2)


func test_level_1_with_ember_on_center_stays_level_1() -> void:
	_c(YURI).spirit_ember_count = 1
	_moved(YURI, CENTER)
	assert_eq(_c(YURI).level, 1)
	assert_eq(_c(YURI).spirit_ember_count, 1)


func test_c6_level_2_carrying_ember_to_center_gives_level_3() -> void:
	var yuri := _c(YURI)
	yuri.level = 2
	yuri.spirit_ember_count = 1
	_moved(YURI, CENTER)
	assert_eq(yuri.level, 3)
	assert_eq(yuri.spirit_ember_count, 0)
	assert_eq(ability.level_ups, [[YURI, 3]])
	assert_signal_emitted_with_parameters(EventBus, "spirit_ember_delivered", [YURI])


func test_c5_ember_picked_up_on_center_completes_level_3() -> void:
	_c(YURI).level = 2
	Fixture.put(YURI, CENTER)
	_defeated(NAIA, YURI)
	assert_eq(_c(YURI).level, 3)
	assert_signal_emit_count(EventBus, "spirit_ember_delivered", 1)


func test_c4a_pair_kill_on_center_levels_once_and_keeps_the_spare() -> void:
	_c(YURI).level = 2
	Fixture.put(YURI, CENTER)
	_defeated(Fixture.MERET, YURI, "direct")
	_defeated(Fixture.AHESU, YURI, "mount_propagation")
	assert_eq(_c(YURI).level, 3)
	assert_eq(_c(YURI).spirit_ember_count, 1)
	assert_signal_emit_count(EventBus, "spirit_ember_delivered", 1)


func test_c7_level_2_on_center_with_ember_chains_to_level_3() -> void:
	# The edge row can't be the center on a 7x7 board, so drive the chain directly:
	# a Level 2 announcement for a character already qualified for Level 3.
	var yuri := Fixture.put(YURI, CENTER)
	yuri.level = 2
	yuri.spirit_ember_count = 1
	EventBus.character_leveled_up.emit(YURI, 2)
	assert_eq(yuri.level, 3)


func test_defeated_characters_do_not_level() -> void:
	var worker := _c(WORKER)
	worker.defeated = true
	_moved(WORKER, Vector2i(2, 6))
	assert_eq(worker.level, 1)


# --- Match isolation -----------------------------------------------------------

func test_listener_from_an_earlier_match_ignores_the_new_match() -> void:
	# Same ids exist in every match, so a stale listener's signals would be read as
	# being about the new match's characters.
	var stale := leveling
	autofree(Fixture.start_match())   # replaces GameState.match_state
	Fixture.clear_board()
	var fresh_spy := SpyAbility.new(Fixture.board())
	leveling = LevelingSystem.new(Fixture.board(), fresh_spy)
	_moved(WORKER, Vector2i(2, 6))
	_defeated(NAIA, YURI)
	assert_eq(_c(WORKER).level, 2)
	assert_eq(_c(YURI).spirit_ember_count, 1)
	assert_signal_emit_count(EventBus, "spirit_ember_picked_up", 1, "only the current match's system announces")
	assert_signal_emit_count(EventBus, "character_leveled_up", 1)
	assert_eq(ability.level_ups, [], "the stale system's ability hook never ran")
	assert_eq(fresh_spy.level_ups, [[WORKER, 2]])
	stale = null
