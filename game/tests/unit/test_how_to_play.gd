extends GutTest
# The How to play walkthrough: reachable from New match and Menu, pages step with Back and
# Next, terms link to the glossary, and it fits a phone-sized window.

const GameScreenScript := preload("res://scripts/ui/game_screen.gd")

var screen: Control


func before_each() -> void:
	GameState.reset()
	screen = GameScreenScript.new()
	screen.size = Vector2(720, 1280)
	add_child_autofree(screen)


func after_each() -> void:
	GameState.reset()


func _button(root: Node, text: String) -> Button:
	for b in root.find_children("*", "Button", true, false):
		if b.text == text and b.is_visible_in_tree():
			return b
	return null


func test_new_match_screen_offers_how_to_play() -> void:
	screen.new_match()
	var b := _button(screen._chooser, "How to play")
	assert_not_null(b)
	b.pressed.emit()
	assert_true(screen._how_to.visible)
	assert_eq(screen._how_to.page, 0)
	screen._how_to.close()
	assert_true(screen._chooser.visible, "closing returns to the New match screen")


func test_menu_offers_how_to_play() -> void:
	screen._toggle_menu()
	var b := _button(screen._menu, "How to play")
	assert_not_null(b)
	b.pressed.emit()
	assert_false(screen._menu.visible)
	assert_true(screen._how_to.visible)


func test_back_and_next_step_through_every_page() -> void:
	var how: HowToPlay = screen._how_to
	how.open()
	assert_true(how._back.disabled, "nothing before the first page")
	for i in HowToPlay.PAGES.size() - 1:
		assert_eq(how._next.text, "Next")
		how._next.pressed.emit()
		assert_eq(how.page, i + 1)
		assert_ne(how._body.text, "")
	assert_eq(how._next.text, "Done")
	how._back.pressed.emit()
	assert_eq(how.page, HowToPlay.PAGES.size() - 2)
	how.show_page(HowToPlay.PAGES.size() - 1)
	how._next.pressed.emit()
	assert_false(how.visible, "Done closes the walkthrough")


func test_terms_link_to_their_definition() -> void:
	var how: HowToPlay = screen._how_to
	how.open()
	how.show_page(8)   # Spirit Embers
	assert_string_contains(how._body.text, "[url=spirit_ember]")
	how.term_pressed.emit("spirit_ember")
	assert_true(screen._terms.visible)


func test_every_page_has_text_and_a_known_diagram() -> void:
	var scenes := ["", "board", "squad", "setup", "ap", "move", "attack", "level", "cards", "embers", "capture"]
	for p in HowToPlay.PAGES:
		assert_has(scenes, p.scene, p.title)
		assert_false(p.body.is_empty(), p.title)


func test_fits_a_phone_and_keeps_the_footer_reachable() -> void:
	var how: HowToPlay = screen._how_to
	how.open()
	await wait_process_frames(3)
	var page := Rect2(Vector2.ZERO, screen.size)
	for b in [how._back, how._next]:
		var r: Rect2 = b.get_global_rect()
		assert_true(page.encloses(r), "%s on screen: %s" % [b.text, r])
		assert_almost_eq(r.size.y, UiStyle.CONTROL_HEIGHT, 1.0)
	assert_almost_eq(how._back.size.x, how._next.size.x, 1.0, "Back and Next are equal width")


func test_ai_waits_while_the_walkthrough_is_open() -> void:
	screen._start("p1")   # the AI plays Player 1, so it moves first
	for i in 2:
		screen.controller.auto_place()
		screen.controller.confirm_placement(42)
	screen._popup_queue.clear()
	screen._next_popup()
	screen._how_to.open()
	var before := MatchLog.entries.size()
	screen._on_ai_tick()
	assert_eq(MatchLog.entries.size(), before, "no AI step while reading")


func test_arrow_keys_page_even_with_a_footer_button_focused() -> void:
	var how: HowToPlay = screen._how_to
	how.open()
	await wait_process_frames(1)
	how._next.grab_focus()
	var right := InputEventAction.new()
	right.action = "ui_right"
	right.pressed = true
	Input.parse_input_event(right)
	await wait_process_frames(2)
	assert_eq(how.page, 1)
	var left := InputEventAction.new()
	left.action = "ui_left"
	left.pressed = true
	Input.parse_input_event(left)
	await wait_process_frames(2)
	assert_eq(how.page, 0)
