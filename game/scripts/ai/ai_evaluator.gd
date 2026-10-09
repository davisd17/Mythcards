class_name AIEvaluator
extends RefCounted
# Scores candidate actions for the basic AI (LLD-ai-opponent.md 4). Each score is in
# "points"; the weights come from an AIPersonality. Cards can add their own estimate
# through AbilityHandler.ai_value / RelicEventHandler.ai_choice_value, using the helpers
# here (value_of, danger, preview).
#
# Phase 1 judges each action by its direct effect, without simulating the rest of the
# turn. The capture rule is guarded by probing the board: a candidate move is applied to
# the occupancy grid, the Hero's legal moves are counted, and the grid is restored.

const VETO := -1000.0

var personality: AIPersonality
var player_id: String


func _init(p_personality: AIPersonality, p_player_id: String) -> void:
	personality = p_personality
	player_id = p_player_id


# {score, why}. Anything that would leave our Hero with no way to move is vetoed.
func score(candidate: Dictionary) -> Dictionary:
	if ["ability", "deck_choice", "bonus"].has(candidate.kind) and _would_wall_in_our_hero(candidate.payload):
		return _result(VETO, "would wall in our Hero")
	return _score(candidate)


func _score(candidate: Dictionary) -> Dictionary:
	var sys: AbilitySystem = RulesEngine.systems().ability
	var actor := _find(candidate.actor_id)
	var payload: Dictionary = candidate.payload
	match candidate.kind:
		"move":
			return _score_move(actor, payload.to, "move")
		"attack":
			return _score_attack(actor, _find(str(payload.target_id)))
		"attack_object":
			var obj: PlacedObjectInstance = sys.board.get_placed_object(payload.target_pos)
			var destroys: bool = obj != null and obj.current_hp <= actor.get_effective_atk()
			return _result(personality.w("object_attack") * (2.0 if destroys else 1.0), "break a %s" % (obj.type_id if obj else "object"))
		"ability":
			var v: float = sys.handler_for(actor).ai_value(sys, actor, str(payload.ability_id), payload, self)
			return _result(v, "%s" % sys.ability_label(actor, str(payload.ability_id)))
		"bonus":
			if payload.tag == "free_move":
				var m := _score_move(actor, payload.to, "free move")
				m.score += 0.05   # free: no AP
				return m
			var v: float = sys.handler_for(actor).ai_value(sys, actor, "bonus:" + str(payload.tag), payload, self)
			return _result(maxf(v, 0.2), "free %s" % payload.tag)
		"return":
			return _result(10.0 + _tile_value(actor, payload.to), "return to the board")
		"mount":
			return _result(personality.w("mount") if actor.data.type == "Hero" else personality.w("mount") * 0.5, "mount")
		"dismount":
			return _result(-0.3, "dismount")
		"relic_power":
			return _result(personality.w("relic_power"), "relic power")
		"deck_choice":
			var handler: RelicEventHandler = RelicEventDeck._handler(str(RelicEventDeck.get_pending_choice(player_id).get("card_id", "")))
			return _result(10.0 + handler.ai_choice_value(sys, player_id, payload, self), "answer the drawn card")
	return _result(0.0, "?")


# --- Helpers cards use in ai_value -------------------------------------------------------

func value_of(c: CharacterInstance) -> float:
	return personality.value_of(c)


# How many enemies could attack `pos` next turn (a move plus their RANGE, by distance).
func danger(c: CharacterInstance, pos: Vector2i) -> int:
	var count := 0
	for e in _enemies_of(c.player_id):
		var reach := e.get_effective_move() + e.get_effective_range("attack")
		if AbilitySystem.distance(e.position, pos) <= reach:
			count += 1
	return count


# Damage an attack or a damaging ability of `amount` would deal now.
func preview(attacker: CharacterInstance, target: CharacterInstance, amount: int) -> int:
	return RulesEngine.systems().combat.preview_damage(attacker, target, amount,
			AbilitySystem.distance(attacker.position, target.position) > 1)


# The value of dealing `damage` to `target`: damage points, plus a defeat bonus.
func damage_value(attacker: CharacterInstance, target: CharacterInstance, damage: int) -> float:
	var v := personality.w("damage") * damage
	if damage >= target.current_hp:
		v += personality.w("defeat") * value_of(target)
		if attacker.level == 2:
			v += personality.w("ember_at_level_2")
	return v


func enemies_near(pos: Vector2i, reach: int) -> int:
	var count := 0
	for e in _enemies_of(player_id):
		if AbilitySystem.distance(e.position, pos) <= reach:
			count += 1
	return count


# --- Scoring --------------------------------------------------------------------------------

func _score_attack(attacker: CharacterInstance, target: CharacterInstance) -> Dictionary:
	var dmg: int = RulesEngine.systems().combat.preview_attack(attacker, target)
	return _result(damage_value(attacker, target, dmg), "attack %s for %d" % [target.data.char_name, dmg])


func _score_move(mover: CharacterInstance, to: Vector2i, label: String) -> Dictionary:
	var from := mover.position
	var gain := _tile_value(mover, to) - _tile_value(mover, from)
	var safety := _probe_move(mover, to)
	if safety.own_hero_trapped:
		return _result(VETO, "would trap our Hero")
	gain -= personality.w("hero_cramped") * maxf(0.0, 2.0 - safety.own_hero_moves) * 0.5
	gain += personality.w("trap_enemy_hero") * (safety.enemy_hero_before - safety.enemy_hero_after) * 0.5
	return _result(gain, "%s %s" % [label, MatchLog._steps(from, to)])


