class_name Sfx
extends Node
# Visual Polish Phase 4 (LLD-atmosphere-phase4.md 4): lightweight sound and haptics. Every
# sound is synthesized once at startup (no audio files to ship or license), played from a
# small pool on EventBus signals, and kept short and quiet. A low drone loop gives the
# convergence an ambience. Presentation only: nothing here reads back into the rules.

const RATE := 22050
const POOL := 8
const REPEAT_GAP_MS := 45       # the same sound twice within this is dropped (AI bursts)
const DRONE_DB := -27.0
const HAPTIC_MS := {"hit": 25, "defeat": 60, "level": 40}
const VOLUME_DB := {"move": -14.0, "hit": -8.0, "blocked": -12.0, "shield": -13.0, "cast": -14.0,
	"defeat": -9.0, "level": -10.0, "ember": -12.0, "draw": -13.0, "turn": -15.0, "leak": -12.0, "win": -8.0}

var streams := {}               # name -> AudioStreamWAV
var played: Array[String] = []  # names actually played, newest last (for tests)
var _players: Array[AudioStreamPlayer] = []
var _drone := AudioStreamPlayer.new()
var _last_ms := {}
# Phase 6: (instance id) -> seconds until an art attack's impact frame (0 = none). While
# such an attack resolves, the sounds it causes wait for the shot. Set by the game screen.
var impact_for: Callable = Callable()
var _delay := 0.0
const AT_IMPACT := ["hit", "blocked", "defeat", "ember", "level"]
var _next := 0


func _ready() -> void:
	streams = build_streams()
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_drone.stream = _wav(_drone_samples(), true)
	_drone.volume_db = DRONE_DB
	add_child(_drone)
	apply_settings()
	EventBus.character_moved.connect(func(_id, _f, _t): play("move"))
	EventBus.character_repositioned.connect(_on_repositioned)
	EventBus.damage_resolved.connect(func(_a, _t, amount, _l): play("hit" if amount > 0 else "blocked"))
	EventBus.status_added.connect(_on_status)
	EventBus.action_requested.connect(_on_requested)
	EventBus.action_resolved.connect(_on_action)
	EventBus.character_defeated.connect(_on_defeated)
	EventBus.character_leveled_up.connect(func(_id, _l): play("level"))
	EventBus.spirit_ember_picked_up.connect(func(_id): play("ember"))
	EventBus.spirit_ember_delivered.connect(func(_id): play("ember"))
	EventBus.relic_drawn.connect(func(_p, _c): play("draw"))
	EventBus.turn_started.connect(func(_p): play("turn"))
	EventBus.leak_triggered.connect(func(_id, _pos): play("leak"))
	EventBus.match_ended.connect(func(_w, _c): play("win"))


# Starts or stops the drone to match Settings.sound.
func apply_settings() -> void:
	if Settings.sound and not _drone.playing and is_inside_tree():
		_drone.play()
	elif not Settings.sound:
		_drone.stop()


func play(sound: String) -> void:
	if _delay > 0.0 and AT_IMPACT.has(sound) and is_inside_tree():
		var wait := _delay
		get_tree().create_timer(wait).timeout.connect(func(): _play_now(sound))
		return
	_play_now(sound)


func _play_now(sound: String) -> void:
	if Settings.haptics and HAPTIC_MS.has(sound):
		Input.vibrate_handheld(HAPTIC_MS[sound])
	if not Settings.sound or not streams.has(sound):
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_ms.get(sound, -100000)) < REPEAT_GAP_MS:
		return
	_last_ms[sound] = now
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = streams[sound]
	p.volume_db = VOLUME_DB.get(sound, -12.0)
	p.pitch_scale = 0.96 + 0.04 * float(played.size() % 3)   # a little variation on repeats
	p.play()
	played.append(sound)
	if played.size() > 50:
		played.pop_front()


func _on_repositioned(_id: String, from: Vector2i, to: Vector2i, cause: String) -> void:
	if cause != "return" and from != to:
		play("move")


func _on_status(_target: String, status_type: String, _value: int, _source: String) -> void:
	if status_type == "shield":
		play("shield")


# A Mount falling with its rider is one defeat to hear, not two.
func _on_defeated(_id: String, _by: String, cause: String) -> void:
	if cause == "direct":
		play("defeat")


func _on_requested(action_type: String, actor_id: String, _payload: Dictionary) -> void:
	_delay = float(impact_for.call(actor_id)) if action_type == "attack" and impact_for.is_valid() else 0.0


