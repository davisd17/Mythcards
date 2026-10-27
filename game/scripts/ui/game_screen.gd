extends Control
# The game screen (HLD build step 16, LLD-presentation.md): a local hotseat match that is
# played entirely by tapping. Portrait, mobile-first. From top to bottom: turn and AP,
# the face-up relic and event cards on the table, the board, the prompt bar (what to pick next, with option
# buttons), then a summary strip of the inspected character beside the action buttons
# (tap it for the full card). Drawn relic and event cards pop up full size; the popup
# scrolls, so no card is ever cut off (playtest 2026-10-06). All game logic lives in GameController and the engine.

const DEBUG_SCENE := "res://scenes/debug_match.tscn"
const DETAILS_RESERVE := 360.0   # stacked layouts keep this much height under the board
const DIALOG_WIDTH := 640.0      # menus, notices and dialog commands are at most this wide
const WARNING := Color("#ff9d6b")   # the capture warning's text
const TABLE_MIN := 88.0          # the face-up card row's height: a command's height, taller
const TABLE_MAX := 136.0         # only when the board can't use the room (it never shrinks)

var controller := GameController.new()

# Layout (docs/UI_STYLE_GUIDE.md section 7). Stacked (narrow, medium): header, commands,
# status chips, the board, then the prompt and the summary beside the actions. Side by side
# (wide, short): the board on the left, everything else in one scrolling column on the
# right. _arrange() moves the same nodes between the two, so a resize keeps every state.
var _mode := ""
var _page := MarginContainer.new()
var _root := VBoxContainer.new()
var _header := HBoxContainer.new()
var _commands := HBoxContainer.new()
var _body := BoxContainer.new()          # the board and the details
var _details := VBoxContainer.new()
var _detail_scroll := ScrollContainer.new()   # side by side: everything under the commands
var _detail_list := VBoxContainer.new()
var _prompt_box := VBoxContainer.new()
var _bottom := HBoxContainer.new()       # stacked: the summary beside the actions
var _side_scroll := ScrollContainer.new()
var _layout_queued := false
var px_override := 0.0   # tests: rendered pixels per unit, instead of the real window's

