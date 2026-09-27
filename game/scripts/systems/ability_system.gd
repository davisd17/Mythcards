class_name AbilitySystem
extends RefCounted
# Dispatches every ability question and event to the character's handler
# (LLD-ability-system.md 3.3), aggregates own + ally-aura bonuses (LLD 4.1), and offers
# the helpers handlers share. The signatures RulesEngine/CombatResolver/MountSystem call
# are the contract in LLD-rules-engine Section 9.
#
# Listens to EventBus synchronously and only for the match it was built for (ids repeat
# across matches; see LLD-leveling 9A).

const ADJACENT_AURA_RANGE := 1

var board: BoardModel
var _match: MatchState
var _combat_ref: WeakRef = null   # weak: CombatResolver also holds this system
var _handlers: Dictionary = {}    # character id -> AbilityHandler


func _init(p_board: BoardModel) -> void:
	board = p_board
	_match = GameState.match_state
	EventBus.character_moved.connect(_on_character_moved)
	EventBus.character_repositioned.connect(_on_character_repositioned)
	EventBus.attack_resolved.connect(_on_attack_resolved)
	EventBus.character_defeated.connect(_on_character_defeated)
	EventBus.spirit_ember_delivered.connect(_on_spirit_ember_delivered)
	EventBus.turn_started.connect(_on_turn_started)


func set_combat(combat: CombatResolver) -> void:
	_combat_ref = weakref(combat)


func combat() -> CombatResolver:
	return _combat_ref.get_ref() if _combat_ref != null else null


func handler_for(instance: CharacterInstance) -> AbilityHandler:
	var id := instance.data.id
	if not _handlers.has(id):
		_handlers[id] = AbilityRegistry.get_handler(id)
	return _handlers[id]


# --- Movement queries (RulesEngine, MountSystem) ---------------------------------

func get_movement_pattern(_instance: CharacterInstance) -> String:
	return "orthogonal"


func get_movement_passable_predicate(instance: CharacterInstance) -> Callable:
	return handler_for(instance).get_movement_passable_predicate(self, instance)


func get_movement_object_passable_predicate(instance: CharacterInstance) -> Callable:
	return handler_for(instance).get_movement_object_passable_predicate(self, instance)


func get_movement_max_passes(instance: CharacterInstance) -> int:
	return handler_for(instance).get_movement_max_passes(self, instance)


func get_bonus_move_tiles(instance: CharacterInstance, from: Vector2i, budget: int) -> Array[Vector2i]:
	return handler_for(instance).get_bonus_move_tiles(self, instance, from, budget)


# --- Attack queries (RulesEngine, CombatResolver) --------------------------------

func get_attack_pattern(_instance: CharacterInstance) -> String:
	return "orthogonal_line"


func get_line_of_sight_exceptions(instance: CharacterInstance, target_pos: Vector2i,
		_board: BoardModel = null) -> Array[String]:
	var ids := handler_for(instance).get_line_of_sight_exceptions(self, instance, target_pos)
	# Granted by another character (Link Mind): ignore one ally on the line.
	if instance.has_status("los_ignore_ally_granted"):
		var ally := first_ally_on_line(instance, instance.position, target_pos)
		if ally != "" and not ids.has(ally):
			ids.append(ally)
	return ids


func get_penetration(instance: CharacterInstance) -> Dictionary:
	return handler_for(instance).get_penetration(self, instance)


func get_conditional_atk_bonus(instance: CharacterInstance) -> int:
	return handler_for(instance).get_conditional_atk_bonus(self, instance)


func get_conditional_range_bonus(instance: CharacterInstance, context: String) -> int:
	var parts := _range_parts(instance, context)
	var bonus: int = parts.bonus
	# Link Mind: use the Conductor's RANGE for abilities if it is longer.
	if parts.override > 0:
		var own := instance.get_effective_range(context, bonus)
		bonus += maxi(0, parts.override - own)
	return bonus


func get_passive_damage_reduction(defender: CharacterInstance, attacker: CharacterInstance,
		is_ranged: bool) -> int:
	var total := handler_for(defender).get_own_damage_reduction(self, defender, attacker, is_ranged)
	for source in allies_of(defender):
		total += handler_for(source).get_aura_damage_reduction(self, source, defender, attacker, is_ranged)
	return total


