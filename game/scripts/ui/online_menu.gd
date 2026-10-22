class_name OnlineMenu
extends Control
# Play a friend online (LLD-network-match.md 3.6): create a match as either team, join one
# with its 6-letter code, or pick up a saved one. The menu only asks; the game screen runs
# the NetSession and reports back with show_message() or show_invite().

signal create_requested(team_id: String)
signal join_requested(code: String)
signal open_requested(code: String)
signal closed

const MAX_WIDTH := 720.0
const CODE_LENGTH := 6

var transport: NetTransport          # reads each saved match's status when the menu opens
var busy := false                    # a request is out: the commands are off

var _column := VBoxContainer.new()
var _message := Label.new()
var _code_edit := LineEdit.new()
var _join: Button
var _invite := VBoxContainer.new()   # after Create: the code, Copy invite, Continue
var _invite_label := Label.new()
var _invite_code := ""
var _list := VBoxContainer.new()
var _commands: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim := ColorRect.new()
	dim.color = UiStyle.BG
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_column.add_theme_constant_override("separation", UiStyle.GAP)
	add_child(_column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", UiStyle.GAP)
	var heading := UiStyle.heading("Play a friend online")
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(heading)
	header.add_child(UiStyle.icon_button("close", "Close", close))
	_column.add_child(header)

	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_color_override("font_color", Color("#ff9d6b"))
	_message.visible = false
	_column.add_child(_message)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", UiStyle.GAP)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	_column.add_child(scroll)

	# After Create: the code to send, in large type, with the invite one tap away.
	_invite.add_theme_constant_override("separation", UiStyle.GAP)
	_invite.visible = false
	_invite_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_invite_label.add_theme_color_override("font_color", UiStyle.HEADING)
	_invite.add_child(_invite_label)
	_invite.add_child(UiStyle.command("Copy invite", func():
		DisplayServer.clipboard_set(invite_text(_invite_code))
		_invite_label.text = _invite_text_label() + "\nCopied."))
	_invite.add_child(UiStyle.primary(UiStyle.command("Continue to deployment", close, "command:primary")))
	content.add_child(_invite)

	content.add_child(_section("Start a match"))
	var teams := ContentDB.get_matchup()
	for team_id in teams:
		var id := str(team_id)
		var team_name := str(ContentDB.get_team(id).get("name", id))
		content.add_child(_command(UiStyle.command("Create as %s" % team_name, func(): _ask(create_requested, id))))

	content.add_child(_section("Join a friend's match"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiStyle.GAP)
	_code_edit.placeholder_text = "Code"
	_code_edit.max_length = CODE_LENGTH
	_code_edit.custom_minimum_size = Vector2(0, UiStyle.CONTROL_HEIGHT)
	_code_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_code_edit.add_theme_font_size_override("font_size", UiStyle.FONT_BODY)
	_code_edit.text_changed.connect(func(_t): _refresh_join())
	_code_edit.text_submitted.connect(func(_t): _on_join())
	row.add_child(_code_edit)
	_join = _command(UiStyle.command("Join", _on_join))
	_join.custom_minimum_size.x = 200
	row.add_child(_join)
	content.add_child(row)

	content.add_child(_section("Your matches"))
	_list.add_theme_constant_override("separation", UiStyle.GAP)
	content.add_child(_list)

	resized.connect(_fit)
	_fit()


# Shows the menu; `code` fills the join box (an invite link's ?room=).
func open(code: String = "") -> void:
	visible = true
	busy = false
	_invite.visible = false
	show_message("")
	_code_edit.text = normalize_code(code)
	_refresh_join()
	_refresh_list()
	_fit()


func close() -> void:
	if visible:
		visible = false
		closed.emit()


func show_message(text: String) -> void:
	busy = false
	_message.text = text
	_message.visible = text != ""
	_refresh_join()


# After a match is created: the code to send your friend.
func show_invite(code: String) -> void:
	busy = false
	show_message("")
	_invite_code = code
	_invite_label.text = _invite_text_label()
	_invite.visible = true


# "abc def" -> "ABCDEF": what a player types or pastes, as the server expects it.
static func normalize_code(text: String) -> String:
	var out := ""
	for ch in text.to_upper():
		if ch >= "A" and ch <= "Z":
			out += ch
	return out.left(CODE_LENGTH)


# The text "Copy invite" puts on the clipboard. On the web it's this page with ?room=CODE.
static func invite_text(code: String) -> String:
	var url := page_url()
	if url != "":
		return "Play MythCards with me: %s?room=%s (code %s)" % [url, code, code]
	return "Play MythCards with me. Open Play a friend online and join with code %s." % code


static func page_url() -> String:
	if not OS.has_feature("web"):
		return ""
	return str(JavaScriptBridge.eval("location.origin + location.pathname", true))


# The ?room= code of the page's URL on the web, or "".
static func room_param() -> String:
	if not OS.has_feature("web"):
		return ""
	return normalize_code(str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('room') || ''", true)))


# A saved match's line in "Your matches", from one fetch of its log (or none: `body` = {}).
static func status_text(saved: Dictionary, body: Dictionary, build: String) -> String:
	if saved.get("ended", false):
		return "Ended"
	if str(saved.get("version", "")) != build:
		return "Started on another build"
	if body.is_empty():
		return "Can't reach the server"
	match str(body.get("status", "")):
		"waiting_for_join":
			return "Waiting for your friend to join"
		"deploying":
			for e in body.get("entries", []):
				if e.get("kind", "") == "deploy" and e.get("seat", "") == saved.seat:
					return "Waiting for your friend to deploy"
			return "Deploy your squad"
	# Player 1 goes first and each end_turn passes play (a drawn card's choice can briefly
	# belong to the other seat; the list doesn't replay the match to find that out).
	var turns := 0
	for e in body.get("entries", []):
		if e.get("kind", "") == "action" and e.action.get("action_type", "") == "end_turn":
			turns += 1
	var active := "p1" if turns % 2 == 0 else "p2"
	return "Your turn" if active == saved.seat else "Their turn"


func _refresh_list() -> void:
	for child in _list.get_children():
		child.queue_free()
	var seats := NetStore.seats()
	if seats.is_empty():
		_list.add_child(UiStyle.counter("No matches yet."))
		return
	for saved in seats:
		var code: String = saved.code
		var team := str(ContentDB.get_team(str(saved.team_id)).get("name", saved.team_id))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UiStyle.GAP)
		var b := _command(UiStyle.choice("%s · %s\nChecking…" % [code, team], func(): _ask(open_requested, code), "choice:match"))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
		var remove := UiStyle.command("Remove", func():
			NetStore.forget(code)
			_refresh_list())
		remove.custom_minimum_size.x = 160
		row.add_child(remove)
		_list.add_child(row)
		_fill_status(b, saved, "%s · %s" % [code, team])


func _fill_status(b: Button, saved: Dictionary, title: String) -> void:
	var body := {}
	if transport != null and not saved.get("ended", false):
		var r: Dictionary = await transport.fetch_log(saved.code, saved.token, 0)
		if r.ok:
			body = r.body
	if is_instance_valid(b):
		b.text = "%s\n%s" % [title, status_text(saved, body, NetSession.version())]


func _on_join() -> void:
	var code := normalize_code(_code_edit.text)
	if code.length() == CODE_LENGTH:
		_ask(join_requested, code)


func _ask(sig: Signal, value: String) -> void:
	if busy:
		return
	busy = true
	_message.text = "Connecting…"
	_message.visible = true
	_refresh_join()
	sig.emit(value)


func _refresh_join() -> void:
	if _join == null:
		return
	for b in _commands:
		b.disabled = busy
	_join.disabled = busy or normalize_code(_code_edit.text).length() != CODE_LENGTH


func _invite_text_label() -> String:
	return "Match created. Your code is %s.\nSend it to your friend, then place your squad. You can deploy before they join." % _invite_code


func _command(b: Button) -> Button:
	_commands.append(b)
	return b


func _section(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", UiStyle.FONT_SECONDARY)
	l.add_theme_color_override("font_color", UiStyle.MUTED)
	return l


func _fit() -> void:
	var w := minf(MAX_WIDTH, size.x - UiStyle.PAGE_INSET * 2.0)
	_column.position = Vector2((size.x - w) / 2.0, UiStyle.PAGE_INSET)
	_column.size = Vector2(w, size.y - UiStyle.PAGE_INSET * 2.0)
