extends AbilityHandler
# Dr. Elena Morozova (Closed City Specialist) — LLD-closed-city-flood-roster.md 4.
# L1 Dream Link (AP): choose an ally within 3, then another ally within 2 of it, and move
#    one marker between them (either way). Markers: Shield, Memory (ruling 2026-10-07),
#    Marked, +ATK, MOVE changes (incl. Slow), +RANGE, Pounce. Never a Spirit Ember.
#    Payload: {"target": id, "other": id, "marker": {"from": id, "type": t, "index": i}}.
# L2 Signal Breach: range 4, and the two may be any characters within 4 of Elena. Moving
#    a harmful marker (Marked, or a negative ATK/MOVE change) onto an enemy shields Elena.
# L3 Missing In The Signal: +1 RANGE. Standalone ability "r-elena-morozova_l3", once per
#    match (AP): Elena leaves the board until your next turn, then returns to an empty
#    tile adjacent to an ally and may move one marker between two characters within 4.

const L3_ID := "r-elena-morozova_l3"
const LINK_REACH := [0, 3, 4, 4]   # by level
const PARTNER_REACH := 2
const BREACH_REACH := 4
const MARKERS := ["shield", "memory", "marked", "temp_atk", "temp_move", "temp_range", "temp_ability_range",
		"pounce_mark"]


func level_bonuses() -> Dictionary:
	return {3: {"range": 1}}


func ability_ids(instance: CharacterInstance) -> Array[String]:
	return [instance.data.id, L3_ID]


func ability_label(_instance: CharacterInstance, ability_id: String) -> String:
	return "Missing In The Signal" if ability_id == L3_ID else "Dream Link"


func can_use(sys, instance: CharacterInstance, ability_id: String) -> bool:
	if ability_id == L3_ID:
		return instance.level >= 3 and not sys.used_this_match(instance, "missing_used")
	return true


# First pick: an ally within reach (L1), or any character within reach (L2+).
func get_legal_targets(sys, instance: CharacterInstance, ability_id: String) -> Array:
	if ability_id == L3_ID:
		return []
	return _first_picks(sys, instance, instance.position, sys.ability_reach(instance, LINK_REACH[instance.level]),
			instance.level >= 2)


func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	if ability_id == L3_ID:
		return ""
	return _link_error(sys, instance, instance.position, payload, instance.level >= 2)