var _turn_label := Label.new()
var _deck_label := Label.new()
var _ap_meter := ApMeter.new()
var _turn_bar := ColorRect.new()     # the active player's color under the header (Phase 3)
var _popup_box := VBoxContainer.new()
var _popup_card_id := ""             # the relic/event card the popup shows, to dock on close
var _sfx := Sfx.new()                # Phase 4 sound and haptics
var _chips := HBoxContainer.new()    # the table: both relics and active events face up, then the Ember score
var _embers := Label.new()           # passive: "P1 Embers 0/4" over "P2 Embers 0/4"
var _table_h := TABLE_MIN
var _board := GameBoardView.new()
var _environment := BattlefieldBackdrop.new()
var _prompt := Label.new()
var _options := ActionGrid.new()     # a pending choice's answers, as two-line choice rows
var _summary := CardSummary.new()
var _primary: Button               # "Done placing" in setup, "End turn" in the match
var _side := ActionGrid.new()        # the selected character's actions, or the setup tray
var _popup := Control.new()
var _popup_card := CardView.new()
var _popup_scroll := ScrollContainer.new()
var _popup_button: Button
var _popup_note := Label.new()
var _popup_queue: Array[String] = []   # card ids waiting to be shown, oldest first
var _shown_reveal := ""                # the revealed card already shown for the current choice
var _menu := Control.new()          # a centered settings panel over a dim
var _menu_panel := PanelContainer.new()
var _menu_scroll := ScrollContainer.new()
var _chooser := Control.new()        # New match: vs AI as either team, or hotseat
var _notice_button := Button.new()  # a passing notice (e.g. the AI drew a card); fades on its own
var _notice_timer := Timer.new()
var _notice_card := ""
var _ai_timer := Timer.new()         # plays the AI's turn one visible step at a time
const AI_STEP_SECONDS := 0.6
var _log_view := ActionLogView.new()   # the action log (MatchLog), in the card panel's place
var _log_scroll := ScrollContainer.new()  # stacked: the log's own scroll; side by side it rides the column
var _log_shown := false
var _log_button: Button
var _seen_turn := -1                 # the last turn _refresh saw, to show the log after the AI's turn
var _seen_player := ""
var _seen_match: MatchState = null
var _game_over := Control.new()
var _game_over_label := Label.new()
var _capture_confirm := Control.new()   # "End turn and lose?" when your Hero can't move
var _terms := TermPopup.new()        # definitions: tapped card terms, long-pressed pieces, glossary
var _how_to := HowToPlay.new()       # the beginner walkthrough, from New match or Menu


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiStyle.theme()
	Settings.load_saved()
	add_child(_sfx)
	_environment.board = _board
	_environment.details = _details
	add_child(_environment)
	_board.resized.connect(_environment.queue_redraw)
	_details.resized.connect(_environment.queue_redraw)

	_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		_page.add_theme_constant_override("margin_" + side, UiStyle.PAGE_INSET)
	add_child(_page)
	_root.add_theme_constant_override("separation", UiStyle.GAP)
	_page.add_child(_root)

	_header.add_theme_constant_override("separation", UiStyle.GAP)
	_turn_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_turn_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_turn_label.add_theme_font_size_override("font_size", UiStyle.FONT_BODY)
	_turn_label.add_theme_color_override("font_color", UiStyle.HEADING)
	_header.add_child(_turn_label)
	# The deck count sits in the header (mobile feedback 2026-10-17: the HUD took three rows).
	_deck_label.add_theme_font_size_override("font_size", UiStyle.FONT_SECONDARY)
	_deck_label.add_theme_color_override("font_color", UiStyle.MUTED)
	_deck_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_header.add_child(_deck_label)
	_header.add_child(_ap_meter)
	# End turn takes the rest of the row; Log and Menu are square utility buttons.
	_commands.add_theme_constant_override("separation", UiStyle.GAP)
	_primary = UiStyle.primary(UiStyle.command("End turn", _on_primary, "command:primary"))
	_primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_commands.add_child(_primary)
	_log_button = UiStyle.icon_button("log", "Log", _toggle_log)
	_commands.add_child(_log_button)
	_commands.add_child(UiStyle.icon_button("menu", "Menu", _toggle_menu))
	_turn_bar.custom_minimum_size = Vector2(0, 3)
	_turn_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# One row, like cards set down beside a board (designer 2026-10-19): Player 1's relic,
	# any active events, Player 2's relic, all face up and tappable, then the Ember score.
	_chips.add_theme_constant_override("separation", UiStyle.GAP)
	_embers.add_theme_font_size_override("font_size", UiStyle.FONT_SECONDARY)
	_embers.add_theme_color_override("font_color", Color("#e0a35a"))
	_embers.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_embers.mouse_filter = Control.MOUSE_FILTER_STOP   # tap for what Embers are
	_embers.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_terms.show_terms(["spirit_ember"]))

	_board.controller = controller
	# Phase 6: an art attack's hit sounds wait for its impact frame, as its visuals do.
	_sfx.impact_for = func(id: String) -> float: return float(_board.attack_art_for(id).get("impact", 0.0))
	_board.tile_tapped.connect(_on_tile_tapped)
	_board.tile_long_pressed.connect(_explain_tile)

	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.add_theme_color_override("font_color", UiStyle.HEADING)
	_prompt_box.add_theme_constant_override("separation", UiStyle.GAP)
	_prompt_box.add_child(_prompt)
	_options.row_height = UiStyle.CHOICE_ROW_HEIGHT
	_options.lines = 2
	_prompt_box.add_child(_options)

	_body.add_theme_constant_override("separation", UiStyle.GAP)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details.add_theme_constant_override("separation", UiStyle.GAP)
	_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_list.add_theme_constant_override("separation", UiStyle.GAP)
	_detail_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_scroll.add_child(_detail_list)
	_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bottom.add_theme_constant_override("separation", UiStyle.GAP)
	_summary.custom_minimum_size.y = 220   # room for the strip's name, stats and status
	_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary.size_flags_stretch_ratio = 1.2
	_summary.pressed.connect(_show_character_card)
	_side_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side_scroll.add_child(_side)
	# Every node starts in the stacked layout; _layout() rearranges them for the window.
	_arrange(false)

	resized.connect(_queue_layout)
	_build_popup()
	_build_log()
	_build_menu()
	_build_notice()
	_build_chooser()
	_ai_timer.wait_time = AI_STEP_SECONDS
	_ai_timer.timeout.connect(_on_ai_tick)
	add_child(_ai_timer)
	_ai_timer.start()
	_build_game_over()
	_build_capture_confirm()
	add_child(_how_to)
	_how_to.term_pressed.connect(func(id): _terms.show_terms([id]))
	add_child(_terms)   # last, so a definition sits over every other overlay
	_popup_card.term_pressed.connect(func(id): _terms.show_terms([id]))
	_layout()

	EventBus.relic_drawn.connect(_on_card_drawn)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.match_ended.connect(func(_w, _c): _refresh())
	for s in ["action_resolved", "turn_started", "relic_slot_changed", "character_defeated"]:
		EventBus.connect(s, func(_a = null, _b = null, _c = null): _refresh.call_deferred())
	new_match()


func _exit_tree() -> void:
	MusicManager.stop()
	# The SetupFlow node lives outside the tree until the match starts.
	if controller.setup != null:
		controller.setup.free()
		controller.setup = null


# TestBridge's restart hook: both back rows in card order, then a fixed deck seed.
func start_new_match(deck_seed: int = -1) -> void:
	_start("")
	for i in 2:
		controller.auto_place()
		controller.confirm_placement(deck_seed)
	_refresh()


# Where things are on screen, for TestBridge's click-driven browser tests: visible buttons
# and every tile's center, in this viewport's coordinates.
func ui_snapshot() -> Dictionary:
	# Each button also reports its rect, its style-guide role, and whether its list has
	# scrolled it out of view ("clipped"), for the responsive tests.
	var buttons := []
	for b in find_children("*", "Button", true, false):
		if not b.is_visible_in_tree() or b.is_queued_for_deletion():
			continue
		var rect: Rect2 = b.get_global_rect()
		buttons.append({"text": b.text if b.text != "" else b.tooltip_text, "center": rect.get_center(),
				"disabled": b.disabled, "rect": rect, "role": str(b.get_meta("ui_role", "")), "clipped": not _on_screen(b)})
	var tiles := {}
	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			tiles["%d,%d" % [x, y]] = _board.get_global_transform() * _board.tile_rect(Vector2i(x, y)).get_center()
	var summary := _summary.get_global_rect().get_center() if _summary.is_visible_in_tree() else Vector2(-1, -1)
	var corner := _board.tile_rect(Vector2i(0, BoardModel.BOARD_SIZE - 1))
	var board := Rect2(_board.get_global_transform() * corner.position,
			corner.size * BoardModel.BOARD_SIZE)
	return {"buttons": buttons, "tiles": tiles, "summary": summary, "prompt": _prompt.text, "popup": _popup.visible,
			"setup": controller.in_setup(), "board": board, "mode": _mode}


