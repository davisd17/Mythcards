extends Node
# Autoload name: RelicEventDeck — the shared relic/event deck (LLD-relic-event-deck.md).
# Each side contributes 5 unique relics and two copies of 5 events (30 total cards), shuffled
# with a seed, and the active player draws one at the start of each turn. Relics fill
# the player's single slot (a full slot means a keep-or-replace choice); events resolve
# at once or last their duration. Anything needing a decision becomes a pending choice,
# resolved through RulesEngine's "deck_choice" action before the player can act. Some
# relics have a power the player triggers with the "use_relic" action.
#
# Every pending choice and relic power describes itself (choice_spec / power_spec) so a
# tap UI can offer exactly the legal picks.

const RELICS_PER_PLAYER := 5
const EVENTS_PER_PLAYER := 10
const EVENT_COPIES := 2

var _match: MatchState = null
var _active: Dictionary = {}    # event instance id -> {card_id, player_id, remaining, drawn_on_turn, data}
var _next_event_id := 0
var _pending: Dictionary = {}   # player id -> {kind: "relic"|"event"|"power", card_id, ...}
var _relic_state: Dictionary = {}   # "<player>:<card>" -> Dictionary, match-scoped relic memory
var _handlers: Dictionary = {}
var _veil_queue: Array[Dictionary] = []


# An optional relic reaction interrupts the active side until its owner answers.
func decision_player() -> String:
	if not _is_current():
		return GameState.match_state.active_player_id if GameState.match_state != null else ""
	return str(_veil_queue[0].player_id) if not _veil_queue.is_empty() else _match.active_player_id


func offer_veil_protection(target: CharacterInstance, value: int, expires: String, source: CharacterInstance) -> bool:
	const CARD := "a-flood-survivor-seraphic-burial-veil"
	if target.defeated or not has_relic(target.player_id, CARD):
		return false
	var round_id: int = (_match.turn_number - 1) / 2
	if relic_state(target.player_id, CARD).get("used_round", -1) == round_id:
		return false
	_veil_queue.append({"player_id": target.player_id, "target": target, "value": value,
		"expires": expires, "source": source, "round": round_id})
	return true


func _resolve_veil(player_id: String, payload: Dictionary) -> Dictionary:
	if _veil_queue.is_empty() or decision_player() != player_id or not payload.get("protect") is bool:
		return {"success": false, "reason": "choose Shield or accept Marked"}
	var entry: Dictionary = _veil_queue.pop_front()
	var target: CharacterInstance = entry.target
	var state := relic_state(player_id, "a-flood-survivor-seraphic-burial-veil")
	if payload.protect and not target.defeated:
		state["used_round"] = entry.round
		_sys().add_status(target, "shield", 1, "until_used")
	else:
		_apply_queued_mark(entry)
	# Other Marks from the same action still apply after this round's protection is used.
	for queued in _veil_queue.duplicate():
		if queued.player_id == player_id and state.get("used_round", -1) == queued.round:
			_veil_queue.erase(queued)
			_apply_queued_mark(queued)
	return {"success": true}


func _apply_queued_mark(entry: Dictionary) -> void:
	var c: CharacterInstance = entry.target
	if c.defeated:
		return
	var se := StatusEffect.new("marked", entry.value, entry.expires, _match.turn_number)
	se.source_character_id = entry.source.instance_id if entry.source != null else ""
	c.status_effects.append(se)
	EventBus.status_added.emit(c.instance_id, "marked", se.value, se.source_character_id)


func _ready() -> void:
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.attack_resolved.connect(func(a, t, dmg, dead): _forward("on_attack_resolved", [a, t, dmg, dead]))
	EventBus.object_attacked.connect(func(a, pos, _k, dmg, gone): _forward("on_object_attacked", [a, pos, dmg, gone]))
	EventBus.character_moved.connect(func(id, from, to): _forward("on_character_moved", [id, from, to]))
	EventBus.memory_gained.connect(func(id): _forward("on_memory_gained", [id]))
	EventBus.leak_triggered.connect(func(id, pos): _forward("on_leak_triggered", [id, pos]))


