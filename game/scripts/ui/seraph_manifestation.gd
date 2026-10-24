class_name SeraphManifestation
extends RefCounted
# Presentation only: the existing ability flag is authoritative, never the outfit.

const CHARACTER_ID := "a-flood-survivor-thalassa-nekh"
const ABILITY_ID := CHARACTER_ID + "_l3"
const TEXTURE_PATH := "res://assets/figures/a-flood-survivor-thalassa-nekh/seraph-entity-v2.png"
const REVEAL_TIME := 0.60
const REST_ALPHA := 0.58
static var _texture: Texture2D


static func is_active(c: CharacterInstance) -> bool:
	return c != null and c.data != null and c.data.id == CHARACTER_ID \
			and bool(c.ability_uses_this_match.get("seraph_form", false))


static func texture() -> Texture2D:
	if _texture == null:
		_texture = load(TEXTURE_PATH) as Texture2D
	return _texture


static func opacity(c: CharacterInstance, fx: BoardFx, motion: bool) -> float:
	if not is_active(c):
		return 0.0
	var alpha := REST_ALPHA
	var l: Dictionary = fx.lunges.get(c.instance_id, {})
	if motion and not l.is_empty():
		# Follow the registered impact, not a second gameplay timer.
		var impact := float(fx.attack_art.call(c.instance_id).get("impact", 0.0)) if fx.attack_art.is_valid() else 0.0
		var distance := absf(fx.now - float(l.start) - impact)
		alpha += 0.30 * maxf(0.0, 1.0 - distance / 0.15)
	if motion and fx.manifestations.has(c.instance_id):
		alpha *= fx.progress(fx.manifestations[c.instance_id], REVEAL_TIME)
	return alpha


# Fit only the spirit. The human's normal figure rect and foot anchor never change.
static func local_rect(human: Rect2, available_height: float, shoulder_side := 1.0) -> Rect2:
	var height := minf(human.size.y * 1.42, maxf(1.0, available_height))
	var width := height * 2.0 / 3.0
	# At the back edge its face would be hidden by the vessel: peek over a shoulder.
	var offset := human.size.x * 0.55 * shoulder_side if height < human.size.y * 1.15 else 0.0
	return Rect2(Vector2(-width * 0.5 + offset, -height), Vector2(width, height))
