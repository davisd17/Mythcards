class_name BoardFx
extends RefCounted
# Phase 2 action feedback (LLD-board-fx.md): short animations started from EventBus
# signals. Every signal fires after the model has changed, so nothing here can delay or
# decide rules; effects only offset, tint, or decorate what GameBoardView already draws.
# Time is this object's own clock, advanced by the view (and by tests) with advance().

const SLIDE := 0.24          # a figure gliding to its new tile
const LUNGE := 0.26          # an attacker winding up, striking at its target, and back
const RECOIL := 0.30         # a struck figure leaning away (Phase 5)
const CAST_TIME := 0.30      # a caster rising as its ability resolves (Phase 5)
const LEVEL_POSE := 0.50     # a figure stretching up on a level-up (Phase 5)
const READY := 0.30          # one figure's turn-start "ready" bob (Phase 5)
const READY_STAGGER := 0.05  # per column, so the bob ripples across the side
const HIT := 0.32            # a struck figure's red flash and shake
const NUMBER := 0.75         # a floating damage number
const RING := 0.40           # shield, cast, and Leak rings
const DEFEAT := 0.50         # a defeated figure sinking and fading
const LEVEL_UP := 0.85
const EMBER := 0.60

const DAMAGE := Color("#ff7a6e")
const BLOCKED := Color("#9fe0f5")
const SHIELD := Color("#7fd6f0")
const CAST := Color("#f1d68a")
const LEAK := Color("#86c46c")
const EMBER_COLOR := Color("#f08a3c")
const LEVEL := Color("#f4cf6a")

var now := 0.0
var slides := {}      # instance id -> {from: Vector2i, to: Vector2i, start: float}
var lunges := {}      # instance id -> {toward: Vector2i, start: float}
var hits := {}        # instance id -> start
var recoils := {}     # instance id -> {away: -1/0/1 (screen x away from the attacker), blocked: bool, start}
var casts := {}       # instance id -> start
var levels := {}      # instance id -> start
var ready := {}       # {player: "p1"/"p2", start}: the side whose turn just started
var ghosts: Array = []    # {character, pos: Vector2i, start: float, away: -1/1 (topple direction)}
var effects: Array = []   # {kind, pos: Vector2i, start, duration, text, color}


func connect_signals() -> void:
	EventBus.character_moved.connect(_on_moved)
	EventBus.character_repositioned.connect(_on_repositioned)
	EventBus.attack_resolved.connect(_on_attack)
	EventBus.damage_resolved.connect(_on_damage)
	EventBus.object_attacked.connect(_on_object_attacked)
	EventBus.status_added.connect(_on_status)
	EventBus.leak_triggered.connect(_on_leak)
	EventBus.character_defeated.connect(_on_defeated)
	EventBus.character_leveled_up.connect(_on_leveled)
	EventBus.spirit_ember_picked_up.connect(_on_ember_picked_up)
	EventBus.spirit_ember_delivered.connect(_on_ember_delivered)
	EventBus.action_resolved.connect(_on_action)
	EventBus.turn_started.connect(_on_turn_started)


func advance(delta: float) -> void:
	now += delta
	for table in [slides, lunges]:
		for id in table.keys():
			if now - table[id].start >= (SLIDE if table == slides else LUNGE):
				table.erase(id)
	for id in hits.keys():
		if now - hits[id] >= HIT:
			hits.erase(id)
	for id in recoils.keys():
		if now - recoils[id].start >= RECOIL:
			recoils.erase(id)
	for pair in [[casts, CAST_TIME], [levels, LEVEL_POSE]]:
		for id in pair[0].keys():
			if now - pair[0][id] >= pair[1]:
				pair[0].erase(id)
	if not ready.is_empty() and now - ready.start >= READY + READY_STAGGER * BoardModel.BOARD_SIZE:
		ready = {}
	ghosts = ghosts.filter(func(g): return now - g.start < DEFEAT)
	effects = effects.filter(func(e): return now - e.start < e.duration)


func active() -> bool:
	return not (slides.is_empty() and lunges.is_empty() and hits.is_empty() and recoils.is_empty()
			and casts.is_empty() and levels.is_empty() and ready.is_empty() and ghosts.is_empty() and effects.is_empty())


func clear() -> void:
	slides.clear()
	lunges.clear()
	hits.clear()
	recoils.clear()
	casts.clear()
	levels.clear()
	ready = {}
	ghosts.clear()
	effects.clear()


# 0..1 progress of something that started at `start` and lasts `duration`.
func progress(start: float, duration: float) -> float:
	return clampf((now - start) / duration, 0.0, 1.0)


static func ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)


# How far a character's drawing is displaced from its tile, in tiles of board space
# (x right, y up, as BoardModel counts rows). A mounted pair answers for either id.
func offset_tiles(c: CharacterInstance) -> Vector2:
	var result := Vector2.ZERO
	for id in [c.instance_id, c.mounted_with_id]:
		if id == "":
			continue
		if slides.has(id):
			var s: Dictionary = slides[id]
			var back := Vector2(s.from - s.to) * (1.0 - ease_out(progress(s.start, SLIDE)))
			result += back
			break
	if lunges.has(c.instance_id):
		var l: Dictionary = lunges[c.instance_id]
		var dir := Vector2(l.toward - c.position)
		if dir.length() > 0.0:
			# Phase 5 wind-up: a small step back, then the strike, then home.
			result += dir.normalized() * lunge_reach(progress(l.start, LUNGE))
	if hits.has(c.instance_id):
		var t := progress(hits[c.instance_id], HIT)
		result.x += 0.035 * sin(t * 38.0) * (1.0 - t)
	return result


