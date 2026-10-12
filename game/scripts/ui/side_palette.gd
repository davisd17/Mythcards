class_name SidePalette
extends RefCounted
# A side's colors and atmosphere (designer request 2026-10-11, LLD-atmosphere-phase4.md 2):
# chosen by the area (culture) and sub-area of the side's Leader. When both Leaders come
# from the same sub-area, Player 2 takes the inverse set (each color's complementary hue,
# same saturation and value) so the two sides never read alike.
#
# primary: territory wash, bases, labels, chips, the turn line. accent: inlay details.
# atmosphere: the drifting effect over the side's territory (Phase 4).
# inlay: "city" (Russian-inspired channels) or "flood" (Atlantean ley lines).

const SUB_AREAS := {
	# Russian-inspired
	"Closed City": {"primary": "#b5474c", "accent": "#6fae7c", "atmosphere": "ash", "inlay": "city"},
	"Winter Front": {"primary": "#c9a04a", "accent": "#b5474c", "atmosphere": "snow", "inlay": "city"},
	"Far North": {"primary": "#5fc48a", "accent": "#9a86e0", "atmosphere": "aurora", "inlay": "city"},
	# Atlantean
	"Flood Survivors": {"primary": "#4fb3bd", "accent": "#a8875a", "atmosphere": "caustics", "inlay": "flood"},
	"First Mind": {"primary": "#6f8ee8", "accent": "#e6dccb", "atmosphere": "stars", "inlay": "flood"},
	"Crystal Dominion": {"primary": "#d06fa8", "accent": "#e8f0f2", "atmosphere": "quartz", "inlay": "flood"},
}
# A Leader with no known sub-area falls back to its culture's flagship sub-area.
const CULTURE_DEFAULT := {"Russian-inspired": "Closed City", "Atlantean": "Flood Survivors"}
const FALLBACK := {"p1": "Closed City", "p2": "Flood Survivors"}

var area := ""          # the sub-area this palette came from
var primary: Color
var accent: Color
var atmosphere := ""
var inlay := ""
var inverted := false


static func of_area(sub_area: String, culture: String = "", fallback: String = "Closed City") -> SidePalette:
	var key := sub_area
	if not SUB_AREAS.has(key):
		key = CULTURE_DEFAULT.get(culture, fallback)
	var entry: Dictionary = SUB_AREAS[key]
	var p := SidePalette.new()
	p.area = key
	p.primary = Color(entry.primary)
	p.accent = Color(entry.accent)
	p.atmosphere = entry.atmosphere
	p.inlay = entry.inlay
	return p


# The complementary set: hue turned half way round, saturation and value kept.
func inverse() -> SidePalette:
	var p := SidePalette.new()
	p.area = area
	p.primary = _complement(primary)
	p.accent = _complement(accent)
	p.atmosphere = atmosphere
	p.inlay = inlay
	p.inverted = not inverted
	return p


static func _complement(c: Color) -> Color:
	return Color.from_hsv(fposmod(c.h + 0.5, 1.0), c.s, c.v, c.a)


# The Leader's sub-area and culture for a side, or ["", ""] if it fields no Leader.
static func leader_area(player: PlayerState) -> Array:
	if player == null:
		return ["", ""]
	for c in player.characters:
		if c.data != null and c.data.type == "Leader":
			return [c.data.sub_area, c.data.culture]
	return ["", player.culture]


# Both sides' palettes, keyed "p1" / "p2". Player 2 is inverted on a same-sub-area match.
static func for_players(p1: PlayerState, p2: PlayerState) -> Dictionary:
	var a := leader_area(p1)
	var b := leader_area(p2)
	var first := of_area(a[0], a[1], FALLBACK.p1)
	var second := of_area(b[0], b[1], FALLBACK.p2)
	if first.area == second.area:
		second = second.inverse()
	return {"p1": first, "p2": second}
