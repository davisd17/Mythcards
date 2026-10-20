extends AbilityHandler
# Zoya Miranova (Closed City Mystic) — LLD-closed-city-flood-roster.md 4.
# L1 Voice Under Static (AP): an enemy within 3 is pulled 1 tile toward Zoya if that tile
#    can be entered (a Leak there is triggered; "can't be moved" effects stop it).
#    Payload: {"target": enemy id}.
# L2 Subject Three: +1 RANGE; an enemy Voice Under Static moved becomes Marked.
# L3 Too Many Names: +1 HP. Once per match, Voice Under Static also charms a target that
#    isn't a Hero: after the pull it joins Zoya's side for the rest of the match. A mounted
#    pair goes together unless it carries a Hero. Spent on the first use whose target can
#    be charmed (balance pass 2026-10-19, replacing the free second pull).

const REACH := 3
const TAG := "too_many_names"


func level_bonuses() -> Dictionary:
	return {2: {"range": 1}, 3: {"hp": 1}}


func ability_label(_instance: CharacterInstance, _ability_id: String) -> String:
	return "Voice Under Static"


func can_use(_sys, _instance: CharacterInstance, _ability_id: String) -> bool:
	return true


func get_legal_targets(sys, instance: CharacterInstance, _ability_id: String) -> Array:
	return sys.characters_in_reach(instance, instance.position, sys.ability_reach(instance, REACH), false)


func next_step(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if payload.has("target"):
		return {}
	var verb := "Voice Under Static: pull and charm which enemy?" if _charm_ready(sys, instance) \
			else "Voice Under Static: pull which enemy?"
	return target_step("target", verb, get_legal_targets(sys, instance, ability_id))


func execute(sys, instance: CharacterInstance, _ability_id: String, payload: Dictionary) -> Dictionary:
	var enemy: CharacterInstance = sys.find(str(payload.target))
	var before := enemy.position
	var after: Vector2i = sys.combat().apply_pull(enemy, instance.position, 1)
	var moved := after != before
	if enemy.defeated:
		return {"success": true, "moved": moved}
	if _charm_ready(sys, instance) and can_charm(sys, enemy):
		instance.ability_uses_this_match[TAG + "_used"] = true
		sys.change_side(enemy)
		return {"success": true, "moved": moved, "charmed": true}
	if moved and instance.level >= 2:
		sys.add_status(enemy, "marked", 1, "until_used", instance)
	return {"success": true, "moved": moved}


func _charm_ready(sys, instance: CharacterInstance) -> bool:
	return instance.level >= 3 and not sys.used_this_match(instance, TAG + "_used")


# Any type but a Hero, and not half of a pair that carries one.
static func can_charm(sys, enemy: CharacterInstance) -> bool:
	if enemy.data.type == "Hero":
		return false
	var partner: CharacterInstance = sys.find(enemy.mounted_with_id) if enemy.mounted_with_id != "" else null
	return partner == null or partner.data.type != "Hero"


func ai_value(sys, instance: CharacterInstance, _ability_id: String, payload: Dictionary, ai) -> float:
	var enemy: CharacterInstance = sys.find(str(payload.get("target", "")))
	if enemy == null:
		return 0.0
	if _charm_ready(sys, instance) and can_charm(sys, enemy):
		return ai.personality.w("defeat") * ai.value_of(enemy) * 2.0   # it leaves them and joins us
	var step := Vector2i(signi(instance.position.x - enemy.position.x), signi(instance.position.y - enemy.position.y))
	var v := 0.4
	if sys.has_leak(enemy.position + step):
		v += 1.0   # pulled into a Leak
	if instance.level >= 2:
		v += 0.5   # and Marked
	return v
