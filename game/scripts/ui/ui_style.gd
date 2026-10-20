class_name UiStyle
extends RefCounted
# The shared UI tokens and control roles (docs/UI_STYLE_GUIDE.md, phase 1). Every command,
# icon button, choice row and chip is made here, so controls of the same role keep the same
# height, font, padding and states at every window size. Values are Godot logical units.

const CONTROL_HEIGHT := 88.0       # every ordinary command, primary and secondary alike
const ICON_SIZE := 88.0            # Log, Menu and other square utility buttons
const CHOICE_ROW_HEIGHT := 128.0   # two-line rows in a dedicated choice list
const PAD_X := 24.0
const PAD_Y := 16.0
const GAP := 16
const SECTION_GAP := 24
const PAGE_INSET := 24
const RADIUS := 6
const BORDER := 2
const FOCUS := 4
const FONT_BUTTON := 32
const FONT_BODY := 32
const FONT_SECONDARY := 28
const FONT_HEADING := 36

const BG := Color("#0b0f0e")
const PANEL := Color("#171c1b")
const CONTROL := Color("#222928")
const HOVER := Color("#303937")
const PRESSED := Color("#151a19")
const TEXT := Color("#e9e5db")
const HEADING := Color("#f3e3b5")
const MUTED := Color("#b8ad92")
const BRASS := Color("#c9a45c")
const ON_BRASS := Color("#1a1916")
const BORDER_COLOR := Color("#4b5552")
const DISABLED_FILL := Color("#171b1a")
const DISABLED_TEXT := Color("#8a908c")   # 5.6:1 on the disabled fill, so the label stays readable

# Layout modes (section 7), chosen from the rendered size in CSS / native pixels.
const NARROW := "narrow"
const MEDIUM := "medium"
const WIDE := "wide"
const SHORT := "short"
const SHORT_UNITS_PER_PX := 2.0   # short mode's one discrete UI scale: 88 units = 44 px


static func theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = FONT_BODY
	t.set_color("font_color", "Label", TEXT)
	t.set_font_size("font_size", "Button", FONT_BUTTON)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", TEXT)
	t.set_color("font_pressed_color", "Button", HEADING)
	t.set_color("font_hover_pressed_color", "Button", HEADING)
	t.set_color("font_disabled_color", "Button", DISABLED_TEXT)
	t.set_stylebox("normal", "Button", box(CONTROL, BORDER_COLOR))
	t.set_stylebox("hover", "Button", box(HOVER, Color("#769080")))
	t.set_stylebox("pressed", "Button", box(PRESSED, BRASS))
	t.set_stylebox("hover_pressed", "Button", box(HOVER, BRASS))
	t.set_stylebox("disabled", "Button", box(DISABLED_FILL, Color("#303634")))
	t.set_stylebox("focus", "Button", focus_ring(HEADING))
	t.set_stylebox("panel", "PanelContainer", panel())
	return t


# A control's surface. Every state keeps the same content margins, so hover, press, focus
# and a thicker border never change a control's size (section 5, "Semantics and States").
static func box(fill: Color, border: Color, border_width: int = BORDER) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(RADIUS)
	s.content_margin_left = PAD_X
	s.content_margin_right = PAD_X
	s.content_margin_top = PAD_Y
	s.content_margin_bottom = PAD_Y
	return s


# Drawn over the control's own state, inside its bounds, so focus never resizes or clips.
static func focus_ring(color: Color) -> StyleBoxFlat:
	var s := box(Color.TRANSPARENT, color, FOCUS)
	s.draw_center = false
	return s


static func panel() -> StyleBoxFlat:
	var s := box(PANEL, Color("#3e4744"), 1)
	s.set_content_margin_all(SECTION_GAP)
	return s


