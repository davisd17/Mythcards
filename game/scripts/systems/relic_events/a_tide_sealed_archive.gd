extends RelicEventHandler
# Tide-Sealed Archive (Relic): your Leader and Specialist each gain +1 RANGE on AP
# abilities. Once each turn, when an ally gains Memory, you may move that ally 1 tile
# (offered as that ally's free move). It must end on an empty tile.

const CARD := "a-flood-survivor-tide-sealed-archive"
const TYPES := ["Leader", "Specialist"]


func get_range_bonus(_sys, owner_id: String, instance: CharacterInstance, context: String) -> int:
	return 1 if context == "ability" and instance.player_id == owner_id and TYPES.has(instance.data.type) else 0


func on_memory_gained(sys, owner_id: String, character_id: String) -> void:
	var c: CharacterInstance = sys.find(character_id)
	if c == null or c.player_id != owner_id:
		return
	var s := RelicEventDeck.relic_state(owner_id, CARD)
	if s.get("used_turn", -1) == sys.state().turn_number:
		return
	s["used_turn"] = sys.state().turn_number
	sys.offer_bonus(c, "free_move")
