extends AbilityHandler
# Divine Conductor (Leader) — Link Mind / Perfect Chord (LLD-ability-system 5.11).
# L1 Link Mind: an ally within 3 may, until end of turn, use the Conductor's RANGE for
#    its abilities and ignore one allied character for line of sight.
#    Payload: {"target": id}.
# L2: up to 2 allies. Payload: {"targets": [id, id]}.
# L3 Perfect Chord: +1 RANGE; once per turn, when a linked ally defeats an enemy or
#    delivers a Spirit Ember, that ally's character AP refreshes.

const LINK_TARGETS := [0, 1, 2, 2]   # by level


func level_bonuses() -> Dictionary:
	return {3: {"range": 1}}


func can_use(_sys, _instance: CharacterInstance, _ability_id: String) -> bool:
	return true


func get_legal_targets(sys, instance: CharacterInstance, _ability_id: String) -> Array:
	return sys.characters_in_reach(instance, instance.position, _reach(sys, instance), true)


func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	var ids := _ids(payload)
	if ids.is_empty():
		return "choose an ally to link"
	if ids.size() > LINK_TARGETS[instance.level]:
		return "too many targets"
	var legal := get_legal_targets(sys, instance, ability_id)
	for id in ids:
		if not legal.has(id) or ids.count(id) > 1:
			return "illegal ability target"
	return ""


func execute(sys, instance: CharacterInstance, _ability_id: String, payload: Dictionary) -> Dictionary:
	var borrowed := _reach(sys, instance)
	for id in _ids(payload):
		var ally: CharacterInstance = sys.find(id)
		sys.add_status(ally, "range_override", borrowed, "this_turn", instance)
		sys.add_status(ally, "los_ignore_ally_granted", 1, "this_turn", instance)
		ally.ability_uses_this_turn["linked_by"] = instance.instance_id
	return {"success": true}


func on_character_defeated(sys, instance: CharacterInstance, _fallen: CharacterInstance,
		defeated_by: CharacterInstance) -> void:
	_perfect_chord(sys, instance, defeated_by)


func on_spirit_ember_delivered(sys, instance: CharacterInstance, carrier: CharacterInstance) -> void:
	_perfect_chord(sys, instance, carrier)


func _perfect_chord(sys, instance: CharacterInstance, ally: CharacterInstance) -> void:
	if instance.level < 3 or ally == null or sys.used_this_turn(instance, "perfect_chord_used"):
		return
	if ally.ability_uses_this_turn.get("linked_by", "") != instance.instance_id:
		return
	instance.ability_uses_this_turn["perfect_chord_used"] = true
	ally.character_ap_remaining = ally.character_ap_max
	EventBus.character_ap_changed.emit(ally.instance_id, ally.character_ap_remaining)


static func _reach(sys, instance: CharacterInstance) -> int:
	return sys.ability_reach(instance, instance.data.range)


static func _ids(payload: Dictionary) -> Array:
	var raw: Array = payload.get("targets", [])
	if raw.is_empty() and payload.has("target"):
		raw = [payload.target]
	return raw.map(func(v): return str(v))
