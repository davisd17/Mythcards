class_name FigurePose
extends RefCounted
# Figure animation (LLD-figure-animation.md, Visual Polish Phase 5): how a standing figure
# is posed right now. Pure functions of the time and BoardFx's timers, so nothing here is
# stored or drawn. A pose is {lift (tiles, up), scale_y (1 = rest), lean (degrees,
# positive = top toward screen-right)}. GameBoardView applies it about the figure's feet.

const IDLE_STRETCH := 0.02          # designer 2026-10-14: noticeable at a glance on a phone
const IDLE_SWAY := 0.9              # degrees
const IDLE_PERIOD := 2.8            # plus up to 0.8 s per figure, so the board never pulses in unison
const MOUNT_SLOWER := 1.25
const MOUNT_DEEPER := 1.3
const SPENT_SINK := 0.01
const SELECT_BOB := 0.012
const SELECT_PERIOD := 1.2
const HOP_HEIGHT := 0.10
const LAND_SQUASH := 0.06
const WINDUP_LEAN := 4.0
const WINDUP_CROUCH := 0.05         # stands in for a lean when the target is straight up or down
const RECOIL_LEAN := 6.0
const FLINCH_LEAN := 2.0
const CAST_LIFT := 0.05
const CAST_STRETCH := 0.03
const LEVEL_STRETCH := 0.10
const TOPPLE := 25.0
const READY_LIFT := 0.05           # the turn-start bob (designer 2026-10-14)
const READY_STRETCH := 0.03


static func rest() -> Dictionary:
	return {"lift": 0.0, "scale_y": 1.0, "lean": 0.0}


# 0..1, fixed per character: where in its breath a figure is.
static func phase(instance_id: String) -> float:
	return float(hash(instance_id) & 0xffff) / 65535.0


static func pose(c: CharacterInstance, fx: BoardFx, spent: bool, selected: bool, motion: bool) -> Dictionary:
	var p := rest()
	var t := fx.now
	if spent:
		p.lift -= SPENT_SINK
	elif motion:
		var mount := c.data != null and c.data.type == "Mount"
		var period := (IDLE_PERIOD + 0.8 * phase(c.instance_id)) * (MOUNT_SLOWER if mount else 1.0)
		var breath := 0.5 - 0.5 * cos(TAU * (t / period + phase(c.instance_id)))
		p.scale_y += IDLE_STRETCH * breath * (MOUNT_DEEPER if mount else 1.0)
		p.lean += IDLE_SWAY * sin(TAU * (t / (period * 1.3) + phase(c.instance_id)))
	if selected and motion:
		p.lift += SELECT_BOB * (0.5 - 0.5 * cos(TAU * t / SELECT_PERIOD))
	_hop(p, c, fx)
	_windup(p, c, fx)
	_recoil(p, c, fx)
	if fx.casts.has(c.instance_id):
		var k := sin(PI * fx.progress(fx.casts[c.instance_id], BoardFx.CAST_TIME))
		p.lift += CAST_LIFT * k
		p.scale_y += CAST_STRETCH * k
	if not fx.ready.is_empty() and fx.ready.player == c.player_id:
		var u := fx.progress(fx.ready.start + BoardFx.READY_STAGGER * c.position.x, BoardFx.READY)
		if u > 0.0 and u < 1.0:
			p.lift += READY_LIFT * sin(PI * u)
			p.scale_y += READY_STRETCH * sin(PI * u)
	if fx.levels.has(c.instance_id):
		p.scale_y += LEVEL_STRETCH * level_curve(fx.progress(fx.levels[c.instance_id], BoardFx.LEVEL_POSE))
	return p


# The move hop rides the Phase 2 slide: an arc, then a squash in the last third (landing).
static func _hop(p: Dictionary, c: CharacterInstance, fx: BoardFx) -> void:
	for id in [c.instance_id, c.mounted_with_id]:
		if id != "" and fx.slides.has(id):
			var u := fx.progress(fx.slides[id].start, BoardFx.SLIDE)
			p.lift += HOP_HEIGHT * sin(PI * u)
			if u > 2.0 / 3.0:
				p.scale_y -= LAND_SQUASH * sin(PI * (u - 2.0 / 3.0) * 3.0)
			return


