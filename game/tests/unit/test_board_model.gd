extends GutTest
# BoardModel — LLD-content-board.md Section 8, cases C7–C17.

var board: BoardModel


func before_each() -> void:
	board = BoardModel.new()


func _sorted(tiles: Array) -> Array:
	var copy := tiles.duplicate()
	copy.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and a.x < b.x))
	return copy


# --- Board shape ---------------------------------------------------------------

func test_board_is_7x7_with_single_center() -> void:
	var centers := 0
	for y in 7:
		for x in 7:
			assert_not_null(board.get_tile(Vector2i(x, y)))
			if board.get_tile(Vector2i(x, y)).is_center:
				centers += 1
	assert_eq(centers, 1)
	assert_true(board.get_tile(Vector2i(3, 3)).is_center)
	assert_null(board.get_tile(Vector2i(7, 0)))
	assert_null(board.get_tile(Vector2i(-1, 3)))


func test_edge_rows() -> void:
	assert_eq(board.get_edge_row(1), 0)
	assert_eq(board.get_edge_row(2), 6)


func test_invalid_edge_row_side_errors() -> void:
	assert_eq(board.get_edge_row(3), -1)
	assert_push_error("player_side")


# --- get_legal_moves ---------------------------------------------------------

func test_c7_open_board_move_2_reaches_12_orthogonal_tiles() -> void:
	board.set_occupant(Vector2i(3, 3), "mover")
	var moves := board.get_legal_moves(Vector2i(3, 3), 2)
	var expected := [
		Vector2i(3, 1), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2),
		Vector2i(1, 3), Vector2i(2, 3), Vector2i(4, 3), Vector2i(5, 3),
		Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4), Vector2i(3, 5),
	]
	assert_eq(_sorted(moves), _sorted(expected))


func test_c7_move_budget_zero_has_no_moves() -> void:
	assert_eq(board.get_legal_moves(Vector2i(3, 3), 0).size(), 0)


func test_c7_corner_moves_stay_in_bounds() -> void:
	var moves := board.get_legal_moves(Vector2i(0, 0), 4)
	for m in moves:
		assert_true(board.is_in_bounds(m), str(m))
	assert_false(moves.has(Vector2i(0, 0)), "start tile is not a move")


func test_c8_occupied_tile_is_a_dead_end() -> void:
	board.set_occupant(Vector2i(3, 3), "mover")
	board.set_occupant(Vector2i(3, 4), "ally")
	var moves := board.get_legal_moves(Vector2i(3, 3), 2)
	assert_false(moves.has(Vector2i(3, 4)))
	assert_false(moves.has(Vector2i(3, 5)))


func test_c9_passable_predicate_passes_through_but_cannot_stop() -> void:
	board.set_occupant(Vector2i(3, 3), "mover")
	board.set_occupant(Vector2i(3, 4), "ally")
	var moves := board.get_legal_moves(Vector2i(3, 3), 2, "orthogonal",
			func(pos): return pos == Vector2i(3, 4))
	assert_false(moves.has(Vector2i(3, 4)))
	assert_true(moves.has(Vector2i(3, 5)))


func test_c15_pylon_does_not_block_movement_but_blocks_los() -> void:
	board.set_occupant(Vector2i(3, 3), "mover")
	board.place_object(Vector2i(3, 4), "pylon", "p1")
	assert_true(board.get_legal_moves(Vector2i(3, 3), 2).has(Vector2i(3, 4)))
	assert_false(board.has_line_of_sight(Vector2i(3, 3), Vector2i(3, 5)))


func test_stone_blocks_movement_and_los() -> void:
	board.set_occupant(Vector2i(3, 3), "mover")
	board.place_object(Vector2i(3, 4), "stone", "p2")
	var moves := board.get_legal_moves(Vector2i(3, 3), 2)
	assert_false(moves.has(Vector2i(3, 4)))
	assert_false(moves.has(Vector2i(3, 5)))
	assert_false(board.has_line_of_sight(Vector2i(3, 3), Vector2i(3, 5)))
	assert_eq(board.get_placed_object(Vector2i(3, 4)).current_hp, 1)


func test_c17_object_passable_predicate_passes_through_barricade() -> void:
	board.set_occupant(Vector2i(3, 3), "mover")
	board.place_object(Vector2i(3, 4), "barricade", "p1")
	var moves := board.get_legal_moves(Vector2i(3, 3), 2, "orthogonal",
			Callable(), func(pos): return pos == Vector2i(3, 4))
	assert_false(moves.has(Vector2i(3, 4)))
	assert_true(moves.has(Vector2i(3, 5)))


func test_max_passes_is_counted_per_path() -> void:
	# Two allies in a column: one pass reaches past the first, not past both.
	board.set_occupant(Vector2i(3, 3), "mover")
	board.set_occupant(Vector2i(3, 4), "a")
	board.set_occupant(Vector2i(3, 5), "b")
	var always := func(_pos): return true
	var moves := board.get_legal_moves(Vector2i(3, 3), 3, "orthogonal", always, Callable(), 1)
	assert_false(moves.has(Vector2i(3, 6)), "would need two passes")
	assert_true(moves.has(Vector2i(2, 5)), "one pass, then sideways")
	assert_true(moves.has(Vector2i(4, 4)), "a different path's pass isn't used up")
	var unlimited := board.get_legal_moves(Vector2i(3, 3), 3, "orthogonal", always)
	assert_true(unlimited.has(Vector2i(3, 6)))


