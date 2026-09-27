extends Node
# Autoload name: RulesEngine — the single gate for every player action (HLD 4.4,
# LLD-rules-engine.md). UI, AI, and TestBridge change match state only through
# request_action(); nothing else mutates MatchState during a match.

const ACTION_TYPES: Array[String] = ["move", "attack", "ability", "mount", "dismount", "end_turn",
	"reactive_bonus"]
const CHARACTER_ACTIONS_WITH_AP: Array[String] = ["move", "attack", "ability", "mount", "dismount"]

# Per-match collaborators, built for the current MatchState on first use. Tests replace
# them with use_systems().
var combat_resolver: Object = null
var ability_system: Object = null
var mount_system: Object = null
var leveling_system: LevelingSystem = null   # reacts to EventBus; never called directly
var _systems_for: MatchState = null


func request_action(action_type: String, actor_id: String, payload: Dictionary) -> Dictionary:
	if not ACTION_TYPES.has(action_type):
		push_error("RulesEngine.request_action: unknown action type '%s'" % action_type)
		return {"success": false, "reason": "unknown action type"}
	EventBus.action_requested.emit(action_type, actor_id, payload)
	var result := _dispatch(action_type, actor_id, payload)
	EventBus.action_resolved.emit(action_type, actor_id, result)
	return result


func get_legal_move_tiles(actor_id: String) -> Array[Vector2i]:
	# Non-mutating preview; _handle_move validates against exactly this set.
	var actor := _find_live(actor_id)
	if actor == null or not actor.is_placed():
		return []
	_ensure_systems()
	var m := _movement(actor)
	var tiles := _board().get_legal_moves(actor.position, m.budget, m.pattern,
			ability_system.get_movement_passable_predicate(m.mover),
			ability_system.get_movement_object_passable_predicate(m.mover),
			ability_system.get_movement_max_passes(m.mover))
	for extra in ability_system.get_bonus_move_tiles(m.mover, actor.position, m.budget):
		if not tiles.has(extra):
			tiles.append(extra)
	return tiles


func get_legal_attack_target_ids(actor_id: String) -> Array[String]:
	# Non-mutating preview; _handle_attack validates against exactly this set.
	var result: Array[String] = []
	var actor := _find_live(actor_id)
	if actor == null or not actor.is_placed():
		return result
	_ensure_systems()
	var board := _board()
	for pos in _attack_candidate_tiles(actor):
		var target := _live_occupant(pos)
		if target == null or target.player_id == actor.player_id:
			continue
		if board.has_line_of_sight(actor.position, pos,
				ability_system.get_line_of_sight_exceptions(actor, pos, board)):
			result.append(target.instance_id)
	return result


func systems() -> Dictionary:
	# The current match's collaborators, built on first use (tools, TestBridge, tests).
	_ensure_systems()
	return {"ability": ability_system, "combat": combat_resolver, "mount": mount_system,
			"leveling": leveling_system}


func use_systems(p_combat: Object, p_ability: Object, p_mount: Object,
		p_leveling: LevelingSystem = null) -> void:
	# Test seam: pins collaborators for the current match. Leveling is off unless passed.
	combat_resolver = p_combat
	ability_system = p_ability
	mount_system = p_mount
	leveling_system = p_leveling
	_systems_for = GameState.match_state
	if p_ability is AbilitySystem and p_combat is CombatResolver:
		p_ability.set_combat(p_combat)


# --- Dispatch ----------------------------------------------------------------

func _dispatch(action_type: String, actor_id: String, payload: Dictionary) -> Dictionary:
	var reason := _validate_common(action_type, actor_id)
	if reason != "":
		return _fail(reason)
	_ensure_systems()
	if action_type == "end_turn":
		return _handle_end_turn(actor_id)
	var actor := GameState.match_state.find_character(actor_id)
	match action_type:
		"move":
			return _handle_move(actor, payload)
		"attack":
			return _handle_attack(actor, payload)
		"ability":
			return _handle_ability(actor, payload)
		"mount":
			return _handle_mount(actor, payload)
		"dismount":
			return _handle_dismount(actor, payload)
		"reactive_bonus":
			return _handle_reactive_bonus(actor, payload)
	return _fail("unknown action type")


