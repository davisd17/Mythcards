class_name AIPlayer
extends RefCounted
# A computer opponent for one side (LLD-ai-opponent.md). It sees the match through
# ActionGenerator, judges with AIEvaluator, and acts only through RulesEngine, exactly
# like a player. Re-plans after every action.
#
#   next_action() -> {action_type, actor_id, payload, score, why}   (end_turn when done)
#   take_turn()   plays the whole turn at once (headless: tests, AI vs AI)
#   place_squad(setup) deploys its back row

const MAX_ACTIONS_PER_TURN := 40   # a safety stop; a turn rarely needs more than 8

var player_id: String
var personality: AIPersonality
var generator: ActionGenerator
var evaluator: AIEvaluator
var rng := RandomNumberGenerator.new()
var last_choice: Dictionary = {}   # the most recent decision, for the screen and log


func _init(p_player_id: String, p_personality: AIPersonality = null, seed_value: int = 1) -> void:
	player_id = p_player_id
	personality = p_personality if p_personality != null else AIPersonality.load_named("basic")
	generator = ActionGenerator.new(player_id)
	evaluator = AIEvaluator.new(personality, player_id)
	rng.seed = seed_value


func is_my_turn() -> bool:
	var state := GameState.match_state
	return state != null and GameState.is_match_active() and state.active_player_id == player_id


func next_action() -> Dictionary:
	if not is_my_turn():
		return {}
	var best: Dictionary = {}
	var best_score := -INF
	var mandatory := false
	for candidate in generator.generate():
		var judged := evaluator.score(candidate)
		var points: float = judged.score + rng.randf() * personality.randomness
		mandatory = mandatory or ["deck_choice", "return"].has(candidate.kind)
		if points > best_score:
			best_score = points
			best = candidate.duplicate()
			best["score"] = points
			best["why"] = judged.why
	var end := {"action_type": "end_turn", "actor_id": player_id, "payload": {}, "score": 0.0, "why": "nothing better to do"}
	if best.is_empty() or (best_score < personality.end_turn_threshold and not mandatory):
		# The capture rule: never end the turn with our Hero unable to move.
		if evaluator.own_hero_moves() == 0:
			var rescue := _free_the_hero()
			if not rescue.is_empty():
				last_choice = rescue
				return rescue
		last_choice = end
		return end
	last_choice = best
	return best


# Plays until the turn passes (or the match ends). Returns the actions taken.
func take_turn() -> Array[Dictionary]:
	var taken: Array[Dictionary] = []
	for i in MAX_ACTIONS_PER_TURN:
		if not is_my_turn():
			break
		var action := next_action()
		var result := RulesEngine.request_action(action.action_type, action.actor_id, action.payload)
		action["result"] = result
		taken.append(action)
		if action.action_type == "end_turn":
			break
		if not result.get("success", false):
			# A rejected action means the generator and the rules disagree: stop, don't loop.
			push_error("AIPlayer %s: %s rejected: %s" % [player_id, action, result.get("reason", "")])
			RulesEngine.request_action("end_turn", player_id, {})
			break
	if is_my_turn():
		RulesEngine.request_action("end_turn", player_id, {})
	return taken


# Deploys the back row: Hero in the middle, guarded by Leader and Warrior, ranged and
# support pieces next, fast pieces on the flanks.
func place_squad(setup: Node) -> void:
	const ORDER := {"Hero": 3, "Leader": 2, "Warrior": 4, "Mystic": 1, "Specialist": 5, "Mount": 0, "Common": 6}
	var row := BoardModel.PLAYER_A_EDGE_ROW if player_id == "p1" else BoardModel.PLAYER_B_EDGE_ROW
	for c in setup.get_player(player_id).characters:
		if c.is_placed():
			continue
		var x: int = ORDER.get(c.data.type, 0)
		if not setup.place_character(player_id, c.instance_id, Vector2i(x, row)):
			for alt in BoardModel.BOARD_SIZE:
				if setup.place_character(player_id, c.instance_id, Vector2i(alt, row)):
					break


# Any move that gives our trapped Hero a way out (a blocker steps aside, or the Hero moves).
func _free_the_hero() -> Dictionary:
	var best: Dictionary = {}
	for candidate in generator.generate():
		if candidate.kind != "move":
			continue
		var probe := evaluator._probe_move(evaluator._find(candidate.actor_id), candidate.payload.to)
		if probe.own_hero_moves > 0:
			best = candidate.duplicate()
			best["score"] = 0.0
			best["why"] = "free our Hero from capture"
			break
	return best
