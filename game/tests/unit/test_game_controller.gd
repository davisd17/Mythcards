extends GutTest
# GameController: the game screen's tap logic (LLD-presentation.md Section 8, adapted in
# its 9A). Every action goes through RulesEngine; these tests check that taps, option
# buttons, and skips build the right payloads, one pick at a time.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const GYMNAST := Fixture.GYMNAST
const TIGER := Fixture.TIGER
const SNIPER := Fixture.SNIPER
const GENERAL := Fixture.GENERAL
const BOGATYR := Fixture.BOGATYR
const GUARD := Fixture.GUARD
const CONDUCTOR := Fixture.CONDUCTOR
const SEER := "p1_r-seer"
const ENGINEER := "p1_r-engineer"
const ARCHITECT := "p2_a-architect"
const CENTER := Vector2i(3, 3)

var gc: GameController


func before_each() -> void:
	autofree(Fixture.start_match())
	Fixture.state().shared_deck.clear()
	Fixture.clear_board()
	Fixture.state().get_player("p1").pool_ap_remaining = 4
	gc = GameController.new()


func after_each() -> void:
	gc = null
	Fixture.teardown()


func _c(id: String) -> CharacterInstance:
	return Fixture.character(id)


# --- Basic taps -------------------------------------------------------------------------

func test_c1_tap_selects_own_character_and_shows_its_moves() -> void:
	Fixture.put(GYMNAST, Vector2i(3, 3))
	gc.tap_tile(Vector2i(3, 3))
	assert_eq(gc.selected_id, GYMNAST)
	assert_eq(gc.inspect_id, GYMNAST)
	assert_true(gc.highlights().move.has(Vector2i(3, 5)))


func test_c2_tap_empty_with_nothing_selected_does_nothing() -> void:
	watch_signals(EventBus)
	gc.tap_tile(Vector2i(3, 3))
	assert_eq(gc.selected_id, "")
	assert_signal_not_emitted(EventBus, "action_requested")


func test_c3_tap_highlighted_tile_moves() -> void:
	Fixture.put(GYMNAST, Vector2i(3, 3))
	gc.tap_tile(Vector2i(3, 3))
	gc.tap_tile(Vector2i(3, 5))
	assert_eq(_c(GYMNAST).position, Vector2i(3, 5))


func test_c4_tap_off_highlight_does_not_act() -> void:
	Fixture.put(GYMNAST, Vector2i(3, 3))
	watch_signals(EventBus)
	gc.tap_tile(Vector2i(3, 3))
	gc.tap_tile(Vector2i(4, 4))   # diagonal: not a straight-line move
	assert_signal_not_emitted(EventBus, "action_requested")
	assert_eq(gc.selected_id, "")


func test_c5_tap_enemy_attacks_and_enemy_card_is_inspectable() -> void:
	Fixture.put(SNIPER, Vector2i(3, 1))
	Fixture.put(CONDUCTOR, Vector2i(3, 3))
	gc.tap_tile(Vector2i(3, 3))
	assert_eq(gc.inspect_id, CONDUCTOR, "tapping an enemy shows its card")
	assert_eq(gc.selected_id, "", "but never selects it")
	gc.tap_tile(Vector2i(3, 1))
	gc.tap_tile(Vector2i(3, 3))
	assert_eq(_c(CONDUCTOR).current_hp, 2)


func test_c6_failed_action_reports_the_reason() -> void:
	Fixture.put(GYMNAST, Vector2i(3, 3))
	Fixture.state().get_player("p1").pool_ap_remaining = 0
	gc.tap_tile(Vector2i(3, 3))
	gc.tap_tile(Vector2i(3, 4))
	assert_ne(gc.message, "")
	assert_eq(_c(GYMNAST).position, Vector2i(3, 3))


func test_c8_nothing_happens_after_the_match_ends() -> void:
	Fixture.put(GYMNAST, Vector2i(3, 3))
	Fixture.state().phase = "ended"
	gc.tap_tile(Vector2i(3, 3))
	assert_eq(gc.selected_id, "")


func test_end_turn_hands_over() -> void:
	gc.end_turn()
	assert_eq(Fixture.state().active_player_id, "p2")


# --- Ability flows --------------------------------------------------------------------------

func test_ability_buttons_list_usable_abilities() -> void:
	Fixture.put(SEER, Vector2i(3, 0))
	gc.tap_tile(Vector2i(3, 0))
	var actions := gc.actions()
	assert_eq(actions.size(), 1)
	assert_eq(actions[0].label, "Chill")
	assert_true(actions[0].enabled)
	Fixture.put(SNIPER, Vector2i(0, 0))
	gc.tap_tile(Vector2i(0, 0))
	assert_eq(gc.actions(), [] as Array[Dictionary], "Aim is passive: no button")


func test_chill_picks_an_enemy_then_fires() -> void:
	Fixture.put(SEER, Vector2i(3, 0))
	Fixture.put(CONDUCTOR, Vector2i(3, 3))
	gc.tap_tile(Vector2i(3, 0))
	gc.start_action("ability", "r-seer")
	assert_eq(gc.current_step().pick, "character")
	assert_eq(gc.highlights().pick_ids, [CONDUCTOR])
	gc.tap_tile(Vector2i(3, 3))
	assert_eq(_c(CONDUCTOR).current_hp, 3)
	assert_true(gc.flow.is_empty())


