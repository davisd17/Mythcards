class_name MountedFigureCatalog
extends RefCounted
# Presentation-only rider/mount combinations; never written into match state.

const PATH := "res://assets/figures/mounted/catalog.json"
static var _entries: Dictionary = {}
static var _textures: Dictionary = {}


static func entries() -> Dictionary:
	if _entries.is_empty() and FileAccess.file_exists(PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			_entries = parsed
	return _entries


static func key_for(c: CharacterInstance, outfit_id := "default") -> String:
	if c == null or c.data == null or not c.is_mounted_rider or GameState.match_state == null:
		return ""
	var mount_char := GameState.match_state.find_character(c.mounted_with_id)
	if mount_char == null or mount_char.data == null:
		return ""
	for key in entries():
		var e: Dictionary = entries()[key]
		if e.rider == c.data.id and e.mount == mount_char.data.id and e.get("outfit", "default") == outfit_id:
			return key
	return ""


static func _texture(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D
	return _textures[path]


static func texture_for(key: String) -> Texture2D:
	return _texture(str(entries().get(key, {}).get("texture", "")))


static func attack_frames(key: String) -> Array:
	var result := []
	for frame in entries().get(key, {}).get("attack", []):
		var texture := _texture(str(frame.get("texture", "")))
		if texture == null:
			return []
		result.append({"texture": texture, "seconds": float(frame.ms) / 1000.0,
			"impact": bool(frame.get("impact", false))})
	return result


static func attack_timing(key: String) -> Dictionary:
	var frames := attack_frames(key)
	if frames.is_empty():
		return {}
	var length := 0.0
	var impact := 0.0
	for frame in frames:
		if frame.impact:
			impact = length
		length += frame.seconds
	return {"length": length, "impact": impact, "mounted_key": key}


static func preload_art() -> void:
	for key in entries():
		texture_for(key)
		attack_frames(key)
