class_name ActionLogView
extends VBoxContainer
# The in-game action log (MatchLog), shown in the card panel's place. One block per turn,
# edged in that player's color; each action is the actor's type symbol in its team's color
# and a few words. Played relic and event cards are links. The last finished turn (what the
# opponent just did) is highlighted. Tap an action for its full record.

signal card_pressed(card_id: String)

const MAX_TURNS := 30
const BADGE := 56.0
const DAMAGE := Color("#e06666")

var color_for: Callable = func(_player_id: String) -> Color: return UiStyle.BRASS
var _signature := ""
var _focus: Control = null   # the block to scroll to: the last finished turn


func _ready() -> void:
	add_theme_constant_override("separation", UiStyle.GAP)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


# Rebuilds only when the log has changed since the last call.
func refresh() -> void:
	var entries := MatchLog.entries
	var sig := "%d" % entries.size()
	if not entries.is_empty():
		sig += ":%d:%d:%s" % [entries[-1].lines.size(), entries[-1].get("brief", []).size(), entries[-1].text]
	var state := GameState.match_state
	sig += ":%d" % (state.turn_number if state != null else 0)
	if sig == _signature:
		return
	_signature = sig
	_rebuild()


func focus_row() -> Control:
	return _focus


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_focus = null
	var entries := MatchLog.entries
	if entries.is_empty():
		add_child(_label("Nothing has happened yet.", UiStyle.MUTED, true))
		return
	var state := GameState.match_state
	var now: int = state.turn_number if state != null and state.phase != "ended" else 1 << 30
	var turns: Array[int] = []
	for e in entries:
		if turns.is_empty() or turns[-1] != e.turn:
			turns.append(e.turn)
	var first: int = turns[maxi(0, turns.size() - MAX_TURNS)]
	if first != turns[0]:
		add_child(_label("Earlier turns are not shown.", UiStyle.MUTED, true))
	var last_done := -1
	for t in turns:
		if t < now:
			last_done = t
	var rows: VBoxContainer = null
	var turn := -1
	for e in entries:
		if e.turn < first:
			continue
		if e.turn != turn:
			turn = e.turn
			rows = _turn_block(e, turn == last_done, turn == now)
		if _is_quiet(e):
			continue
		if e.get("kind") != "turn":
			rows.add_child(_entry(e))
		else:
			for brief in _merged(e.get("brief", [])):
				rows.add_child(_flow(brief, true))


# Results that say the same of several characters share one row: their symbols, then the words.
static func _merged(briefs: Array) -> Array:
	var out: Array = []
	for b in briefs:
		var single: bool = b.size() == 2 and b[0].get("t") == "char" and b[1].get("t") == "text"
		var last: Array = out[-1] if not out.is_empty() else []
		if single and last.size() >= 2 and last[-1].get("t") == "text" and last[-1].s == b[1].s \
				and last.slice(0, -1).all(func(p): return p.get("t") == "char"):
			last.insert(last.size() - 1, b[0])
		else:
			out.append(b.duplicate())
	return out


# Ending the turn says nothing the next turn's heading doesn't.
static func _is_quiet(e: Dictionary) -> bool:
	var parts: Array = e.get("parts", [])
	return parts.size() == 1 and parts[0].get("s", "") == "Ends turn" and e.get("brief", []).is_empty() and not e.failed


