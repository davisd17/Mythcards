extends GutTest
# NetSession against LoopbackTransport (LLD-network-match.md 8.3). Only one engine runs per
# process, so "switching device" means that device rebuilding from the log (resync), which
# is exactly what a real device does when it opens the match.

const SEED := 42
const TEST_STORE := "user://test_net_matches.cfg"

var loop: LoopbackTransport
var a: NetSession      # p1, the creator
var b: NetSession      # p2
var _errors: Array = []
var _desyncs: Array = []
var _depth := 0
var _forward: NetSession = null


func before_each() -> void:
	NetStore.path = TEST_STORE
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_STORE))
	loop = LoopbackTransport.new()
	loop.next_seed = SEED
	a = _session()
	b = _session()
	_errors = []
	_desyncs = []


func after_each() -> void:
	_stop_forwarding()
	for s in [a, b]:
		if s.controller.setup != null:
			s.controller.setup.free()
	TurnManager.relic_event_deck = null
	TurnManager.victory_checker = null
	GameState.reset()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_STORE))
	NetStore.path = "user://net_matches.cfg"


func _session() -> NetSession:
	var s: NetSession = autofree(NetSession.new(loop, GameController.new()))
	s.build_version = "test1"
	s.poll_seconds = 0.0
	s.room_error.connect(func(m): _errors.append(m))
	s.desync.connect(func(seq, expected, actual): _desyncs.append([seq, expected, actual]))
	return s


# Both join, then each deploys with Auto-place on its own device.
func _deployed_match() -> void:
	assert_true(await a.create("closed-city"))
	assert_true(await b.join(a.code))
	await a.resync()
	a.controller.auto_place()
	a.controller.confirm_placement()
	await b.resync()
	b.controller.auto_place()
	b.controller.confirm_placement()


# Plays one AI turn for the session's seat, sending each top-level action as _send would.
func _play_turn(s: NetSession) -> void:
	_forward = s
	_depth = 0
	EventBus.action_requested.connect(_on_requested)
	EventBus.action_resolved.connect(_on_resolved)
	AIPlayer.new(s.seat, null, 7).take_turn()
	_stop_forwarding()


var _pending: Array = []

func _on_requested(action_type: String, actor_id: String, payload: Dictionary) -> void:
	_depth += 1
	if _depth == 1:
		_pending = [action_type, actor_id, payload.duplicate(true)]


func _on_resolved(_t: String, _a: String, result: Dictionary) -> void:
	_depth -= 1
	if _depth == 0 and result.get("success", false):
		_forward.submit(_pending[0], _pending[1], _pending[2])


func _stop_forwarding() -> void:
	if EventBus.action_requested.is_connected(_on_requested):
		EventBus.action_requested.disconnect(_on_requested)
		EventBus.action_resolved.disconnect(_on_resolved)


# --- Rooms ---------------------------------------------------------------------------------

func test_join_with_another_version_is_refused() -> void:
	assert_true(await a.create("flood-survivors"))
	assert_eq(a.seat, "p1")
	assert_eq(a.room.teams, {"p1": "flood-survivors", "p2": "closed-city"})
	b.build_version = "other9"
	assert_false(await b.join(a.code))
	assert_eq(_errors.size(), 1)
	assert_string_contains(_errors[0], "different version")
	assert_string_contains(_errors[0], "other9")
	assert_eq(b.code, "", "no seat taken")


func test_create_saves_the_seat() -> void:
	await a.create("closed-city")
	var saved := NetStore.get_seat(a.code)
	assert_eq(saved.seat, "p1")
	assert_eq(saved.token, a.token)
	assert_eq(saved.version, "test1")
	assert_true(a.controller.in_setup())
	assert_eq(a.controller.placing_player, "p1")


# --- Deploys -------------------------------------------------------------------------------

func test_deploy_stays_hidden_then_the_match_starts_with_the_room_seed() -> void:
	await a.create("closed-city")
	await b.join(a.code)
	await a.resync()
	a.controller.auto_place()
	a.controller.confirm_placement()
	assert_true(a.deploys.has("p1"))
	assert_false(a.is_my_decision(), "p1 waits once deployed")

	await b.resync()
	assert_true(b.opponent_deployed, "p2 knows p1 is in")
	assert_false(b.deploys.has("p1"), "but not where")
	assert_true(b.controller.in_setup())
	assert_true(b.is_my_decision())

	b.controller.auto_place()
	b.controller.confirm_placement()
	assert_eq(b.deploys.size(), 2)
	assert_true(b.match_started())
	assert_eq(GameState.match_state.deck_seed, SEED)
	assert_eq(GameState.match_state.active_player_id, "p1")
	for id in a.deploys.p1:
		assert_eq(b.controller.find(id).position, a.deploys.p1[id], "%s where p1 put it" % id)
	assert_eq(b.applied, 2)


func test_a_deploy_sent_after_the_other_still_goes_in() -> void:
	# p2 deploys while p1 is still placing; p1's deploy then meets a seq conflict.
	await a.create("closed-city")
	await b.join(a.code)
	b.controller.auto_place()
	b.controller.confirm_placement()
	assert_eq(a.applied, 0, "p1 hasn't fetched since creating")
	a.controller.auto_place()
	a.controller.confirm_placement()
	assert_eq(_errors, [])
	assert_true(a.match_started())
	assert_eq(loop.rooms[a.code].log.size(), 2)
	assert_eq(loop.rooms[a.code].log[1].seat, "p1")