# An ordinary command: one line, CONTROL_HEIGHT tall, never wraps. A label too long for its
# slot ends in an ellipsis; the selected character's card carries the full name. No tooltip:
# hover text that repeats the label isn't needed (designer 2026-10-19).
static func command(text: String, on_press: Callable, role: String = "command") -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, CONTROL_HEIGHT)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.set_meta("ui_role", role)
	b.pressed.connect(on_press)
	return b


# The one command that moves the game on in its region: brass instead of neutral. Emphasis
# changes color only, never height or font size.
static func primary(b: Button) -> Button:
	var states := {"normal": BRASS, "hover": Color("#d6b36c"), "pressed": Color("#a8883f"),
			"hover_pressed": Color("#d6b36c"), "disabled": Color("#4d4535")}
	for state in states:
		b.add_theme_stylebox_override(state, box(states[state], states[state].darkened(0.25)))
	b.add_theme_stylebox_override("focus", focus_ring(ON_BRASS))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, ON_BRASS)
	b.add_theme_color_override("font_disabled_color", Color("#a99c7e"))
	return b


# A row in a dedicated choice list: up to two lines, CHOICE_ROW_HEIGHT tall for every sibling.
static func choice(text: String, on_press: Callable, role: String = "choice") -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, CHOICE_ROW_HEIGHT)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.set_meta("ui_role", role)
	b.pressed.connect(on_press)
	return b


# Marks a choice as the selected one without relying on color alone: a brass bar on the left.
static func mark_selected(b: Button, selected: bool) -> void:
	if not selected:
		b.remove_theme_stylebox_override("normal")
		b.remove_theme_stylebox_override("hover")
		return
	for state in ["normal", "hover"]:
		var s := box(HOVER if state == "hover" else CONTROL, BRASS)
		s.border_width_left = 12
		b.add_theme_stylebox_override(state, s)


# A square utility button with a drawn glyph ("menu", "log", "close"). The tooltip is its
# accessible name, and ui_snapshot() reports it as the button's text.
static func icon_button(glyph: String, name: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.tooltip_text = name
	b.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.set_meta("ui_role", "icon")
	var g := UiGlyph.new()
	g.glyph = glyph
	g.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(g)
	b.pressed.connect(on_press)
	return b


# A tappable status chip (a relic, an active event): command height, tinted by its owner.
static func chip(text: String, color: Color, on_press: Callable) -> Button:
	var b := command(text, on_press, "command:chip")
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", FONT_SECONDARY)
	var tinted := {"normal": color, "hover": color.lightened(0.08), "pressed": color.darkened(0.15),
			"hover_pressed": color.lightened(0.08), "disabled": color.darkened(0.4)}
	for state in tinted:
		var s := box(tinted[state], color.lightened(0.35))
		s.content_margin_left = 12
		s.content_margin_right = 12
		b.add_theme_stylebox_override(state, s)
	return b


# A passive counter (Embers, deck): plain text that doesn't look like a button.
static func counter(text: String, color: Color = MUTED) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", FONT_SECONDARY)
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


static func heading(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", FONT_HEADING)
	l.add_theme_color_override("font_color", HEADING)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


# Rendered pixels (CSS pixels on the web) per logical unit in `viewport`. The one place the
# conversion happens, for native and web alike.
static func px_per_unit(viewport: Viewport) -> float:
	var scale := viewport.get_final_transform().get_scale().x
	if OS.has_feature("web"):
		var ratio = JavaScriptBridge.eval("window.devicePixelRatio || 1", true)
		if ratio != null and float(ratio) > 0.0:
			scale /= float(ratio)
	return scale


# The layout mode for a rendered size (section 7). Medium portrait stacks like narrow; a
# portrait window stays stacked even when wide.
static func mode_for(rendered: Vector2) -> String:
	if rendered.y < 600.0 and rendered.x > rendered.y:
		return SHORT
	if rendered.x >= 1000.0 and rendered.y >= 600.0 and rendered.x > rendered.y:
		return WIDE
	if rendered.x >= 600.0:
		return MEDIUM
	return NARROW
