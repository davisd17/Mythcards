class_name HowToPlay
extends Control
# How to play: a beginner's walkthrough of the rules, one short page at a time, opened from
# the New match screen or Menu. Portrait first: the page scrolls, Back and Next stay at the
# bottom in thumb reach. Underlined terms open their glossary definition (term_pressed).

signal term_pressed(id: String)
signal closed

const MAX_WIDTH := 720.0   # one portrait page; wide windows center it

# Each page: a title, a diagram scene (HowToDiagram, "" for none) and short paragraphs.
const PAGES := [
	{"title": "Welcome to MythCards", "scene": "board",
	 "body": ["Two squads face off on a 7x7 board. You take turns moving, attacking and using abilities.",
		"There are three ways to win:",
		"• Hero capture: trap the enemy Hero so it has no legal move.",
		"• Spirit Embers: bank 4 Embers on the glowing center tile.",
		"• Army defeat: defeat every enemy character.",
		"Tap Next to learn the basics. It takes about two minutes."]},
	{"title": "Your squad", "scene": "squad",
	 "body": ["Each side has 7 characters, one of each type: Leader, Hero, Mount, Specialist, Warrior, Common and Mystic.",
		"Each type has its own symbol, shown on its piece and on its card.",
		"Your Hero is your most important piece. Keep it safe and keep it free to move.",
		"Every character has HP (how much damage it can take), ATK (its attack damage), MOVE and RANGE. Its card also lists its abilities.",
		"Tap any character to read its card."]},
	{"title": "Setting up", "scene": "setup",
	 "body": ["Before the match, each player places all 7 characters on their own back row: the bottom row for Player 1, the top row for Player 2.",
		"Pick a character from the list, then tap a highlighted tile. Tap a placed character to pick it up again.",
		"Not sure where to start? Tap Auto-place the rest, then Done placing."]},
	{"title": "Your turn", "scene": "ap",
	 "body": ["Each turn you get 4 AP (action points), shown as pips at the top of the screen. The first player's very first turn gets 2.",
		"Moving, attacking and using an ability each cost 1 AP.",
		"Most characters can act only once per turn, so you can't use everyone. Choose the moves that matter most.",
		"When you're done, tap End turn. Unused AP doesn't carry over."]},
	{"title": "Moving", "scene": "move",
	 "body": ["Tap one of your characters to select it. Green dots show where it can move.",
		"Characters move in a straight line, up, down, left or right, as far as their MOVE. They can't pass through other characters or objects that block the way.",
		"Tap a dot to move there."]},
	{"title": "Attacking", "scene": "attack",
	 "body": ["Red rings show enemies your selected character can attack. Tap one to attack it.",
		"Attacks reach in a straight line, up to the character's RANGE, and need line of sight: a character or object in between blocks the shot.",
		"An attack deals the attacker's ATK as damage. A character with no HP left is defeated and leaves the board."]},
	{"title": "Abilities and levels", "scene": "level",
	 "body": ["A selected character's abilities appear as buttons next to its summary. A Passive is always on; an AP Ability costs 1 AP.",
		"Characters grow stronger as they level up:",
		"• Level 2: reach the opponent's back row.",
		"• Level 3: defeat an enemy while at Level 2.",
		"Each level-up restores full HP and improves the character's abilities. Read its card to see how."]},
	{"title": "Relics and events", "scene": "cards",
	 "body": ["At the start of each turn, the active player draws one card from a shared deck.",
		"A relic stays with you and gives a lasting bonus or a power you can use. You hold one relic at a time; draw another and you choose which to keep.",
		"An event happens at once or stays in effect for a while.",
		"Cards in play lie face up above the board. Tap one to read it."]},
	{"title": "Spirit Embers", "scene": "embers",
	 "body": ["When a character defeats an enemy, it takes that enemy's Spirit Ember, plus any Embers the enemy was carrying.",
		"Carry Embers to the glowing center tile to bank them. The first team to bank 4 wins.",
		"A character carrying Embers is a big target, so protect your carriers and hunt theirs."]},
	{"title": "Protect your Hero", "scene": "capture",
	 "body": ["If your Hero has no legal move at the end of your own turn, it's captured and you lose at once.",
		"Losing all its HP doesn't capture a Hero: it's defeated like any other character, and the match goes on.",
		"Don't box your Hero in with your own pieces. The game warns you before you end a turn with a trapped Hero."]},
	{"title": "Tips for your first match", "scene": "",
	 "body": ["• Tap any character to see its card. Tap the summary for the full card.",
		"• Long-press a piece or tile to see what everything on it means.",
		"• Tap an underlined word on a card for its definition.",
		"• Pinch to zoom the board. Double-tap to zoom back out.",
		"• The Log button lists everything that has happened.",
		"• Menu has the Glossary, a new match and sound settings.",
		"Start with a match against the AI. Good luck!"]},
]

