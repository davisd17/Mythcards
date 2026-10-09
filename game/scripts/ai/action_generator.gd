class_name ActionGenerator
extends RefCounted
# Every legal candidate action for one side (LLD-ai-opponent.md 3). Uses only the queries
# the game screen uses, so any card the screen can play, the AI can play too:
# legal moves and attack targets, abilities expanded through AbilityHandler.next_step,
# bonuses through bonus_step, and card choices through RelicEventDeck's specs.
# A candidate: {action_type, actor_id, payload, kind}.

const MAX_PAYLOADS := 40   # per ability/bonus/choice; keeps branching (e.g. 2 Leaks) bounded

var player_id: String


func _init(p_player_id: String) -> void:
	player_id = p_player_id


func generate() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var state := GameState.match_state
	if state == null or not GameState.is_match_active() or state.active_player_id != player_id:
		return result
	# A drawn card waiting on a decision comes first, then an off-board return.
	if RelicEventDeck.has_pending_choice(player_id):
		var spec := RelicEventDeck.choice_spec(player_id)
		for picks in expand(func(p): return GameController.spec_step(spec, p)):
			result.append(_candidate("deck_choice", player_id, GameController.finalize_payload(picks), "deck_choice"))
		return result
	var sys: AbilitySystem = RulesEngine.systems().ability
	for c in state.get_player(player_id).characters:
		if c.ability_uses_this_turn.get("return_available", false):
			for picks in expand(func(p): return sys.bonus_step(c, "return", p)):
				var payload := GameController.finalize_payload(picks)
				payload["tag"] = "return"
				result.append(_candidate("reactive_bonus", c.instance_id, payload, "return"))
			return result

	var pool: int = state.get_player(player_id).pool_ap_remaining
	for c in state.get_player(player_id).characters:
		if c.defeated or not c.is_placed() or (c.mounted_with_id != "" and not c.is_mounted_rider):
			continue
		var id := c.instance_id
		if pool > 0 and RulesEngine.ap_payer(c, "move").character_ap_remaining > 0:
			for to in RulesEngine.get_legal_move_tiles(id):
				result.append(_candidate("move", id, {"to": to}, "move"))
		if pool > 0 and c.character_ap_remaining > 0:
			for target in RulesEngine.get_legal_attack_target_ids(id):
				result.append(_candidate("attack", id, {"target_id": target}, "attack"))
			for pos in RulesEngine.get_legal_attack_object_tiles(id):
				result.append(_candidate("attack", id, {"target_pos": pos}, "attack_object"))
			for ability_id in RulesEngine.get_usable_ability_ids(id):
				for picks in expand(func(p): return sys.ability_step(c, ability_id, p)):
					var payload := GameController.finalize_payload(picks)
					payload["ability_id"] = ability_id
					result.append(_candidate("ability", id, payload, "ability"))
			for mount_id in RulesEngine.get_legal_mount_ids(id):
				result.append(_candidate("mount", id, {"mount_id": mount_id}, "mount"))
			for to in RulesEngine.get_legal_dismount_tiles(id):
				result.append(_candidate("dismount", id, {"to": to}, "dismount"))
		for tag in RulesEngine.get_offered_bonus_tags(id):
			for picks in expand(func(p): return sys.bonus_step(c, tag, p)):
				var payload := GameController.finalize_payload(picks)
				payload["tag"] = tag
				result.append(_candidate("reactive_bonus", id, payload, "bonus"))

	var power := RelicEventDeck.power_spec(player_id)
	if not power.is_empty():
		for picks in expand(func(p): return GameController.spec_step(power, p)):
			result.append(_candidate("use_relic", player_id, GameController.finalize_payload(picks), "relic_power"))
	return result


# Every complete set of picks a step function allows (depth-first, capped). A step with
# no choices left ends a branch; optional steps also branch on skipping (null).
static func expand(stepper: Callable, picks: Dictionary = {}, out: Array[Dictionary] = []) -> Array[Dictionary]:
	if out.size() >= MAX_PAYLOADS:
		return out
	var step: Dictionary = stepper.call(picks)
	if step.is_empty():
		out.append(picks.duplicate(true))
		return out
	var key: String = step.key
	var values: Array = []
	match step.get("pick", "option"):
		"tile":
			values = step.get("tiles", [])
		"character":
			values = step.get("characters", [])
		_:
			values = step.get("options", []).map(func(o): return o.value)
	if step.get("optional", false) or values.is_empty():
		var skipped := picks.duplicate(true)
		skipped[key] = null
		if values.is_empty() and not step.get("optional", false):
			return out   # nothing legal to pick: this branch can't be completed
		expand(stepper, skipped, out)
	for v in values:
		if out.size() >= MAX_PAYLOADS:
			break
		var next := picks.duplicate(true)
		if step.get("append", false):
			var list: Array = next.get(key, []).duplicate()
			list.append(v)
			next[key] = list
		else:
			next[key] = v
		expand(stepper, next, out)
	return out


static func _candidate(action_type: String, actor_id: String, payload: Dictionary, kind: String) -> Dictionary:
	return {"action_type": action_type, "actor_id": actor_id, "payload": payload, "kind": kind}
