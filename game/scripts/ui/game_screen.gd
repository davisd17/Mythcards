extends Control
# The game screen (HLD build step 16, LLD-presentation.md): a local hotseat match that is
# played entirely by tapping. Portrait, mobile-first. From top to bottom: turn and AP,
# relic and event chips, the board, the prompt bar (what to pick next, with option
# buttons), then a summary strip of the inspected character beside the action buttons
# (tap it for the full card). Drawn relic and event cards pop up full size; the popup
# scrolls, so no card is ever cut off (playtest 2026-10-06). All game logic lives in GameController and the engine.

const DEBUG_SCENE := "res://scenes/debug_match.tscn"
const BUTTON_FONT := 20
const BUTTON_HEIGHT := 56.0
const SIDE_BUTTON_WIDTH := 280.0

var controller := GameController.new()

var _turn_label := Label.new()
var _ap_label := Label.new()
var _chips := HFlowContainer.new()
var _board := GameBoardView.new()
var _prompt := Label.new()
var _options := HFlowContainer.new()
var _summary := CardSummary.new()
var _primary: Button               # "Done placing" in setup, "End turn" in the match
var _side := HFlowContainer.new()   # action buttons; two per row when the card is hidden
var _popup := Control.new()
var _popup_card := CardView.new()
var _popup_scroll := ScrollContainer.new()
var _popup_button: Button
var _popup_note := Label.new()
var _popup_queue: Array[String] = []   # card ids waiting to be shown, oldest first
var _shown_reveal := ""                # the revealed card already shown for the current choice
var _menu := PanelContainer.new()
var _chooser := Control.new()        # New match: vs AI as either team, or hotseat
var _ai_timer := Timer.new()         # plays the AI's turn one visible step at a time
const AI_STEP_SECONDS := 0.6
var _log := Control.new()            # the action log overlay (MatchLog)
var _log_text := RichTextLabel.new()
var _log_scroll := ScrollContainer.new()
var _game_over := Control.new()
var _game_over_label := Label.new()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = _build_ui_theme()
	var background := ColorRect.new()
	background.color = Color("#0b0f0e")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	var top := HBoxContainer.new()
	_turn_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_turn_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_turn_label.add_theme_font_size_override("font_size", 24)
	_turn_label.add_theme_color_override("font_color", Color("#f3e3b5"))
	top.add_child(_turn_label)
	_ap_label.add_theme_font_size_override("font_size", 24)
	_ap_label.add_theme_color_override("font_color", Color("#9fe0f5"))
	top.add_child(_ap_label)
	_primary = _button("End turn", _on_primary, false)
	_primary.custom_minimum_size.x = 170
	_accent(_primary)
	top.add_child(_primary)
	top.add_child(_button("Log", _toggle_log, false))
	top.add_child(_button("Menu", _toggle_menu, false))
	root.add_child(_margin(top))

	_chips.add_theme_constant_override("h_separation", 6)
	_chips.add_theme_constant_override("v_separation", 6)
	root.add_child(_margin(_chips))

	_board.controller = controller
	_board.custom_minimum_size = Vector2(0, 560)
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.size_flags_stretch_ratio = 2.2
	_board.tile_tapped.connect(func(pos): controller.tap_tile(pos); _refresh())
	root.add_child(_board)

	var prompt_box := VBoxContainer.new()
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.add_theme_font_size_override("font_size", 20)
	_prompt.add_theme_color_override("font_color", Color("#f3e3b5"))
	prompt_box.add_child(_prompt)
	_options.add_theme_constant_override("h_separation", 6)
	_options.add_theme_constant_override("v_separation", 6)
	prompt_box.add_child(_options)
	root.add_child(_margin(prompt_box))

	var bottom := HBoxContainer.new()
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom.add_theme_constant_override("separation", 8)
	_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary.size_flags_stretch_ratio = 1.4
	_summary.pressed.connect(_show_character_card)
	bottom.add_child(_summary)
	var side_scroll := ScrollContainer.new()
	side_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side.add_theme_constant_override("h_separation", 6)
	_side.add_theme_constant_override("v_separation", 6)
	side_scroll.add_child(_side)
	bottom.add_child(side_scroll)
	root.add_child(_margin(bottom))

	_build_popup()
	_build_log()
	_build_menu()
	_build_chooser()
	_ai_timer.wait_time = AI_STEP_SECONDS
	_ai_timer.timeout.connect(_on_ai_tick)
	add_child(_ai_timer)
	_ai_timer.start()
	_build_game_over()

	EventBus.relic_drawn.connect(_on_card_drawn)
	EventBus.match_ended.connect(func(_w, _c): _refresh())
	for s in ["action_resolved", "turn_started", "relic_slot_changed", "character_defeated"]:
		EventBus.connect(s, func(_a = null, _b = null, _c = null): _refresh.call_deferred())
	new_match()