func test_zero_max_passes_means_no_pass() -> void:
	board.set_occupant(Vector2i(3, 3), "mover")
	board.set_occupant(Vector2i(3, 4), "a")
	var moves := board.get_legal_moves(Vector2i(3, 3), 2, "orthogonal", func(_p): return true, Callable(), 0)
	assert_false(moves.has(Vector2i(3, 5)))


func test_entering_frost_ends_the_move() -> void:
	board.set_occupant(Vector2i(3, 3), "mover")
	board.get_tile(Vector2i(3, 4)).terrain_type = "frost"
	var moves := board.get_legal_moves(Vector2i(3, 3), 3)
	assert_true(moves.has(Vector2i(3, 4)), "can stop on frost")
	assert_false(moves.has(Vector2i(3, 5)), "can't continue through it")
	assert_true(moves.has(Vector2i(4, 5)), "other routes still work")


func test_ignore_terrain_crosses_frost() -> void:
	board.set_occupant(Vector2i(3, 3), "mover")
	board.get_tile(Vector2i(3, 4)).terrain_type = "frost"
	var moves := board.get_legal_moves(Vector2i(3, 3), 3, "orthogonal", Callable(), Callable(), -1, true)
	assert_true(moves.has(Vector2i(3, 6)))


func test_unsupported_movement_pattern_errors() -> void:
	assert_eq(board.get_legal_moves(Vector2i(3, 3), 2, "diagonal").size(), 0)
	assert_push_error("diagonal")


# --- has_line_of_sight -------------------------------------------------------

func test_c10_character_between_blocks_los() -> void:
	board.set_occupant(Vector2i(3, 4), "enemy_id")
	assert_false(board.has_line_of_sight(Vector2i(3, 3), Vector2i(3, 5)))


func test_c11_ignored_character_does_not_block_los() -> void:
	board.set_occupant(Vector2i(3, 4), "enemy_id")
	assert_true(board.has_line_of_sight(Vector2i(3, 3), Vector2i(3, 5), ["enemy_id"] as Array[String]))


func test_c14_barricade_blocks_los() -> void:
	board.place_object(Vector2i(3, 4), "barricade", "p1")
	assert_false(board.has_line_of_sight(Vector2i(3, 3), Vector2i(3, 5)))


func test_los_clear_lane_and_adjacent() -> void:
	assert_true(board.has_line_of_sight(Vector2i(0, 3), Vector2i(6, 3)))
	board.set_occupant(Vector2i(3, 4), "adjacent")
	assert_true(board.has_line_of_sight(Vector2i(3, 3), Vector2i(3, 4)), "adjacent target is never blocked")


func test_los_is_false_off_row_and_column() -> void:
	assert_false(board.has_line_of_sight(Vector2i(0, 0), Vector2i(2, 2)))


# --- get_tiles_in_range ------------------------------------------------------

func test_c12_range_2_from_center_is_8_tiles() -> void:
	var tiles := board.get_tiles_in_range(Vector2i(3, 3), 2)
	assert_eq(tiles.size(), 8)
	for t in tiles:
		assert_true(t.x == 3 or t.y == 3, str(t))


func test_c13_range_from_corner_stays_in_bounds() -> void:
	var tiles := board.get_tiles_in_range(Vector2i(0, 0), 3)
	assert_eq(tiles.size(), 6)
	for t in tiles:
		assert_true(board.is_in_bounds(t), str(t))


# --- Placed objects ----------------------------------------------------------

func test_place_object_uses_registry_hp_and_unique_ids() -> void:
	var a := board.place_object(Vector2i(1, 1), "barricade", "p1")
	var b := board.place_object(Vector2i(2, 2), "barricade", "p1")
	assert_ne(a, b)
	assert_eq(board.get_placed_object(Vector2i(1, 1)).current_hp, 2)
	assert_eq(board.get_placed_object(Vector2i(1, 1)).owner_player_id, "p1")


func test_c16_cannot_place_object_on_occupied_tile() -> void:
	assert_ne(board.place_object(Vector2i(3, 4), "barricade", "p1"), "")
	assert_eq(board.place_object(Vector2i(3, 4), "pylon", "p2"), "")
	assert_push_error("not empty")
	assert_eq(board.get_placed_object(Vector2i(3, 4)).type_id, "barricade", "original object untouched")


func test_c16_cannot_place_object_on_character() -> void:
	board.set_occupant(Vector2i(3, 4), "someone")
	assert_eq(board.place_object(Vector2i(3, 4), "barricade", "p1"), "")
	assert_push_error("not empty")


func test_unknown_object_type_errors() -> void:
	assert_eq(board.place_object(Vector2i(3, 4), "portal", "p1"), "")
	assert_push_error("portal")
	assert_null(board.get_placed_object(Vector2i(3, 4)))


func test_remove_object_clears_tile() -> void:
	board.place_object(Vector2i(3, 4), "barricade", "p1")
	board.remove_object(Vector2i(3, 4))
	assert_null(board.get_placed_object(Vector2i(3, 4)))
	assert_false(board.is_blocked_for_movement(Vector2i(3, 4)))
	board.remove_object(Vector2i(3, 4))  # no-op, no error
	assert_push_error_count(0)
