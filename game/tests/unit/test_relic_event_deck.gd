extends GutTest
# RelicEventDeck with the Closed City + Flood Survivors set (designer choice 2026-09-27),
# the Leak / Memory / Stone rules they need, and choices through RulesEngine.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const SNIPER := Fixture.SNIPER         # Warrior ATK 2 RANGE 4
const GYMNAST := Fixture.GYMNAST       # Common MOVE 3
const GENERAL := Fixture.GENERAL       # Leader MOVE 2
const BOGATYR := Fixture.BOGATYR       # Hero
const ENGINEER := "p1_r-engineer"      # Specialist
const SEER := "p1_r-seer"              # Mystic RANGE 3
const GUARD := Fixture.GUARD
const CONDUCTOR := Fixture.CONDUCTOR   # HP 4
const HARMONIC := "p2_a-harmonic"      # Mystic
const CENTER := Vector2i(3, 3)

var sys: AbilitySystem


func before_each() -> void:
	autofree(Fixture.start_match())
	TurnManager.relic_event_deck = null        # the real deck from here on
	Fixture.state().shared_deck.clear()        # tests stack their own cards
	Fixture.clear_board()
	Fixture.state().get_player("p1").pool_ap_remaining = 4
	sys = RulesEngine.systems().ability
	watch_signals(EventBus)


func after_each() -> void:
	sys = null
	Fixture.teardown()


func _c(id: String) -> CharacterInstance:
	return Fixture.character(id)


func _act(action: String, actor: String, payload: Dictionary = {}) -> Dictionary:
	return RulesEngine.request_action(action, actor, payload)


func _draw(card_id: String, player_id: String = "p1") -> void:
	Fixture.state().shared_deck.push_front(card_id)
	RelicEventDeck.draw_for(player_id)


func _relic(player_id: String, card_id: String) -> void:
	Fixture.state().get_player(player_id).active_relic_id = card_id


func _leak(pos: Vector2i) -> void:
	Fixture.board().get_tile(pos).leak = true


func _combat() -> CombatResolver:
	return RulesEngine.systems().combat


func _range(c: CharacterInstance, context: String) -> int:
	return c.get_effective_range(context, sys.get_conditional_range_bonus(c, context))


# --- Deck ---------------------------------------------------------------------------

func test_deck_holds_both_contributions() -> void:
	RelicEventDeck.build_deck("Russian-inspired", "Atlantean", 42)
	var deck := Fixture.state().shared_deck
	assert_eq(deck.size(), 14)
	for id in RelicEventRegistry.HANDLERS.keys():
		assert_true(deck.has(id), id)


func test_every_card_in_the_data_has_a_handler() -> void:
	for id in ContentDB.relic_events.keys():
		assert_true(RelicEventRegistry.HANDLERS.has(id), id)


func test_same_seed_same_order() -> void:
	RelicEventDeck.build_deck("Russian-inspired", "Atlantean", 42)
	var first := Fixture.state().shared_deck.duplicate()
	RelicEventDeck.build_deck("Russian-inspired", "Atlantean", 42)
	assert_eq(Fixture.state().shared_deck, first)


func test_full_slot_offers_keep_or_replace() -> void:
	_relic("p1", "r-reactor-core-fragment")
	Fixture.put(GYMNAST, Vector2i(0, 0))
	_draw("r-karpovas-black-key")
	var spec := RelicEventDeck.choice_spec("p1")
	assert_eq(spec.pick, "option")
	assert_eq(spec.options.size(), 2)
	assert_eq(_act("move", GYMNAST, {"to": Vector2i(0, 1)}).reason, "resolve the drawn card first")
	assert_true(_act("deck_choice", "p1", spec.options[0].payload).success)
	assert_eq(Fixture.state().get_player("p1").active_relic_id, "r-karpovas-black-key")


# --- Markers -------------------------------------------------------------------------

func test_leak_damages_the_first_character_to_enter_then_goes() -> void:
	var gymnast := Fixture.put(GYMNAST, Vector2i(3, 0))
	_leak(Vector2i(3, 2))
	assert_true(_act("move", GYMNAST, {"to": Vector2i(3, 3)}).success, "Leaks don't block movement")
	assert_eq(gymnast.current_hp, 1, "crossing it counts as entering")
	assert_false(sys.has_leak(Vector2i(3, 2)))
	assert_signal_emitted_with_parameters(EventBus, "leak_triggered", [GYMNAST, Vector2i(3, 2)])


