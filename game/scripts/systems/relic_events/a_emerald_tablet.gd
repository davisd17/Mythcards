extends RelicEventHandler
# The Emerald Tablet (Rare Relic): once each turn, after one of your characters gains
# Memory or starts movement adjacent to a placed object, choose one allied character
# within 2 tiles of a placed object. It gains Shield or +1 RANGE on its next AP ability
# this turn. Power payload: {"target_id": id, "boost": "shield"|"range"}.

const CARD := "a-flood-survivor-emerald-tablet"
const REACH := 2


func on_memory_gained(sys, owner_id: String, character_id: String) -> void:
	var c: CharacterInstance = sys.find(character_id)
	if c != null and c.player_id == owner_id:
		_trigger(sys, owner_id)


func on_character_moved(sys, owner_id: String, character_id: String, from: Vector2i, _to: Vector2i) -> void:
	var c: CharacterInstance = sys.find(character_id)
	if c == null or c.player_id != owner_id:
		return
	for n in sys.neighbors(from):
		if sys.board.get_placed_object(n) != null:
			_trigger(sys, owner_id)
			return


func power_available(sys, owner_id: String) -> bool:
	var s := RelicEventDeck.relic_state(owner_id, CARD)
	var turn: int = sys.state().turn_number
	return s.get("ready_turn", -1) == turn and s.get("used_turn", -1) != turn \
			and not _targets(sys, owner_id).is_empty()


func power_spec(sys, owner_id: String) -> Dictionary:
	return {"prompt": "Emerald Tablet: choose an ally within 2 of a placed object.", "pick": "character",
			"characters": _targets(sys, owner_id),
			"options": [{"label": "Shield", "payload": {"boost": "shield"}},
					{"label": "+1 RANGE on next ability", "payload": {"boost": "range"}}]}


func use_power(sys, owner_id: String, payload: Dictionary) -> Dictionary:
	var target_id := str(payload.get("target_id", ""))
	if not _targets(sys, owner_id).has(target_id) or not ["shield", "range"].has(payload.get("boost")):
		return {"success": false, "reason": "choose an ally within 2 of a placed object, and Shield or RANGE"}
	RelicEventDeck.relic_state(owner_id, CARD)["used_turn"] = sys.state().turn_number
	var target: CharacterInstance = sys.find(target_id)
	if payload.boost == "shield":
		sys.add_status(target, "shield", 1, "this_turn")
	else:
		var se: StatusEffect = sys.add_status(target, "temp_ability_range", 1, "this_turn")
		se.consume_on_ability = true
	return {"success": true}


func _trigger(sys, owner_id: String) -> void:
	RelicEventDeck.relic_state(owner_id, CARD)["ready_turn"] = sys.state().turn_number


func _targets(sys, owner_id: String) -> Array[String]:
	var result: Array[String] = []
	var objects: Array[Vector2i] = []
	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			if sys.board.get_placed_object(Vector2i(x, y)) != null:
				objects.append(Vector2i(x, y))
	for c in own_live(sys, owner_id):
		for o in objects:
			if sys.distance(o, c.position) <= REACH:
				result.append(c.instance_id)
				break
	return result
