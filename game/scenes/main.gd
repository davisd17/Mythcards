extends Control
# Placeholder board scene: proves the project boots, content loads, and the empty
# 7x7 board renders on both desktop and Web export (HLD-R-007). Replaced by
# BoardView/HUD in the presentation step.

const TILE_COLOR := Color("#d9d4c7")
const TILE_ALT_COLOR := Color("#cbc5b5")
const CENTER_COLOR := Color("#e0b44c")
const BACK_ROW_COLOR := Color("#9fb3c8")
const GRID_LINE_COLOR := Color("#3b3a36")
const MARGIN := 24.0

var board := BoardModel.new()
var _status_label := Label.new()


func _ready() -> void:
	_status_label.position = Vector2(MARGIN, MARGIN)
	_status_label.add_theme_font_size_override("font_size", 22)
	_status_label.text = "MythCards rules prototype\n%d characters · %d relic/event cards loaded" % [
		ContentDB.characters.size(), ContentDB.relic_events.size()]
	add_child(_status_label)
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#1f1e1b"))
	var board_px := minf(size.x, size.y) - MARGIN * 2.0
	var tile_px := board_px / BoardModel.BOARD_SIZE
	var origin := Vector2((size.x - board_px) / 2.0, (size.y - board_px) / 2.0)
	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			var pos := Vector2i(x, y)
			var color := TILE_COLOR if (x + y) % 2 == 0 else TILE_ALT_COLOR
			if y == board.get_edge_row(1) or y == board.get_edge_row(2):
				color = BACK_ROW_COLOR
			if board.is_center(pos):
				color = CENTER_COLOR
			var rect := Rect2(origin + Vector2(x, y) * tile_px, Vector2(tile_px, tile_px))
			draw_rect(rect, color)
			draw_rect(rect, GRID_LINE_COLOR, false, 2.0)