var page := 0
var _column := VBoxContainer.new()
var _step := Label.new()
var _scroll := ScrollContainer.new()
var _title := Label.new()
var _diagram := HowToDiagram.new()
var _body := RichTextLabel.new()
var _back: Button
var _next: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim := ColorRect.new()
	dim.color = UiStyle.BG   # opaque: the page reads cleanly over the board
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_column.add_theme_constant_override("separation", UiStyle.GAP)
	add_child(_column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", UiStyle.GAP)
	var heading := UiStyle.heading("How to play")
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(heading)
	_step.add_theme_font_size_override("font_size", UiStyle.FONT_SECONDARY)
	_step.add_theme_color_override("font_color", UiStyle.MUTED)
	_step.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_step)
	header.add_child(UiStyle.icon_button("close", "Close", close))
	_column.add_child(header)
	_column.add_child(_progress())

	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", UiStyle.SECTION_GAP)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_font_size_override("font_size", UiStyle.FONT_HEADING)
	_title.add_theme_color_override("font_color", UiStyle.HEADING)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_title)
	_diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_diagram)
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.scroll_active = false
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.mouse_filter = Control.MOUSE_FILTER_PASS   # drags still scroll the page
	_body.add_theme_font_size_override("normal_font_size", UiStyle.FONT_BODY)
	_body.add_theme_font_size_override("bold_font_size", UiStyle.FONT_BODY)
	_body.add_theme_constant_override("paragraph_separation", 12)
	_body.meta_clicked.connect(func(meta): term_pressed.emit(str(meta)))
	content.add_child(_body)
	_scroll.add_child(content)
	_column.add_child(_scroll)

	# Back and Next share the row equally; Next is the page's one primary command.
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", UiStyle.GAP)
	_back = UiStyle.command("Back", func(): show_page(page - 1))
	_back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_back)
	_next = UiStyle.primary(UiStyle.command("Next", _on_next, "command:primary"))
	_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_next)
	_column.add_child(footer)

	resized.connect(_fit)
	_fit()


func open() -> void:
	visible = true
	show_page(0)
	_fit()


func close() -> void:
	if visible:
		visible = false
		closed.emit()


func show_page(index: int) -> void:
	page = clampi(index, 0, PAGES.size() - 1)
	var p: Dictionary = PAGES[page]
	_step.text = "%d of %d" % [page + 1, PAGES.size()]
	_title.text = p.title
	_diagram.scene = p.scene
	_diagram.visible = p.scene != ""
	_diagram.queue_redraw()
	var used := {}
	var paragraphs := []
	for line in p.body:
		paragraphs.append(Glossary.link(str(line), used))
	_body.text = "\n".join(paragraphs)
	_back.disabled = page == 0
	_next.text = "Done" if page == PAGES.size() - 1 else "Next"
	_scroll.scroll_vertical = 0
	var bar := _column.get_child(1)
	if bar != null:
		bar.queue_redraw()


func _on_next() -> void:
	if page == PAGES.size() - 1:
		close()
	else:
		show_page(page + 1)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
	elif event.is_action_pressed("ui_right"):
		_on_next()
	elif event.is_action_pressed("ui_left"):
		show_page(page - 1)
	else:
		return
	get_viewport().set_input_as_handled()


# The page column: at most one portrait page wide, centered, inside the page inset. The
# diagram stays square-ish and leaves at least half the height for the text.
func _fit() -> void:
	var w := minf(MAX_WIDTH, size.x - UiStyle.PAGE_INSET * 2.0)
	_column.position = Vector2((size.x - w) / 2.0, UiStyle.PAGE_INSET)
	_column.size = Vector2(w, size.y - UiStyle.PAGE_INSET * 2.0)
	_diagram.custom_minimum_size.y = clampf(minf(w, size.y * 0.4), 240.0, 440.0)


# A thin bar of one segment per page, filled in brass up to the current page.
func _progress() -> Control:
	var bar := Control.new()
	bar.custom_minimum_size.y = 6
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.draw.connect(func():
		var n := PAGES.size()
		var gap := 6.0
		var seg := (bar.size.x - gap * (n - 1)) / n
		for i in n:
			var color := UiStyle.BRASS if i <= page else UiStyle.BORDER_COLOR
			bar.draw_rect(Rect2(i * (seg + gap), 0, seg, bar.size.y), color))
	return bar
