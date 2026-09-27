extends GutTest
# SetupFlow, MatchState, CharacterInstance — LLD-match-setup.md Section 8, cases C1–C7.

const SetupFlowScript := preload("res://scripts/scenes/setup_flow.gd")

const RUSSIAN := "Russian-inspired"
const ATLANTEAN := "Atlantean"
const ORLOV := "p1_r-mikhail-orlov"          # Closed City Hero
const WORKER := "p1_r-reactor-worker"        # Closed City Common

var setup


class FakeDeck:
	func build_deck(_a, _b, _c) -> void:
		pass
	func draw_for(_player_id) -> void:
		pass


func before_each() -> void:
	setup = autofree(SetupFlowScript.new())
	TurnManager.relic_event_deck = FakeDeck.new()


func after_each() -> void:
	GameState.reset()
	TurnManager.relic_event_deck = null


func _select_both() -> void:
	setup.select_culture("p1", RUSSIAN)
	setup.select_culture("p2", ATLANTEAN)


# Places every character of a player along their back row, left to right.
func _place_all(player_id: String) -> void:
	var row := 0 if player_id == "p1" else 6
	var x := 0
	for c in setup.get_player(player_id).characters:
		assert_true(setup.place_character(player_id, c.instance_id, Vector2i(x, row)))
		x += 1


# --- Culture selection -------------------------------------------------------

func test_c1_select_culture_builds_one_of_each_type() -> void:
	setup.select_culture("p1", RUSSIAN)
	var chars: Array[CharacterInstance] = setup.get_player("p1").characters
	assert_eq(chars.size(), 7)
	var types := chars.map(func(c): return c.data.type)
	for t in GameEnums.CHARACTER_TYPES:
		assert_eq(types.count(t), 1, t)


func test_c1_squad_starts_at_level_1_full_hp_unplaced() -> void:
	setup.select_culture("p1", RUSSIAN)
	var orlov: CharacterInstance = setup.get_player("p1").find_character(ORLOV)
	assert_not_null(orlov)
	assert_eq(orlov.player_id, "p1")
	assert_eq(orlov.level, 1)
	assert_eq(orlov.current_hp, orlov.data.hp)
	assert_eq(orlov.base_max_hp, orlov.data.hp)
	assert_eq(orlov.character_ap_remaining, 1)
	assert_false(orlov.is_placed())


func test_unknown_culture_is_rejected() -> void:
	setup.select_culture("p1", "Martian")
	assert_push_error("Martian")
	assert_null(setup.get_player("p1"))


func test_mirror_match_ids_do_not_collide() -> void:
	setup.select_culture("p1", RUSSIAN)
	setup.select_culture("p2", RUSSIAN)
	assert_not_null(setup.get_player("p1").find_character(ORLOV))
	assert_not_null(setup.get_player("p2").find_character("p2_r-mikhail-orlov"))
	assert_null(setup.get_player("p2").find_character(ORLOV))


func test_reselecting_culture_clears_earlier_placements() -> void:
	setup.select_culture("p1", RUSSIAN)
	setup.place_character("p1", ORLOV, Vector2i(3, 0))
	setup.select_culture("p1", ATLANTEAN)
	assert_false(setup.board.is_occupied_by_character(Vector2i(3, 0)))
	assert_eq(setup.get_player("p1").culture, ATLANTEAN)


# --- Placement ---------------------------------------------------------------

func test_c2_place_on_own_back_row() -> void:
	_select_both()
	assert_true(setup.place_character("p1", ORLOV, Vector2i(3, 0)))
	assert_true(setup.board.is_occupied_by_character(Vector2i(3, 0)))
	assert_eq(setup.get_player("p1").find_character(ORLOV).position, Vector2i(3, 0))


func test_c3_cannot_place_off_back_row() -> void:
	_select_both()
	assert_false(setup.place_character("p1", ORLOV, Vector2i(3, 3)))
	assert_eq(setup.get_placement_error("p1", ORLOV, Vector2i(3, 3)), "outside your back row")
	assert_false(setup.board.is_occupied_by_character(Vector2i(3, 3)))


func test_c3_cannot_place_on_opponents_back_row() -> void:
	_select_both()
	assert_false(setup.place_character("p1", ORLOV, Vector2i(3, 6)))


func test_c4_cannot_place_on_occupied_tile() -> void:
	_select_both()
	setup.place_character("p1", ORLOV, Vector2i(3, 0))
	assert_false(setup.place_character("p1", WORKER, Vector2i(3, 0)))
	assert_eq(setup.get_placement_error("p1", WORKER, Vector2i(3, 0)), "tile occupied")


