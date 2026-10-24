class_name EmberLines
extends RefCounted
# Each character's two approved Ember-claim speech lines (data/ember_lines.json, synced into
# game/data/; docs/art-specs/ember-claim/SPEC.md 4C). Shown verbatim. Presentation only.

const PATH := "res://data/ember_lines.json"

static var _lines: Dictionary = {}


# The claim line, or the big-claim line when 2 or more Embers were gained at once; "" when
# the character has none.
static func line_for(character_id: String, big: bool) -> String:
	if _lines.is_empty() and FileAccess.file_exists(PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			_lines = parsed
	var entry = _lines.get(character_id, {})
	return str(entry.get("big" if big else "claim", "")) if entry is Dictionary else ""