func intercept_lethal_damage(defender: CharacterInstance, combat_resolver: CombatResolver) -> Dictionary:
	return handler_for(defender).intercept_lethal_damage(self, defender, combat_resolver)


func get_effective_max_hp(instance: CharacterInstance) -> int:
	return instance.base_max_hp + int(instance.ability_uses_this_match.get("_hp_bonus_applied", 0))


# --- Activated abilities (RulesEngine) --------------------------------------------

func can_use_ability(instance: CharacterInstance, ability_id: String) -> bool:
	var handler := handler_for(instance)
	return handler.ability_ids(instance).has(ability_id) and handler.can_use(self, instance, ability_id)


func get_legal_ability_targets(instance: CharacterInstance, ability_id: String) -> Array:
	return handler_for(instance).get_legal_targets(self, instance, ability_id)


func validate_ability(instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	return handler_for(instance).validate(self, instance, ability_id, payload)


func execute_ability(instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	return handler_for(instance).execute(self, instance, ability_id, payload)


func execute_reactive_bonus(instance: CharacterInstance, tag: String, payload: Dictionary) -> Dictionary:
	if tag == "free_move":
		return _free_move(instance, payload)
	return handler_for(instance).execute_reactive_bonus(self, instance, tag, payload)


# --- Level-up (LevelingSystem) -----------------------------------------------------

func apply_level_up_effects(instance: CharacterInstance, new_level: int) -> void:
	var bonus: Dictionary = handler_for(instance).level_bonuses().get(new_level, {})
	var hp := int(bonus.get("hp", 0))
	instance.base_max_hp += hp
	instance.current_hp += hp   # a level-up that raises max HP also heals by that much
	instance.atk_bonus += int(bonus.get("atk", 0))
	instance.move_bonus += int(bonus.get("move", 0))
	instance.range_bonus += int(bonus.get("range", 0))
	handler_for(instance).on_level_up(self, instance, new_level)
	sync_conditional_hp(instance)


# --- Helpers for handlers -----------------------------------------------------------

func state() -> MatchState:
	return _match


func find(instance_id: String) -> CharacterInstance:
	var c := _match.find_character(instance_id) if _match != null else null
	return c if c != null and not c.defeated else null


func live_characters() -> Array[CharacterInstance]:
	var result: Array[CharacterInstance] = []
	for p in _match.players:
		for c in p.characters:
			if not c.defeated and c.is_placed():
				result.append(c)
	return result


# Live teammates, excluding the character itself.
func allies_of(instance: CharacterInstance) -> Array[CharacterInstance]:
	var result: Array[CharacterInstance] = []
	for c in live_characters():
		if c.player_id == instance.player_id and c.instance_id != instance.instance_id:
			result.append(c)
	return result


func enemies_of(instance: CharacterInstance) -> Array[CharacterInstance]:
	var result: Array[CharacterInstance] = []
	for c in live_characters():
		if c.player_id != instance.player_id:
			result.append(c)
	return result


func occupant(pos: Vector2i) -> CharacterInstance:
	var tile := board.get_tile(pos)
	return find(tile.occupant_id) if tile != null and tile.occupant_id != "" else null


static func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


static func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return distance(a, b) == 1


func neighbors(pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in BoardModel.ORTHOGONAL_DIRECTIONS:
		if board.is_in_bounds(pos + dir):
			result.append(pos + dir)
	return result


func is_empty_tile(pos: Vector2i) -> bool:
	return board.is_in_bounds(pos) and not board.is_occupied_by_character(pos) and board.get_placed_object(pos) == null


# How far `instance` reaches with an ability whose printed reach is `printed`
# ("within 2 tiles"), including level, temporary, and conditional ability-range bonuses,
# and Link Mind's borrowed RANGE.
func ability_reach(instance: CharacterInstance, printed: int) -> int:
	var parts := _range_parts(instance, "ability")
	var reach := printed + instance.range_bonus + instance.sum_status("temp_range") + int(parts.bonus)
	return maxi(maxi(1, reach), int(parts.override))


# Tiles `instance` can target from `origin` in an orthogonal line within `reach`, with
# line of sight (BR-011 applies to ranged ability targeting too).
func tiles_in_reach(instance: CharacterInstance, origin: Vector2i, reach: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pos in board.get_tiles_in_range(origin, reach):
		if board.has_line_of_sight(origin, pos, get_line_of_sight_exceptions(instance, pos)):
			result.append(pos)
	return result


func characters_in_reach(instance: CharacterInstance, origin: Vector2i, reach: int, want_allies: bool) -> Array[String]:
	var result: Array[String] = []
	for pos in tiles_in_reach(instance, origin, reach):
		var c := occupant(pos)
		if c != null and (c.player_id == instance.player_id) == want_allies:
			result.append(c.instance_id)
	return result


# Instance id of the first allied character between `from` and `to` on a line, or "".
func first_ally_on_line(instance: CharacterInstance, from: Vector2i, to: Vector2i) -> String:
	if from == to or (from.x != to.x and from.y != to.y):
		return ""
	var step := Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	var cursor := from + step
	while cursor != to:
		var c := occupant(cursor)
		if c != null:
			return c.instance_id if c.player_id == instance.player_id else ""
		cursor += step
	return ""


func add_status(target: CharacterInstance, type: String, value: int, expires: String,
		source: CharacterInstance = null, consume_on_attack: bool = false) -> StatusEffect:
	var se := StatusEffect.new(type, value, expires, _match.turn_number)
	se.source_character_id = source.instance_id if source != null else ""
	se.consume_on_attack = consume_on_attack
	target.status_effects.append(se)
	return se


func remove_status(target: CharacterInstance, type: String) -> void:
	for i in range(target.status_effects.size() - 1, -1, -1):
		if target.status_effects[i].type == type:
			target.status_effects.remove_at(i)


func heal(target: CharacterInstance, amount: int) -> void:
	target.current_hp = mini(get_effective_max_hp(target), target.current_hp + amount)


# Offers a free follow-up the player may take via the "reactive_bonus" action.
func offer_bonus(instance: CharacterInstance, tag: String) -> void:
	instance.ability_uses_this_turn[tag + "_available"] = true


func consume_bonus(instance: CharacterInstance, tag: String) -> void:
	instance.ability_uses_this_turn.erase(tag + "_available")
	instance.ability_uses_this_match.erase(tag + "_available")


func used_this_turn(instance: CharacterInstance, key: String) -> bool:
	return instance.ability_uses_this_turn.get(key, false)


func used_this_match(instance: CharacterInstance, key: String) -> bool:
	return instance.ability_uses_this_match.get(key, false)


# A move granted by an ability (free move, Aurora Predator): the character's own
# movement, so it emits character_moved and counts as having moved this turn.
func move_character(instance: CharacterInstance, to: Vector2i) -> void:
	var from := instance.position
	board.clear_occupant(from)
	board.set_occupant(to, instance.instance_id)
	instance.position = to
	if instance.is_mounted_rider:
		var mount_char := _match.find_character(instance.mounted_with_id)
		if mount_char != null:
			mount_char.position = to
	instance.ability_uses_this_turn["moved"] = true
	instance.ability_uses_this_turn["last_move_required_pass"] = false
	EventBus.character_moved.emit(instance.instance_id, from, to)


# A position change that isn't the character's own move (Relay Gate teleport).
func reposition_character(instance: CharacterInstance, to: Vector2i, cause: String) -> void:
	var from := instance.position
	board.clear_occupant(from)
	board.set_occupant(to, instance.instance_id)
	instance.position = to
	if instance.is_mounted_rider:
		var mount_char := _match.find_character(instance.mounted_with_id)
		if mount_char != null:
			mount_char.position = to
	EventBus.character_repositioned.emit(instance.instance_id, from, to, cause)


# Legal destinations for a move of `budget` tiles with the character's own movement rules.
func moves_for(instance: CharacterInstance, budget: int) -> Array[Vector2i]:
	return board.get_legal_moves(instance.position, budget, "orthogonal",
			get_movement_passable_predicate(instance), get_movement_object_passable_predicate(instance),
			get_movement_max_passes(instance))


# Pylon-equivalence (LLD 5.8 joint pass, recommended defaults): a tile is a pylon source
# for a player if it holds that player's pylon, or that player's Level 3 Quartz
# Attendant (Collective Node). Own side only; a Collective Node is not an object.
func is_pylon_source(pos: Vector2i, player_id: String) -> bool:
	var obj := board.get_placed_object(pos)
	if obj != null and obj.type_id == "pylon" and obj.owner_player_id == player_id:
		return true
	var c := occupant(pos)
	return c != null and c.player_id == player_id and c.data.id == "a-attendant" and c.level >= 3


func pylon_sources(player_id: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			if is_pylon_source(Vector2i(x, y), player_id):
				result.append(Vector2i(x, y))
	return result


# Stand Firm-style conditional max HP: current HP follows the bonus up and down,
# but losing the bonus never drops a character below 1 HP (LLD 5.5).
func sync_conditional_hp(instance: CharacterInstance) -> void:
	if instance.defeated:
		return
	var bonus := handler_for(instance).get_own_conditional_max_hp_bonus(self, instance)
	var applied := int(instance.ability_uses_this_match.get("_hp_bonus_applied", 0))
	if bonus == applied:
		return
	instance.ability_uses_this_match["_hp_bonus_applied"] = bonus
	var delta := bonus - applied
	instance.current_hp = maxi(1, instance.current_hp + delta) if delta < 0 else instance.current_hp + delta


# --- Event dispatch ----------------------------------------------------------------

func _on_character_moved(character_id: String, from: Vector2i, to: Vector2i) -> void:
	if not _is_current():
		return
	var mover := find(character_id)
	if mover == null:
		return
	var required_pass: bool = mover.ability_uses_this_turn.get("last_move_required_pass", false)
	sync_conditional_hp(mover)
	for c in live_characters():
		if not c.defeated:
			handler_for(c).on_character_moved(self, c, mover, from, to, required_pass)


func _on_character_repositioned(character_id: String, _from: Vector2i, _to: Vector2i, _cause: String) -> void:
	if not _is_current():
		return
	var moved := find(character_id)
	if moved == null:
		return
	sync_conditional_hp(moved)
	for c in live_characters():
		if not c.defeated:
			handler_for(c).on_character_repositioned(self, c, moved)


func _on_attack_resolved(attacker_id: String, target_id: String, damage: int, defeated: bool) -> void:
	if not _is_current():
		return
	var attacker := _match.find_character(attacker_id)
	var target := _match.find_character(target_id)
	if attacker == null or target == null:
		return
	for c in _all_characters():
		if not c.defeated or c == target:
			handler_for(c).on_attack_resolved(self, c, attacker, target, damage, defeated)
	# Single-use attack buffs ("+1 ATK on its next attack") are spent by this attack.
	for i in range(attacker.status_effects.size() - 1, -1, -1):
		if attacker.status_effects[i].consume_on_attack:
			attacker.status_effects.remove_at(i)


func _on_character_defeated(character_id: String, defeated_by_id: String, _cause: String) -> void:
	if not _is_current():
		return
	var fallen := _match.find_character(character_id)
	var by := _match.find_character(defeated_by_id)
	if fallen == null:
		return
	for c in live_characters():
		handler_for(c).on_character_defeated(self, c, fallen, by)


func _on_spirit_ember_delivered(character_id: String) -> void:
	if not _is_current():
		return
	var carrier := find(character_id)
	if carrier == null:
		return
	for c in live_characters():
		handler_for(c).on_spirit_ember_delivered(self, c, carrier)


func _on_turn_started(player_id: String) -> void:
	if not _is_current():
		return
	for c in live_characters():
		handler_for(c).on_turn_started(self, c, player_id)


# --- Internals ------------------------------------------------------------------------

func _free_move(instance: CharacterInstance, payload: Dictionary) -> Dictionary:
	# Command / Astral Echo: move 1 tile without spending AP.
	var to = payload.get("to")
	if not to is Vector2i or not moves_for(instance, 1).has(to):
		return {"success": false, "reason": "illegal move"}
	consume_bonus(instance, "free_move")
	move_character(instance, to)
	return {"success": true}


func _range_parts(instance: CharacterInstance, context: String) -> Dictionary:
	var bonus := handler_for(instance).get_conditional_range_bonus(self, instance, context)
	for source in allies_of(instance):
		bonus += handler_for(source).get_aura_range_bonus(self, source, instance, context)
	var override := 0
	if context == "ability":
		for se in instance.status_effects:
			if se.type == "range_override":
				override = maxi(override, se.value)
	return {"bonus": bonus, "override": override}


func _all_characters() -> Array[CharacterInstance]:
	var result: Array[CharacterInstance] = []
	for p in _match.players:
		result.append_array(p.characters)
	return result


func _is_current() -> bool:
	return _match != null and GameState.match_state == _match
