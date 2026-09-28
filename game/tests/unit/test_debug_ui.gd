extends GutTest
# DebugPanel, DebugController, and the debug match (LLD-debug-panel.md, adapted in 9A):
# the readout matches real state, the log follows signals, clicks and commands become
# the right actions, and a seeded match plays through the whole deck.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const DebugMatchScript := preload("res://scripts/ui/debug_match.gd")
const SNIPER := Fixture.SNIPER
const GYMNAST := Fixture.GYMNAST
const GUARD := Fixture.GUARD
const CONDUCTOR := Fixture.CONDUCTOR
const SEER := "p1_r-seer"

var controller: DebugController


func before_each() -> void:
	autofree(Fixture.start_match())
	Fixture.state().shared_deck.clear()
	Fixture.clear_board()
	Fixture.state().get_player("p1").pool_ap_remaining = 4
	controller = DebugController.new()


func after_each() -> void:
	Fixture.teardown()


func _c(id: String) -> CharacterInstance:
	return Fixture.character(id)


# --- Panel readout ------------------------------------------------------------------

func test_render_shows_turn_ap_and_characters() -> void:
	Fixture.put(SNIPER, Vector2i(3, 1))
	var text := DebugPanel.render(Fixture.state())
	assert_string_contains(text, "Turn 1 — p1 to act")
	assert_string_contains(text, "pool AP 4/2")
	assert_string_contains(text, "[SN] Sniper L1  (3,1)  HP 3/3")


func test_render_is_right_after_ability_damage() -> void:
	# The LLD's signal-only HP would miss this: Chill emits no attack_resolved.
	Fixture.put(SEER, Vector2i(3, 0))
	Fixture.put(CONDUCTOR, Vector2i(3, 3))
	RulesEngine.request_action("ability", SEER, {"ability_id": "r-seer", "target": CONDUCTOR})
	var text := DebugPanel.render(Fixture.state())
	assert_string_contains(text, "[DC] Divine Conductor L1  (3,3)  HP 3/4")
	assert_string_contains(text, "temp_move-1")


func test_render_shows_defeat_objects_frost_and_offers() -> void:
	_c(GUARD).defeated = true
	Fixture.board().place_object(Vector2i(2, 2), "barricade", "p1")
	Fixture.board().get_tile(Vector2i(4, 4)).terrain_type = "frost"
	var sniper := Fixture.put(SNIPER, Vector2i(3, 1))
	sniper.ability_uses_this_turn["free_move_available"] = true
	var text := DebugPanel.render(Fixture.state())
	assert_string_contains(text, "Resonance Guard L1 — defeated")
	assert_string_contains(text, "barricade (2,2) 2/2 (p1)")
	assert_string_contains(text, "Frost: (4,4)")
	assert_string_contains(text, "bonus: free_move")


func test_render_shows_pending_choice_and_selected_card_text() -> void:
	Fixture.state().get_player("p1").active_relic_id = "r-reactor-core-fragment"
	Fixture.state().shared_deck = ["r-karpovas-black-key"] as Array[String]
	RelicEventDeck.draw_for("p1")
	Fixture.put(SNIPER, Vector2i(3, 1))
	var text := DebugPanel.render(Fixture.state(), SNIPER)
	assert_string_contains(text, "Choose (Karpova's Black Key)")
	assert_string_contains(text, "L1: Passive: Aim")


func test_c6_render_match_over() -> void:
	Fixture.state().phase = "ended"
	Fixture.state().winner_id = "p2"
	Fixture.state().win_condition = "hero_capture"
	assert_string_contains(DebugPanel.render(Fixture.state()), "MATCH OVER — p2 wins by hero_capture")


func test_log_follows_signals() -> void:
	var panel: DebugPanel = autofree(DebugPanel.new())
	add_child(panel)
	Fixture.put(SNIPER, Vector2i(3, 1))
	Fixture.put(CONDUCTOR, Vector2i(3, 3))
	RulesEngine.request_action("attack", SNIPER, {"target_id": CONDUCTOR})
	RulesEngine.request_action("move", GYMNAST, {"to": Vector2i(0, 0)})
	var log := panel.log_lines()
	assert_true(log.any(func(l): return l.contains("p1_r-sniper hits p2_a-conductor for 2")), str(log))
	assert_true(log.any(func(l): return l.contains("✗ move p1_r-gymnast")), str(log))


func test_abbreviations_are_unique() -> void:
	var seen := {}
	for p in Fixture.state().players:
		for c in p.characters:
			var tag := DebugPanel.abbreviation(c.data)
			assert_false(seen.has(tag), tag)
			seen[tag] = true


# --- Clicks -------------------------------------------------------------------------

func test_click_selects_then_moves() -> void:
	Fixture.put(GYMNAST, Vector2i(3, 3))
	assert_eq(controller.click_tile(Vector2i(3, 3)), "Selected Gymnast.")
	assert_true(controller.move_tiles().has(Vector2i(3, 5)))
	assert_eq(controller.click_tile(Vector2i(3, 5)), "OK")
	assert_eq(_c(GYMNAST).position, Vector2i(3, 5))