func test_command_at_level_2_offers_a_second_ally_that_can_be_skipped() -> void:
	Fixture.put(GENERAL, Vector2i(3, 0))
	var sniper := Fixture.put(SNIPER, Vector2i(3, 1))
	Fixture.put(GYMNAST, Vector2i(2, 0))
	_c(GENERAL).level = 2
	gc.tap_tile(Vector2i(3, 0))
	gc.start_action("ability", "r-general")
	gc.tap_tile(Vector2i(3, 1))
	assert_eq(gc.current_step().pick, "option")
	gc.press_option(0)                      # +1 ATK
	assert_eq(gc.current_step().key, "target_2")
	assert_true(gc.current_step().optional)
	assert_false(gc.current_step().characters.has(SNIPER), "not the same ally twice")
	gc.skip()
	assert_true(gc.flow.is_empty())
	assert_true(sniper.has_status("temp_atk"))


func test_command_move_then_free_move_bonus() -> void:
	Fixture.put(GENERAL, Vector2i(3, 0))
	var gymnast := Fixture.put(GYMNAST, Vector2i(2, 0))
	gc.tap_tile(Vector2i(3, 0))
	gc.start_action("ability", "r-general")
	gc.tap_tile(Vector2i(2, 0))
	gc.press_option(1)                      # move 1 tile free
	gc.tap_tile(Vector2i(2, 0))
	var bonus := gc.actions().filter(func(a): return a.kind == "bonus")
	assert_eq(bonus.size(), 1)
	assert_eq(bonus[0].label, "Free move (free)")
	gc.start_action("bonus", "free_move")
	gc.tap_tile(Vector2i(2, 1))
	assert_eq(gymnast.position, Vector2i(2, 1))


func test_barricade_picks_a_tile() -> void:
	Fixture.put(ENGINEER, Vector2i(3, 3))
	gc.tap_tile(Vector2i(3, 3))
	gc.start_action("ability", "r-engineer")
	assert_eq(gc.current_step().pick, "tile")
	gc.tap_tile(Vector2i(3, 4))
	assert_eq(Fixture.board().get_placed_object(Vector2i(3, 4)).type_id, "barricade")


func test_pounce_needs_no_target_and_fires_at_once() -> void:
	var tiger := Fixture.put(TIGER, Vector2i(3, 0))
	gc.tap_tile(Vector2i(3, 0))
	gc.start_action("ability", "r-tiger")
	assert_true(tiger.has_status("pounce_mark"))


func test_cancel_drops_an_ability_flow() -> void:
	Fixture.put(SEER, Vector2i(3, 0))
	gc.tap_tile(Vector2i(3, 0))
	gc.start_action("ability", "r-seer")
	assert_true(gc.can_cancel())
	gc.cancel()
	assert_true(gc.flow.is_empty())
	assert_eq(Fixture.state().get_player("p1").pool_ap_remaining, 4)


func test_mount_flow() -> void:
	var hero := Fixture.put(BOGATYR, Vector2i(3, 0))
	Fixture.put(TIGER, Vector2i(4, 0))
	gc.tap_tile(Vector2i(3, 0))
	assert_true(gc.actions().any(func(a): return a.kind == "mount"))
	gc.start_action("mount")
	gc.tap_tile(Vector2i(4, 0))
	assert_true(hero.is_mounted_rider)


func test_architect_can_move_an_existing_pylon() -> void:
	gc.end_turn()
	Fixture.state().get_player("p2").pool_ap_remaining = 4
	Fixture.put(ARCHITECT, Vector2i(3, 6))
	Fixture.board().place_object(Vector2i(3, 5), "pylon", "p2")
	gc.tap_tile(Vector2i(3, 6))
	gc.start_action("ability", "a-architect")
	assert_eq(gc.current_step().key, "mode")
	gc.press_option(1)
	gc.tap_tile(Vector2i(3, 5))
	gc.tap_tile(Vector2i(3, 4))
	assert_not_null(Fixture.board().get_placed_object(Vector2i(3, 4)))
	assert_null(Fixture.board().get_placed_object(Vector2i(3, 5)))


# --- Drawn cards and relic powers ---------------------------------------------------------------

func _draw(card_id: String, player_id: String = "p1") -> void:
	TurnManager.relic_event_deck = null
	Fixture.state().shared_deck.push_front(card_id)
	RelicEventDeck.draw_for(player_id)
	gc._start_pending_choice()


func test_drawn_card_choice_becomes_a_flow_that_cannot_be_cancelled() -> void:
	_draw("r-closed-city-incident")
	assert_eq(gc.flow.kind, "deck")
	assert_false(gc.can_cancel())
	assert_eq(gc.current_step().pick, "tile")
	gc.tap_tile(CENTER)
	assert_false(gc.current_step().tiles.has(CENTER), "each tile once")
	gc.tap_tile(Vector2i(3, 2))
	assert_true(gc.flow.is_empty())
	assert_true(Fixture.board().get_tile(CENTER).leak)
	assert_true(Fixture.board().get_tile(Vector2i(3, 2)).leak)


