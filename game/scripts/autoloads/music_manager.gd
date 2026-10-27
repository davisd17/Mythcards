extends Node
# One theme per match: the starting Leader's specific theme, then their area base.
# Area bases remain available for eventual single-player exploration. No culture fallback:
# an unscored sub-area must not inherit another area's musical identity.
const THEMES := {
	"Closed City": "res://assets/music/closed-city-v2.wav",
	"Flood Survivors": "res://assets/music/flood-survivors-stone-remembers-v1.wav",
}
const LEADER_THEMES := {
	"r-irina-karpova": "res://assets/music/irina-private-favors-a-v2.wav",
	"a-flood-survivor-meret-anu": "res://assets/music/meret-anu-pearl-current-a-v2.wav",
}
const MENU_THEME := "res://assets/music/the-threshold-menu-v1.wav"
const MUSIC_BUS := "Music"
const MENU_DB := -7.0
const FADE_SECONDS := 1.0

var current_sub_area := ""
var current_leader_id := ""
var current_theme_path := ""
var _player: AudioStreamPlayer
var _menu_player: AudioStreamPlayer
var _menu_fade: Tween
var _menu_active := false


func _ready() -> void:
	if AudioServer.get_bus_index(MUSIC_BUS) < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, MUSIC_BUS)
	_player = AudioStreamPlayer.new()
	_player.name = "MatchMusic"
	_player.volume_db = -3.0
	_player.bus = MUSIC_BUS
	add_child(_player)
	_menu_player = AudioStreamPlayer.new()
	_menu_player.name = "MenuAmbience"
	_menu_player.bus = MUSIC_BUS
	_menu_player.volume_db = -80.0
	add_child(_menu_player)
	apply_settings()
	EventBus.match_started.connect(_on_match_started)
	EventBus.match_reset.connect(_stop_match)
	EventBus.match_ended.connect(_on_match_ended)


func _on_match_started() -> void:
	_stop_match()
	_fade_menu_out()
	apply_settings()
	var state := GameState.match_state
	if state == null:
		return
	var starter := state.get_player(state.first_player_id)
	if starter == null:
		return
	for character in starter.characters:
		if character.data != null and character.data.type == "Leader":
			current_sub_area = character.data.sub_area
			current_leader_id = character.data.id
			break
	current_theme_path = LEADER_THEMES.get(current_leader_id, THEMES.get(current_sub_area, ""))
	if current_theme_path == "":
		return
	_player.stream = _loop_stream(current_theme_path)
	if _player.stream == null:
		return
	_player.stream_paused = false
	_player.play()


func stop() -> void:
	_stop_match()
	_cancel_menu_fade()
	_menu_player.stop()
	_menu_player.stream = null
	_menu_active = false


func _stop_match() -> void:
	_player.stop()
	_player.stream_paused = false
	_player.stream = null
	current_sub_area = ""
	current_leader_id = ""
	current_theme_path = ""


func play_menu() -> void:
	apply_settings()
	if _player.playing:
		_player.stream_paused = true
	if _menu_active and _menu_player.playing:
		return  # Team selection must not restart the same ambience.
	_cancel_menu_fade()
	_menu_active = true
	if not _menu_player.playing:
		_menu_player.stream = _loop_stream(MENU_THEME)
		if _menu_player.stream == null:
			return
		_menu_player.volume_db = -80.0
		_menu_player.play()
	_menu_fade = create_tween()
	_menu_fade.tween_property(_menu_player, "volume_db", MENU_DB, FADE_SECONDS)


func close_menu() -> void:
	if not GameState.is_match_active():
		return  # The chooser and deployment still need their ambient bed.
	_player.stream_paused = false
	_fade_menu_out()


# Music has its own toggle, separate from Sound (designer 2026-10-17).
func apply_settings() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(MUSIC_BUS), not Settings.music)


func _fade_menu_out() -> void:
	_cancel_menu_fade()
	_menu_active = false
	if not _menu_player.playing:
		return
	_menu_fade = create_tween()
	_menu_fade.tween_property(_menu_player, "volume_db", -80.0, FADE_SECONDS)
	_menu_fade.tween_callback(_menu_player.stop)


func _cancel_menu_fade() -> void:
	if _menu_fade != null:
		_menu_fade.kill()
		_menu_fade = null


func _loop_stream(path: String) -> AudioStreamWAV:
	var source := load(path) as AudioStreamWAV
	if source == null:
		return null
	var stream := source.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	return stream


func _on_match_ended(_winner_id: String, _condition: String) -> void:
	stop()
