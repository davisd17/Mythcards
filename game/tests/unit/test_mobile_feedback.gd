extends GutTest
# Mobile feedback 2026-10-17: game terms are defined on tap/long-press, the board zooms
# and pans, and a tap only counts on release (so a drag or long press never also taps).

const GameScreenScript := preload("res://scripts/ui/game_screen.gd")

var screen: Control


func before_each() -> void:
	GameState.reset()
	screen = GameScreenScript.new()
	screen.size = Vector2(720, 1280)
	add_child_autofree(screen)


func after_each() -> void:
	GameState.reset()


func _deploy_both() -> void:
	for i in 2:
		screen.controller.auto_place()
		screen.controller.confirm_placement(42)
	screen._refresh()
	screen._popup_queue.clear()
	screen._next_popup()


func _click(board: GameBoardView, at: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = at
	board._gui_input(e)


func test_glossary_links_each_term_once_per_card() -> void:
	var used := {}
	var a := Glossary.link("Places a Leak marker. Leak damage hurts.", used)
	assert_string_contains(a, "[url=leak]")
	assert_eq(a.count("[url="), 1, "the second mention of the same term isn't linked")
	var b := Glossary.link("Then mark that enemy.", used)
	assert_string_contains(b, "[url=marked]")
	assert_eq(Glossary.link("A Leak again.", used).count("[url="), 0, "already linked on this card")


func test_glossary_prefers_the_longest_alias_and_whole_words() -> void:
	assert_string_contains(Glossary.link("a 1-damage shield"), "[url=shield][color=%s]1-damage shield" % Glossary.LINK_COLOR)
	assert_eq(Glossary.link("Leaking pipes").count("[url="), 0, "no match inside a longer word")


func test_every_status_the_board_can_show_has_a_definition() -> void:
	for status in GameBoardView.STATUS:
		assert_ne(Glossary.id_for("status", status), "", "no glossary term for status '%s'" % status)
	for type in GameBoardView.ROLE_COLORS:
		assert_false(Glossary.find("type_" + type.to_lower()).is_empty(), "no glossary term for %s" % type)


func test_full_card_terms_open_their_definition() -> void:
	_deploy_both()
	var orlov := GameState.match_state.find_character("p1_r-mikhail-orlov")
	screen.controller.inspect_id = orlov.instance_id
	screen._show_character_card()
	assert_string_contains(screen._popup_card._body.text, "[url=leak]")
	screen._popup_card.term_pressed.emit("leak")
	assert_true(screen._terms.visible)
	assert_eq(screen._terms._title.text, "Leak marker")


func test_long_press_explains_a_piece() -> void:
	_deploy_both()
	var zoya := GameState.match_state.find_character("p1_r-zoya-miranova")
	zoya.spirit_ember_count = 2
	RulesEngine.systems().ability.add_status(zoya, "marked", 1, "until_used")
	screen._explain_tile(zoya.position)
	assert_true(screen._terms.visible)
	assert_eq(screen._terms._title.text, "Zoya Miranova")
	await wait_process_frames(1)
	var text := ""
	for row in screen._terms._list.get_children():
		if not row.is_queued_for_deletion():
			text += (row.get_child(row.get_child_count() - 1) as RichTextLabel).get_parsed_text() + "\n"
	assert_string_contains(text, "Mystic")
	assert_string_contains(text, "Spirit Ember")
	assert_string_contains(text, "Marked")


func test_a_tap_fires_on_release_and_a_drag_does_not_tap() -> void:
	_deploy_both()
	var board: GameBoardView = screen._board
	board.size = Vector2(700, 700)
	var tapped := []
	board.tile_tapped.connect(func(pos): tapped.append(pos))
	var center := board.tile_rect(Vector2i(3, 3)).get_center()
	_click(board, center, true)
	assert_eq(tapped.size(), 0, "nothing on press")
	_click(board, center, false)
	assert_eq(tapped, [Vector2i(3, 3)])
	_click(board, center, true)
	var drag := InputEventMouseMotion.new()
	drag.position = center + Vector2(60, 0)
	drag.relative = Vector2(60, 0)
	board._gui_input(drag)
	_click(board, center + Vector2(60, 0), false)
	assert_eq(tapped.size(), 1, "a drag isn't a tap")


func test_zoom_keeps_the_focus_point_and_tiles_follow() -> void:
	_deploy_both()
	var board: GameBoardView = screen._board
	board.size = Vector2(700, 700)
	var pos := Vector2i(5, 5)
	var before := board.tile_rect(pos).get_center()
	board.set_zoom(2.0, before)
	assert_almost_eq(board.zoom, 2.0, 0.001)
	assert_almost_eq(board.tile_rect(pos).get_center().distance_to(before), 0.0, 0.5, "the pinched point stays put")
	assert_eq(board.tile_at(before), pos, "hit testing follows the zoom")
	board.set_zoom(9.0, before)
	assert_almost_eq(board.zoom, GameBoardView.MAX_ZOOM, 0.001)
	board.set_zoom(1.0, Vector2(350, 350))
	assert_eq(board._pan, Vector2.ZERO, "unzoomed, the board is centered again")


func test_the_reset_chip_unzooms() -> void:
	_deploy_both()
	var board: GameBoardView = screen._board
	board.size = Vector2(700, 700)
	board.set_zoom(2.0, Vector2(350, 350))
	var chip := board.reset_zoom_rect().get_center()
	_click(board, chip, true)
	_click(board, chip, false)
	assert_almost_eq(board.zoom, 1.0, 0.001)


# Designer 2026-10-19: a definition shows the icon the board uses for that term.
func test_definitions_show_the_terms_board_icon() -> void:
	for id in ["marked", "shield", "leak", "spirit_ember", "type_hero"]:
		screen._terms.show_terms([id])
		var row: Node = screen._terms._list.get_child(screen._terms._list.get_child_count() - 1)
		var icon: StatusIcon = row.get_child(0) as StatusIcon
		assert_not_null(icon, "%s has an icon" % id)
		if icon != null:
			assert_eq(icon.term.id, id)
	screen._terms.show_terms(["center"])
	var plain: Node = screen._terms._list.get_child(screen._terms._list.get_child_count() - 1)
	assert_false(plain.get_child(0) is StatusIcon, "a term with nothing on the board has no icon")
