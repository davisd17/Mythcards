class_name BattlefieldTheme
extends RefCounted
# Match environment, independent of each side's territory palette. Like MusicManager,
# it follows the starting side's Leader, never the currently active turn.

const CLOSED_CITY := "Closed City"
const CHAMBER := "res://assets/boards/closed-city/chamber-v1.png"
const SURFACE := "res://assets/boards/closed-city/containment-deck-v1.png"
static var _textures: Dictionary = {}


static func area_for(state: MatchState) -> String:
	if state == null:
		return ""
	var starter := state.get_player(state.first_player_id)
	if starter == null:
		return ""
	for c in starter.characters:
		if c.data != null and c.data.type == "Leader":
			return c.data.sub_area
	return ""


static func is_closed_city() -> bool:
	return area_for(GameState.match_state) == CLOSED_CITY


static func texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D
	return _textures[path]


static func cover(source: Vector2, target: Vector2) -> Rect2:
	var scale := maxf(target.x / source.x, target.y / source.y)
	var visible := target / scale
	return Rect2((source - visible) * 0.5, visible)


static func draw_backdrop(canvas: CanvasItem, bounds: Rect2) -> void:
	canvas.draw_rect(bounds, UiStyle.BG)
	if not is_closed_city() or bounds.size.x <= 0 or bounds.size.y <= 0:
		return
	var backdrop := texture(CHAMBER)
	if backdrop != null:
		canvas.draw_texture_rect_region(backdrop, bounds, cover(backdrop.get_size(), bounds.size))
		# A constant wash guarantees quiet text surfaces without blurring the setting.
		canvas.draw_rect(bounds, Color(0.025, 0.035, 0.03, 0.54))


static func draw_deck(canvas: CanvasItem, playable: Rect2) -> void:
	var surface := texture(SURFACE)
	if surface == null:
		return
	# Nine-slice the illustrated surround into the existing margin: the grid and hit
	# targets are unchanged, and the frame cannot consume a row of playable squares.
	var source := surface.get_size()
	var inset := source * 0.085
	var border := minf(18.0, playable.size.x * 0.04)
	var outer := playable.grow(border)
	var src_x := [0.0, inset.x, source.x - inset.x, source.x]
	var src_y := [0.0, inset.y, source.y - inset.y, source.y]
	var dst_x := [outer.position.x, playable.position.x, playable.end.x, outer.end.x]
	var dst_y := [outer.position.y, playable.position.y, playable.end.y, outer.end.y]
	for y in 3:
		for x in 3:
			var from := Rect2(Vector2(src_x[x], src_y[y]), Vector2(src_x[x + 1] - src_x[x], src_y[y + 1] - src_y[y]))
			var to := Rect2(Vector2(dst_x[x], dst_y[y]), Vector2(dst_x[x + 1] - dst_x[x], dst_y[y + 1] - dst_y[y]))
			var tint := Color(0.73, 0.78, 0.76) if x == 1 and y == 1 else Color.WHITE
			canvas.draw_texture_rect_region(surface, to, from, tint)
