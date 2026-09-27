class_name CharacterInstance
extends RefCounted
# One character on the board for one match. Constructed only by SetupFlow (setup) or,
# for copies created mid-match, with an id from MatchState.mint_instance_id().
# Never parse instance_id to recover the card id — read data.id.

const UNPLACED := Vector2i(-1, -1)

var instance_id: String = ""
var data: CharacterData = null
var player_id: String = ""       # "p1" | "p2"
var current_hp: int = 0
var base_max_hp: int = 0         # data.hp plus permanent level-up HP; positional/aura bonuses
                                 # are computed live by AbilitySystem, never stored here
var level: int = 1               # 1-3
var position: Vector2i = UNPLACED
var character_ap_remaining: int = 0
var character_ap_max: int = 1
var status_effects: Array[StatusEffect] = []
var spirit_ember_count: int = 0  # a mounted-pair kill grants two
var mounted_with_id: String = "" # instance_id of the other half of a mounted pair
var is_mounted_rider: bool = false
var ability_uses_this_turn: Dictionary = {}   # effect_tag -> count; cleared each owner turn start
var ability_uses_this_match: Dictionary = {}  # effect_tag -> count; never cleared mid-match
var atk_bonus: int = 0    # permanent, written only when a level-up is applied
var move_bonus: int = 0
var range_bonus: int = 0


func is_placed() -> bool:
	return position != UNPLACED


func get_effective_atk() -> int:
	# The only place combat/ability math reads ATK.
	return data.atk + atk_bonus + _sum_status("temp_atk")


func get_effective_move() -> int:
	# Unmounted movement only; a mounted pair uses the Mount's MOVE (MountSystem).
	# Floored at 0: stacked slows can push the raw sum negative.
	return maxi(0, data.move + move_bonus + _sum_status("temp_move"))


func get_effective_range(_context: String) -> int:
	# _context: "attack" | "ability". Not yet read: the context-specific conditional
	# bonuses (AbilitySystem) and MatchState's global modifier (relic/event deck) join
	# this sum when those modules land. Floored at 1 (Whiteout's "minimum 1").
	return maxi(1, data.range + range_bonus + _sum_status("temp_range"))


func has_status(type: String) -> bool:
	return status_effects.any(func(se: StatusEffect) -> bool: return se.type == type)


func _sum_status(type: String) -> int:
	var total := 0
	for se in status_effects:
		if se.type == type:
			total += se.value
	return total
