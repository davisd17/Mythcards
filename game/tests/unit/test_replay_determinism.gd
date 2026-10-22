extends GutTest
# The online-match guarantee (LLD-network-match.md 8.2): a match is two teams, a deck seed,
# the placements and an ordered action log, and replaying that log through RulesEngine
# reaches the same state after every action. If this fails, online play can't work.

const SetupFlowScript := preload("res://scripts/scenes/setup_flow.gd")
const MAX_TURNS := 120

var _log: Array = []      # [{action_type, actor_id, payload, success, hash}]
var _depth := 0           # only top-level actions are recorded


func after_each() -> void:
	_stop_recording()
	TurnManager.relic_event_deck = null
	TurnManager.victory_checker = null
	GameState.reset()


func _start(seed_value: int, placements: Dictionary) -> Node:
	TurnManager.relic_event_deck = null
	TurnManager.victory_checker = null
	GameState.reset()
	var setup: Node = autofree(SetupFlowScript.new())
	setup.select_team("p1", "closed-city")
	setup.select_team("p2", "flood-survivors")
	if placements.is_empty():
		AIPlayer.new("p1", null, seed_value).place_squad(setup)
		AIPlayer.new("p2", null, seed_value + 100).place_squad(setup)
	else:
		for id in placements:
			var player_id: String = id.left(2)
			assert_true(setup.place_character(player_id, id, placements[id]), "replay places %s" % id)
	setup.start_match(seed_value)
	return setup


func _placements() -> Dictionary:
	var out := {}
	for p in GameState.match_state.players:
		for c in p.characters:
			out[c.instance_id] = c.position
	return out


func _on_requested(action_type: String, actor_id: String, payload: Dictionary) -> void:
	_depth += 1
	if _depth == 1:
		_log.append({"action_type": action_type, "actor_id": actor_id, "payload": payload.duplicate(true)})


func _on_resolved(_action_type: String, _actor_id: String, result: Dictionary) -> void:
	_depth -= 1
	if _depth == 0:
		_log[-1]["success"] = result.get("success", false)
		_log[-1]["hash"] = ActionCodec.state_hash()


func _start_recording() -> void:
	_log = []
	_depth = 0
	EventBus.action_requested.connect(_on_requested)
	EventBus.action_resolved.connect(_on_resolved)


func _stop_recording() -> void:
	if EventBus.action_requested.is_connected(_on_requested):
		EventBus.action_requested.disconnect(_on_requested)
		EventBus.action_resolved.disconnect(_on_resolved)


# Plays an AI-vs-AI match and returns everything needed to replay it.
func _record(seed_value: int) -> Dictionary:
	_start(seed_value, {})
	var placements := _placements()
	var start_hash := ActionCodec.state_hash()
	var players := {"p1": AIPlayer.new("p1", null, seed_value), "p2": AIPlayer.new("p2", null, seed_value + 100)}
	_start_recording()
	var state := GameState.match_state
	var guard := 0
	while state.phase == "in_progress" and state.turn_number <= MAX_TURNS and guard < MAX_TURNS * 2:
		players[state.active_player_id].take_turn()
		guard += 1
	_stop_recording()
	return {"placements": placements, "start_hash": start_hash, "log": _log.duplicate(true),
			"winner": state.winner_id, "how": state.win_condition, "phase": state.phase}


# Rebuilds from the recording; returns the index of the first mismatch, or -1.
func _replay(seed_value: int, recording: Dictionary, through_json: bool) -> int:
	_start(seed_value, recording.placements)
	if ActionCodec.state_hash() != recording.start_hash:
		return -2
	var entries: Array = recording.log
	for i in entries.size():
		var e: Dictionary = entries[i]
		var payload: Dictionary = e.payload
		if through_json:
			var wire := JSON.stringify(ActionCodec.encode(e.action_type, e.actor_id, payload))
			var parsed: Dictionary = JSON.parse_string(wire)
			payload = ActionCodec.to_engine(parsed.payload)
		var result := RulesEngine.request_action(e.action_type, e.actor_id, payload)
		if result.get("success", false) != e.success or ActionCodec.state_hash() != e.hash:
			gut.p("seed %d: mismatch at action %d %s %s %s" % [seed_value, i, e.action_type, e.actor_id, e.payload])
			return i
	return -1


func test_codec_round_trips_positions() -> void:
	var payload := {"to": Vector2i(3, 2), "tiles": [Vector2i(1, 1)], "option": "a"}
	var wire := JSON.stringify(ActionCodec.encode("move", "p1_x", payload))
	var back: Dictionary = JSON.parse_string(wire)
	assert_eq(ActionCodec.to_engine(back.payload), payload)


func test_state_hash_is_stable_and_changes_after_a_move() -> void:
	_start(7, {})
	var before := ActionCodec.state_hash()
	assert_eq(ActionCodec.state_hash(), before, "the same state hashes the same")
	assert_eq(before.length(), 16)
	AIPlayer.new("p1", null, 7).take_turn()
	assert_ne(ActionCodec.state_hash(), before, "a played turn changes the hash")


func test_replaying_the_log_reaches_the_same_state() -> void:
	for seed_value in [7, 42, 2026]:
		var recording := _record(seed_value)
		gut.p("seed %d: %d actions, %s %s %s" % [seed_value, recording.log.size(), recording.phase,
				recording.winner, recording.how])
		assert_gt(recording.log.size(), 10, "seed %d played a real match" % seed_value)
		assert_eq(_replay(seed_value, recording, false), -1, "seed %d replays exactly" % seed_value)
		assert_eq(GameState.match_state.winner_id, recording.winner, "seed %d: same winner" % seed_value)


func test_replaying_through_json_reaches_the_same_state() -> void:
	for seed_value in [7, 42, 2026]:
		var recording := _record(seed_value)
		assert_eq(_replay(seed_value, recording, true), -1, "seed %d replays exactly over JSON" % seed_value)
		assert_eq(GameState.match_state.winner_id, recording.winner, "seed %d: same winner" % seed_value)