func _validate_common(action_type: String, actor_id: String) -> String:
	# Ordered checks; the first failure wins (LLD 4.1).
	if not GameState.is_match_active():
		return "match not active"
	var state := GameState.match_state
	if action_type == "end_turn":
		return "" if actor_id == state.active_player_id else "not your turn"
	var actor := state.find_character(actor_id)
	if actor == null:
		return "unknown actor"
	if actor.defeated:
		return "character defeated"
	if actor.player_id != state.active_player_id:
		return "not your turn"
	if actor.mounted_with_id != "" and not actor.is_mounted_rider:
		return "carrying a rider"  # BR-015: a mounted Mount cannot act separately
	if CHARACTER_ACTIONS_WITH_AP.has(action_type):
		if state.get_player(actor.player_id).pool_ap_remaining < 1:
			return "no pool AP remaining"
		if actor.character_ap_remaining < 1:
			return "no character AP remaining"
	return ""


# --- Handlers ----------------------------------------------------------------

func _handle_move(actor: CharacterInstance, payload: Dictionary) -> Dictionary:
	var to = payload.get("to")
	if not to is Vector2i:
		return _fail("missing destination")
	if not get_legal_move_tiles(actor.instance_id).has(to):
		return _fail("illegal move")
	var board := _board()
	var from := actor.position
	# Whether this move needed a pass-through (Vault, Glide): "after vaulting" triggers
	# read it. True when the destination isn't reachable without passing anything.
	var m := _movement(actor)
	actor.ability_uses_this_turn["last_move_required_pass"] = \
			not board.get_legal_moves(from, m.budget, m.pattern).has(to)
	board.clear_occupant(from)
	board.set_occupant(to, actor.instance_id)
	actor.position = to
	if actor.is_mounted_rider:
		GameState.match_state.find_character(actor.mounted_with_id).position = to
	_spend_ap(actor)
	actor.ability_uses_this_turn["moved"] = true   # shared "moved this turn" marker (e.g. Aim)
	EventBus.character_moved.emit(actor.instance_id, from, to)
	return {"success": true}


func _handle_attack(actor: CharacterInstance, payload: Dictionary) -> Dictionary:
	var target_id: String = str(payload.get("target_id", ""))
	var target := GameState.match_state.find_character(target_id)
	if target == null:
		return _fail("unknown target")
	if target.defeated:
		return _fail("target already defeated")
	if target.player_id == actor.player_id:
		return _fail("cannot attack an ally")
	if target.mounted_with_id != "" and not target.is_mounted_rider:
		return _fail("mount is being ridden; attack the rider")   # BR-016: damage goes to the rider
	if not get_legal_attack_target_ids(actor.instance_id).has(target_id):
		# Same candidate tiles the legal set uses, so the reason is specific.
		if _attack_candidate_tiles(actor).has(target.position):
			return _fail("blocked line of sight")
		return _fail("out of range")
	# Pay first: effects triggered by the attack (Perfect Chord) may refresh AP, and must
	# not be undone by the payment.
	_spend_ap(actor)
	var combat: Dictionary = combat_resolver.resolve_attack(actor, target)
	return {"success": true, "damage": combat.get("damage", 0), "defeated": combat.get("defeated", false)}


func _handle_ability(actor: CharacterInstance, payload: Dictionary) -> Dictionary:
	var ability_id: String = str(payload.get("ability_id", ""))
	if not ability_system.can_use_ability(actor, ability_id):
		return _fail("ability unavailable")
	# The ability validates its whole payload: several carry choices or multiple targets
	# (Command's +ATK or move, Foresight's keep-or-bottom), not just one target.
	var invalid: String = ability_system.validate_ability(actor, ability_id, payload)
	if invalid != "":
		return _fail(invalid)
	_spend_ap(actor)   # before the effect, for the same reason as attacks
	var ability_result: Dictionary = ability_system.execute_ability(actor, ability_id, payload)
	if not ability_result.get("success", false):
		# A validated ability that still failed costs nothing.
		_refund_ap(actor)
		return _fail(str(ability_result.get("reason", "ability failed")))
	var result := ability_result.duplicate()
	result.erase("reason")
	result["success"] = true
	return result


func _handle_mount(actor: CharacterInstance, payload: Dictionary) -> Dictionary:
	var mount_char := GameState.match_state.find_character(str(payload.get("mount_id", "")))
	if mount_char == null or mount_char.defeated:
		return _fail("unknown mount")
	if not ["Hero", "Leader"].has(actor.data.type):
		return _fail("only a Hero or Leader may mount")
	if mount_char.data.type != "Mount" or mount_char.player_id != actor.player_id:
		return _fail("invalid mount target")
	if actor.mounted_with_id != "" or mount_char.mounted_with_id != "":
		return _fail("already mounted")
	if not _is_orthogonally_adjacent(actor.position, mount_char.position):
		return _fail("not adjacent")
	if actor.has_status("no_mount_dismount"):
		return _fail("cannot mount right now")
	mount_system.mount(actor, mount_char)
	_spend_ap(actor)
	return {"success": true}


