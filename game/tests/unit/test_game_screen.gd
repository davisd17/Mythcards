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
	# Every character the playtest matchup fields has card art (the Reactor Worker had none
	# until playtest 2026-10-26: map it in data/cards/card_art.json).
	for team_id in ["closed-city", "flood-survivors"]:
		for data in ContentDB.get_team_characters(team_id):
			assert_not_null(CardView.art_for(data.id), "%s has no card art" % data.id)


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
	# Playtest 2026-10-26: upgrade text cut the strip off on a phone; a leveled character's
	# strip points to the full card instead.
	var zoya := GameState.match_state.find_character("p1_r-zoya-miranova")
	zoya.level = 2
	screen._refresh()
	assert_false(screen._summary.text().contains(zoya.data.l2), "upgrades stay on the full card")
	assert_string_contains(screen._summary.text(), "Level 2 upgrades")
	zoya.level = 1
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


func _find_in(node: Node, meta: String) -> Array[Node]:
	var out: Array[Node] = []
	for c in node.find_children("*", "", true, false):
		if c.has_meta(meta) and not c.is_queued_for_deletion():
			out.append(c)
	return out


func test_the_log_takes_the_card_panels_place() -> void:
	_deploy_both()
	screen._popup_queue.clear()
	screen._next_popup()
	screen.controller.end_turn()
	screen._refresh()
	assert_true(screen._bottom.visible, "the card panel shows first")
	screen._toggle_log()
	assert_true(screen._log_shown)
	assert_true(screen._log_view.is_visible_in_tree(), "the log is inline, not an overlay")
	assert_false(screen._bottom.visible, "it replaces the summary and actions")
	assert_true(screen._board.is_visible_in_tree(), "the board stays in view")
	assert_true(screen._details.is_ancestor_of(screen._log_view), "inside the details panel")
	assert_eq((screen._log_button.get_child(0) as UiGlyph).glyph, "card", "the button now switches back to the card")
	assert_gt(_find_in(screen._log_view, "log_turn").size(), 0, "one block per turn")
	await wait_process_frames(2)
	screen._toggle_log()
	assert_false(screen._log_shown)
	assert_true(screen._bottom.visible)
	assert_false(screen._log_scroll.visible)


func test_log_actions_use_type_symbols_and_link_cards() -> void:
	_deploy_both()
	screen._popup_queue.clear()
	screen._next_popup()
	var state := GameState.match_state
	var mover: CharacterInstance = null
	for c in state.get_player("p1").characters:
		if c.is_placed() and not c.defeated and RulesEngine.get_legal_move_tiles(c.instance_id).size() > 0:
			mover = c
			break
	if mover == null:
		pending("no legal move in this deployment")
		return
	var to: Vector2i = RulesEngine.get_legal_move_tiles(mover.instance_id)[0]
	RulesEngine.request_action("move", mover.instance_id, {"to": to})
	MatchLog.entries[-1].brief.append([{"t": "text", "s": "Draws"}, MatchLog._tok_card("r-reactor-prayer")])
	screen._toggle_log()
	var badges: Array = screen._log_view.find_children("*", "Control", true, false).filter(
			func(n): return n is ActionLogView.LogBadge and not n.is_queued_for_deletion())
	assert_gt(badges.size(), 0, "the mover is its type symbol")
	assert_eq(badges[0].type, mover.data.type)
	assert_eq(badges[0].tooltip_text, "Show %s" % mover.data.char_name)
	var links := _find_in(screen._log_view, "log_card").filter(func(n): return n.get_meta("log_card") == "r-reactor-prayer")
	assert_eq(links.size(), 1)
	(links[0] as Button).pressed.emit()
	await wait_process_frames(2)
	assert_true(screen._popup.visible, "the link opens the card")
	assert_eq(screen._popup_card._title.text, "Reactor Prayer")


func test_tapping_a_symbol_switches_the_panel_to_that_card() -> void:
	_deploy_both()
	screen._popup_queue.clear()
	screen._next_popup()
	var enemy: CharacterInstance = GameState.match_state.get_player("p2").characters[0]
	MatchLog._entry("Player 1 (Closed City) tests the log",
			[{"t": "text", "s": "sees"}, MatchLog._tok_char(enemy.instance_id)])
	screen._toggle_log()
	var badge: Control = _find_in(screen._log_view, "log_char").filter(
			func(n): return n.get_meta("log_char") == enemy.instance_id)[-1]
	var entry: Control = _find_in(screen._log_view, "log_entry").filter(
			func(n): return n.is_ancestor_of(badge))[0]
	assert_gte(badge.custom_minimum_size.y, ActionLogView.BADGE, "a comfortable tap target")
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = Vector2(8, 8)
		badge.gui_input.emit(e)
	assert_false(_find_in(entry, "log_full")[0].visible, "a symbol tap doesn't expand the action")
	assert_false(screen._log_shown, "the panel switches back to the card")
	assert_eq(screen.controller.inspect_id, enemy.instance_id)
	assert_true(screen._summary.visible)
	assert_true(screen._bottom.visible)
	assert_eq((screen._log_button.get_child(0) as UiGlyph).glyph, "log")


func test_tapping_an_action_shows_its_full_record() -> void:
	_deploy_both()
	screen._popup_queue.clear()
	screen._next_popup()
	MatchLog._entry("Player 1 (Closed City) tests the log", [{"t": "text", "s": "tests"}])
	screen._toggle_log()
	var entry: Control = _find_in(screen._log_view, "log_entry")[0]
	var full: Label = _find_in(entry, "log_full")[0]
	assert_false(full.visible)
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		entry.gui_input.emit(e)
	assert_true(full.visible)
	assert_string_contains(full.text, "Player 1 (Closed City) tests the log")


