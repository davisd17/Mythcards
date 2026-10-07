extends Control
# The playable debug match (HLD build step 14): a local hotseat match of the playtest
# matchup (teams.json) on a clickable board, with the DebugPanel readout and a command line for
# abilities, free actions, and card choices. Debug-grade by design; the mobile UI is
# the presentation step (HLD 4.12).

const SetupFlowScript := preload("res://scripts/scenes/setup_flow.gd")

var controller := DebugController.new()
var _setup: Node = null
var _status := Label.new()
var _board := DebugBoardView.new()
var _panel := DebugPanel.new()
var _message := Label.new()
var _command := LineEdit.new()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 4)
	add_child(root)

	var bar := HBoxContainer.new()
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.add_theme_font_size_override("font_size", 20)
	bar.add_child(_status)
	for spec in [["End turn", _on_end_turn], ["New match", start_new_match], ["Panel", _toggle_panel],
			["Game view", _open_game_view]]:
		var button := Button.new()
		button.text = spec[0]
		button.custom_minimum_size = Vector2(0, 44)
		button.pressed.connect(spec[1])
		bar.add_child(button)
	root.add_child(bar)

	_board.controller = controller
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.size_flags_stretch_ratio = 1.4
	_board.tile_clicked.connect(_on_tile_clicked)
	root.add_child(_board)

	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_theme_font_size_override("normal_font_size", 14)
	_panel.add_theme_font_size_override("bold_font_size", 14)
	root.add_child(_panel)

	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_font_size_override("font_size", 16)
	root.add_child(_message)

	_command.placeholder_text = "Command (type help) — e.g. ability FS {\"target\": \"RG\"}"
	_command.custom_minimum_size = Vector2(0, 44)
	_command.text_submitted.connect(_on_command)
	root.add_child(_command)

	for s in ["action_resolved", "turn_started", "match_ended", "relic_slot_changed"]:
		EventBus.connect(s, func(_a = null, _b = null, _c = null): _refresh())
	start_new_match()


func _open_game_view() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


# Starts a fresh match: the playtest matchup (teams.json), each back row in card order, p1 first.
func start_new_match(deck_seed: int = -1) -> void:
	if _setup != null:
		_setup.queue_free()
	GameState.reset()
	controller.selected_id = ""
	_setup = SetupFlowScript.new()
	add_child(_setup)
	_setup.select_team("p1", ContentDB.get_matchup()[0])
	_setup.select_team("p2", ContentDB.get_matchup()[1])
	for id in ["p1", "p2"]:
		var x := 0
		for c in _setup.get_player(id).characters:
			_setup.place_character(id, c.instance_id, Vector2i(x, 0 if id == "p1" else 6))
			x += 1
	_setup.start_match(deck_seed)
	_message.text = "New match. Tap one of your characters, then a highlighted tile. Type help for commands."
	_refresh()


func _on_tile_clicked(pos: Vector2i) -> void:
	var message := controller.click_tile(pos)
	if message != "":
		_message.text = message
	_refresh()


func _on_command(text: String) -> void:
	_message.text = controller.run_command(text)
	_command.clear()
	_refresh()


func _on_end_turn() -> void:
	_message.text = controller.run_command("end")
	controller.selected_id = ""
	_refresh()


func _toggle_panel() -> void:
	_panel.visible = not _panel.visible


func _refresh() -> void:
	var state := GameState.match_state
	if state == null:
		return
	if state.phase == "ended":
		_status.text = "%s wins (%s)" % [state.winner_id, state.win_condition.replace("_", " ")]
	else:
		var player := state.get_player(state.active_player_id)
		_status.text = "Turn %d · %s · AP %d" % [state.turn_number, state.active_player_id, player.pool_ap_remaining]
	_panel.selected_id = controller.selected_id
	_panel.refresh()
	_board.queue_redraw()
