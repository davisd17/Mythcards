class_name BattlefieldBackdrop
extends Control

var board: Control
var details: Control
var side_by_side := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	EventBus.match_started.connect(queue_redraw)
	EventBus.match_reset.connect(queue_redraw)
	BattlefieldTheme.texture(BattlefieldTheme.CHAMBER)


func _draw() -> void:
	BattlefieldTheme.draw_backdrop(self, Rect2(Vector2.ZERO, size))
	if not BattlefieldTheme.is_closed_city() or board == null or not board.is_inside_tree():
		return
	var inverse := get_global_transform().affine_inverse()
	var board_rect := inverse * board.get_global_rect()
	var scrim := Color(0.025, 0.04, 0.035, 0.70)
	if side_by_side and details != null:
		var region := inverse * details.get_global_rect()
		draw_rect(Rect2(Vector2(region.position.x - 8, 0), Vector2(size.x - region.position.x + 8, size.y)), scrim)
	else:
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, maxf(0.0, board_rect.position.y - 4))), scrim)
		var below := minf(size.y, board_rect.end.y + 4)
		draw_rect(Rect2(Vector2(0, below), Vector2(size.x, size.y - below)), scrim)
