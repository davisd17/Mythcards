class_name HowToDiagram
extends Control
# The How to play pages' small pictures: a simplified 7x7 board in the game board's colors
# (green dots to move, red rings to attack, the glowing center), or AP pips and table
# cards. Drawn, not screenshots, so they stay crisp at any size. Player 1 is at the bottom.

var scene := ""

const N := BoardModel.BOARD_SIZE
const P1 := GameBoardView.CITY_RED
const P2 := GameBoardView.FLOOD_CYAN
const TYPES := ["Common", "Mount", "Warrior", "Leader", "Hero", "Specialist", "Mystic"]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	match scene:
		"ap":
			_draw_ap()
			return
		"cards":
			_draw_cards()
			return
		"squad":
			_draw_squad()
			return
		"":
			return
	_draw_board()
	match scene:
		"board":
			for x in N:
				_token(Vector2i(x, 6), P1, TYPES[x])
				_token(Vector2i(x, 0), P2, TYPES[x])
		"setup":
			_row(6, GameBoardView.PICK)
			for x in [0, 1, 4]:
				_token(Vector2i(x, 6), P1, TYPES[x])
			for x in [2, 3, 5, 6]:
				_brackets(Vector2i(x, 6), GameBoardView.PICK)
		"move":
			_selected(Vector2i(2, 4))
			_token(Vector2i(2, 4), P1, "Warrior")
			_token(Vector2i(4, 4), P1, "Common")
			for t in [Vector2i(2, 3), Vector2i(2, 2), Vector2i(1, 4), Vector2i(0, 4),
					Vector2i(3, 4), Vector2i(2, 5), Vector2i(2, 6)]:
				_dot(t)
			_token(Vector2i(2, 1), P2, "Warrior")
		"attack":
			_selected(Vector2i(1, 5))
			_token(Vector2i(1, 5), P1, "Specialist")
			_token(Vector2i(1, 2), P2, "Warrior")
			_ring(Vector2i(1, 2), GameBoardView.ATTACK)
			_token(Vector2i(3, 5), P1, "Common")
			_token(Vector2i(5, 5), P2, "Mount")
			_cross(Vector2i(5, 5))
		"level":
			_row(0, GameBoardView.PICK)
			_token(Vector2i(3, 2), P1, "Warrior")
			_arrow(Vector2i(3, 2), Vector2i(3, 0), GameBoardView.PICK)
		"embers":
			_token(Vector2i(3, 5), P1, "Mount")
			_ember(Vector2i(3, 5))
			_arrow(Vector2i(3, 5), Vector2i(3, 3), GameBoardView.EMBER)
			_token(Vector2i(5, 2), P2, "Warrior")
		"capture":
			_token(Vector2i(0, 6), P1, "Hero")
			_ring(Vector2i(0, 6), GameBoardView.ATTACK)
			_token(Vector2i(1, 6), P1, "Leader")
			_token(Vector2i(0, 5), P2, "Warrior")
			_token(Vector2i(4, 6), P1, "Common")


# --- Board -----------------------------------------------------------------------------

func _board_rect() -> Rect2:
	var side := minf(size.x, size.y)
	return Rect2((size - Vector2(side, side)) / 2.0, Vector2(side, side))


func _tile(pos: Vector2i) -> Rect2:
	var b := _board_rect().grow(-8.0)
	var px := b.size.x / N
	return Rect2(b.position + Vector2(pos) * px, Vector2(px, px))


