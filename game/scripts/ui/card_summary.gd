class_name CardSummary
extends PanelContainer
# The strip under the board (playtest 2026-10-06: the full card didn't fit there). Shows
# the inspected character's portrait, name and level, live stats and statuses, and only
# its abilities up to its current level. It clips rather than overflows; tapping it emits `pressed`,
# and the game screen opens the full card in its scrollable overlay.

signal pressed

var _art := TextureRect.new()
var _placeholder := ColorRect.new()
var _title := Label.new()
var _body := RichTextLabel.new()


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1c1f1c")
	style.border_color = Color("#c9a45c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(6)
	add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.custom_minimum_size = Vector2(120, 0)
	_art.clip_contents = true
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_art)
	_placeholder.custom_minimum_size = Vector2(120, 0)
	_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_placeholder)

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text)
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_color", Color("#f3e3b5"))
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(_title)
	_body.bbcode_enabled = true
	_body.scroll_active = false
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.clip_contents = true
	_body.add_theme_font_size_override("normal_font_size", 17)
	_body.add_theme_font_size_override("bold_font_size", 17)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(_body)
	var hint := Label.new()
	hint.text = "Tap for the full card"
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color("#9fe0f5"))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(hint)


func _gui_input(event: InputEvent) -> void:
	var tapped: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventScreenTouch and event.pressed)
	if tapped:
		pressed.emit()
		accept_event()


func show_character(data: CharacterData, instance: CharacterInstance = null) -> void:
	var texture := CardView.art_for(data.id)
	_art.texture = texture
	_art.visible = texture != null
	_placeholder.visible = texture == null
	_placeholder.color = CardView.FACTION_COLORS.get(data.culture, Color.DIM_GRAY).darkened(0.35)
	var level := instance.level if instance != null else 1
	_title.text = "%s  L%d" % [data.char_name, level]
	var lines: Array[String] = [CardView.stat_line(data, instance)]
	if instance != null:
		lines.append(CardView.status_text(instance))
	# The upgrades build on the Level 1 ability, so show it plus every upgrade reached.
	var texts := [data.l1, data.l2, data.l3]
	for i in level:
		lines.append("[b]L%d[/b] %s" % [i + 1, texts[i]])
	_body.text = "\n".join(lines)


# The text shown, for tests.
func text() -> String:
	return _title.text + "\n" + _body.get_parsed_text()
