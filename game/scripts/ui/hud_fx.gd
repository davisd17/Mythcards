class_name HudFx
extends RefCounted
# Visual Polish Phase 3 (LLD-hud-phase3.md): the HUD's moments. Each builds a node that
# ignores input, tweens itself, and frees itself, so none can block play or a tap.

const BANNER_IN := 0.15
const BANNER_HOLD := 0.75
const BANNER_OUT := 0.30
const FLY_IN := 0.22
const FLY_HOLD := 0.9           # an AI draw lingers at center long enough to see
const FLY_DOCK := 0.38
const CARD_SIZE := Vector2(150, 210)


# "Player 2's turn" across the middle of `parent`, in the player's color.
static func turn_banner(parent: Control, text: String, color: Color) -> Control:
	var banner := PanelContainer.new()
	banner.name = "TurnBanner"
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.04, 0.88)
	style.border_color = color
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.set_content_margin_all(14)
	banner.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", color.lightened(0.35))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(label)
	parent.add_child(banner)
	banner.set_anchors_preset(Control.PRESET_HCENTER_WIDE)
	banner.anchor_top = 0.40
	banner.anchor_bottom = 0.40
	banner.modulate.a = 0.0
	var tween := banner.create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, BANNER_IN)
	tween.tween_interval(BANNER_HOLD)
	tween.tween_property(banner, "modulate:a", 0.0, BANNER_OUT)
	tween.tween_callback(banner.queue_free)
	return banner


# A small copy of a relic/event card that appears at `from` (a screen point), optionally
# holds, then shrinks into `to` (the HUD chip it docks into) and frees itself.
static func card_flyer(parent: Control, card_id: String, from: Vector2, to: Rect2, hold: float) -> Control:
	var card := ContentDB.get_relic_event(card_id)
	var flyer := PanelContainer.new()
	flyer.name = "CardFlyer"
	flyer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#171c1b")
	style.border_color = Color("#c9a45c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(4)
	flyer.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flyer.add_child(box)
	var art := TextureRect.new()
	art.texture = CardView.art_for(card_id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.clip_contents = true
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(art)
	var label := Label.new()
	label.text = card.card_name if card != null else card_id
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color("#f3e3b5"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	parent.add_child(flyer)
	flyer.size = CARD_SIZE
	flyer.pivot_offset = CARD_SIZE * 0.5
	flyer.position = from - CARD_SIZE * 0.5
	flyer.scale = Vector2(0.6, 0.6)
	flyer.modulate.a = 0.0
	var tween := flyer.create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(flyer, "scale", Vector2.ONE, FLY_IN)
	tween.parallel().tween_property(flyer, "modulate:a", 1.0, FLY_IN)
	if hold > 0.0:
		tween.tween_interval(hold)
	tween.set_ease(Tween.EASE_IN)
	var end_scale := clampf(to.size.y / CARD_SIZE.y, 0.12, 0.5)
	tween.tween_property(flyer, "position", to.get_center() - CARD_SIZE * 0.5, FLY_DOCK)
	tween.parallel().tween_property(flyer, "scale", Vector2(end_scale, end_scale), FLY_DOCK)
	tween.parallel().tween_property(flyer, "modulate:a", 0.25, FLY_DOCK)
	tween.tween_callback(flyer.queue_free)
	return flyer


# The opening of a drawn card's full-size popup: a quick scale-and-fade into place.
static func pop_in(node: Control) -> void:
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2(0.86, 0.86)
	node.modulate.a = 0.0
	var tween := node.create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "scale", Vector2.ONE, FLY_IN)
	tween.parallel().tween_property(node, "modulate:a", 1.0, FLY_IN * 0.8)
