class_name GameBoardView
extends Control
# The game screen's board (LLD-presentation.md 3.1-3.3; staged per
# LLD-board-visual-phase1.md). One Control draws everything: a framed board of dark
# stone and frozen metal, faction territory inlaid into each back row, the convergence
# aperture at the center, engraved markers for legal actions, and full-body figures on
# bases, drawn back to front. Player 1's back row is at the bottom. All state comes from
# GameController.highlights() and the model; nothing here decides legality.

signal tile_tapped(pos: Vector2i)
signal tile_long_pressed(pos: Vector2i)   # or right-clicked: show that tile's terms

# --- Material -------------------------------------------------------------------------
const BACKGROUND := Color("#0b0f0e")
# Contrast pass (LLD-board-visual-phase1.md 12): the stone sits clearly above the page.
const STONE_A := Color("#3a4542")
const STONE_B := Color("#333d3a")
const SEAM := Color(0.85, 0.88, 0.84, 0.10)
const SPECK := Color(0.9, 0.92, 0.88, 1.0)
const GRID := Color(0.85, 0.88, 0.84, 0.13)
const FRAME_SHADOW := Color(0.0, 0.0, 0.0, 0.85)
const FRAME_BAND := Color("#4a4438")
const FRAME_EDGE := Color("#b9a27a")
const FRAME_BEVEL_LIGHT := Color("#e2d3ac")
const FRAME_BEVEL_DARK := Color("#211f1a")
const CENTER_GLOW := Color("#f2b85a")
# Territory wash: strongest on a side's own back row, gone by the fourth row.
const TERRITORY_ALPHA := 0.36
const TERRITORY_DEPTH := 3.0
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
const MAX_ANIMATION_STEP := 0.05   # seconds of animation per frame, at most
const PULSE_FPS := 24.0       # also paces the Phase 4 ambience
# --- Touch (mobile feedback 2026-10-17) -------------------------------------------------
const LONG_PRESS_MSEC := 450
const DRAG_SLOP := 14.0       # how far a press may wander and still be a tap
const MAX_ZOOM := 2.5
const WHEEL_STEP := 1.15
const DOUBLE_TAP_MSEC := 300

const OBJECT_ART := {
	"barricade": "res://assets/objects/barricade.png",
	"pylon": "res://assets/objects/pylon.png",
	"stone": "res://assets/objects/stone.png",
	"vault": "res://assets/objects/vault.png",
	"leak": "res://assets/objects/leak.png",
}
static var _object_textures: Dictionary = {}

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

var fx := BoardFx.new()    # Phase 2 action feedback; presentation only
var _palettes: Dictionary = {}   # "p1"/"p2" -> SidePalette, refreshed every draw

var _time := 0.0           # drives the center pulse only
var _since_redraw := 0.0
static var _silhouettes: Dictionary = {}   # texture RID -> opaque Rect2 in texture pixels

# Pinch zoom and pan. Zoom scales tile_px() and the pan shifts _origin(), so drawing, hit
# testing and TestBridge's tile positions all follow without anything else knowing.
var zoom := 1.0
var _pan := Vector2.ZERO
var _touches: Dictionary = {}      # touch index -> position
var _pinch_from_dist := 0.0
var _pinch_from_zoom := 1.0
var _pinch_mid := Vector2.ZERO
# A press becomes a tap on release unless it turned into a pan, pinch or long press.
var _pressing := false
var _press_at := Vector2.ZERO
var _press_msec := 0
var _gesture := false
var _last_tap_msec := -DOUBLE_TAP_MSEC


static func status_name(se: StatusEffect) -> String:
	var label: String = STATUS.get(se.type, ["", se.type.capitalize()])[1]
	return "%s %d" % [label, se.value] if se.type == "shield" else label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true   # a zoomed board stays inside its area
	resized.connect(func(): _clamp_pan(); queue_redraw())
	fx.connect_signals()
	fx.attack_art = attack_art_for
	FigureCatalog.preload_attack_frames()