func build_deck(p1_culture: String, p2_culture: String, deck_seed: int) -> void:
	_reset_for(GameState.match_state)
	var cards: Array[String] = []
	cards.append_array(_contribution(p1_culture))
	cards.append_array(_contribution(p2_culture))
	var rng := RandomNumberGenerator.new()
	rng.seed = deck_seed
	for i in range(cards.size() - 1, 0, -1):   # Fisher-Yates
		var j := rng.randi_range(0, i)
		var swap := cards[i]
		cards[i] = cards[j]
		cards[j] = swap
	_match.shared_deck = cards
	_match.deck_seed = deck_seed


func draw_for(player_id: String) -> void:
	_sync()
	if _match == null or _match.shared_deck.is_empty():
		return   # an empty deck just means no draw (BR-028A)
	var card_id: String = _match.shared_deck.pop_front()
	var card := ContentDB.get_relic_event(card_id)
	if card == null:
		push_error("RelicEventDeck: unknown card '%s' in the deck" % card_id)
		return
	EventBus.relic_drawn.emit(player_id, card_id)
	if card.is_relic():
		var player := _match.get_player(player_id)
		if player.active_relic_id == "":
			_set_relic(player, card_id)
		else:
			_pending[player_id] = {"kind": "relic", "card_id": card_id}
		return
	var handler := _handler(card_id)
	var outcome: Dictionary
	if card.duration == "Immediate":
		outcome = handler.resolve_immediate(_sys(), player_id)
	else:
		outcome = handler.on_activate(_sys(), player_id)
		_next_event_id += 1
		_active[str(_next_event_id)] = {
			"card_id": card_id,
			"player_id": player_id,
			"remaining": 2 if card.duration == "1 round" else 1,   # a round = 2 individual turns
			"drawn_on_turn": _match.turn_number,
			"data": outcome,
		}
	if outcome.get("needs_choice", false):
		_pending[player_id] = outcome.duplicate()
		_pending[player_id].merge({"kind": "event", "card_id": card_id}, true)
		return
	EventBus.event_resolved.emit(card_id)


func has_pending_choice(player_id: String) -> bool:
	return _is_current() and ((not _veil_queue.is_empty() and decision_player() == player_id) or _pending.has(player_id))


func get_pending_choice(player_id: String) -> Dictionary:
	if _is_current() and not _veil_queue.is_empty() and decision_player() == player_id:
		return {"kind": "veil", "card_id": "a-flood-survivor-seraphic-burial-veil"}
	return _pending.get(player_id, {}) if _is_current() else {}


# What the pending choice asks for, for the UI: {prompt, pick, count?, tiles?,
# characters?, options?, ...}. pick is "option" | "tiles" | "character" | "character_tile".
func choice_spec(player_id: String) -> Dictionary:
	var pending := get_pending_choice(player_id)
	if pending.is_empty():
		return {}
	if pending.kind == "veil":
		return {"kind": "veil", "card_id": pending.card_id, "pick": "option",
			"prompt": "Seraphic Burial Veil: protect %s from Marked?" % _veil_queue[0].target.data.char_name,
			"options": [{"label": "Gain Shield instead", "payload": {"protect": true}},
				{"label": "Accept Marked", "payload": {"protect": false}}]}
	var spec: Dictionary
	if pending.kind == "relic":
		var old := ContentDB.get_relic_event(_match.get_player(player_id).active_relic_id)
		spec = {"prompt": "Your relic slot is full. Keep %s, or replace it with the new one?" % old.card_name,
				"pick": "option", "options": [
					{"label": "Take the new relic", "payload": {"keep_new": true}},
					{"label": "Keep %s" % old.card_name, "payload": {"keep_new": false}}]}
	else:
		spec = _handler(pending.card_id).choice_spec(_sys(), player_id, pending)
	spec["card_id"] = pending.card_id
	spec["kind"] = pending.kind
	return spec


