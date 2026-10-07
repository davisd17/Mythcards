extends AbilityHandler
# Iset-Nara, Architect of the Hidden Vault (Flood Survivors Specialist) — LLD-closed-city-flood-roster.md 4.
# L1 Hidden Geometry (AP): an adjacent placed object (any owner, Leaks included) moves up
#    to 2 tiles in a straight line to an empty tile, stopping at characters and objects.
#    Payload: {"target": object pos, "to": pos}.
# L2 Vault Surveyor: +1 RANGE; the object may be within 2 (line of sight).
# L3 The Hidden Vault Opens: +1 HP. Standalone ability "a-flood-survivor-iset-nara_l3",
#    once per match (AP): place the Hidden Vault (3 HP, blocks movement and line of sight)
#    on an empty tile adjacent to a Stone. At the start of your turn, allies adjacent to it
#    gain Shield (AbilitySystem._vault_shields). Payload: {"target": pos}.

const L3_ID := "a-flood-survivor-iset-nara_l3"
const SHIFT := 2
const SURVEY_REACH := 2


func level_bonuses() -> Dictionary:
	return {2: {"range": 1}, 3: {"hp": 1}}


func ability_ids(instance: CharacterInstance) -> Array[String]:
	return [instance.data.id, L3_ID]


func ability_label(_instance: CharacterInstance, ability_id: String) -> String:
	return "The Hidden Vault Opens" if ability_id == L3_ID else "Hidden Geometry"


func can_use(sys, instance: CharacterInstance, ability_id: String) -> bool:
	if ability_id == L3_ID:
		return instance.level >= 3 and not sys.used_this_match(instance, "vault_used")
	return true


# Hidden Geometry: tiles holding an object she can move. The Vault: tiles she can build on.
func get_legal_targets(sys, instance: CharacterInstance, ability_id: String) -> Array:
	if ability_id == L3_ID:
		return _vault_tiles(sys)
	var candidates: Array = sys.neighbors(instance.position)
	if instance.level >= 2:
		candidates = sys.tiles_in_reach(instance, instance.position, sys.ability_reach(instance, SURVEY_REACH))
		for n in sys.neighbors(instance.position):
			if not candidates.has(n):
				candidates.append(n)   # an adjacent object never blocks its own line
	return candidates.filter(func(pos): return sys.board.get_placed_object(pos) != null \
			and not _destinations(sys, pos).is_empty())


func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	if not get_legal_targets(sys, instance, ability_id).has(payload.get("target")):
		return "illegal ability target"
	if ability_id != L3_ID and not _destinations(sys, payload.target).has(payload.get("to")):
		return "choose an empty tile up to 2 away in a straight line"
	return ""


func next_step(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if not payload.has("target"):
		var prompt := "Place the Hidden Vault next to a Stone." if ability_id == L3_ID \
				else "Hidden Geometry: move which placed object?"
		return target_step("target", prompt, get_legal_targets(sys, instance, ability_id))
	if ability_id == L3_ID or payload.has("to"):
		return {}
	return target_step("to", "Move it to which tile?", _destinations(sys, payload.target))


func execute(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if ability_id == L3_ID:
		instance.ability_uses_this_match["vault_used"] = true
		sys.board.place_object(payload.target, "vault", instance.player_id)
		return {"success": true}
	var obj: PlacedObjectInstance = sys.board.get_placed_object(payload.target)
	var type_id := obj.type_id
	var owner_id := obj.owner_player_id
	var max_hp := obj.max_hp
	var hp := obj.current_hp
	sys.board.remove_object(payload.target)
	sys.board.place_object(payload.to, type_id, owner_id)
	var moved: PlacedObjectInstance = sys.board.get_placed_object(payload.to)
	moved.max_hp = max_hp
	moved.current_hp = hp
	return {"success": true}


# Empty tiles up to 2 away from `from` along one line, stopping at anything in the way.
func _destinations(sys, from: Vector2i) -> Array:
	var result := []
	for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var pos := from
		for _step in SHIFT:
			pos += dir
			if not sys.is_empty_tile(pos):
				break
			result.append(pos)
	return result


func _vault_tiles(sys) -> Array:
	var result := []
	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			var pos := Vector2i(x, y)
			if not sys.is_empty_tile(pos):
				continue
			for n in sys.neighbors(pos):
				var obj: PlacedObjectInstance = sys.board.get_placed_object(n)
				if obj != null and obj.type_id == "stone":
					result.append(pos)
					break
	return result
