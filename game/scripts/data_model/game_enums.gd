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

const PLACED_OBJECT_TYPES: Array[String] = ["barricade", "pylon", "stone"]
