class_name PlacedObjectDef
extends RefCounted

var type_id: String
var blocks_movement: bool
var blocks_line_of_sight: bool
var default_max_hp: int   # 0 = no HP tracked (indestructible at this tier)


func _init(p_type_id: String, p_blocks_movement: bool, p_blocks_line_of_sight: bool, p_default_max_hp: int) -> void:
	type_id = p_type_id
	blocks_movement = p_blocks_movement
	blocks_line_of_sight = p_blocks_line_of_sight
	default_max_hp = p_default_max_hp
