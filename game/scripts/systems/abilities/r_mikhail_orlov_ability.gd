extends AbilityHandler
# Dr. Mikhail Orlov (Closed City Hero) — LLD-closed-city-flood-roster.md 4.
# L1 Reactor Leak (AP): place a Leak marker on an empty tile within 2.
#    Payload: {"target": pos} (L2 adds "target_2").
# L2 Containment Pattern: +1 RANGE; Reactor Leak may place 2 Leaks on different tiles.
# L3 Slumber: +1 HP. Standalone ability "r-mikhail-orlov_l3", once per match (AP, ruling
#    2026-10-07): Orlov leaves the board until your next turn. Then he returns to an empty
#    tile within 2 of where he left (any empty tile if none) and places 1 Leak on an
#    adjacent empty tile (the "return" bonus; the Leak pick is skipped if none is free).

const L3_ID := "r-mikhail-orlov_l3"
const LEAK_REACH := 2
const RETURN_REACH := 2


func level_bonuses() -> Dictionary:
	return {2: {"range": 1}, 3: {"hp": 1}}


func ability_ids(instance: CharacterInstance) -> Array[String]:
	return [instance.data.id, L3_ID]


func ability_label(_instance: CharacterInstance, ability_id: String) -> String:
	return "Slumber" if ability_id == L3_ID else "Reactor Leak"


func can_use(sys, instance: CharacterInstance, ability_id: String) -> bool:
	if ability_id == L3_ID:
		return instance.level >= 3 and not sys.used_this_match(instance, "slumber_used")
	return true


func get_legal_targets(sys, instance: CharacterInstance, ability_id: String) -> Array:
	if ability_id == L3_ID:
		return []
	var reach: int = sys.ability_reach(instance, LEAK_REACH)
	return sys.tiles_in_reach(instance, instance.position, reach).filter(func(pos): return sys.can_place_leak(pos))


func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	if ability_id == L3_ID:
		return ""
	var legal := get_legal_targets(sys, instance, ability_id)
	var tiles := _tiles(payload)
	if tiles.is_empty() or tiles.size() > (2 if instance.level >= 2 else 1):
		return "choose a tile within range" if instance.level < 2 else "choose 1 or 2 tiles"
	for pos in tiles:
		if not legal.has(pos) or tiles.count(pos) > 1:
			return "choose different empty tiles within range"
	return ""


func next_step(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if ability_id == L3_ID:
		return {}
	var legal := get_legal_targets(sys, instance, ability_id)
	if not payload.has("target"):
		return target_step("target", "Reactor Leak: place a Leak on which tile?", legal)
	if instance.level < 2 or payload.has("target_2"):
		return {}
	return second_step("target_2", "Place a second Leak?", legal, payload.target)


func execute(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if ability_id == L3_ID:
		instance.ability_uses_this_match["slumber_used"] = true
		sys.remove_from_board(instance, {"kind": "within", "reach": RETURN_REACH})
		return {"success": true}
	for pos in _tiles(payload):
		sys.place_leak(pos)
	return {"success": true}


# After the return tile: place 1 Leak on an adjacent empty tile.
func return_step(sys, _instance: CharacterInstance, payload: Dictionary) -> Dictionary:
	if payload.has("leak"):
		return {}
	var tiles: Array = sys.neighbors(payload.to).filter(func(pos): return sys.can_place_leak(pos))
	return {} if tiles.is_empty() else target_step("leak", "Slumber: place a Leak next to Orlov.", tiles)


func on_returned(sys, instance: CharacterInstance, payload: Dictionary) -> void:
	var leak = payload.get("leak")
	if leak is Vector2i and sys.is_adjacent(leak, instance.position) and sys.can_place_leak(leak):
		sys.place_leak(leak)


static func _tiles(payload: Dictionary) -> Array:
	var result := []
	for key in ["target", "target_2"]:
		if payload.get(key) is Vector2i:
			result.append(payload[key])
	return result