func _draw_board() -> void:
	var b := _board_rect()
	draw_rect(b, GameBoardView.FRAME_BAND)
	draw_rect(b, GameBoardView.FRAME_EDGE, false, 2.0)
	for y in N:
		for x in N:
			var r := _tile(Vector2i(x, y))
			draw_rect(r, GameBoardView.STONE_A if (x + y) % 2 == 0 else GameBoardView.STONE_B)
			# Each side's territory, faded toward the middle.
			if y >= 4:
				draw_rect(r, Color(P1, 0.36 - (6 - y) * 0.12))
			elif y <= 2:
				draw_rect(r, Color(P2, 0.36 - y * 0.12))
			draw_rect(r, GameBoardView.GRID, false, 1.0)
	var c := _tile(BoardModel.CENTER_TILE)
	draw_circle(c.get_center(), c.size.x * 0.75, Color(GameBoardView.CENTER_GLOW, 0.12))
	draw_circle(c.get_center(), c.size.x * 0.42, Color(GameBoardView.CENTER_GLOW, 0.3))
	draw_arc(c.get_center(), c.size.x * 0.36, 0.0, TAU, 32, GameBoardView.CENTER_GLOW, 2.0, true)


# A piece: a disc in its team's color with its type's symbol (TypeIcon, as on the board).
func _token(pos: Vector2i, color: Color, type: String) -> void:
	var r := _tile(pos)
	var center := r.get_center()
	var radius := r.size.x * 0.4
	draw_circle(center, radius, color.darkened(0.55))
	draw_arc(center, radius, 0.0, TAU, 32, color.lightened(0.2), maxf(1.5, radius * 0.12), true)
	TypeIcon.draw_symbol(self, type, center, radius * 0.56, GameBoardView.ROLE_COLORS.get(type, UiStyle.TEXT),
			maxf(1.2, radius * 0.13))


func _selected(pos: Vector2i) -> void:
	draw_rect(_tile(pos).grow(-2.0), Color(GameBoardView.SELECTED, 0.25))
	draw_rect(_tile(pos).grow(-2.0), GameBoardView.SELECTED, false, 2.0)


func _dot(pos: Vector2i) -> void:
	var r := _tile(pos)
	draw_circle(r.get_center(), r.size.x * 0.14, GameBoardView.MOVE)


func _ring(pos: Vector2i, color: Color) -> void:
	var r := _tile(pos)
	draw_arc(r.get_center(), r.size.x * 0.46, 0.0, TAU, 32, color, 4.0, true)


func _row(y: int, color: Color) -> void:
	var a := _tile(Vector2i(0, y))
	draw_rect(Rect2(a.position, Vector2(a.size.x * N, a.size.y)), Color(color, 0.18))
	draw_rect(Rect2(a.position, Vector2(a.size.x * N, a.size.y)), color, false, 2.0)


func _brackets(pos: Vector2i, color: Color) -> void:
	var r := _tile(pos).grow(-4.0)
	var l := r.size.x * 0.25
	for corner in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
		var sx := 1.0 if corner.x == r.position.x else -1.0
		var sy := 1.0 if corner.y == r.position.y else -1.0
		draw_line(corner, corner + Vector2(l * sx, 0), color, 3.0)
		draw_line(corner, corner + Vector2(0, l * sy), color, 3.0)


func _cross(pos: Vector2i) -> void:
	var r := _tile(pos)
	var c := r.get_center() + Vector2(r.size.x * 0.3, -r.size.x * 0.3)
	var d := r.size.x * 0.12
	draw_circle(c, d * 1.6, UiStyle.BG)
	draw_line(c - Vector2(d, d), c + Vector2(d, d), GameBoardView.ATTACK, 3.0, true)
	draw_line(c + Vector2(d, -d), c - Vector2(d, -d), GameBoardView.ATTACK, 3.0, true)


func _ember(pos: Vector2i) -> void:
	var r := _tile(pos)
	var c := r.position + Vector2(r.size.x * 0.82, r.size.x * 0.2)
	draw_circle(c, r.size.x * 0.13, GameBoardView.EMBER)
	draw_circle(c, r.size.x * 0.06, Color("#ffd9a0"))