func test_leak_does_not_block_line_of_sight() -> void:
	Fixture.put(SNIPER, Vector2i(3, 0))
	Fixture.put(CONDUCTOR, Vector2i(3, 3))
	_leak(Vector2i(3, 1))
	assert_true(RulesEngine.get_legal_attack_target_ids(SNIPER).has(CONDUCTOR))


func test_being_pushed_onto_a_leak_triggers_it() -> void:
	var conductor := Fixture.put(CONDUCTOR, Vector2i(3, 3))
	_leak(Vector2i(3, 4))
	_combat().apply_push(conductor, Vector2i(3, 2), 1)
	assert_eq(conductor.current_hp, 3)


func test_memory_blocks_one_damage_after_shields() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))    # HP 5
	assert_true(sys.give_memory(guard))
	assert_false(sys.give_memory(guard), "max 1")
	assert_signal_emit_count(EventBus, "memory_gained", 1)
	Fixture.shield(GUARD, 1)
	assert_eq(_combat().apply_damage(_c(SNIPER), guard, 3, false).damage, 1, "shield 1, then Memory 1")
	assert_false(guard.has_status("memory"))
	assert_false(guard.has_status("shield"))


func test_memory_is_kept_when_shields_absorb_everything() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	sys.give_memory(guard)
	Fixture.shield(GUARD, 2)
	_combat().apply_damage(_c(SNIPER), guard, 2, false)
	assert_true(guard.has_status("memory"))


# --- Closed City relics ----------------------------------------------------------------

func test_chintamani_reveals_then_top_or_bottom() -> void:
	_relic("p1", "r-chintamani-fragment")
	Fixture.state().shared_deck = ["r-reactor-prayer", "r-seventeen-seconds"] as Array[String]
	assert_eq(RelicEventDeck.power_spec("p1").card_id, "r-chintamani-fragment")
	var used := _act("use_relic", "p1", {})
	assert_eq(used.revealed, "r-reactor-prayer")
	assert_string_contains(RelicEventDeck.choice_spec("p1").prompt, "Reactor Prayer")
	assert_true(_act("deck_choice", "p1", {"to_bottom": true}).success)
	assert_eq(Fixture.state().shared_deck, ["r-seventeen-seconds", "r-reactor-prayer"] as Array[String])
	assert_eq(_act("use_relic", "p1", {}).reason, "no relic power available", "once each turn")


func test_reactor_core_fragment() -> void:
	_relic("p1", "r-reactor-core-fragment")
	var seer := Fixture.put(SEER, Vector2i(3, 0))
	assert_eq(sys.get_conditional_atk_bonus(seer), 1)
	assert_eq(sys.get_conditional_atk_bonus(Fixture.put(SNIPER, Vector2i(0, 0))), 0)
	_leak(Vector2i(3, 1))
	_act("move", SEER, {"to": Vector2i(3, 2)})
	assert_eq(sys.ability_reach(seer, 3), 4, "+1 RANGE on its next AP ability after Leak damage")


func test_karpovas_black_key_move_and_one_pass() -> void:
	_relic("p1", "r-karpovas-black-key")
	var general := Fixture.put(GENERAL, Vector2i(3, 0))       # MOVE 2 + 1
	Fixture.put(SNIPER, Vector2i(3, 1))                        # an ally in the way
	assert_eq(sys.get_move_bonus(general), 1)
	assert_true(RulesEngine.get_legal_move_tiles(GENERAL).has(Vector2i(3, 3)), "through the ally")
	assert_true(_act("move", GENERAL, {"to": Vector2i(3, 3)}).success)
	assert_true(Fixture.state().get_player("p1").player_flags_this_turn.get("black_key_used", false))
	Fixture.put(GYMNAST, Vector2i(0, 0))
	Fixture.board().place_object(Vector2i(0, 1), "barricade", "p2")
	assert_false(RulesEngine.get_legal_move_tiles(GYMNAST).has(Vector2i(0, 2)), "once each turn")