func _on_action(action_type: String, _actor: String, result: Dictionary) -> void:
	_delay = 0.0
	if action_type == "ability" and result.get("success", false):
		play("cast")


# --- Synthesis ---------------------------------------------------------------------------------

static func build_streams() -> Dictionary:
	return {
		"move": _wav(_noise_sweep(0.16, 0.25, 0.15, 0.03)),
		"hit": _wav(_mix([_sweep(0.24, 170.0, 65.0, 0.9, 9.0), _noise_sweep(0.06, 0.6, 0.5, 0.2)])),
		"blocked": _wav(_mix([_sweep(0.28, 1240.0, 1240.0, 0.35, 11.0), _sweep(0.28, 1860.0, 1860.0, 0.2, 13.0)])),
		"shield": _wav(_mix([_sweep(0.45, 880.0, 880.0, 0.35, 6.0), _sweep(0.45, 1320.0, 1320.0, 0.25, 7.0)])),
		"cast": _wav(_sweep(0.26, 380.0, 920.0, 0.35, 5.0)),
		"defeat": _wav(_sweep(0.55, 330.0, 100.0, 0.6, 4.0, 9.0)),
		"level": _wav(_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.085, 0.4)),
		"ember": _wav(_arpeggio([1567.98, 2093.0, 1760.0], 0.06, 0.25)),
		"draw": _wav(_noise_sweep(0.2, 0.3, 0.05, 0.4)),
		"turn": _wav(_mix([_sweep(0.7, 659.25, 659.25, 0.3, 4.0), _sweep(0.7, 987.77, 987.77, 0.15, 5.0)])),
		"leak": _wav(_sweep(0.32, 210.0, 150.0, 0.45, 6.0, 22.0)),
		"win": _wav(_mix([_sweep(1.3, 261.63, 261.63, 0.3, 1.6), _sweep(1.3, 329.63, 329.63, 0.25, 1.6),
				_sweep(1.3, 392.0, 392.0, 0.25, 1.6), _sweep(1.3, 523.25, 523.25, 0.2, 1.8)])),
	}


# A sine gliding from f0 to f1 with an exponential decay, a 5 ms attack, and optional tremolo.
static func _sweep(seconds: float, f0: float, f1: float, amp: float, decay: float, tremolo: float = 0.0) -> PackedFloat32Array:
	var n := int(seconds * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var u := float(i) / n
		phase += TAU * lerpf(f0, f1, u) / RATE
		var env := minf(1.0, i / (0.005 * RATE)) * exp(-decay * u)
		if tremolo > 0.0:
			env *= 0.7 + 0.3 * sin(TAU * tremolo * i / RATE)
		out[i] = sin(phase) * amp * env
	return out


# Filtered noise whose brightness moves from b0 to b1 (0..1): swishes and whooshes.
static func _noise_sweep(seconds: float, amp: float, b0: float, b1: float) -> PackedFloat32Array:
	var n := int(seconds * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234   # the same swish every launch
	var y := 0.0
	for i in n:
		var u := float(i) / n
		y += lerpf(b0, b1, u) * (rng.randf_range(-1.0, 1.0) - y)
		out[i] = y * amp * sin(PI * u) * 2.0
	return out


static func _arpeggio(notes: Array, step: float, amp: float) -> PackedFloat32Array:
	var parts: Array = []
	for i in notes.size():
		var note := PackedFloat32Array()
		note.resize(int(step * i * RATE))
		note.append_array(_sweep(step * 2.5, notes[i], notes[i], amp, 5.0))
		parts.append(note)
	return _mix(parts)


static func _mix(parts: Array) -> PackedFloat32Array:
	var n := 0
	for p in parts:
		n = maxi(n, p.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for p in parts:
		for i in p.size():
			out[i] += p[i]
	return out


# Six seconds that loop seamlessly: every partial completes a whole number of cycles.
static func _drone_samples() -> PackedFloat32Array:
	var n := 6 * RATE
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		out[i] = 0.30 * sin(TAU * 55.0 * t) + 0.22 * sin(TAU * 55.5 * t) + 0.12 * sin(TAU * 110.0 * t) \
				+ 0.05 * sin(TAU * 82.5 * t) * (0.5 + 0.5 * sin(TAU * t / 6.0))
	return out


static func _wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = samples.size()
	return wav
