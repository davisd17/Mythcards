class_name NetStore
# The online seats this device holds (LLD-network-match.md 3.3), one ConfigFile section per
# room code. On the web build user:// persists in IndexedDB. Unsent entries (the outbox,
# Section 7) are saved with their seat so a closed app can send them later.

static var path := "user://net_matches.cfg"   # tests point this elsewhere


static func save(code: String, seat: String, token: String, team_id: String, version: String = "") -> void:
	var cfg := _load()
	cfg.set_value(code, "seat", seat)
	cfg.set_value(code, "token", token)
	cfg.set_value(code, "team_id", team_id)
	cfg.set_value(code, "version", version)
	cfg.set_value(code, "ended", false)
	cfg.set_value(code, "saved_at", Time.get_unix_time_from_system())
	cfg.save(path)


static func get_seat(code: String) -> Dictionary:
	var cfg := _load()
	if not cfg.has_section(code):
		return {}
	return _row(cfg, code)


# [{code, seat, token, team_id, version, ended}], newest first.
static func seats() -> Array[Dictionary]:
	var cfg := _load()
	var rows: Array[Dictionary] = []
	for code in cfg.get_sections():
		rows.append(_row(cfg, code))
	rows.sort_custom(func(a, b): return a.saved_at > b.saved_at)
	return rows


static func mark_ended(code: String) -> void:
	_put(code, "ended", true)


static func set_outbox(code: String, entries: Array) -> void:
	_put(code, "outbox", entries)


static func forget(code: String) -> void:
	var cfg := _load()
	if cfg.has_section(code):
		cfg.erase_section(code)
		cfg.save(path)


static func _put(code: String, key: String, value: Variant) -> void:
	var cfg := _load()
	if not cfg.has_section(code):
		return
	cfg.set_value(code, key, value)
	cfg.save(path)


static func _row(cfg: ConfigFile, code: String) -> Dictionary:
	return {"code": code, "seat": cfg.get_value(code, "seat", ""), "token": cfg.get_value(code, "token", ""),
			"team_id": cfg.get_value(code, "team_id", ""), "version": cfg.get_value(code, "version", ""),
			"ended": cfg.get_value(code, "ended", false), "saved_at": cfg.get_value(code, "saved_at", 0.0),
			"outbox": cfg.get_value(code, "outbox", [])}


static func _load() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(path)   # a missing file is an empty store
	return cfg
