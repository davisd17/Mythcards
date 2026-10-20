extends GutTest
const Fixture := preload("res://tests/helpers/match_fixture.gd")
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
	assert_true((MusicManager.get_node("MenuAmbience") as AudioStreamPlayer).playing)
	await wait_process_frames(2)
	var labels := _buttons(screen._side).map(func(b): return b.text)
	assert_true(labels.has("Dr. Mikhail Orlov"), str(labels))
	assert_true(labels.has("Auto-place the rest"))


func test_chooser_to_team_setup_keeps_ambience_and_menu_controls_music() -> void:
	var menu := MusicManager.get_node("MenuAmbience") as AudioStreamPlayer
	var stream := menu.stream
	screen._start("p2")
	assert_true(menu.playing)
	assert_same(menu.stream, stream)
	_deploy_both()
	screen._toggle_menu()
	assert_true((MusicManager.get_node("MatchMusic") as AudioStreamPlayer).stream_paused)
	screen._toggle_menu()
	assert_false((MusicManager.get_node("MatchMusic") as AudioStreamPlayer).stream_paused)


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
	TurnManager.victory_checker = Fixture.NullChecker.new()   # exercise all 30 draws
	var gc: GameController = screen.controller
	var state := GameState.match_state
	var turns := 0
	while turns < 35 and state.phase == "in_progress":
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


func test_ai_draws_do_not_stop_play() -> void:
	# Playtest 2026-10-11: no Continue needed when the computer draws.
	screen._start("p2")
	var gc: GameController = screen.controller
	gc.auto_place()
	gc.confirm_placement(7)
	screen._popup_queue.clear()
	screen._next_popup()
	TurnManager.relic_event_deck = null
	GameState.match_state.shared_deck = ["r-seventeen-seconds"] as Array[String]
	RelicEventDeck.draw_for("p2")
	assert_false(screen._popup.visible, "no blocking popup for the AI's draw")
	assert_true(screen._notice_button.visible)
	assert_string_contains(screen._notice_button.text, "drew Seventeen Seconds")
	screen._notice_button.pressed.emit()
	assert_true(screen._popup.visible, "tapping the notice shows the card")


func test_ember_score_shows_in_the_top_bar() -> void:
	_deploy_both()
	GameState.match_state.get_player("p1").embers_delivered = 2
	screen._refresh()
	await wait_process_frames(1)
	# A passive counter beside the relic chips (UI style guide 7), one line per player.
	assert_true(screen._embers.is_visible_in_tree())
	assert_string_contains(screen._embers.text, "P1 Embers 2/4")
	assert_string_contains(screen._embers.text, "P2 Embers 0/4")


# Playtest 2026-10-13: a player picking a formation never sees the other one.
func test_player_2_does_not_see_player_1s_formation_while_deploying() -> void:
	var gc: GameController = screen.controller
	gc.auto_place()
	gc.confirm_placement(42)
	assert_eq(gc.placing_player, "p2")
	assert_true(gc.characters().all(func(c): return c.player_id == "p2"), "only Player 2's squad is drawn")
	var p1_piece: CharacterInstance = gc.setup.get_player("p1").characters[0]
	gc.tap_tile(p1_piece.position)
	assert_ne(gc.inspect_id, p1_piece.instance_id, "tapping a hidden piece reveals nothing")
	assert_null(gc.find(p1_piece.instance_id))
	gc.auto_place()
	gc.confirm_placement(42)
	assert_eq(gc.characters().size(), 14, "both formations appear once the match starts")


func test_player_1_never_sees_player_2_before_the_match() -> void:
	var gc: GameController = screen.controller
	assert_true(gc.characters().all(func(c): return c.player_id == "p1"))


func test_an_ai_that_deploys_first_stays_hidden() -> void:
	screen._start("p1")   # the AI is Player 1 and places its squad at once
	var gc: GameController = screen.controller
	assert_eq(gc.placing_player, "p2")
	assert_true(gc.setup.is_player_ready("p1"), "the AI has deployed")
	assert_true(gc.characters().all(func(c): return c.player_id == "p2"), "but its formation is hidden")


# Designer 2026-10-19: warn before a Hero capture, and confirm an End turn that loses.
func test_a_trapped_hero_warns_and_end_turn_asks_first() -> void:
	TurnManager.victory_checker = null   # the real capture check (an earlier suite may leave a stub)
	_deploy_both()
	screen._popup_queue.clear()
	screen._next_popup()
	var gc: GameController = screen.controller
	gc.flow = {}
	var orlov := GameState.match_state.find_character("p1_r-mikhail-orlov")
	var front := orlov.position + Vector2i(0, 1)
	for pos in [front, orlov.position + Vector2i(1, 0), orlov.position + Vector2i(-1, 0)]:
		if Fixture.board().is_in_bounds(pos) and not Fixture.board().is_occupied_by_character(pos):
			Fixture.board().place_object(pos, "stone", "p2")
	assert_true(gc.hero_trapped("p1"))
	screen._refresh()
	assert_string_contains(screen._prompt.text, "your Hero can't move")
	screen._on_primary()
	assert_true(screen._capture_confirm.visible, "asks before losing")
	assert_eq(GameState.match_state.active_player_id, "p1", "the turn hasn't ended")
	for b in screen._capture_confirm.find_children("*", "Button", true, false):
		if b.text == "End turn and lose":
			b.pressed.emit()
	assert_eq(GameState.match_state.phase, "ended")
	assert_eq(GameState.match_state.win_condition, "hero_capture")
