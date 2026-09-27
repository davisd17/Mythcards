class_name PlacedObjectInstance
extends RefCounted
# Runtime state for one placed object. Owned by BoardModel, referenced by BoardTile.object_id.

var id: String = ""              # unique instance id, e.g. "obj_3"
var type_id: String = ""         # key into PlacedObjectRegistry
var owner_player_id: String = "" # which player created it
var max_hp: int = 0              # starts at the registry default; abilities may raise it (Fortified Works)
var current_hp: int = 0          # meaningful only if the def's default_max_hp > 0
