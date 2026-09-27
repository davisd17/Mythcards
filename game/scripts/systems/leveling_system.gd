class_name LevelingSystem
extends RefCounted
# Decides WHEN a character levels up (LLD-leveling.md): Level 2 on reaching the
# opponent's edge row, a Spirit Ember on every defeat, Level 3 on reaching the center
# while Level 2 with an Ember. AbilitySystem.apply_level_up_effects decides WHAT the
# level-up does.
#
# Listens to EventBus synchronously; the Level 2 -> Level 3 same-move chain relies on
# that, so never connect these with CONNECT_DEFERRED.

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
	_check_level_3(character)
	# A ridden Mount moves with its rider but only the rider's id is in the signal.
	if character.mounted_with_id != "":
		var partner := _match.find_character(character.mounted_with_id)
		if partner != null:
			_check_level_2(partner)
			_check_level_3(partner)


func _on_character_repositioned(character_id: String, from: Vector2i, to: Vector2i, _cause: String) -> void:
	_on_character_moved(character_id, from, to)


func _on_character_defeated(_character_id: String, defeated_by_id: String, _cause: String) -> void:
	# Every defeat releases an Ember, including a Mount falling with its rider (BR-023A).
	if not _is_current():
		return
	var attacker := _match.find_character(defeated_by_id)
	if attacker == null:
		return
	attacker.spirit_ember_count += 1
	EventBus.spirit_ember_picked_up.emit(attacker.instance_id)
	_check_level_3(attacker)   # already Level 2 on the center: completes without moving


func _on_character_leveled_up(character_id: String, new_level: int) -> void:
	# Reaching Level 2 while already on the center holding an Ember completes Level 3.
	if not _is_current() or new_level != 2:
		return
	var character := _match.find_character(character_id)
	if character != null:
		_check_level_3(character)


func _check_level_2(character: CharacterInstance) -> void:
	if character.level != 1 or character.defeated:
		return
	var opponent_side := 2 if character.player_id == "p1" else 1
	if character.position.y == board.get_edge_row(opponent_side):
		_level_up(character, 2)


func _check_level_3(character: CharacterInstance) -> void:
	if character.level != 2 or character.spirit_ember_count < 1 or character.defeated:
		return
	if not board.is_center(character.position):
		return
	character.spirit_ember_count -= 1   # surplus Embers stay with the carrier
	_level_up(character, 3)
	EventBus.spirit_ember_delivered.emit(character.instance_id)


func _level_up(character: CharacterInstance, new_level: int) -> void:
	# The only path a level changes through; never exceeds 3.
	character.level = new_level
	ability_system.apply_level_up_effects(character, new_level)
	EventBus.character_leveled_up.emit(character.instance_id, new_level)


func _is_current() -> bool:
	return _match != null and GameState.match_state == _match