# --- Closed City events -----------------------------------------------------------------

func test_signal_array_turns_near_an_object_or_leak() -> void:
	var sniper := Fixture.put(SNIPER, Vector2i(3, 0))
	sniper.ability_uses_this_turn["moved"] = true             # no Aim: RANGE 4
	_draw("r-signal-array-turns")
	assert_eq(_range(sniper, "attack"), 4)
	_leak(Vector2i(2, 0))
	assert_eq(_range(sniper, "attack"), 5)
	Fixture.put(CONDUCTOR, Vector2i(3, 5))
	assert_true(_act("attack", SNIPER, {"target_id": CONDUCTOR}).success)
	assert_eq(_range(sniper, "attack"), 4, "first ranged attack only")


func test_reactor_prayer_hurts_then_boosts() -> void:
	var sniper := Fixture.put(SNIPER, Vector2i(3, 1))          # HP 3 ATK 2
	_draw("r-reactor-prayer")
	var spec := RelicEventDeck.choice_spec("p1")
	assert_eq(spec.pick, "character")
	assert_true(spec.characters.has(SNIPER))
	assert_true(_act("deck_choice", "p1", {"target_id": SNIPER, "boost": "atk"}).success)
	assert_eq(sniper.current_hp, 2)
	Fixture.put(CONDUCTOR, Vector2i(3, 3))
	assert_eq(_act("attack", SNIPER, {"target_id": CONDUCTOR}).damage, 3)


func test_closed_city_incident_places_two_leaks() -> void:
	_draw("r-closed-city-incident")
	var spec := RelicEventDeck.choice_spec("p1")
	assert_eq(spec.pick, "tiles")
	assert_eq(spec.count, 2)
	assert_true(spec.tiles.has(CENTER))
	assert_false(spec.tiles.has(Vector2i(0, 0)), "only within 2 of the center")
	assert_eq(_act("deck_choice", "p1", {"tiles": [CENTER, CENTER]}).reason,
			"choose different empty tiles within 2 of the center")
	assert_true(_act("deck_choice", "p1", {"tiles": [CENTER, Vector2i(3, 2)]}).success)
	assert_true(sys.has_leak(CENTER))
	assert_true(sys.has_leak(Vector2i(3, 2)))


func test_seventeen_seconds_first_move_passes_one_thing() -> void:
	Fixture.put(SNIPER, Vector2i(3, 0))                        # MOVE 2
	Fixture.put(CONDUCTOR, Vector2i(3, 1))                     # an enemy in the way
	_draw("r-seventeen-seconds")
	assert_true(_act("move", SNIPER, {"to": Vector2i(3, 2)}).success, "through the enemy")
	Fixture.put(GYMNAST, Vector2i(0, 3))
	Fixture.put(GUARD, Vector2i(0, 4))
	assert_false(RulesEngine.get_legal_move_tiles(GYMNAST).has(Vector2i(0, 5)), "first move only")


func test_seventeen_seconds_crosses_a_leak_safely() -> void:
	var gymnast := Fixture.put(GYMNAST, Vector2i(3, 0))
	_leak(Vector2i(3, 1))
	_draw("r-seventeen-seconds")
	_act("move", GYMNAST, {"to": Vector2i(3, 2)})
	assert_eq(gymnast.current_hp, 2)
	assert_true(sys.has_leak(Vector2i(3, 1)), "the Leak stays for someone else")


# --- Flood Survivors relics ---------------------------------------------------------------

func test_emerald_tablet_after_gaining_memory() -> void:
	_relic("p2", "a-flood-survivor-emerald-tablet")
	_act("end_turn", "p1")
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	Fixture.board().place_object(Vector2i(3, 4), "stone", "p2")
	assert_eq(RelicEventDeck.power_spec("p2"), {}, "not ready until triggered")
	sys.give_memory(guard)
	assert_true(RelicEventDeck.power_spec("p2").characters.has(GUARD))
	assert_true(_act("use_relic", "p2", {"target_id": GUARD, "boost": "shield"}).success)
	assert_eq(guard.sum_status("shield"), 1)
	assert_eq(RelicEventDeck.power_spec("p2"), {}, "once each turn")


