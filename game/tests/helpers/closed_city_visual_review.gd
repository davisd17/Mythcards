extends Node
# Native rendering proof using the real game screen, not a painted UI mockup.

const GameScreen := preload("res://scripts/ui/game_screen.gd")
var screen: Control
var output := "res://../docs/art-specs/board-themes/closed-city/qa"


func _ready() -> void:
	get_window().size = Vector2i(1440, 960)
	screen = GameScreen.new()
	get_tree().root.add_child.call_deferred(screen)
	await get_tree().process_frame
	get_tree().current_scene = screen
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.start_new_match(42)
	GameState.match_state.shared_deck.clear()
	screen._popup.visible = false
	screen._chooser.visible = false
	screen._popup_queue.clear()
	for banner in screen.find_children("TurnBanner", "", false, false):
		banner.queue_free()
	Settings.motion = false
	screen.controller.selected_id = "p1_r-mikhail-orlov"
	screen.controller.inspect_id = screen.controller.selected_id
	screen._refresh()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	await _capture("closed-city-desktop")
	get_window().size = Vector2i(390, 844)
	await _capture("closed-city-mobile")
	get_window().size = Vector2i(844, 390)
	await _capture("closed-city-landscape")
	screen.queue_free()
	GameState.reset()
	await get_tree().process_frame
	get_tree().quit()


func _capture(label: String) -> void:
	for i in 6:
		await get_tree().process_frame
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen._layout()
	await get_tree().create_timer(0.5).timeout
	screen._layout()
	await get_tree().create_timer(0.5).timeout
	screen._board.queue_redraw()
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	assert(image.save_png(output.path_join(label + ".png")) == OK)
	print("Closed City visual review: ", label, " size=", screen.size, " mode=", screen._mode)
