extends AbilityHandler
# Oracle Sovereign (Hero) — Foresight / Spirit Mantle / Collective Ascension (LLD 5.12).
# L1 Foresight: reveal the next shared relic/event card; you may put it on the bottom
#    of the deck (designer ruling 2026-09-27: optional at every level). Then one
#    adjacent ally gains a 1-damage shield.
#    Payload: {"to_bottom": bool, "ally_id": optional adjacent ally}.
# L2 Spirit Mantle: at the start of your turn the Oracle gains a 1-damage shield, and
#    may give one to an adjacent ally ("spirit_mantle" reactive bonus). (The printed
#    L2 "may instead leave it on top" is already true at L1 under that ruling.)
# L3 Collective Ascension: +1 HP, +1 RANGE. Standalone ability "a-hero_l3", once per
#    match: every ally heals 2, gains a 1-damage shield, and +1 MOVE this turn.

const L3_ID := "a-hero_l3"
const FORESIGHT_SHIELD := 1
const SPIRIT_MANTLE_SHIELD := 1
const ASCENSION_HEAL := 2
const ASCENSION_SHIELD := 1
const ASCENSION_MOVE := 1


func level_bonuses() -> Dictionary:
	return {3: {"hp": 1, "range": 1}}


func ability_ids(instance: CharacterInstance) -> Array[String]:
	return [instance.data.id, L3_ID]


func can_use(sys, instance: CharacterInstance, ability_id: String) -> bool:
	if ability_id == L3_ID:
		return instance.level >= 3 and not sys.used_this_match(instance, "collective_ascension_used")
	return true


func get_legal_targets(sys, instance: CharacterInstance, ability_id: String) -> Array:
	return [] if ability_id == L3_ID else _adjacent_allies(sys, instance)


func validate(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> String:
	if ability_id == L3_ID:
		return ""
	if payload.has("ally_id") and not _adjacent_allies(sys, instance).has(str(payload.ally_id)):
		return "needs an adjacent ally"
	return ""


func execute(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if ability_id == L3_ID:
		instance.ability_uses_this_match["collective_ascension_used"] = true
		for ally in sys.live_characters():
			if ally.player_id != instance.player_id:
				continue
			sys.heal(ally, ASCENSION_HEAL)
			sys.add_status(ally, "shield", ASCENSION_SHIELD, "this_turn", instance)
			sys.add_status(ally, "temp_move", ASCENSION_MOVE, "this_turn", instance)
		return {"success": true}
	var revealed := RelicEventDeck.peek_next()
	if revealed != "" and payload.get("to_bottom", false):
		RelicEventDeck.move_top_to_bottom()
	if payload.has("ally_id"):
		sys.add_status(sys.find(str(payload.ally_id)), "shield", FORESIGHT_SHIELD, "this_turn", instance)
	return {"success": true, "revealed": revealed}


func on_turn_started(sys, instance: CharacterInstance, player_id: String) -> void:
	if instance.level < 2 or player_id != instance.player_id:
		return
	sys.add_status(instance, "shield", SPIRIT_MANTLE_SHIELD, "this_turn", instance)
	if not _adjacent_allies(sys, instance).is_empty():
		sys.offer_bonus(instance, "spirit_mantle")


func execute_reactive_bonus(sys, instance: CharacterInstance, tag: String, payload: Dictionary) -> Dictionary:
	if tag != "spirit_mantle":
		return super(sys, instance, tag, payload)
	var target_id := str(payload.get("target_id", ""))
	if not _adjacent_allies(sys, instance).has(target_id):
		return {"success": false, "reason": "needs an adjacent ally"}
	sys.consume_bonus(instance, "spirit_mantle")
	sys.add_status(sys.find(target_id), "shield", SPIRIT_MANTLE_SHIELD, "this_turn", instance)
	return {"success": true}


func ability_label(_instance: CharacterInstance, ability_id: String) -> String:
	return "Collective Ascension" if ability_id == L3_ID else "Foresight"


func next_step(sys, instance: CharacterInstance, ability_id: String, payload: Dictionary) -> Dictionary:
	if ability_id == L3_ID:
		return {}
	var next := RelicEventDeck.peek_next()
	if next != "" and not payload.has("to_bottom"):
		var card := ContentDB.get_relic_event(next)
		var title: String = card.card_name if card != null else next
		var step := option_step("to_bottom", "Foresight reveals: %s." % title,
				[{"label": "Leave it on top", "value": false}, {"label": "Put it on the bottom", "value": true}])
		step["revealed"] = next   # the screen shows the card itself
		return step
	if payload.has("ally_id"):
		return {}
	var allies := _adjacent_allies(sys, instance)
	return {} if allies.is_empty() else target_step("ally_id", "Shield which adjacent ally?", allies, true)


func bonus_label(tag: String) -> String:
	return "Spirit Mantle" if tag == "spirit_mantle" else super(tag)


func bonus_step(sys, instance: CharacterInstance, tag: String, payload: Dictionary) -> Dictionary:
	if tag != "spirit_mantle" or payload.has("target_id"):
		return {}
	return target_step("target_id", "Spirit Mantle: shield which adjacent ally?", _adjacent_allies(sys, instance))


static func _adjacent_allies(sys, instance: CharacterInstance) -> Array[String]:
	var result: Array[String] = []
	for ally in sys.allies_of(instance):
		if sys.is_adjacent(ally.position, instance.position):
			result.append(ally.instance_id)
	return result
