class_name StatusEffect
extends RefCounted
# A temporary marker on a character (Shield, Marked, Slow, Memory, ...). This class
# defines only the shape; AbilitySystem/CombatResolver apply and consume effects, and
# TurnManager clears them by `expires` (LLD-match-setup 3.2, 4.3).

var type: String = ""       # e.g. "shield" | "temp_atk" | "temp_move" | "temp_range" | "slow" | "marked"
var value: int = 0          # meaning depends on type (shield: prevention left; temp_*: stat delta); 0 for flags
var expires: String = ""    # one of GameEnums.STATUS_EXPIRY
var applied_on_turn: int = -1  # MatchState.turn_number when applied; read by "this_round" clearing
var ticks: int = 0             # holder's own turn-starts survived; read by "next_turn" clearing
var source_character_id: String = ""  # instance_id of whoever applied it (debug/attribution only)


func _init(p_type: String = "", p_value: int = 0, p_expires: String = "this_turn", p_applied_on_turn: int = -1) -> void:
	type = p_type
	value = p_value
	expires = p_expires
	applied_on_turn = p_applied_on_turn
