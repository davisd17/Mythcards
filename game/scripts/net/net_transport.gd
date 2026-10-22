class_name NetTransport
extends RefCounted
# The relay server API (LLD-network-match.md 3.2, routes in Section 6). Every call returns
# {"ok": bool, "status": int, "body": Dictionary, "error": String}; callers `await` it.
# status 0 means the server couldn't be reached. HttpTransport talks to the Worker;
# LoopbackTransport keeps the same rules in memory for tests.


func create_room(_team_id: String, _version: String) -> Dictionary:
	return result(0, {}, "not implemented")


func join_room(_code: String, _version: String) -> Dictionary:
	return result(0, {}, "not implemented")


func fetch_log(_code: String, _token: String, _since: int) -> Dictionary:
	return result(0, {}, "not implemented")


func append(_code: String, _token: String, _entry: Dictionary) -> Dictionary:
	return result(0, {}, "not implemented")


static func result(status: int, body: Dictionary, error: String = "") -> Dictionary:
	if error == "" and status >= 300:
		error = str(body.get("error", "http_%d" % status))
	return {"ok": status >= 200 and status < 300, "status": status, "body": body, "error": error}
