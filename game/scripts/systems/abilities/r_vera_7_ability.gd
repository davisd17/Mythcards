extends AbilityHandler
# VERA-7 (Closed City Mount) — LLD-closed-city-flood-roster.md 4.
# L1 Protected Passenger: the character mounted on VERA-7 has +1 maximum HP.
# L2 No Map Confirms This Corridor: +1 MOVE; may move through one placed object or allied
#    occupied tile per move, ending on an empty tile (a mounted pair moves the same way).
# L3 Passenger Signal Retained: once per turn, free: move 1 adjacent ally to another empty
#    tile adjacent to VERA-7. (Any two tiles next to her are diagonal to each other, so a
#    literal "1 tile" step can never qualify; [NEED: confirm] this reading.) Not while
#    carrying a rider (a ridden Mount takes no separate actions).
#    Payload: {"target_id": ally, "to": pos}.

const PASSENGER_HP := 1
const TAG := "passenger_signal"


func level_bonuses() -> Dictionary:
	return {2: {"move": 1}}


func get_rider_max_hp_bonus(_sys, _mount: CharacterInstance, _rider: CharacterInstance) -> int:
	return PASSENGER_HP


func get_movement_passable_predicate(sys, instance: CharacterInstance) -> Callable:
	if instance.level < 2:
		return Callable()
	return func(pos: Vector2i) -> bool:
		var c: CharacterInstance = sys.occupant(pos)
		return c != null and c.player_id == instance.player_id


func get_movement_object_passable_predicate(_sys, instance: CharacterInstance) -> Callable:
	if instance.level < 2:
		return Callable()
	return func(_pos: Vector2i) -> bool: return true


func get_movement_max_passes(_sys, instance: CharacterInstance) -> int:
	return 1 if instance.level >= 2 else 0


func offered_bonuses(sys, instance: CharacterInstance) -> Array[String]:
	if instance.level < 3 or instance.mounted_with_id != "" or sys.used_this_turn(instance, "passenger_signal_used"):
		return []
	if _movable_allies(sys, instance).is_empty():
		return []
	return [TAG]


func bonus_label(tag: String) -> String:
	return "Passenger Signal" if tag == TAG else super(tag)


func bonus_step(sys, instance: CharacterInstance, tag: String, payload: Dictionary) -> Dictionary:
	if tag != TAG:
		return {}
	if not payload.has("target_id"):
		return target_step("target_id", "Passenger Signal: move which adjacent ally?", _movable_allies(sys, instance))
	if payload.has("to"):
		return {}
	return target_step("to", "Move it to which tile next to VERA-7?", _destinations(sys, instance, sys.find(str(payload.target_id))))


func execute_reactive_bonus(sys, instance: CharacterInstance, tag: String, payload: Dictionary) -> Dictionary:
	if tag != TAG:
		return super(sys, instance, tag, payload)
	var ally: CharacterInstance = sys.find(str(payload.get("target_id", "")))
	if ally == null or not _movable_allies(sys, instance).has(ally.instance_id):
		return {"success": false, "reason": "needs an adjacent ally"}
	if not _destinations(sys, instance, ally).has(payload.get("to")):
		return {"success": false, "reason": "choose an empty tile next to VERA-7"}
	instance.ability_uses_this_turn["passenger_signal_used"] = true
	sys.reposition_character(ally, payload.to, "passenger_signal")
	return {"success": true}


func _movable_allies(sys, instance: CharacterInstance) -> Array[String]:
	var result: Array[String] = []
	for ally in sys.allies_of(instance):
		if sys.is_adjacent(ally.position, instance.position) and ally.mounted_with_id == "" \
				and not _destinations(sys, instance, ally).is_empty():
			result.append(ally.instance_id)
	return result


# The other empty tiles next to VERA-7.
func _destinations(sys, instance: CharacterInstance, ally: CharacterInstance) -> Array:
	if ally == null:
		return []
	return sys.neighbors(instance.position).filter(func(pos): return sys.is_empty_tile(pos))