# How far toward the target an attacker is, in tiles, at lunge progress u: back 0.05 by
# 30%, forward to 0.16 by 55%, then home (LLD-figure-animation.md 3, row 5).
static func lunge_reach(u: float) -> float:
	if u < 0.3:
		return -0.05 * ease_out(u / 0.3)
	if u < 0.55:
		return lerpf(-0.05, 0.16, (u - 0.3) / 0.25)
	return 0.16 * (1.0 - ease_out((u - 0.55) / 0.45))


# 0..1 strength of the red hit flash on a character.
func hit_strength(id: String) -> float:
	if not hits.has(id):
		return 0.0
	return 1.0 - progress(hits[id], HIT)


# --- Signal handlers --------------------------------------------------------------------------

func _find(id: String) -> CharacterInstance:
	return GameState.match_state.find_character(id) if GameState.match_state != null else null


func _add(kind: String, pos: Vector2i, duration: float, text := "", color := Color.WHITE) -> void:
	effects.append({"kind": kind, "pos": pos, "start": now, "duration": duration, "text": text, "color": color})


func _at(id: String, kind: String, duration: float, text := "", color := Color.WHITE) -> void:
	var c := _find(id)
	if c != null and c.is_placed():
		_add(kind, c.position, duration, text, color)


func _on_moved(id: String, from: Vector2i, to: Vector2i) -> void:
	if from != to:
		slides[id] = {"from": from, "to": to, "start": now}


func _on_repositioned(id: String, from: Vector2i, to: Vector2i, cause: String) -> void:
	if cause == "return" or from == to:
		_add("ring", to, RING, "", CAST)   # back from off the board: it appears, not slides
	else:
		_on_moved(id, from, to)


func _on_attack(attacker_id: String, target_id: String, _damage: int, _defeated: bool) -> void:
	var target := _find(target_id)
	if target != null and target.is_placed():
		lunges[attacker_id] = {"toward": target.position, "start": now}


func _on_damage(attacker_id: String, target_id: String, amount: int, _lines: Array) -> void:
	var target := _find(target_id)
	if target == null or not target.is_placed():
		return
	recoils[target_id] = {"away": _away_from(attacker_id, target.position), "blocked": amount <= 0, "start": now}
	if amount > 0:
		hits[target_id] = now
		_add("number", target.position, NUMBER, "-%d" % amount, DAMAGE)
	else:
		_add("number", target.position, NUMBER, "Blocked", BLOCKED)


func _on_object_attacked(_attacker_id: String, pos: Vector2i, _type: String, damage: int, destroyed: bool) -> void:
	_add("number", pos, NUMBER, "Destroyed" if destroyed else "-%d" % damage, DAMAGE)
	_add("burst", pos, RING, "", DAMAGE)


func _on_status(target_id: String, status_type: String, _value: int, _source_id: String) -> void:
	if status_type == "shield":
		_at(target_id, "ring", RING, "", SHIELD)


func _on_defeated(id: String, by: String, cause: String) -> void:
	var c := _find(id)
	# A Mount falling with its rider is hidden under the rider's figure; one ghost is enough.
	if c != null and c.is_placed() and cause != "mount_propagation":
		var away := _away_from(by, c.position)
		ghosts.append({"character": c, "pos": c.position, "start": now, "away": away if away != 0 else 1})
		_add("burst", c.position, DEFEAT, "", DAMAGE)


func _on_leak(_id: String, pos: Vector2i) -> void:
	_add("ring", pos, RING, "", LEAK)


func _on_ember_picked_up(id: String) -> void:
	_at(id, "burst", EMBER, "+Ember", EMBER_COLOR)


func _on_ember_delivered(id: String) -> void:
	_at(id, "burst", EMBER * 1.4, "Banked", EMBER_COLOR)


func _on_leveled(id: String, level: int) -> void:
	levels[id] = now
	_at(id, "level", LEVEL_UP, "LEVEL %d" % level, LEVEL)


func _on_action(action_type: String, actor_id: String, result: Dictionary) -> void:
	if action_type == "ability" and result.get("success", false):
		casts[actor_id] = now
		_at(actor_id, "ring", RING, "", CAST)


# Screen-x direction pointing away from a character (the attacker) at `from_pos`: -1, 0
# (straight up or down, or no attacker such as a Leak), or 1.
func _away_from(attacker_id: String, pos: Vector2i) -> int:
	var attacker := _find(attacker_id)
	if attacker == null or not attacker.is_placed():
		return 0
	return int(signf(float(pos.x - attacker.position.x)))


# The side whose turn starts does a quick "ready" bob, rippling across its columns.
func _on_turn_started(player_id: String) -> void:
	ready = {"player": player_id, "start": now}