func next_step(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if ability_id == L3_ID:
		return {}
	return _link_step(sys, instance, instance.position, payload, instance.level >= 2, false)


func execute(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if ability_id == L3_ID:
		instance.ability_uses_this_match["missing_used"] = true
		sys.remove_from_board(instance, {"kind": "adjacent_ally"})
		return {"success": true}
	_move_marker(sys, instance, payload)
	return {"success": true}


# After she returns: optionally move one marker between any two characters within 4.
func return_step(sys, instance: CharacterInstance, payload: Dictionary) -> Dictionary:
	return _link_step(sys, instance, payload.to, payload, true, true)


func on_returned(sys, instance: CharacterInstance, payload: Dictionary) -> void:
	if payload.get("target") != null and _link_error(sys, instance, instance.position, payload, true, BREACH_REACH) == "":
		_move_marker(sys, instance, payload)


# --- Dream Link ---------------------------------------------------------------------------

func _first_picks(sys, instance: CharacterInstance, origin: Vector2i, reach: int, any_side: bool) -> Array:
	var result := []
	for pos in sys.tiles_in_reach(instance, origin, reach):
		var c: CharacterInstance = sys.occupant(pos)
		if c != null and (any_side or (c.player_id == instance.player_id and c != instance)):
			result.append(c.instance_id)
	return result


func _partners(sys, instance: CharacterInstance, origin: Vector2i, first: CharacterInstance, any_side: bool) -> Array:
	if any_side:
		return _first_picks(sys, instance, origin, sys.ability_reach(instance, BREACH_REACH), true) \
				.filter(func(id): return id != first.instance_id)
	var result := []
	for ally in sys.allies_of(instance):
		if ally != first and sys.distance(ally.position, first.position) <= PARTNER_REACH:
			result.append(ally.instance_id)
	if instance != first and sys.distance(instance.position, first.position) <= PARTNER_REACH:
		result.append(instance.instance_id)   # Elena is an allied character too
	return result


# Markers that can move between a and b, as option values {from, type, index}.
func _marker_options(sys, a: CharacterInstance, b: CharacterInstance) -> Array:
	var options := []
	for pair in [[a, b], [b, a]]:
		var giver: CharacterInstance = pair[0]
		var taker: CharacterInstance = pair[1]
		var counts := {}
		for se in giver.status_effects:
			if not MARKERS.has(se.type):
				continue
			var index: int = counts.get(se.type, 0)
			counts[se.type] = index + 1
			if se.type == "memory" and sys.memory_count(taker) >= sys.handler_for(taker).memory_max(taker):
				continue
			options.append({"label": "%s: %s -> %s" % [GameBoardView.status_name(se), giver.data.char_name, taker.data.char_name],
					"value": {"from": giver.instance_id, "type": se.type, "index": index}})
	return options


func _link_step(sys, instance: CharacterInstance, origin: Vector2i, payload: Dictionary, any_side: bool,
		optional: bool) -> Dictionary:
	var reach: int = sys.ability_reach(instance, BREACH_REACH if optional else LINK_REACH[instance.level])
	if not payload.has("target"):
		var picks := _first_picks(sys, instance, origin, reach, any_side)
		return {} if optional and picks.is_empty() else \
				target_step("target", "Dream Link: first character?", picks, optional)
	if payload.target == null:
		return {}
	var first: CharacterInstance = sys.find(str(payload.target))
	if not payload.has("other"):
		return target_step("other", "Dream Link: second character?", _partners(sys, instance, origin, first, any_side), optional)
	if payload.other == null or payload.has("marker"):
		return {}
	var options := _marker_options(sys, first, sys.find(str(payload.other)))
	return option_step("marker", "Move which marker?", options, optional or options.is_empty())


func _link_error(sys, instance: CharacterInstance, origin: Vector2i, payload: Dictionary, any_side: bool,
		printed_reach: int = -1) -> String:
	var reach: int = sys.ability_reach(instance, printed_reach if printed_reach > 0 else LINK_REACH[instance.level])
	if not _first_picks(sys, instance, origin, reach, any_side).has(str(payload.get("target", ""))):
		return "choose a character in range"
	var first: CharacterInstance = sys.find(str(payload.target))
	if not _partners(sys, instance, origin, first, any_side).has(str(payload.get("other", ""))):
		return "choose a second character in range"
	var marker = payload.get("marker")
	if not marker is Dictionary:
		return "choose a marker to move"
	for option in _marker_options(sys, first, sys.find(str(payload.other))):
		var v: Dictionary = option.value
		if v.from == str(marker.get("from", "")) and v.type == str(marker.get("type", "")) \
				and v.index == int(marker.get("index", -1)):
			return ""
	return "choose a marker to move"


func _move_marker(sys, instance: CharacterInstance, payload: Dictionary) -> void:
	var marker: Dictionary = payload.marker
	var giver: CharacterInstance = sys.find(str(marker.from))
	var taker: CharacterInstance = sys.find(str(payload.other)) if giver.instance_id == str(payload.target) \
			else sys.find(str(payload.target))
	var moved: StatusEffect = null
	if marker.type == "memory":
		sys.take_memory(giver, 1)
		sys.give_memory(taker)
	else:
		var seen := 0
		for se in giver.status_effects:
			if se.type == marker.type:
				if seen == int(marker.index):
					moved = se
					break
				seen += 1
		if moved == null:
			return
		giver.status_effects.erase(moved)
		taker.status_effects.append(moved)
	# Signal Breach: a harmful marker moved onto an enemy shields Elena.
	if instance.level >= 2 and taker.player_id != instance.player_id and moved != null and _harmful(moved):
		sys.add_status(instance, "shield", 1, "this_turn", instance)


static func _harmful(se: StatusEffect) -> bool:
	return se.type == "marked" or (["temp_move", "temp_atk", "temp_range"].has(se.type) and se.value < 0)
