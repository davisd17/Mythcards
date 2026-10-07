extends AbilityHandler
# Stone-Line Laborer (Flood Survivors Common) — LLD-closed-city-flood-roster.md 4.
# L1 Stone Line (AP): place a Stone (1 HP, blocks movement) on an adjacent empty tile.
#    Payload: {"target": pos} (L2 adds "target_2").
# L2 Causeway Crew: +1 HP; up to 2 Stones on different adjacent empty tiles.
# L3 Route To The Surface: +1 MOVE; may move through Stone markers. Once per turn, after
#    a move that passed a Stone, gains Shield.


func level_bonuses() -> Dictionary:
	return {2: {"hp": 1}, 3: {"move": 1}}


func ability_label(_instance: CharacterInstance, _ability_id: String) -> String:
	return "Stone Line"


func can_use(_sys, _instance: CharacterInstance, _ability_id: String) -> bool:
	return true


func get_legal_targets(sys, instance: CharacterInstance, _ability_id: String) -> Array:
	return sys.neighbors(instance.position).filter(func(pos): return sys.is_empty_tile(pos))


func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	var legal := get_legal_targets(sys, instance, ability_id)
	var tiles := _tiles(payload)
	if tiles.is_empty() or tiles.size() > (2 if instance.level >= 2 else 1):
		return "choose an adjacent empty tile"
	for pos in tiles:
		if not legal.has(pos) or tiles.count(pos) > 1:
			return "choose different adjacent empty tiles"
	return ""


func next_step(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	var legal := get_legal_targets(sys, instance, ability_id)
	if not payload.has("target"):
		return target_step("target", "Stone Line: place a Stone on which tile?", legal)
	if instance.level < 2 or payload.has("target_2"):
		return {}
	return second_step("target_2", "Place a second Stone?", legal, payload.target)


func execute(sys, instance: CharacterInstance, _ability_id: String, payload: Dictionary) -> Dictionary:
	for pos in _tiles(payload):
		sys.board.place_object(pos, "stone", instance.player_id)
	return {"success": true}


func get_movement_object_passable_predicate(sys, instance: CharacterInstance) -> Callable:
	if instance.level < 3:
		return Callable()
	return func(pos: Vector2i) -> bool:
		var obj: PlacedObjectInstance = sys.board.get_placed_object(pos)
		return obj != null and obj.type_id == "stone"


func on_character_moved(sys, instance: CharacterInstance, mover: CharacterInstance,
		from: Vector2i, to: Vector2i, _required_pass: bool) -> void:
	if mover != instance or instance.level < 3 or sys.used_this_turn(instance, "route_shield_used"):
		return
	for pos in BoardModel.tiles_between(from, to):
		var obj: PlacedObjectInstance = sys.board.get_placed_object(pos)
		if obj != null and obj.type_id == "stone":
			instance.ability_uses_this_turn["route_shield_used"] = true
			sys.add_status(instance, "shield", 1, "this_turn", instance)
			return


static func _tiles(payload: Dictionary) -> Array:
	var result := []
	for key in ["target", "target_2"]:
		if payload.get(key) is Vector2i:
			result.append(payload[key])
	return result
