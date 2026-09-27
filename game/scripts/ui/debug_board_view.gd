class_name DebugBoardView
extends Control
# Debug-grade board drawing for playtesting (not the mobile BoardView, HLD 4.12): tiles,
# frost, placed objects, characters with HP, and the selected character's legal moves
# (green), attack targets (red), and attackable objects (orange). Emits the tapped tile.

signal tile_clicked(pos: Vector2i)

const TILE := Color("#d9d4c7")
const TILE_ALT := Color("#cbc5b5")
const CENTER := Color("#e0b44c")
const BACK_ROW := Color("#b9c6d2")
const FROST := Color("#a8d8f0")
const GRID := Color("#3b3a36")
const MOVE := Color(0.2, 0.75, 0.3, 0.45)
const ATTACK := Color(0.9, 0.2, 0.2, 0.45)
const OBJECT_TARGET := Color(0.95, 0.55, 0.1, 0.5)
const SELECTED := Color("#ffe14d")
const PLAYER_COLORS := {"p1": Color("#8c2f39"), "p2": Color("#1f6f8b")}
const MARGIN := 8.0

var controller: DebugController


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos := _tile_at(event.position)
		if pos.x >= 0:
			tile_clicked.emit(pos)
			accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#1f1e1b"))
	var state := GameState.match_state
	if state == null:
		return
	var font := ThemeDB.fallback_font
	var tile_px := _tile_px()
	var moves: Array[Vector2i] = []
	var objects: Array[Vector2i] = []
	var targets: Array[String] = []
	if controller != null:
		moves = controller.move_tiles()
		objects = controller.attack_object_tiles()
		targets = controller.attack_target_ids()

	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			var pos := Vector2i(x, y)
			var rect := _tile_rect(pos)
			var tile := state.board.get_tile(pos)
			var color := TILE if (x + y) % 2 == 0 else TILE_ALT
			if y == BoardModel.PLAYER_A_EDGE_ROW or y == BoardModel.PLAYER_B_EDGE_ROW:
				color = BACK_ROW
			if tile.is_center:
				color = CENTER
			if tile.terrain_type == "frost":
				color = FROST
			draw_rect(rect, color)
			if moves.has(pos):
				draw_rect(rect, MOVE)
			if objects.has(pos):
				draw_rect(rect, OBJECT_TARGET)
			draw_rect(rect, GRID, false, 1.0)
			var obj := state.board.get_placed_object(pos)
			if obj != null:
				var inset := rect.grow(-tile_px * 0.18)
				draw_rect(inset, Color("#6b5b45") if obj.type_id == "barricade" else Color("#7fd6c9"))
				_text(font, "%s %d" % [obj.type_id.left(1).to_upper(), obj.current_hp], rect, tile_px * 0.22, Color.WHITE)

	for p in state.players:
		for c in p.characters:
			if c.defeated or not c.is_placed() or (c.mounted_with_id != "" and not c.is_mounted_rider):
				continue
			var rect := _tile_rect(c.position)
			var center := rect.get_center()
			var radius := tile_px * 0.38
			if targets.has(c.instance_id):
				draw_rect(rect, ATTACK)
			draw_circle(center, radius, PLAYER_COLORS.get(c.player_id, Color.GRAY))
			if controller and c.instance_id == controller.selected_id:
				draw_arc(center, radius + 2.0, 0.0, TAU, 32, SELECTED, 3.0)
			var tag := DebugPanel.abbreviation(c.data) + ("+" if c.is_mounted_rider else "")
			_text(font, tag, Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.62)), tile_px * 0.26, Color.WHITE)
			_text(font, "%d  L%d" % [c.current_hp, c.level],
					Rect2(rect.position + Vector2(0, rect.size.y * 0.42), Vector2(rect.size.x, rect.size.y * 0.5)),
					tile_px * 0.18, Color("#f2f2f2"))


func _text(font: Font, s: String, rect: Rect2, font_size: float, color: Color) -> void:
	var fs := int(maxf(8.0, font_size))
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var baseline := rect.position + Vector2((rect.size.x - w) / 2.0, rect.size.y / 2.0 + fs * 0.35)
	draw_string(font, baseline, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


func _tile_px() -> float:
	return (minf(size.x, size.y) - MARGIN * 2.0) / BoardModel.BOARD_SIZE


func _origin() -> Vector2:
	var board_px := _tile_px() * BoardModel.BOARD_SIZE
	return Vector2((size.x - board_px) / 2.0, (size.y - board_px) / 2.0)


func _tile_rect(pos: Vector2i) -> Rect2:
	var px := _tile_px()
	return Rect2(_origin() + Vector2(pos) * px, Vector2(px, px))


func _tile_at(point: Vector2) -> Vector2i:
	var local := (point - _origin()) / _tile_px()
	var pos := Vector2i(floori(local.x), floori(local.y))
	if pos.x < 0 or pos.y < 0 or pos.x >= BoardModel.BOARD_SIZE or pos.y >= BoardModel.BOARD_SIZE:
		return Vector2i(-1, -1)
	return pos