func _arrow(from: Vector2i, to: Vector2i, color: Color) -> void:
	var a := _tile(from).get_center()
	var b := _tile(to).get_center()
	var dir := (b - a).normalized()
	var px := _tile(from).size.x
	a += dir * px * 0.5
	b -= dir * px * 0.3
	draw_line(a, b, color, 4.0, true)
	var side := Vector2(-dir.y, dir.x) * px * 0.15
	draw_colored_polygon(PackedVector2Array([b + dir * px * 0.2, b + side, b - side]), color)


# --- Other pictures ----------------------------------------------------------------------

# The seven types as a key: each symbol over its name, 4 on top and 3 below.
func _draw_squad() -> void:
	var font := ThemeDB.fallback_font
	var font_size := UiStyle.FONT_SECONDARY
	var col_w := size.x / 4.0
	var row_h := size.y / 2.0
	var radius := minf(col_w * 0.3, row_h * 0.28)
	var order := ["Leader", "Hero", "Mount", "Specialist", "Warrior", "Common", "Mystic"]
	for i in order.size():
		var row := 0 if i < 4 else 1
		var col := i if row == 0 else i - 4
		var x := col_w * (col + 0.5) + (col_w * 0.5 if row == 1 else 0.0)
		var center := Vector2(x, row_h * row + row_h * 0.42)
		var type: String = order[i]
		TypeIcon.draw_badge(self, center, radius, type, GameBoardView.ROLE_COLORS[type])
		var tw := font.get_string_size(type, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, Vector2(x - tw / 2.0, center.y + radius + font_size * 1.1), type,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiStyle.TEXT)


# The header's AP pips, large: 3 left of 4, one spent on a move.
func _draw_ap() -> void:
	var font := ThemeDB.fallback_font
	var pip := minf(size.y * 0.16, 40.0)
	var gap := pip * 0.8
	var label_w := pip * 3.2
	var total := label_w + 4 * pip * 2.0 + 3 * gap
	var x := (size.x - total) / 2.0
	var mid := size.y * 0.42
	draw_string(font, Vector2(x, mid + pip * 0.6), "AP", HORIZONTAL_ALIGNMENT_LEFT, -1, int(pip * 1.6), ApMeter.FILLED)
	for i in 4:
		var c := Vector2(x + label_w + pip + i * (pip * 2.0 + gap), mid)
		if i < 3:
			draw_circle(c, pip, ApMeter.FILLED)
			draw_circle(c, pip * 0.45, Color(1, 1, 1, 0.55))
		else:
			draw_arc(c, pip - 2.0, 0.0, TAU, 32, ApMeter.SPENT, 4.0, true)
	var caption := "Move, attack or ability: 1 AP each"
	var font_size := UiStyle.FONT_SECONDARY
	var w := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2((size.x - w) / 2.0, mid + pip * 3.0), caption,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiStyle.MUTED)


# Cards set down beside the board: your relic, an event in effect, their relic.
func _draw_cards() -> void:
	var font := ThemeDB.fallback_font
	var h := minf(size.y * 0.8, 300.0)
	var w := minf(h * 0.68, (size.x - UiStyle.GAP * 2.0) / 3.0)
	h = w / 0.68
	var gap := float(UiStyle.GAP)
	var x := (size.x - (w * 3.0 + gap * 2.0)) / 2.0
	var y := (size.y - h) / 2.0
	var cards := [["Relic", "Player 1", P1], ["Event", "In effect", UiStyle.BRASS], ["Relic", "Player 2", P2]]
	for i in cards.size():
		var r := Rect2(x + i * (w + gap), y, w, h)
		var color: Color = cards[i][2]
		draw_rect(r, UiStyle.PANEL)
		draw_rect(r.grow(-6.0), Color(color, 0.25))
		draw_rect(r, color, false, 3.0)
		for j in 2:
			var text: String = cards[i][j]
			var font_size := UiStyle.FONT_SECONDARY if j == 0 else 22
			var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			draw_string(font, Vector2(r.get_center().x - tw / 2.0, r.position.y + h * (0.45 + j * 0.18)), text,
					HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiStyle.HEADING if j == 0 else UiStyle.TEXT)
