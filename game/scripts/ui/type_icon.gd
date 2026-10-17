class_name TypeIcon
extends Control
# The seven character types as sacred-geometry line symbols (mobile feedback 2026-10-17,
# "Elemental set"): Leader circumpunct, Hero eight-point star, Warrior fire triangle,
# Mount spiral, Specialist square in a circle, Mystic vesica piscis, Common plain ring.
# draw_symbol() is shared with the board's badges; this Control shows one on its own.

var type := ""
var color := Color.TRANSPARENT   # TRANSPARENT: the type's own color


func _draw() -> void:
	var c: Color = color if color.a > 0.0 else GameBoardView.ROLE_COLORS.get(type, Color("#b7b8b1"))
	var r := minf(size.x, size.y) * 0.5
	draw_badge(self, size / 2.0, r, type, c)


# A dark disc with a colored rim and the type's symbol inside: the board's role badge.
static func draw_badge(canvas: CanvasItem, center: Vector2, radius: float, p_type: String, c: Color) -> void:
	canvas.draw_circle(center, radius, Color(0.03, 0.035, 0.035, 0.88))
	canvas.draw_arc(center, radius * 0.94, 0.0, TAU, 32, c, maxf(1.0, radius * 0.12), true)
	draw_symbol(canvas, p_type, center, radius * 0.62, c, maxf(1.2, radius * 0.14))


static func draw_symbol(canvas: CanvasItem, p_type: String, at: Vector2, r: float, c: Color, w: float) -> void:
	match p_type:
		"Leader":
			canvas.draw_arc(at, r, 0.0, TAU, 32, c, w, true)
			canvas.draw_circle(at, r * 0.32, c)
		"Hero":
			var pts := PackedVector2Array()
			for i in 17:
				var a := -PI / 2.0 + i * TAU / 16.0
				pts.append(at + Vector2.from_angle(a) * (r * 1.05 if i % 2 == 0 else r * 0.5))
			canvas.draw_polyline(pts, c, w, true)
		"Warrior":
			var tri := PackedVector2Array()
			for i in 4:
				tri.append(at + Vector2.from_angle(-PI / 2.0 + i * TAU / 3.0) * r * 1.08 + Vector2(0, r * 0.12))
			canvas.draw_polyline(tri, c, w, true)
		"Mount":
			var spiral := PackedVector2Array()
			for i in 40:
				var t := i / 39.0
				var a := t * TAU * 1.75
				spiral.append(at + Vector2.from_angle(a) * r * (0.12 + 0.92 * t))
			canvas.draw_polyline(spiral, c, w, true)
		"Specialist":
			canvas.draw_arc(at, r, 0.0, TAU, 32, c, w, true)
			var s := r * 0.62
			canvas.draw_polyline(PackedVector2Array([at + Vector2(-s, -s), at + Vector2(s, -s), at + Vector2(s, s),
					at + Vector2(-s, s), at + Vector2(-s, -s)]), c, w, true)
		"Mystic":
			var off := Vector2(r * 0.42, 0)
			canvas.draw_arc(at - off, r * 0.7, 0.0, TAU, 32, c, w, true)
			canvas.draw_arc(at + off, r * 0.7, 0.0, TAU, 32, c, w, true)
		_:   # Common
			canvas.draw_arc(at, r * 0.8, 0.0, TAU, 32, c, w, true)