# The center's slow breathing pulse at a bounded redraw rate; every frame while an action
# animation plays; nothing while hidden.
func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	_since_redraw += delta
	if _pressing and not _gesture and Time.get_ticks_msec() - _press_msec >= LONG_PRESS_MSEC:
		_gesture = true
		_long_press(_press_at)
	var animating := fx.active()
	# A slow frame (a stall, a backgrounded tab) can't skip past an animation.
	fx.advance(minf(delta, MAX_ANIMATION_STEP))
	if animating or _since_redraw >= 1.0 / PULSE_FPS:
		_since_redraw = 0.0
		queue_redraw()


# Taps, drags and long presses come in as mouse events (Godot emulates the mouse from the
# first finger), so desktop and phone share one path. Raw touch events only count fingers
# for the pinch. A tap fires on release, so a pan or long press never also taps.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.index == 0:
				_touches.clear()   # a fresh first finger: drop any touch whose release was lost
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		if _touches.size() >= 2:
			_gesture = true
			_begin_pinch()
		return
	if event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() >= 2:
			_update_pinch()
		return
	if event is InputEventMouseButton:
		_mouse_button(event)
		accept_event()
	elif event is InputEventMouseMotion and _pressing and _touches.size() < 2:
		if not _gesture and event.position.distance_to(_press_at) > DRAG_SLOP:
			_gesture = true
		if _gesture and zoom > 1.0:
			_pan += event.relative
			_clamp_pan()
			queue_redraw()
		accept_event()


func _mouse_button(event: InputEventMouseButton) -> void:
	if not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# The press position: a tap ends within DRAG_SLOP of it anyway, and a touch
			# release can report a different spot than the finger lifted from.
			if _pressing and not _gesture:
				_tap(_press_at)
			_pressing = false
		return
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			set_zoom(zoom * WHEEL_STEP, event.position)
		MOUSE_BUTTON_WHEEL_DOWN:
			set_zoom(zoom / WHEEL_STEP, event.position)
		MOUSE_BUTTON_RIGHT:
			_long_press(event.position)
		MOUSE_BUTTON_LEFT:
			_pressing = true
			_gesture = false
			_press_at = event.position
			_press_msec = Time.get_ticks_msec()


func _tap(at: Vector2) -> void:
	var now := Time.get_ticks_msec()
	if zoom > 1.0 and (reset_zoom_rect().has_point(at) or now - _last_tap_msec < DOUBLE_TAP_MSEC):
		_last_tap_msec = -DOUBLE_TAP_MSEC
		set_zoom(1.0, size / 2.0)
		return
	_last_tap_msec = now
	var pos := tile_at(at)
	if pos.x >= 0:
		tile_tapped.emit(pos)


func _long_press(at: Vector2) -> void:
	var pos := tile_at(at)
	if pos.x >= 0:
		tile_long_pressed.emit(pos)


func _begin_pinch() -> void:
	var points: Array = _touches.values()
	_pinch_from_dist = maxf(1.0, points[0].distance_to(points[1]))
	_pinch_from_zoom = zoom
	_pinch_mid = (points[0] + points[1]) / 2.0


func _update_pinch() -> void:
	var points: Array = _touches.values()
	var mid: Vector2 = (points[0] + points[1]) / 2.0
	set_zoom(_pinch_from_zoom * points[0].distance_to(points[1]) / _pinch_from_dist, mid)
	_pan += mid - _pinch_mid
	_pinch_mid = mid
	_clamp_pan()


# Zooms to `new_zoom` (1 to MAX_ZOOM) keeping the board point under `focus` in place.
func set_zoom(new_zoom: float, focus: Vector2) -> void:
	new_zoom = clampf(new_zoom, 1.0, MAX_ZOOM)
	var keep := focus - (focus - _origin()) * (new_zoom / zoom)
	zoom = new_zoom
	_pan += keep - _origin()
	_clamp_pan()
	queue_redraw()


# The board can't be dragged further than its own edge plus the frame margin.
func _clamp_pan() -> void:
	if zoom <= 1.0:
		_pan = Vector2.ZERO
		return
	var board_px := tile_px() * BoardModel.BOARD_SIZE
	var limit := Vector2(maxf(0.0, (board_px - size.x) / 2.0 + MARGIN), maxf(0.0, (board_px - size.y) / 2.0 + MARGIN))
	_pan = _pan.clamp(-limit, limit)


