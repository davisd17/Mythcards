extends GutTest
# LevelingSystem — LLD-leveling.md Section 8, cases C1–C9, driven by emitting the
# EventBus signals it listens to.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const GYMNAST := Fixture.GYMNAST   # p1; opponent's edge is row 6
const SNIPER := Fixture.SNIPER
const GENERAL := Fixture.GENERAL
const TIGER := Fixture.TIGER
const GUARD := Fixture.GUARD       # p2; opponent's edge is row 0
const ATTENDANT := Fixture.ATTENDANT
const CENTER := Vector2i(3, 3)


class SpyAbility extends AbilitySystem:
	func handler_for(_i) -> AbilityHandler:
		return AbilityHandler.new()
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
	_moved(GYMNAST, Vector2i(2, 6))
	assert_eq(_c(GYMNAST).level, 2)
	assert_eq(ability.level_ups, [[GYMNAST, 2]])
	assert_signal_emitted_with_parameters(EventBus, "character_leveled_up", [GYMNAST, 2])


func test_c1_player_2_levels_on_row_0() -> void:
	_moved(GUARD, Vector2i(4, 0))
	assert_eq(_c(GUARD).level, 2)


func test_own_back_row_and_midboard_do_not_level() -> void:
	_moved(GYMNAST, Vector2i(2, 0))
	_moved(GYMNAST, Vector2i(2, 5))
	assert_eq(_c(GYMNAST).level, 1)
	assert_signal_not_emitted(EventBus, "character_leveled_up")


func test_c9_level_3_character_never_retriggers() -> void:
	_c(GYMNAST).level = 3
	_moved(GYMNAST, Vector2i(2, 6))
	assert_eq(_c(GYMNAST).level, 3)
	assert_signal_not_emitted(EventBus, "character_leveled_up")


func test_c8_ridden_mount_levels_when_carried_across() -> void:
	Fixture.put(GENERAL, Vector2i(3, 5))
	Fixture.mount_pair(GENERAL, TIGER)
	Fixture.put(GENERAL, Vector2i(3, 6))
	_c(TIGER).position = Vector2i(3, 6)   # RulesEngine keeps the Mount's position in sync
	EventBus.character_moved.emit(GENERAL, Vector2i(3, 5), Vector2i(3, 6))
	assert_eq(_c(GENERAL).level, 2)
	assert_eq(_c(TIGER).level, 2)


func test_being_repositioned_onto_the_edge_levels_up() -> void:
	# Pushed or placed there counts, not just moving there (designer ruling 2026-09-27).
	var gymnast := Fixture.put(GYMNAST, Vector2i(2, 6))
	EventBus.character_repositioned.emit(GYMNAST, Vector2i(2, 5), Vector2i(2, 6), "push")
	assert_eq(gymnast.level, 2)


func test_being_repositioned_onto_the_center_banks_embers() -> void:
	var sniper := Fixture.put(SNIPER, CENTER)
	sniper.spirit_ember_count = 1
	EventBus.character_repositioned.emit(SNIPER, Vector2i(3, 2), CENTER, "teleport")
	assert_eq(sniper.spirit_ember_count, 0)
	assert_eq(Fixture.state().get_player("p1").embers_delivered, 1)


# --- Spirit Embers (designer rulings 2026-10-11) ------------------------------

func test_c3_defeat_grants_the_attacker_an_ember() -> void:
	_defeated(GUARD, SNIPER)
	assert_eq(_c(SNIPER).spirit_ember_count, 1)
	assert_signal_emit_count(EventBus, "spirit_ember_picked_up", 1)
	assert_signal_emitted_with_parameters(EventBus, "spirit_ember_picked_up", [SNIPER, 1])


func test_c4_mounted_pair_kill_grants_two_embers() -> void:
	_defeated(Fixture.CONDUCTOR, SNIPER, "direct")
	_defeated(Fixture.GLIDER, SNIPER, "mount_propagation")
	assert_eq(_c(SNIPER).spirit_ember_count, 2)
	assert_signal_emit_count(EventBus, "spirit_ember_picked_up", 2)


func test_embers_stack_onto_whoever_defeats_the_carrier() -> void:
	_c(GUARD).spirit_ember_count = 2          # undelivered
	_defeated(GUARD, SNIPER)
	assert_eq(_c(SNIPER).spirit_ember_count, 3, "its own 1 plus the 2 it carried")
	assert_signal_emitted_with_parameters(EventBus, "spirit_ember_picked_up", [SNIPER, 3])
	assert_eq(_c(GUARD).spirit_ember_count, 0)


