extends AbilityHandler
# Crystal Architect (Specialist) — Pylon / Relay Gate (LLD-ability-system 5.13).
# L1 Pylon: place a quartz pylon on an adjacent empty tile, or move one of your pylons
#    1 tile. Payload: {"target": pos} or {"move_from": pos, "target": pos}.
#    Allies within 2 tiles of a pylon gain +1 RANGE on abilities.
# L2: place within 2; pylons have 2 HP; the bonus covers attacks too.
# L3 Relay Gate: +1 HP. Standalone ability "a-architect_l3", once per turn: teleport an
#    ally adjacent to a pylon to an empty tile adjacent to another pylon within 4 tiles
#    of the first, then shield it (1). Payload: {"target": ally id, "to": pos}.
# "Pylon" includes a Level 3 Quartz Attendant (AbilitySystem.is_pylon_source).

const L3_ID := "a-architect_l3"
const PYLON_REACH := [0, 1, 2, 2]   # by level
const PYLON_HP := [0, 1, 2, 2]   # L1 1 HP (designer ruling 2026-09-27), L2 "Pylons have 2 HP"
const PYLON_AURA_RANGE := 2
const PYLON_RANGE_BONUS := 1
const RELAY_DISTANCE := 4
const RELAY_SHIELD := 1


func level_bonuses() -> Dictionary:
	return {3: {"hp": 1}}


func on_level_up(sys, instance: CharacterInstance, new_level: int) -> void:
	if new_level != 2:
		return
	for pos in sys.pylon_sources(instance.player_id):
		var obj: PlacedObjectInstance = sys.board.get_placed_object(pos)
		if obj != null and obj.max_hp < PYLON_HP[2]:
			obj.max_hp = PYLON_HP[2]
			obj.current_hp = PYLON_HP[2]


func get_aura_range_bonus(sys, source: CharacterInstance, target: CharacterInstance, context: String) -> int:
	if context == "attack" and source.level < 2:
		return 0
	for pos in sys.pylon_sources(source.player_id):
		if sys.distance(pos, target.position) <= PYLON_AURA_RANGE:
			return PYLON_RANGE_BONUS
	return 0


func ability_ids(instance: CharacterInstance) -> Array[String]:
	return [instance.data.id, L3_ID]


func can_use(sys, instance: CharacterInstance, ability_id: String) -> bool:
	if ability_id == L3_ID:
		return instance.level >= 3 and not sys.used_this_turn(instance, "relay_gate_used")
	return true


func get_legal_targets(sys, instance: CharacterInstance, ability_id: String) -> Array:
	if ability_id == L3_ID:
		var result := []
		for ally in sys.allies_of(instance):
			if not _adjacent_sources(sys, instance, ally.position).is_empty():
				result.append(ally.instance_id)
		return result
	return _placement_tiles(sys, instance)


func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	if ability_id == L3_ID:
		if not get_legal_targets(sys, instance, ability_id).has(str(payload.get("target", ""))):
			return "needs an ally next to a pylon"
		var ally: CharacterInstance = sys.find(str(payload.target))
		if not _relay_destinations(sys, instance, ally).has(payload.get("to")):
			return "needs an empty tile next to another pylon within 4"
		return ""
	var to = payload.get("target")
	if payload.has("move_from"):
		var from = payload.move_from
		var obj: PlacedObjectInstance = sys.board.get_placed_object(from) if from is Vector2i else null
		if obj == null or obj.type_id != "pylon" or obj.owner_player_id != instance.player_id:
			return "not one of your pylons"
		if not (to is Vector2i and sys.is_adjacent(from, to) and sys.is_empty_tile(to)):
			return "a pylon moves 1 tile to an empty tile"
		return ""
	return "" if _placement_tiles(sys, instance).has(to) else "illegal ability target"


func execute(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if ability_id == L3_ID:
		instance.ability_uses_this_turn["relay_gate_used"] = true
		var ally: CharacterInstance = sys.find(str(payload.target))
		sys.reposition_character(ally, payload.to, "teleport")
		sys.add_status(ally, "shield", RELAY_SHIELD, "this_turn", instance)
		return {"success": true}
	if payload.has("move_from"):
		var old: PlacedObjectInstance = sys.board.get_placed_object(payload.move_from)
		sys.board.remove_object(payload.move_from)
		sys.board.place_object(payload.target, "pylon", instance.player_id)
		var moved: PlacedObjectInstance = sys.board.get_placed_object(payload.target)
		moved.max_hp = old.max_hp
		moved.current_hp = old.current_hp
		return {"success": true}
	sys.board.place_object(payload.target, "pylon", instance.player_id)
	var obj: PlacedObjectInstance = sys.board.get_placed_object(payload.target)
	obj.max_hp = PYLON_HP[instance.level]
	obj.current_hp = obj.max_hp
	return {"success": true}


func _placement_tiles(sys, instance: CharacterInstance) -> Array:
	var reach: int = PYLON_REACH[instance.level]
	var tiles: Array = sys.neighbors(instance.position) if reach == 1 \
			else sys.tiles_in_reach(instance, instance.position, sys.ability_reach(instance, reach))
	return tiles.filter(func(pos): return sys.is_empty_tile(pos))


func _adjacent_sources(sys, instance: CharacterInstance, pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for n in sys.neighbors(pos):
		if sys.is_pylon_source(n, instance.player_id):
			result.append(n)
	return result


func _relay_destinations(sys, instance: CharacterInstance, ally: CharacterInstance) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var starts := _adjacent_sources(sys, instance, ally.position)
	for end in sys.pylon_sources(instance.player_id):
		var reachable := starts.any(func(s): return s != end and sys.distance(s, end) <= RELAY_DISTANCE)
		if not reachable:
			continue
		for pos in sys.neighbors(end):
			if sys.is_empty_tile(pos) and not result.has(pos):
				result.append(pos)
	return result
