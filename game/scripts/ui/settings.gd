class_name Settings
extends RefCounted
# Player presentation settings: sound, motion, vibration. Presentation only; saved to
# user://settings.cfg so they survive a restart. "motion" covers the board's ambience
# (Phase 4) and the figures' idle animation (Phase 5): one toggle, designer 2026-10-14.
# Action animations always play, because they show what happened.

const PATH := "user://settings.cfg"

static var sound := true
static var motion := true
static var haptics := true


static func load_saved() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	sound = bool(cfg.get_value("presentation", "sound", true))
	# "atmosphere" was this toggle's name before 2026-10-14.
	motion = bool(cfg.get_value("presentation", "motion", cfg.get_value("presentation", "atmosphere", true)))
	haptics = bool(cfg.get_value("presentation", "haptics", true))


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("presentation", "sound", sound)
	cfg.set_value("presentation", "motion", motion)
	cfg.set_value("presentation", "haptics", haptics)
	cfg.save(PATH)


# By name, for the menu toggles: "sound", "motion", or "haptics".
static func value(field: String) -> bool:
	match field:
		"sound": return sound
		"motion": return motion
		"haptics": return haptics
	return false


static func toggle(field: String) -> void:
	match field:
		"sound": sound = not sound
		"motion": motion = not motion
		"haptics": haptics = not haptics
	save()