# Whether a control's center is inside every scrolling list that holds it.
func _on_screen(c: Control) -> bool:
	var at := c.get_global_rect().get_center()
	var parent := c.get_parent()
	while parent != null and parent != self:
		if parent is ScrollContainer and not (parent as Control).get_global_rect().has_point(at):
			return false
		parent = parent.get_parent()
	return true


# Shows the New match chooser; a hotseat setup waits underneath until a choice is made.
func new_match() -> void:
	_start("")
	_chooser.visible = true


# ai_side: the player the AI controls ("p1" / "p2"), or "" for hotseat.
func _start(ai_side: String) -> void:
	_popup_queue.clear()
	_popup.visible = false
	_menu.visible = false
	_log_shown = false
	_chooser.visible = false
	controller.begin_setup("", "", ai_side)
	MusicManager.play_menu()
	_refresh()


# --- Layout (docs/UI_STYLE_GUIDE.md section 7) --------------------------------------------

# Resizes arrive in bursts; the layout is worked out once per frame.
func _queue_layout() -> void:
	if not _layout_queued:
		_layout_queued = true
		_layout.call_deferred()


func _layout() -> void:
	_layout_queued = false
	if not is_inside_tree():
		return
	var px := px_override if px_override > 0.0 else UiStyle.px_per_unit(get_viewport())
	var mode := UiStyle.mode_for(size * px)
	# Short (landscape phone) windows get one fixed UI scale so controls stay touchable. Only
	# when this screen owns the window: never inside the test runner.
	if get_tree().current_scene == self:
		var window := get_window()
		var factor := 1.0
		if mode == UiStyle.SHORT:
			var base := px / window.content_scale_factor
			factor = clampf(1.0 / (UiStyle.SHORT_UNITS_PER_PX * base), 1.0, 3.0)
		if not is_equal_approx(window.content_scale_factor, factor):
			window.content_scale_factor = factor
			return   # the resize this causes lays out again
	var side := mode == UiStyle.WIDE or mode == UiStyle.SHORT
	_environment.side_by_side = side
	_environment.queue_redraw()
	if mode != _mode:
		_mode = mode
		_arrange(side)
	var inner := size - Vector2.ONE * UiStyle.PAGE_INSET * 2.0
	if side:
		# The board gets a full-height square; the column takes what is left, between 480
		# units and one portrait page (720), and its action buttons stay within 360 rendered px.
		var column := clampf(inner.x - inner.y - UiStyle.GAP, 480.0, 720.0)
		_details.custom_minimum_size = Vector2(column, 0)
		_set_table_height(TABLE_MAX)   # the column scrolls
		_side.max_width = 360.0 / px if 360.0 / px < column else 0.0
		_board.custom_minimum_size = Vector2.ZERO
	else:
		# The board is square: as wide as the page, unless that leaves too little below it.
		_details.custom_minimum_size = Vector2.ZERO
		_side.max_width = 0.0
		var above := _header.get_combined_minimum_size().y + _commands.get_combined_minimum_size().y \
				+ (TABLE_MIN if _chips.visible else 0.0) + 3.0 + UiStyle.GAP * 5.0
		var board := minf(inner.x, inner.y - above - DETAILS_RESERVE)
		# The cards grow only into height the square board can't use, so it never shrinks.
		_set_table_height(clampf(TABLE_MIN + inner.y - above - DETAILS_RESERVE - inner.x, TABLE_MIN, TABLE_MAX))
		_board.custom_minimum_size = Vector2(0, maxf(board, 320.0))
		# The actions widen to fit their longest label (style guide 5, "Long Labels"), between
		# 40% and 60% of the page; the summary takes the rest and its card is a tap away.
		var longest := 0.0
		for b in _side.items():
			longest = maxf(longest, _side.label_width(b))
		_side_scroll.custom_minimum_size.x = clampf(longest + 4.0, inner.x * 0.4, inner.x * 0.6)
		_side_scroll.size_flags_horizontal = Control.SIZE_FILL
	var dialog := minf(DIALOG_WIDTH, size.x - UiStyle.PAGE_INSET * 2.0)
	_menu_panel.custom_minimum_size.x = dialog
	_menu_scroll.custom_minimum_size.y = minf(_menu_scroll.get_child(0).get_combined_minimum_size().y,
			size.y - UiStyle.PAGE_INSET * 4.0 - UiStyle.SECTION_GAP * 2.0)
	_notice_button.offset_left = -dialog / 2.0
	_notice_button.offset_right = dialog / 2.0
	for c in find_children("*", "Button", true, false):
		if c.has_meta("dialog_command"):
			(c as Control).custom_minimum_size.x = dialog


# Puts each node where the layout wants it. Stacked: everything in one column under the
# page header. Side by side: the board, then a column with the header, the commands and a
# scrolling list of the rest. Nodes are moved, never rebuilt.
func _arrange(side: bool) -> void:
	_body.vertical = not side
	if side:
		_put(_details, [_header, _commands, _turn_bar, _detail_scroll, _bottom])
		_put(_detail_list, [_chips, _prompt_box, _summary, _side, _log_view])
		_put(_root, [_body])
		_bottom.visible = false
		_detail_scroll.visible = true
		_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_details.size_flags_horizontal = Control.SIZE_FILL
		_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		_put(_root, [_header, _commands, _turn_bar, _chips, _body])
		_put(_bottom, [_summary, _side_scroll])
		_put(_side_scroll, [_side])
		_put(_log_scroll, [_log_view])
		_put(_details, [_prompt_box, _bottom, _log_scroll, _detail_scroll])
		_bottom.visible = true
		_detail_scroll.visible = false
		_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_board.size_flags_vertical = Control.SIZE_FILL
		_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_put(_body, [_board, _details])
	_apply_log()


