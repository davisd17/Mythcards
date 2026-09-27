extends Node
# Autoload name: RelicEventDeck — the shared relic/event deck (LLD-relic-event-deck.md).
# Each player contributes their culture's 3 relics + 4 events; the 14 cards are shuffled
# with a seed, and the active player draws one at the start of each turn. Relics fill
# the player's single slot (a full slot means a keep-or-replace choice); events resolve
# at once or last their duration. Decisions wait as a pending choice, resolved through
# RulesEngine's "deck_choice" action before the player can act.

const RELICS_PER_PLAYER := 3
const EVENTS_PER_PLAYER := 4

var _match: MatchState = null
var _active: Dictionary = {}    # card id -> {player_id, remaining, drawn_on_turn, data}
var _pending: Dictionary = {}   # player id -> {kind: "relic"|"event", card_id, revealed?}
var _handlers: Dictionary = {}


func _ready() -> void:
	EventBus.turn_started.connect(_on_turn_started)


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
	if card.duration == "Immediate":
		var outcome := handler.resolve_immediate(_sys(), player_id)
		if outcome.get("needs_choice", false):
			_pending[player_id] = {"kind": "event", "card_id": card_id, "revealed": outcome.get("revealed", "")}
			return
		EventBus.event_resolved.emit(card_id)
		return
	_active[card_id] = {
		"player_id": player_id,
		"remaining": 2 if card.duration == "1 round" else 1,   # a round = 2 individual turns
		"drawn_on_turn": _match.turn_number,
		"data": handler.on_activate(_sys(), player_id),
	}
	EventBus.event_resolved.emit(card_id)


func has_pending_choice(player_id: String) -> bool:
	return _is_current() and _pending.has(player_id)


func get_pending_choice(player_id: String) -> Dictionary:
	return _pending.get(player_id, {}) if _is_current() else {}


# RulesEngine's "deck_choice" action. Relic: {"keep_new": bool}. Event: card-specific.
func resolve_choice(player_id: String, payload: Dictionary) -> Dictionary:
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
		_pending.erase(player_id)
		EventBus.event_resolved.emit(pending.card_id)
	return result


func is_active(card_id: String) -> bool:
	return _is_current() and _active.has(card_id)


# Deck-top access for Foresight / Dream Of The Deep City. Index 0 is the next draw.
func peek_next() -> String:
	var state := GameState.match_state
	return state.shared_deck[0] if state != null and not state.shared_deck.is_empty() else ""


func move_top_to_bottom() -> void:
	var state := GameState.match_state
	if state != null and state.shared_deck.size() > 1:
		state.shared_deck.append(state.shared_deck.pop_front())


# --- Relic queries (AbilitySystem, CombatResolver) ---------------------------------

func get_relic_max_hp_bonus(sys, target: CharacterInstance) -> int:
	var total := 0
	for owner in _relic_owners():
		total += _handler(owner.active_relic_id).get_max_hp_bonus(sys, owner.id, target)
	return total


func get_relic_shield_bonus(sys, defender: CharacterInstance) -> int:
	var total := 0
	for owner in _relic_owners():
		total += _handler(owner.active_relic_id).get_shield_bonus(sys, owner.id, defender)
	return total


func get_relic_range_bonus(sys, instance: CharacterInstance, context: String) -> int:
	var total := 0
	for owner in _relic_owners():
		total += _handler(owner.active_relic_id).get_range_bonus(sys, owner.id, instance, context)
	return total


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
			_handler(card_id).on_expire(_sys(), entry.player_id, entry.data)
	var player := _match.get_player(player_id)
	if player != null and player.active_relic_id != "":
		_handler(player.active_relic_id).on_owner_turn_started(_sys(), player_id)


func _set_relic(player: PlayerState, card_id: String) -> void:
	player.active_relic_id = card_id
	EventBus.relic_slot_changed.emit(player.id, card_id)
	# A replaced relic may have raised max HP; nobody keeps HP above the new maximum.
	var sys := _sys()
	for p in _match.players:
		for c in p.characters:
			if not c.defeated:
				c.current_hp = mini(c.current_hp, sys.get_effective_max_hp(c))


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
			events.append(card.id)
	if relics.size() != RELICS_PER_PLAYER or events.size() != EVENTS_PER_PLAYER:
		push_error("RelicEventDeck: %s contributes %d relics and %d events; expected %d and %d"
				% [culture, relics.size(), events.size(), RELICS_PER_PLAYER, EVENTS_PER_PLAYER])
	var result: Array[String] = []
	result.append_array(relics.slice(0, RELICS_PER_PLAYER))
	result.append_array(events.slice(0, EVENTS_PER_PLAYER))
	return result


func _relic_owners() -> Array[PlayerState]:
	var result: Array[PlayerState] = []
	var state := GameState.match_state
	if state != null:
		for p in state.players:
			if p.active_relic_id != "":
				result.append(p)
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
	_pending.clear()


func _is_current() -> bool:
	return _match != null and GameState.match_state == _match
