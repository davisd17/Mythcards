class_name AIPersonality
extends RefCounted
# An AI level's weights, loaded from data/ai/<name>.json (LLD-ai-opponent.md 3-4). A new
# level or personality is a new file, not new code.

const DIR := "res://data/ai/"

var name := "Basic"
var end_turn_threshold := 0.15
var randomness := 0.05
var weights: Dictionary = {}
var character_value: Dictionary = {}


static func load_named(personality: String = "basic") -> AIPersonality:
	var p := AIPersonality.new()
	var path := DIR + personality + ".json"
	var json := JSON.new()
	if not FileAccess.file_exists(path) or json.parse(FileAccess.get_file_as_string(path)) != OK \
			or not json.data is Dictionary:
		push_error("AIPersonality: can't read %s (run tools/sync_game_content.ps1)" % path)
		return p
	var data: Dictionary = json.data
	p.name = str(data.get("name", personality))
	p.end_turn_threshold = float(data.get("end_turn_threshold", p.end_turn_threshold))
	p.randomness = float(data.get("randomness", p.randomness))
	p.weights = data.get("weights", {})
	p.character_value = data.get("character_value", {})
	return p


func w(key: String, fallback: float = 0.0) -> float:
	return float(weights.get(key, fallback))


func value_of(c: CharacterInstance) -> float:
	return float(character_value.get(c.data.type, 3))
