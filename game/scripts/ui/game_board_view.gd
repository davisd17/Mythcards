class_name GameBoardView
extends Control
# The game screen's board (LLD-presentation.md 3.1-3.3; staged per
# LLD-board-visual-phase1.md). One Control draws everything: a framed board of dark
# stone and frozen metal, faction territory inlaid into each back row, the convergence
# aperture at the center, engraved markers for legal actions, and full-body figures on
# bases, drawn back to front. Player 1's back row is at the bottom. All state comes from
# GameController.highlights() and the model; nothing here decides legality.

signal tile_tapped(pos: Vector2i)

# --- Material -------------------------------------------------------------------------
const BACKGROUND := Color("#0b0f0e")
const STONE_A := Color("#232a29")
const STONE_B := Color("#202726")
const SEAM := Color(0.85, 0.88, 0.84, 0.07)
const SPECK := Color(0.9, 0.92, 0.88, 1.0)
const GRID := Color(0.85, 0.88, 0.84, 0.07)
const FRAME_SHADOW := Color(0.0, 0.0, 0.0, 0.85)
const FRAME_EDGE := Color("#9a958a")
const FRAME_BEVEL_LIGHT := Color("#c9c3b4")
const FRAME_BEVEL_DARK := Color("#3a3d3a")
const FROST := Color("#8fb3bd")
const FROST_EDGE := Color("#e4f4f8")
# --- Faction --------------------------------------------------------------------------
const CITY_RED := Color("#b5474c")
const CITY_GREEN := Color("#6fae7c")
const FLOOD_CYAN := Color("#4fb3bd")
const FLOOD_BRONZE := Color("#a8875a")
const FLOOD_IVORY := Color("#e6dccb")
const PLAYER_COLORS := {"p1": CITY_RED, "p2": FLOOD_CYAN}
const ROLE_COLORS := {
	"Common": Color("#b7b8b1"), "Mount": Color("#8cc7b1"), "Warrior": Color("#c98a75"),
	"Leader": Color("#ded6ba"), "Hero": Color("#d7b968"), "Specialist": Color("#98a6b2"),
	"Mystic": Color("#a5a1c8"),
}
const ROLE_MARKS := {
	"Common": "C", "Mount": "M", "Warrior": "W", "Leader": "L", "Hero": "H",
	"Specialist": "S", "Mystic": "Y",
}
# --- State ----------------------------------------------------------------------------
const MOVE := Color("#6cc08a")
const ATTACK := Color("#d65a5a")
const PICK := Color("#d6b25e")
const SELECTED := Color("#f1d68a")
const LEAK := Color("#86c46c")
const EMBER := Color("#f08a3c")
# --- Geometry (fractions of a tile) ------------------------------------------------------
const FIGURE_HEIGHT := 0.95          # visible silhouette height of a standing figure
const FIGURE_MAX_WIDTH := 0.90       # widest a standing figure may be
const FEET_LINE := 0.86              # where the silhouette's lowest pixel rests
const MOUNT_MAX_SILHOUETTE := 0.94
const MOUNT_MAX_HEIGHT := 0.92
const SELECT_SCALE := 1.065
const SELECT_LIFT := 0.035
const MARGIN := 22.0
# --- Timing -----------------------------------------------------------------------------
const PULSE_PERIOD := 3.2
const PULSE_FPS := 15.0

# Short badges for status effects, drawn on the token; full names show on the card.
const STATUS := {
	"shield": ["S", "Shield"], "memory": ["Me", "Memory"], "marked": ["X", "Marked"],
	"temp_atk": ["+A", "+ATK"], "temp_move": ["Mv", "MOVE change"], "temp_range": ["+R", "+RANGE"],
	"temp_ability_range": ["+R", "+ability RANGE"], "pounce_mark": ["P", "Pounce"],
	"no_mount_dismount": ["No", "can't mount"], "no_push": ["No", "can't be pushed"],
	"no_reaction": ["No", "no reactions"], "range_override": ["L", "Linked"],
	"los_ignore_ally_granted": ["L", "sees past an ally"], "slow": ["-M", "slowed"],
}
const PORTRAIT_FOCUS := {"r-gymnast": 0.38, "r-tiger": 0.48, "r-sniper": 0.36, "r-general": 0.37,
	"r-hero": 0.40, "r-engineer": 0.38, "r-seer": 0.36, "a-attendant": 0.40, "a-glider": 0.50,
	"a-guard": 0.39, "a-conductor": 0.37, "a-hero": 0.38, "a-architect": 0.38, "a-harmonic": 0.38}