func _exit_tree() -> void:
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
	var buttons := []
	for b in find_children("*", "Button", true, false):
		if b.is_visible_in_tree() and not b.is_queued_for_deletion():
			buttons.append({"text": b.text, "center": b.get_global_rect().get_center(), "disabled": b.disabled})
	var tiles := {}
	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			tiles["%d,%d" % [x, y]] = _board.get_global_transform() * _board.tile_rect(Vector2i(x, y)).get_center()
	var summary := _summary.get_global_rect().get_center() if _summary.is_visible_in_tree() else Vector2(-1, -1)
	return {"buttons": buttons, "tiles": tiles, "summary": summary, "prompt": _prompt.text, "popup": _popup.visible,
			"setup": controller.in_setup()}


# Shows the New match chooser; a hotseat setup waits underneath until a choice is made.
func new_match() -> void:
	_start("")
	_chooser.visible = true


# ai_side: the player the AI controls ("p1" / "p2"), or "" for hotseat.
func _start(ai_side: String) -> void:
	_popup_queue.clear()
	_popup.visible = false
	_menu.visible = false
	_log.visible = false
	_chooser.visible = false
	controller.begin_setup("", "", ai_side)
	_refresh()


func _on_ai_tick() -> void:
	if controller.is_ai_turn() and not _chooser.visible:
		controller.ai_step()
		_refresh()


# --- Rendering -------------------------------------------------------------------------

func _refresh() -> void:
	controller.sync()
	_board.queue_redraw()
	_refresh_header()
	_refresh_prompt()
	_refresh_side()
	_refresh_card()
	var state := GameState.match_state
	_game_over.visible = state != null and state.phase == "ended" and controller.setup == null
	if _game_over.visible:
		var how := "Hero capture" if state.win_condition == "hero_capture" else "Army defeat"
		_game_over_label.text = "%s wins by %s." % [_player_name(state.winner_id), how]


func _refresh_header() -> void:
	for child in _chips.get_children():
		child.queue_free()
	if controller.in_setup():
		_turn_label.text = "Setup · %s" % _player_name(controller.placing_player)
		_ap_label.text = ""
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
	_turn_label.text = "Turn %d · %s" % [state.turn_number, _player_name(state.active_player_id)]
	var player := state.get_player(state.active_player_id)
	_ap_label.text = "AP %d/%d" % [player.pool_ap_remaining, player.pool_ap_max]
	for p in state.players:
		var label := "%s relic: %s" % [_short_name(p.id), _card_name(p.active_relic_id) if p.active_relic_id != "" else "none"]
		var chip := _chip(label, PLAYER_COLORS[p.id])
		if p.active_relic_id != "":
			var id := p.active_relic_id
			chip.pressed.connect(func(): _show_card(id, "%s's active relic." % _player_name(p.id)))
		_chips.add_child(chip)
	for card_id in RelicEventDeck.active_event_ids():
		var chip := _chip("Event: " + _card_name(card_id), Color("#5b4a2e"))
		chip.pressed.connect(func(): _show_card(card_id, "This event is in effect."))
		_chips.add_child(chip)
	_chips.add_child(_chip("Deck: %d" % state.shared_deck.size(), Color("#333333")))


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
			_options.add_child(_button(step.options[i].label, func(): controller.press_option(index); _refresh()))
		if step.get("optional", false):
			_options.add_child(_button("Skip", func(): controller.skip(); _refresh()))
		if controller.can_cancel():
			_options.add_child(_button("Cancel", func(): controller.cancel(); _refresh()))
		return
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
	if controller.in_setup():
		if not controller.tray().is_empty():
			_side.add_child(_button("Auto-place the rest", func(): controller.auto_place(); _refresh()))
		for c in controller.tray():
			var id := c.instance_id
			var b := _button(c.data.char_name, func(): controller.pick_from_tray(id); _refresh())
			if id == controller.placing_id:
				b.modulate = Color("#ffe14d")
			_side.add_child(b)
		return
	if GameState.match_state == null or not GameState.is_match_active():
		return
	for action in controller.actions():
		var kind: String = action.kind
		var id: String = action.id
		var b := _button(action.label, func(): controller.start_action(kind, id); _refresh())
		b.disabled = not action.enabled
		_side.add_child(b)
	var selected := controller.find(controller.selected_id)
	if selected != null and FigureCatalog.outfits(selected.data.id).size() > 1:
		var label := "Outfit: %s" % _board.outfit_name(selected)
		_side.add_child(_button(label, func(): _board.cycle_outfit(selected); _refresh()))
	var relic := controller.relic_power_label()
	if relic != "":
		_side.add_child(_button(relic, func(): controller.use_relic(); _refresh()))


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