func _set_table_height(h: float) -> void:
	_table_h = h
	for c in _chips.get_children():
		if c is TableCard:
			(c as Control).custom_minimum_size.y = h


func _put(parent: Node, children: Array) -> void:
	for i in children.size():
		var c: Node = children[i]
		if c.get_parent() != parent:
			if c.get_parent() != null:
				c.get_parent().remove_child(c)
			parent.add_child(c)
		parent.move_child(c, i)


# A short banner whenever the turn passes (Phase 3); it ignores input and fades on its own.
func _on_turn_started(player_id: String) -> void:
	var state := GameState.match_state
	if state == null or controller.setup != null:
		return
	var player := state.get_player(player_id)
	var team := str(ContentDB.get_team(player.team_id).get("name", player.culture)) if player != null else ""
	var text := "Turn %d · %s" % [state.turn_number, team]
	if controller.is_ai(player_id):
		text += " (AI)"
	elif not controller.ai_players.is_empty():
		text = "Your turn · " + text
	for old in find_children("TurnBanner", "", false, false):
		old.queue_free()
	var banner := HudFx.turn_banner(self, text, _bright(player_id))
	move_child(banner, _popup.get_index())   # under a drawn card's popup, over the board


func _on_ai_tick() -> void:
	if controller.is_ai_turn() and not _chooser.visible and not _how_to.visible:
		controller.ai_step()
		_refresh()


# --- Rendering -------------------------------------------------------------------------

func _refresh() -> void:
	controller.sync()
	_board.refresh_palettes()   # the Leaders may have changed (new match, mirror)
	_board.queue_redraw()
	_refresh_header()
	_refresh_prompt()
	_refresh_side()
	_refresh_card()
	_watch_turns()
	if _log_shown:
		_log_view.refresh()
	_apply_log()
	_queue_layout()   # the table row may have appeared or gone
	var state := GameState.match_state
	_game_over.visible = state != null and state.phase == "ended" and controller.setup == null
	if _game_over.visible:
		var how: String = {"hero_capture": "Hero capture", "army_defeat": "Army defeat",
				"ember_delivery": "delivering 4 Spirit Embers"}.get(state.win_condition, state.win_condition)
		_game_over_label.text = "%s wins by %s." % [_player_name(state.winner_id), how]


func _refresh_header() -> void:
	for child in _chips.get_children():
		if child != _embers:
			child.queue_free()
	_deck_label.text = ""
	_chips.visible = not controller.in_setup() and GameState.match_state != null
	if controller.in_setup():
		_turn_label.text = "Setup · %s" % _player_name(controller.placing_player)
		_turn_label.add_theme_color_override("font_color", _bright(controller.placing_player))
		_turn_bar.color = Color(_bright(controller.placing_player), 0.8)
		_ap_meter.set_ap(0, 0)
		_primary.text = "Done placing"
		_primary.disabled = not controller.placement_done()
		_primary.visible = true
		return
	_primary.text = "End turn"
	_primary.disabled = not controller.flow.is_empty() or controller.is_ai_turn()
	_primary.visible = GameState.is_match_active()
	var state := GameState.match_state
	if state == null:
		return
	# Short enough for one line beside the deck count and AP: the color says which player.
	_turn_label.text = "Turn %d · %s" % [state.turn_number, _team_name(state.active_player_id)]
	var player := state.get_player(state.active_player_id)
	_turn_label.add_theme_color_override("font_color", _bright(state.active_player_id))
	_turn_bar.color = Color(_bright(state.active_player_id), 0.8)
	_ap_meter.set_ap(player.pool_ap_remaining, player.pool_ap_max)
	_deck_label.text = "Deck %d" % state.shared_deck.size()
	# Each relic lies face up in its owner's color, Player 1's first and Player 2's last;
	# the events in effect lie between them.
	var cards: Array[TableCard] = []
	for p in state.players:
		var id := p.active_relic_id
		cards.append(TableCard.make(id, "Relic · %s" % _short_name(p.id), _board.faction_color(p.id),
				"%s: no relic" % _short_name(p.id), func():
					if id != "":
						_show_card(id, "%s's active relic." % _player_name(p.id))))
	for card_id in RelicEventDeck.active_event_ids():
		var card := ContentDB.get_relic_event(card_id)
		cards.insert(cards.size() - 1, TableCard.make(card_id, "Event · %s" % (card.duration if card != null else ""),
				UiStyle.BRASS, "", func(): _show_card(card_id, "This event is in effect.")))
	for i in cards.size():
		cards[i].custom_minimum_size.y = _table_h
		_chips.add_child(cards[i])
		_chips.move_child(cards[i], i)
	# The Ember score is a passive counter, not a button: tapping it still explains Embers.
	var lines := []
	for p in state.players:
		lines.append("%s Embers %d/%d" % [_short_name(p.id), p.embers_delivered, VictoryChecker.EMBERS_TO_WIN])
	_embers.text = "\n".join(lines)
	if _embers.get_parent() != _chips:
		_chips.add_child(_embers)
	_chips.move_child(_embers, -1)