var controller: GameController
var outfit_by_instance_id: Dictionary = {}

var _time := 0.0           # drives the center pulse only
var _since_redraw := 0.0
static var _silhouettes: Dictionary = {}   # texture RID -> opaque Rect2 in texture pixels


static func status_name(se: StatusEffect) -> String:
	var label: String = STATUS.get(se.type, ["", se.type.capitalize()])[1]
	return "%s %d" % [label, se.value] if se.type == "shield" else label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)


# The center's slow breathing pulse: a bounded redraw rate, and nothing while hidden.
func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	_since_redraw += delta
	if _since_redraw >= 1.0 / PULSE_FPS:
		_since_redraw = 0.0
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventScreenTouch and event.pressed)
	if pressed:
		var pos := tile_at(event.position)
		if pos.x >= 0:
			tile_tapped.emit(pos)
			accept_event()


# --- Drawing ------------------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	if controller == null or controller.board() == null:
		return
	var board := controller.board()
	var font := ThemeDB.fallback_font
	var px := tile_px()
	var h := controller.highlights()
	var board_rect := Rect2(_origin(), Vector2(px * BoardModel.BOARD_SIZE, px * BoardModel.BOARD_SIZE))
	_draw_board_frame(board_rect)

	var occupants := {}
	for c in controller.characters():
		if not c.defeated and c.is_placed():
			occupants[c.position] = c
	var selected_id := controller.selected_id if controller.selected_id != "" else controller.placing_id

	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			var pos := Vector2i(x, y)
			var rect := tile_rect(pos)
			var tile := board.get_tile(pos)
			_draw_tile_material(pos, rect)
			_draw_faction_inlay(pos, rect)
			if tile.terrain_type == "frost":
				_draw_frost(rect)
			if tile.is_center:
				_draw_center_aperture(rect)
			var obj := board.get_placed_object(pos)
			if obj != null:
				_draw_object(font, rect, obj)
			# Markers: above the material, below the figures.
			if h.move.has(pos):
				_draw_move_rune(rect)
			var occupant: CharacterInstance = occupants.get(pos)
			if h.attack_objects.has(pos) or (occupant != null and h.attack_ids.has(occupant.instance_id)):
				_draw_attack_perimeter(rect)
			if h.pick_tiles.has(pos) or (occupant != null and h.pick_ids.has(occupant.instance_id)):
				_draw_brackets(rect, PICK)

	for c in draw_order(controller.characters()):
		_draw_character(font, c, c.instance_id == selected_id)


# Back to front by screen row (Player 2's side at the top is "back"), then left to right,
# so a lower figure's head overlaps the feet behind it consistently (LLD 3.2).
static func draw_order(characters: Array) -> Array:
	var result := characters.filter(func(c): return not c.defeated and c.is_placed() \
			and not (c.mounted_with_id != "" and not c.is_mounted_rider))
	result.sort_custom(func(a, b):
		if a.position.y != b.position.y:
			return a.position.y > b.position.y
		return a.position.x < b.position.x)
	return result


static func pulse(t: float) -> float:
	return 0.5 - 0.5 * cos(TAU * t / PULSE_PERIOD)