# The "1:1" chip that undoes the zoom, top right; drawn only while zoomed.
func reset_zoom_rect() -> Rect2:
	return Rect2(Vector2(size.x - 104.0, 6.0), Vector2(98.0, 50.0))


# --- Drawing ------------------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	if controller == null or controller.board() == null:
		return
	var board := controller.board()
	_palettes = palettes()
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

	var center_rect := Rect2()
	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			var pos := Vector2i(x, y)
			var rect := tile_rect(pos)
			var tile := board.get_tile(pos)
			_draw_tile_material(pos, rect)
			_draw_territory(pos, rect)
			_draw_faction_inlay(pos, rect)
			if tile.terrain_type == "frost":
				_draw_frost(rect)
			if tile.is_center:
				center_rect = rect
	if Settings.motion:
		_draw_atmosphere(board, px)
	# The center glow spills onto its neighbors, so it goes over the whole material pass.
	if center_rect.size.x > 0:
		_draw_center_glow(center_rect)
		_draw_center_aperture(center_rect)
		if Settings.motion:
			BoardAtmosphere.draw_convergence(self, center_rect.get_center(), px, _time, CENTER_GLOW)
	for c in occupants.values():
		if selected_id != "" and (c.instance_id == selected_id or c.mounted_with_id == selected_id):
			_draw_selected_tile(tile_rect(c.position))
			break

	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			var pos := Vector2i(x, y)
			var rect := tile_rect(pos)
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
	for g in fx.ghosts:
		_draw_ghost(g)
	for e in fx.effects:
		_draw_effect(font, e)
	if zoom > 1.0:
		var chip := reset_zoom_rect()
		draw_rect(chip, Color(0.03, 0.035, 0.035, 0.85))
		draw_rect(chip, Color("#c9a45c"), false, 2.0)
		_text(font, "1:1", chip, 26.0, Color("#f3e3b5"))


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
	# A soft drop shadow, then a bronze band that separates the board from the page.
	for i in 4:
		draw_rect(board_rect.grow(20.0 - 2.0 * i), Color(FRAME_SHADOW, 0.18 + 0.12 * i))
	draw_rect(board_rect.grow(10.0), FRAME_BAND)
	draw_rect(board_rect.grow(10.0), FRAME_EDGE, false, 3.0)
	draw_rect(board_rect.grow(1.5), Color(0, 0, 0, 0.6), false, 2.0)
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


# Each side's territory as a wash of its palette color that fades toward the middle of the
# board: a vertical gradient per tile, continuous across rows (Player 1 is at the bottom).
func _draw_territory(pos: Vector2i, rect: Rect2) -> void:
	var depth_p1 := float(pos.y - BoardModel.PLAYER_A_EDGE_ROW)
	var depth_p2 := float(BoardModel.PLAYER_B_EDGE_ROW - pos.y)
	var bottom_side := depth_p1 < TERRITORY_DEPTH
	if not bottom_side and depth_p2 >= TERRITORY_DEPTH:
		return
	var color := faction_color("p1" if bottom_side else "p2")
	var near_edge := depth_p1 if bottom_side else depth_p2   # tiles from the owner's outer edge
	var outer := Color(color, territory_alpha(near_edge))
	var inner := Color(color, territory_alpha(near_edge + 1.0))
	var top := inner if bottom_side else outer
	var bottom := outer if bottom_side else inner
	draw_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
			Vector2(rect.position.x, rect.end.y)]), PackedColorArray([top, top, bottom, bottom]))


static func territory_alpha(tiles_from_edge: float) -> float:
	var t := clampf(1.0 - tiles_from_edge / TERRITORY_DEPTH, 0.0, 1.0)
	return TERRITORY_ALPHA * t * t