# RulesEngine's "deck_choice" action. Relic: {"keep_new": bool}. Others: card-specific.
func resolve_choice(player_id: String, payload: Dictionary) -> Dictionary:
	if not _veil_queue.is_empty():
		return _resolve_veil(player_id, payload)
	if not has_pending_choice(player_id):
		return {"success": false, "reason": "nothing to choose"}
	var pending: Dictionary = _pending[player_id]
	if pending.kind == "relic":
		if not payload.get("keep_new") is bool:
			return {"success": false, "reason": "choose keep_new true or false"}
		_pending.erase(player_id)
		if payload.keep_new:
			_set_relic(_match.get_player(player_id), pending.card_id)
		return {"success": true}
	var result := _handler(pending.card_id).resolve_choice(_sys(), player_id, payload)
	if result.get("success", false):
		if result.has("pending"):
			_pending[player_id] = result.pending
			return result
		_pending.erase(player_id)
		if pending.kind == "event":
			EventBus.event_resolved.emit(pending.card_id)
	return result


# --- Relic powers ("use_relic") -------------------------------------------------------

# The active player's relic power, if it can be used now: {} or a spec like choice_spec.
func power_spec(player_id: String) -> Dictionary:
	if not _is_current():
		return {}
	var relic := _match.get_player(player_id).active_relic_id
	if relic == "" or not _handler(relic).power_available(_sys(), player_id):
		return {}
	var spec := _handler(relic).power_spec(_sys(), player_id)
	spec["card_id"] = relic
	return spec


func use_relic(player_id: String, payload: Dictionary) -> Dictionary:
	_sync()
	var relic := _match.get_player(player_id).active_relic_id
	if relic == "" or not _handler(relic).power_available(_sys(), player_id):
		return {"success": false, "reason": "no relic power available"}
	var result := _handler(relic).use_power(_sys(), player_id, payload)
	if result.has("pending"):
		# A power can reveal something and then ask (Chintamani Fragment).
		var pending: Dictionary = result.pending
		pending["kind"] = "power"
		pending["card_id"] = relic
		_pending[player_id] = pending
		result.erase("pending")
	return result


# Match-scoped memory for a player's relic (e.g. "once each round").
func relic_state(player_id: String, card_id: String) -> Dictionary:
	var key := "%s:%s" % [player_id, card_id]
	if not _relic_state.has(key):
		_relic_state[key] = {}
	return _relic_state[key]


func has_relic(player_id: String, card_id: String) -> bool:
	var state := GameState.match_state
	if state == null:
		return false
	var p := state.get_player(player_id)
	return p != null and p.active_relic_id == card_id


func is_active(card_id: String) -> bool:
	return _is_current() and _active.values().any(func(e): return e.card_id == card_id)


# A running duration event's live data (what its on_activate returned).
func active_data(card_id: String) -> Dictionary:
	if _is_current():
		for entry in _active.values():
			if entry.card_id == card_id:
				return entry.data
	return {}


# Currently running duration events, for inspection (DebugPanel).
func active_event_ids() -> Array[String]:
	var result: Array[String] = []
	if _is_current():
		for entry in _active.values():
			result.append(entry.card_id)
	return result


# Deck-top access (Foresight, Chintamani Fragment). Index 0 is the next draw.
func peek_next() -> String:
	var state := GameState.match_state
	return state.shared_deck[0] if state != null and not state.shared_deck.is_empty() else ""


func move_top_to_bottom() -> void:
	var state := GameState.match_state
	if state != null and state.shared_deck.size() > 1:
		state.shared_deck.append(state.shared_deck.pop_front())


# --- Relic queries (AbilitySystem, CombatResolver) ---------------------------------

func get_relic_max_hp_bonus(sys, target: CharacterInstance) -> int:
	return _sum_relics(func(h, owner): return h.get_max_hp_bonus(sys, owner, target))


func get_relic_shield_bonus(sys, defender: CharacterInstance) -> int:
	return _sum_relics(func(h, owner): return h.get_shield_bonus(sys, owner, defender))


func get_relic_range_bonus(sys, instance: CharacterInstance, context: String) -> int:
	return _sum_relics(func(h, owner): return h.get_range_bonus(sys, owner, instance, context))