func _draw_board_frame(board_rect: Rect2) -> void:
	draw_rect(board_rect.grow(16.0), FRAME_SHADOW)
	draw_rect(board_rect.grow(10.0), Color("#151918"))
	draw_rect(board_rect.grow(10.0), FRAME_EDGE, false, 3.0)
	var bevel := board_rect.grow(5.0)
	draw_line(bevel.position, Vector2(bevel.end.x, bevel.position.y), FRAME_BEVEL_LIGHT, 2.0)
	draw_line(bevel.position, Vector2(bevel.position.x, bevel.end.y), FRAME_BEVEL_LIGHT, 2.0)
	draw_line(Vector2(bevel.position.x, bevel.end.y), bevel.end, FRAME_BEVEL_DARK, 2.0)
	draw_line(Vector2(bevel.end.x, bevel.position.y), bevel.end, FRAME_BEVEL_DARK, 2.0)
	var outer := board_rect.grow(10.0)
	var rivet := board_rect.grow(13.5)
	for corner in [outer.position, Vector2(outer.end.x, outer.position.y), outer.end, Vector2(outer.position.x, outer.end.y)]:
		var sx := 1.0 if corner.x < outer.get_center().x else -1.0
		var sy := 1.0 if corner.y < outer.get_center().y else -1.0
		draw_line(corner, corner + Vector2(14.0 * sx, 0), FRAME_BEVEL_LIGHT, 2.0)
		draw_line(corner, corner + Vector2(0, 14.0 * sy), FRAME_BEVEL_LIGHT, 2.0)
	for corner in [rivet.position, Vector2(rivet.end.x, rivet.position.y), rivet.end, Vector2(rivet.position.x, rivet.end.y)]:
		draw_circle(corner, 2.5, FRAME_EDGE)


# Dark stone fused with frozen metal; deterministic specks and one seam per tile.
func _draw_tile_material(pos: Vector2i, rect: Rect2) -> void:
	var px := rect.size.x
	draw_rect(rect, STONE_A if (pos.x + 2 * pos.y) % 3 == 0 else STONE_B)
	var noise := (pos.x * 92821 + pos.y * 68917 + 7) & 0x7fffffff
	for i in 5:
		noise = _lcg(noise)
		var sx := float(noise % 1000) / 1000.0
		noise = _lcg(noise)
		var sy := float(noise % 1000) / 1000.0
		draw_circle(rect.position + Vector2(sx, sy) * px, 1.0, Color(SPECK, 0.05 + 0.05 * float(i % 2)))
	noise = _lcg(noise)
	var a := rect.position + Vector2(0.0, float(noise % 1000) / 1000.0 * px)
	noise = _lcg(noise)
	var b := rect.position + Vector2(px, float(noise % 1000) / 1000.0 * px)
	draw_line(a, a.lerp(b, 0.45), SEAM, 1.0)
	draw_rect(rect, GRID, false, 1.0)


static func _lcg(noise: int) -> int:
	return (noise * 1103515245 + 12345) & 0x7fffffff


# Faction territory inlaid into each back row: channels and inlays, never solid fills.
func _draw_faction_inlay(pos: Vector2i, rect: Rect2) -> void:
	var px := rect.size.x
	if pos.y == BoardModel.PLAYER_A_EDGE_ROW:
		# Closed City: warning-red channels near the outer edge, pressure seals, a registration dot.
		var y1 := rect.position.y + px * 0.86
		var y2 := rect.position.y + px * 0.93
		draw_line(Vector2(rect.position.x, y1), Vector2(rect.end.x, y1), Color(CITY_RED, 0.75), 2.0)
		draw_line(Vector2(rect.position.x, y2), Vector2(rect.end.x, y2), Color(CITY_RED, 0.45), 1.0)
		draw_rect(Rect2(rect.position + Vector2(px * 0.02, px * 0.80), Vector2(px * 0.05, px * 0.16)), Color(CITY_RED, 0.55), false, 1.5)
		draw_circle(rect.position + Vector2(px * 0.5, px * 0.89), px * 0.022, Color(CITY_GREEN, 0.85))
		draw_line(rect.position + Vector2(px * 0.44, px * 0.80), rect.position + Vector2(px * 0.56, px * 0.80), Color(CITY_GREEN, 0.4), 1.0)
	elif pos.y == BoardModel.PLAYER_B_EDGE_ROW:
		# Flood Survivors: cyan ley lines near the outer edge, a bronze shell arc, an ivory inlay.
		var y1 := rect.position.y + px * 0.14
		var y2 := rect.position.y + px * 0.07
		draw_line(Vector2(rect.position.x, y1), Vector2(rect.end.x, y1), Color(FLOOD_CYAN, 0.75), 2.0)
		draw_line(Vector2(rect.position.x, y2), Vector2(rect.end.x, y2), Color(FLOOD_CYAN, 0.4), 1.0)
		draw_arc(rect.position + Vector2(px * 0.5, px * 0.14), px * 0.09, 0.0, PI, 10, Color(FLOOD_BRONZE, 0.8), 1.5)
		draw_circle(rect.position + Vector2(px * 0.5, px * 0.19), px * 0.018, Color(FLOOD_IVORY, 0.85))


