extends Node
# Autoload name: ContentDB — must stay first in the autoload list; every other
# autoload assumes content is loaded and validated by the time its _ready() runs.
#
# Loads card data copied into res://data/cards by tools/sync_game_content.ps1
# (repo-root data/cards is the source of truth). See LLD-content-board.md.

const CHARACTERS_PATH := "res://data/cards/characters.json"
const RELIC_EVENTS_PATH := "res://data/cards/relic_events.json"
const REVIEW_DRAFTS_DIR := "res://data/cards/review_drafts/"
const DRAFT_STATUS := "draft_for_review"

var characters: Dictionary = {}          # String id -> CharacterData (playable)
var relic_events: Dictionary = {}        # String id -> RelicEventData (playable)
var draft_characters: Dictionary = {}    # String id -> CharacterData (review drafts, BR-043A)
var draft_relic_events: Dictionary = {}  # String id -> RelicEventData (review drafts, BR-043A)

# Problems found while parsing (duplicate ids, malformed stats, unknown entry shapes).
# Reported by validate() alongside the structural checks.
var _load_errors: Array[String] = []


func _ready() -> void:
	load_all()
	var errors := validate()
	for e in errors:
		push_error("ContentDB validation: %s" % e)
	assert(errors.is_empty(), "ContentDB: %d validation error(s); see Output log" % errors.size())


func load_all(characters_path: String = CHARACTERS_PATH,
		relic_events_path: String = RELIC_EVENTS_PATH,
		drafts_dir: String = REVIEW_DRAFTS_DIR) -> void:
	clear()
	var char_entries = _read_json(characters_path)
	if char_entries is Array:
		add_character_entries(char_entries, false)
	var relic_entries = _read_json(relic_events_path)
	if relic_entries is Array:
		add_relic_event_entries(relic_entries, false)
	_load_review_drafts(drafts_dir)


func clear() -> void:
	characters.clear()
	relic_events.clear()
	draft_characters.clear()
	draft_relic_events.clear()
	_load_errors.clear()


func get_character(id: String) -> CharacterData:
	return characters.get(id, null)


func get_characters_by_culture(culture: String) -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	for c: CharacterData in characters.values():
		if c.culture == culture:
			result.append(c)
	return result


func get_cultures() -> Array[String]:
	var result: Array[String] = []
	for c: CharacterData in characters.values():
		if not result.has(c.culture):
			result.append(c.culture)
	return result


func get_relic_event(id: String) -> RelicEventData:
	# Draft-only ids are deliberately not found here (BR-043A).
	return relic_events.get(id, null)


func get_draft_character(id: String) -> CharacterData:
	return draft_characters.get(id, null)


func get_draft_relic_event(id: String) -> RelicEventData:
	return draft_relic_events.get(id, null)


func get_playable_relic_events_by_faction(faction: String) -> Array[RelicEventData]:
	# What RelicEventDeck calls to build each player's 3-relic/4-event contribution (BR-027A).
	var result: Array[RelicEventData] = []
	for r: RelicEventData in relic_events.values():
		if r.faction == faction:
			result.append(r)
	return result


func add_character_entries(entries: Array, is_draft: bool, source: String = "") -> void:
	var target := draft_characters if is_draft else characters
	for entry in entries:
		if not entry is Dictionary:
			_load_errors.append("%s: character entry is not an object" % source)
			continue
		var data := _build_character(entry, source)
		if data.review_status == "" and is_draft:
			data.review_status = DRAFT_STATUS
		if target.has(data.id):
			_load_errors.append("duplicate character id '%s'" % data.id)
			continue
		target[data.id] = data


func add_relic_event_entries(entries: Array, is_draft: bool, source: String = "") -> void:
	var target := draft_relic_events if is_draft else relic_events
	for entry in entries:
		if not entry is Dictionary:
			_load_errors.append("%s: relic/event entry is not an object" % source)
			continue
		var data := _build_relic_event(entry)
		if is_draft:
			if data.review_status != DRAFT_STATUS:
				# A draft file with a different status is an authoring mistake worth surfacing.
				push_error("ContentDB: draft '%s' in %s has review_status '%s'; treating as '%s'"
						% [data.id, source, data.review_status, DRAFT_STATUS])
				data.review_status = DRAFT_STATUS
		if target.has(data.id):
			_load_errors.append("duplicate relic/event id '%s'" % data.id)
			continue
		target[data.id] = data