func test_a_hazard_defeat_loses_the_embers() -> void:
	_c(GUARD).spirit_ember_count = 2
	_defeated(GUARD, GUARD)                     # a Leak: no enemy did it
	assert_eq(_c(GUARD).spirit_ember_count, 0)
	assert_signal_not_emitted(EventBus, "spirit_ember_picked_up")


func test_unknown_attacker_is_ignored() -> void:
	_defeated(GUARD, "nobody")
	assert_signal_not_emitted(EventBus, "spirit_ember_picked_up")


# --- Level 3: a Level 2 character defeats an enemy ------------------------------

func test_level_2_defeating_an_enemy_reaches_level_3() -> void:
	_c(SNIPER).level = 2
	_defeated(GUARD, SNIPER)
	assert_eq(_c(SNIPER).level, 3)
	assert_eq(ability.level_ups, [[SNIPER, 3]])
	assert_eq(_c(SNIPER).spirit_ember_count, 1, "and takes the Ember")


func test_level_1_defeating_an_enemy_only_takes_the_ember() -> void:
	_defeated(GUARD, SNIPER)
	assert_eq(_c(SNIPER).level, 1)
	assert_eq(_c(SNIPER).spirit_ember_count, 1)


func test_level_3_stays_level_3() -> void:
	_c(SNIPER).level = 3
	_defeated(GUARD, SNIPER)
	assert_eq(_c(SNIPER).level, 3)
	assert_signal_not_emitted(EventBus, "character_leveled_up")


func test_the_center_no_longer_levels() -> void:
	var sniper := _c(SNIPER)
	sniper.level = 2
	sniper.spirit_ember_count = 1
	_moved(SNIPER, CENTER)
	assert_eq(sniper.level, 2)


# --- Delivering Embers --------------------------------------------------------------

func test_a_carrier_on_the_center_banks_everything_it_holds() -> void:
	var sniper := _c(SNIPER)
	sniper.spirit_ember_count = 3
	_moved(SNIPER, CENTER)
	assert_eq(sniper.spirit_ember_count, 0)
	assert_eq(Fixture.state().get_player("p1").embers_delivered, 3)
	assert_signal_emitted_with_parameters(EventBus, "spirit_ember_delivered", [SNIPER])


func test_a_defeat_on_the_center_banks_at_once() -> void:
	Fixture.put(SNIPER, CENTER)
	_defeated(GUARD, SNIPER)
	assert_eq(Fixture.state().get_player("p1").embers_delivered, 1)


func test_four_banked_embers_win() -> void:
	Fixture.state().get_player("p1").embers_delivered = 2
	_c(SNIPER).spirit_ember_count = 2
	_moved(SNIPER, CENTER)
	assert_eq(Fixture.state().phase, "ended")
	assert_eq(Fixture.state().winner_id, "p1")
	assert_eq(Fixture.state().win_condition, "ember_delivery")


func test_defeated_characters_do_not_level() -> void:
	var gymnast := _c(GYMNAST)
	gymnast.defeated = true
	_moved(GYMNAST, Vector2i(2, 6))
	assert_eq(gymnast.level, 1)


# --- Match isolation -----------------------------------------------------------

func test_listener_from_an_earlier_match_ignores_the_new_match() -> void:
	# Same ids exist in every match, so a stale listener's signals would be read as
	# being about the new match's characters.
	var stale := leveling
	autofree(Fixture.start_match())   # replaces GameState.match_state
	Fixture.clear_board()
	var fresh_spy := SpyAbility.new(Fixture.board())
	leveling = LevelingSystem.new(Fixture.board(), fresh_spy)
	_moved(GYMNAST, Vector2i(2, 6))
	_defeated(GUARD, SNIPER)
	assert_eq(_c(GYMNAST).level, 2)
	assert_eq(_c(SNIPER).spirit_ember_count, 1)
	assert_signal_emit_count(EventBus, "spirit_ember_picked_up", 1, "only the current match's system announces")
	assert_signal_emit_count(EventBus, "character_leveled_up", 1)
	assert_eq(ability.level_ups, [], "the stale system's ability hook never ran")
	assert_eq(fresh_spy.level_ups, [[GYMNAST, 2]])
	stale = null
