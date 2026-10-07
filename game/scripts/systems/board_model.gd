class_name BoardModel
extends RefCounted
# Owns the 7x7 tile state and the shared movement / line-of-sight / range queries
# every other module calls instead of re-deriving them (LLD-content-board 3.6).
# Pure query/mutation surface: emits no signals; callers emit after mutating.

const BOARD_SIZE := 7
const CENTER_TILE := Vector2i(3, 3)
const PLAYER_A_EDGE_ROW := 0   # internal coordinate convention only; no gameplay effect
const PLAYER_B_EDGE_ROW := 6

const ORTHOGONAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT
]

var _tiles: Array[BoardTile] = []   # size 49; index = y * BOARD_SIZE + x
var _objects: Dictionary = {}       # String object_id -> PlacedObjectInstance
var _next_object_id: int = 0


func _init() -> void:
	for y in BOARD_SIZE:
		for x in BOARD_SIZE:
			var tile := BoardTile.new(Vector2i(x, y))
			tile.is_center = tile.position == CENTER_TILE
			_tiles.append(tile)


func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE


func get_tile(pos: Vector2i) -> BoardTile:
	# Returns null out of bounds; never clamps.
	if not is_in_bounds(pos):
		return null
	return _tiles[pos.y * BOARD_SIZE + pos.x]


func is_occupied_by_character(pos: Vector2i) -> bool:
	var tile := get_tile(pos)
	return tile != null and tile.occupant_id != ""


func get_placed_object(pos: Vector2i) -> PlacedObjectInstance:
	var tile := get_tile(pos)
	if tile == null or tile.object_id == "":
		return null
	return _objects.get(tile.object_id, null)


func is_blocked_for_movement(pos: Vector2i) -> bool:
	if is_occupied_by_character(pos):
		return true
	var def := _object_def_at(pos)
	return def != null and def.blocks_movement


func blocks_line_of_sight(pos: Vector2i) -> bool:
	if is_occupied_by_character(pos):
		return true
	var def := _object_def_at(pos)
	return def != null and def.blocks_line_of_sight


func set_occupant(pos: Vector2i, character_id: String) -> void:
	# Does not guard against double occupancy — that is RulesEngine's validation job.
	get_tile(pos).occupant_id = character_id


func clear_occupant(pos: Vector2i) -> void:
	get_tile(pos).occupant_id = ""


func place_object(pos: Vector2i, type_id: String, owner_player_id: String) -> String:
	# Enforces only the tile-level invariant (one thing per tile). Whether placing here is
	# a legal action is AbilitySystem's call. Returns "" and push_errors on misuse.
	var tile := get_tile(pos)
	if tile == null:
		push_error("BoardModel.place_object: %s is out of bounds" % pos)
		return ""
	if tile.occupant_id != "" or tile.object_id != "":
		push_error("BoardModel.place_object: tile %s is not empty" % pos)
		return ""
	var def := PlacedObjectRegistry.get_def(type_id)
	if def == null:
		return ""
	var obj := PlacedObjectInstance.new()
	obj.id = "obj_%d" % _next_object_id
	_next_object_id += 1
	obj.type_id = type_id
	obj.owner_player_id = owner_player_id
	obj.max_hp = def.default_max_hp
	obj.current_hp = def.default_max_hp
	_objects[obj.id] = obj
	tile.object_id = obj.id
	return obj.id


func remove_object(pos: Vector2i) -> void:
	var tile := get_tile(pos)
	if tile == null or tile.object_id == "":
		return
	_objects.erase(tile.object_id)
	tile.object_id = ""


func get_edge_row(player_side: int) -> int:
	match player_side:
		1:
			return PLAYER_A_EDGE_ROW
		2:
			return PLAYER_B_EDGE_ROW
		_:
			push_error("BoardModel.get_edge_row: player_side must be 1 or 2, got %d" % player_side)
			return -1


func is_center(pos: Vector2i) -> bool:
	return pos == CENTER_TILE


func get_legal_moves(from: Vector2i, move_budget: int, pattern: String = "orthogonal",
		passable_predicate: Callable = Callable(),
		object_passable_predicate: Callable = Callable(),
		max_passes: int = -1, ignore_terrain: bool = false, max_char_passes: int = -1) -> Array[Vector2i]:
	# Straight-line movement (designer ruling 2026-09-27): up to move_budget tiles in ONE of
	# the four directions, no turning. passable_predicate: may pass through (not stop on) a
	# character-occupied tile; object_passable_predicate: same for movement-blocking
	# objects. max_passes caps pass-throughs (characters and objects) along the line; -1 =
	# unlimited. max_char_passes further caps the characters passed (Ahesu: any number of
	# Stones, but 1 ally). Entering frost ends the line there unless ignore_terrain.
	var result: Array[Vector2i] = []
	if pattern != "orthogonal":
		push_error("BoardModel.get_legal_moves: unsupported pattern '%s'" % pattern)
		return result
	for dir in ORTHOGONAL_DIRECTIONS:
		var cursor := from
		var passes := 0
		var char_passes := 0
		for _step in move_budget:
			cursor += dir
			if not is_in_bounds(cursor):
				break
			if is_occupied_by_character(cursor):
				var may_pass: bool = passable_predicate.is_valid() and passable_predicate.call(cursor)
				if not may_pass or (max_passes >= 0 and passes >= max_passes) \
						or (max_char_passes >= 0 and char_passes >= max_char_passes):
					break
				passes += 1
				char_passes += 1
				continue   # can pass, can't stop
			var def := _object_def_at(cursor)
			if def != null and def.blocks_movement:
				var may_pass_object: bool = object_passable_predicate.is_valid() and object_passable_predicate.call(cursor)
				if not may_pass_object or (max_passes >= 0 and passes >= max_passes):
					break
				passes += 1
				continue
			result.append(cursor)
			if not ignore_terrain and get_tile(cursor).terrain_type == "frost":
				break
	return result


# The tiles strictly between two points on a straight line ([] if not on one line).
static func tiles_between(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if from == to or (from.x != to.x and from.y != to.y):
		return result
	var step := Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	var cursor := from + step
	while cursor != to:
		result.append(cursor)
		cursor += step
	return result


func has_line_of_sight(from: Vector2i, to: Vector2i, ignore_ids: Array[String] = []) -> bool:
	# LLD 4.2. ignore_ids applies to character occupants only (e.g. Link Mind's ally exception).
	if from == to:
		return true
	if from.x != to.x and from.y != to.y:
		return false
	var step := Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	var cursor := from + step
	while cursor != to:
		if is_occupied_by_character(cursor):
			if not ignore_ids.has(get_tile(cursor).occupant_id):
				return false
		else:
			var def := _object_def_at(cursor)
			if def != null and def.blocks_line_of_sight:
				return false
		cursor += step
	return true


func get_tiles_in_range(origin: Vector2i, attack_range: int, pattern: String = "orthogonal_line") -> Array[Vector2i]:
	# LLD 4.3. Purely geometric — callers filter the result through has_line_of_sight().
	var result: Array[Vector2i] = []
	if pattern != "orthogonal_line":
		push_error("BoardModel.get_tiles_in_range: unsupported pattern '%s'" % pattern)
		return result
	for dir in ORTHOGONAL_DIRECTIONS:
		var cursor := origin
		for _step in attack_range:
			cursor += dir
			if not is_in_bounds(cursor):
				break
			result.append(cursor)
	return result


func _object_def_at(pos: Vector2i) -> PlacedObjectDef:
	var obj := get_placed_object(pos)
	if obj == null:
		return null
	return PlacedObjectRegistry.get_def(obj.type_id)
