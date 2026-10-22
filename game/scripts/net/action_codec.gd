class_name ActionCodec
# JSON-safe action payloads and a short hash of the match state (LLD-network-match.md 3.1).
# Online play sends every action as JSON and checks the hash after it on both clients, so
# a divergence is caught at the first bad action. TestBridge uses the same conversions.


# {"x": int, "y": int} -> Vector2i, recursively (JSON has no Vector2i).
static func to_engine(value: Variant) -> Variant:
	if value is Dictionary:
		if value.size() == 2 and value.has("x") and value.has("y") and _is_number(value.x) and _is_number(value.y):
			return Vector2i(int(value.x), int(value.y))
		var out := {}
		for k in value.keys():
			out[k] = to_engine(value[k])
		return out
	if value is Array:
		return value.map(func(v): return to_engine(v))
	return value


static func to_json_safe(value: Variant) -> Variant:
	if value is Vector2i:
		return pos(value)
	if value is Dictionary:
		var out := {}
		for k in value.keys():
			out[k] = to_json_safe(value[k])
		return out
	if value is Array:
		return value.map(func(v): return to_json_safe(v))
	return value


static func encode(action_type: String, actor_id: String, payload: Dictionary) -> Dictionary:
	return {"action_type": action_type, "actor_id": actor_id, "payload": to_json_safe(payload)}


# 16 hex characters of SHA-256 over the serialized match state, with sorted keys.
static func state_hash() -> String:
	return JSON.stringify(TestBridge.serialize_state(), "", true).sha256_text().left(16)


static func pos(p: Vector2i) -> Dictionary:
	return {"x": p.x, "y": p.y}


static func _is_number(v) -> bool:
	return v is int or v is float