func _refresh_prompt() -> void:
	for child in _options.get_children():
		child.queue_free()
	var step := controller.current_step()
	# A card revealed from the deck (Chintamani Fragment, Foresight) is shown in full,
	# once, before the top-or-bottom choice (playtest 2026-10-09).
	var revealed := str(step.get("revealed", ""))
	if revealed != "" and revealed != _shown_reveal:
		_shown_reveal = revealed
		_show_card.call_deferred(revealed, "Revealed: the next card in the shared deck. Choose below the board whether it stays on top.")
	elif revealed == "":
		_shown_reveal = ""
	if not step.is_empty():
		var prompt: String = step.get("prompt", "")
		if step.pick == "tile" or step.pick == "character":
			var count: int = step.get("tiles", step.get("characters", [])).size()
			prompt += "  Tap a highlighted %s." % ("tile" if step.pick == "tile" else "character") \
					if count > 0 else "  Nothing can be chosen."
		_prompt.text = prompt
		for i in step.get("options", []).size():
			var index: int = i
			_options.add_child(UiStyle.choice(step.options[i].label, func(): controller.press_option(index); _refresh(), "choice:option"))
		if step.get("optional", false):
			_options.add_child(UiStyle.choice("Skip", func(): controller.skip(); _refresh(), "choice:option"))
		if controller.can_cancel():
			_options.add_child(UiStyle.choice("Cancel", func(): controller.cancel(); _refresh(), "choice:option"))
		return
	var warning := _capture_warning()
	if warning != "" and not controller.is_ai_turn():
		_prompt.text = warning + ("\n" + controller.message if controller.message != "" else "")
		_prompt.add_theme_color_override("font_color", WARNING)
		return
	_prompt.add_theme_color_override("font_color", UiStyle.HEADING)
	if controller.is_ai_turn():
		_prompt.text = "%s is playing. %s" % [_player_name(GameState.match_state.active_player_id), controller.message]
	elif controller.message != "":
		_prompt.text = controller.message
	elif controller.in_setup():
		_prompt.text = "Pick a character on the right, then tap a highlighted tile on your back row. Tap a placed character to pick it up again."
	elif controller.selected_id != "":
		_prompt.text = "Dots: move there. Red rings: attack. Or use a button on the right."
	else:
		_prompt.text = "Tap one of your characters. Tap any character to read its card."


func _refresh_side() -> void:
	for child in _side.get_children():
		child.queue_free()
	# The setup tray is a choice list (two-line rows, for long names); a character's actions
	# are one-line commands.
	_side.row_height = UiStyle.CHOICE_ROW_HEIGHT if controller.in_setup() else UiStyle.CONTROL_HEIGHT
	_side.lines = 2 if controller.in_setup() else 1
	if controller.in_setup():
		if not controller.tray().is_empty():
			_side.add_child(UiStyle.choice("Auto-place the rest", func(): controller.auto_place(); _refresh(), "choice:action"))
		for c in controller.tray():
			var id := c.instance_id
			var b := UiStyle.choice(c.data.char_name, func(): controller.pick_from_tray(id); _refresh(), "choice:action")
			UiStyle.mark_selected(b, id == controller.placing_id)
			_side.add_child(b)
		return
	if GameState.match_state == null or not GameState.is_match_active():
		return
	for action in controller.actions():
		var kind: String = action.kind
		var id: String = action.id
		var b := UiStyle.command(action.label, func(): controller.start_action(kind, id); _refresh(), "command:action")
		b.disabled = not action.enabled
		_side.add_child(b)
	var selected := controller.find(controller.selected_id)
	if selected != null and FigureCatalog.outfits(selected.data.id).size() > 1:
		var label := "Outfit: %s" % _board.outfit_name(selected)
		_side.add_child(UiStyle.command(label, func(): _board.cycle_outfit(selected); _refresh(), "command:action"))
	var relic := controller.relic_power_label()
	if relic != "":
		_side.add_child(UiStyle.command(relic, func(): controller.use_relic(); _refresh(), "command:action"))


func _refresh_card() -> void:
	var id := controller.inspect_id
	if id == "":
		id = controller.selected_id
	var c := controller.find(id)
	_summary.visible = c != null
	if c != null:
		_summary.show_character(c.data, c)


# The inspected character's full card, in the scrollable popup.
func _show_character_card() -> void:
	var id := controller.inspect_id if controller.inspect_id != "" else controller.selected_id
	if controller.find(id) == null:
		return
	_popup_queue.push_front("char:%s|" % id)
	_next_popup()


# Long-press on the board: what everything on that tile means. A piece lists its type,
# level, Embers, mount and statuses; an object or the center tile explains itself.
func _explain_tile(pos: Vector2i) -> void:
	var ids := []
	var title := ""
	var c: CharacterInstance = null
	for each in controller.characters():
		if not each.defeated and each.is_placed() and each.position == pos \
				and (c == null or each.is_mounted_rider):
			c = each
	if c != null:
		title = c.data.char_name
		ids.append("type_" + c.data.type.to_lower())
		if c.level > 1:
			ids.append("level")
		if c.spirit_ember_count > 0:
			ids.append("spirit_ember")
		if c.mounted_with_id != "":
			ids.append("mounted")
		for se in c.status_effects:
			var id := Glossary.id_for("status", se.type)
			if id != "" and not ids.has(id):
				ids.append(id)
	var board := controller.board()
	var obj := board.get_placed_object(pos) if board != null else null
	if obj != null:
		ids.append(Glossary.id_for("object", obj.type_id))
	if board != null and board.get_tile(pos).is_center:
		ids.append("center")
	_terms.show_terms(ids, title)


