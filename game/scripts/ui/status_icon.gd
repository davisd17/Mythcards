class_name StatusIcon
extends Control
# The icon a glossary term shows on the board, drawn on its own (designer 2026-10-19: "if
# there is an icon, it should show on that definition as well"): a status badge (Shield,
# Marked, Memory, short tags), a carried Spirit Ember, a type badge, or a placed object's
# art. draw_status() is shared with the board's badges, so the two always match.

var term: Dictionary = {}


# The term has something to draw.
static func has_icon(t: Dictionary) -> bool:
	return str(t.get("type", "")) != "" or str(t.get("status", "")) != "" \
			or GameBoardView.OBJECT_ART.has(str(t.get("object", ""))) or str(t.get("icon", "")) == "ember"


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.5
	var c := size / 2.0
	var type := str(term.get("type", ""))
	var status := str(term.get("status", ""))
	var object := str(term.get("object", ""))
	if type != "":
		TypeIcon.draw_badge(self, c, r, type, GameBoardView.ROLE_COLORS.get(type, Color("#b7b8b1")))
	elif status != "":
		draw_status(self, get_theme_default_font(), c, status, 1, r / 1.15)
	elif GameBoardView.object_texture(object) != null:
		draw_texture_rect(GameBoardView.object_texture(object), Rect2(Vector2.ZERO, size), false)
	elif str(term.get("icon", "")) == "ember":
		draw_ember(self, c, r / 1.55)


# One status as a small icon: Shield (with its value), Marked, Memory; others as a short tag.
static func draw_status(canvas: CanvasItem, font: Font, at: Vector2, type: String, value: int, r: float) -> void:
	canvas.draw_circle(at, r * 1.15, Color(0.02, 0.025, 0.024, 0.85))
	match type:
		"shield":
			var s := r * 0.95
			var shape := PackedVector2Array([at + Vector2(-s * 0.8, -s * 0.75), at + Vector2(s * 0.8, -s * 0.75),
					at + Vector2(s * 0.8, s * 0.05), at + Vector2(0, s * 0.95), at + Vector2(-s * 0.8, s * 0.05)])
			canvas.draw_colored_polygon(shape, Color("#5aa9d6"))
			fit_text(canvas, font, str(value), Rect2(at - Vector2(r, r * 0.95), Vector2(r * 2, r * 1.7)), r * 1.25, Color("#0b1a24"))
		"marked":
			var red := Color("#ff6b5e")
			var w := maxf(1.2, r * 0.18)
			canvas.draw_arc(at, r * 0.62, 0.0, TAU, 20, red, w, true)
			for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				canvas.draw_line(at + dir * r * 0.3, at + dir * r * 1.0, red, w, true)
		"memory":
			var drop := GameBoardView._flame(at + Vector2(0, r * 0.1), r * 0.95)
			canvas.draw_colored_polygon(drop, Color("#6fd3dc"))
			canvas.draw_circle(at + Vector2(0, r * 0.3), r * 0.22, Color("#0b2226"))
		_:
			fit_text(canvas, font, GameBoardView.STATUS.get(type, [type.left(2).capitalize()])[0],
					Rect2(at - Vector2(r * 1.1, r * 1.1), Vector2(r * 2.2, r * 2.2)), r * 1.1, Color("#9fe0f5"))


# A Spirit Ember without the board's pulse.
static func draw_ember(canvas: CanvasItem, at: Vector2, r: float) -> void:
	canvas.draw_circle(at, r * 1.55, Color(GameBoardView.EMBER, 0.3))
	canvas.draw_circle(at, r * 1.05, Color(0.06, 0.03, 0.02, 0.88))
	canvas.draw_colored_polygon(GameBoardView._flame(at, r * 0.95), GameBoardView.EMBER)
	canvas.draw_colored_polygon(GameBoardView._flame(at + Vector2(0, r * 0.28), r * 0.5), Color("#ffe3a3"))


# `s` centered in `rect`, shrunk until it fits the width.
static func fit_text(canvas: CanvasItem, font: Font, s: String, rect: Rect2, font_size: float, color: Color) -> void:
	var fs := int(maxf(16.0, font_size))
	while fs > 9 and font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > rect.size.x - 2.0:
		fs -= 1
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var baseline := rect.position + Vector2((rect.size.x - w) / 2.0, rect.size.y / 2.0 + fs * 0.35)
	canvas.draw_string(font, baseline, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
