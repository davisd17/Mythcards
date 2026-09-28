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
	assert_true(labels.has("Bogatyr Champion"), str(labels))
	assert_true(labels.has("Auto-place the rest"))


func test_deploying_starts_the_match_and_shows_the_drawn_card() -> void:
	_deploy_both()
	assert_true(GameState.is_match_active())
	assert_true(screen._popup.visible, "the first turn's card pops up")
	assert_string_contains(screen._popup_note.text, "Player 1")
	await wait_process_frames(2)
	screen._next_popup()
	assert_false(screen._popup.visible)


func test_card_art_loads_when_mapped_and_falls_back_otherwise() -> void:
	assert_not_null(CardView.art_for("r-seer"), "run tools/sync_game_content.ps1 if this fails")
	assert_null(CardView.art_for("a-harmonic"))


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