# --- Drawn-card popup --------------------------------------------------------------------

func _build_popup() -> void:
	_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popup.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popup.add_child(dim)
	var box := _popup_box
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", UiStyle.GAP)
	var top_gap := Control.new()
	top_gap.custom_minimum_size = Vector2(0, UiStyle.SECTION_GAP)
	box.add_child(top_gap)
	_popup_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_popup_note.add_theme_color_override("font_color", UiStyle.HEADING)
	box.add_child(_margin(_popup_note, 40))
	# The card scrolls inside the overlay, so a long card never runs off the screen. It sits
	# centered, at a card's width, below the note rather than against the top edge
	# (playtest 2026-10-13); a column as tall as the scroll area does the centering.
	_popup_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_popup_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_popup_scroll.resized.connect(func(): column.custom_minimum_size.y = _popup_scroll.size.y)
	_popup_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_popup_card.custom_minimum_size.x = CardView.FULL_CARD_WIDTH
	column.add_child(_popup_card)
	_popup_scroll.add_child(column)
	box.add_child(_margin(_popup_scroll, UiStyle.PAGE_INSET))
	_popup_button = UiStyle.primary(UiStyle.command("Continue", _next_popup, "command:primary"))
	box.add_child(_dialog_command(_popup_button))
	var bottom_gap := Control.new()
	bottom_gap.custom_minimum_size = Vector2(0, UiStyle.SECTION_GAP)
	box.add_child(bottom_gap)
	_popup.add_child(box)
	add_child(_popup)


func _on_card_drawn(player_id: String, card_id: String) -> void:
	var card := ContentDB.get_relic_event(card_id)
	var kind := card.kind.to_lower() if card != null else "card"
	var article := "an" if kind.begins_with("e") else "a"
	if controller.is_ai(player_id):
		# The AI's draws don't stop play (playtest 2026-10-11): a notice you can tap to view,
		# and the card itself flies in over the board and docks into the HUD (Phase 3).
		_notice("%s drew %s. Tap to view." % [_player_name(player_id), card.card_name if card != null else card_id], card_id)
		_dock.call_deferred(card_id, _board.get_global_rect().get_center(), HudFx.FLY_HOLD)
		return
	_popup_queue.append("%s|%s drew %s %s." % [card_id, _player_name(player_id), article, kind])
	if not _popup.visible:
		_next_popup()


func _show_card(card_id: String, note: String) -> void:
	_popup_queue.push_front("%s|%s" % [card_id, note])
	_next_popup()


func _next_popup() -> void:
	# Closing a relic/event card sends a small copy of it into its HUD chip (Phase 3).
	if _popup.visible and _popup_card_id != "":
		_dock.call_deferred(_popup_card_id, _popup_scroll.get_global_rect().get_center(), 0.0)
	_popup_card_id = ""
	if _popup_queue.is_empty():
		_popup.visible = false
		_refresh()
		return
	var was_visible := _popup.visible
	var entry: String = _popup_queue.pop_front()
	var parts := entry.split("|", true, 1)
	var note := parts[1]
	_popup_scroll.scroll_vertical = 0
	if parts[0].begins_with("char:"):
		var c := controller.find(parts[0].trim_prefix("char:"))
		_popup_card.show_character(c.data, c)
		_popup_note.text = ""
		_popup_note.visible = false
		_popup_button.text = "Close"
		_popup.visible = true
		return
	_popup_card_id = parts[0]
	if not was_visible:
		HudFx.pop_in(_popup_box)
	_popup_card.show_relic_event(parts[0])
	_popup_note.visible = true
	_popup_button.text = "Continue"
	if RelicEventDeck.has_pending_choice(GameState.match_state.active_player_id) and _popup_queue.is_empty():
		note += " It needs a choice: answer it below the board."
	_popup_note.text = note
	_popup.visible = true


# Flies a card from `from` onto the table card that now holds it: the player's relic, an
# active event, or the deck count for a card that went back or already resolved.
func _dock(card_id: String, from: Vector2, hold: float) -> void:
	var card_name := _card_name(card_id)
	var target: Control = null
	for chip in _chips.get_children():
		if chip.is_queued_for_deletion() or not chip is Button:
			continue
		if chip.text.contains(card_name):
			target = chip
	# A card that went back or already resolved docks into the deck count.
	var to := target.get_global_rect() if target != null else Rect2(_deck_label.get_global_rect())
	HudFx.card_flyer(self, card_id, from - get_global_position(), Rect2(to.position - get_global_position(), to.size), hold)


# --- Menu and game over --------------------------------------------------------------------

func _build_menu() -> void:
	# A centered panel over a dim (style guide 7: dialogs fit the window and scroll).
	_menu.visible = false
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_toggle_menu())
	_menu.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu.add_child(center)
	center.add_child(_menu_panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", UiStyle.GAP)
	_menu_panel.add_child(outer)
	outer.add_child(UiStyle.heading("Menu"))
	_menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(_menu_scroll)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UiStyle.GAP)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_menu_scroll.add_child(box)
	box.add_child(UiStyle.command("New match", new_match))
	box.add_child(UiStyle.command("How to play", func(): _toggle_menu(); _how_to.open()))
	box.add_child(UiStyle.command("Glossary", func(): _toggle_menu(); _terms.show_glossary()))
	box.add_child(UiStyle.command("Debug view", func(): get_tree().change_scene_to_file(DEBUG_SCENE)))
	# Phase 4 presentation toggles, saved across restarts.
	box.add_child(_setting_toggle("Sound", "sound"))
	box.add_child(_setting_toggle("Music", "music"))
	box.add_child(_setting_toggle("Motion", "motion"))
	box.add_child(_setting_toggle("Vibration", "haptics"))
	outer.add_child(UiStyle.command("Close", _toggle_menu))
	add_child(_menu)