func test_relic_replace_choice_uses_option_buttons() -> void:
	Fixture.state().get_player("p1").active_relic_id = "r-reactor-core-fragment"
	_draw("r-karpovas-black-key")
	assert_eq(gc.current_step().options.size(), 2)
	gc.press_option(0)
	assert_eq(Fixture.state().get_player("p1").active_relic_id, "r-karpovas-black-key")


func test_character_choice_with_options() -> void:
	var sniper := Fixture.put(SNIPER, Vector2i(3, 1))
	_draw("r-reactor-prayer")
	gc.tap_tile(Vector2i(3, 1))
	assert_eq(gc.current_step().pick, "option")
	gc.press_option(0)
	assert_true(gc.flow.is_empty())
	assert_eq(sniper.current_hp, 2)


func test_character_tile_choice() -> void:
	gc.end_turn()
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	Fixture.board().place_object(Vector2i(3, 4), "stone", "p2")
	_draw("a-flood-survivor-black-water-remembers", "p2")
	gc.tap_tile(Vector2i(3, 3))
	gc.tap_tile(Vector2i(2, 3))
	assert_eq(guard.position, Vector2i(2, 3))
	assert_true(guard.has_status("memory"))


func test_relic_power_flows_into_its_follow_up_choice() -> void:
	TurnManager.relic_event_deck = null
	Fixture.state().get_player("p1").active_relic_id = "r-chintamani-fragment"
	Fixture.state().shared_deck = ["r-reactor-prayer", "r-seventeen-seconds"] as Array[String]
	assert_eq(gc.relic_power_label(), "Use Chintamani Fragment")
	gc.use_relic()
	assert_eq(gc.flow.kind, "power")
	gc.press_option(0)                          # Reveal
	assert_eq(gc.flow.kind, "deck")
	assert_string_contains(gc.current_step().prompt, "Reactor Prayer")
	gc.press_option(1)                          # bottom
	assert_eq(Fixture.state().shared_deck, ["r-seventeen-seconds", "r-reactor-prayer"] as Array[String])


# --- Setup -----------------------------------------------------------------------------------

func test_setup_places_both_rows_then_starts_the_match() -> void:
	Fixture.teardown()
	var setup: Node = gc.begin_setup()
	assert_true(gc.in_setup())
	assert_eq(gc.tray().size(), 7)
	gc.pick_from_tray("p1_r-hero")
	assert_eq(gc.placement_tiles().size(), 7)
	gc.tap_tile(Vector2i(3, 3))
	assert_ne(gc.message, "", "only the back row")
	gc.tap_tile(Vector2i(3, 0))
	assert_eq(setup.get_player("p1").find_character("p1_r-hero").position, Vector2i(3, 0))
	gc.tap_tile(Vector2i(3, 0))                 # pick it back up
	assert_eq(gc.placing_id, "p1_r-hero")
	gc.auto_place()
	assert_true(gc.placement_done())
	gc.confirm_placement()
	assert_eq(gc.placing_player, "p2")
	assert_eq(gc.placing_id, "p2_a-attendant", "the first tray character is ready to place")
	assert_eq(gc.placement_tiles().size(), 7)
	assert_eq(gc.placement_tiles()[0].y, 6)
	gc.auto_place()
	gc.confirm_placement(42)
	assert_false(gc.in_setup())
	assert_true(GameState.is_match_active())
	assert_eq(Fixture.state().active_player_id, "p1")
	if RelicEventDeck.has_pending_choice("p1"):
		assert_eq(gc.flow.kind, "deck", "a first-turn card choice is ready to answer")


func test_setup_cannot_confirm_an_incomplete_row() -> void:
	Fixture.teardown()
	autofree(gc.begin_setup())
	gc.confirm_placement()
	assert_eq(gc.placing_player, "p1")
	assert_eq(gc.message, "Place all 7 characters first.")


func test_an_attack_explains_reduced_damage() -> void:
	# Playtest 2026-09-28: a Sniper's 2 ATK taking 1 life looked like a bug. It was the
	# Resonance Guard's Quartz Armor; the screen now says so.
	Fixture.put(SNIPER, Vector2i(3, 0))
	Fixture.put(GUARD, Vector2i(3, 3))
	gc.tap_tile(Vector2i(3, 0))
	gc.tap_tile(Vector2i(3, 3))
	assert_eq(gc.message, "Sniper hit Resonance Guard for 1 (ATK 2, -1 Resonance Guard's armor).")
	Fixture.put(CONDUCTOR, Vector2i(0, 3))
	Fixture.put(GYMNAST, Vector2i(0, 2))
	gc.tap_tile(Vector2i(0, 2))
	gc.tap_tile(Vector2i(0, 3))
	assert_eq(gc.message, "Gymnast hit Divine Conductor for 1.", "nothing to explain")
