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
		"vault":
			# Iset-Nara L3: "The Hidden Vault is a placed object with 3 HP." Blocks movement and
			# line of sight like other solid objects.
			return PlacedObjectDef.new("vault", true, true, 3)
		"leak":
			# A Leak marker is a placed object (designer ruling 2026-10-06) that blocks neither
			# movement nor line of sight, has no owner (""), and no HP. Entering it deals 1
			# damage and removes it (AbilitySystem._enter_tiles).
			return PlacedObjectDef.new("leak", false, false, 0)
		_:
			push_error("PlacedObjectRegistry: unknown type_id '%s'" % type_id)
			return null
