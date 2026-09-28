extends AbilityHandler
# Gymnast (Common) — Vault / Aurora Acrobat (LLD-ability-system 5.1).
# L1 Vault: may pass through 1 allied character while moving.
# L2: +1 MOVE; Vault may pass any one occupied tile; after vaulting, 1 extra tile.
# L3 Aurora Acrobat: +1 ATK, +1 MOVE; once per turn after vaulting, a free 1-damage
#    attack on an adjacent enemy (offered as the "aurora_acrobat" reactive bonus).

const VAULT_PASSES := 1
const AURORA_ACROBAT_DAMAGE := 1


func level_bonuses() -> Dictionary:
	return {2: {"move": 1}, 3: {"atk": 1, "move": 1}}


func get_movement_passable_predicate(sys, instance: CharacterInstance) -> Callable:
	var any_occupant := instance.level >= 2
	var player_id := instance.player_id
	return func(pos: Vector2i) -> bool:
		var c: CharacterInstance = sys.occupant(pos)
		return c != null and (any_occupant or c.player_id == player_id)


func get_movement_max_passes(_sys, _instance: CharacterInstance) -> int:
	return VAULT_PASSES


func get_bonus_move_tiles(sys, instance: CharacterInstance, from: Vector2i, budget: int) -> Array[Vector2i]:
	# L2 "after Vaulting, may move 1 extra tile": a tile one step past the normal budget,
	# reachable only by a path that vaults (LLD 5.1's recommended approach).
	var result: Array[Vector2i] = []
	if instance.level < 2:
		return result
	var vault := get_movement_passable_predicate(sys, instance)
	var normal: Array[Vector2i] = sys.board.get_legal_moves(from, budget, "orthogonal", vault, Callable(), VAULT_PASSES)
	var plain: Array[Vector2i] = sys.board.get_legal_moves(from, budget + 1)
	for pos in sys.board.get_legal_moves(from, budget + 1, "orthogonal", vault, Callable(), VAULT_PASSES):
		if not normal.has(pos) and not plain.has(pos):
			result.append(pos)
	return result


func on_character_moved(sys, instance: CharacterInstance, mover: CharacterInstance,
		_from: Vector2i, _to: Vector2i, required_pass: bool) -> void:
	if mover != instance or instance.level < 3 or not required_pass:
		return
	if not sys.used_this_turn(instance, "aurora_acrobat_used"):
		sys.offer_bonus(instance, "aurora_acrobat")


func execute_reactive_bonus(sys, instance: CharacterInstance, tag: String, payload: Dictionary) -> Dictionary:
	if tag != "aurora_acrobat":
		return super(sys, instance, tag, payload)
	var target: CharacterInstance = sys.find(str(payload.get("target_id", "")))
	if target == null or target.player_id == instance.player_id or not sys.is_adjacent(instance.position, target.position):
		return {"success": false, "reason": "needs an adjacent enemy"}
	sys.consume_bonus(instance, "aurora_acrobat")
	instance.ability_uses_this_turn["aurora_acrobat_used"] = true
	# The card calls it an attack, so it reports as one (reflects and "next attack" buffs apply).
	var result: Dictionary = sys.combat().apply_damage(instance, target, AURORA_ACROBAT_DAMAGE, false)
	EventBus.attack_resolved.emit(instance.instance_id, target.instance_id, result.damage, result.defeated)
	return {"success": true, "damage": result.damage, "defeated": result.defeated}


func bonus_label(tag: String) -> String:
	return "Aurora Acrobat strike" if tag == "aurora_acrobat" else super(tag)


func bonus_step(sys, instance: CharacterInstance, tag: String, payload: Dictionary) -> Dictionary:
	if tag != "aurora_acrobat" or payload.has("target_id"):
		return {}
	var enemies: Array[String] = []
	for enemy in sys.enemies_of(instance):
		if sys.is_adjacent(enemy.position, instance.position):
			enemies.append(enemy.instance_id)
	return target_step("target_id", "Deal 1 damage to which adjacent enemy?", enemies)
