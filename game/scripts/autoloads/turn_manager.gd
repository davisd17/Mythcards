extends Node
# Autoload name: TurnManager — turn alternation and AP refresh (LLD-match-setup 3.8).
# Owns AP *refresh* only; RulesEngine spends AP during actions.

const FIRST_TURN_POOL_AP := 2
const POOL_AP := 4

# Collaborators, replaceable in tests. null means "use the autoload", resolved at call
# time because those autoloads load after this one.
var victory_checker: Object = null
var relic_event_deck: Object = null


func start_turn(player_id: String) -> void:
	var state := GameState.match_state
	var player := state.get_player(player_id)
	# BR-018: the 2-AP pool is the match's first turn only, so only the player who goes
	# first pays it. turn_number is still 0 on that one turn (incremented below).
	player.pool_ap_max = FIRST_TURN_POOL_AP if state.turn_number == 0 else POOL_AP
	player.pool_ap_remaining = player.pool_ap_max
	for character in player.characters:
		character.character_ap_remaining = character.character_ap_max
		character.ability_uses_this_turn.clear()
		_clear_expired_status_effects(character, state.turn_number + 1)
	player.player_flags_this_turn.clear()
	state.active_player_id = player_id
	state.turn_number += 1
	_relic_event_deck().draw_for(player_id)
	EventBus.turn_started.emit(player_id)
	EventBus.pool_ap_changed.emit(player_id, player.pool_ap_remaining)
	for character in player.characters:
		EventBus.character_ap_changed.emit(character.instance_id, character.character_ap_remaining)


func end_turn(player_id: String) -> void:
	# The Hero-capture check runs against the player who just acted, before the turn
	# flips (BR-034, HLD Flow C). If it ends the match, nothing else happens.
	_victory_checker().check_hero_capture(player_id)
	var state := GameState.match_state
	if state.phase == "ended":
		return
	EventBus.turn_ended.emit(player_id)
	start_turn(state.get_other_player_id(player_id))


func _clear_expired_status_effects(character: CharacterInstance, starting_turn: int) -> void:
	# Runs at the owner's turn start, before they can act (LLD-match-setup 4.3).
	var kept: Array[StatusEffect] = []
	for se in character.status_effects:
		match se.expires:
			"immediate", "this_turn":
				continue
			"this_round":
				# A round is both players taking one turn.
				if starting_turn - se.applied_on_turn >= 2:
					continue
			"next_turn":
				# Survives exactly one of the holder's own turn starts: in force for the
				# holder's next turn, gone at the one after.
				if se.ticks >= 1:
					continue
				se.ticks += 1
		kept.append(se)
	character.status_effects = kept


func _victory_checker() -> Object:
	return victory_checker if victory_checker != null else VictoryChecker


func _relic_event_deck() -> Object:
	return relic_event_deck if relic_event_deck != null else RelicEventDeck
