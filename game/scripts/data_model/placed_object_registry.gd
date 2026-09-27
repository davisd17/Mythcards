class_name PlacedObjectRegistry
# Every placed object blocks line-of-sight by default (BR-011A); no card grants an
# exception yet.


static func get_def(type_id: String) -> PlacedObjectDef:
	match type_id:
		"barricade":
			return PlacedObjectDef.new("barricade", true, true, 2)  # "Barricades block movement and have 2 HP"
		"pylon":
			return PlacedObjectDef.new("pylon", false, true, 1)     # no movement block; 1 HP at L1 (designer ruling 2026-09-27), 2 from Architect L2
		"stone":
			return PlacedObjectDef.new("stone", true, true, 1)      # Stone-Line Laborer: "placed objects with 1 HP that block movement"
		_:
			push_error("PlacedObjectRegistry: unknown type_id '%s'" % type_id)
			return null
