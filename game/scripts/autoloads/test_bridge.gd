extends Node
# Autoload name: TestBridge — JS hooks so Playwright can read exact match state and drive
# a match through RulesEngine's real validation path (HLD 4.13, LLD-test-bridge.md):
#   window.mythcards_get_state()             -> JSON string (serialize_state)
#   window.mythcards_dispatch_action(json)   -> JSON string (dispatch_action)
#   window.mythcards_new_match(seed)         -> JSON string (restart with a fixed deck seed)
# Live only in a Web export carrying the "mythcards_testbridge" custom feature tag, so the
# hooks never ship in a normal build (HLD-R-008). serialize_state/dispatch_action are pure
# and GUT-tested; the JS glue is covered by the Playwright suite in e2e/.

const FEATURE_TAG := "mythcards_testbridge"

# JavaScriptObject callbacks must stay referenced, or JS calls into freed callables.
var _callbacks: Array = []
var _window: JavaScriptObject = null


func _ready() -> void:
	if not (OS.has_feature("web") and OS.has_feature(FEATURE_TAG)):
		return
	_register_js_callbacks()


func serialize_state() -> Dictionary:
	var state := GameState.match_state
	if state == null:
		return {"phase": "", "turn_number": 0, "active_player_id": "", "winner_id": "",
				"win_condition": "", "players": {}}
	var players := {}
	for p in state.players:
		var characters := []
		for c in p.characters:
			var statuses := []
			for se in c.status_effects:
				statuses.append({"type": se.type, "value": se.value, "expires": se.expires,
						"source_character_id": se.source_character_id})
			characters.append({
				"instance_id": c.instance_id,
				"character_id": c.data.id,
				"type": c.data.type,
				"position": _pos(c.position),
				"current_hp": c.current_hp,
				"max_hp": RulesEngine.systems().ability.get_effective_max_hp(c),
				"level": c.level,
				"character_ap_remaining": c.character_ap_remaining,
				"spirit_ember_count": c.spirit_ember_count,
				"mounted_with_id": c.mounted_with_id,
				"is_mounted_rider": c.is_mounted_rider,
				"defeated": c.defeated,
				"status_effects": statuses,
			})
		players[p.id] = {
			"culture": p.culture,
			"pool_ap_remaining": p.pool_ap_remaining,
			"pool_ap_max": p.pool_ap_max,
			"active_relic_id": p.active_relic_id,
			"characters": characters,
		}
	var objects := []
	var frost := []
	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			var obj := state.board.get_placed_object(Vector2i(x, y))
			if obj != null:
				objects.append({"type": obj.type_id, "position": _pos(Vector2i(x, y)),
						"current_hp": obj.current_hp, "max_hp": obj.max_hp, "owner": obj.owner_player_id})
			if state.board.get_tile(Vector2i(x, y)).terrain_type == "frost":
				frost.append(_pos(Vector2i(x, y)))
	var pending := RelicEventDeck.get_pending_choice(state.active_player_id)
	return {
		"phase": state.phase,
		"turn_number": state.turn_number,
		"active_player_id": state.active_player_id,
		"winner_id": state.winner_id,
		"win_condition": state.win_condition,
		"players": players,
		"deck_size": state.shared_deck.size(),
		"deck_seed": state.deck_seed,
		"pending_choice": {"kind": pending.kind, "card_id": pending.card_id} if not pending.is_empty() else {},
		"active_events": RelicEventDeck.active_event_ids(),
		"global_range_modifier": state.global_range_modifier,
		"objects": objects,
		"frost": frost,
	}


func dispatch_action(action_json: String) -> Dictionary:
	var json := JSON.new()
	var parsed = json.data if json.parse(action_json) == OK else null   # parse() fails quietly
	if not parsed is Dictionary or not parsed.get("action_type") is String or not parsed.get("actor_id") is String:
		return {"success": false, "reason": "malformed action JSON"}
	var payload = parsed.get("payload", {})
	if not payload is Dictionary:
		return {"success": false, "reason": "malformed action JSON"}
	var result := RulesEngine.request_action(parsed.action_type, parsed.actor_id, _to_engine(payload))
	return _to_json_safe(result)


# Restarts through the current scene (the debug match) with a fixed deck seed.
func new_match(deck_seed: int) -> Dictionary:
	var scene := get_tree().current_scene
	if scene == null or not scene.has_method("start_new_match"):
		return {"success": false, "reason": "the current scene can't start a match"}
	scene.start_new_match(deck_seed)
	return {"success": true, "deck_seed": deck_seed}


# --- JS glue ---------------------------------------------------------------------------

func _register_js_callbacks() -> void:
	_window = JavaScriptBridge.get_interface("window")
	_expose("__mythcards_get_state", func(_args): return JSON.stringify(serialize_state()))
	_expose("__mythcards_dispatch_action", func(args): return JSON.stringify(dispatch_action(str(args[0]))))
	_expose("__mythcards_new_match", func(args): return JSON.stringify(new_match(int(args[0]))))
	# The Godot callbacks store their answer in window.__mythcards_result; these wrappers
	# return it, so JS gets a value whether or not a callback's own return reaches JS.
	JavaScriptBridge.eval("""
		window.mythcards_get_state = function () { window.__mythcards_get_state(); return window.__mythcards_result; };
		window.mythcards_dispatch_action = function (json) { window.__mythcards_dispatch_action(json); return window.__mythcards_result; };
		window.mythcards_new_match = function (seed) { window.__mythcards_new_match(seed); return window.__mythcards_result; };
		window.mythcards_ready = true;
	""", true)


func _expose(name: String, body: Callable) -> void:
	var callback := JavaScriptBridge.create_callback(func(args: Array) -> void:
		_window.set("__mythcards_result", body.call(args)))
	_callbacks.append(callback)
	_window.set(name, callback)


# --- Conversions -------------------------------------------------------------------------

# {"x": int, "y": int} -> Vector2i, recursively (JSON has no Vector2i).
static func _to_engine(value):
	if value is Dictionary:
		if value.size() == 2 and value.has("x") and value.has("y") and _is_number(value.x) and _is_number(value.y):
			return Vector2i(int(value.x), int(value.y))
		var out := {}
		for k in value.keys():
			out[k] = _to_engine(value[k])
		return out
	if value is Array:
		return value.map(func(v): return _to_engine(v))
	return value


static func _to_json_safe(value):
	if value is Vector2i:
		return _pos(value)
	if value is Dictionary:
		var out := {}
		for k in value.keys():
			out[k] = _to_json_safe(value[k])
		return out
	if value is Array:
		return value.map(func(v): return _to_json_safe(v))
	return value


static func _pos(pos: Vector2i) -> Dictionary:
	return {"x": pos.x, "y": pos.y}


static func _is_number(v) -> bool:
	return v is int or v is float