# Each back row's inlay, in its side's culture style and palette, measured from the
# board's outer edge (the bottom for Player 1, the top for Player 2).
func _draw_faction_inlay(pos: Vector2i, rect: Rect2) -> void:
	var bottom_side := pos.y == BoardModel.PLAYER_A_EDGE_ROW
	if not bottom_side and pos.y != BoardModel.PLAYER_B_EDGE_ROW:
		return
	var palette := side_palette("p1" if bottom_side else "p2")
	var px := rect.size.x
	var outer_y := rect.end.y if bottom_side else rect.position.y
	var inward := -1.0 if bottom_side else 1.0
	var at := func(x: float, d: float) -> Vector2: return Vector2(rect.position.x + px * x, outer_y + inward * px * d)
	var primary := palette.primary
	var accent := palette.accent
	if palette.inlay == "city":
		# Russian-inspired: channels near the outer edge, a pressure seal, a registration dot.
		draw_line(at.call(0.0, 0.14), at.call(1.0, 0.14), Color(primary, 0.75), 2.0)
		draw_line(at.call(0.0, 0.07), at.call(1.0, 0.07), Color(primary, 0.45), 1.0)
		var seal_a: Vector2 = at.call(0.02, 0.04)
		var seal_b: Vector2 = at.call(0.07, 0.20)
		draw_rect(Rect2(Vector2(seal_a.x, minf(seal_a.y, seal_b.y)), (seal_b - seal_a).abs()), Color(primary, 0.55), false, 1.5)
		draw_circle(at.call(0.5, 0.11), px * 0.022, Color(accent, 0.85))
		draw_line(at.call(0.44, 0.20), at.call(0.56, 0.20), Color(accent, 0.4), 1.0)
	else:
		# Atlantean: ley lines near the outer edge, a shell arc opening inward, an inlaid dot.
		draw_line(at.call(0.0, 0.14), at.call(1.0, 0.14), Color(primary, 0.75), 2.0)
		draw_line(at.call(0.0, 0.07), at.call(1.0, 0.07), Color(primary, 0.4), 1.0)
		var arc_from := PI if bottom_side else 0.0
		draw_arc(at.call(0.5, 0.14), px * 0.09, arc_from, arc_from + PI, 10, Color(accent, 0.8), 1.5)
		draw_circle(at.call(0.5, 0.19), px * 0.018, Color(accent.lightened(0.4), 0.85))


# Phase 4 ambience: each side's atmosphere over its three home rows, and frost drift.
func _draw_atmosphere(board: BoardModel, px: float) -> void:
	var depth := int(TERRITORY_DEPTH) - 1
	var p1_region := tile_rect(Vector2i(0, BoardModel.PLAYER_A_EDGE_ROW + depth)).merge(
			tile_rect(Vector2i(BoardModel.BOARD_SIZE - 1, BoardModel.PLAYER_A_EDGE_ROW)))
	var p2_region := tile_rect(Vector2i(0, BoardModel.PLAYER_B_EDGE_ROW)).merge(
			tile_rect(Vector2i(BoardModel.BOARD_SIZE - 1, BoardModel.PLAYER_B_EDGE_ROW - depth)))
	BoardAtmosphere.draw_side(self, side_palette("p1"), p1_region, true, px, _time)
	BoardAtmosphere.draw_side(self, side_palette("p2"), p2_region, false, px, _time)
	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			if board.get_tile(Vector2i(x, y)).terrain_type == "frost":
				BoardAtmosphere.draw_frost_drift(self, tile_rect(Vector2i(x, y)), _time, x * 7 + y)


# --- Side palettes (LLD-atmosphere-phase4.md 2) ----------------------------------------------

# Both sides' palettes, from the Leaders on the board (or still in the setup tray).
func palettes() -> Dictionary:
	var source: Object = null
	if controller != null and controller.setup != null:
		source = controller.setup
	elif GameState.match_state != null:
		source = GameState.match_state
	if source == null:
		return SidePalette.for_players(null, null)
	return SidePalette.for_players(source.get_player("p1"), source.get_player("p2"))


func refresh_palettes() -> void:
	_palettes = palettes()


func side_palette(player_id: String) -> SidePalette:
	if _palettes.is_empty():
		_palettes = palettes()
	return _palettes.get(player_id, _palettes.p1)


func faction_color(player_id: String) -> Color:
	return side_palette(player_id).primary if player_id in ["p1", "p2"] else Color.GRAY


# A warm light pooling out of the convergence: it reaches the neighboring tiles so the
# objective reads from across the board, and breathes with the pulse.
func _draw_center_glow(rect: Rect2) -> void:
	var px := rect.size.x
	var c := rect.get_center()
	var p := pulse(_time)
	draw_rect(rect, Color(CENTER_GLOW, 0.10 + 0.04 * p))
	for i in 8:
		draw_circle(c, px * (1.15 - 0.12 * i), Color(CENTER_GLOW, 0.022 + 0.008 * p))
	draw_rect(rect.grow(-1.0), Color(CENTER_GLOW, 0.55 + 0.2 * p), false, 2.0)


