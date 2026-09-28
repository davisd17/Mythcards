class_name CombatResolver
extends RefCounted
# Damage (marks, reduction, shields, lethal interception), pushes, and defeat
# (LLD-combat-mount.md 3.1, 4.1–4.3). Callers have already validated range, line of
# sight, and targeting; this class applies the result.

var board: BoardModel
var ability_system: AbilitySystem
var mount_system: MountSystem
# How the last basic attack's damage came out, for the screen to explain it (playtest
# 2026-09-28): {atk, reduced, reduced_by: [names], shielded, memory}.
var last_attack_breakdown: Dictionary = {}
var _last_breakdown: Dictionary = {}


func _init(p_board: BoardModel, p_ability_system: AbilitySystem = null, p_mount_system: MountSystem = null) -> void:
	board = p_board
	ability_system = p_ability_system if p_ability_system != null else AbilitySystem.new(p_board)
	mount_system = p_mount_system if p_mount_system != null else MountSystem.new(p_board)


func resolve_attack(attacker: CharacterInstance, defender: CharacterInstance) -> Dictionary:
	# A basic attack. "Ranged" means the two are more than 1 tile apart right now,
	# regardless of printed RANGE (BR-011B).
	var base_amount := attacker.get_effective_atk() + ability_system.get_conditional_atk_bonus(attacker)
	var is_ranged := _distance(attacker.position, defender.position) > 1
	var result := apply_damage(attacker, defender, base_amount, is_ranged)
	# Kept before attack_resolved, whose reactions (Resonant Bastion) may deal damage too.
	last_attack_breakdown = _last_breakdown
	EventBus.attack_resolved.emit(attacker.instance_id, defender.instance_id, result.damage, result.defeated)
	return result


func resolve_object_attack(attacker: CharacterInstance, pos: Vector2i) -> Dictionary:
	# A basic attack on a placed object (designer ruling 2026-09-27: attacks may target
	# objects unless a card says otherwise). Objects have no shields or reduction; at
	# 0 HP the object is removed, which also clears the movement/LOS block.
	var obj := board.get_placed_object(pos)
	var damage := attacker.get_effective_atk() + ability_system.get_conditional_atk_bonus(attacker)
	obj.current_hp = maxi(0, obj.current_hp - damage)
	var destroyed := obj.current_hp == 0
	var object_type := obj.type_id
	if destroyed:
		board.remove_object(pos)
	EventBus.object_attacked.emit(attacker.instance_id, pos, object_type, damage, destroyed)
	return {"damage": damage, "destroyed": destroyed}


func apply_damage(attacker: CharacterInstance, defender: CharacterInstance, base_amount: int,
		is_ranged: bool) -> Dictionary:
	# Shared by basic attacks and damaging abilities, so the pipeline exists once.
	# Does not emit attack_resolved; the calling ability signals its own effect.
	var used_marks := _marks_benefiting(defender, attacker)
	var marked_amount := base_amount
	for se in used_marks:
		marked_amount += se.value

	var penetration := ability_system.get_penetration(attacker)
	var reduction := maxi(0, ability_system.get_passive_damage_reduction(defender, attacker, is_ranged)
			- int(penetration.get("ignore_reduction", 0)))
	var after_reduction := maxi(0, marked_amount - reduction)

	var shield_entries := 0
	for se in defender.status_effects:
		if se.type == "shield":
			shield_entries += se.value
	# Quartz Heart Core: a shielded defender's shields prevent 1 more. The extra point is
	# used after the shield itself, so a 1-point shield still breaks against 1 damage.
	var shield_bonus := RelicEventDeck.get_relic_shield_bonus(ability_system, defender) if shield_entries > 0 else 0
	var shield_total := maxi(0, shield_entries + shield_bonus - int(penetration.get("ignore_shield", 0)))
	var shield_consumed := mini(shield_total, after_reduction)
	var final_damage := after_reduction - shield_consumed
	# Memory (designer ruling 2026-09-27): spent automatically to prevent 1 damage, after shields.
	var memory_spent := final_damage > 0 and defender.has_status("memory")
	if memory_spent:
		final_damage -= 1

	# Marks are single use; shields drain newest-first (designer ruling 2026-09-25).
	for se in used_marks:
		defender.status_effects.erase(se)
	_consume_shields(defender, mini(shield_entries, shield_consumed))
	if memory_spent:
		ability_system.remove_status(defender, "memory")

	var would_be_hp := defender.current_hp - final_damage
	if would_be_hp <= 0:
		var intercept := ability_system.intercept_lethal_damage(defender, self)
		if intercept.get("triggered", false):
			defender.current_hp = int(intercept.get("final_hp", 1))
		else:
			defender.current_hp = 0
	else:
		defender.current_hp = would_be_hp

	var reduced_by: Array[String] = []
	if marked_amount > after_reduction:
		reduced_by = ability_system.damage_reduction_sources(defender, attacker, is_ranged)
	_last_breakdown = {"atk": marked_amount, "reduced": marked_amount - after_reduction, "reduced_by": reduced_by,
			"shielded": shield_consumed, "memory": memory_spent}

	var defeated := defender.current_hp <= 0
	if defeated:
		_handle_defeat(defender, attacker)
	return {"damage": final_damage, "defeated": defeated}