func test_click_attacks_a_highlighted_enemy_and_object() -> void:
	Fixture.put(SNIPER, Vector2i(3, 1))
	Fixture.put(CONDUCTOR, Vector2i(3, 3))
	controller.click_tile(Vector2i(3, 1))
	assert_true(controller.attack_target_ids().has(CONDUCTOR))
	assert_string_contains(controller.click_tile(Vector2i(3, 3)), "OK")
	assert_eq(_c(CONDUCTOR).current_hp, 2)


func test_click_cannot_select_the_opponent_and_empty_click_deselects() -> void:
	Fixture.put(GUARD, Vector2i(3, 5))
	assert_eq(controller.click_tile(Vector2i(3, 5)), "")
	assert_eq(controller.selected_id, "")


# --- Commands -----------------------------------------------------------------------

func test_command_move_with_tag_and_coordinates() -> void:
	Fixture.put(GYMNAST, Vector2i(3, 3))
	assert_eq(controller.run_command("move GY 3,4"), "OK")
	assert_eq(_c(GYMNAST).position, Vector2i(3, 4))


func test_command_ability_with_json_and_tag_targets() -> void:
	Fixture.put(SEER, Vector2i(3, 0))
	Fixture.put(CONDUCTOR, Vector2i(3, 3))
	assert_string_contains(controller.run_command("ability FS {\"target\": \"DC\"}"), "OK")
	assert_eq(_c(CONDUCTOR).current_hp, 3)


func test_command_ability_with_positions() -> void:
	Fixture.put("p1_r-engineer", Vector2i(3, 3))
	assert_eq(controller.run_command("ability WE {\"target\": [3, 4]}"), "OK")
	assert_eq(Fixture.board().get_placed_object(Vector2i(3, 4)).type_id, "barricade")


func test_command_attack_object_and_bonus() -> void:
	Fixture.put(SNIPER, Vector2i(3, 1))
	Fixture.board().place_object(Vector2i(3, 3), "barricade", "p2")
	assert_string_contains(controller.run_command("attack SN 3,3"), "\"destroyed\":true")
	var gymnast := Fixture.put(GYMNAST, Vector2i(0, 3))
	gymnast.ability_uses_this_turn["free_move_available"] = true
	assert_eq(controller.run_command("bonus GY free_move {\"to\": [0, 4]}"), "OK")


func test_command_choose_and_end() -> void:
	Fixture.state().get_player("p1").active_relic_id = "r-reactor-core-fragment"
	Fixture.state().shared_deck = ["r-karpovas-black-key"] as Array[String]
	RelicEventDeck.draw_for("p1")
	assert_eq(controller.run_command("end"), "✗ resolve the drawn card first")
	assert_eq(controller.run_command("choose {\"keep_new\": true}"), "OK")
	assert_eq(controller.run_command("end"), "OK")
	assert_eq(Fixture.state().active_player_id, "p2")


func test_command_errors_are_readable() -> void:
	assert_eq(controller.run_command("move ZZ 3,4"), "Unknown character 'ZZ'.")
	assert_eq(controller.run_command("move GY"), "move needs x,y")
	assert_string_contains(controller.run_command("help"), "Commands:")
	assert_string_contains(controller.run_command("choose nope"), "choose needs a JSON object")


func test_resolve_character_prefers_the_active_players_piece() -> void:
	assert_eq(DebugController.resolve_character("hero", "p2"), "p2_a-hero")
	assert_eq(DebugController.resolve_character("BC", ""), "p1_r-hero")
	assert_eq(DebugController.resolve_character("hero", ""), "", "ambiguous without a preference")


# --- The debug match scene ------------------------------------------------------------

func test_debug_match_scene_plays_through_the_whole_deck() -> void:
	# Seeded hotseat match: each turn resolve any drawn-card choice, then end the turn.
	Fixture.teardown()
	var scene: Control = autofree(DebugMatchScript.new())
	add_child(scene)
	scene.start_new_match(42)
	var state := GameState.match_state
	assert_eq(state.deck_seed, 42)
	var turns := 0
	while turns < 20 and state.phase == "in_progress":
		if RelicEventDeck.has_pending_choice(state.active_player_id):
			var spec := RelicEventDeck.choice_spec(state.active_player_id)
			var result := RulesEngine.request_action("deck_choice", state.active_player_id, _first_choice(spec))
			assert_true(result.success, "%s %s" % [spec, result])
		assert_eq(scene.controller.run_command("end"), "OK", "turn %d" % state.turn_number)
		turns += 1
	assert_eq(state.shared_deck.size(), 0, "every card drawn")
	assert_eq(state.phase, "in_progress")


# The first legal answer a choice_spec offers, as a deck_choice payload.
func _first_choice(spec: Dictionary) -> Dictionary:
	var choice: Dictionary = {}
	if not spec.get("options", []).is_empty():
		choice.merge(spec.options[0].payload)
	match spec.pick:
		"tiles":
			choice["tiles"] = spec.tiles.slice(0, spec.count)
		"character":
			choice["target_id"] = spec.characters[0]
		"character_tile":
			var id: String = spec.characters[0]
			choice["target_id"] = id
			choice["to"] = spec.tiles_by_character[id][0]
	return choice
