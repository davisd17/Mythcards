class_name RelicEventRegistry
# Card id -> handler script (LLD-relic-event-deck.md 3.2), using the real ids from
# data/cards/prototype_relic_events.json.

const HANDLER_DIR := "res://scripts/systems/relic_events/"
const HANDLERS := {
	"r-winter-palace-standard": "r_winter_palace_standard.gd",
	"r-iron-birch-talisman": "r_iron_birch_talisman.gd",
	"r-generals-war-map": "r_generals_war_map.gd",
	"r-whiteout": "r_whiteout.gd",
	"r-frozen-center": "r_frozen_center.gd",
	"r-rally-from-the-snow": "r_rally_from_the_snow.gd",
	"r-long-winter-march": "r_long_winter_march.gd",
	"a-quartz-heart-core": "a_quartz_heart_core.gd",
	"a-hall-of-shared-minds": "a_hall_of_shared_minds.gd",
	"a-tideglass-obelisk": "a_tideglass_obelisk.gd",
	"a-resonance-surge": "a_resonance_surge.gd",
	"a-psychic-undertow": "a_psychic_undertow.gd",
	"a-crystal-tide": "a_crystal_tide.gd",
	"a-dream-of-the-deep-city": "a_dream_of_the_deep_city.gd",
}


# Never null: an unknown card gets the no-effect base handler.
static func get_handler(card_id: String) -> RelicEventHandler:
	if not HANDLERS.has(card_id):
		push_error("RelicEventRegistry: no handler for card '%s'" % card_id)
		return RelicEventHandler.new()
	return load(HANDLER_DIR + HANDLERS[card_id]).new()
