extends RelicEventHandler
# Whiteout (Event, 1 round): all ranged attacks and ranged abilities have -1 RANGE,
# minimum 1 — for both players (designer ruling 2026-09-27).

const RANGE_PENALTY := 1


func on_activate(sys, _player_id: String) -> Dictionary:
	sys.state().global_range_modifier -= RANGE_PENALTY
	return {}


func on_expire(sys, _player_id: String, _data: Dictionary) -> void:
	sys.state().global_range_modifier += RANGE_PENALTY
