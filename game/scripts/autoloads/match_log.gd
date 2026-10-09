extends Node
# Autoload name: MatchLog — a readable record of the match for playtesting (playtest
# 2026-10-09: "a log of the actions taken and any bonuses involved and where they came
# from"). It only listens to EventBus; it never changes the game. Each action a player
# (or the AI) takes is one entry, and everything that action caused (damage with each
# bonus and reduction named, statuses and who gave them, defeats, level-ups, Leaks,
# Memory) becomes its detail lines. Things that happen outside an action (turn starts,
# card draws, start-of-turn effects) get their own entries.

const MAX_ENTRIES := 2000
const DIRECTIONS := {Vector2i(0, 1): "up", Vector2i(0, -1): "down", Vector2i(1, 0): "right", Vector2i(-1, 0): "left"}

# {turn, player, text, lines: Array[String], failed: bool}
var entries: Array[Dictionary] = []
var _match: MatchState = null
var _open: Dictionary = {}   # the action being resolved, or {}


func _ready() -> void:
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.action_requested.connect(_on_action_requested)
	EventBus.action_resolved.connect(_on_action_resolved)
	EventBus.damage_resolved.connect(_on_damage)
	EventBus.status_added.connect(_on_status)
	EventBus.object_attacked.connect(_on_object_attacked)
	EventBus.character_defeated.connect(_on_defeated)
	EventBus.character_leveled_up.connect(func(id, level): _detail("%s reaches Level %d (full HP)" % [_name(id), level]))
	EventBus.spirit_ember_picked_up.connect(func(id): _detail("%s takes a Spirit Ember" % _name(id)))
	EventBus.spirit_ember_delivered.connect(func(id): _detail("%s delivers a Spirit Ember to the center" % _name(id)))
	EventBus.memory_gained.connect(func(id): _detail("%s gains Memory" % _name(id)))
	EventBus.leak_triggered.connect(func(id, _pos): _detail("%s triggers a Leak" % _name(id)))
	EventBus.relic_drawn.connect(_on_drawn)
	EventBus.relic_slot_changed.connect(func(player, card): _detail("%s's relic is now %s" % [_player(player), _card(card)]) if card != "" else null)
	EventBus.character_repositioned.connect(_on_repositioned)
	EventBus.match_ended.connect(func(winner, how): _entry("%s wins by %s" % [_player(winner), how.replace("_", " ")]))


func clear() -> void:
	entries.clear()
	_open = {}


# The log as plain text lines, newest last (what the overlay shows).
func as_text(bbcode: bool = false) -> String:
	var out: Array[String] = []
	var turn := -1
	for e in entries:
		if e.turn != turn:
			turn = e.turn
			out.append(("[b]Turn %d[/b]" if bbcode else "Turn %d") % turn)
		var head: String = e.text
		if e.failed:
			head = ("[color=#e06666]%s[/color]" if bbcode else "%s") % head
		out.append("  " + head)
		for line in e.lines:
			out.append("      " + line)
	return "\n".join(out)


# --- Listeners ----------------------------------------------------------------------------

func _on_turn_started(player_id: String) -> void:
	_sync_match()
	_begin_turn(player_id)


# "Ends the turn" starts the next turn (and its card draw) before it resolves. Whichever
# comes first, the draw or turn_started, closes the end-turn entry and opens the new
# turn's entry, so the draw is filed under the turn it belongs to.
func _begin_turn(player_id: String) -> void:
	var turn := _state().turn_number
	if not entries.is_empty() and entries[-1].get("kind") == "turn" and entries[-1].turn == turn:
		return
	if not _open.is_empty():
		_push(_open)
		_open = {}
	var entry := _new_entry("%s's turn begins (%d AP)" % [_player(player_id), _state().get_player(player_id).pool_ap_max])
	entry["kind"] = "turn"
	_push(entry)


func _on_action_requested(action_type: String, actor_id: String, payload: Dictionary) -> void:
	_sync_match()
	_open = _new_entry(_describe(action_type, actor_id, payload))


func _on_action_resolved(_action_type: String, _actor_id: String, result: Dictionary) -> void:
	if _open.is_empty():
		return
	if not result.get("success", false):
		_open.text += " (failed: %s)" % result.get("reason", "?")
		_open.failed = true
	_push(_open)
	_open = {}


func _on_damage(attacker_id: String, target_id: String, amount: int, lines: Array) -> void:
	var who := "%s takes %d" % [_name(target_id), amount] if attacker_id == target_id \
			else "%s deals %d to %s" % [_name(attacker_id), amount, _name(target_id)]
	_detail("%s: %s" % [who, ", ".join(lines)])


func _on_status(target_id: String, status_type: String, value: int, source_id: String) -> void:
	if status_type == "memory":
		return   # memory_gained says it
	var label: String = GameBoardView.STATUS.get(status_type, ["", status_type.capitalize()])[1]
	var amount := " %d" % value if status_type == "shield" or (value != 0 and status_type.begins_with("temp_")) else ""
	var by := " (from %s)" % _name(source_id) if source_id != "" and source_id != target_id else ""
	_detail("%s gains %s%s%s" % [_name(target_id), label, amount, by])


