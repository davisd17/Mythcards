extends Node
# Autoload name: VictoryChecker — the two ways a match ends (LLD-victory-checker.md).
#   Hero capture (BR-034): at the end of its controller's turn, the Hero (or its mounted
#     pair) has no legal move. Checked by TurnManager.end_turn before the turn passes.
#   Army defeat (BR-035): every character on one side is defeated. Checked on each defeat.


func _ready() -> void:
	EventBus.character_defeated.connect(_on_character_defeated)


func check_hero_capture(player_id: String) -> void:
	var state := GameState.match_state
	if state == null or state.phase == "ended":
		return
	var hero := _hero_of(state.get_player(player_id))
	# A Hero defeated in combat is not "captured"; its fall counts toward army defeat
	# instead (BR-034A). An unplaced Hero (setup, test arrangements) has nothing to check.
	if hero == null or hero.defeated or not hero.is_placed():
		return
	# The same legality query the move action validates against, so a Hero can never be
	# "trapped" by one code path and "free" by another (HLD-R-002). It already handles
	# mounted pairs, status effects, and pass-through abilities.
	var has_legal_move := not RulesEngine.get_legal_move_tiles(hero.instance_id).is_empty()
	EventBus.hero_capture_checked.emit(player_id, has_legal_move)
	if not has_legal_move:
		_end_match(state.get_other_player_id(player_id), "hero_capture")


func _on_character_defeated(character_id: String, _defeated_by_id: String, _cause: String) -> void:
	# Every emission counts, including a Mount falling with its rider.
	var state := GameState.match_state
	if state == null or state.phase == "ended":
		return
	var fallen := state.find_character(character_id)
	if fallen == null:
		return
	var side := state.get_player(fallen.player_id)
	if side.characters.all(func(c: CharacterInstance) -> bool: return c.defeated):
		_end_match(state.get_other_player_id(fallen.player_id), "army_defeat")


func _end_match(winner_id: String, condition: String) -> void:
	# The single path both conditions end a match through.
	var state := GameState.match_state
	state.winner_id = winner_id
	state.win_condition = condition
	state.phase = "ended"
	EventBus.match_ended.emit(winner_id, condition)


static func _hero_of(player: PlayerState) -> CharacterInstance:
	if player == null:
		return null
	for c in player.characters:
		if c.data.type == "Hero":
			return c
	return null