# The selected piece's tile: a gold wash and edge, under its markers and figure.
func _draw_selected_tile(rect: Rect2) -> void:
	draw_rect(rect, Color(SELECTED, 0.20))
	draw_rect(rect.grow(-1.5), Color(SELECTED, 0.85), false, 3.0)


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
	var texture := object_texture(obj.type_id)
	if texture != null:
		_draw_object_art(rect, obj, texture)
		return
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
			draw_polyline(outline + PackedVector2Array([outline[0]]), faction_color(obj.owner_player_id), 2.0)
	if obj.max_hp > 0:
		# HP as pips along the bottom edge.
		for i in obj.current_hp:
			draw_circle(rect.position + Vector2(px * (0.5 + (i - (obj.current_hp - 1) * 0.5) * 0.12), px * 0.88),
					px * 0.035, Color("#f1ede3"))


static func object_texture(type_id: String) -> Texture2D:
	if not OBJECT_ART.has(type_id):
		return null
	if not _object_textures.has(type_id):
		var path: String = OBJECT_ART[type_id]
		_object_textures[type_id] = load(path) if ResourceLoader.exists(path) else null
	return _object_textures[type_id] as Texture2D


func _draw_object_art(rect: Rect2, obj: PlacedObjectInstance, texture: Texture2D) -> void:
	var px := rect.size.x
	var center := rect.get_center()
	var is_leak := obj.type_id == "leak"
	if not is_leak:
		draw_set_transform(Vector2(center.x, rect.position.y + px * 0.79), 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, px * 0.31, Color(0, 0, 0, 0.38))
		if obj.owner_player_id in ["p1", "p2"]:
			draw_arc(Vector2.ZERO, px * 0.36, 0.0, TAU, 32, Color(faction_color(obj.owner_player_id), 0.85), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var side := px * (0.92 if is_leak else 0.86)
	var target := Rect2(Vector2(center.x - side * 0.5, rect.position.y + px * 0.03), Vector2.ONE * side)
	if is_leak:
		target.position.y = center.y - side * 0.5
	draw_texture_rect(texture, target, false)
	if obj.max_hp > 0:
		var width := px * maxf(0.28, obj.max_hp * 0.12 + 0.10)
		draw_style_box(_object_health_backing(), Rect2(center.x - width * 0.5, rect.position.y + px * 0.84, width, px * 0.14))
		for i in obj.max_hp:
			var at := Vector2(center.x + px * (i - (obj.max_hp - 1) * 0.5) * 0.12, rect.position.y + px * 0.91)
			draw_circle(at, px * 0.036, Color("#e9e3d3") if i < obj.current_hp else Color("#555b58"))


static var _object_health_style: StyleBoxFlat


static func _object_health_backing() -> StyleBoxFlat:
	if _object_health_style == null:
		_object_health_style = StyleBoxFlat.new()
		_object_health_style.bg_color = Color(0.02, 0.03, 0.025, 0.88)
		_object_health_style.set_corner_radius_all(3)
	return _object_health_style


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
	rect.position += screen_offset(fx.offset_tiles(c), rect.size.x)
	var spent: bool = GameState.match_state != null and c.player_id == GameState.match_state.active_player_id \
			and c.character_ap_remaining <= 0 and _mount_ap(c) <= 0
	var figure := FigureCatalog.texture_for(c.data.id, outfit_id_for(c))
	_draw_piece_base(c, rect, selected)
	# Phase 5: breathe, hop, wind up, recoil... posed about the feet. Only the figure moves;
	# the base, the HP pill, and the badges stay level and readable.
	var feet := feet_point(rect, selected)
	_begin_pose(feet, FigurePose.pose(c, fx, spent, selected, Settings.motion), rect.size.x,
			FigurePose.attack_mirrored(c, fx))
	if figure != null:
		var modulate := Color(0.62, 0.62, 0.66, 0.9) if spent else Color.WHITE
		modulate = modulate.lerp(Color(1.0, 0.32, 0.28), 0.75 * fx.hit_strength(c.instance_id))
		# Every image, attack frames included, uses the default figure's transform: the
		# frames share its canvas and foot anchor and are never fitted one by one.
		var fr := figure_rect(c, rect, figure, selected)
		var local := Rect2(fr.position - feet, fr.size)
		for layer in _figure_layers(c, figure):
			draw_texture_rect(layer.texture, local, false, Color(modulate, modulate.a * layer.alpha))
	else:
		_draw_portrait_token(c, Rect2(rect.position - feet, rect.size), spent)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_labels(font, c, rect)


# Where a figure's feet rest on its tile: the pivot for every pose.
func feet_point(tile: Rect2, selected: bool) -> Vector2:
	var px := tile.size.x
	return Vector2(tile.get_center().x, tile.position.y + FEET_LINE * px - (SELECT_LIFT * px if selected else 0.0))


# Sets the canvas transform so local (0, 0) is the feet, lifted, leaned, and squashed or
# stretched. Volume is kept roughly: a taller figure gets a touch narrower.
func _begin_pose(feet: Vector2, pose: Dictionary, px: float, mirrored := false) -> void:
	var sy: float = pose.scale_y
	var sx := (1.0 - (sy - 1.0) * 0.5) * (-1.0 if mirrored else 1.0)
	draw_set_transform(feet - Vector2(0.0, pose.lift * px), deg_to_rad(pose.lean), Vector2(sx, sy))


# The images that make up a figure this frame, bottom to top: the default figure, or a
# crossfade of hand-drawn attack frames while its art attack plays (Phase 6).
func _figure_layers(c: CharacterInstance, figure: Texture2D) -> Array:
	var l: Dictionary = fx.lunges.get(c.instance_id, {})
	if not l.get("framed", false):
		return [{"texture": figure, "alpha": 1.0}]
	var frames := FigureCatalog.attack_frames(c.data.id, outfit_id_for(c))
	var seconds := frames.map(func(f): return f.seconds)
	var result := []
	for layer in FigurePose.frame_layers(seconds, fx.now - l.start):
		result.append({"texture": figure if layer.frame < 0 else frames[layer.frame].texture, "alpha": layer.alpha})
	return result


# For BoardFx: the attack art timing of a figure, by instance id ({} = procedural).
func attack_art_for(instance_id: String) -> Dictionary:
	var c: CharacterInstance = controller.find(instance_id) if controller != null else null
	if c == null or c.data == null:
		return {}
	return FigureCatalog.attack_timing(c.data.id, outfit_id_for(c))


# Board-space tiles (y up) to screen pixels (y down; Player 1 is at the bottom).
static func screen_offset(tiles: Vector2, px: float) -> Vector2:
	return Vector2(tiles.x, -tiles.y) * px


# A defeated figure sinks into the stone and fades, tinted red.
func _draw_ghost(g: Dictionary) -> void:
	var c: CharacterInstance = g.character
	var t := fx.progress(g.start, BoardFx.DEFEAT)
	var rect := tile_rect(g.pos)
	var figure := FigureCatalog.texture_for(c.data.id, outfit_id_for(c))
	if figure == null:
		return
	var r := figure_rect(c, rect, figure, false)
	var feet := feet_point(rect, false)
	# Before an art attack's impact the defeated figure still stands, untinted (Phase 6).
	var tint := Color.WHITE.lerp(Color(1.0, 0.45, 0.4), minf(1.0, t * 4.0)) if fx.started(g.start) else Color.WHITE
	# It sinks into the stone and, Phase 5, tips over away from whoever defeated it.
	var sunk := feet + Vector2(0.0, rect.size.y * 0.22 * BoardFx.ease_out(t))
	draw_set_transform(sunk, deg_to_rad(FigurePose.topple(g, fx)), Vector2.ONE)
	draw_texture_rect(figure, Rect2(r.position - feet, r.size), false, Color(tint, 1.0 - t))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# Rings, bursts, floating numbers, and the level-up flourish (BoardFx effects).
func _draw_effect(font: Font, e: Dictionary) -> void:
	if not fx.started(e.start):
		return   # waiting for an art attack's impact frame
	var rect := tile_rect(e.pos)
	var px := rect.size.x
	var c := rect.get_center()
	var t := fx.progress(e.start, e.duration)
	var color: Color = e.color
	match e.kind:
		"ring":
			draw_arc(c, px * (0.2 + 0.32 * BoardFx.ease_out(t)), 0.0, TAU, 32, Color(color, 1.0 - t), 3.0)
		"burst":
			for i in 8:
				var dir := Vector2.from_angle(TAU * i / 8.0 + 0.3)
				var a := c + dir * px * (0.12 + 0.30 * BoardFx.ease_out(t))
				draw_line(a, a + dir * px * 0.10 * (1.0 - t), Color(color, 1.0 - t), 3.0)
			if e.text != "":
				_float_text(font, e.text, c, px, t, color, 0.16)
		"number":
			_float_text(font, e.text, c, px, t, color, 0.22)
		"level":
			for i in 2:
				var ti := clampf(t * 1.4 - 0.25 * i, 0.0, 1.0)
				draw_arc(c, px * (0.25 + 0.45 * BoardFx.ease_out(ti)), 0.0, TAU, 40, Color(color, 1.0 - ti), 4.0)
			_float_text(font, e.text, c, px, t, color, 0.20)


# Text that rises from a tile and fades, with a dark outline so it reads over anything.
func _float_text(font: Font, s: String, center: Vector2, px: float, t: float, color: Color, size_frac: float) -> void:
	var fs := int(maxf(12.0, px * size_frac))
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var at := center + Vector2(-w * 0.5, -px * (0.15 + 0.35 * BoardFx.ease_out(t)))
	var alpha := 1.0 - t * t
	draw_string_outline(font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, alpha))
	draw_string(font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(color, alpha))


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
	var faction := faction_color(c.player_id)
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
		draw_rect(portrait, faction_color(c.player_id).darkened(0.4))
	draw_rect(portrait, faction_color(c.player_id), false, 2.0)


