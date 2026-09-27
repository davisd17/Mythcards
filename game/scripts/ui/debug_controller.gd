class_name DebugController
extends RefCounted
# Input logic for the debug match (LLD-debug-panel.md 9A): board clicks and typed
# commands, both turned into RulesEngine.request_action calls. Kept free of UI nodes so
# tests can drive it directly.
#
# Clicks: select one of the active player's characters, then click a highlighted tile
# to move there, an enemy to attack it, or an enemy object to attack that.
# Commands (character tokens may be ids, card ids, or the panel's two-letter tags):
#   end                                  end the turn
#   choose {json}                        resolve the drawn card (see the panel's hint)
#   move <who> x,y                       move
#   attack <who> <target | x,y>          attack a character, or an object at x,y
#   ability <who> [ability_id] [{json}]  use an ability ({"target": "GU"} etc.)
#   bonus <who> <tag> [{json}]           take an offered free action
#   mount <who> <mount>  |  dismount <who> x,y
#   <action> <actor> {json}              anything else, raw

const HELP := "Commands: end | choose {json} | move <who> x,y | attack <who> <target|x,y> | " \
		+ "ability <who> [id] [{json}] | bonus <who> <tag> [{json}] | mount <who> <mount> | dismount <who> x,y"
const CHARACTER_KEYS := ["target_id", "target", "targets", "over_id", "echo_target_id", "ally_id", "mount_id", "id"]

var selected_id: String = ""


func move_tiles() -> Array[Vector2i]:
	if _selected() == null:
		return []
	return RulesEngine.get_legal_move_tiles(selected_id)


func attack_target_ids() -> Array[String]:
	if _selected() == null:
		return []
	return RulesEngine.get_legal_attack_target_ids(selected_id)


func attack_object_tiles() -> Array[Vector2i]:
	if _selected() == null:
		return []
	return RulesEngine.get_legal_attack_object_tiles(selected_id)


func click_tile(pos: Vector2i) -> String:
	var state := GameState.match_state
	if state == null or not GameState.is_match_active():
		return "The match is over."
	var occupant := _occupant(pos)
	if _selected() != null:
		if move_tiles().has(pos):
			return _report(RulesEngine.request_action("move", selected_id, {"to": pos}))
		if occupant != null and attack_target_ids().has(occupant.instance_id):
			return _report(RulesEngine.request_action("attack", selected_id, {"target_id": occupant.instance_id}))
		if attack_object_tiles().has(pos):
			return _report(RulesEngine.request_action("attack", selected_id, {"target_pos": pos}))
	if occupant != null and occupant.player_id == state.active_player_id:
		selected_id = occupant.instance_id
		return "Selected %s." % occupant.data.char_name
	selected_id = ""
	return ""


func run_command(line: String) -> String:
	var text := line.strip_edges()
	if text == "" or text == "help":
		return HELP
	var state := GameState.match_state
	if state == null:
		return "No match."
	var parts := _split(text)
	var verb: String = parts[0]
	match verb:
		"end", "end_turn":
			return _report(RulesEngine.request_action("end_turn", state.active_player_id, {}))
		"choose":
			var choice = _json(parts[1] if parts.size() > 1 else "{}")
			if not choice is Dictionary:
				return "choose needs a JSON object, e.g. choose {\"keep_new\": true}"
			return _report(RulesEngine.request_action("deck_choice", state.active_player_id, choice))
	if parts.size() < 2:
		return HELP
	var actor := resolve_character(parts[1], state.active_player_id)
	if actor == "":
		return "Unknown character '%s'." % parts[1]
	var rest: Array = parts.slice(2)
	var payload := {}
	match verb:
		"move", "dismount":
			var to = _coords(rest[0] if rest.size() > 0 else "")
			if to == null:
				return "%s needs x,y" % verb
			payload = {"to": to}
		"attack":
			if rest.is_empty():
				return "attack needs a target"
			var pos = _coords(rest[0])
			payload = {"target_pos": pos} if pos != null else {"target_id": resolve_character(rest[0], "")}
		"mount":
			payload = {"mount_id": resolve_character(rest[0] if rest.size() > 0 else "", state.active_player_id)}
		"ability":
			payload = {"ability_id": _default_ability_id(actor)}
			if rest.size() > 0 and not rest[0].begins_with("{"):
				payload.ability_id = rest.pop_front()
			if rest.size() > 0:
				var extra = _json(" ".join(rest))
				if not extra is Dictionary:
					return "Couldn't read the JSON."
				payload.merge(extra, true)
		"bonus":
			if rest.is_empty():
				return "bonus needs a tag"
			verb = "reactive_bonus"
			payload = {"tag": rest.pop_front()}
			if rest.size() > 0:
				var extra = _json(" ".join(rest))
				if not extra is Dictionary:
					return "Couldn't read the JSON."
				payload.merge(extra, true)
		_:
			if rest.size() > 0:
				var raw = _json(" ".join(rest))
				if not raw is Dictionary:
					return "Couldn't read the JSON."
				payload = raw
	return _report(RulesEngine.request_action(verb, actor, _convert(payload)))


