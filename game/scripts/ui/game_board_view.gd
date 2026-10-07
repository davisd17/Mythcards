class_name GameBoardView
extends Control
# The game screen's board (LLD-presentation.md 3.1-3.3, drawn in one Control rather than
# node-per-tile). Player 1's back row is at the bottom. Draws tiles, frost, Leak markers,
# placed objects, and characters with HP, level, AP, and status badges, plus whatever
# GameController.highlights() reports. Highlights pair a color with a shape (NFR-024):
# moves are dots, attack targets are crosshair rings, picks are corner brackets.

signal tile_tapped(pos: Vector2i)

const TILE := Color("#29312f")
const TILE_ALT := Color("#222927")
const CENTER := Color("#59604a")
const P1_BACK_ROW := Color("#3b2428")
const P2_BACK_ROW := Color("#1d3438")
const FROST := Color("#7898a0")
const GRID := Color("#70736c")
const MOVE := Color("#5ea776")
const ATTACK := Color("#c95555")
const PICK := Color("#d0ad59")
const LEAK := Color("#7dbb64")
const SELECTED := Color("#f1d379")
const PLAYER_COLORS := {"p1": Color("#a9444c"), "p2": Color("#38919a")}
const ROLE_COLORS := {
	"Common": Color("#b7b8b1"), "Mount": Color("#8cc7b1"), "Warrior": Color("#c98a75"),
	"Leader": Color("#ded6ba"), "Hero": Color("#d7b968"), "Specialist": Color("#98a6b2"),
	"Mystic": Color("#a5a1c8"),
}
const ROLE_MARKS := {
	"Common": "C", "Mount": "M", "Warrior": "W", "Leader": "L", "Hero": "H",
	"Specialist": "S", "Mystic": "Y",
}
const PORTRAIT_FOCUS := {
	"r-gymnast": 0.38, "r-tiger": 0.48, "r-sniper": 0.36, "r-general": 0.37,
	"r-hero": 0.40, "r-engineer": 0.38, "r-seer": 0.36,
	"a-attendant": 0.40, "a-glider": 0.50, "a-guard": 0.39, "a-conductor": 0.37,
	"a-hero": 0.38, "a-architect": 0.38, "a-harmonic": 0.38,
}
const MARGIN := 18.0

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
var outfit_by_instance_id: Dictionary = {}


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
	draw_rect(Rect2(Vector2.ZERO, size), Color("#0b0f0e"))
	if controller == null or controller.board() == null:
		return
	var board := controller.board()
	var font := ThemeDB.fallback_font
	var px := tile_px()
	var h := controller.highlights()
	var board_rect := Rect2(_origin(), Vector2(px * BoardModel.BOARD_SIZE, px * BoardModel.BOARD_SIZE))
	draw_rect(board_rect.grow(10.0), Color("#090c0b"))
	draw_rect(board_rect.grow(7.0), Color("#909088"), false, 2.0)
	draw_rect(board_rect.grow(3.0), Color("#3b403e"), false, 3.0)

	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			var pos := Vector2i(x, y)
			var rect := tile_rect(pos)
			var tile := board.get_tile(pos)
			var color := TILE if (x + y) % 2 == 0 else TILE_ALT
			if y == BoardModel.PLAYER_A_EDGE_ROW:
				color = P1_BACK_ROW
			elif y == BoardModel.PLAYER_B_EDGE_ROW:
				color = P2_BACK_ROW
			if tile.is_center:
				color = CENTER
			if tile.terrain_type == "frost":
				color = FROST
			draw_rect(rect, color)
			draw_rect(rect, GRID, false, 1.5)
			var grain := Color(0.8, 0.82, 0.76, 0.055)
			draw_line(rect.position + Vector2(px * 0.12, px * 0.82), rect.position + Vector2(px * 0.82, px * 0.12), grain, 1.0)
			draw_line(rect.position + Vector2(px * 0.55, px * 0.94), rect.position + Vector2(px * 0.94, px * 0.55), grain, 1.0)
			if tile.is_center:
				var c := rect.get_center()
				var r := px * 0.29
				draw_arc(c, r, 0.0, TAU, 32, Color("#cbb77a"), 2.0)
				draw_arc(c, r * 0.58, 0.0, TAU, 24, Color("#a8c6b1"), 2.0)
				for dir in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
					draw_line(c + dir * r * 0.2, c + dir * r, Color("#d0c392"), 2.0)
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
	if obj.type_id == "leak":
		# Neutral and walk-on: a glowing pool rather than a block.
		draw_circle(rect.get_center(), px * 0.3, Color(LEAK, 0.35))
		draw_arc(rect.get_center(), px * 0.3, 0.0, TAU, 24, LEAK, 3.0)
		_text(font, "LEAK", Rect2(rect.position + Vector2(0, px * 0.62), Vector2(px, px * 0.3)), px * 0.16, Color("#2d5a10"))
		return
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
	var color: Color = PLAYER_COLORS.get(c.player_id, Color.GRAY)
	var role_color: Color = ROLE_COLORS.get(c.data.type, Color("#b7b8b1"))
	var portrait_rect := rect.grow(-px * 0.13)
	var spent: bool = GameState.match_state != null and c.player_id == GameState.match_state.active_player_id \
			and c.character_ap_remaining <= 0 and _mount_ap(c) <= 0
	var outfit_id := outfit_id_for(c)
	var figure := FigureCatalog.texture_for(c.data.id, outfit_id)
	if figure != null:
		_draw_full_body_character(font, c, h, rect, figure, color, role_color, spent)
		return
	draw_rect(Rect2(portrait_rect.position + Vector2(px * 0.045, px * 0.055), portrait_rect.size), Color(0, 0, 0, 0.58))
	var texture := CardView.art_for(c.data.id)
	if texture != null:
		_draw_cover_texture(texture, portrait_rect, float(PORTRAIT_FOCUS.get(c.data.id, 0.4)))
	else:
		draw_rect(portrait_rect, color.darkened(0.38))
	draw_rect(portrait_rect, color, false, maxf(3.0, px * 0.045))
	draw_rect(portrait_rect.grow(-px * 0.045), role_color, false, maxf(1.5, px * 0.018))
	if spent:
		draw_rect(portrait_rect.grow(-px * 0.055), Color(0, 0, 0, 0.48))
	if c.is_mounted_rider:
		draw_arc(center, px * 0.38, 0.0, TAU, 32, Color("#f3e3b5"), 3.0)
	if c.instance_id == controller.selected_id or c.instance_id == controller.placing_id:
		draw_rect(portrait_rect.grow(5.0), SELECTED, false, 4.0)
	if h.attack_ids.has(c.instance_id):
		_draw_crosshair(rect, ATTACK)
	if h.pick_ids.has(c.instance_id):
		_draw_brackets(rect, PICK)

	var role_mark: String = ROLE_MARKS.get(c.data.type, "?")
	_badge(font, portrait_rect.position + Vector2(px * 0.09, px * 0.09), role_mark, role_color, px)
	var tag := DebugPanel.abbreviation(c.data)
	var name_strip := Rect2(portrait_rect.position + Vector2(0, portrait_rect.size.y * 0.64), Vector2(portrait_rect.size.x, portrait_rect.size.y * 0.36))
	draw_rect(name_strip, Color(0.02, 0.025, 0.024, 0.84))
	_text(font, tag, Rect2(name_strip.position, Vector2(name_strip.size.x, name_strip.size.y * 0.52)), px * 0.19, Color("#f2ede2"))
	var hp_max := c.base_max_hp
	if GameState.match_state != null:
		hp_max = RulesEngine.systems().ability.get_effective_max_hp(c)
	_text(font, "%d/%d HP" % [c.current_hp, hp_max], Rect2(name_strip.position + Vector2(0, name_strip.size.y * 0.45),
			Vector2(name_strip.size.x, name_strip.size.y * 0.52)), px * 0.13, Color("#cbd9d4"))
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
		var strip := Rect2(rect.position + Vector2(0, px * 0.82), Vector2(px, px * 0.18))
		draw_rect(strip, Color(0, 0, 0, 0.72))
		_text(font, " ".join(shorts), strip, px * 0.16, Color("#9fe0f5"))