func test_the_log_opens_on_the_ais_turn_when_play_returns() -> void:
	screen._start("p2")
	_deploy_both()
	screen._popup_queue.clear()
	screen._next_popup()
	assert_false(screen._log_shown)
	screen.controller.end_turn()
	screen._refresh()   # the AI's turn
	while screen.controller.is_ai_turn():
		screen.controller.ai_step()
		screen._refresh()
	assert_true(screen._log_shown, "the person's turn opens on what the AI did")
	var focus: Control = screen._log_view.focus_row()
	assert_not_null(focus)
	assert_eq(focus.get_meta("log_turn"), GameState.match_state.turn_number - 1, "its last turn is highlighted")
	# Left open and scrolled back, the log still jumps to the AI's next turn.
	screen._detail_scroll.scroll_vertical = 0
	screen._log_scroll.scroll_vertical = 0
	screen.controller.end_turn()
	screen._refresh()
	while screen.controller.is_ai_turn():
		screen.controller.ai_step()
		screen._refresh()
	await wait_process_frames(3)
	focus = screen._log_view.focus_row()
	assert_eq(focus.get_meta("log_turn"), GameState.match_state.turn_number - 1)
	var view: Rect2 = screen._log_scroll.get_global_rect()
	assert_between(focus.global_position.y, view.position.y - 2.0, view.end.y, "scrolled to the AI's turn")


func test_the_log_works_side_by_side() -> void:
	screen.px_override = 0.5625
	screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
	screen.size = Vector2(2276, 1280)
	_deploy_both()
	screen._popup_queue.clear()
	screen._next_popup()
	screen._layout()
	assert_true(screen._detail_scroll.visible)
	screen._toggle_log()
	assert_eq(screen._log_view.get_parent(), screen._detail_list)
	assert_true(screen._log_view.is_visible_in_tree())
	assert_false(screen._side.visible)
	assert_false(screen._log_scroll.visible)
	screen._toggle_log()
	assert_true(screen._side.visible)


func test_new_match_offers_ai_hotseat_or_how_to_play() -> void:
	assert_true(screen._chooser.visible, "the game opens on the New match chooser")
	var labels := []
	for b in screen._chooser.find_children("*", "Button", true, false):
		labels.append(b.text)
	assert_eq(labels, ["Play Closed City vs the AI", "Play Flood Survivors vs the AI", "Hotseat: play both sides", "Play a friend online", "How to play"])


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
	assert_gt(screen._notice_button.offset_top, screen._commands.get_global_rect().end.y - screen.get_global_position().y,
			"below the command row, so it never covers End turn")
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
	# Playtest 2026-10-26: warn as soon as it's stuck, while there's AP to free it.
	assert_true(screen._capture_confirm.visible, "warns before the end of the turn")
	assert_false(screen._capture_lose.visible, "only the end-turn confirm offers to lose")
	screen._capture_confirm.visible = false
	screen._refresh()
	assert_false(screen._capture_confirm.visible, "once per turn, not on every refresh")
	screen._on_primary()
	assert_true(screen._capture_confirm.visible, "asks before losing")
	assert_eq(GameState.match_state.active_player_id, "p1", "the turn hasn't ended")
	for b in screen._capture_confirm.find_children("*", "Button", true, false):
		if b.text == "End turn and lose":
			b.pressed.emit()
	assert_eq(GameState.match_state.phase, "ended")
	assert_eq(GameState.match_state.win_condition, "hero_capture")


# BR-018A (designer 2026-10-27): the game flips for who goes first, and the board art and
# music follow that side's Leader.
func test_coin_flip_picks_the_starter_and_its_leader_sets_the_scene() -> void:
	const SetupFlowScript := preload("res://scripts/scenes/setup_flow.gd")
	_deploy_both()
	var state := GameState.match_state
	assert_eq(state.first_player_id, SetupFlowScript.coin_flip(42))
	assert_eq(state.active_player_id, state.first_player_id, "the winner takes the first turn")
	assert_eq(state.get_player(state.first_player_id).pool_ap_max, 2, "and pays the 2-AP first turn")
	var leader_area := ""
	for c in state.get_player(state.first_player_id).characters:
		if c.data.type == "Leader":
			leader_area = c.data.sub_area
	assert_eq(BattlefieldTheme.area_for(state), leader_area)
	assert_eq(MusicManager.current_sub_area, leader_area)
	assert_string_contains(screen.controller.message, "Coin flip:")


func test_an_ai_that_wins_the_coin_flip_plays_first_and_hands_back() -> void:
	const SetupFlowScript := preload("res://scripts/scenes/setup_flow.gd")
	var seed_value := 0
	while SetupFlowScript.coin_flip(seed_value) != "p2":
		seed_value += 1
	screen._start("p2")                             # you play Closed City; the AI wins the flip
	var gc: GameController = screen.controller
	gc.auto_place()
	gc.confirm_placement(seed_value)
	var state := GameState.match_state
	assert_eq(state.active_player_id, "p2")
	assert_true(gc.is_ai_turn())
	var ticks := 0
	while gc.is_ai_turn() and ticks < 40:
		screen._on_ai_tick()
		ticks += 1
	assert_eq(state.active_player_id, "p1", "the AI ended its first turn")
	assert_eq(state.turn_number, 2)
	assert_eq(state.get_player("p1").pool_ap_max, 4, "the second player gets a full pool")
