class_name GameBoardView
extends Control
# The game screen's board (LLD-presentation.md 3.1-3.3, drawn in one Control rather than
# node-per-tile). Player 1's back row is at the bottom. Draws tiles, frost, Leak markers,
# placed objects, and characters with HP, level, AP, and status badges, plus whatever
# GameController.highlights() reports. Highlights pair a color with a shape (NFR-024):
# moves are dots, attack targets are crosshair rings, picks are corner brackets.

signal tile_tapped(pos: Vector2i)

const TILE := Color("#d9d4c7")
const TILE_ALT := Color("#cbc5b5")
const CENTER := Color("#e0b44c")
const BACK_ROW := Color("#b9c6d2")
const FROST := Color("#a8d8f0")
const GRID := Color("#3b3a36")
const MOVE := Color(0.15, 0.6, 0.25)
const ATTACK := Color(0.85, 0.15, 0.15)
const PICK := Color(0.95, 0.75, 0.1)
const LEAK := Color(0.45, 0.85, 0.2)
const SELECTED := Color("#ffe14d")
const PLAYER_COLORS := {"p1": Color("#8c2f39"), "p2": Color("#1f6f8b")}
const MARGIN := 6.0

# Short badges for status effects, drawn on the token; full names show on the card.
const STATUS := {
	"shield": ["S", "Shield"], "memory": ["Me", "Memory"], "marked": ["X", "Marked"],
	"temp_atk": ["+A", "+ATK"], "temp_move": ["Mv", "MOVE change"], "temp_range": ["+R", "+RANGE"],
	"temp_ability_range": ["+R", "+ability RANGE"], "pounce_mark": ["P", "Pounce"],
	"no_mount_dismount": ["No", "can't mount"], "no_push": ["No", "can't be pushed"],
	"no_reaction": ["No", "no reactions"], "range_override": ["L", "Linked"],
	"los_ignore_ally_granted": ["L", "sees past an ally"], "slow": ["-M", "slowed"],
}

var controller: GameController


static func status_name(se: StatusEffect) -> String:
	var label: String = STATUS.get(se.type, ["", se.type.capitalize()])[1]
	return "%s %d" % [label, se.value] if se.type == "shield" else label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventScreenTouch and event.pressed)
	if pressed:
		var pos := tile_at(event.position)
		if pos.x >= 0:
			tile_tapped.emit(pos)
			accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#1a1916"))
	if controller == null or controller.board() == null:
		return
	var board := controller.board()
	var font := ThemeDB.fallback_font
	var px := tile_px()
	var h := controller.highlights()

	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			var pos := Vector2i(x, y)
			var rect := tile_rect(pos)
			var tile := board.get_tile(pos)
			var color := TILE if (x + y) % 2 == 0 else TILE_ALT
			if y == BoardModel.PLAYER_A_EDGE_ROW or y == BoardModel.PLAYER_B_EDGE_ROW:
				color = BACK_ROW
			if tile.is_center:
				color = CENTER
			if tile.terrain_type == "frost":
				color = FROST
			draw_rect(rect, color)
			draw_rect(rect, GRID, false, 2.0)
			if tile.is_center:
				var c := rect.get_center()
				var r := px * 0.22
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]),
						Color(1, 1, 1, 0.45))
			if tile.leak:
				draw_circle(rect.get_center(), px * 0.3, Color(LEAK, 0.35))
				draw_arc(rect.get_center(), px * 0.3, 0.0, TAU, 24, LEAK, 3.0)
				_text(font, "LEAK", Rect2(rect.position + Vector2(0, px * 0.62), Vector2(px, px * 0.3)), px * 0.16, Color("#2d5a10"))
			var obj := board.get_placed_object(pos)
			if obj != null:
				_draw_object(font, rect, obj)
			if h.move.has(pos):
				draw_circle(rect.get_center(), px * 0.14, Color(MOVE, 0.85))
			if h.attack_objects.has(pos):
				_draw_crosshair(rect, ATTACK)
			if h.pick_tiles.has(pos):
				_draw_brackets(rect, PICK)

	for c in controller.characters():
		if c.defeated or not c.is_placed() or (c.mounted_with_id != "" and not c.is_mounted_rider):
			continue
		_draw_character(font, c, h)


func _draw_object(font: Font, rect: Rect2, obj: PlacedObjectInstance) -> void:
	var px := rect.size.x
	var inset := rect.grow(-px * 0.16)
	var colors := {"barricade": Color("#6b5b45"), "pylon": Color("#7fd6c9"), "stone": Color("#6e6e6e")}
	draw_rect(inset, colors.get(obj.type_id, Color("#555555")))
	draw_rect(inset, PLAYER_COLORS.get(obj.owner_player_id, Color.GRAY), false, 3.0)
	var label: String = obj.type_id.capitalize()
	if obj.max_hp > 0:
		label += " %d" % obj.current_hp
	_text(font, label, inset, px * 0.17, Color.WHITE)


