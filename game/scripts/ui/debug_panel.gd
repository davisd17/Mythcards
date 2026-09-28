class_name DebugPanel
extends RichTextLabel
# Playtesting readout (HLD 4.11, LLD-debug-panel.md). Two halves:
#   - State: re-read from MatchState after every event (read-only). Signal-only
#     bookkeeping can't stay correct: ability damage (Chill, reflects, Last Oath) emits
#     no attack_resolved, and statuses, objects, and frost have no signals at all.
#   - Log: built purely from EventBus signals, which keeps the signal contract honest.
# render() is static and pure so tests can check the text without a scene.

const LOG_LINES := 14

var selected_id: String = ""
var _log: Array[String] = []


func _ready() -> void:
	bbcode_enabled = true
	scroll_following = false
	EventBus.turn_started.connect(func(p): _record("turn_started", [p]))
	EventBus.character_moved.connect(func(id, from, to): _record("character_moved", [id, from, to]))
	EventBus.character_repositioned.connect(func(id, from, to, cause): _record("character_repositioned", [id, from, to, cause]))
	EventBus.attack_resolved.connect(func(a, t, dmg, dead): _record("attack_resolved", [a, t, dmg, dead]))
	EventBus.object_attacked.connect(func(a, pos, kind, dmg, gone): _record("object_attacked", [a, pos, kind, dmg, gone]))
	EventBus.character_defeated.connect(func(id, by, cause): _record("character_defeated", [id, by, cause]))
	EventBus.character_leveled_up.connect(func(id, lvl): _record("character_leveled_up", [id, lvl]))
	EventBus.spirit_ember_picked_up.connect(func(id): _record("spirit_ember_picked_up", [id]))
	EventBus.spirit_ember_delivered.connect(func(id): _record("spirit_ember_delivered", [id]))
	EventBus.relic_drawn.connect(func(p, card): _record("relic_drawn", [p, card]))
	EventBus.relic_slot_changed.connect(func(p, card): _record("relic_slot_changed", [p, card]))
	EventBus.event_resolved.connect(func(card): _record("event_resolved", [card]))
	EventBus.hero_capture_checked.connect(func(p, ok): _record("hero_capture_checked", [p, ok]))
	EventBus.match_ended.connect(func(w, how): _record("match_ended", [w, how]))
	EventBus.action_resolved.connect(func(kind, actor, result): _record("action_resolved", [kind, actor, result]))


func refresh() -> void:
	text = render(GameState.match_state, selected_id) + "\n[b]Log[/b]\n" + "\n".join(_log)


func log_lines() -> Array[String]:
	return _log.duplicate()


func add_log(line: String) -> void:
	_log.push_front(line)
	if _log.size() > LOG_LINES:
		_log.resize(LOG_LINES)


static func render(state: MatchState, selected_id: String = "") -> String:
	if state == null:
		return "No match."
	var sys: AbilitySystem = RulesEngine.systems().ability
	var lines: Array[String] = []
	if state.phase == "ended":
		lines.append("[b]MATCH OVER — %s wins by %s[/b]" % [state.winner_id, state.win_condition])
	else:
		lines.append("[b]Turn %d — %s to act[/b]   deck %d left (seed %d)" % [
				state.turn_number, state.active_player_id, state.shared_deck.size(), state.deck_seed])
	var spec := RelicEventDeck.choice_spec(state.active_player_id)
	if not spec.is_empty():
		lines.append("[color=orange]Choose (%s): %s[/color]" % [_card_name(spec.card_id), spec.prompt])
	var events: Array[String] = []
	for id in RelicEventDeck.active_event_ids():
		events.append(_card_name(id))
	if not events.is_empty():
		lines.append("Active events: " + ", ".join(events))
	if state.global_range_modifier != 0:
		lines.append("Global RANGE %+d" % state.global_range_modifier)

	for player in state.players:
		var relic := _card_name(player.active_relic_id) if player.active_relic_id != "" else "none"
		lines.append("")
		lines.append("[b]%s[/b] %s — pool AP %d/%d — relic: %s%s" % [player.id, player.culture,
				player.pool_ap_remaining, player.pool_ap_max, relic, _flag_text(player.player_flags_this_turn)])
		for c in player.characters:
			lines.append(_character_line(c, sys, c.instance_id == selected_id))

	var objects: Array[String] = []
	var frost: Array[String] = []
	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			var pos := Vector2i(x, y)
			var obj := state.board.get_placed_object(pos)
			if obj != null:
				objects.append("%s %s %d/%d (%s)" % [obj.type_id, _pos(pos), obj.current_hp, obj.max_hp, obj.owner_player_id])
			if state.board.get_tile(pos).terrain_type == "frost":
				frost.append(_pos(pos))
	if not objects.is_empty():
		lines.append("\nObjects: " + "; ".join(objects))
	if not frost.is_empty():
		lines.append("Frost: " + " ".join(frost))

	var selected := state.find_character(selected_id) if selected_id != "" else null
	if selected != null:
		lines.append("\n[b]%s[/b] — %s" % [selected.data.char_name, selected.instance_id])
		lines.append("L1: " + selected.data.l1)
		if selected.level >= 2:
			lines.append("L2: " + selected.data.l2)
		if selected.level >= 3:
			lines.append("L3: " + selected.data.l3)
	return "\n".join(lines)


