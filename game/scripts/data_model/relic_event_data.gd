class_name RelicEventData
extends Resource
# Mirrors one entry of data/cards/relic_events.json (or a review-draft file).
# Populated only by ContentDB.

var id: String = ""
var faction: String = ""
var sub_area: String = ""
var card_name: String = ""     # JSON key is "name"
var kind: String = ""          # one of GameEnums.RELIC_EVENT_KINDS
var duration: String = ""      # "Persistent" | "1 round" | "1 turn" | "Immediate"
var effect: String = ""
var note: String = ""
var review_status: String = "" # "" = playable; "draft_for_review" = review draft (BR-043A)
var raw: Dictionary = {}       # full source entry, so narrative-only fields aren't lost


func is_relic() -> bool:
	return GameEnums.RELIC_KINDS.has(kind)


func is_event() -> bool:
	return GameEnums.EVENT_KINDS.has(kind)
