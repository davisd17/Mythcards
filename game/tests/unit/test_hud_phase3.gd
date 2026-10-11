extends GutTest
# Visual Polish Phase 3 (LLD-hud-phase3.md): the turn banner, AP pips, and drawn cards
# that fly into the HUD. All of it ignores input and frees itself.

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


func _named(node_name: String) -> Array:
	return screen.find_children(node_name, "", false, false).filter(func(n): return not n.is_queued_for_deletion())


func test_a_turn_change_shows_one_banner_that_ignores_taps_and_goes_away() -> void:
	_deploy_both()
	var banners := _named("TurnBanner")
	assert_eq(banners.size(), 1)
	assert_eq(banners[0].mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_string_contains(banners[0].get_child(0).text, "Turn 1")
	assert_lt(banners[0].get_index(), screen._popup.get_index(), "a drawn card's popup stays on top")
	await wait_seconds(HudFx.BANNER_IN + HudFx.BANNER_HOLD + HudFx.BANNER_OUT + 0.2)
	assert_eq(_named("TurnBanner").size(), 0)


func test_vs_ai_the_banner_says_whose_turn() -> void:
	screen._start("p2")
	screen.controller.auto_place()
	screen.controller.confirm_placement(7)
	screen.controller.auto_place()
	screen.controller.confirm_placement(7)
	assert_string_contains(_named("TurnBanner").back().get_child(0).text, "Your turn")


func test_ap_shows_as_pips_for_the_active_player() -> void:
	_deploy_both()
	var meter: ApMeter = screen._ap_meter
	assert_true(meter.visible)
	var player := GameState.match_state.get_player(GameState.match_state.active_player_id)
	assert_eq([meter.remaining, meter.maximum], [player.pool_ap_remaining, player.pool_ap_max])


func test_setup_hides_the_ap_pips() -> void:
	assert_false(screen._ap_meter.visible)


func test_closing_a_drawn_card_flies_it_into_the_hud() -> void:
	_deploy_both()
	assert_true(screen._popup.visible)
	assert_ne(screen._popup_card_id, "")
	screen._popup_queue.clear()
	screen._next_popup()
	await wait_process_frames(2)
	var flyers := _named("CardFlyer")
	assert_eq(flyers.size(), 1)
	assert_eq(flyers[0].mouse_filter, Control.MOUSE_FILTER_IGNORE)
	await wait_seconds(HudFx.FLY_IN + HudFx.FLY_DOCK + 0.2)
	assert_eq(_named("CardFlyer").size(), 0, "freed once docked")


func test_an_ai_draw_flies_in_over_the_board_without_a_popup() -> void:
	screen._start("p2")
	var gc: GameController = screen.controller
	gc.auto_place()
	gc.confirm_placement(7)
	screen._popup_queue.clear()
	screen._next_popup()
	await wait_process_frames(2)
	for f in _named("CardFlyer"):
		f.free()
	TurnManager.relic_event_deck = null
	GameState.match_state.shared_deck = ["r-seventeen-seconds"] as Array[String]
	RelicEventDeck.draw_for("p2")
	await wait_process_frames(2)
	assert_false(screen._popup.visible)
	assert_eq(_named("CardFlyer").size(), 1)


func test_character_cards_do_not_fly_anywhere() -> void:
	_deploy_both()
	screen._popup_queue.clear()
	screen._next_popup()
	await wait_process_frames(2)
	for f in _named("CardFlyer"):
		f.free()
	screen.controller.tap_tile(GameState.match_state.find_character("p1_r-mikhail-orlov").position)
	screen._show_character_card()
	screen._next_popup()
	await wait_process_frames(2)
	assert_eq(_named("CardFlyer").size(), 0)
