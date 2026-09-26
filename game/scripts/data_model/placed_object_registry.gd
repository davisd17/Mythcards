class_name PlacedObjectRegistry
# Every placed object blocks line-of-sight by default (BR-011A); no card grants an
# exception yet.


static func get_def(type_id: String) -> PlacedObjectDef:
	match type_id:
		"barricade":
			return PlacedObjectDef.new("barricade", true, true, 2)  # "Barricades block movement and have 2 HP"
		"pylon":
			return PlacedObjectDef.new("pylon", false, true, 0)     # no movement block or base HP stated for L1 Pylon
		"stone":
			return PlacedObjectDef.new("stone", true, true, 1)      # Stone-Line Laborer: "placed objects with 1 HP that block movement"
		_:
			push_error("PlacedObjectRegistry: unknown type_id '%s'" % type_id)
			return null
