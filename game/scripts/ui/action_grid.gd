class_name ActionGrid
extends Container
# Buttons in equal-width slots (docs/UI_STYLE_GUIDE.md section 5): one column, or two when
# every label fits half the width. Every row is `row_height` tall, and an incomplete last
# row keeps the column width instead of stretching its button across both columns.

var row_height := UiStyle.CONTROL_HEIGHT
var lines := 1            # 2 for choice rows: a label may take two lines of its slot
var max_columns := 2
var max_width := 0.0      # 0: the full width; otherwise the slots stay within this width


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			_sort()
		NOTIFICATION_RESIZED:
			update_minimum_size()


func items() -> Array[Control]:
	var result: Array[Control] = []
	for child in get_children():
		if child is Control and child.visible and not child.is_queued_for_deletion():
			result.append(child)
	return result


func columns() -> int:
	if max_columns < 2:
		return 1
	var slot := (_region_width() - UiStyle.GAP) / 2.0
	for c in items():
		if label_width(c) > slot * lines * (0.85 if lines > 1 else 1.0):
			return 1
	return 2


func slot_width() -> float:
	var cols := columns()
	return (_region_width() - UiStyle.GAP * (cols - 1)) / cols


func _get_minimum_size() -> Vector2:
	var n := items().size()
	if n == 0:
		return Vector2.ZERO
	var rows := ceili(float(n) / columns())
	return Vector2(0, rows * row_height + (rows - 1) * UiStyle.GAP)


func _sort() -> void:
	var cols := columns()
	var slot := slot_width()
	var i := 0
	for c in items():
		@warning_ignore("integer_division")
		var row := i / cols
		fit_child_in_rect(c, Rect2((i % cols) * (slot + UiStyle.GAP), row * (row_height + UiStyle.GAP), slot, row_height))
		i += 1
	update_minimum_size()


func _region_width() -> float:
	return minf(size.x, max_width) if max_width > 0.0 else size.x


# The width a button's label needs on one line, with its padding.
func label_width(c: Control) -> float:
	if not c is Button:
		return c.get_combined_minimum_size().x
	var b := c as Button
	var font := b.get_theme_font("font")
	var font_size := b.get_theme_font_size("font_size")
	var style := b.get_theme_stylebox("normal")
	var pad := style.get_content_margin(SIDE_LEFT) + style.get_content_margin(SIDE_RIGHT) if style != null else 0.0
	return font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + pad
