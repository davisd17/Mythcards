class_name Settings
extends RefCounted
# Player presentation settings: sound, music, motion, vibration. Presentation only; saved to
# user://settings.cfg so they survive a restart. "motion" covers the board's ambience
# (Phase 4) and the figures' idle animation (Phase 5): one toggle, designer 2026-10-14.
# Action animations always play, because they show what happened.

const PATH := "user://settings.cfg"

static var sound := true
static var music := true   # the match theme, separate from effects (designer 2026-10-17)
static var motion := true
static var haptics := true
static var lines := true   # Ember claim speech lines (claim spec 7)


static func load_saved() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	sound = bool(cfg.get_value("presentation", "sound", true))
	music = bool(cfg.get_value("presentation", "music", true))
	# "atmosphere" was this toggle's name before 2026-10-14.
	motion = bool(cfg.get_value("presentation", "motion", cfg.get_value("presentation", "atmosphere", true)))
	haptics = bool(cfg.get_value("presentation", "haptics", true))
	lines = bool(cfg.get_value("presentation", "lines", true))


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("presentation", "sound", sound)
	cfg.set_value("presentation", "music", music)
	cfg.set_value("presentation", "motion", motion)
	cfg.set_value("presentation", "haptics", haptics)
	cfg.set_value("presentation", "lines", lines)
	cfg.save(PATH)


# By name, for the menu toggles: "sound", "music", "motion", "haptics", or "lines".
static func value(field: String) -> bool:
	match field:
		"sound": return sound
		"music": return music
		"motion": return motion
		"haptics": return haptics
		"lines": return lines
	return false


static func toggle(field: String) -> void:
	match field:
		"sound": sound = not sound
		"music": music = not music
		"motion": motion = not motion
		"haptics": haptics = not haptics
		"lines": lines = not lines
	save()
