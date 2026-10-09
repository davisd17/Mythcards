extends AbilityHandler
# Sahu-Ren, Last Memory-Keeper (Flood Survivors Hero) — LLD-closed-city-flood-roster.md 4.
# L1 Living Archive: the first time each turn an ally within 2 takes damage, he gains 1
#    Memory (he may hold up to 3). His Memory also blocks damage to him as usual.
# L2 Forbidden Testimony: +1 RANGE. Once per turn, free: spend 1 Memory to Mark an enemy
#    within 3 (the "forbidden_testimony" bonus, {"target_id": id}).
# L3 Last Memory Released: +1 HP. Standalone ability "a-flood-survivor-sahu-ren_l3", once
#    per match (AP): spend up to 3 Memory; for each, 1 damage to a Marked enemy within 3
#    (targets chosen up front; the same enemy may be chosen again).
#    Payload: {"target": id, "target_2": optional id, "target_3": optional id}.

const L3_ID := "a-flood-survivor-sahu-ren_l3"
const MEMORY_MAX := 3
const ARCHIVE_REACH := 2
const REACH := 3
const TAG := "forbidden_testimony"
const KEYS := ["target", "target_2", "target_3"]


func level_bonuses() -> Dictionary:
	return {2: {"range": 1}, 3: {"hp": 1}}


func memory_max(_instance: CharacterInstance) -> int:
	return MEMORY_MAX


func ability_ids(instance: CharacterInstance) -> Array[String]:
	return [L3_ID]


func ability_label(_instance: CharacterInstance, _ability_id: String) -> String:
	return "Last Memory Released"


func can_use(sys, instance: CharacterInstance, _ability_id: String) -> bool:
	return instance.level >= 3 and not sys.used_this_match(instance, "last_memory_used") \
			and sys.memory_count(instance) > 0


func get_legal_targets(sys, instance: CharacterInstance, _ability_id: String) -> Array:
	return _enemies(sys, instance).filter(func(id): return sys.find(id).has_status("marked"))


func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	var ids := _ids(payload)
	if ids.is_empty():
		return "choose a Marked enemy"
	if ids.size() > sys.memory_count(instance):
		return "not enough Memory"
	var legal := get_legal_targets(sys, instance, ability_id)
	for id in ids:
		if not legal.has(id):
			return "choose Marked enemies within 3"
	return ""


func next_step(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	var legal := get_legal_targets(sys, instance, ability_id)
	var chosen := _ids(payload)
	for i in KEYS.size():
		if payload.has(KEYS[i]):
			if payload[KEYS[i]] == null:
				return {}   # skipped: done choosing
			continue
		if i >= sys.memory_count(instance) or legal.is_empty():
			return {}
		return target_step(KEYS[i], "Last Memory Released: 1 damage to which Marked enemy? (%d chosen)" % chosen.size(),
				legal, i > 0)
	return {}


func execute(sys, instance: CharacterInstance, _ability_id: String, payload: Dictionary) -> Dictionary:
	instance.ability_uses_this_match["last_memory_used"] = true
	var total := 0
	for id in _ids(payload):
		var enemy: CharacterInstance = sys.find(id)
		if enemy.defeated or sys.take_memory(instance, 1) == 0:
			continue
		var hit: Dictionary = sys.combat().apply_damage(instance, enemy, 1,
				sys.distance(instance.position, enemy.position) > 1)
		total += int(hit.damage)
	return {"success": true, "damage": total}


func on_character_damaged(sys, instance: CharacterInstance, damaged: CharacterInstance,
		_attacker: CharacterInstance, _incoming: int, final: int) -> void:
	if final <= 0 or damaged == instance or damaged.player_id != instance.player_id:
		return
	if sys.distance(damaged.position, instance.position) > ARCHIVE_REACH:
		return
	var turn: int = sys.state().turn_number
	if int(instance.ability_uses_this_match.get("archive_turn", -1)) == turn:
		return
	instance.ability_uses_this_match["archive_turn"] = turn
	sys.give_memory(instance)


func offered_bonuses(sys, instance: CharacterInstance) -> Array[String]:
	if instance.level < 2 or sys.memory_count(instance) == 0 or sys.used_this_turn(instance, "testimony_used") \
			or _enemies(sys, instance).is_empty():
		return []
	return [TAG]


func bonus_label(tag: String) -> String:
	return "Forbidden Testimony" if tag == TAG else super(tag)


func bonus_step(sys, instance: CharacterInstance, tag: String, payload: Dictionary) -> Dictionary:
	if tag != TAG or payload.has("target_id"):
		return {}
	return target_step("target_id", "Forbidden Testimony: spend 1 Memory to Mark which enemy?", _enemies(sys, instance))


func execute_reactive_bonus(sys, instance: CharacterInstance, tag: String, payload: Dictionary) -> Dictionary:
	if tag != TAG:
		return super(sys, instance, tag, payload)
	var id := str(payload.get("target_id", ""))
	if not _enemies(sys, instance).has(id):
		return {"success": false, "reason": "needs an enemy within 3"}
	instance.ability_uses_this_turn["testimony_used"] = true
	sys.take_memory(instance, 1)
	sys.add_status(sys.find(id), "marked", 1, "until_used", instance)
	return {"success": true}


func _enemies(sys, instance: CharacterInstance) -> Array:
	return sys.characters_in_reach(instance, instance.position, sys.ability_reach(instance, REACH), false)


static func _ids(payload: Dictionary) -> Array:
	var result := []
	for key in KEYS:
		if payload.get(key) != null and str(payload.get(key)) != "":
			result.append(str(payload[key]))
	return result


func ai_value(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary, ai) -> float:
	if ability_id == "bonus:" + TAG:
		return 0.6
	var v := 0.0
	for id in _ids(payload):
		var enemy: CharacterInstance = sys.find(id)
		v += ai.damage_value(instance, enemy, ai.preview(instance, enemy, 1))
	return v
