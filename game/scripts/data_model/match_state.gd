class_name MatchState
extends RefCounted
# The single live-state root, held by the GameState autoload (LLD-match-setup 3.5).

var players: Array[PlayerState] = []   # index 0 = "p1", index 1 = "p2"
var board: BoardModel = null           # the BoardModel itself, not a copied tile array
var turn_number: int = 0               # +1 per individual turn (p1 = 1, p2 = 2, p1 = 3, ...)
var active_player_id: String = ""
var first_player_id: String = ""       # "p1" today; a coin flip will set it later (BR-018A)
var next_instance_serial: int = 1      # for ids of characters created after setup
var shared_deck: Array[String] = []    # remaining relic/event draw order; owned by RelicEventDeck
var deck_seed: int = 0
var phase: String = ""                 # one of GameEnums.MATCH_PHASES
var winner_id: String = ""             # set by VictoryChecker
var win_condition: String = ""         # one of GameEnums.WIN_CONDITIONS


func get_player(player_id: String) -> PlayerState:
	for p in players:
		if p.id == player_id:
			return p
	return null


func get_other_player_id(player_id: String) -> String:
	match player_id:
		"p1":
			return "p2"
		"p2":
			return "p1"
		_:
			push_error("MatchState.get_other_player_id: unknown player '%s'" % player_id)
			return ""


func find_character(instance_id: String) -> CharacterInstance:
	for p in players:
		var c := p.find_character(instance_id)
		if c != null:
			return c
	return null


func mint_instance_id(player_id: String, data_id: String) -> String:
	# Only for characters created AFTER setup (copies). Setup-phase ids use the plain
	# "p1_<card id>" form, unique because setup forbids duplicate characters per side.
	var id := "%s_%s#%d" % [player_id, data_id, next_instance_serial]
	next_instance_serial += 1
	return id
