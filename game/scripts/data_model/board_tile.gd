class_name BoardTile
extends RefCounted
# Live state for one of the 49 board tiles. Owned exclusively by BoardModel.
# A tile holds at most one of occupant_id or object_id at a time.

var position: Vector2i
var occupant_id: String = ""   # character id, or "" if empty
var object_id: String = ""     # PlacedObjectInstance id, or "" if none
var terrain_type: String = ""  # e.g. "frost"; BoardModel stores it but never interprets it
var leak: bool = false         # a Leak marker: the first character to enter takes 1 damage (AbilitySystem)
var is_center: bool = false


func _init(p_position: Vector2i = Vector2i.ZERO) -> void:
	position = p_position