# A toggle showing "Sound: On" that flips the Settings field and saves it. The word and the
# pressed look both say the state, not color alone.
func _setting_toggle(label: String, field: String) -> Button:
	var b := UiStyle.command("", func(): pass, "command:toggle")
	b.toggle_mode = true
	var relabel := func():
		b.text = "%s: %s" % [label, "On" if Settings.value(field) else "Off"]
		b.set_pressed_no_signal(Settings.value(field))
	relabel.call()
	b.pressed.connect(func():
		Settings.toggle(field)
		relabel.call()
		_sfx.apply_settings()
		MusicManager.apply_settings()
		_board.queue_redraw())
	return b


func _on_primary() -> void:
	if controller.in_setup():
		controller.confirm_placement()
	elif controller.hero_trapped(GameState.match_state.active_player_id) and not controller.is_ai_turn():
		_capture_confirm.visible = true   # ending the turn now loses: ask first
		return
	else:
		controller.end_turn()
	_refresh()


# Warnings about the capture rule (designer 2026-10-19): your Hero can't move, so ending the
# turn now loses; or the other Hero can't move, so it loses if it's still stuck when its
# player ends their turn.
func _capture_warning() -> String:
	var state := GameState.match_state
	if state == null or controller.in_setup() or not GameState.is_match_active():
		return ""
	var lines := []
	if controller.hero_trapped(state.active_player_id):
		lines.append("Warning: your Hero can't move. Free it before you end the turn, or you lose by Hero capture.")
	if controller.hero_trapped(state.get_other_player_id(state.active_player_id)):
		lines.append("Their Hero can't move. If it's still stuck when they end their turn, you win.")
	return "\n".join(lines)


func _build_capture_confirm() -> void:
	_capture_confirm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_capture_confirm.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_capture_confirm.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel())
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", UiStyle.GAP)
	var label := Label.new()
	label.text = "Your Hero can't move. Ending the turn now loses the match by Hero capture."
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 480
	label.add_theme_color_override("font_color", WARNING)
	inner.add_child(label)
	var keep := UiStyle.primary(UiStyle.command("Keep playing", func(): _capture_confirm.visible = false, "command:primary"))
	keep.set_meta("dialog_command", true)
	inner.add_child(keep)
	var lose := UiStyle.command("End turn and lose", func():
		_capture_confirm.visible = false
		controller.end_turn()
		_refresh())
	lose.set_meta("dialog_command", true)
	inner.add_child(lose)
	panel.add_child(inner)
	center.add_child(panel)
	_capture_confirm.add_child(center)
	add_child(_capture_confirm)


# --- Action log ----------------------------------------------------------------------------

func _build_log() -> void:
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_log_view.color_for = _bright
	_log_view.card_pressed.connect(func(id): _show_card(id, "Played this match."))
	_log_view.character_pressed.connect(_show_log_character)


# The log and the card panel (the summary and the actions) share one place; the Log button
# switches between them. Side by side, the log takes the column under the table and prompt.
func _toggle_log() -> void:
	_set_log_shown(not _log_shown)


func _set_log_shown(shown: bool) -> void:
	_log_shown = shown
	if shown:
		_log_view.refresh()
	_apply_log()
	if shown:
		_scroll_log.call_deferred()


func _apply_log() -> void:
	var side := _log_view.get_parent() == _detail_list
	_bottom.visible = not side and not _log_shown
	_log_scroll.visible = not side and _log_shown
	_log_view.visible = _log_shown
	_side.visible = not (side and _log_shown)
	if side:
		var id := controller.inspect_id if controller.inspect_id != "" else controller.selected_id
		_summary.visible = not _log_shown and controller.find(id) != null
	if _log_button != null:
		var glyph := _log_button.get_child(0) as UiGlyph
		glyph.glyph = "card" if _log_shown else "log"
		glyph.queue_redraw()
		_log_button.tooltip_text = "Card" if _log_shown else "Log"


# Brings the last finished turn (what the opponent just did) to the top, or the newest
# action if there is none.
func _scroll_log() -> void:
	for i in 2:   # the rebuilt blocks are placed by the deferred container sort
		await get_tree().process_frame
	var scroll := _log_scroll if _log_scroll.visible else _detail_scroll
	var target := _log_view.focus_row()
	if target != null and target.is_inside_tree():
		var content := scroll.get_child(0) as Control
		scroll.scroll_vertical = int(target.global_position.y - content.global_position.y)
	else:
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


# Tapping the board means playing again: a character to command brings its card back.
func _on_tile_tapped(pos: Vector2i) -> void:
	controller.tap_tile(pos)
	if _log_shown and (controller.selected_id != "" or controller.inspect_id != ""):
		_log_shown = false
	_refresh()


# A symbol in the log: the panel switches back to that character's card.
func _show_log_character(instance_id: String) -> void:
	if controller.find(instance_id) == null:
		return
	controller.inspect_id = instance_id
	_log_shown = false
	_refresh()