func validate() -> Array[String]:
	var errors: Array[String] = _load_errors.duplicate()

	for map in [characters, draft_characters]:
		for c: CharacterData in map.values():
			if c.id == "":
				errors.append("character '%s' has no id" % c.char_name)
			if not GameEnums.CHARACTER_TYPES.has(c.type):
				errors.append("character '%s' has unknown type '%s'" % [c.id, c.type])
			if c.sub_area.contains(" / "):
				errors.append("character '%s' has combined sub_area '%s'; use a single value" % [c.id, c.sub_area])

	for map in [relic_events, draft_relic_events]:
		for r: RelicEventData in map.values():
			if r.id == "":
				errors.append("relic/event '%s' has no id" % r.card_name)
			if not GameEnums.RELIC_EVENT_KINDS.has(r.kind):
				errors.append("relic/event '%s' has unknown kind '%s'" % [r.id, r.kind])

	# BR-005: every playable culture has exactly one character of each type.
	for culture in get_cultures():
		var counts := {}
		for c in get_characters_by_culture(culture):
			counts[c.type] = counts.get(c.type, 0) + 1
		for t in GameEnums.CHARACTER_TYPES:
			var n: int = counts.get(t, 0)
			if n != 1:
				errors.append("culture '%s' has %d %s character(s); expected exactly 1" % [culture, n, t])

	return errors


func _load_review_drafts(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("ContentDB: cannot open review drafts dir %s (error %d)" % [dir_path, DirAccess.get_open_error()])
		return
	var files := Array(dir.get_files())
	files.sort()
	for file_name: String in files:
		if not file_name.ends_with(".json"):
			continue
		var path := dir_path.path_join(file_name)
		var parsed = _read_json(path)
		# Object-shaped files (tarot mapping, story frameworks) are design documents, not card lists.
		if not parsed is Array:
			continue
		for entry in parsed:
			if not entry is Dictionary:
				_load_errors.append("%s: entry is not an object" % file_name)
			elif entry.has("kind"):
				add_relic_event_entries([entry], true, file_name)
			elif entry.has("type"):
				add_character_entries([entry], true, file_name)
			else:
				_load_errors.append("%s: entry '%s' has neither 'kind' nor 'type'" % [file_name, entry.get("id", "?")])


func _read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ContentDB: cannot open %s (error %d). Run tools/sync_game_content.ps1 to copy card data into the project."
				% [path, FileAccess.get_open_error()])
		return null
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("ContentDB: %s line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data


func _build_character(entry: Dictionary, source: String) -> CharacterData:
	var data := CharacterData.new()
	data.id = str(entry.get("id", ""))
	data.faction = str(entry.get("faction", ""))
	data.culture = str(entry.get("culture", ""))
	data.sub_area = str(entry.get("sub_area", ""))
	data.char_name = str(entry.get("name", ""))
	data.type = str(entry.get("type", ""))
	data.unique = bool(entry.get("unique", false))
	data.l1 = str(entry.get("l1", ""))
	data.l2 = str(entry.get("l2", ""))
	data.l3 = str(entry.get("l3", ""))
	data.role = str(entry.get("role", ""))
	data.review_status = str(entry.get("review_status", ""))
	data.raw = entry

	# stats is [HP, ATK, MOVE, RANGE] in that fixed order.
	var stats = entry.get("stats", null)
	if stats is Array and stats.size() == 4 and stats.all(_is_whole_number):
		data.hp = int(stats[0])
		data.atk = int(stats[1])
		data.move = int(stats[2])
		data.range = int(stats[3])
	else:
		_load_errors.append("character '%s'%s: stats must be 4 whole numbers [HP, ATK, MOVE, RANGE], got %s"
				% [data.id, (" in " + source) if source != "" else "", str(stats)])
	return data


func _build_relic_event(entry: Dictionary) -> RelicEventData:
	var data := RelicEventData.new()
	data.id = str(entry.get("id", ""))
	data.faction = str(entry.get("faction", ""))
	data.sub_area = str(entry.get("sub_area", ""))
	data.card_name = str(entry.get("name", ""))
	data.kind = str(entry.get("kind", ""))
	data.duration = str(entry.get("duration", ""))
	data.effect = str(entry.get("effect", ""))
	data.note = str(entry.get("note", ""))
	data.review_status = str(entry.get("review_status", ""))
	data.raw = entry
	return data


static func _is_whole_number(v: Variant) -> bool:
	return (typeof(v) == TYPE_INT) or (typeof(v) == TYPE_FLOAT and v == floorf(v))