func _turn_block(e: Dictionary, last: bool, current: bool) -> VBoxContainer:
	var color: Color = color_for.call(e.player)
	var panel := PanelContainer.new()
	var box := UiStyle.box(UiStyle.CONTROL if last else UiStyle.PANEL, Color(color, 0.9 if last or current else 0.5), 0)
	box.border_width_left = 8 if last else 6
	box.content_margin_left = UiStyle.GAP + 8
	box.content_margin_right = UiStyle.GAP
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", box)
	panel.set_meta("log_turn", e.turn)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	panel.add_child(rows)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.GAP)
	var title := _label("Turn %d · %s" % [e.turn, _player_label(e.player)], color, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	if last or current:
		head.add_child(_label("Last turn" if last else "Now", UiStyle.HEADING if last else UiStyle.MUTED))
	rows.add_child(head)
	add_child(panel)
	if last:
		_focus = panel
	return rows


# One action: its compact row, its key results under it, and its full record on a tap.
func _entry(e: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.set_meta("log_entry", e.text)
	var parts: Array = e.get("parts", [])
	box.add_child(_flow(parts, false) if not parts.is_empty() else _label(e.text, UiStyle.TEXT, true))
	for brief in _merged(e.get("brief", [])):
		box.add_child(_flow(brief, true))
	var full := _label("\n".join([e.text] + Array(e.lines)), UiStyle.MUTED, true)
	full.visible = false
	full.set_meta("log_full", true)
	box.add_child(full)
	var press := {"at": Vector2.ZERO}
	box.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				press.at = event.position
			elif event.position.distance_to(press.at) < 24.0:
				full.visible = not full.visible
				box.accept_event())
	return box


func _flow(parts: Array, result: bool) -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 4)
	flow.mouse_filter = Control.MOUSE_FILTER_PASS
	if result:
		var indent := Control.new()
		indent.custom_minimum_size = Vector2(BADGE * 0.5, 0)
		indent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flow.add_child(indent)
	for p in parts:
		match str(p.get("t", "")):
			"char":
				flow.add_child(_badge(p, result))
			"card":
				flow.add_child(_card_link(p))
			"player":
				flow.add_child(_label(_player_label(str(p.id)), color_for.call(str(p.id))))
			_:
				var s := str(p.get("s", ""))
				var color := UiStyle.MUTED if result else UiStyle.TEXT
				if s == "defeated" or s == "failed" or (s.begins_with("-") and s.substr(1).is_valid_int()):
					color = DAMAGE
				flow.add_child(_label(s, color))
	return flow


func _badge(p: Dictionary, small: bool) -> Control:
	var b := LogBadge.new()
	b.type = str(p.get("type", ""))
	b.team = color_for.call(str(p.get("player", "")))
	b.custom_minimum_size = Vector2.ONE * (BADGE * 0.8 if small else BADGE)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.tooltip_text = str(p.get("name", ""))
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	return b


func _card_link(p: Dictionary) -> Button:
	var b := Button.new()
	b.text = str(p.get("name", ""))
	b.tooltip_text = "Show %s" % b.text
	b.flat = true
	b.custom_minimum_size.y = UiStyle.ICON_SIZE
	b.add_theme_font_size_override("font_size", UiStyle.FONT_SECONDARY)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, UiStyle.BRASS if state != "font_hover_color" else UiStyle.HEADING)
	var line := UiStyle.box(Color(0, 0, 0, 0), UiStyle.BRASS, 0)
	line.border_width_bottom = 2
	line.content_margin_left = 4
	line.content_margin_right = 4
	for style in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(style, line)
	b.set_meta("log_card", str(p.get("id", "")))
	var id := str(p.get("id", ""))
	b.pressed.connect(func(): card_pressed.emit(id))
	return b


func _player_label(player_id: String) -> String:
	return "Player 1" if player_id == "p1" else ("Player 2" if player_id == "p2" else player_id)


# Tokens in a row stay whole (the row wraps between them); notes and records wrap.
func _label(text: String, color: Color, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", UiStyle.FONT_SECONDARY)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


# A character: its type symbol in the type's color, ringed in its team's color.
class LogBadge:
	extends Control
	var type := ""
	var team := Color.WHITE

	func _draw() -> void:
		var r := minf(size.x, size.y) * 0.5
		var c := size * 0.5
		draw_circle(c, r, Color(0.03, 0.035, 0.035, 0.92))
		draw_arc(c, r * 0.9, 0.0, TAU, 40, team, maxf(2.0, r * 0.18), true)
		TypeIcon.draw_symbol(self, type, c, r * 0.5, GameBoardView.ROLE_COLORS.get(type, UiStyle.TEXT), maxf(1.5, r * 0.12))
