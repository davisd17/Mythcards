class_name FigureCatalog
extends RefCounted
# Cosmetic-only board figures. This catalog is deliberately separate from CharacterData
# and MatchState so an outfit can never change rules, stats, placement, or selection.

const CATALOG_PATH := "res://assets/figures/wardrobe.json"

static var _catalog: Dictionary = {}
static var _textures: Dictionary = {}


static func outfits(character_id: String) -> Array:
	_ensure_loaded()
	var entries = _catalog.get(character_id, [])
	return entries if entries is Array else []


static func has_figure(character_id: String) -> bool:
	return not outfits(character_id).is_empty()


static func default_outfit_id(character_id: String) -> String:
	var entries := outfits(character_id)
	return str(entries[0].get("id", "default")) if not entries.is_empty() else ""


static func next_outfit_id(character_id: String, current_id: String) -> String:
	var entries := outfits(character_id)
	if entries.is_empty():
		return ""
	for i in entries.size():
		if str(entries[i].get("id", "")) == current_id:
			return str(entries[(i + 1) % entries.size()].get("id", ""))
	return str(entries[0].get("id", ""))


static func outfit_name(character_id: String, outfit_id: String) -> String:
	var entry := _entry(character_id, outfit_id)
	return str(entry.get("name", outfit_id))


static func texture_for(character_id: String, outfit_id: String) -> Texture2D:
	var entry := _entry(character_id, outfit_id)
	var path := str(entry.get("texture", ""))
	if path == "":
		return null
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D
	return _textures[path]


# Phase 6 (LLD-figure-animation.md 8): an outfit's hand-drawn attack sequence, as
# [{texture: Texture2D, seconds: float, impact: bool}], or [] to use the procedural
# wind-up. Frames share the default figure's canvas and foot anchor (y 756), so they are
# drawn with the default figure's transform, never fitted one by one.
static func attack_frames(character_id: String, outfit_id: String) -> Array:
	return _frames(character_id, outfit_id, "attack")


# The outfit's three Ember-claim poses (gather, hold, settle), in the same form and on the
# same canvas as attack_frames, or [] for the procedural stretch (claim spec 4A, 7).
static func claim_frames(character_id: String, outfit_id: String) -> Array:
	return _frames(character_id, outfit_id, "claim")


static func _frames(character_id: String, outfit_id: String, key: String) -> Array:
	var result := []
	var frames = _entry(character_id, outfit_id).get(key, [])
	if not frames is Array:
		return result
	for f in frames:
		var path := str(f.get("texture", ""))
		if not _textures.has(path):
			_textures[path] = load(path) as Texture2D
		if _textures[path] == null:
			return []   # a missing frame falls back to the procedural wind-up
		result.append({"texture": _textures[path], "seconds": float(f.get("ms", 100)) / 1000.0,
				"impact": bool(f.get("impact", false))})
	return result


# Loads every outfit's attack frames up front. Loading them on a figure's first attack
# stalled that frame long enough to skip the wind-up (web build, 2026-10-15).
static func preload_attack_frames() -> void:
	_ensure_loaded()
	for character_id in _catalog:
		for entry in outfits(character_id):
			if entry is Dictionary:
				attack_frames(character_id, str(entry.get("id", "")))
				claim_frames(character_id, str(entry.get("id", "")))


# {length, impact} in seconds for an outfit's attack art, or {} when it has none. The
# impact is when the impact frame (the shot, the blow) appears.
static func attack_timing(character_id: String, outfit_id: String) -> Dictionary:
	var frames := attack_frames(character_id, outfit_id)
	if frames.is_empty():
		return {}
	var length := 0.0
	var impact := -1.0
	for f in frames:
		if f.impact and impact < 0.0:
			impact = length
		length += f.seconds
	return {"length": length, "impact": maxf(impact, 0.0)}


static func _entry(character_id: String, outfit_id: String) -> Dictionary:
	for entry in outfits(character_id):
		if entry is Dictionary and str(entry.get("id", "")) == outfit_id:
			return entry
	return {}


static func _ensure_loaded() -> void:
	if not _catalog.is_empty():
		return
	if not FileAccess.file_exists(CATALOG_PATH):
		push_error("FigureCatalog: missing %s" % CATALOG_PATH)
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if parsed is Dictionary:
		_catalog = parsed
	else:
		push_error("FigureCatalog: wardrobe catalog must be a JSON object")
