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
