extends Node
# Uses real mount, move, attack and dismount requests in a controlled visual fixture.

const GameScreen := preload("res://scripts/ui/game_screen.gd")
var screen: Control
const OUTPUT := "res://../docs/art-specs/mounted/qa"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	screen = GameScreen.new()
	get_tree().root.add_child.call_deferred(screen)
	await get_tree().process_frame
	get_tree().current_scene = screen
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Settings.motion = false
	for key in MountedFigureCatalog.entries():
		get_window().size = Vector2i(1440, 960)
		screen.start_new_match(42)
		var state := GameState.match_state
		state.shared_deck.clear()
		screen._popup.visible = false
		screen._chooser.visible = false
		screen._popup_queue.clear()
		for banner in screen.find_children("TurnBanner", "", false, false):
			banner.queue_free()
		var entry: Dictionary = MountedFigureCatalog.entries()[key]
		var player := "p1" if str(entry.rider).begins_with("r-") else "p2"
		if player == "p2":
			TurnManager.start_turn("p2")
		state.get_player(player).pool_ap_remaining = 4
		for p in state.players:
			for c in p.characters:
				state.board.clear_occupant(c.position)
				c.position = CharacterInstance.UNPLACED
		var rider := state.find_character(player + "_" + entry.rider)
		var mount_char := state.find_character(player + "_" + entry.mount)
		var target := state.find_character("p2_a-flood-survivor-naia" if player == "p1" else "p1_r-yuri-volkov")
		_put(rider, Vector2i(2, 3))
		_put(mount_char, Vector2i(3, 3))
		_put(target, Vector2i(5, 4))
		screen.controller.selected_id = rider.instance_id
		screen.controller.inspect_id = rider.instance_id
		screen.controller.message = ""
		screen._refresh()
		_assert_action("mount", rider, {"mount_id": mount_char.instance_id})
		_assert_action("move", rider, {"to": Vector2i(3, 4)})
		screen._board.fx.advance(1.0)
		screen._board.set_process(false)
		await _capture(key + "-mounted-desktop")
		_assert_action("attack", rider, {"target_id": target.instance_id})
		assert(screen._board.fx.lunges[rider.instance_id].mounted_key == key)
		screen._board.fx.advance(0.35)
		await _capture(key + "-impact-desktop")
		screen._board.fx.advance(1.0)
		get_window().size = Vector2i(390, 844)
		await _capture(key + "-mounted-mobile")
		# A rider has spent its attack AP; refresh through the real turn manager before dismount.
		TurnManager.start_turn(player)
		_assert_action("dismount", rider, {"to": Vector2i(2, 4)})
		screen._board.fx.advance(1.0)
		assert(MountedFigureCatalog.key_for(rider) == "")
		await _capture(key + "-dismounted-mobile")
		print("Mounted visual review passed: ", key, " target HP=", target.current_hp)
		screen._board.set_process(true)
	screen.queue_free()
	GameState.reset()
	await get_tree().process_frame
	get_tree().quit()


func _put(c: CharacterInstance, pos: Vector2i) -> void:
	c.position = pos
	GameState.match_state.board.set_occupant(pos, c.instance_id)


func _assert_action(kind: String, c: CharacterInstance, payload: Dictionary) -> void:
	var result := RulesEngine.request_action(kind, c.instance_id, payload)
	assert(result.success, kind + ": " + str(result))


func _capture(label: String) -> void:
	for i in 6:
		await get_tree().process_frame
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen._layout()
	await get_tree().create_timer(0.3).timeout
	screen._layout()
	await get_tree().create_timer(0.3).timeout
	screen._board.queue_redraw()
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(OUTPUT.path_join(label + ".png")) == OK)
