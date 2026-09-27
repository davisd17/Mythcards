class_name PlayerState
extends RefCounted

var id: String = ""                  # "p1" | "p2"
var culture: String = ""             # e.g. "Russian-inspired"
var characters: Array[CharacterInstance] = []  # exactly 7 once setup completes (BR-005)
var active_relic_id: String = ""     # mutated only by RelicEventDeck (BR-029)
var pool_ap_remaining: int = 0
var pool_ap_max: int = 0             # 2 on the match's first turn only, otherwise 4 (BR-018)
var player_flags_this_turn: Dictionary = {}  # player-wide relic/event bonuses; cleared each turn start


func find_character(instance_id: String) -> CharacterInstance:
	for c in characters:
		if c.instance_id == instance_id:
			return c
	return null
