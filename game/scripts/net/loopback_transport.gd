class_name LoopbackTransport
extends NetTransport
# An in-memory relay server for GUT (LLD-network-match.md 3.2). It follows the same rules
# as server/src/room_logic.ts, and every body goes through JSON both ways, as on the wire
# (numbers come back as floats). Two NetSessions sharing one LoopbackTransport are the two
# players.

const OPPONENT_TEAM := {"closed-city": "flood-survivors", "flood-survivors": "closed-city"}

var rooms: Dictionary = {}    # code -> {seed, teams, version, tokens: {p1, p2}, log: Array}
var offline := false          # true: every call fails as if the server can't be reached
var next_seed := -1           # >= 0 fixes the next room's seed
var _count := 0


func create_room(team_id: String, version: String) -> Dictionary:
	if offline:
		return NetTransport.result(0, {}, "can't reach the server")
	if not OPPONENT_TEAM.has(team_id):
		return _reply(400, {"error": "unknown_team"})
	_count += 1
	var code := "TEST%s" % char(64 + _count).repeat(2)   # TESTAA, TESTBB, ...
	var token := "p1-%s" % code
	var seed_value := next_seed if next_seed >= 0 else randi() & 0x7fffffff
	next_seed = -1
	rooms[code] = {"seed": seed_value, "teams": {"p1": team_id, "p2": OPPONENT_TEAM[team_id]},
			"version": version, "tokens": {"p1": token, "p2": ""}, "log": []}
	return _reply(201, _summary(code).merged({"code": code, "seat": "p1", "token": token}))


func join_room(code: String, version: String) -> Dictionary:
	if offline:
		return NetTransport.result(0, {}, "can't reach the server")
	code = code.to_upper()
	if not rooms.has(code):
		return _reply(404, {"error": "no_room"})
	var room: Dictionary = rooms[code]
	if room.tokens.p2 != "":
		return _reply(409, {"error": "seat_taken"})
	if version != room.version:
		return _reply(409, {"error": "version_mismatch", "room_version": room.version, "your_version": version})
	room.tokens.p2 = "p2-%s" % code
	return _reply(200, _summary(code).merged({"seat": "p2", "token": room.tokens.p2}))


func fetch_log(code: String, token: String, since: int) -> Dictionary:
	if offline:
		return NetTransport.result(0, {}, "can't reach the server")
	if not rooms.has(code):
		return _reply(404, {"error": "no_room"})
	var seat := _seat(code, token)
	if seat == "":
		return _reply(401, {"error": "bad_token"})
	var room: Dictionary = rooms[code]
	var deployed := _deployed(code)
	var entries := []
	for e in room.log:
		if e.seq < since:
			continue
		if e.kind == "deploy" and e.seat != seat and not deployed.has(seat):
			entries.append({"seq": e.seq, "seat": e.seat, "kind": "deploy_hidden"})
		else:
			entries.append(e)
	var status := "waiting_for_join" if room.tokens.p2 == "" else ("deploying" if deployed.size() < 2 else "playing")
	return _reply(200, _summary(code).merged({"entries": entries, "next": room.log.size(), "status": status}))


func append(code: String, token: String, entry: Dictionary) -> Dictionary:
	if offline:
		return NetTransport.result(0, {}, "can't reach the server")
	if not rooms.has(code):
		return _reply(404, {"error": "no_room"})
	var seat := _seat(code, token)
	if seat == "":
		return _reply(401, {"error": "bad_token"})
	var room: Dictionary = rooms[code]
	entry = JSON.parse_string(JSON.stringify(entry))
	var next: int = room.log.size()
	if int(entry.get("seq", -1)) != next:
		return _reply(409, {"error": "seq_conflict", "next": next})
	var deployed := _deployed(code)
	match entry.get("kind"):
		"deploy":
			if deployed.has(seat):
				return _reply(409, {"error": "already_deployed"})
		"action":
			if deployed.size() < 2:
				return _reply(409, {"error": "not_started"})
		_:
			return _reply(400, {"error": "unknown_kind"})
	entry.seq = next
	entry.seat = seat
	room.log.append(entry)
	return _reply(200, {"next": next + 1})


# Adds an entry as if the given seat sent it, skipping the checks (forged-entry tests).
func inject(code: String, entry: Dictionary) -> void:
	var room: Dictionary = rooms[code]
	entry = JSON.parse_string(JSON.stringify(entry))
	entry.seq = room.log.size()
	room.log.append(entry)


func _summary(code: String) -> Dictionary:
	var room: Dictionary = rooms[code]
	return {"seed": room.seed, "teams": room.teams.duplicate(), "version": room.version}


func _seat(code: String, token: String) -> String:
	var tokens: Dictionary = rooms[code].tokens
	if token != "" and token == tokens.p1:
		return "p1"
	if token != "" and token == tokens.p2:
		return "p2"
	return ""


func _deployed(code: String) -> Dictionary:
	var seats := {}
	for e in rooms[code].log:
		if e.kind == "deploy":
			seats[e.seat] = true
	return seats


func _reply(status: int, body: Dictionary) -> Dictionary:
	return NetTransport.result(status, JSON.parse_string(JSON.stringify(body)))
