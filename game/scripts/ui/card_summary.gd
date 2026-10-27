class_name CardSummary
extends PanelContainer
# The strip under the board (playtest 2026-10-06: the full card didn't fit there). Shows
# the inspected character's portrait, name and level, live stats and statuses, and its
# Level 1 ability. Upgrades live on the full card only (playtest 2026-10-26: appending them
# cut the text off on a phone). It clips rather than overflows; tapping it emits `pressed`,
# and the game screen opens the full card in its scrollable overlay.

signal pressed

var _art := TextureRect.new()
var _placeholder := ColorRect.new()
var _icon := TypeIcon.new()
var _title := Label.new()
var _body := RichTextLabel.new()
var _hint := Label.new()


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#161a19")
	style.border_color = Color("#4b5552")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(6)
	add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.custom_minimum_size = Vector2(80, 0)
	_art.clip_contents = true
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_art)
	_placeholder.custom_minimum_size = Vector2(80, 0)
	_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_placeholder)

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.custom_minimum_size = Vector2(34, 34)
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(_icon)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", Color("#f3e3b5"))
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.clip_text = true
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(_title)
	text.add_child(title_row)
	# The body clips; a fade over its last lines says there's more on the full card,
	# rather than cutting a line in half (mobile feedback 2026-10-17).
	var body_box := Control.new()
	body_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_box.clip_contents = true
	body_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(body_box)
	_body.bbcode_enabled = true
	_body.scroll_active = false
	_body.fit_content = true
	_body.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_body.add_theme_font_size_override("normal_font_size", 24)
	_body.add_theme_font_size_override("bold_font_size", 24)
	_body.add_theme_constant_override("table_h_separation", 18)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_box.add_child(_body)
	var fade := TextureRect.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.086, 0.102, 0.098, 0.0))
	gradient.set_color(1, Color(0.086, 0.102, 0.098, 1.0))
	var fade_texture := GradientTexture2D.new()
	fade_texture.gradient = gradient
	fade_texture.fill_from = Vector2(0, 0)
	fade_texture.fill_to = Vector2(0, 1)
	fade.texture = fade_texture
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	fade.offset_top = -34
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_box.add_child(fade)
	_hint.text = "Tap for the full card"
	_hint.add_theme_font_size_override("font_size", 24)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_color_override("font_color", Color("#9fe0f5"))
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(_hint)


func _gui_input(event: InputEvent) -> void:
	# Mouse only: touch is emulated as a click, so handling InputEventScreenTouch too fires twice.
	var tapped: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
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
	_icon.type = data.type
	_icon.queue_redraw()
	var s := CardView.stats(data, instance)
	var lines: Array[String] = ["[b][table=2][cell]HP %s[/cell][cell]ATK %d[/cell][cell]MOVE %d[/cell][cell]RANGE %d[/cell][/table][/b]"
			% [s.hp, s.atk, s.move, s.range]]
	if s.defeated:
		lines.append("[color=#e06666]DEFEATED[/color]")
	if instance != null:
		lines.append(CardView.status_text(instance))
	lines.append("[b]L1[/b] %s" % data.l1)
	_body.text = "\n".join(lines)
	_hint.text = "Tap for the full card" if level < 2 else "Tap for the full card: Level %d upgrades" % level


# The text shown, for tests.
func text() -> String:
	return _title.text + "\n" + _body.get_parsed_text() + "\n" + _hint.text
