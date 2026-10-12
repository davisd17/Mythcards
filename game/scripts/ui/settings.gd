class_name Settings
extends RefCounted
# Player presentation settings (Visual Polish Phase 4): sound, ambient motion, vibration.
# Presentation only; saved to user://settings.cfg so they survive a restart.

const PATH := "user://settings.cfg"

static var sound := true
static var atmosphere := true
static var haptics := true


static func load_saved() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	sound = bool(cfg.get_value("presentation", "sound", true))
	atmosphere = bool(cfg.get_value("presentation", "atmosphere", true))
	haptics = bool(cfg.get_value("presentation", "haptics", true))


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("presentation", "sound", sound)
	cfg.set_value("presentation", "atmosphere", atmosphere)
	cfg.set_value("presentation", "haptics", haptics)
	cfg.save(PATH)


# By name, for the menu toggles: "sound", "atmosphere", or "haptics".
static func value(field: String) -> bool:
	match field:
		"sound": return sound
		"atmosphere": return atmosphere
		"haptics": return haptics
	return false


static func toggle(field: String) -> void:
	match field:
		"sound": sound = not sound
		"atmosphere": atmosphere = not atmosphere
		"haptics": haptics = not haptics
	save()
