class_name UiGlyph
extends Control
# A utility icon drawn as lines, for UiStyle.icon_button: "menu" (three bars), "log" (a
# list), "card" (a card with a portrait), "close" (an X). Drawn rather than an emoji or a font glyph, so it looks the same on
# every platform.

var glyph := ""
var color := UiStyle.TEXT


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.22
	var c := size / 2.0
	var w := maxf(2.0, r * 0.2)
	match glyph:
		"menu":
			for i in 3:
				var y := c.y + (i - 1) * r * 0.8
				draw_line(Vector2(c.x - r, y), Vector2(c.x + r, y), color, w, true)
		"log":
			for i in 3:
				var y := c.y + (i - 1) * r * 0.8
				draw_circle(Vector2(c.x - r, y), w * 0.75, color)
				draw_line(Vector2(c.x - r * 0.55, y), Vector2(c.x + r, y), color, w, true)
		"card":
			var card := Rect2(c - Vector2(r * 0.72, r), Vector2(r * 1.44, r * 2.0))
			draw_rect(card, color, false, w)
			draw_circle(c - Vector2(0, r * 0.3), r * 0.28, color, false, w, true)
			draw_line(Vector2(card.position.x + r * 0.3, c.y + r * 0.45), Vector2(card.end.x - r * 0.3, c.y + r * 0.45), color, w, true)
		"close":
			draw_line(c + Vector2(-r, -r) * 0.8, c + Vector2(r, r) * 0.8, color, w, true)
			draw_line(c + Vector2(r, -r) * 0.8, c + Vector2(-r, r) * 0.8, color, w, true)