# --- Drawn-card popup --------------------------------------------------------------------

func _build_popup() -> void:
	_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popup.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popup.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 10)
	var top_gap := Control.new()
	top_gap.custom_minimum_size = Vector2(0, 30)
	box.add_child(top_gap)
	_popup_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_popup_note.add_theme_font_size_override("font_size", 22)
	_popup_note.add_theme_color_override("font_color", Color("#f3e3b5"))
	box.add_child(_margin(_popup_note, 40))
	# The card scrolls inside the overlay, so a long card never runs off the screen.
	_popup_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_popup_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_popup_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_popup_scroll.add_child(_popup_card)
	box.add_child(_margin(_popup_scroll, 50))
	_popup_button = _accent(_button("Continue", _next_popup))
	box.add_child(_margin(_popup_button, 50))
	var bottom_gap := Control.new()
	bottom_gap.custom_minimum_size = Vector2(0, 30)
	box.add_child(bottom_gap)
	_popup.add_child(box)
	add_child(_popup)


func _on_card_drawn(player_id: String, card_id: String) -> void:
	var card := ContentDB.get_relic_event(card_id)
	var kind := card.kind.to_lower() if card != null else "card"
	var article := "an" if kind.begins_with("e") else "a"
	_popup_queue.append("%s|%s drew %s %s." % [card_id, _player_name(player_id), article, kind])
	if not _popup.visible:
		_next_popup()


func _show_card(card_id: String, note: String) -> void:
	_popup_queue.push_front("%s|%s" % [card_id, note])
	_next_popup()


func _next_popup() -> void:
	if _popup_queue.is_empty():
		_popup.visible = false
		_refresh()
		return
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
	_popup_card.show_relic_event(parts[0])
	_popup_note.visible = true
	_popup_button.text = "Continue"
	if RelicEventDeck.has_pending_choice(GameState.match_state.active_player_id) and _popup_queue.is_empty():
		note += " It needs a choice: answer it below the board."
	_popup_note.text = note
	_popup.visible = true


# --- Menu and game over --------------------------------------------------------------------

func _build_menu() -> void:
	_menu.visible = false
	_menu.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_menu.offset_left = -270
	_menu.offset_right = -10
	_menu.offset_top = 60
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(240, 0)
	box.add_child(_button("New match", new_match))
	box.add_child(_button("Debug view", func(): get_tree().change_scene_to_file(DEBUG_SCENE)))
	box.add_child(_button("Close", _toggle_menu))
	_menu.add_child(box)
	add_child(_menu)


func _on_primary() -> void:
	if controller.in_setup():
		controller.confirm_placement()
	else:
		controller.end_turn()
	_refresh()


# --- Action log ----------------------------------------------------------------------------

func _build_log() -> void:
	_log.set_anchors_preset(Control.PRESET_FULL_RECT)
	_log.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.04, 0.96)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_log.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 8)
	var title := Label.new()
	title.text = "Action log"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("#f3e3b5"))
	box.add_child(_margin(title))
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_log_text.bbcode_enabled = true
	_log_text.fit_content = true
	_log_text.scroll_active = false
	_log_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_text.add_theme_font_size_override("normal_font_size", 17)
	_log_text.add_theme_font_size_override("bold_font_size", 19)
	_log_scroll.add_child(_log_text)
	box.add_child(_margin(_log_scroll))
	box.add_child(_margin(_accent(_button("Close", _toggle_log))))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	box.add_child(gap)
	_log.add_child(box)
	add_child(_log)


