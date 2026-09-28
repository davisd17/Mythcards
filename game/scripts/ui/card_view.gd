class_name CardView
extends PanelContainer
# One card, as the game screen shows it: art when data/cards/card_art.json maps one
# (tools/sync_game_content.ps1 copies it in), otherwise a text-card placeholder with the
# card's name and type. Below it, the card's rules text. Used for characters (with live
# stats when an instance is given) and for relic/event cards.

const ART_DIR := "res://data/card_art/"
const FACTION_COLORS := {"Russian-inspired": Color("#8c2f39"), "Russian-Inspired": Color("#8c2f39"),
		"Atlantean": Color("#1f6f8b")}

static var _art_cache: Dictionary = {}

var compact := false   # smaller art for the side panel

var _art := TextureRect.new()
var _placeholder := PanelContainer.new()
var _placeholder_label := Label.new()
var _title := Label.new()
var _subtitle := Label.new()
var _body := RichTextLabel.new()


# The card's art, or null if it has none.
static func art_for(card_id: String) -> Texture2D:
	if _art_cache.has(card_id):
		return _art_cache[card_id]
	var texture: Texture2D = null
	var path := ART_DIR + card_id + ".art"
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load_jpg_from_buffer(FileAccess.get_file_as_bytes(path)) == OK:
			texture = ImageTexture.create_from_image(image)
	_art_cache[card_id] = texture
	return texture


func _init(p_compact: bool = false) -> void:
	compact = p_compact


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#23211d")
	style.border_color = Color("#c9a45c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)

	var art_height := 150.0 if compact else 360.0
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.custom_minimum_size = Vector2(0, art_height)
	_art.clip_contents = true
	box.add_child(_art)

	_placeholder.custom_minimum_size = Vector2(0, art_height)
	_placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_placeholder_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_placeholder_label.add_theme_font_size_override("font_size", 22 if compact else 34)
	_placeholder.add_child(_placeholder_label)
	box.add_child(_placeholder)

	_title.add_theme_font_size_override("font_size", 22 if compact else 30)
	_title.add_theme_color_override("font_color", Color("#f3e3b5"))
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_title)
	_subtitle.add_theme_font_size_override("font_size", 16 if compact else 20)
	_subtitle.add_theme_color_override("font_color", Color("#b8ad92"))
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_subtitle)

	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.scroll_active = false
	_body.add_theme_font_size_override("normal_font_size", 16 if compact else 20)
	_body.add_theme_font_size_override("bold_font_size", 16 if compact else 20)
	box.add_child(_body)


func show_character(data: CharacterData, instance: CharacterInstance = null) -> void:
	_set_art(data.id, data.char_name, data.type, FACTION_COLORS.get(data.culture, Color.DIM_GRAY))
	_title.text = data.char_name
	var level := instance.level if instance != null else 1
	_subtitle.text = "%s · %s · Level %d" % [data.type, data.culture, level]
	var lines: Array[String] = []
	lines.append(_stat_line(data, instance))
	if instance != null:
		var extras := _status_text(instance)
		if extras != "":
			lines.append(extras)
	for i in 3:
		var text: String = [data.l1, data.l2, data.l3][i]
		var marker := "[b][color=#f3e3b5]L%d (now)[/color][/b]" % (i + 1) if i + 1 == level else "[color=#8a826f]L%d[/color]" % (i + 1)
		var color := "#e8e2d2" if i + 1 <= level else "#8a826f"
		lines.append("%s [color=%s]%s[/color]" % [marker, color, text])
	_body.text = "\n".join(lines)


func show_relic_event(card_id: String) -> void:
	var card := ContentDB.get_relic_event(card_id)
	if card == null:
		_title.text = card_id
		_subtitle.text = ""
		_body.text = ""
		return
	_set_art(card_id, card.card_name, card.kind, FACTION_COLORS.get(card.faction, Color.DIM_GRAY))
	_title.text = card.card_name
	_subtitle.text = "%s · %s · %s" % [card.kind, card.duration, card.sub_area]
	_body.text = card.effect


func _set_art(card_id: String, card_name: String, kind: String, color: Color) -> void:
	var texture := art_for(card_id)
	_art.texture = texture
	_art.visible = texture != null
	_placeholder.visible = texture == null
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.35)
	style.set_corner_radius_all(6)
	_placeholder.add_theme_stylebox_override("panel", style)
	_placeholder_label.text = "%s\n\n%s" % [card_name, kind.to_upper()]


static func _stat_line(data: CharacterData, instance: CharacterInstance) -> String:
	if instance == null or GameState.match_state == null:
		return "[b]HP %d · ATK %d · MOVE %d · RANGE %d[/b]" % [data.hp, data.atk, data.move, data.range]
	var sys: AbilitySystem = RulesEngine.systems().ability
	var hp_max := sys.get_effective_max_hp(instance)
	var atk := instance.get_effective_atk() + sys.get_conditional_atk_bonus(instance)
	var rng := instance.get_effective_range("attack", sys.get_conditional_range_bonus(instance, "attack"))
	var line := "[b]HP %d/%d · ATK %d · MOVE %d · RANGE %d[/b]" % [instance.current_hp, hp_max, atk,
			instance.get_effective_move(), rng]
	if instance.defeated:
		line += "  [color=#e06666]DEFEATED[/color]"
	return line


static func _status_text(instance: CharacterInstance) -> String:
	var parts: Array[String] = []
	parts.append("AP %d/%d" % [instance.character_ap_remaining, instance.character_ap_max])
	if instance.spirit_ember_count > 0:
		parts.append("Spirit Ember ×%d" % instance.spirit_ember_count)
	if instance.is_mounted_rider and GameState.match_state != null:
		var mount_char := GameState.match_state.find_character(instance.mounted_with_id)
		if mount_char != null:
			parts.append("riding %s (move AP %d/%d)" % [mount_char.data.char_name,
					mount_char.character_ap_remaining, mount_char.character_ap_max])
	for se in instance.status_effects:
		parts.append(GameBoardView.status_name(se))
	return "[color=#9fd3e6]%s[/color]" % " · ".join(parts)
