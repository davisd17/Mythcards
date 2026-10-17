class_name TermPopup
extends Control
# Definitions of game terms over everything else (mobile feedback 2026-10-17): one term
# from a tapped link, every term on a long-pressed piece, or the whole glossary. Tapping
# outside the panel or Close dismisses it.

const PANEL_WIDTH := 640.0

var _panel := PanelContainer.new()
var _scroll := ScrollContainer.new()
var _title := Label.new()
var _list := VBoxContainer.new()


func _ready() -> void:
	# Already in the tree here, so the offsets must be reset too or the overlay keeps a zero size.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			close())
	add_child(dim)

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1b1f1e")
	style.border_color = Color("#c9a45c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(18)
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 12
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)   # _fit() centers it

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_panel.add_child(box)
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color("#f3e3b5"))
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_title)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list.add_theme_constant_override("separation", 16)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)
	box.add_child(_scroll)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(0, 72)
	close_button.add_theme_font_size_override("font_size", 28)
	close_button.pressed.connect(close)
	box.add_child(close_button)
	resized.connect(_fit)
	_list.minimum_size_changed.connect(_fit)


# Shows the terms with these ids, in order; unknown ids are skipped. `title` heads the
# panel (a piece's name); with one term and no title, the term is the heading.
func show_terms(ids: Array, title: String = "") -> void:
	for child in _list.get_children():
		child.queue_free()
	var shown := 0
	for id in ids:
		var t := Glossary.find(str(id))
		if t.is_empty():
			continue
		_list.add_child(_entry(t, ids.size() > 1 or title != ""))
		shown += 1
	if shown == 0:
		return
	_title.text = title if title != "" else str(Glossary.find(str(ids[0])).term)
	_title.visible = true
	visible = true
	_scroll.scroll_vertical = 0
	_fit.call_deferred()


func show_glossary() -> void:
	var ids := []
	for t in Glossary.terms():
		ids.append(t.id)
	show_terms(ids, "Glossary")


func close() -> void:
	visible = false


func _entry(t: Dictionary, with_heading: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var type := str(t.get("type", ""))
	if type != "":
		var icon := TypeIcon.new()
		icon.type = type
		icon.custom_minimum_size = Vector2(44, 44)
		icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(icon)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.mouse_filter = Control.MOUSE_FILTER_PASS
	text.add_theme_font_size_override("normal_font_size", 26)
	text.add_theme_font_size_override("bold_font_size", 26)
	var body := str(t.definition)
	text.text = ("[b][color=#f3e3b5]%s[/color][/b]\n%s" % [t.term, body]) if with_heading else body
	row.add_child(text)
	return row


# The panel is at most PANEL_WIDTH wide and as tall as its content, up to 80% of the screen.
func _fit() -> void:
	if not visible:
		return
	var w := minf(PANEL_WIDTH, size.x - 40.0)
	_scroll.custom_minimum_size = Vector2(w - 36.0, 0)
	var content := _list.get_combined_minimum_size().y
	_scroll.custom_minimum_size.y = minf(content, size.y * 0.8 - 160.0)
	_panel.reset_size()
	_panel.position = (size - _panel.size) / 2.0
