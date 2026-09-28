class_name RelicEventHandler
extends RefCounted
# One subclass per relic/event card (LLD-relic-event-deck.md 3.1). Every hook defaults
# to "no effect". `sys` is the match's AbilitySystem (board, state, helpers); `owner_id`
# is the player whose relic slot holds this card, or who drew this event.

# --- Relics: queried live while in the owner's slot -------------------------------------

func get_max_hp_bonus(_sys, _owner_id: String, _target: CharacterInstance) -> int:
	return 0


# Extra damage prevented by the defender's shields (only when it has a shield).
func get_shield_bonus(_sys, _owner_id: String, _defender: CharacterInstance) -> int:
	return 0


func get_range_bonus(_sys, _owner_id: String, _instance: CharacterInstance, _context: String) -> int:
	return 0


func get_atk_bonus(_sys, _owner_id: String, _instance: CharacterInstance) -> int:
	return 0


func get_move_bonus(_sys, _owner_id: String, _instance: CharacterInstance) -> int:
	return 0


# At each of the owner's turn starts while the relic is active (and when it's gained).
func on_owner_turn_started(_sys, _owner_id: String) -> void:
	pass


# --- Relic powers: the player triggers them with the "use_relic" action ---------------

func power_available(_sys, _owner_id: String) -> bool:
	return false


# Same shape as choice_spec: what the player picks to use the power.
func power_spec(_sys, _owner_id: String) -> Dictionary:
	return {}


# May return {"pending": {...}} to follow up with a deck_choice (e.g. top or bottom).
func use_power(_sys, _owner_id: String, _payload: Dictionary) -> Dictionary:
	return {"success": false, "reason": "no relic power"}


# --- Game events, forwarded to active relics and running events ---------------------

func on_attack_resolved(_sys, _owner_id: String, _attacker_id: String, _target_id: String,
		_damage: int, _defeated: bool) -> void:
	pass


func on_object_attacked(_sys, _owner_id: String, _attacker_id: String, _pos: Vector2i,
		_damage: int, _destroyed: bool) -> void:
	pass


func on_character_moved(_sys, _owner_id: String, _character_id: String, _from: Vector2i, _to: Vector2i) -> void:
	pass


func on_memory_gained(_sys, _owner_id: String, _character_id: String) -> void:
	pass


func on_leak_triggered(_sys, _owner_id: String, _character_id: String, _pos: Vector2i) -> void:
	pass


# --- Events ----------------------------------------------------------------------------

# Immediate events. Return {"needs_choice": true} to wait for a deck_choice.
func resolve_immediate(_sys, _player_id: String) -> Dictionary:
	return {}


# Duration events, when drawn. The returned data is kept for on_expire (and readable via
# RelicEventDeck.active_data); include "needs_choice": true to ask the player first.
func on_activate(_sys, _player_id: String) -> Dictionary:
	return {}


func on_expire(_sys, _player_id: String, _data: Dictionary) -> void:
	pass


# What a pending choice asks for: {prompt, pick: "option"|"tiles"|"character"|
# "character_tile", options: [{label, payload}], tiles, count, characters, ...}.
func choice_spec(_sys, _player_id: String, _pending: Dictionary) -> Dictionary:
	return {"prompt": "", "pick": "option", "options": []}


func resolve_choice(_sys, _player_id: String, _payload: Dictionary) -> Dictionary:
	return {"success": false, "reason": "nothing to choose"}


# --- Shared helpers for handlers ---------------------------------------------------------

static func tiles_near_center(sys, reach: int, allow: Callable) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			var pos := Vector2i(x, y)
			if sys.distance(pos, BoardModel.CENTER_TILE) <= reach and allow.call(pos):
				result.append(pos)
	return result


static func ids(characters: Array) -> Array[String]:
	var result: Array[String] = []
	for c in characters:
		result.append(c.instance_id)
	return result


static func own_live(sys, player_id: String) -> Array[CharacterInstance]:
	var result: Array[CharacterInstance] = []
	for c in sys.live_characters():
		if c.player_id == player_id:
			result.append(c)
	return result