# How good a tile is for this character: in range of a target, not too exposed, and on
# the way to levelling.
func _tile_value(c: CharacterInstance, pos: Vector2i) -> float:
	var v := 0.0
	var enemies := _enemies_of(c.player_id)
	var best := 99
	for e in enemies:
		var d := AbilitySystem.distance(pos, e.position)
		var lined: bool = pos.x == e.position.x or pos.y == e.position.y
		if lined and d <= c.get_effective_range("attack"):
			v += personality.w("in_range") * (1.0 + 0.1 * (value_of(e) - e.current_hp * 0.2))
			best = 0
			break
		best = mini(best, maxi(0, d - c.get_effective_range("attack")))
	var boldness := _boldness()
	if best > 0 and best < 99:
		v -= personality.w("approach") * best * (2.0 - boldness)
	# Fragile, valuable pieces fear danger more, but capped: an uncapped ratio made two
	# 2-HP Heroes refuse to engage forever (AI vs AI, seed 2).
	var fragility := clampf(value_of(c) / maxf(1.0, float(c.current_hp)), 0.5, 2.0)
	v -= personality.w("danger") * danger(c, pos) * fragility * 0.5 * boldness
	var sys: AbilitySystem = RulesEngine.systems().ability
	if c.level == 1 and pos.y == _opponent_edge(c.player_id):
		v += personality.w("level_2")
	if c.level == 2 and c.spirit_ember_count > 0 and pos == BoardModel.CENTER_TILE:
		v += personality.w("level_3")
	if sys.has_leak(pos) and not sys.handler_for(c).ignores_leaks(sys, c):
		v -= personality.w("leak_tile")
	return v


# Moves `mover` on the occupancy grid only, counts both Heroes' legal moves, restores.
func _probe_move(mover: CharacterInstance, to: Vector2i) -> Dictionary:
	var board := GameState.match_state.board
	var own_hero := _hero(player_id)
	var enemy_hero := _hero(_other(player_id))
	var enemy_before := _moves(enemy_hero)
	var from := mover.position
	var partner: CharacterInstance = _find(mover.mounted_with_id) if mover.is_mounted_rider else null
	board.clear_occupant(from)
	board.set_occupant(to, mover.instance_id)
	mover.position = to
	if partner != null:
		partner.position = to
	var own_moves := _moves(own_hero)
	var enemy_after := _moves(enemy_hero)
	board.clear_occupant(to)
	board.set_occupant(from, mover.instance_id)
	mover.position = from
	if partner != null:
		partner.position = from
	return {"own_hero_trapped": own_hero != null and own_moves == 0, "own_hero_moves": own_moves,
			"enemy_hero_before": enemy_before, "enemy_hero_after": enemy_after}


# Places a temporary blocking object on every tile the payload names and recounts our
# Hero's moves (conservative: a Leak, which doesn't block, is probed as if it did).
func _would_wall_in_our_hero(payload: Dictionary) -> bool:
	var hero := _hero(player_id)
	if hero == null or not hero.is_placed() or _moves(hero) == 0:
		return false
	var board := GameState.match_state.board
	var tiles: Array[Vector2i] = []
	for value in [payload.get("target"), payload.get("target_2"), payload.get("leak"), payload.get("to")] + Array(payload.get("tiles", [])):
		var free_tile: bool = value is Vector2i and board.is_in_bounds(value) \
				and board.get_placed_object(value) == null and not board.is_occupied_by_character(value)
		if free_tile:
			tiles.append(value)
	if tiles.is_empty():
		return false
	for pos in tiles:
		board.place_object(pos, "stone", "")
	var trapped := _moves(hero) == 0
	for pos in tiles:
		board.remove_object(pos)
	return trapped


# 1.0 early; falls toward 0.3 as a match drags on, so cautious play turns to pressure and
# stalemates break (turns past personality "patience", default 20).
func _boldness() -> float:
	var patience := personality.w("patience", 20.0)
	var turn := float(GameState.match_state.turn_number)
	return clampf(1.0 - (turn - patience) / 30.0, 0.3, 1.0)


func allies_near(pos: Vector2i, reach: int) -> int:
	var count := 0
	for c in GameState.match_state.get_player(player_id).characters:
		if not c.defeated and c.is_placed() and AbilitySystem.distance(c.position, pos) <= reach:
			count += 1
	return count


func own_hero_moves() -> int:
	return _moves(_hero(player_id))


static func _moves(hero: CharacterInstance) -> int:
	if hero == null or hero.defeated or not hero.is_placed():
		return 99
	return RulesEngine.get_legal_move_tiles(hero.instance_id).size()


func _hero(pid: String) -> CharacterInstance:
	for c in GameState.match_state.get_player(pid).characters:
		if c.data.type == "Hero" and not c.defeated:
			return c
	return null


func _enemies_of(pid: String) -> Array[CharacterInstance]:
	var result: Array[CharacterInstance] = []
	for c in GameState.match_state.get_player(_other(pid)).characters:
		if not c.defeated and c.is_placed() and not (c.mounted_with_id != "" and not c.is_mounted_rider):
			result.append(c)
	return result


static func _other(pid: String) -> String:
	return "p2" if pid == "p1" else "p1"


static func _opponent_edge(pid: String) -> int:
	return BoardModel.PLAYER_B_EDGE_ROW if pid == "p1" else BoardModel.PLAYER_A_EDGE_ROW


func _find(id: String) -> CharacterInstance:
	return GameState.match_state.find_character(id) if id != "" else null


static func _result(points: float, why: String) -> Dictionary:
	return {"score": points, "why": why}
