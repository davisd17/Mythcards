class_name Glossary
extends RefCounted
# Game terms players can look up (data/glossary.json, synced into game/data/). Card text
# gets its terms underlined as [url] links (tap one for its definition); the board's
# long-press finds terms by status type, placed-object type and character type.

const PATH := "res://data/glossary.json"
const LINK_COLOR := "#9fe0f5"

static var _terms: Array = []
static var _by_id: Dictionary = {}
static var _pattern: RegEx = null
static var _alias_to_id: Dictionary = {}   # lowercased alias -> term id


static func terms() -> Array:
	_load()
	return _terms


# {id, term, definition, ...} or {} when unknown.
static func find(id: String) -> Dictionary:
	_load()
	return _by_id.get(id, {})


static func id_for(field: String, value: String) -> String:
	_load()
	for t in _terms:
		if str(t.get(field, "")) == value:
			return str(t.id)
	return ""


# Wraps each linkable term in `text` as a [url=<id>] link, the first time that term
# appears among calls sharing `used` (so a card links each term once). `text` must be
# plain (no BBCode yet); the result is BBCode.
static func link(text: String, used: Dictionary = {}) -> String:
	_load()
	if _pattern == null:
		return text
	var out := ""
	var at := 0
	for m in _pattern.search_all(text):
		var id: String = _alias_to_id.get(m.get_string().to_lower(), "")
		if id == "" or used.has(id):
			continue
		used[id] = true
		out += text.substr(at, m.get_start() - at)
		out += "[url=%s][color=%s]%s[/color][/url]" % [id, LINK_COLOR, m.get_string()]
		at = m.get_end()
	return out + text.substr(at)


static func _load() -> void:
	if not _terms.is_empty() or not FileAccess.file_exists(PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Glossary: can't parse %s" % PATH)
		return
	_terms = parsed.get("terms", [])
	var aliases: Array[String] = []
	for t in _terms:
		_by_id[str(t.id)] = t
		if not t.get("link", true):
			continue
		for a in t.get("aliases", []):
			_alias_to_id[str(a).to_lower()] = str(t.id)
			aliases.append(str(a))
	if aliases.is_empty():
		return
	# Longest first, so "Leak marker" wins over "Leak" at the same spot.
	aliases.sort_custom(func(a, b): return a.length() > b.length())
	var escaped: Array[String] = []
	for a in aliases:
		escaped.append(_escape(a))
	_pattern = RegEx.create_from_string("(?i)\\b(?:%s)\\b" % "|".join(escaped))


static func _escape(s: String) -> String:
	var out := ""
	for ch in s:
		out += "\\" + ch if "\\^$.|?*+()[]{}-".contains(ch) else ch
	return out