func _draw_frost(rect: Rect2) -> void:
	var px := rect.size.x
	draw_rect(rect.grow(-1.0), Color(FROST, 0.55))
	for i in 3:
		var o := rect.position + Vector2(px * (0.2 + 0.25 * i), px * 0.25)
		draw_line(o, o + Vector2(px * 0.16, px * 0.16), Color(FROST_EDGE, 0.6), 1.0)
		draw_line(o + Vector2(px * 0.16, 0), o + Vector2(0, px * 0.16), Color(FROST_EDGE, 0.35), 1.0)
	draw_rect(rect.grow(-3.0), Color(FROST_EDGE, 0.8), false, 2.0)


# The convergence aperture: astrolabe rings, reactor cardinals, a slow pulse, and each
# team's banked Spirit Embers as notches on its side of the outer ring.
func _draw_center_aperture(rect: Rect2) -> void:
	var px := rect.size.x
	var c := rect.get_center()
	var p := pulse(_time)
	draw_circle(c, px * 0.44, Color(0, 0, 0, 0.25))
	draw_arc(c, px * 0.40 * (1.0 + 0.02 * p), 0.0, TAU, 40, Color(FLOOD_BRONZE, 0.55 + 0.25 * p), 2.0)
	draw_arc(c, px * 0.27, 0.0, TAU, 32, Color(SELECTED, 0.55), 1.5)
	draw_arc(c, px * 0.14, 0.0, TAU, 24, Color(FLOOD_CYAN, 0.35 + 0.2 * p), 1.5)
	for dir in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		draw_line(c + dir * px * 0.30, c + dir * px * 0.40, Color(FLOOD_BRONZE, 0.75), 2.0)
	var state := GameState.match_state
	for player_id in ["p2", "p1"]:
		var banked := 0
		if state != null and state.get_player(player_id) != null:
			banked = state.get_player(player_id).embers_delivered
		# Screen angles: the upper arc belongs to Player 2 (top), the lower to Player 1.
		var start := deg_to_rad(205.0) if player_id == "p2" else deg_to_rad(25.0)
		for i in VictoryChecker.EMBERS_TO_WIN:
			var angle := start + deg_to_rad(130.0) * float(i) / float(VictoryChecker.EMBERS_TO_WIN - 1)
			var dot := c + Vector2(cos(angle), sin(angle)) * px * 0.40
			draw_circle(dot, px * 0.035, EMBER if i < banked else Color(FLOOD_BRONZE, 0.45))


