class_name ApMeter
extends Control
# The active player's pool AP as pips (Visual Polish Phase 3): filled for AP left, hollow
# for AP spent. Hidden during setup (maximum 0).

const FILLED := Color("#9fe0f5")
const SPENT := Color("#3c4a4d")
const PIP := 9.0
const GAP := 6.0

var remaining := 0
var maximum := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func set_ap(p_remaining: int, p_maximum: int) -> void:
	remaining = p_remaining
	maximum = p_maximum
	visible = maximum > 0
	custom_minimum_size = Vector2(44.0 + maximum * (PIP * 2.0 + GAP), 40.0)
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var mid := size.y * 0.5
	draw_string(font, Vector2(0, mid + 8.0), "AP", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, FILLED)
	for i in maximum:
		var c := Vector2(44.0 + PIP + i * (PIP * 2.0 + GAP), mid)
		if i < remaining:
			draw_circle(c, PIP, FILLED)
			draw_circle(c, PIP * 0.45, Color(1, 1, 1, 0.55))
		else:
			draw_arc(c, PIP - 1.0, 0.0, TAU, 20, SPENT, 2.0)
