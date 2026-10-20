extends GutTest
# docs/UI_STYLE_GUIDE.md phase 1: shared control roles, equal-width action slots, and the
# narrow / wide / short layouts of the game screen.

const GameScreenScript := preload("res://scripts/ui/game_screen.gd")

var screen: Control


func before_each() -> void:
	GameState.reset()


func after_each() -> void:
	GameState.reset()


func _screen(size: Vector2, px: float) -> Control:
	screen = GameScreenScript.new()
	screen.px_override = px
	screen.size = size
	add_child_autofree(screen)
	for i in 2:
		screen.controller.auto_place()
		screen.controller.confirm_placement(42)
	screen._refresh()
	screen._layout()
	return screen


# The screen anchors itself to its parent; a test resize sets the size directly.
func _resize(v: Vector2) -> void:
	screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
	screen.size = v


func _grid(width: float, labels: Array) -> ActionGrid:
	var grid := ActionGrid.new()
	grid.theme = UiStyle.theme()
	add_child_autofree(grid)
	for text in labels:
		grid.add_child(UiStyle.command(text, func(): pass))
	grid.size = Vector2(width, 0)
	grid.notification(Container.NOTIFICATION_SORT_CHILDREN)
	return grid


func test_short_labels_share_two_equal_columns_and_a_lone_last_button_keeps_its_width() -> void:
	var grid := _grid(600, ["Move", "Attack", "Mount"])
	assert_eq(grid.columns(), 2)
	var widths := grid.items().map(func(b): return b.size.x)
	assert_almost_eq(widths[0], widths[2], 0.5, "the incomplete row does not stretch")
	assert_almost_eq(widths[0], (600.0 - UiStyle.GAP) / 2.0, 0.5)
	for b in grid.items():
		assert_eq(b.size.y, UiStyle.CONTROL_HEIGHT)


func test_a_label_too_long_for_half_the_width_reflows_to_one_column() -> void:
	var grid := _grid(600, ["Move", "Black-Water Communion of the Deep"])
	assert_eq(grid.columns(), 1)
	for b in grid.items():
		assert_almost_eq(b.size.x, 600.0, 0.5)
		assert_eq(b.size.y, UiStyle.CONTROL_HEIGHT, "a long label never makes a taller button")