func _draw_object(font: Font, rect: Rect2, obj: PlacedObjectInstance) -> void:
	var px := rect.size.x
	var c := rect.get_center()
	match obj.type_id:
		"leak":
			# Neutral and walk-on: a glowing seep in the stone rather than a block.
			draw_circle(c, px * 0.30, Color(LEAK, 0.18))
			draw_circle(c, px * 0.19, Color(LEAK, 0.30))
			draw_arc(c, px * 0.30, 0.0, TAU, 28, Color(LEAK, 0.9), 2.0)
			draw_arc(c, px * 0.22, 0.6, 2.4, 10, Color("#d8f5c8"), 1.5)
			return
		"pylon":
			var crystal := PackedVector2Array([c + Vector2(0, -px * 0.30), c + Vector2(px * 0.14, 0),
					c + Vector2(0, px * 0.22), c + Vector2(-px * 0.14, 0)])
			draw_colored_polygon(crystal, Color("#7fd6c9"))
			draw_polyline(crystal + PackedVector2Array([crystal[0]]), Color("#e6fbf7"), 1.5)
		_:
			# Stone, barricade, vault: a bevelled block, darker on its shadow side.
			var colors := {"barricade": Color("#6b5b45"), "stone": Color("#6c6f6b"), "vault": Color("#4a4136")}
			var block := rect.grow(-px * 0.17)
			var base: Color = colors.get(obj.type_id, Color("#555555"))
			var cut := px * 0.07   # chamfered corners: a cut block, not a UI square
			var outline := PackedVector2Array([
				block.position + Vector2(cut, 0), Vector2(block.end.x - cut, block.position.y),
				Vector2(block.end.x, block.position.y + cut), block.end - Vector2(0, cut),
				block.end - Vector2(cut, 0), Vector2(block.position.x + cut, block.end.y),
				Vector2(block.position.x, block.end.y - cut), block.position + Vector2(0, cut)])
			var shadow := PackedVector2Array()
			for v in outline:
				shadow.append(v + Vector2(px * 0.04, px * 0.05))
			draw_colored_polygon(shadow, Color(0, 0, 0, 0.45))
			draw_colored_polygon(outline, base)
			# A lighter top face and chisel marks give it weight.
			draw_rect(Rect2(block.position + Vector2(cut, px * 0.03), Vector2(block.size.x - 2 * cut, block.size.y * 0.32)),
					base.lightened(0.12))
			draw_line(block.position + Vector2(px * 0.12, px * 0.36), block.position + Vector2(px * 0.3, px * 0.42), Color(0, 0, 0, 0.35), 1.5)
			draw_line(block.position + Vector2(px * 0.36, px * 0.5), block.position + Vector2(px * 0.5, px * 0.46), Color(0, 0, 0, 0.3), 1.5)
			draw_polyline(outline + PackedVector2Array([outline[0]]), Color(0, 0, 0, 0.5), 1.5)
			if obj.type_id == "vault":
				draw_arc(block.get_center(), px * 0.12, 0.0, TAU, 16, Color(FLOOD_BRONZE, 0.9), 2.0)
			draw_polyline(outline + PackedVector2Array([outline[0]]), PLAYER_COLORS.get(obj.owner_player_id, Color.GRAY), 2.0)
	if obj.max_hp > 0:
		# HP as pips along the bottom edge.
		for i in obj.current_hp:
			draw_circle(rect.position + Vector2(px * (0.5 + (i - (obj.current_hp - 1) * 0.5) * 0.12), px * 0.88),
					px * 0.035, Color("#f1ede3"))


func _draw_move_rune(rect: Rect2) -> void:
	var px := rect.size.x
	var c := rect.get_center()
	draw_circle(c, px * 0.10, Color(MOVE, 0.45))
	draw_arc(c, px * 0.17, 0.0, TAU, 24, Color(MOVE, 0.9), 2.0)
	for dir in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		draw_circle(c + dir * px * 0.22, px * 0.022, Color(MOVE, 0.9))


func _draw_attack_perimeter(rect: Rect2) -> void:
	var px := rect.size.x
	var r := rect.grow(-px * 0.06)
	draw_rect(r, ATTACK, false, 3.0)
	var c := r.get_center()
	for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var edge := c + Vector2(dir.x * r.size.x * 0.5, dir.y * r.size.y * 0.5)
		draw_line(edge, edge - dir * px * 0.10, ATTACK, 3.0)


func _draw_brackets(rect: Rect2, color: Color) -> void:
	var r := rect.grow(-3.0)
	var l := r.size.x * 0.26
	for corner in [r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y)]:
		var sx := 1.0 if corner.x < r.get_center().x else -1.0
		var sy := 1.0 if corner.y < r.get_center().y else -1.0
		draw_line(corner, corner + Vector2(l * sx, 0), color, 4.0)
		draw_line(corner, corner + Vector2(0, l * sy), color, 4.0)


# --- Figures --------------------------------------------------------------------------------

func _draw_character(font: Font, c: CharacterInstance, selected: bool) -> void:
	var rect := tile_rect(c.position)
	var spent: bool = GameState.match_state != null and c.player_id == GameState.match_state.active_player_id \
			and c.character_ap_remaining <= 0 and _mount_ap(c) <= 0
	var figure := FigureCatalog.texture_for(c.data.id, outfit_id_for(c))
	_draw_piece_base(c, rect, selected)
	if figure != null:
		var modulate := Color(0.62, 0.62, 0.66, 0.9) if spent else Color.WHITE
		draw_texture_rect(figure, figure_rect(c, rect, figure, selected), false, modulate)
	else:
		_draw_portrait_token(c, rect, spent)
	_draw_labels(font, c, rect)