func get_relic_atk_bonus(sys, instance: CharacterInstance) -> int:
	return _sum_relics(func(h, owner): return h.get_atk_bonus(sys, owner, instance))


func get_relic_move_bonus(sys, instance: CharacterInstance) -> int:
	return _sum_relics(func(h, owner): return h.get_move_bonus(sys, owner, instance))


# --- Internals ---------------------------------------------------------------------

func _on_turn_started(player_id: String) -> void:
	if not _is_current():
		return
	# Durations count down at each turn start, but not the one they were drawn on
	# (TurnManager draws before announcing the turn).
	for card_id in _active.keys():
		var entry: Dictionary = _active[card_id]
		if entry.drawn_on_turn == _match.turn_number:
			continue
		entry.remaining -= 1
		if entry.remaining <= 0:
			_active.erase(card_id)
			_handler(entry.card_id).on_expire(_sys(), entry.player_id, entry.data)
	var player := _match.get_player(player_id)
	if player != null and player.active_relic_id != "":
		_handler(player.active_relic_id).on_owner_turn_started(_sys(), player_id)


# Sends a game event to both players' active relics and every running event.
func _forward(method: String, args: Array) -> void:
	if not _is_current():
		return
	# Nothing in play: don't touch (and so lazily build) the match's rules systems.
	if _active.is_empty() and _match.players.all(func(p): return p.active_relic_id == ""):
		return
	var sys := _sys()
	for p in _match.players:
		if p.active_relic_id != "":
			_handler(p.active_relic_id).callv(method, [sys, p.id] + args)
	for card_id in _active.keys():
		var entry: Dictionary = _active.get(card_id, {})
		if not entry.is_empty():
			_handler(entry.card_id).callv(method, [sys, entry.player_id] + args)


func _sum_relics(query: Callable) -> int:
	var total := 0
	var state := GameState.match_state
	if state == null:
		return 0
	for p in state.players:
		if p.active_relic_id != "":
			total += int(query.call(_handler(p.active_relic_id), p.id))
	return total


func _set_relic(player: PlayerState, card_id: String) -> void:
	player.active_relic_id = card_id
	EventBus.relic_slot_changed.emit(player.id, card_id)
	# A replaced relic may have raised max HP; nobody keeps HP above the new maximum.
	var sys := _sys()
	for p in _match.players:
		for c in p.characters:
			if not c.defeated:
				c.current_hp = mini(c.current_hp, sys.get_effective_max_hp(c))
	_handler(card_id).on_equipped(sys, player.id)


func _contribution(culture: String) -> Array[String]:
	var chars := ContentDB.get_characters_by_culture(culture)
	if chars.is_empty():
		push_error("RelicEventDeck: unknown culture '%s'" % culture)
		return []
	var relics: Array[String] = []
	var events: Array[String] = []
	for card in ContentDB.get_playable_relic_events_by_faction(chars[0].faction):
		if card.is_relic():
			relics.append(card.id)
		else:
			for _copy in EVENT_COPIES:
				events.append(card.id)
	if relics.size() != RELICS_PER_PLAYER or events.size() != EVENTS_PER_PLAYER:
		push_error("RelicEventDeck: %s contributes %d relics and %d events; expected %d and %d"
				% [culture, relics.size(), events.size(), RELICS_PER_PLAYER, EVENTS_PER_PLAYER])
	var result: Array[String] = []
	result.append_array(relics.slice(0, RELICS_PER_PLAYER))
	result.append_array(events.slice(0, EVENTS_PER_PLAYER))
	return result


func _handler(card_id: String) -> RelicEventHandler:
	if not _handlers.has(card_id):
		_handlers[card_id] = RelicEventRegistry.get_handler(card_id)
	return _handlers[card_id]


func _sys() -> AbilitySystem:
	return RulesEngine.systems().ability


func _sync() -> void:
	if not _is_current():
		_reset_for(GameState.match_state)


func _reset_for(state: MatchState) -> void:
	_match = state
	_active.clear()
	_veil_queue.clear()
	_next_event_id = 0
	_pending.clear()
	_relic_state.clear()


func _is_current() -> bool:
	return _match != null and GameState.match_state == _match
