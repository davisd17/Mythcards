class_name TableCard
extends Button
# A relic or event lying face up beside the board (designer 2026-10-19: "simulate a
# physical game"): its art, name and kind on a card in its owner's color, set down a little
# askew. An empty relic slot is a dashed outline. Tap it for the full card. `text` holds
# the card's name for the dock animation and the browser tests; the face is drawn instead.

const FACE := Color("#e6d9bb")      # the card's light edge
const INK := Color("#171c1b")       # its dark printed panel

var card_id := ""
var caption := ""                   # the small line under the name: "Relic · P1", "Event · 1 turn"
var owner_color := UiStyle.BRASS
var tilt := 0.0                     # degrees


static func make(id: String, p_caption: String, color: Color, empty_text: String, on_press: Callable) -> TableCard:
	var c := TableCard.new()
	c.card_id = id
	c.caption = p_caption
	c.owner_color = color
	var data := ContentDB.get_relic_event(id) if id != "" else null
	c.text = data.card_name if data != null else (id if id != "" else empty_text)
	c.disabled = id == ""
	# Set down a little askew, the same way every time for the same card.
	c.tilt = (absi(hash(id + p_caption)) % 5 - 2) * 0.7 if id != "" else 0.0
	c.clip_text = true   # the hidden label mustn't widen the row
	c.custom_minimum_size.x = 120
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.set_meta("ui_role", "card:table")
	c.focus_mode = Control.FOCUS_NONE
	var none := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		c.add_theme_stylebox_override(state, none)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color",
			"font_disabled_color", "font_focus_color"]:
		c.add_theme_color_override(key, Color.TRANSPARENT)
	c.pressed.connect(on_press)
	c.mouse_entered.connect(c.queue_redraw)
	c.mouse_exited.connect(c.queue_redraw)
	return c


func _draw() -> void:
	var font := get_theme_default_font()
	var body := Rect2(Vector2(3, 3), size - Vector2(8, 9))
	if card_id == "":
		_draw_empty(font, body)
		return
	var lift := -2.0 if is_hovered() and not button_pressed else 0.0
	draw_set_transform(size / 2.0 + Vector2(0, lift), deg_to_rad(tilt))
	var local := Rect2(body.position - size / 2.0, body.size)
	# Shadow on the table, the card's light edge, then its dark printed face.
	draw_style_box(_box(Color(0, 0, 0, 0.45), Color.TRANSPARENT, 0), Rect2(local.position + Vector2(3, 5), local.size))
	draw_style_box(_box(FACE, owner_color, 3), local)
	var face := local.grow(-6)
	draw_style_box(_box(INK, Color.TRANSPARENT, 0), face)
	var tex := CardView.art_for(card_id)
	if face.size.x < face.size.y * 1.6:
		_draw_full_art(font, face, tex)
		draw_set_transform(Vector2.ZERO)
		return
	# Wide: the art at the face's full height, cropped to 2:3 or narrower, beside the name.
	var art_h := face.size.y - 6.0
	var art := Rect2(face.position + Vector2(3, 3), Vector2(minf(art_h * 2.0 / 3.0, face.size.x * 0.34), art_h))
	if tex != null:
		draw_texture_rect_region(tex, art, _cover(tex.get_size(), art.size))
	else:
		draw_rect(art, owner_color.darkened(0.5))
	draw_rect(art, Color(owner_color, 0.9), false, 1.5)
	# Name over its caption.
	var x := art.end.x + 8.0
	var w := face.end.x - x - 4.0
	var lines := 3 if size.y >= 120.0 else 2
	var name_size := _name_size(font, w, 26 if size.y >= 100.0 else 22, lines, face.size.y - 26.0)
	draw_multiline_string(font, Vector2(x, face.position.y + name_size + 2.0), text, HORIZONTAL_ALIGNMENT_LEFT,
			w, name_size, lines, UiStyle.HEADING)
	draw_string(font, Vector2(x, face.end.y - 6.0), caption, HORIZONTAL_ALIGNMENT_LEFT, w, 18, Color(owner_color.lightened(0.45), 0.95))
	draw_set_transform(Vector2.ZERO)


# Narrow (three or more cards in the row): the art fills the face and the name sits on a
# dark band across the bottom, like a printed card. The frame's color says whose it is.
func _draw_full_art(font: Font, face: Rect2, tex: Texture2D) -> void:
	var art := face.grow(-2)
	if tex != null:
		draw_texture_rect_region(tex, art, _cover(tex.get_size(), art.size))
	else:
		draw_rect(art, owner_color.darkened(0.5))
	var w := art.size.x - 8.0
	var name_size := _name_size(font, w, 22, 2, art.size.y * 0.5)
	var lines := 1 if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x <= w else 2
	var band_h := name_size * 1.2 * lines + 8.0
	var band := Rect2(Vector2(art.position.x, art.end.y - band_h), Vector2(art.size.x, band_h))
	draw_rect(band, Color(INK, 0.86))
	draw_line(band.position, Vector2(band.end.x, band.position.y), Color(owner_color, 0.9), 1.5)
	draw_multiline_string(font, band.position + Vector2(4, name_size + 2.0), text, HORIZONTAL_ALIGNMENT_CENTER,
			w, name_size, lines, UiStyle.HEADING)


# The largest size, up to `largest`, at which every word of the name fits the width and the
# wrapped name fits `lines` lines and `height`.
func _name_size(font: Font, w: float, largest: int, lines: int, height: float) -> int:
	var fs := largest
	while fs > 16:
		var widest := 0.0
		for word in text.split(" "):
			widest = maxf(widest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		var wrapped := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, w, fs, lines + 1)
		if widest <= w and wrapped.y <= minf(height, fs * 1.25 * lines):
			break
		fs -= 1
	return fs


# An open relic slot: a dashed outline in its owner's color.
func _draw_empty(font: Font, body: Rect2) -> void:
	var c := Color(owner_color.lightened(0.2), 0.7)
	var pts := [body.position, Vector2(body.end.x, body.position.y), body.end, Vector2(body.position.x, body.end.y)]
	for i in 4:
		draw_dashed_line(pts[i], pts[(i + 1) % 4], c, 2.0, 10.0)
	var s := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, body.size.x - 12.0, 20)
	draw_multiline_string(font, Vector2(body.position.x + 6.0, body.get_center().y - s.y / 2.0 + 18.0), text,
			HORIZONTAL_ALIGNMENT_CENTER, body.size.x - 12.0, 20, 2, Color(UiStyle.MUTED, 0.9))


static func _box(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(8)
	s.anti_aliasing = true
	return s


# The centered part of a `tex`-sized image with the aspect of `want`.
static func _cover(tex: Vector2, want: Vector2) -> Rect2:
	var scale := maxf(want.x / tex.x, want.y / tex.y)
	var region := want / scale
	return Rect2((tex - region) / 2.0, region)