# Where a figure is drawn (LLD 4.2, revised after visual review). Sized by its measured
# silhouette, not its canvas: the figure canvases carry wide faint pixels, so a
# canvas-sized figure looked ~40% too small. A standing figure's visible body is
# FIGURE_HEIGHT tiles tall with its lowest pixel on FEET_LINE, centered on the tile;
# Mounts are fitted by width (at most 0.94 tile).
func figure_rect(c: CharacterInstance, tile: Rect2, texture: Texture2D, selected: bool) -> Rect2:
	var px := tile.size.x
	var sil := _silhouette(texture)
	var s: float
	if c.data.type == "Mount":
		s = minf(MOUNT_MAX_SILHOUETTE * px / maxf(1.0, sil.size.x), MOUNT_MAX_HEIGHT * px / maxf(1.0, sil.size.y))
	else:
		s = minf(FIGURE_HEIGHT * px / maxf(1.0, sil.size.y), FIGURE_MAX_WIDTH * px / maxf(1.0, sil.size.x))
	if selected:
		s *= SELECT_SCALE
	var feet := tile.position.y + FEET_LINE * px - (SELECT_LIFT * px if selected else 0.0)
	var left := tile.get_center().x - (sil.position.x + sil.size.x * 0.5) * s
	var top := feet - (sil.position.y + sil.size.y) * s
	return Rect2(left, top, texture.get_width() * s, texture.get_height() * s)


static func _silhouette(texture: Texture2D) -> Rect2:
	var key := texture.get_rid()
	if not _silhouettes.has(key):
		var image := texture.get_image()
		var used := image.get_used_rect() if image != null else Rect2i()
		_silhouettes[key] = Rect2(used) if used.size.x > 0 else Rect2(Vector2.ZERO, texture.get_size())
	return _silhouettes[key]