static func abbreviation(data: CharacterData) -> String:
	# Two letters: word initials ("Frost Seer" -> FS), or the first two letters of a
	# one-word name ("Gymnast" -> GY).
	var words := data.char_name.split(" ", false)
	if words.size() >= 2:
		return (words[0].left(1) + words[1].left(1)).to_upper()
	return data.char_name.left(2).to_upper()


static func _character_line(c: CharacterInstance, sys: AbilitySystem, selected: bool) -> String:
	var tag := "[%s] %s L%d" % [abbreviation(c.data), c.data.char_name, c.level]
	if c.defeated:
		return "  [color=gray]%s — defeated[/color]" % tag
	var atk := c.get_effective_atk() + sys.get_conditional_atk_bonus(c)
	var rng := c.get_effective_range("attack", sys.get_conditional_range_bonus(c, "attack"))
	var parts: Array[String] = [
		tag, _pos(c.position),
		"HP %d/%d" % [c.current_hp, sys.get_effective_max_hp(c)],
		"ATK %d MOVE %d RANGE %d" % [atk, c.get_effective_move(), rng],
		"AP %d" % c.character_ap_remaining,
	]
	if c.spirit_ember_count > 0:
		parts.append("Embers %d" % c.spirit_ember_count)
	if c.is_mounted_rider:
		parts.append("riding " + c.mounted_with_id)
	elif c.mounted_with_id != "":
		parts.append("carrying " + c.mounted_with_id)
	var statuses: Array[String] = []
	for se in c.status_effects:
		statuses.append("%s%s" % [se.type, "" if se.value == 0 else str(se.value)])
	if not statuses.is_empty():
		parts.append("{" + ", ".join(statuses) + "}")
	var offers := _flag_text(c.ability_uses_this_turn)
	var line := "  " + "  ".join(parts) + offers
	return "[color=yellow]%s[/color]" % line if selected else line


# Offered free actions ("<tag>_available") as " bonus: tag".
static func _flag_text(flags: Dictionary) -> String:
	var offers: Array[String] = []
	for key in flags.keys():
		if str(key).ends_with("_available") and flags[key]:
			offers.append(str(key).trim_suffix("_available"))
	return "" if offers.is_empty() else "  [color=cyan]bonus: %s[/color]" % ", ".join(offers)


static func _card_name(card_id: String) -> String:
	var card := ContentDB.get_relic_event(card_id)
	return card.card_name if card != null else card_id


static func _pos(pos: Vector2i) -> String:
	return "(%d,%d)" % [pos.x, pos.y]


func _record(name: String, args: Array) -> void:
	var line := describe(name, args)
	if line != "":
		add_log(line)
	if is_inside_tree():
		refresh()


static func describe(name: String, args: Array) -> String:
	match name:
		"turn_started":
			return "— turn: %s —" % args[0]
		"character_moved":
			return "%s moves %s → %s" % [args[0], _pos(args[1]), _pos(args[2])]
		"character_repositioned":
			return "%s %s to %s" % [args[0], args[3], _pos(args[2])]
		"attack_resolved":
			return "%s hits %s for %d%s" % [args[0], args[1], args[2], " — defeated" if args[3] else ""]
		"object_attacked":
			return "%s hits %s %s for %d%s" % [args[0], args[2], _pos(args[1]), args[3], " — destroyed" if args[4] else ""]
		"character_defeated":
			return "[color=red]%s defeated by %s[/color]" % [args[0], args[1]]
		"character_leveled_up":
			return "[color=green]%s reaches Level %d[/color]" % [args[0], args[1]]
		"spirit_ember_picked_up":
			return "%s picks up a Spirit Ember" % args[0]
		"spirit_ember_delivered":
			return "%s delivers a Spirit Ember" % args[0]
		"relic_drawn":
			return "%s draws %s" % [args[0], _card_name(args[1])]
		"relic_slot_changed":
			return "%s relic: %s" % [args[0], _card_name(args[1])]
		"event_resolved":
			return "event: %s" % _card_name(args[0])
		"hero_capture_checked":
			return "" if args[1] else "%s's Hero has no legal move" % args[0]
		"match_ended":
			return "[b]%s wins by %s[/b]" % [args[0], args[1]]
		"action_resolved":
			var result: Dictionary = args[2]
			return "" if result.get("success", false) else "[color=red]✗ %s %s: %s[/color]" % [args[0], args[1], result.get("reason", "")]
	return name
