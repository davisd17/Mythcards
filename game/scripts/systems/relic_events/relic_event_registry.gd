class_name RelicEventRegistry
# Card id -> handler script (LLD-relic-event-deck.md 3.2), using the ids in
# data/cards/relic_events.json (Closed City + Flood Survivors; designer choice 2026-09-27).

const HANDLER_DIR := "res://scripts/systems/relic_events/"
const HANDLERS := {
	"r-chintamani-fragment": "r_chintamani_fragment.gd",
	"r-reactor-core-fragment": "r_reactor_core_fragment.gd",
	"r-karpovas-black-key": "r_karpovas_black_key.gd",
	"r-signal-array-turns": "r_signal_array_turns.gd",
	"r-reactor-prayer": "r_reactor_prayer.gd",
	"r-closed-city-incident": "r_closed_city_incident.gd",
	"r-seventeen-seconds": "r_seventeen_seconds.gd",
	"a-flood-survivor-emerald-tablet": "a_emerald_tablet.gd",
	"a-flood-survivor-black-sarcophagus": "a_black_sarcophagus.gd",
	"a-flood-survivor-tide-sealed-archive": "a_tide_sealed_archive.gd",
	"a-flood-survivor-the-causeway-breathes": "a_the_causeway_breathes.gd",
	"a-flood-survivor-black-water-remembers": "a_black_water_remembers.gd",
	"a-flood-survivor-the-flood-reaches-the-walls": "a_the_flood_reaches_the_walls.gd",
	"a-flood-survivor-the-drowned-seraph-speaks": "a_the_drowned_seraph_speaks.gd",
}


# Never null: an unknown card gets the no-effect base handler.
static func get_handler(card_id: String) -> RelicEventHandler:
	if not HANDLERS.has(card_id):
		push_error("RelicEventRegistry: no handler for card '%s'" % card_id)
		return RelicEventHandler.new()
	return load(HANDLER_DIR + HANDLERS[card_id]).new()