# A compact physical base: contact shadow, faction rim, role accent, selection ring.
func _draw_piece_base(c: CharacterInstance, rect: Rect2, selected: bool) -> void:
	var px := rect.size.x
	var feet := Vector2(rect.get_center().x, rect.position.y + px * (FEET_LINE - 0.01))
	var faction: Color = PLAYER_COLORS.get(c.player_id, Color.GRAY)
	var role: Color = ROLE_COLORS.get(c.data.type, Color("#b7b8b1"))
	draw_set_transform(feet, 0.0, Vector2(1.0, 0.34))
	draw_circle(Vector2.ZERO, px * 0.30, Color(0, 0, 0, 0.6))
	draw_arc(Vector2.ZERO, px * 0.25, 0.0, TAU, 32, Color(faction, 0.95 if selected else 0.7), 2.0)
	draw_arc(Vector2.ZERO, px * 0.25, deg_to_rad(55.0), deg_to_rad(125.0), 10, role, 4.0)
	if selected:
		draw_arc(Vector2.ZERO, px * 0.34, 0.0, TAU, 40, SELECTED, 3.0)
		for dir in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
			draw_line(dir * px * 0.34, dir * px * 0.40, SELECTED, 3.0)
	if c.is_mounted_rider:
		draw_arc(Vector2.ZERO, px * 0.29, 0.0, TAU, 32, Color("#f3e3b5"), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# Fallback when a character has no board figure (the hidden original 14).
func _draw_portrait_token(c: CharacterInstance, rect: Rect2, spent: bool) -> void:
	var px := rect.size.x
	var portrait := rect.grow(-px * 0.16)
	var texture := CardView.art_for(c.data.id)
	if texture != null:
		var source := texture.get_size()
		var crop := minf(source.x, source.y)
		var top := clampf(source.y * float(PORTRAIT_FOCUS.get(c.data.id, 0.4)) - crop * 0.5, 0.0, source.y - crop)
		draw_texture_rect_region(texture, portrait, Rect2(Vector2((source.x - crop) * 0.5, top), Vector2(crop, crop)),
				Color(0.62, 0.62, 0.66, 0.9) if spent else Color.WHITE)
	else:
		draw_rect(portrait, PLAYER_COLORS.get(c.player_id, Color.GRAY).darkened(0.4))
	draw_rect(portrait, PLAYER_COLORS.get(c.player_id, Color.GRAY), false, 2.0)


# The fixed tag/HP pill (LLD 3.2): the same rect whether or not the figure is selected.
func label_rect(tile: Rect2) -> Rect2:
	var px := tile.size.x
	return Rect2(tile.position + Vector2(px * 0.22, px * 0.865), Vector2(px * 0.56, px * 0.125))


func _draw_labels(font: Font, c: CharacterInstance, rect: Rect2) -> void:
	var px := rect.size.x
	var faction: Color = PLAYER_COLORS.get(c.player_id, Color.GRAY)
	var hp_max := c.base_max_hp
	if GameState.match_state != null:
		hp_max = RulesEngine.systems().ability.get_effective_max_hp(c)
	var pill := label_rect(rect)
	draw_rect(pill, Color(0.02, 0.025, 0.024, 0.85))
	draw_rect(pill, Color(faction, 0.9), false, 1.5)
	_text(font, "%s %d/%d" % [DebugPanel.abbreviation(c.data), c.current_hp, hp_max], pill, px * 0.115, Color("#f1ede3"))
	# Role (top-left), level (top-right), Embers (right, below level), statuses above the pill.
	var role: Color = ROLE_COLORS.get(c.data.type, Color("#b7b8b1"))
	_badge(font, rect.position + Vector2(px * 0.13, px * 0.13), ROLE_MARKS.get(c.data.type, "?"), role, px)
	if c.level > 1:
		_badge(font, rect.position + Vector2(px * 0.87, px * 0.13), "L%d" % c.level, Color("#c9a45c"), px)
	if c.spirit_ember_count > 0:
		var ember := "E" if c.spirit_ember_count == 1 else "E%d" % c.spirit_ember_count
		_badge(font, rect.position + Vector2(px * 0.87, px * 0.38), ember, EMBER, px)
	var shorts: Array[String] = []
	for se in c.status_effects:
		var short: String = STATUS.get(se.type, [se.type.left(2).capitalize()])[0]
		if se.type == "shield":
			short += str(se.value)
		if not shorts.has(short):
			shorts.append(short)
	if not shorts.is_empty():
		# Statuses sit at the left edge, beside the figure rather than across it.
		var strip := Rect2(rect.position + Vector2(px * 0.02, px * 0.62), Vector2(px * 0.24, px * 0.12))
		draw_rect(strip, Color(0, 0, 0, 0.72))
		_text(font, " ".join(shorts), strip, px * 0.10, Color("#9fe0f5"))


func outfit_id_for(c: CharacterInstance) -> String:
	return str(outfit_by_instance_id.get(c.instance_id, FigureCatalog.default_outfit_id(c.data.id)))


func outfit_name(c: CharacterInstance) -> String:
	return FigureCatalog.outfit_name(c.data.id, outfit_id_for(c))


func cycle_outfit(c: CharacterInstance) -> void:
	var next_id := FigureCatalog.next_outfit_id(c.data.id, outfit_id_for(c))
	if next_id != "":
		outfit_by_instance_id[c.instance_id] = next_id
		queue_redraw()


# A rider's pair can still move on its Mount's AP (ruling 2026-09-28).
func _mount_ap(c: CharacterInstance) -> int:
	if not c.is_mounted_rider or GameState.match_state == null:
		return 0
	var mount_char := GameState.match_state.find_character(c.mounted_with_id)
	return mount_char.character_ap_remaining if mount_char != null else 0


func _badge(font: Font, at: Vector2, text: String, color: Color, px: float) -> void:
	draw_circle(at, px * 0.105, Color(0, 0, 0, 0.55))
	draw_circle(at, px * 0.09, color)
	_text(font, text, Rect2(at - Vector2(px * 0.1, px * 0.1), Vector2(px * 0.2, px * 0.2)), px * 0.11, Color.BLACK)


func _text(font: Font, s: String, rect: Rect2, font_size: float, color: Color) -> void:
	var fs := int(maxf(9.0, font_size))
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var baseline := rect.position + Vector2((rect.size.x - w) / 2.0, rect.size.y / 2.0 + fs * 0.35)
	draw_string(font, baseline, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


# --- Geometry (hit testing unchanged) --------------------------------------------------------

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