func _toggle_log() -> void:
	_log.visible = not _log.visible
	if _log.visible:
		_log_text.text = MatchLog.as_text(true) if not MatchLog.entries.is_empty() else "Nothing has happened yet."
		await get_tree().process_frame
		_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)   # newest at the bottom


func _build_chooser() -> void:
	_chooser.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.04, 0.97)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chooser.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	var title := Label.new()
	title.text = "New match"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#f3e3b5"))
	box.add_child(title)
	var teams := ContentDB.get_matchup()
	var p1_name := str(ContentDB.get_team(teams[0]).get("name", "Player 1"))
	var p2_name := str(ContentDB.get_team(teams[1]).get("name", "Player 2"))
	box.add_child(_margin(_accent(_button("Play %s vs the AI" % p1_name, func(): _start("p2"))), 60))
	box.add_child(_margin(_accent(_button("Play %s vs the AI" % p2_name, func(): _start("p1"))), 60))
	box.add_child(_margin(_button("Hotseat: play both sides", func(): _start("")), 60))
	_chooser.add_child(box)
	add_child(_chooser)


func _toggle_menu() -> void:
	_menu.visible = not _menu.visible


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
	_game_over_label.add_theme_font_size_override("font_size", 32)
	_game_over_label.add_theme_color_override("font_color", Color("#f3e3b5"))
	_game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(_game_over_label)
	inner.add_child(_button("New match", new_match))
	panel.add_child(inner)
	box.add_child(panel)
	_game_over.add_child(box)
	add_child(_game_over)


# --- Helpers ---------------------------------------------------------------------------------

const PLAYER_COLORS := {"p1": Color("#8c2f39"), "p2": Color("#1f6f8b")}


func _build_ui_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 18
	result.set_color("font_color", "Label", Color("#e9e5db"))
	result.set_color("font_color", "Button", Color("#e9e5db"))
	result.set_color("font_hover_color", "Button", Color.WHITE)
	result.set_color("font_pressed_color", "Button", Color("#f3e3b5"))
	result.set_color("font_disabled_color", "Button", Color("#777d79"))
	result.set_stylebox("normal", "Button", _button_style("#222928", "#4b5552"))
	result.set_stylebox("hover", "Button", _button_style("#303937", "#769080"))
	result.set_stylebox("pressed", "Button", _button_style("#151a19", "#c9a45c"))
	result.set_stylebox("focus", "Button", _button_style("#252d2b", "#c9a45c"))
	result.set_stylebox("disabled", "Button", _button_style("#171b1a", "#303634"))
	result.set_stylebox("panel", "PanelContainer", _panel_style())
	return result


func _button_style(fill: String, border: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(fill)
	style.border_color = Color(border)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	return style


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#171c1b")
	style.border_color = Color("#3e4744")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	return style


func _button(text: String, on_press: Callable, wide: bool = true) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	b.add_theme_font_size_override("font_size", BUTTON_FONT)
	if wide:
		b.custom_minimum_size.x = SIDE_BUTTON_WIDTH
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.pressed.connect(on_press)
	return b


# Gold, for the one button that moves the game on.
func _accent(b: Button) -> Button:
	var colors := {"normal": "#c9a45c", "hover": "#d6b36c", "pressed": "#a8883f", "focus": "#c9a45c", "disabled": "#4d4535"}
	for state in colors:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(colors[state])
		style.set_corner_radius_all(8)
		style.set_content_margin_all(8)
		b.add_theme_stylebox_override(state, style)
	b.add_theme_color_override("font_color", Color("#1a1916"))
	b.add_theme_color_override("font_hover_color", Color("#1a1916"))
	b.add_theme_color_override("font_pressed_color", Color("#1a1916"))
	return b


func _chip(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 16)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(12)
	style.set_content_margin_all(8)
	b.add_theme_stylebox_override("normal", style)
	return b


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


static func _short_name(player_id: String) -> String:
	return "P1" if player_id == "p1" else "P2"


static func _card_name(card_id: String) -> String:
	var card := ContentDB.get_relic_event(card_id)
	return card.card_name if card != null else card_id
