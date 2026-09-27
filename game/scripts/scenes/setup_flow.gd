extends Node
# Match setup: culture selection and player-chosen back-row deployment (BR-007A),
# then hands a built MatchState to GameState (LLD-match-setup 3.6, 4.1).
# Visuals belong to the presentation layer; the UI polls these query methods.

var board := BoardModel.new()
var _pending_players: Dictionary = {}   # String player_id -> PlayerState


func select_culture(player_id: String, culture: String) -> void:
	# Re-selecting before placing replaces the squad. Both players may pick the same
	# culture (a mirror match); instance ids stay unique via the player prefix.
	if not GameEnums.PLAYER_IDS.has(player_id):
		push_error("SetupFlow.select_culture: unknown player '%s'" % player_id)
		return
	if ContentDB.get_characters_by_culture(culture).size() != GameEnums.CHARACTER_TYPES.size():
		push_error("SetupFlow.select_culture: culture '%s' has no complete squad" % culture)
		return
	var previous: PlayerState = _pending_players.get(player_id)
	if previous != null:
		for c in previous.characters:
			if c.is_placed():
				board.clear_occupant(c.position)
	var player := PlayerState.new()
	player.id = player_id
	player.culture = culture
	player.characters = _build_squad(player_id, culture)
	_pending_players[player_id] = player


func get_player(player_id: String) -> PlayerState:
	return _pending_players.get(player_id)


func place_character(player_id: String, instance_id: String, pos: Vector2i) -> bool:
	if get_placement_error(player_id, instance_id, pos) != "":
		return false
	var character := get_player(player_id).find_character(instance_id)
	character.position = pos
	board.set_occupant(pos, instance_id)
	return true


func get_placement_error(player_id: String, instance_id: String, pos: Vector2i) -> String:
	# "" if the placement is legal, otherwise a reason the UI can show.
	var player := get_player(player_id)
	if player == null:
		return "choose a culture first"
	var character := player.find_character(instance_id)
	if character == null:
		return "not one of your characters"
	if character.is_placed():
		return "already placed"
	if not board.is_in_bounds(pos):
		return "off the board"
	if pos.y != board.get_edge_row(_side_of(player_id)):
		return "outside your back row"
	if board.is_occupied_by_character(pos) or board.get_placed_object(pos) != null:
		return "tile occupied"
	return ""


func is_player_ready(player_id: String) -> bool:
	var player := get_player(player_id)
	return player != null and player.characters.all(func(c: CharacterInstance) -> bool: return c.is_placed())


func start_match() -> void:
	# The UI only offers "start match" once both players are ready.
	for id in GameEnums.PLAYER_IDS:
		if not is_player_ready(id):
			push_error("SetupFlow.start_match: player %s has not placed all characters" % id)
			return
	var state := MatchState.new()
	state.players = [get_player("p1"), get_player("p2")]
	state.board = board
	state.phase = "setup"
	GameState.start_match(state)
	RelicEventDeck.build_deck(state.players[0].culture, state.players[1].culture, randi())
	state.first_player_id = "p1"   # a coin flip replaces this later (BR-018A)
	TurnManager.start_turn(state.first_player_id)


func _build_squad(player_id: String, culture: String) -> Array[CharacterInstance]:
	var squad: Array[CharacterInstance] = []
	for data in ContentDB.get_characters_by_culture(culture):
		var c := CharacterInstance.new()
		c.instance_id = "%s_%s" % [player_id, data.id]
		c.data = data
		c.player_id = player_id
		c.current_hp = data.hp
		c.base_max_hp = data.hp
		c.character_ap_max = 1
		c.character_ap_remaining = 1
		squad.append(c)
	return squad


static func _side_of(player_id: String) -> int:
	return 1 if player_id == "p1" else 2