# --- Actions -------------------------------------------------------------------------------

func test_an_action_is_appended_and_the_other_device_reaches_the_same_state() -> void:
	await _deployed_match()
	await a.resync()
	assert_false(a.controller.is_remote_turn())
	_play_turn(a)
	var log: Array = loop.rooms[a.code].log
	assert_gt(log.size(), 2, "p1's turn was sent")
	assert_eq(a.applied, log.size())
	assert_eq(a.outbox, [])
	var hash_after := ActionCodec.state_hash()
	assert_eq(log[-1].hash_after, hash_after)

	await b.resync()
	assert_eq(ActionCodec.state_hash(), hash_after)
	assert_eq(b.applied, a.applied)
	assert_eq(_desyncs, [])


func test_end_turn_through_the_controller_is_sent() -> void:
	await _deployed_match()
	await a.resync()
	a.controller.end_turn()
	var log: Array = loop.rooms[a.code].log
	assert_eq(log[-1].kind, "action")
	assert_eq(log[-1].action.action_type, "end_turn")
	assert_eq(log[-1].seat, "p1")
	assert_true(a.controller.is_remote_turn(), "p2 is up")
	assert_false(a.is_my_decision())


func test_poll_applies_new_entries_in_order() -> void:
	await _deployed_match()
	await a.resync()
	_play_turn(a)
	var hash_after := ActionCodec.state_hash()
	var log: Array = loop.rooms[a.code].log
	var turn: Array = log.slice(2)
	log.resize(2)
	await b.resync()           # p2 opened the match before p1 moved
	assert_true(b.controller.is_remote_turn())
	log.append_array(turn)
	var counts := []
	b.log_applied.connect(func(n): counts.append(n))
	await b.poll()
	assert_eq(counts, [turn.size()])
	assert_eq(b.applied, log.size())
	assert_eq(ActionCodec.state_hash(), hash_after)


func test_is_remote_turn_follows_the_decision_player() -> void:
	await _deployed_match()
	await b.resync()
	assert_eq(RelicEventDeck.decision_player(), "p1")
	assert_true(b.controller.is_remote_turn())
	assert_false(b.is_my_decision())
	await a.resync()
	assert_false(a.controller.is_remote_turn())
	assert_true(a.is_my_decision())


# --- Failures ------------------------------------------------------------------------------

func test_a_forged_hash_is_a_desync() -> void:
	await _deployed_match()
	await b.resync()
	loop.inject(a.code, {"seat": "p1", "kind": "action", "hash_after": "0000000000000000",
			"action": ActionCodec.encode("end_turn", "p1", {})})
	await b.poll()
	assert_true(b.desynced)
	assert_eq(_desyncs.size(), 1)
	assert_eq(_desyncs[0][0], 2)
	assert_eq(_desyncs[0][1], "0000000000000000")
	assert_eq(b.applied, 2, "the bad entry isn't counted")
	b.submit("end_turn", "p2", {})
	assert_eq(loop.rooms[a.code].log.size(), 3, "a desynced device sends nothing")


func test_a_stale_seq_resyncs() -> void:
	await _deployed_match()
	await a.resync()
	a.controller.end_turn()
	await a.resync()
	a.applied -= 1   # this device missed an entry
	await a.submit("end_turn", "p1", {})
	assert_eq(_errors.size(), 1)
	assert_string_contains(_errors[0], "arrived first")
	assert_eq(a.applied, loop.rooms[a.code].log.size(), "rebuilt from the server log")
	assert_eq(a.outbox, [])


func test_offline_actions_wait_in_the_outbox() -> void:
	await _deployed_match()
	await a.resync()
	loop.offline = true
	a.controller.end_turn()
	assert_true(a.offline)
	assert_eq(a.outbox.size(), 1)
	assert_eq(NetStore.get_seat(a.code).outbox.size(), 1, "saved for a restart")
	assert_eq(loop.rooms[a.code].log.size(), 2)
	loop.offline = false
	await a._flush()
	assert_false(a.offline)
	assert_eq(a.outbox, [])
	assert_eq(loop.rooms[a.code].log.size(), 3)
	assert_eq(NetStore.get_seat(a.code).outbox, [])


func test_open_sends_the_saved_outbox_and_rebuilds() -> void:
	await _deployed_match()
	await a.resync()
	loop.offline = true
	a.controller.end_turn()
	var hash_after := ActionCodec.state_hash()
	loop.offline = false
	# Both test seats share one store, and b's join overwrote this code; restore p1's
	# seat as p1's own device would have it (the outbox is kept).
	NetStore.save(a.code, "p1", a.token, "closed-city", "test1")
	var reopened := _session()   # the app was closed and opened again
	assert_true(await reopened.open(a.code))
	assert_eq(reopened.seat, "p1")
	assert_eq(loop.rooms[a.code].log.size(), 3)
	assert_eq(ActionCodec.state_hash(), hash_after)
	assert_eq(_desyncs, [])


func test_open_refuses_another_build() -> void:
	await a.create("closed-city")
	var other := _session()
	other.build_version = "newer"
	assert_false(await other.open(a.code))
	assert_string_contains(_errors[-1], "build test1")
	assert_false(await other.open("NOPEXX"))
