extends GutTest
# MountSystem — LLD-combat-mount.md Section 8, cases C9–C12, plus rider defeat.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const IRINA := Fixture.IRINA   # Leader MOVE 2
const VERA := Fixture.VERA     # Mount  MOVE 4

var mounts: MountSystem


func before_each() -> void:
	autofree(Fixture.start_match())
	Fixture.clear_board()
	mounts = MountSystem.new(Fixture.board())


func after_each() -> void:
	Fixture.teardown()


func _c(id: String) -> CharacterInstance:
	return Fixture.character(id)


func test_c9_mount_shares_the_riders_tile() -> void:
	var irina := Fixture.put(IRINA, Vector2i(3, 3))
	var vera := Fixture.put(VERA, Vector2i(3, 4))
	mounts.mount(irina, vera)
	assert_eq(irina.mounted_with_id, VERA)
	assert_eq(vera.mounted_with_id, IRINA)
	assert_true(irina.is_mounted_rider)
	assert_false(vera.is_mounted_rider)
	assert_false(Fixture.board().is_occupied_by_character(Vector2i(3, 4)), "Mount's tile vacated")
	assert_eq(Fixture.board().get_tile(Vector2i(3, 3)).occupant_id, IRINA)
	assert_eq(vera.position, irina.position)


func test_c10_dismount_places_mount_rider_stays() -> void:
	var irina := Fixture.put(IRINA, Vector2i(3, 3))
	var vera := Fixture.put(VERA, Vector2i(3, 4))
	mounts.mount(irina, vera)
	mounts.dismount(irina, Vector2i(2, 3))
	assert_eq(vera.position, Vector2i(2, 3))
	assert_eq(Fixture.board().get_tile(Vector2i(2, 3)).occupant_id, VERA)
	assert_eq(irina.position, Vector2i(3, 3))
	assert_eq(Fixture.board().get_tile(Vector2i(3, 3)).occupant_id, IRINA)
	assert_eq(irina.mounted_with_id, "")
	assert_eq(vera.mounted_with_id, "")
	assert_false(irina.is_mounted_rider)


func test_c11_mounted_rider_uses_mounts_move() -> void:
	Fixture.put(IRINA, Vector2i(3, 3))
	Fixture.mount_pair(IRINA, VERA)
	assert_eq(mounts.get_effective_move_stat(_c(IRINA)), 4)


func test_mount_move_includes_the_mounts_own_slow() -> void:
	Fixture.put(IRINA, Vector2i(3, 3))
	Fixture.mount_pair(IRINA, VERA)
	_c(VERA).status_effects.append(StatusEffect.new("temp_move", -1))
	assert_eq(mounts.get_effective_move_stat(_c(IRINA)), 3)


func test_c12_unmounted_uses_own_move() -> void:
	Fixture.put(IRINA, Vector2i(3, 3))
	assert_eq(mounts.get_effective_move_stat(_c(IRINA)), 2)


func test_handle_rider_defeated_returns_and_flags_the_mount() -> void:
	Fixture.put(IRINA, Vector2i(3, 3))
	Fixture.mount_pair(IRINA, VERA)
	var fallen := mounts.handle_rider_defeated(_c(IRINA))
	assert_eq(fallen, _c(VERA))
	assert_true(fallen.defeated)
	assert_eq(fallen.mounted_with_id, "")
	assert_eq(_c(IRINA).mounted_with_id, "")


func test_handle_rider_defeated_with_broken_link() -> void:
	var irina := Fixture.put(IRINA, Vector2i(3, 3))
	irina.is_mounted_rider = true
	irina.mounted_with_id = "p1_nobody"
	assert_null(mounts.handle_rider_defeated(irina))
	assert_push_error("no resolvable mount")