func _draw_cover_texture(texture: Texture2D, target: Rect2, focus_y: float) -> void:
	var source_size := texture.get_size()
	var crop := minf(source_size.x, source_size.y)
	var source_x := (source_size.x - crop) * 0.5
	var source_y := clampf(source_size.y * focus_y - crop * 0.5, 0.0, source_size.y - crop)
	draw_texture_rect_region(texture, target, Rect2(Vector2(source_x, source_y), Vector2(crop, crop)))


func outfit_id_for(c: CharacterInstance) -> String:
	return str(outfit_by_instance_id.get(c.instance_id, FigureCatalog.default_outfit_id(c.data.id)))


func outfit_name(c: CharacterInstance) -> String:
	return FigureCatalog.outfit_name(c.data.id, outfit_id_for(c))


func cycle_outfit(c: CharacterInstance) -> void:
	var next_id := FigureCatalog.next_outfit_id(c.data.id, outfit_id_for(c))
	if next_id != "":
		outfit_by_instance_id[c.instance_id] = next_id
		queue_redraw()


func _draw_full_body_character(font: Font, c: CharacterInstance, h: Dictionary, rect: Rect2,
		texture: Texture2D, player_color: Color, role_color: Color, spent: bool) -> void:
	var px := rect.size.x
	var center := rect.get_center()
	var target_height := px * 0.88
	var target_width := target_height * texture.get_width() / texture.get_height()
	var target := Rect2(Vector2(center.x - target_width * 0.5, rect.position.y + px * 0.035),
			Vector2(target_width, target_height))

	draw_set_transform(Vector2(center.x, rect.position.y + px * 0.82), 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, px * 0.28, Color(0, 0, 0, 0.62))
	draw_circle(Vector2.ZERO, px * 0.23, Color(player_color, 0.68), false, 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var modulate := Color(0.48, 0.5, 0.49, 0.88) if spent else Color.WHITE
	draw_texture_rect(texture, target, false, modulate)

	if c.is_mounted_rider:
		draw_arc(center, px * 0.42, 0.0, TAU, 32, Color("#f3e3b5"), 2.0)
	if c.instance_id == controller.selected_id or c.instance_id == controller.placing_id:
		_draw_brackets(rect.grow(-2.0), SELECTED)
	if h.attack_ids.has(c.instance_id):
		_draw_crosshair(rect, ATTACK)
	if h.pick_ids.has(c.instance_id):
		_draw_brackets(rect, PICK)

	var role_mark: String = ROLE_MARKS.get(c.data.type, "?")
	_badge(font, rect.position + Vector2(px * 0.16, px * 0.16), role_mark, role_color, px)
	if c.level > 1:
		_badge(font, rect.position + Vector2(px * 0.84, px * 0.16), "L%d" % c.level, Color("#c9a45c"), px)
	elif c.spirit_ember_count > 0:
		var ember := "E" if c.spirit_ember_count == 1 else "E%d" % c.spirit_ember_count
		_badge(font, rect.position + Vector2(px * 0.84, px * 0.16), ember, Color("#e07b39"), px)

	var hp_max := c.base_max_hp
	if GameState.match_state != null:
		hp_max = RulesEngine.systems().ability.get_effective_max_hp(c)
	var label := Rect2(rect.position + Vector2(px * 0.17, px * 0.72), Vector2(px * 0.66, px * 0.19))
	draw_rect(label, Color(0.02, 0.025, 0.024, 0.86))
	draw_rect(label, player_color, false, 2.0)
	_text(font, "%s  %d/%d" % [DebugPanel.abbreviation(c.data), c.current_hp, hp_max], label, px * 0.13, Color("#f1ede3"))

	var shorts: Array[String] = []
	for se in c.status_effects:
		var short: String = STATUS.get(se.type, [se.type.left(2).capitalize()])[0]
		if se.type == "shield":
			short += str(se.value)
		if not shorts.has(short):
			shorts.append(short)
	if not shorts.is_empty():
		var strip := Rect2(rect.position + Vector2(0, px * 0.86), Vector2(px, px * 0.14))
		draw_rect(strip, Color(0, 0, 0, 0.76))
		_text(font, " ".join(shorts), strip, px * 0.14, Color("#9fe0f5"))


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
