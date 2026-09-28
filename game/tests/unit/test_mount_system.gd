extends GutTest
# MountSystem — LLD-combat-mount.md Section 8, cases C9–C12, plus rider defeat.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const GENERAL := Fixture.GENERAL   # Leader MOVE 2
const TIGER := Fixture.TIGER     # Mount  MOVE 4

var mounts: MountSystem


func before_each() -> void:
	autofree(Fixture.start_match())
	Fixture.clear_board()
	mounts = MountSystem.new(Fixture.board())


func after_each() -> void:
	Fixture.teardown()


func _c(id: String) -> CharacterInstance:
	return Fixture.character(id)


func test_c9_rider_climbs_onto_the_mounts_tile() -> void:
	# Designer ruling 2026-09-28 (PRD Section 8): the pair stays on the Mount's square.
	var general := Fixture.put(GENERAL, Vector2i(3, 3))
	var tiger := Fixture.put(TIGER, Vector2i(3, 4))
	mounts.mount(general, tiger)
	assert_eq(general.mounted_with_id, TIGER)
	assert_eq(tiger.mounted_with_id, GENERAL)
	assert_true(general.is_mounted_rider)
	assert_false(tiger.is_mounted_rider)
	assert_false(Fixture.board().is_occupied_by_character(Vector2i(3, 3)), "the rider's tile empties")
	assert_eq(Fixture.board().get_tile(Vector2i(3, 4)).occupant_id, GENERAL)
	assert_eq(general.position, Vector2i(3, 4))
	assert_eq(tiger.position, Vector2i(3, 4))


func test_c10_dismount_places_mount_rider_stays() -> void:
	var general := Fixture.put(GENERAL, Vector2i(3, 3))
	var tiger := Fixture.put(TIGER, Vector2i(3, 4))
	mounts.mount(general, tiger)
	mounts.dismount(general, Vector2i(2, 4))
	assert_eq(tiger.position, Vector2i(2, 4))
	assert_eq(Fixture.board().get_tile(Vector2i(2, 4)).occupant_id, TIGER)
	assert_eq(general.position, Vector2i(3, 4))
	assert_eq(Fixture.board().get_tile(Vector2i(3, 4)).occupant_id, GENERAL)
	assert_eq(general.mounted_with_id, "")
	assert_eq(tiger.mounted_with_id, "")
	assert_false(general.is_mounted_rider)


func test_mount_and_dismount_report_who_repositioned() -> void:
	watch_signals(EventBus)
	var general := Fixture.put(GENERAL, Vector2i(3, 3))
	Fixture.put(TIGER, Vector2i(3, 4))
	mounts.mount(general, _c(TIGER))
	assert_signal_emitted_with_parameters(EventBus, "character_repositioned", [GENERAL, Vector2i(3, 3), Vector2i(3, 4), "mount"])
	mounts.dismount(general, Vector2i(2, 4))
	assert_signal_emitted_with_parameters(EventBus, "character_repositioned", [TIGER, Vector2i(3, 4), Vector2i(2, 4), "dismount"])
	assert_signal_not_emitted(EventBus, "character_moved")


func test_c11_mounted_rider_uses_mounts_move() -> void:
	Fixture.put(GENERAL, Vector2i(3, 3))
	Fixture.mount_pair(GENERAL, TIGER)
	assert_eq(mounts.get_effective_move_stat(_c(GENERAL)), 4)


func test_mount_move_includes_the_mounts_own_slow() -> void:
	Fixture.put(GENERAL, Vector2i(3, 3))
	Fixture.mount_pair(GENERAL, TIGER)
	_c(TIGER).status_effects.append(StatusEffect.new("temp_move", -1))
	assert_eq(mounts.get_effective_move_stat(_c(GENERAL)), 3)


func test_c12_unmounted_uses_own_move() -> void:
	Fixture.put(GENERAL, Vector2i(3, 3))
	assert_eq(mounts.get_effective_move_stat(_c(GENERAL)), 2)


func test_handle_rider_defeated_returns_and_flags_the_mount() -> void:
	Fixture.put(GENERAL, Vector2i(3, 3))
	Fixture.mount_pair(GENERAL, TIGER)
	var fallen := mounts.handle_rider_defeated(_c(GENERAL))
	assert_eq(fallen, _c(TIGER))
	assert_true(fallen.defeated)
	assert_eq(fallen.mounted_with_id, "")
	assert_eq(_c(GENERAL).mounted_with_id, "")


func test_handle_rider_defeated_with_broken_link() -> void:
	var general := Fixture.put(GENERAL, Vector2i(3, 3))
	general.is_mounted_rider = true
	general.mounted_with_id = "p1_nobody"
	assert_null(mounts.handle_rider_defeated(general))
	assert_push_error("no resolvable mount")