func test_black_sarcophagus() -> void:
	_relic("p2", "a-flood-survivor-black-sarcophagus")
	assert_eq(sys.get_effective_max_hp(_c(GUARD)), 6)
	assert_eq(sys.get_effective_max_hp(_c(CONDUCTOR)), 4, "not a Warrior or Hero")
	var sniper := Fixture.put(SNIPER, Vector2i(3, 1))
	Fixture.board().place_object(Vector2i(3, 0), "stone", "p2")
	Fixture.put(CONDUCTOR, Vector2i(3, 3))
	_act("attack", SNIPER, {"target_id": CONDUCTOR})
	assert_true(sniper.has_status("marked"), "attacked from next to a p2 object")


func test_tide_sealed_archive() -> void:
	_relic("p2", "a-flood-survivor-tide-sealed-archive")
	var conductor := Fixture.put(CONDUCTOR, Vector2i(3, 3))    # Leader RANGE 3
	assert_eq(sys.ability_reach(conductor, 3), 4)
	var guard := Fixture.put(GUARD, Vector2i(5, 5))
	sys.give_memory(guard)
	assert_true(guard.ability_uses_this_turn.get("free_move_available", false), "may move 1 tile")


# --- Flood Survivors events ----------------------------------------------------------------

func test_the_causeway_breathes() -> void:
	_act("end_turn", "p1")
	_draw("a-flood-survivor-the-causeway-breathes", "p2")
	var spec := RelicEventDeck.choice_spec("p2")
	assert_eq(spec.pick, "tiles")
	assert_eq(spec.count, 1)
	assert_true(_act("deck_choice", "p2", {"tiles": [CENTER]}).success)
	var stone := Fixture.board().get_placed_object(CENTER)
	assert_eq(stone.type_id, "stone")
	assert_eq(stone.owner_player_id, "p2")
	Fixture.put(GUARD, Vector2i(3, 4))
	assert_true(RulesEngine.get_legal_move_tiles(GUARD).has(Vector2i(3, 2)), "first move passes the object")


func test_black_water_remembers() -> void:
	_act("end_turn", "p1")
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	Fixture.board().place_object(Vector2i(3, 4), "stone", "p2")
	_draw("a-flood-survivor-black-water-remembers", "p2")
	var spec := RelicEventDeck.choice_spec("p2")
	assert_eq(spec.pick, "character_tile")
	assert_eq(spec.characters, [GUARD])
	assert_true(spec.tiles_by_character[GUARD].has(Vector2i(2, 3)))
	assert_true(_act("deck_choice", "p2", {"target_id": GUARD, "to": Vector2i(2, 3)}).success)
	assert_true(guard.has_status("memory"))
	assert_eq(guard.position, Vector2i(2, 3))


func test_black_water_with_nobody_eligible_resolves_at_once() -> void:
	_draw("a-flood-survivor-black-water-remembers", "p1")
	assert_false(RelicEventDeck.has_pending_choice("p1"))


func test_the_flood_reaches_the_walls() -> void:
	var edge := Fixture.put(GYMNAST, Vector2i(0, 3))
	var middle := Fixture.put(SNIPER, Vector2i(3, 3))
	var enemy_edge := Fixture.put(GUARD, Vector2i(6, 6))
	_draw("a-flood-survivor-the-flood-reaches-the-walls")
	assert_true(edge.has_status("marked"))
	assert_true(enemy_edge.has_status("marked"), "every character on the edge")
	assert_false(middle.has_status("marked"))


func test_the_drowned_seraph_speaks() -> void:
	_act("end_turn", "p1")
	Fixture.put(HARMONIC, Vector2i(3, 3))
	_draw("a-flood-survivor-the-drowned-seraph-speaks", "p2")
	_act("end_turn", "p2")
	var sniper := Fixture.put(SNIPER, Vector2i(3, 1))
	var gymnast := Fixture.put(GYMNAST, Vector2i(3, 4))
	_act("attack", SNIPER, {"target_id": HARMONIC})
	assert_true(sniper.has_status("marked"), "the first enemy to damage the Mystic")
	_act("attack", GYMNAST, {"target_id": HARMONIC})
	assert_false(gymnast.has_status("marked"), "only the first")