func _draw_character(font: Font, c: CharacterInstance, h: Dictionary) -> void:
	var rect := tile_rect(c.position)
	var px := rect.size.x
	var center := rect.get_center()
	var radius := px * 0.4
	var color: Color = PLAYER_COLORS.get(c.player_id, Color.GRAY)
	var spent: bool = GameState.match_state != null and c.player_id == GameState.match_state.active_player_id \
			and c.character_ap_remaining <= 0 and _mount_ap(c) <= 0
	draw_circle(center, radius, color.darkened(0.45) if spent else color)
	if c.is_mounted_rider:
		draw_arc(center, radius - 3.0, 0.0, TAU, 32, Color("#f3e3b5"), 2.0)
	if c.instance_id == controller.selected_id or c.instance_id == controller.placing_id:
		draw_arc(center, radius + 3.0, 0.0, TAU, 40, SELECTED, 4.0)
	if h.attack_ids.has(c.instance_id):
		_draw_crosshair(rect, ATTACK)
	if h.pick_ids.has(c.instance_id):
		_draw_brackets(rect, PICK)

	var tag := DebugPanel.abbreviation(c.data)
	_text(font, tag, Rect2(rect.position + Vector2(0, px * 0.12), Vector2(px, px * 0.4)), px * 0.28, Color.WHITE)
	var hp_max := c.base_max_hp
	if GameState.match_state != null:
		hp_max = RulesEngine.systems().ability.get_effective_max_hp(c)
	_text(font, "%d/%d" % [c.current_hp, hp_max], Rect2(rect.position + Vector2(0, px * 0.5), Vector2(px, px * 0.3)),
			px * 0.19, Color("#f2f2f2"))
	# Level badge (top-left), Spirit Embers (top-right), statuses along the bottom.
	if c.level > 1:
		_badge(font, rect.position + Vector2(px * 0.16, px * 0.16), "L%d" % c.level, Color("#c9a45c"), px)
	if c.spirit_ember_count > 0:
		var ember := "E" if c.spirit_ember_count == 1 else "E%d" % c.spirit_ember_count
		_badge(font, rect.position + Vector2(px * 0.84, px * 0.16), ember, Color("#e07b39"), px)
	var shorts: Array[String] = []
	for se in c.status_effects:
		var short: String = STATUS.get(se.type, [se.type.left(2).capitalize()])[0]
		if se.type == "shield":
			short += str(se.value)
		if not shorts.has(short):
			shorts.append(short)
	if not shorts.is_empty():
		var strip := Rect2(rect.position + Vector2(0, px * 0.78), Vector2(px, px * 0.22))
		draw_rect(strip, Color(0, 0, 0, 0.55))
		_text(font, " ".join(shorts), strip, px * 0.16, Color("#9fe0f5"))


# A rider's pair can still move on its Mount's AP (ruling 2026-09-28).
func _mount_ap(c: CharacterInstance) -> int:
	if not c.is_mounted_rider or GameState.match_state == null:
		return 0
	var mount_char := GameState.match_state.find_character(c.mounted_with_id)
	return mount_char.character_ap_remaining if mount_char != null else 0


func _badge(font: Font, at: Vector2, text: String, color: Color, px: float) -> void:
	draw_circle(at, px * 0.13, color)
	_text(font, text, Rect2(at - Vector2(px * 0.13, px * 0.13), Vector2(px * 0.26, px * 0.26)), px * 0.13, Color.BLACK)


func _draw_crosshair(rect: Rect2, color: Color) -> void:
	var c := rect.get_center()
	var r := rect.size.x * 0.46
	draw_arc(c, r, 0.0, TAU, 32, color, 4.0)
	for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(c + dir * r * 0.75, c + dir * r * 1.05, color, 4.0)


func _draw_brackets(rect: Rect2, color: Color) -> void:
	var r := rect.grow(-3.0)
	var l := r.size.x * 0.28
	for corner in [r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y)]:
		var sx := 1.0 if corner.x < r.get_center().x else -1.0
		var sy := 1.0 if corner.y < r.get_center().y else -1.0
		draw_line(corner, corner + Vector2(l * sx, 0), color, 5.0)
		draw_line(corner, corner + Vector2(0, l * sy), color, 5.0)


func _text(font: Font, s: String, rect: Rect2, font_size: float, color: Color) -> void:
	var fs := int(maxf(9.0, font_size))
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var baseline := rect.position + Vector2((rect.size.x - w) / 2.0, rect.size.y / 2.0 + fs * 0.35)
	draw_string(font, baseline, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


func tile_px() -> float:
	return (minf(size.x, size.y) - MARGIN * 2.0) / BoardModel.BOARD_SIZE


func _origin() -> Vector2:
	var board_px := tile_px() * BoardModel.BOARD_SIZE
	return Vector2((size.x - board_px) / 2.0, (size.y - board_px) / 2.0)


# Player 1's side (row 0) is drawn at the bottom.
func tile_rect(pos: Vector2i) -> Rect2:
	var px := tile_px()
	var screen := Vector2(pos.x, BoardModel.BOARD_SIZE - 1 - pos.y)
	return Rect2(_origin() + screen * px, Vector2(px, px))


func tile_at(point: Vector2) -> Vector2i:
	var local := (point - _origin()) / tile_px()
	var col := floori(local.x)
	var row := floori(local.y)
	if col < 0 or row < 0 or col >= BoardModel.BOARD_SIZE or row >= BoardModel.BOARD_SIZE:
		return Vector2i(-1, -1)
	return Vector2i(col, BoardModel.BOARD_SIZE - 1 - row)
