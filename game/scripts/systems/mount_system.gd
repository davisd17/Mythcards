class_name MountSystem
extends RefCounted
# Mounted-pair tile mechanics and stat inheritance (LLD-combat-mount.md 3.2).
# RulesEngine validates legality before calling mount()/dismount().

var board: BoardModel


func _init(p_board: BoardModel) -> void:
	board = p_board


func mount(rider: CharacterInstance, mount_char: CharacterInstance) -> void:
	# BR-012/BR-013: the pair shares the rider's tile; the Mount's tile empties.
	rider.mounted_with_id = mount_char.instance_id
	mount_char.mounted_with_id = rider.instance_id
	rider.is_mounted_rider = true
	mount_char.is_mounted_rider = false
	var from := mount_char.position
	board.clear_occupant(from)
	mount_char.position = rider.position
	EventBus.character_repositioned.emit(mount_char.instance_id, from, rider.position, "mount")


func dismount(rider: CharacterInstance, to: Vector2i) -> void:
	# BR-017: the rider stays put; the Mount steps out onto `to`.
	var mount_char := _mount_of(rider)
	if mount_char == null:
		push_error("MountSystem.dismount: %s has no resolvable mount" % rider.instance_id)
		return
	var from := mount_char.position
	board.set_occupant(to, mount_char.instance_id)
	mount_char.position = to
	rider.mounted_with_id = ""
	mount_char.mounted_with_id = ""
	rider.is_mounted_rider = false
	EventBus.character_repositioned.emit(mount_char.instance_id, from, to, "dismount")


func get_effective_move_stat(rider: CharacterInstance) -> int:
	# BR-014: a mounted pair moves with the Mount's MOVE.
	var mount_char := _mount_of(rider)
	return mount_char.get_effective_move() if mount_char != null else rider.get_effective_move()


func get_effective_movement_pattern(_rider: CharacterInstance) -> String:
	# No current Mount changes the pattern itself; Glide-style pass-through comes from
	# AbilitySystem's predicates, asked of the Mount.
	return "orthogonal"


func handle_rider_defeated(rider: CharacterInstance) -> CharacterInstance:
	# BR-016: the Mount is defeated with its rider. Returns it so CombatResolver can emit
	# its character_defeated; returns null (after push_error) if the link is broken.
	var mount_char := _mount_of(rider)
	if mount_char == null:
		push_error("MountSystem.handle_rider_defeated: %s has no resolvable mount" % rider.instance_id)
		return null
	if board.get_tile(mount_char.position) != null and board.get_tile(mount_char.position).occupant_id == mount_char.instance_id:
		board.clear_occupant(mount_char.position)
	mount_char.defeated = true
	rider.mounted_with_id = ""
	rider.is_mounted_rider = false
	mount_char.mounted_with_id = ""
	return mount_char


func _mount_of(rider: CharacterInstance) -> CharacterInstance:
	if not rider.is_mounted_rider or GameState.match_state == null:
		return null
	return GameState.match_state.find_character(rider.mounted_with_id)
