class_name NetSession
extends Node
# One online match on this device (LLD-network-match.md 3.4, 4.1-4.3). The match is the
# room's seed and teams plus an ordered log of deploys and actions; this device plays
# `seat`. Local actions are sent after they succeed here; the other seat's entries are
# replayed through RulesEngine and checked against the hash the sender recorded.
#
# Network calls run one at a time (`_busy`), and polling waits while anything is unsent,
# so `applied` always equals the number of server entries this device has applied.

signal log_applied(count: int)
signal desync(seq: int, expected: String, actual: String)
signal room_error(message: String)
signal rebuilt                      # a rebuild from the log finished (the screen drops replayed effects)

const POLL_SECONDS := 5.0

var transport: NetTransport
var controller: GameController
var code := ""
var seat := ""
var token := ""
var room: Dictionary = {}           # {seed, teams: {p1, p2}, version, status}
var applied := 0                    # entries applied locally; the next seq
var desynced := false
var replaying := false              # catching up from the log: no popups, effects or sounds
var offline := false                # the last call couldn't reach the server
var poll_seconds := POLL_SECONDS    # 0 turns polling off
var build_version := version()      # this build; tests override it
var deploys: Dictionary = {}        # seat -> {instance_id: Vector2i}, as known on this device
var opponent_deployed := false      # the other seat's deploy is in (it may still be hidden)
var outbox: Array = []              # entries accepted locally but not yet by the server

var _busy := false
var _since_poll := 0.0


func _init(net_transport: NetTransport = null, game_controller: GameController = null) -> void:
	transport = net_transport
	controller = game_controller


static func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", ""))


# --- Rooms ---------------------------------------------------------------------------------

func create(team_id: String) -> bool:
	var r: Dictionary = await transport.create_room(team_id, build_version)
	if not r.ok:
		room_error.emit(_message(r))
		return false
	code = str(r.body.code)
	_take_seat(r.body, team_id)
	await _rebuild([])
	return true


func join(room_code: String) -> bool:
	var r: Dictionary = await transport.join_room(room_code.strip_edges().to_upper(), build_version)
	if not r.ok:
		room_error.emit(_message(r))
		return false
	code = room_code.strip_edges().to_upper()
	_take_seat(r.body, str(r.body.teams.p2))
	await _rebuild([])
	return true


# Picks up a saved seat: sends anything left unsent, then rebuilds from the whole log.
func open(room_code: String) -> bool:
	var saved := NetStore.get_seat(room_code)
	if saved.is_empty():
		room_error.emit("This device has no seat in match %s." % room_code)
		return false
	if saved.version != build_version:
		room_error.emit("This match was started on build %s. Finish it on that build, or start a new one." % saved.version)
		return false
	code = room_code
	seat = saved.seat
	token = saved.token
	outbox = saved.outbox.duplicate(true)   # each entry keeps the seq it was numbered with
	await _flush(false)
	return await resync()


func _take_seat(body: Dictionary, team_id: String) -> void:
	seat = str(body.seat)
	token = str(body.token)
	room = {"seed": int(body.seed), "teams": body.teams, "version": str(body.version), "status": ""}
	NetStore.save(code, seat, token, team_id, build_version)


# --- Sending -------------------------------------------------------------------------------

# GameController._send calls this after a local action succeeded.
func submit(action_type: String, actor_id: String, payload: Dictionary) -> void:
	if desynced or replaying or code == "":
		return
	_queue({"kind": "action", "action": ActionCodec.encode(action_type, actor_id, payload),
			"hash_after": ActionCodec.state_hash()})
	await _flush()


# placements: {instance_id: Vector2i}
func submit_deploy(placements: Dictionary) -> void:
	deploys[seat] = placements.duplicate()
	_queue({"kind": "deploy", "placements": ActionCodec.to_json_safe(placements)})
	await _flush()


func _queue(entry: Dictionary) -> void:
	entry.seq = applied + outbox.size()
	entry.seat = seat
	outbox.append(entry)
	NetStore.set_outbox(code, outbox)