# The fixed tag/HP pill (LLD 3.2): the same rect whether or not the figure is selected.
func label_rect(tile: Rect2) -> Rect2:
	var px := tile.size.x
	return Rect2(tile.position + Vector2(px * 0.22, px * 0.865), Vector2(px * 0.56, px * 0.125))


func _draw_labels(font: Font, c: CharacterInstance, rect: Rect2) -> void:
	var px := rect.size.x
	var faction := faction_color(c.player_id)
	var hp_max := c.base_max_hp
	if GameState.match_state != null:
		hp_max = RulesEngine.systems().ability.get_effective_max_hp(c)
	var pill := label_rect(rect)
	draw_rect(pill, Color(0.02, 0.025, 0.024, 0.85))
	draw_rect(pill, Color(faction, 0.9), false, 1.5)
	_text(font, "%s %d/%d" % [DebugPanel.abbreviation(c.data), c.current_hp, hp_max], pill, px * 0.115, Color("#f1ede3"))
	# Type symbol (top-left), level (top-right), Embers (right, below level), statuses down
	# the left edge, beside the figure rather than across it. Long-press explains each.
	var role: Color = ROLE_COLORS.get(c.data.type, Color("#b7b8b1"))
	TypeIcon.draw_badge(self, rect.position + Vector2(px * 0.14, px * 0.14), px * 0.14, c.data.type, role)
	if c.level > 1:
		_badge(font, rect.position + Vector2(px * 0.87, px * 0.13), "I".repeat(c.level), Color("#c9a45c"), px)
	if c.spirit_ember_count > 0:
		_draw_ember(font, rect.position + Vector2(px * 0.86, px * 0.42), c.spirit_ember_count, px)
	var at := rect.position + Vector2(px * 0.12, px * 0.36)
	var drawn := {}
	for se in c.status_effects:
		if drawn.has(se.type):
			continue
		drawn[se.type] = true
		_draw_status(font, at, se, px)
		at.y += px * 0.2
		if at.y > rect.position.y + px * 0.8:
			break


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