# When the turn passes from the computer to a person, the log opens on what it just did.
func _watch_turns() -> void:
	var state := GameState.match_state
	if state != _seen_match:
		_seen_match = state
		_seen_turn = -1
		_seen_player = ""
	if state == null or controller.in_setup() or not GameState.is_match_active() or state.turn_number == _seen_turn:
		return
	var before := _seen_player
	_seen_turn = state.turn_number
	_seen_player = state.active_player_id
	if before != "" and controller.is_ai(before) and not controller.is_ai(_seen_player):
		_set_log_shown(true)   # already open: still brings the AI's turn into view


func _build_notice() -> void:
	_notice_button.visible = false
	# A two-line choice row at the normal button font (style guide 9: no 18-unit text).
	_notice_button.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_notice_button.offset_left = -DIALOG_WIDTH / 2.0
	_notice_button.offset_right = DIALOG_WIDTH / 2.0
	_notice_button.offset_top = 120
	_notice_button.custom_minimum_size = Vector2(0, UiStyle.CHOICE_ROW_HEIGHT)
	_notice_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice_button.clip_text = true
	_notice_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_notice_button.set_meta("ui_role", "choice:notice")
	_notice_button.pressed.connect(func():
		_notice_button.visible = false
		if _notice_card != "":
			_show_card(_notice_card, "Drawn by the AI."))
	add_child(_notice_button)
	_notice_timer.one_shot = true
	_notice_timer.wait_time = 4.0
	_notice_timer.timeout.connect(func(): _notice_button.visible = false)
	add_child(_notice_timer)


func _notice(text: String, card_id: String = "") -> void:
	_notice_button.text = text
	_notice_card = card_id
	_notice_button.visible = true
	_notice_timer.start()


func _build_chooser() -> void:
	_chooser.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.04, 0.97)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chooser.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", UiStyle.GAP)
	var title := UiStyle.heading("New match")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var teams := ContentDB.get_matchup()
	var p1_name := str(ContentDB.get_team(teams[0]).get("name", "Player 1"))
	var p2_name := str(ContentDB.get_team(teams[1]).get("name", "Player 2"))
	# Three equal choices, so none is the brass primary.
	box.add_child(_dialog_command(UiStyle.command("Play %s vs the AI" % p1_name, func(): _start("p2"))))
	box.add_child(_dialog_command(UiStyle.command("Play %s vs the AI" % p2_name, func(): _start("p1"))))
	box.add_child(_dialog_command(UiStyle.command("Hotseat: play both sides", func(): _start(""))))
	# New players start here; a gap sets it apart from the three ways to play.
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, UiStyle.SECTION_GAP)
	box.add_child(gap)
	box.add_child(_dialog_command(UiStyle.command("How to play", _how_to.open)))
	_chooser.add_child(box)
	add_child(_chooser)


func _toggle_menu() -> void:
	_menu.visible = not _menu.visible
	if _menu.visible:
		MusicManager.play_menu()
	else:
		MusicManager.close_menu()


func _build_game_over() -> void:
	_game_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_over.visible = false
	_game_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	var panel := PanelContainer.new()
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", UiStyle.GAP)
	_game_over_label.add_theme_font_size_override("font_size", UiStyle.FONT_HEADING)
	_game_over_label.add_theme_color_override("font_color", UiStyle.HEADING)
	_game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(_game_over_label)
	var again := UiStyle.primary(UiStyle.command("New match", new_match, "command:primary"))
	again.set_meta("dialog_command", true)
	inner.add_child(again)
	panel.add_child(inner)
	box.add_child(panel)
	_game_over.add_child(box)
	add_child(_game_over)


# --- Helpers ---------------------------------------------------------------------------------

# A dialog's command: centered, as wide as a dialog (_layout() keeps the width in step with
# the window), never the whole screen.
func _dialog_command(b: Button) -> CenterContainer:
	b.set_meta("dialog_command", true)
	b.custom_minimum_size.x = DIALOG_WIDTH
	var center := CenterContainer.new()
	center.add_child(b)
	return center


func _margin(child: Control, side: int = 10) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", side)
	m.add_theme_constant_override("margin_right", side)
	m.size_flags_vertical = child.size_flags_vertical
	m.size_flags_stretch_ratio = child.size_flags_stretch_ratio
	m.add_child(child)
	return m


# "Player 1 (Closed City)": the team name, or the culture for a culture-built squad.
func _player_name(player_id: String) -> String:
	var side := ""
	var player: PlayerState = null
	if controller.setup != null:
		player = controller.setup.get_player(player_id)
	elif GameState.match_state != null:
		player = GameState.match_state.get_player(player_id)
	if player != null:
		side = str(ContentDB.get_team(player.team_id).get("name", player.culture))
	var n := "Player 1" if player_id == "p1" else "Player 2"
	if controller.is_ai(player_id):
		side = side + ", AI" if side != "" else "AI"
	return "%s (%s)" % [n, side] if side != "" else n


# "Closed City", "Flood Survivors (AI)": the header's short form of _player_name.
func _team_name(player_id: String) -> String:
	var player := GameState.match_state.get_player(player_id) if GameState.match_state != null else null
	var team := str(ContentDB.get_team(player.team_id).get("name", player.culture)) if player != null else _short_name(player_id)
	return team + " (AI)" if controller.is_ai(player_id) else team


# The player's faction color, bright enough for text and banners on the dark page.
func _bright(player_id: String) -> Color:
	return _board.side_palette(player_id).primary.lightened(0.15) if player_id in ["p1", "p2"] else Color("#c9a45c")


static func _short_name(player_id: String) -> String:
	return "P1" if player_id == "p1" else "P2"


static func _card_name(card_id: String) -> String:
	var card := ContentDB.get_relic_event(card_id)
	return card.card_name if card != null else card_id