# Finds a character by instance id, card id ("r-sniper"), short card id ("sniper"), or
# two-letter tag ("SN"). When several match, the preferred player's one wins.
static func resolve_character(token: String, prefer_player: String) -> String:
	var state := GameState.match_state
	if state == null or token == "":
		return ""
	var matches: Array[CharacterInstance] = []
	for p in state.players:
		for c in p.characters:
			if c.instance_id == token:
				return c.instance_id
			var t := token.to_lower()
			if c.data.id == t or c.data.id.ends_with("-" + t) or DebugPanel.abbreviation(c.data) == token.to_upper():
				matches.append(c)
	if matches.size() == 1:
		return matches[0].instance_id
	for c in matches:
		if c.player_id == prefer_player:
			return c.instance_id
	return ""


static func _default_ability_id(actor_id: String) -> String:
	var c := GameState.match_state.find_character(actor_id)
	return c.data.id if c != null else ""


func _selected() -> CharacterInstance:
	if selected_id == "" or GameState.match_state == null:
		return null
	var c := GameState.match_state.find_character(selected_id)
	return c if c != null and not c.defeated else null


static func _occupant(pos: Vector2i) -> CharacterInstance:
	var tile := GameState.match_state.board.get_tile(pos)
	if tile == null or tile.occupant_id == "":
		return null
	return GameState.match_state.find_character(tile.occupant_id)


static func _report(result: Dictionary) -> String:
	if result.get("success", false):
		var extra := result.duplicate()
		extra.erase("success")
		return "OK" if extra.is_empty() else "OK %s" % JSON.stringify(extra)
	return "✗ " + str(result.get("reason", "failed"))


# Splits on spaces, keeping a trailing {...} JSON blob in one piece.
static func _split(text: String) -> Array:
	var brace := text.find("{")
	var head := text if brace < 0 else text.substr(0, brace)
	var parts := Array(head.split(" ", false))
	if brace >= 0:
		parts.append(text.substr(brace))
	return parts


static func _coords(token: String):
	var bits := token.split(",")
	if bits.size() != 2 or not bits[0].strip_edges().is_valid_int() or not bits[1].strip_edges().is_valid_int():
		return null
	return Vector2i(bits[0].strip_edges().to_int(), bits[1].strip_edges().to_int())


static func _json(text: String):
	var json := JSON.new()
	return json.data if json.parse(text) == OK else null


# JSON has no Vector2i: turn [x, y] pairs into tiles, and character tokens into ids.
static func _convert(value, key: String = ""):
	if value is Array:
		if value.size() == 2 and (value[0] is float or value[0] is int) and (value[1] is float or value[1] is int):
			return Vector2i(int(value[0]), int(value[1]))
		return value.map(func(v): return _convert(v, key))
	if value is Dictionary:
		var out := {}
		for k in value.keys():
			out[k] = _convert(value[k], str(k))
		return out
	if value is String and CHARACTER_KEYS.has(key):
		var id := resolve_character(value, "")
		return id if id != "" else value
	return value