# Lean back away from the target, then snap into the strike (the lunge itself is
# BoardFx.offset_tiles). A target straight up or down gets a crouch instead.
static func _windup(p: Dictionary, c: CharacterInstance, fx: BoardFx) -> void:
	if not fx.lunges.has(c.instance_id):
		return
	var l: Dictionary = fx.lunges[c.instance_id]
	if l.get("framed", false):
		return   # Phase 6: the drawn brace and recoil are the wind-up; no extra lean
	var k := windup_curve(fx.progress(l.start, l.duration))
	var dx := signf(float(l.toward.x - c.position.x))
	if dx != 0.0:
		p.lean += dx * WINDUP_LEAN * k
	else:
		p.scale_y -= WINDUP_CROUCH * maxf(0.0, -k)


# -1 (leaning back) by 30%, +0.6 (into the strike) by 55%, then back to 0.
static func windup_curve(u: float) -> float:
	if u < 0.3:
		return -u / 0.3
	if u < 0.55:
		return lerpf(-1.0, 0.6, (u - 0.3) / 0.25)
	return lerpf(0.6, 0.0, (u - 0.55) / 0.45)


# Struck: lean away from the attacker fast, ease back. Straight up or down: a squash.
static func _recoil(p: Dictionary, c: CharacterInstance, fx: BoardFx) -> void:
	if not fx.recoils.has(c.instance_id):
		return
	var r: Dictionary = fx.recoils[c.instance_id]
	var u := fx.progress(r.start, BoardFx.RECOIL)
	var k := u / 0.25 if u < 0.25 else 1.0 - (u - 0.25) / 0.75
	var angle := FLINCH_LEAN if r.blocked else RECOIL_LEAN
	if r.away != 0:
		p.lean += float(r.away) * angle * k
	else:
		p.scale_y -= (0.015 if r.blocked else 0.04) * k


# Up to full stretch by 40%, then a settle that overshoots a little below rest.
static func level_curve(u: float) -> float:
	if u < 0.4:
		return BoardFx.ease_out(u / 0.4)
	var v := (u - 0.4) / 0.6
	return cos(v * PI) * (1.0 - v) if v < 1.0 else 0.0


# The defeat ghost tips away from whoever defeated it as it sinks.
static func topple(g: Dictionary, fx: BoardFx) -> float:
	return float(g.get("away", 1)) * TOPPLE * BoardFx.ease_out(fx.progress(g.start, BoardFx.DEFEAT))


# --- Phase 6: hand-drawn attack frames ----------------------------------------------------

const FRAME_BLEND := 0.04   # seconds of crossfade into the next pose (and back to idle)


# Which images to draw for an art attack `elapsed` seconds in, bottom to top:
# [{frame: index, or -1 for the default figure, alpha}]. Each pose crossfades into the
# next over the end of its hold (at most 40% of it), and the last pose into the idle
# figure, so playback never snaps (art delivery note 2026-10-15: "less choppy").
static func frame_layers(seconds: Array, elapsed: float) -> Array:
	if seconds.is_empty():
		return [{"frame": -1, "alpha": 1.0}]
	if elapsed < FRAME_BLEND:
		return [{"frame": -1, "alpha": 1.0}, {"frame": 0, "alpha": elapsed / FRAME_BLEND}]
	var start := 0.0
	for i in seconds.size():
		var hold: float = seconds[i]
		if elapsed < start + hold:
			var window := minf(FRAME_BLEND, hold * 0.4)
			var into := elapsed - start - (hold - window)
			if into <= 0.0:
				return [{"frame": i, "alpha": 1.0}]
			var nxt := i + 1 if i + 1 < seconds.size() else -1
			return [{"frame": i, "alpha": 1.0}, {"frame": nxt, "alpha": into / window}]
		start += hold
	return [{"frame": -1, "alpha": 1.0}]


# Frames face screen-right; an attack toward the left plays them mirrored.
static func attack_mirrored(c: CharacterInstance, fx: BoardFx) -> bool:
	var l: Dictionary = fx.lunges.get(c.instance_id, {})
	return l.get("framed", false) and l.toward.x < c.position.x