func _on_object_attacked(attacker_id: String, _pos: Vector2i, object_type: String, damage: int, destroyed: bool) -> void:
	_detail("%s hits a %s for %d%s" % [_name(attacker_id), object_type, damage, " and destroys it" if destroyed else ""])


func _on_defeated(id: String, by_id: String, cause: String) -> void:
	if cause == "mount_propagation":
		_detail("%s falls with its rider" % _name(id))
	elif by_id == id or by_id == "":
		_detail("%s is defeated" % _name(id))
	else:
		_detail("%s is defeated by %s" % [_name(id), _name(by_id)])


func _on_drawn(player_id: String, card_id: String) -> void:
	_sync_match()
	if _open.is_empty() or _open.turn != _state().turn_number:
		_begin_turn(player_id)
	var card := ContentDB.get_relic_event(card_id)
	var kind := card.kind.to_lower() if card != null else "card"
	_detail("%s draws %s (%s): %s" % [_player(player_id), _card(card_id), kind, card.effect if card != null else ""])


func _on_repositioned(id: String, from: Vector2i, to: Vector2i, cause: String) -> void:
	if from == to or cause == "mount" or cause == "dismount":
		return
	_detail("%s is moved %s (%s)" % [_name(id), _steps(from, to), cause.replace("_", " ")])


# --- Entries -------------------------------------------------------------------------------

func _describe(action_type: String, actor_id: String, payload: Dictionary) -> String:
	var who := _name(actor_id)
	var c := _find(actor_id)
	match action_type:
		"move":
			return "%s moves %s" % [who, _steps(c.position, payload.get("to", c.position))] if c != null else "%s moves" % who
		"attack":
			if payload.has("target_pos"):
				return "%s attacks an object" % who
			return "%s attacks %s" % [who, _name(str(payload.get("target_id", "")))]
		"ability":
			var label := str(payload.get("ability_id", ""))
			if c != null:
				label = RulesEngine.systems().ability.ability_label(c, label)
			var target = payload.get("target")
			var on := ""
			if target is Vector2i and c != null:
				on = " on the tile %s" % _steps(c.position, target)
			elif _find(str(target)) != null:
				on = " on %s" % _name(str(target))
			return "%s uses %s%s" % [who, label, on]
		"reactive_bonus":
			var tag := str(payload.get("tag", ""))
			var label: String = RulesEngine.systems().ability.bonus_label(c, tag) if c != null else tag
			return "%s uses %s (free)" % [who, label]
		"mount":
			return "%s mounts %s" % [who, _name(str(payload.get("mount_id", "")))]
		"dismount":
			return "%s dismounts" % who
		"end_turn":
			return "%s ends the turn" % _player(actor_id)
		"deck_choice":
			return "%s answers the drawn card" % _player(actor_id)
		"use_relic":
			return "%s uses their relic" % _player(actor_id)
	return "%s: %s" % [who, action_type]


func _new_entry(text: String) -> Dictionary:
	var state := _state()
	return {"turn": state.turn_number if state != null else 0, "player": state.active_player_id if state != null else "",
			"text": text, "lines": [], "failed": false}


func _entry(text: String) -> void:
	_push(_new_entry(text))


# Attaches a detail to the action in progress, or to the latest entry between actions.
func _detail(line: String) -> void:
	if not _open.is_empty():
		_open.lines.append(line)
	elif not entries.is_empty():
		entries[-1].lines.append(line)
	else:
		_entry(line)


func _push(entry: Dictionary) -> void:
	entries.append(entry)
	if entries.size() > MAX_ENTRIES:
		entries.pop_front()


func _sync_match() -> void:
	if GameState.match_state != _match:
		_match = GameState.match_state
		clear()


# --- Names ---------------------------------------------------------------------------------

func _state() -> MatchState:
	return GameState.match_state


func _find(id: String) -> CharacterInstance:
	return _state().find_character(id) if _state() != null and id != "" else null


func _name(id: String) -> String:
	var c := _find(id)
	return c.data.char_name if c != null else _player(id)


func _player(player_id: String) -> String:
	if player_id != "p1" and player_id != "p2":
		return player_id
	var n := "Player 1" if player_id == "p1" else "Player 2"
	var p := _state().get_player(player_id) if _state() != null else null
	var team := str(ContentDB.get_team(p.team_id).get("name", "")) if p != null else ""
	return "%s (%s)" % [n, team] if team != "" else n


static func _card(card_id: String) -> String:
	var card := ContentDB.get_relic_event(card_id)
	return card.card_name if card != null else card_id


# "2 up" as seen on screen (Player 1 at the bottom).
static func _steps(from: Vector2i, to: Vector2i) -> String:
	var delta := to - from
	var length := absi(delta.x) + absi(delta.y)
	if length == 0:
		return "nowhere"
	var dir := Vector2i(signi(delta.x), signi(delta.y))
	return "%d %s" % [length, DIRECTIONS.get(dir, "diagonally")]
