extends GutTest
# The game screen as a whole (LLD-presentation.md Section 8, adapted in its 9A): it builds,
# setup hands over to a match, drawn cards pop up, and a seeded match plays through the
# whole deck with every choice answered by the same taps and buttons a player uses.

const GameScreenScript := preload("res://scripts/ui/game_screen.gd")

var screen: Control


func before_each() -> void:
	GameState.reset()
	screen = GameScreenScript.new()
	screen.size = Vector2(720, 1280)
	add_child_autofree(screen)


func after_each() -> void:
	GameState.reset()


func _buttons(node: Node) -> Array[Button]:
	var result: Array[Button] = []
	for child in node.get_children():
		if child is Button and not child.is_queued_for_deletion():
			result.append(child)
	return result


func _deploy_both() -> void:
	for i in 2:
		screen.controller.auto_place()
		screen.controller.confirm_placement(42)
	screen._refresh()


func test_starts_in_setup_with_a_tray() -> void:
	assert_true(screen.controller.in_setup())
	await wait_process_frames(2)
	var labels := _buttons(screen._side).map(func(b): return b.text)
	assert_true(labels.has("Dr. Mikhail Orlov"), str(labels))
	assert_true(labels.has("Auto-place the rest"))


func test_deploying_starts_the_match_and_shows_the_drawn_card() -> void:
	_deploy_both()
	assert_true(GameState.is_match_active())
	assert_true(screen._popup.visible, "the first turn's card pops up")
	assert_string_contains(screen._popup_note.text, "Player 1")
	await wait_process_frames(2)
	screen._next_popup()
	assert_false(screen._popup.visible)


func test_character_art_loads_for_both_playable_cultures() -> void:
	assert_not_null(CardView.art_for("r-seer"), "run tools/sync_game_content.ps1 if this fails")
	assert_not_null(CardView.art_for("a-harmonic"), "run tools/sync_game_content.ps1 if this fails")


func test_a_seeded_match_plays_through_the_whole_deck_by_taps() -> void:
	_deploy_both()
	var gc: GameController = screen.controller
	var state := GameState.match_state
	var turns := 0
	while turns < 20 and state.phase == "in_progress":
		while not gc.flow.is_empty():
			var step := gc.current_step()
			match step.pick:
				"option":
					gc.press_option(0)
				"tile":
					gc.tap_tile(step.tiles[0])
				"character":
					gc.tap_tile(state.find_character(step.characters[0]).position)
			screen._refresh()
		screen._next_popup()
		gc.end_turn()
		screen._refresh()
		await wait_process_frames(1)
		turns += 1
	assert_eq(state.shared_deck.size(), 0, "every card drawn")
	assert_eq(gc.message, "", "no action failed")


func test_summary_strip_and_full_card_overlay() -> void:
	# Playtest 2026-10-06: the card under the board didn't show fully. The strip shows a
	# summary; tapping it opens the full card in a scrollable overlay.
	_deploy_both()
	screen._popup_queue.clear()
	screen._next_popup()
	var gc: GameController = screen.controller
	gc.tap_tile(GameState.match_state.find_character("p1_r-zoya-miranova").position)
	screen._refresh()
	assert_true(screen._summary.visible)
	assert_string_contains(screen._summary.text(), "Zoya Miranova  L1")
	assert_string_contains(screen._summary.text(), "Voice Under Static")
	assert_false(screen._summary.text().contains("Subject Three"), "upgrades not reached stay on the full card")
	screen._summary.pressed.emit()
	assert_true(screen._popup.visible)
	assert_eq(screen._popup_button.text, "Close")
	assert_string_contains(screen._popup_card._body.get_parsed_text(), "Subject Three")
	screen._next_popup()
	assert_false(screen._popup.visible)


func test_a_revealed_card_is_shown_in_full() -> void:
	# Playtest 2026-10-09: Chintamani Fragment named the next card; now the card pops up.
	_deploy_both()
	screen._popup_queue.clear()
	screen._next_popup()
	var state := GameState.match_state
	state.get_player("p1").active_relic_id = "r-chintamani-fragment"
	state.shared_deck = ["r-reactor-prayer", "r-seventeen-seconds"] as Array[String]
	var gc: GameController = screen.controller
	gc.flow = {}
	gc.use_relic()
	gc.press_option(0)                              # Reveal
	screen._refresh()
	await wait_process_frames(2)
	assert_true(screen._popup.visible)
	assert_eq(screen._popup_card._title.text, "Reactor Prayer")
	assert_string_contains(screen._popup_note.text, "Revealed")
	screen._next_popup()
	assert_eq(gc.current_step().options.size(), 2, "then the top-or-bottom choice")
	assert_false(screen._popup.visible, "shown once, not again on every refresh")


func test_log_overlay_shows_the_match_so_far() -> void:
	_deploy_both()
	screen._popup_queue.clear()
	screen._next_popup()
	screen.controller.end_turn()
	screen._toggle_log()
	assert_true(screen._log.visible)
	assert_string_contains(screen._log_text.get_parsed_text(), "Player 1 (Closed City) ends the turn")
	await wait_process_frames(2)
	screen._toggle_log()
	assert_false(screen._log.visible)


func test_new_match_offers_ai_or_hotseat() -> void:
	assert_true(screen._chooser.visible, "the game opens on the New match chooser")
	var labels := []
	for b in screen._chooser.find_children("*", "Button", true, false):
		labels.append(b.text)
	assert_eq(labels, ["Play Closed City vs the AI", "Play Flood Survivors vs the AI", "Hotseat: play both sides"])


func test_the_ai_plays_its_turn_and_hands_back() -> void:
	screen._start("p2")                             # you play Closed City
	var gc: GameController = screen.controller
	assert_eq(gc.placing_player, "p1")
	gc.auto_place()
	gc.confirm_placement(7)                         # the AI deployed Flood Survivors itself
	var state := GameState.match_state
	assert_true(GameState.is_match_active())
	while not gc.flow.is_empty():                   # answer a first-turn card, if any
		gc.press_option(0) if gc.current_step().pick == "option" else gc.skip()
		if not gc.flow.is_empty() and gc.current_step().pick == "tile":
			gc.tap_tile(gc.current_step().tiles[0])
	gc.end_turn()
	assert_eq(state.active_player_id, "p2")
	assert_true(gc.is_ai_turn())
	assert_string_contains(screen._player_name("p2"), "Flood Survivors, AI")
	gc.tap_tile(Vector2i(3, 6))
	assert_eq(gc.selected_id, "", "taps are ignored on the AI's turn")
	var ticks := 0
	while gc.is_ai_turn() and ticks < 40:
		screen._on_ai_tick()
		ticks += 1
	assert_eq(state.active_player_id, "p1", "the AI ended its turn")
	assert_true(MatchLog.entries.any(func(e): return e.player == "p2" and e.text.contains("ends the turn")))
