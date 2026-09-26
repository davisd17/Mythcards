class_name CharacterData
extends Resource
# Mirrors one entry of data/cards/characters.json. Populated only by ContentDB.

var id: String = ""
var faction: String = ""       # e.g. "Russian-Inspired" — display/theming only
var culture: String = ""       # e.g. "Russian-inspired" — used for culture-scoped queries
var sub_area: String = ""      # single value (validated — no "X / Y" combined values)
var char_name: String = ""     # JSON key is "name"; renamed to avoid Resource.resource_name
var type: String = ""          # one of GameEnums.CHARACTER_TYPES
var unique: bool = false
var hp: int = 0
var atk: int = 0
var move: int = 0
var range: int = 0
var l1: String = ""
var l2: String = ""
var l3: String = ""
var role: String = ""
var review_status: String = "" # "" = playable; "draft_for_review" = review draft
var raw: Dictionary = {}       # full source entry, so narrative/asset fields aren't lost
