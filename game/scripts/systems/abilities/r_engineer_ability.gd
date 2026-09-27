extends AbilityHandler
# Winter Engineer (Specialist) — Barricade / Fortified Works / Frozen Redoubt (LLD 5.6).
# L1 Barricade: build a barricade (2 HP, blocks movement) on an adjacent empty tile, or
#    repair an adjacent own barricade/placed object by 1. Payload: {"target": pos}.
# L2 Fortified Works: barricades have 3 HP; build or repair up to 2 adjacent tiles per
#    use. Payload: {"targets": [pos, pos]}.
# L3 Frozen Redoubt: +1 HP. Standalone ability "r-engineer_l3", once per turn: a
#    barricade or frost tile within 2. Payload: {"target": pos, "kind": "barricade"|"frost"}.
#    Also: allies adjacent to any placed object take -1 damage from ranged attacks.

const L3_ID := "r-engineer_l3"
const BARRICADE_HP := [0, 2, 3, 3]   # by level
const BARRICADE_TILES := [0, 1, 2, 2]
const REDOUBT_REACH := 2
const REDOUBT_RANGED_REDUCTION := 1


func level_bonuses() -> Dictionary:
	return {3: {"hp": 1}}


func on_level_up(sys, instance: CharacterInstance, new_level: int) -> void:
	# "Barricades have 3 HP": this Engineer's existing barricades are fortified too.
	if new_level != 2:
		return
	for obj in _own_barricades(sys, instance):
		var raise: int = BARRICADE_HP[2] - obj.max_hp
		if raise > 0:
			obj.max_hp += raise
			obj.current_hp += raise


func ability_ids(instance: CharacterInstance) -> Array[String]:
	return [instance.data.id, L3_ID]


func can_use(sys, instance: CharacterInstance, ability_id: String) -> bool:
	if ability_id == L3_ID:
		return instance.level >= 3 and not sys.used_this_turn(instance, "frozen_redoubt_used")
	return true


func get_legal_targets(sys, instance: CharacterInstance, ability_id: String) -> Array:
	var result := []
	if ability_id == L3_ID:
		for pos in sys.tiles_in_reach(instance, instance.position, sys.ability_reach(instance, REDOUBT_REACH)):
			if sys.is_empty_tile(pos):
				result.append(pos)
		return result
	for pos in sys.neighbors(instance.position):
		if sys.is_empty_tile(pos) or _repairable(sys, instance, pos):
			result.append(pos)
	return result


func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	var legal := get_legal_targets(sys, instance, ability_id)
	if ability_id == L3_ID:
		if not legal.has(payload.get("target")):
			return "illegal ability target"
		return "" if ["barricade", "frost"].has(payload.get("kind")) else "choose barricade or frost"
	var tiles := _tiles(payload)
	if tiles.is_empty() or tiles.size() > BARRICADE_TILES[instance.level]:
		return "choose 1 tile" if instance.level < 2 else "choose 1 or 2 tiles"
	for pos in tiles:
		if not legal.has(pos) or tiles.count(pos) > 1:
			return "illegal ability target"
	return ""


func execute(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if ability_id == L3_ID:
		instance.ability_uses_this_turn["frozen_redoubt_used"] = true
		if payload.kind == "frost":
			sys.board.get_tile(payload.target).terrain_type = "frost"
		else:
			_build(sys, instance, payload.target)
		return {"success": true}
	for pos in _tiles(payload):
		if sys.is_empty_tile(pos):
			_build(sys, instance, pos)
		else:
			var obj: PlacedObjectInstance = sys.board.get_placed_object(pos)
			obj.current_hp = mini(obj.max_hp, obj.current_hp + 1)
	return {"success": true}


func get_aura_damage_reduction(sys, source: CharacterInstance, defender: CharacterInstance,
		_attacker: CharacterInstance, is_ranged: bool) -> int:
	if source.level < 3 or not is_ranged:
		return 0
	for pos in sys.neighbors(defender.position):
		if sys.board.get_placed_object(pos) != null:
			return REDOUBT_RANGED_REDUCTION
	return 0


func _build(sys, instance: CharacterInstance, pos: Vector2i) -> void:
	sys.board.place_object(pos, "barricade", instance.player_id)
	var obj: PlacedObjectInstance = sys.board.get_placed_object(pos)
	obj.max_hp = BARRICADE_HP[instance.level]
	obj.current_hp = obj.max_hp


func _repairable(sys, instance: CharacterInstance, pos: Vector2i) -> bool:
	var obj: PlacedObjectInstance = sys.board.get_placed_object(pos)
	return obj != null and obj.owner_player_id == instance.player_id and obj.max_hp > 0 and obj.current_hp < obj.max_hp


func _own_barricades(sys, instance: CharacterInstance) -> Array:
	var result := []
	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			var obj: PlacedObjectInstance = sys.board.get_placed_object(Vector2i(x, y))
			if obj != null and obj.type_id == "barricade" and obj.owner_player_id == instance.player_id:
				result.append(obj)
	return result


static func _tiles(payload: Dictionary) -> Array:
	var raw: Array = payload.get("targets", [])
	if raw.is_empty() and payload.get("target") is Vector2i:
		raw = [payload.target]
	return raw.filter(func(p): return p is Vector2i)
