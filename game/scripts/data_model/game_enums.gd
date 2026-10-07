class_name GameEnums
# Shared constant lists so validation strings in ContentDB, BoardModel, and
# PlacedObjectRegistry can't drift apart (LLD-content-board 3.1).

const CHARACTER_TYPES: Array[String] = [
	"Common", "Mount", "Warrior", "Leader", "Hero", "Specialist", "Mystic"
]

# "Rare Relic" arrived with the Closed City / Flood Survivors sets. It occupies the
# relic slot exactly like "Relic"; rarity only matters to deck building.
const RELIC_KINDS: Array[String] = ["Relic", "Rare Relic"]
const EVENT_KINDS: Array[String] = ["Event"]
const RELIC_EVENT_KINDS: Array[String] = ["Relic", "Rare Relic", "Event"]

const MOVEMENT_PATTERNS: Array[String] = ["orthogonal"]

const PLACED_OBJECT_TYPES: Array[String] = ["barricade", "pylon", "stone", "leak", "vault"]

const MATCH_PHASES: Array[String] = ["setup", "in_progress", "ended"]
const WIN_CONDITIONS: Array[String] = ["", "hero_capture", "army_defeat"]

# How long a StatusEffect lasts; TurnManager clears each kind at its owner's turn start
# (LLD-match-setup 4.3).
const STATUS_EXPIRY: Array[String] = ["immediate", "this_turn", "this_round", "next_turn", "until_used"]

const PLAYER_IDS: Array[String] = ["p1", "p2"]
