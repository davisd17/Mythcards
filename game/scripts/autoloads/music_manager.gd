extends Node
# One theme per match, chosen from the starting player's Leader, not the active turn.
# Add approved sub-area tracks here as they become available. No culture fallback:
# an unscored sub-area must not inherit another area's musical identity.
const THEMES := {
	"Closed City": "res://assets/music/closed-city-v2.wav",
}

var current_sub_area := ""
var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "MatchMusic"
	_player.volume_db = -3.0
	add_child(_player)
	EventBus.match_started.connect(_on_match_started)
	EventBus.match_reset.connect(stop)
	EventBus.match_ended.connect(_on_match_ended)


func _on_match_started() -> void:
	stop()
	var state := GameState.match_state
	if state == null:
		return
	var starter := state.get_player(state.first_player_id)
	if starter == null:
		return
	for character in starter.characters:
		if character.data != null and character.data.type == "Leader":
			current_sub_area = character.data.sub_area
			break
	if not THEMES.has(current_sub_area):
		return
	var source := load(THEMES[current_sub_area]) as AudioStreamWAV
	if source == null:
		return
	var stream := source.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	_player.stream = stream
	_player.play()


func stop() -> void:
	_player.stop()
	_player.stream = null
	current_sub_area = ""


func _on_match_ended(_winner_id: String, _condition: String) -> void:
	stop()