func test_cannot_place_same_character_twice() -> void:
	_select_both()
	setup.place_character("p1", ORLOV, Vector2i(3, 0))
	assert_false(setup.place_character("p1", ORLOV, Vector2i(4, 0)))
	assert_eq(setup.get_placement_error("p1", ORLOV, Vector2i(4, 0)), "already placed")


func test_cannot_place_opponents_character() -> void:
	_select_both()
	assert_eq(setup.get_placement_error("p2", ORLOV, Vector2i(3, 6)), "not one of your characters")


func test_placement_errors_before_culture_and_off_board() -> void:
	assert_eq(setup.get_placement_error("p1", ORLOV, Vector2i(3, 0)), "choose a culture first")
	setup.select_culture("p1", RUSSIAN)
	assert_eq(setup.get_placement_error("p1", ORLOV, Vector2i(9, 0)), "off the board")


func test_c5_not_ready_with_6_of_7_placed() -> void:
	_select_both()
	var chars: Array[CharacterInstance] = setup.get_player("p1").characters
	for i in 6:
		setup.place_character("p1", chars[i].instance_id, Vector2i(i, 0))
	assert_false(setup.is_player_ready("p1"))


func test_c6_both_ready_when_all_placed() -> void:
	_select_both()
	_place_all("p1")
	_place_all("p2")
	assert_true(setup.is_player_ready("p1"))
	assert_true(setup.is_player_ready("p2"))


# --- Starting the match ------------------------------------------------------

func test_c7_start_match_hands_state_to_game_state() -> void:
	_select_both()
	_place_all("p1")
	_place_all("p2")
	setup.start_match()
	var state := GameState.match_state
	assert_not_null(state)
	assert_eq(state.phase, "in_progress")
	assert_eq(state.first_player_id, "p1")
	assert_eq(state.active_player_id, "p1")
	assert_eq(state.turn_number, 1)
	assert_eq(state.board, setup.board)
	var orlov := state.find_character(ORLOV)
	assert_eq(state.board.get_tile(orlov.position).occupant_id, ORLOV, "board and instance agree")
	assert_eq(state.board.get_tile(Vector2i(0, 6)).occupant_id, state.players[1].characters[0].instance_id)


func test_start_match_refuses_until_both_ready() -> void:
	_select_both()
	_place_all("p1")
	setup.start_match()
	assert_push_error("p2")
	assert_null(GameState.match_state)


# --- MatchState / CharacterInstance helpers ----------------------------------

func test_match_state_lookups() -> void:
	_select_both()
	var state := MatchState.new()
	state.players = [setup.get_player("p1"), setup.get_player("p2")]
	assert_eq(state.get_player("p2").culture, ATLANTEAN)
	assert_null(state.get_player("p3"))
	assert_eq(state.get_other_player_id("p1"), "p2")
	assert_eq(state.get_other_player_id("p2"), "p1")
	assert_eq(state.find_character("p2_a-flood-survivor-naia").data.char_name, "Naia of the Black Sarcophagus")
	assert_null(state.find_character("nobody"))


func test_mint_instance_id_is_unique_and_serial() -> void:
	var state := MatchState.new()
	var a := state.mint_instance_id("p1", "r-reactor-worker")
	var b := state.mint_instance_id("p1", "r-reactor-worker")
	assert_eq(a, "p1_r-reactor-worker#1")
	assert_eq(b, "p1_r-reactor-worker#2")


func test_effective_stats_include_bonuses_and_temp_effects() -> void:
	setup.select_culture("p1", RUSSIAN)
	var c: CharacterInstance = setup.get_player("p1").find_character(ORLOV)  # ATK 1, MOVE 2, RANGE 3
	c.atk_bonus = 1
	c.status_effects.append(StatusEffect.new("temp_atk", 2))
	c.status_effects.append(StatusEffect.new("temp_range", 1))
	assert_eq(c.get_effective_atk(), 4)
	assert_eq(c.get_effective_move(), 2)
	assert_eq(c.get_effective_range("attack"), 4)


func test_effective_move_floors_at_0_and_range_at_1() -> void:
	setup.select_culture("p1", RUSSIAN)
	var c: CharacterInstance = setup.get_player("p1").find_character(ORLOV)
	c.status_effects.append(StatusEffect.new("temp_move", -10))
	c.status_effects.append(StatusEffect.new("temp_range", -10))
	assert_eq(c.get_effective_move(), 0)
	assert_eq(c.get_effective_range("ability"), 1)
