class_name LevelingSystem
extends RefCounted
# Decides WHEN a character levels up and handles Spirit Embers (LLD-leveling.md 9A,
# designer rulings 2026-10-11):
# - Level 2: reaching the opponent's edge row.
# - Level 3: a Level 2 character defeats an enemy. (A Level 1 character that defeats an
#   enemy only takes the Embers.)
# - Embers stack: a defeat gives the defeater 1 Ember plus every undelivered Ember the
#   fallen character carried.
# - Delivering: a carrier on the center tile banks every Ember it holds into its team's
#   total; VictoryChecker ends the match at 4 (the Ember win).
# AbilitySystem.apply_level_up_effects decides WHAT a level-up does.

var board: BoardModel
var ability_system: AbilitySystem
var _match: MatchState   # listeners ignore events from any other match (ids repeat across matches)


func _init(p_board: BoardModel, p_ability_system: AbilitySystem) -> void:
	board = p_board
	ability_system = p_ability_system
	_match = GameState.match_state
	EventBus.character_moved.connect(_on_character_moved)
	# Being pushed or placed onto the edge or center counts too (designer ruling 2026-09-27).
	EventBus.character_repositioned.connect(_on_character_repositioned)
	EventBus.character_defeated.connect(_on_character_defeated)
	EventBus.character_leveled_up.connect(_on_character_leveled_up)


func _on_character_moved(character_id: String, _from: Vector2i, _to: Vector2i) -> void:
	if not _is_current():
		return
	var character := _match.find_character(character_id)
	if character == null:
		return
	_check_level_2(character)
	_check_delivery(character)
	# A ridden Mount moves with its rider but only the rider's id is in the signal.
	if character.mounted_with_id != "":
		var partner := _match.find_character(character.mounted_with_id)
		if partner != null:
			_check_level_2(partner)
			_check_delivery(partner)


func _on_character_repositioned(character_id: String, from: Vector2i, to: Vector2i, _cause: String) -> void:
	_on_character_moved(character_id, from, to)


func _on_character_defeated(character_id: String, defeated_by_id: String, _cause: String) -> void:
	# Every defeat releases an Ember, including a Mount falling with its rider (BR-023A),
	# plus whatever the fallen character carried. A hazard defeat (no enemy) loses them.
	if not _is_current():
		return
	var fallen := _match.find_character(character_id)
	var attacker := _match.find_character(defeated_by_id)
	var carried := fallen.spirit_ember_count if fallen != null else 0
	if fallen != null:
		fallen.spirit_ember_count = 0
	if attacker == null or attacker == fallen or (fallen != null and attacker.player_id == fallen.player_id):
		return
	attacker.spirit_ember_count += 1 + carried
	EventBus.spirit_ember_picked_up.emit(attacker.instance_id)
	if attacker.level == 2 and not attacker.defeated:
		_level_up(attacker, 3)
	_check_delivery(attacker)   # standing on the center already: banks at once


func _on_character_leveled_up(_character_id: String, _new_level: int) -> void:
	pass   # kept connected for symmetry; leveling no longer chains on level-up


func _check_level_2(character: CharacterInstance) -> void:
	if character.level != 1 or character.defeated:
		return
	var opponent_side := 2 if character.player_id == "p1" else 1
	if character.position.y == board.get_edge_row(opponent_side):
		_level_up(character, 2)


# A carrier on the center banks all it holds into its team's total.
func _check_delivery(character: CharacterInstance) -> void:
	if character.spirit_ember_count < 1 or character.defeated or not board.is_center(character.position):
		return
	var player := _match.get_player(character.player_id)
	player.embers_delivered += character.spirit_ember_count
	character.spirit_ember_count = 0
	EventBus.spirit_ember_delivered.emit(character.instance_id)


func _level_up(character: CharacterInstance, new_level: int) -> void:
	# The only path a level changes through; never exceeds 3.
	character.level = new_level
	ability_system.apply_level_up_effects(character, new_level)
	EventBus.character_leveled_up.emit(character.instance_id, new_level)


func _is_current() -> bool:
	return _match != null and GameState.match_state == _match