func _handle_dismount(actor: CharacterInstance, payload: Dictionary) -> Dictionary:
	if not actor.is_mounted_rider or actor.mounted_with_id == "":
		return _fail("not mounted")
	var to = payload.get("to")
	if not to is Vector2i:
		return _fail("missing destination")
	if not _is_orthogonally_adjacent(actor.position, to):
		return _fail("not adjacent")
	var board := _board()
	if not board.is_in_bounds(to) or board.is_occupied_by_character(to) or board.get_placed_object(to) != null:
		return _fail("no empty adjacent tile")
	if actor.has_status("no_mount_dismount"):
		return _fail("cannot dismount right now")
	mount_system.dismount(actor, to)
	_spend_ap(actor)
	return {"success": true}


func _handle_end_turn(player_id: String) -> Dictionary:
	TurnManager.end_turn(player_id)
	return {"success": true}


func _handle_reactive_bonus(actor: CharacterInstance, payload: Dictionary) -> Dictionary:
	# Free by design: the card text grants these "without spending AP".
	if actor.has_status("no_reaction"):
		return _fail("reactions disabled")
	var flag := str(payload.get("tag", "")) + "_available"
	if not actor.ability_uses_this_turn.get(flag, false) and not actor.ability_uses_this_match.get(flag, false):
		return _fail("no bonus action available")
	return ability_system.execute_reactive_bonus(actor, str(payload.get("tag", "")), payload)


# --- Helpers -----------------------------------------------------------------

func _spend_ap(actor: CharacterInstance) -> void:
	# The only AP spend path (BR-020).
	var player := GameState.match_state.get_player(actor.player_id)
	player.pool_ap_remaining -= 1
	actor.character_ap_remaining -= 1
	EventBus.pool_ap_changed.emit(actor.player_id, player.pool_ap_remaining)
	EventBus.character_ap_changed.emit(actor.instance_id, actor.character_ap_remaining)


func _refund_ap(actor: CharacterInstance) -> void:
	var player := GameState.match_state.get_player(actor.player_id)
	player.pool_ap_remaining += 1
	actor.character_ap_remaining += 1
	EventBus.pool_ap_changed.emit(actor.player_id, player.pool_ap_remaining)
	EventBus.character_ap_changed.emit(actor.instance_id, actor.character_ap_remaining)


func _movement(actor: CharacterInstance) -> Dictionary:
	# Who supplies the movement rules, and with what budget and pattern. A mounted pair
	# moves with the Mount's MOVE, pattern, and movement abilities (BR-014).
	if actor.is_mounted_rider:
		return {
			"mover": GameState.match_state.find_character(actor.mounted_with_id),
			"budget": mount_system.get_effective_move_stat(actor),
			"pattern": mount_system.get_effective_movement_pattern(actor),
		}
	return {"mover": actor, "budget": actor.get_effective_move(),
			"pattern": ability_system.get_movement_pattern(actor)}


func _attack_candidate_tiles(actor: CharacterInstance) -> Array[Vector2i]:
	# RANGE is always the rider's own, even when mounted (BR-014).
	var attack_range := actor.get_effective_range("attack",
			ability_system.get_conditional_range_bonus(actor, "attack"))
	return _board().get_tiles_in_range(actor.position, attack_range, ability_system.get_attack_pattern(actor))


func _live_occupant(pos: Vector2i) -> CharacterInstance:
	var tile := _board().get_tile(pos)
	if tile == null or tile.occupant_id == "":
		return null
	var c := GameState.match_state.find_character(tile.occupant_id)
	return c if c != null and not c.defeated else null


func _find_live(actor_id: String) -> CharacterInstance:
	if GameState.match_state == null:
		return null
	var c := GameState.match_state.find_character(actor_id)
	return c if c != null and not c.defeated else null


func _ensure_systems() -> void:
	var state := GameState.match_state
	if state == null or _systems_for == state:
		return
	_systems_for = state
	ability_system = AbilitySystem.new(state.board)
	mount_system = MountSystem.new(state.board)
	combat_resolver = CombatResolver.new(state.board, ability_system, mount_system)
	ability_system.set_combat(combat_resolver)
	leveling_system = LevelingSystem.new(state.board, ability_system)


func _board() -> BoardModel:
	return GameState.match_state.board


static func _is_orthogonally_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1


static func _fail(reason: String) -> Dictionary:
	return {"success": false, "reason": reason}
