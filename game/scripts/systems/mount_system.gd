class_name MountSystem
extends RefCounted
# Movement queries are implemented (BR-014: a mounted pair moves with the Mount's MOVE
# and pattern). mount()/dismount() are placeholders for HLD build step 9
# (LLD-combat-mount.md); their signatures are the contract RulesEngine calls.

var board: BoardModel


func _init(p_board: BoardModel) -> void:
	board = p_board


func get_effective_move_stat(rider: CharacterInstance) -> int:
	var mount_char := _mount_of(rider)
	return mount_char.get_effective_move() if mount_char != null else rider.get_effective_move()


func get_effective_movement_pattern(_rider: CharacterInstance) -> String:
	# No current Mount changes the pattern itself; Glide-style pass-through comes from
	# AbilitySystem's predicates, asked of the Mount.
	return "orthogonal"


func mount(_rider: CharacterInstance, _mount_char: CharacterInstance) -> void:
	push_error("MountSystem.mount: mounting arrives in build step 9")


func dismount(_rider: CharacterInstance, _to: Vector2i) -> void:
	push_error("MountSystem.dismount: dismounting arrives in build step 9")


func _mount_of(rider: CharacterInstance) -> CharacterInstance:
	if not rider.is_mounted_rider or GameState.match_state == null:
		return null
	return GameState.match_state.find_character(rider.mounted_with_id)