# Sends the outbox in order. After a deploy goes through, the whole log is fetched again:
# that's when the server reveals the other formation if it was already in.
func _flush(resync_after_deploy: bool = true) -> void:
	if _busy:
		return
	_busy = true
	var deployed := false
	while not outbox.is_empty():
		var entry: Dictionary = outbox[0]
		var r: Dictionary = await transport.append(code, token, entry)
		if r.ok:
			outbox.pop_front()
			applied += 1
			deployed = deployed or entry.kind == "deploy"
			offline = false
			continue
		if r.status == 0:
			offline = true   # kept and retried on the next poll tick (Section 7)
			break
		if r.error == "seq_conflict" and entry.kind == "deploy":
			# The other formation went in first while this one was being placed.
			if await _fetch_and_apply():
				for i in outbox.size():
					outbox[i].seq = applied + i
				continue
			break
		outbox.clear()
		if r.error == "seq_conflict":
			room_error.emit("Your friend's moves arrived first, so the board was reloaded and your last move was undone.")
			deployed = true   # rebuild below
		else:
			room_error.emit(_message(r))
		break
	NetStore.set_outbox(code, outbox)
	_busy = false
	if deployed and resync_after_deploy:
		await resync()


# --- Receiving -----------------------------------------------------------------------------

func poll() -> void:
	if _busy or desynced or code == "":
		return
	_busy = true
	await _fetch_and_apply()
	_busy = false


func resync() -> bool:
	var r: Dictionary = await transport.fetch_log(code, token, 0)
	if not r.ok:
		offline = r.status == 0
		room_error.emit(_message(r))
		return false
	_read_room(r.body)
	await _rebuild(r.body.entries)
	return true


func _fetch_and_apply() -> bool:
	var r: Dictionary = await transport.fetch_log(code, token, applied)
	if not r.ok:
		offline = r.status == 0
		return false
	offline = false
	_read_room(r.body)
	_apply_entries(r.body.entries)
	return true


func _read_room(body: Dictionary) -> void:
	room = {"seed": int(body.seed), "teams": body.teams, "version": str(body.version), "status": str(body.status)}


# 4.1: start over from setup and replay every entry.
func _rebuild(entries: Array) -> void:
	replaying = true
	applied = 0
	deploys = {}
	opponent_deployed = false
	desynced = false
	MatchLog.clear()
	controller.begin_online(self)
	_apply_entries(entries)
	replaying = false
	controller.sync()
	rebuilt.emit()


# 4.2: applies entries in seq order and stops at the first gap or mismatch.
func _apply_entries(entries: Array) -> void:
	var count := 0
	for entry in entries:
		var seq := int(entry.seq)
		if seq < applied:
			continue
		if seq != applied:
			resync.call_deferred()
			return
		match entry.kind:
			"deploy", "deploy_hidden":
				if entry.seat != seat:
					opponent_deployed = true
				if entry.kind == "deploy":
					deploys[entry.seat] = ActionCodec.to_engine(entry.placements)
					if entry.seat == seat and not match_started():
						controller.place_deploy(seat, deploys[seat])
			"action":
				var a: Dictionary = entry.action
				var result := {}
				if match_started():
					result = RulesEngine.request_action(a.action_type, a.actor_id, ActionCodec.to_engine(a.payload))
				var actual := ActionCodec.state_hash()
				if not result.get("success", false) or actual != entry.hash_after:
					desynced = true
					desync.emit(seq, str(entry.hash_after), actual)
					return
		applied += 1
		count += 1
		if deploys.size() == 2 and not match_started():
			controller.apply_remote_deploys(deploys, int(room.seed))
	if GameState.match_state != null and GameState.match_state.phase == "ended":
		NetStore.mark_ended(code)
	log_applied.emit(count)


# --- State ---------------------------------------------------------------------------------

func match_started() -> bool:
	return controller.setup == null and GameState.match_state != null


# Whether this device should act now: deploying until its formation is in, then whenever
# the engine's decision player is this seat (a drawn card's choice included).
func is_my_decision() -> bool:
	if not match_started():
		return not deploys.has(seat)
	return RelicEventDeck.decision_player() == seat


func _process(delta: float) -> void:
	if poll_seconds <= 0.0 or code == "" or desynced or _busy:
		return
	var waiting := not is_my_decision() and not (match_started() and not GameState.is_match_active())
	if outbox.is_empty() and not waiting:
		_since_poll = 0.0
		return
	_since_poll += delta
	if _since_poll < poll_seconds:
		return
	_since_poll = 0.0
	if not outbox.is_empty():
		_flush()
	else:
		poll()


func _message(r: Dictionary) -> String:
	if r.status == 0:
		return "Can't reach the server. Check your connection and try again."
	match r.error:
		"version_mismatch":
			return "Your friend is on a different version of the game (theirs: %s, yours: %s)." % [
					r.body.get("room_version", "?"), r.body.get("your_version", "?")]
		"no_room":
			return "There's no match with that code."
		"seat_taken":
			return "That match already has two players."
		"bad_token":
			return "This device's seat in that match isn't valid any more."
	return "The server refused that (%s)." % r.error