func apply_push(target: CharacterInstance, from_position: Vector2i, distance: int) -> Vector2i:
	# Moves target directly away from from_position, stopping at the first obstruction.
	# A partial or zero push is valid ("if possible"). Emits character_repositioned only
	# (so leveling sees the arrival); the pushing ability signals its own effect.
	if target.has_status("no_push"):
		return target.position
	var delta := target.position - from_position
	if delta == Vector2i.ZERO or (delta.x != 0 and delta.y != 0):
		push_error("CombatResolver.apply_push: %s is not in an orthogonal line from %s" % [target.position, from_position])
		return target.position
	var direction := Vector2i(signi(delta.x), signi(delta.y))
	var cursor := target.position
	for _step in distance:
		var next := cursor + direction
		if not board.is_in_bounds(next) or board.is_blocked_for_movement(next):
			break
		cursor = next
	if cursor != target.position:
		var from := target.position
		board.clear_occupant(from)
		board.set_occupant(cursor, target.instance_id)
		target.position = cursor
		if target.is_mounted_rider:
			var mount_char := _find(target.mounted_with_id)
			if mount_char != null:
				mount_char.position = cursor
		EventBus.character_repositioned.emit(target.instance_id, from, cursor, "push")
	return cursor


func apply_hazard_damage(target: CharacterInstance, amount: int) -> Dictionary:
	# Damage from the board or a card rather than a character (Leak, Reactor Prayer). It
	# still runs the normal pipeline (shields, Memory, Last Oath). With no attacker, a
	# defeat is credited to the target itself, so no enemy gains a Spirit Ember from it.
	return apply_damage(target, target, amount, false)


func apply_pull(target: CharacterInstance, toward: Vector2i, distance: int) -> Vector2i:
	# Moves target toward `toward` along their shared line, stopping before any
	# obstruction (Psychic Undertow). "Can't be pushed, pulled, or displaced" (no_push)
	# blocks it too. Emits character_repositioned only.
	if target.has_status("no_push"):
		return target.position
	var delta := toward - target.position
	if delta == Vector2i.ZERO or (delta.x != 0 and delta.y != 0):
		push_error("CombatResolver.apply_pull: %s is not in an orthogonal line with %s" % [target.position, toward])
		return target.position
	var direction := Vector2i(signi(delta.x), signi(delta.y))
	var cursor := target.position
	for _step in distance:
		var next := cursor + direction
		if next == toward or not board.is_in_bounds(next) or board.is_blocked_for_movement(next):
			break
		cursor = next
	if cursor != target.position:
		var from := target.position
		board.clear_occupant(from)
		board.set_occupant(cursor, target.instance_id)
		target.position = cursor
		if target.is_mounted_rider:
			var mount_char := _find(target.mounted_with_id)
			if mount_char != null:
				mount_char.position = cursor
		EventBus.character_repositioned.emit(target.instance_id, from, cursor, "pull")
	return cursor


func _handle_defeat(defender: CharacterInstance, attacker: CharacterInstance) -> void:
	board.clear_occupant(defender.position)
	defender.defeated = true
	var was_rider := defender.is_mounted_rider
	EventBus.character_defeated.emit(defender.instance_id, attacker.instance_id, "direct")
	if was_rider:
		# BR-016: the Mount falls with its rider, and is its own defeat (a second Spirit Ember).
		var mount_char := mount_system.handle_rider_defeated(defender)
		if mount_char != null:
			EventBus.character_defeated.emit(mount_char.instance_id, attacker.instance_id, "mount_propagation")


func _marks_benefiting(defender: CharacterInstance, attacker: CharacterInstance) -> Array[StatusEffect]:
	# A mark helps only the marking character's own side. A mark with no source (applied
	# by an event rather than a character) helps any attacker.
	var result: Array[StatusEffect] = []
	for se in defender.status_effects:
		if se.type != "marked":
			continue
		var source := _find(se.source_character_id)
		if se.source_character_id == "" or (source != null and source.player_id == attacker.player_id):
			result.append(se)
	return result


static func _consume_shields(defender: CharacterInstance, amount: int) -> void:
	var remaining := amount
	for i in range(defender.status_effects.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var se := defender.status_effects[i]
		if se.type != "shield":
			continue
		var used := mini(se.value, remaining)
		se.value -= used
		remaining -= used
		if se.value <= 0:
			defender.status_effects.remove_at(i)


static func _distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


static func _find(instance_id: String) -> CharacterInstance:
	if instance_id == "" or GameState.match_state == null:
		return null
	return GameState.match_state.find_character(instance_id)