# A carried Spirit Ember: a glowing flame, with the count in a dot when it's more than one.
func _draw_ember(font: Font, at: Vector2, count: int, px: float) -> void:
	var r := px * 0.11
	draw_circle(at, r * 1.55, Color(EMBER, 0.18 + 0.22 * pulse(_time * 2.0)))
	draw_circle(at, r * 1.05, Color(0.06, 0.03, 0.02, 0.88))
	draw_colored_polygon(_flame(at, r * 0.95), EMBER)
	draw_colored_polygon(_flame(at + Vector2(0, r * 0.28), r * 0.5), Color("#ffe3a3"))
	if count > 1:
		var dot := at + Vector2(r * 0.9, r * 0.9)
		draw_circle(dot, r * 0.62, Color("#1a0f08"))
		draw_arc(dot, r * 0.62, 0.0, TAU, 20, EMBER, maxf(1.0, r * 0.12), true)
		_text(font, str(count), Rect2(dot - Vector2(r * 0.6, r * 0.6), Vector2(r * 1.2, r * 1.2)), r * 0.95, Color.WHITE)


# A teardrop pointing up: round at the bottom, a tip at the top.
static func _flame(at: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array([at + Vector2(0, -r)])
	var base := at + Vector2(0, r * 0.32)
	for i in 13:
		pts.append(base + Vector2.from_angle(deg_to_rad(-25.0 + i * 230.0 / 12.0)) * r * 0.62)
	return pts


# One status as a small icon: Shield (with its value), Marked, Memory; others as a short tag.
func _draw_status(font: Font, at: Vector2, se: StatusEffect, px: float) -> void:
	var r := px * 0.085
	draw_circle(at, r * 1.15, Color(0.02, 0.025, 0.024, 0.85))
	match se.type:
		"shield":
			var s := r * 0.95
			var shape := PackedVector2Array([at + Vector2(-s * 0.8, -s * 0.75), at + Vector2(s * 0.8, -s * 0.75),
					at + Vector2(s * 0.8, s * 0.05), at + Vector2(0, s * 0.95), at + Vector2(-s * 0.8, s * 0.05)])
			draw_colored_polygon(shape, Color("#5aa9d6"))
			_text(font, str(se.value), Rect2(at - Vector2(r, r * 0.95), Vector2(r * 2, r * 1.7)), r * 1.25, Color("#0b1a24"))
		"marked":
			var red := Color("#ff6b5e")
			var w := maxf(1.2, r * 0.18)
			draw_arc(at, r * 0.62, 0.0, TAU, 20, red, w, true)
			for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				draw_line(at + dir * r * 0.3, at + dir * r * 1.0, red, w, true)
		"memory":
			var drop := _flame(at + Vector2(0, r * 0.1), r * 0.95)
			draw_colored_polygon(drop, Color("#6fd3dc"))
			draw_circle(at + Vector2(0, r * 0.3), r * 0.22, Color("#0b2226"))
		_:
			_text(font, STATUS.get(se.type, [se.type.left(2).capitalize()])[0],
					Rect2(at - Vector2(r * 1.1, r * 1.1), Vector2(r * 2.2, r * 2.2)), r * 1.1, Color("#9fe0f5"))


func _badge(font: Font, at: Vector2, text: String, color: Color, px: float) -> void:
	draw_circle(at, px * 0.105, Color(0, 0, 0, 0.55))
	draw_circle(at, px * 0.09, color)
	_text(font, text, Rect2(at - Vector2(px * 0.1, px * 0.1), Vector2(px * 0.2, px * 0.2)), px * 0.11, Color.BLACK)


func _text(font: Font, s: String, rect: Rect2, font_size: float, color: Color) -> void:
	var fs := int(maxf(16.0, font_size))
	while fs > 9 and font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > rect.size.x - 2.0:
		fs -= 1
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var baseline := rect.position + Vector2((rect.size.x - w) / 2.0, rect.size.y / 2.0 + fs * 0.35)
	draw_string(font, baseline, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


# --- Geometry (hit testing unchanged) --------------------------------------------------------

func tile_px() -> float:
	return (minf(size.x, size.y) - MARGIN * 2.0) / BoardModel.BOARD_SIZE * zoom


func _origin() -> Vector2:
	var board_px := tile_px() * BoardModel.BOARD_SIZE
	return Vector2((size.x - board_px) / 2.0, (size.y - board_px) / 2.0) + _pan


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