func test_commands_are_one_line_and_every_state_keeps_the_same_padding() -> void:
	var b := UiStyle.command("End turn", func(): pass)
	autofree(b)
	assert_eq(b.autowrap_mode, TextServer.AUTOWRAP_OFF)
	assert_true(b.clip_text)
	var t := UiStyle.theme()
	var normal := t.get_stylebox("normal", "Button")
	for state in ["hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var other := t.get_stylebox(state, "Button")
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			assert_eq(other.get_content_margin(side), normal.get_content_margin(side), "%s side %d" % [state, side])


func test_narrow_screen_stacks_with_a_square_board_and_equal_command_heights() -> void:
	_screen(Vector2(720, 1600), 0.57)   # a 412x915 phone
	assert_eq(screen._mode, UiStyle.NARROW)
	assert_true(screen._body.vertical)
	assert_eq(screen._chips.get_parent(), screen._root)
	await wait_process_frames(2)
	var ui: Dictionary = screen.ui_snapshot()
	var board: Rect2 = ui.board
	assert_almost_eq(board.size.x, board.size.y, 1.0)
	assert_gt(board.size.x, 600.0, "the board takes the page width")
	var heights := {}
	for b in ui.buttons:
		var role := str(b.role).get_slice(":", 0)
		if role != "":
			heights[role] = heights.get(role, []) + [b.rect.size.y]
	for role in heights:
		assert_almost_eq(heights[role].min(), heights[role].max(), 1.0, "%s heights %s" % [role, heights[role]])
	assert_true(heights.has("command") and heights.has("icon"), str(heights.keys()))


func test_wide_screen_puts_the_board_beside_a_capped_column_and_keeps_the_selection() -> void:
	_screen(Vector2(720, 1600), 0.57)
	var yuri: CharacterInstance = screen.controller.find("p1_r-yuri-volkov")
	screen.controller.tap_tile(yuri.position)
	screen._refresh()
	# The same match, resized to a 1280x720 desktop window.
	screen.px_override = 0.5625
	_resize(Vector2(2276, 1280))
	screen._layout()
	assert_eq(screen._mode, UiStyle.WIDE)
	assert_false(screen._body.vertical)
	assert_eq(screen._header.get_parent(), screen._details)
	assert_eq(screen._side.get_parent(), screen._detail_list)
	assert_eq(screen.controller.selected_id, "p1_r-yuri-volkov", "resizing keeps the selection")
	await wait_process_frames(2)
	assert_lte(screen._details.size.x * 0.5625, 420.0, "the column stays near 360 rendered px")
	var ui: Dictionary = screen.ui_snapshot()
	assert_almost_eq((ui.board as Rect2).size.x, (ui.board as Rect2).size.y, 1.0)
	assert_true(ui.buttons.any(func(b): return b.text == "End turn"))
	# And back to the phone.
	screen.px_override = 0.57
	_resize(Vector2(720, 1600))
	screen._layout()
	assert_eq(screen._mode, UiStyle.NARROW)
	assert_eq(screen._side.get_parent(), screen._side_scroll)


func test_layout_modes_follow_the_rendered_size() -> void:
	assert_eq(UiStyle.mode_for(Vector2(360, 640)), UiStyle.NARROW)
	assert_eq(UiStyle.mode_for(Vector2(768, 1024)), UiStyle.MEDIUM)
	assert_eq(UiStyle.mode_for(Vector2(844, 390)), UiStyle.SHORT)
	assert_eq(UiStyle.mode_for(Vector2(1280, 720)), UiStyle.WIDE)
	assert_eq(UiStyle.mode_for(Vector2(1920, 1080)), UiStyle.WIDE)
	assert_eq(UiStyle.mode_for(Vector2(999, 720)), UiStyle.MEDIUM)
	assert_eq(UiStyle.mode_for(Vector2(1000, 720)), UiStyle.WIDE)


func test_menu_toggles_show_their_state_in_words_and_pressed_look() -> void:
	_screen(Vector2(720, 1600), 0.57)
	var music: Button = null
	for b in screen._menu.find_children("*", "Button", true, false):
		if b.text.begins_with("Music"):
			music = b
	assert_not_null(music)
	assert_true(music.toggle_mode)
	assert_eq(music.button_pressed, Settings.music)
	assert_eq(music.text, "Music: %s" % ("On" if Settings.music else "Off"))


# Designer 2026-10-19: relics and events lie face up beside the board, like a physical
# game, and the board is never made smaller for them.
func test_relics_and_events_lie_face_up_without_shrinking_the_board() -> void:
	_screen(Vector2(720, 1280), 0.57)
	await wait_process_frames(2)
	var before: Rect2 = screen.ui_snapshot().board
	GameState.match_state.get_player("p1").active_relic_id = "r-karpovas-black-key"
	RelicEventDeck._active["t1"] = {"card_id": "r-reactor-prayer", "player_id": "p1", "remaining": 1,
			"drawn_on_turn": GameState.match_state.turn_number, "data": {}}
	screen._refresh()
	screen._layout()
	await wait_process_frames(2)
	var cards: Array = screen._chips.get_children().filter(func(c): return c is TableCard and not c.is_queued_for_deletion())
	assert_eq(cards.map(func(c): return c.card_id), ["r-karpovas-black-key", "r-reactor-prayer", ""],
			"Player 1's relic, the event, then Player 2's empty slot")
	assert_true(cards[2].disabled, "an empty slot isn't a button")
	assert_almost_eq(screen.ui_snapshot().board.size.x, before.size.x, 0.5, "the board keeps its size")
	RelicEventDeck._active.erase("t1")
