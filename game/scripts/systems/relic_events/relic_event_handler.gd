class_name RelicEventHandler
extends RefCounted
# One subclass per relic/event card (LLD-relic-event-deck.md 3.1). Every hook defaults
# to "no effect". `sys` is the match's AbilitySystem (board, state, and helpers).

# --- Relics: queried live while the relic sits in its owner's slot ---------------

func get_max_hp_bonus(_sys, _owner_id: String, _target: CharacterInstance) -> int:
	return 0


# Extra damage prevented by the defender's shields (only when it has a shield).
func get_shield_bonus(_sys, _owner_id: String, _defender: CharacterInstance) -> int:
	return 0


func get_range_bonus(_sys, _owner_id: String, _instance: CharacterInstance, _context: String) -> int:
	return 0


# At the start of each of the owner's turns while the relic is active.
func on_owner_turn_started(_sys, _owner_id: String) -> void:
	pass


# --- Events ----------------------------------------------------------------------

# Immediate events. Return {"needs_choice": true, ...} to wait for a deck_choice.
func resolve_immediate(_sys, _player_id: String) -> Dictionary:
	return {}


func resolve_choice(_sys, _player_id: String, _payload: Dictionary) -> Dictionary:
	return {"success": false, "reason": "nothing to choose"}


# Duration events: set up when drawn; the returned data comes back to on_expire.
func on_activate(_sys, _player_id: String) -> Dictionary:
	return {}


func on_expire(_sys, _player_id: String, _data: Dictionary) -> void:
	pass
