extends GutTest
# RelicEventDeck and the original 14 relic/event cards (LLD-relic-event-deck.md, cases
# C1–C12 plus every card's effect), with the real deck wired into TurnManager.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const SNIPER := Fixture.SNIPER       # RANGE 4
const GYMNAST := Fixture.GYMNAST
const GENERAL := Fixture.GENERAL     # Leader HP 5
const BOGATYR := Fixture.BOGATYR     # Hero HP 6
const GUARD := Fixture.GUARD         # Warrior HP 5
const CONDUCTOR := Fixture.CONDUCTOR
const SEER := "p1_r-seer"            # RANGE 3

var sys: AbilitySystem


func before_each() -> void:
	autofree(Fixture.start_match())
	TurnManager.relic_event_deck = null        # the real deck from here on
	Fixture.state().shared_deck.clear()        # SetupFlow built a real deck; tests stack their own
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


# Puts `card_id` on top of the deck and has p1 draw it.
func _draw(card_id: String, player_id: String = "p1") -> void:
	Fixture.state().shared_deck.push_front(card_id)
	RelicEventDeck.draw_for(player_id)


func _relic(player_id: String, card_id: String) -> void:
	Fixture.state().get_player(player_id).active_relic_id = card_id


func _range(id: String, context: String) -> int:
	var c := _c(id)
	return c.get_effective_range(context, sys.get_conditional_range_bonus(c, context))


# Ends p1's turn and p2's, back to p1.
func _next_p1_turn() -> void:
	_act("end_turn", "p1")
	_act("end_turn", "p2")


# --- Deck construction and drawing ------------------------------------------------

func test_c1_deck_holds_both_contributions() -> void:
	RelicEventDeck.build_deck("Russian-inspired", "Atlantean", 42)
	var deck := Fixture.state().shared_deck
	assert_eq(deck.size(), 14)
	for id in ["r-winter-palace-standard", "r-iron-birch-talisman", "r-generals-war-map",
			"r-whiteout", "r-frozen-center", "r-rally-from-the-snow", "r-long-winter-march",
			"a-quartz-heart-core", "a-hall-of-shared-minds", "a-tideglass-obelisk",
			"a-resonance-surge", "a-psychic-undertow", "a-crystal-tide", "a-dream-of-the-deep-city"]:
		assert_true(deck.has(id), id)


func test_c2_same_seed_same_order() -> void:
	RelicEventDeck.build_deck("Russian-inspired", "Atlantean", 42)
	var first := Fixture.state().shared_deck.duplicate()
	RelicEventDeck.build_deck("Russian-inspired", "Atlantean", 42)
	assert_eq(Fixture.state().shared_deck, first)
	RelicEventDeck.build_deck("Russian-inspired", "Atlantean", 7)
	assert_ne(Fixture.state().shared_deck, first, "a different seed shuffles differently")


func test_a_real_match_builds_the_deck_and_draws_on_turn_one() -> void:
	Fixture.teardown()
	var setup: Node = autofree(Fixture.SetupFlowScript.new())
	setup.select_culture("p1", "Russian-inspired")
	setup.select_culture("p2", "Atlantean")
	for id in ["p1", "p2"]:
		var x := 0
		for c in setup.get_player(id).characters:
			setup.place_character(id, c.instance_id, Vector2i(x, 0 if id == "p1" else 6))
			x += 1
	setup.start_match()
	assert_eq(Fixture.state().shared_deck.size(), 13, "p1 drew on turn 1")
	assert_signal_emit_count(EventBus, "relic_drawn", 1)


func test_c10_empty_deck_draws_nothing() -> void:
	Fixture.state().shared_deck.clear()
	RelicEventDeck.draw_for("p1")
	assert_signal_not_emitted(EventBus, "relic_drawn")


# --- Relic slot ---------------------------------------------------------------------

func test_c3_relic_into_an_empty_slot() -> void:
	_draw("r-winter-palace-standard")
	assert_eq(Fixture.state().get_player("p1").active_relic_id, "r-winter-palace-standard")
	assert_signal_emitted_with_parameters(EventBus, "relic_slot_changed", ["p1", "r-winter-palace-standard"])
	assert_false(RelicEventDeck.has_pending_choice("p1"))


func test_c4_c5_full_slot_asks_and_can_replace() -> void:
	_relic("p1", "r-iron-birch-talisman")
	_draw("r-winter-palace-standard")
	assert_eq(Fixture.state().get_player("p1").active_relic_id, "r-iron-birch-talisman")
	assert_true(RelicEventDeck.has_pending_choice("p1"))
	Fixture.put(GYMNAST, Vector2i(3, 3))
	assert_eq(_act("move", GYMNAST, {"to": Vector2i(3, 4)}).reason, "resolve the drawn card first")
	assert_eq(_act("deck_choice", "p1", {"keep_new": true}), {"success": true})
	assert_eq(Fixture.state().get_player("p1").active_relic_id, "r-winter-palace-standard")
	assert_true(_act("move", GYMNAST, {"to": Vector2i(3, 4)}).success)


func test_c6_full_slot_can_keep_the_old_relic() -> void:
	_relic("p1", "r-iron-birch-talisman")
	_draw("r-winter-palace-standard")
	assert_eq(_act("deck_choice", "p1", {"keep_new": false}), {"success": true})
	assert_eq(Fixture.state().get_player("p1").active_relic_id, "r-iron-birch-talisman")


func test_deck_choice_validation() -> void:
	assert_eq(_act("deck_choice", "p1", {"keep_new": true}).reason, "nothing to choose")
	_relic("p1", "r-iron-birch-talisman")
	_draw("r-winter-palace-standard")
	assert_eq(_act("deck_choice", "p1", {}).reason, "choose keep_new true or false")
	assert_eq(_act("deck_choice", "p2", {"keep_new": true}).reason, "not your turn")


func test_replacing_a_hp_relic_trims_hp_to_the_new_max() -> void:
	var general := Fixture.put(GENERAL, Vector2i(3, 3))    # Leader HP 5
	_draw("r-winter-palace-standard")
	general.current_hp = 6
	_draw("r-iron-birch-talisman")
	_act("deck_choice", "p1", {"keep_new": true})
	assert_eq(general.current_hp, 5)


# --- Relic effects ------------------------------------------------------------------

func test_c11_c12_winter_palace_standard() -> void:
	_relic("p1", "r-winter-palace-standard")
	assert_eq(sys.get_effective_max_hp(_c(BOGATYR)), 7)
	assert_eq(sys.get_effective_max_hp(_c(GENERAL)), 6)
	assert_eq(sys.get_effective_max_hp(_c(SNIPER)), 3, "not a Hero or Leader")
	assert_eq(sys.get_effective_max_hp(_c(Fixture.ORACLE)), 5, "the owner's characters only")


func test_iron_birch_talisman() -> void:
	_relic("p1", "r-iron-birch-talisman")
	assert_eq(sys.get_effective_max_hp(_c(GYMNAST)), 3)
	assert_eq(sys.get_effective_max_hp(_c(SNIPER)), 4)
	assert_eq(sys.get_effective_max_hp(_c(GENERAL)), 5)


func test_generals_war_map_once_per_turn() -> void:
	_relic("p1", "r-generals-war-map")
	_next_p1_turn()
	var sniper := Fixture.put(SNIPER, Vector2i(3, 0))
	sniper.ability_uses_this_turn["moved"] = true     # no Aim: RANGE 4
	Fixture.put(CONDUCTOR, Vector2i(3, 5))
	assert_true(_act("reactive_bonus", SNIPER, {"tag": "generals_war_map"}).success)
	assert_eq(_range(SNIPER, "attack"), 5)
	assert_eq(_act("attack", SNIPER, {"target_id": CONDUCTOR}).damage, 2)
	assert_eq(_range(SNIPER, "attack"), 4, "spent by the attack")
	Fixture.put(GYMNAST, Vector2i(6, 0))
	assert_eq(_act("reactive_bonus", GYMNAST, {"tag": "generals_war_map"}).reason, "no bonus action available",
			"once per turn")
	assert_false(Fixture.state().get_player("p1").player_flags_this_turn.has("generals_war_map_available"))


func test_quartz_heart_core_adds_one_to_shields() -> void:
	_relic("p2", "a-quartz-heart-core")
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	Fixture.shield(GUARD, 1)
	var combat := RulesEngine.systems().combat as CombatResolver
	assert_eq(combat.apply_damage(_c(SNIPER), guard, 3, false).damage, 1, "1 shield + 1 bonus")
	assert_false(guard.has_status("shield"), "the shield itself is used up")
	assert_eq(combat.apply_damage(_c(SNIPER), guard, 2, false).damage, 2, "no shield, no bonus")


func test_hall_of_shared_minds_formation_bonus() -> void:
	# Designer ruling 2026-09-27: adjacent to another friendly character.
	_relic("p2", "a-hall-of-shared-minds")
	var harmonic := Fixture.put("p2_a-harmonic", Vector2i(3, 3))
	assert_eq(_range("p2_a-harmonic", "ability"), 3)
	Fixture.put(GUARD, Vector2i(3, 4))
	assert_eq(_range("p2_a-harmonic", "ability"), 4)
	assert_eq(_range("p2_a-harmonic", "attack"), 3, "abilities only")
	Fixture.put(GUARD, Vector2i(6, 6))
	Fixture.put(SNIPER, Vector2i(3, 4))
	assert_eq(_range("p2_a-harmonic", "ability"), 3, "an enemy neighbor doesn't count")


func test_tideglass_obelisk_next_to_any_object() -> void:
	_relic("p2", "a-tideglass-obelisk")
	Fixture.put(CONDUCTOR, Vector2i(3, 3))                  # RANGE 3
	Fixture.board().place_object(Vector2i(3, 4), "barricade", "p1")
	assert_eq(_range(CONDUCTOR, "attack"), 4)
	assert_eq(_range(CONDUCTOR, "ability"), 4)


# --- Events -------------------------------------------------------------------------

func test_c8_c9_whiteout_hits_both_players_for_a_round() -> void:
	# Designer ruling 2026-09-27: both players.
	Fixture.put(SNIPER, Vector2i(0, 0))
	Fixture.put(CONDUCTOR, Vector2i(6, 6))
	_draw("r-whiteout")
	assert_eq(_range(CONDUCTOR, "attack"), 2)
	_c(SNIPER).ability_uses_this_turn["moved"] = true
	assert_eq(_range(SNIPER, "attack"), 3)
	assert_eq(_range(GYMNAST, "attack"), 1, "minimum 1")
	_act("end_turn", "p1")
	assert_eq(_range(CONDUCTOR, "attack"), 2, "still on during the opponent's turn")
	_act("end_turn", "p2")
	assert_eq(_range(CONDUCTOR, "attack"), 3, "gone after a full round")


func test_frozen_center_freezes_the_middle_row_for_a_round() -> void:
	Fixture.board().get_tile(Vector2i(0, 3)).terrain_type = "frost"   # from Frozen Redoubt
	_draw("r-frozen-center")
	for x in 7:
		assert_eq(Fixture.board().get_tile(Vector2i(x, 3)).terrain_type, "frost")
	Fixture.put(GYMNAST, Vector2i(3, 2))
	assert_false(RulesEngine.get_legal_move_tiles(GYMNAST).has(Vector2i(3, 4)), "stops on the row")
	_next_p1_turn()
	assert_eq(Fixture.board().get_tile(Vector2i(3, 3)).terrain_type, "")
	assert_eq(Fixture.board().get_tile(Vector2i(0, 3)).terrain_type, "frost", "earlier frost stays")


func test_c7_rally_from_the_snow_heals_a_chosen_character() -> void:
	var sniper := Fixture.put(SNIPER, Vector2i(3, 3))
	sniper.current_hp = 1
	_draw("r-rally-from-the-snow")
	assert_true(RelicEventDeck.has_pending_choice("p1"))
	assert_eq(_act("deck_choice", "p1", {"target_id": GYMNAST}).reason, "choose one of your damaged characters")
	assert_true(_act("deck_choice", "p1", {"target_id": SNIPER}).success)
	assert_eq(sniper.current_hp, 2)
	assert_signal_emitted_with_parameters(EventBus, "event_resolved", ["r-rally-from-the-snow"])


func test_rally_with_nobody_hurt_resolves_at_once() -> void:
	Fixture.put(SNIPER, Vector2i(3, 3))
	_draw("r-rally-from-the-snow")
	assert_false(RelicEventDeck.has_pending_choice("p1"))


func test_long_winter_march_first_move_only() -> void:
	var general := Fixture.put(GENERAL, Vector2i(3, 0))     # MOVE 2
	var sniper := Fixture.put(SNIPER, Vector2i(0, 0))
	_draw("r-long-winter-march")
	assert_true(_act("move", GENERAL, {"to": Vector2i(3, 3)}).success, "3 tiles")
	assert_false(RulesEngine.get_legal_move_tiles(SNIPER).has(Vector2i(0, 3)), "only the first move")


func test_resonance_surge_first_ability_only() -> void:
	_act("end_turn", "p1")
	Fixture.put("p2_a-harmonic", Vector2i(3, 6))            # Resonance Shield reach 3
	Fixture.put(GUARD, Vector2i(3, 2))                      # 4 tiles
	Fixture.put(CONDUCTOR, Vector2i(4, 6))
	_draw("a-resonance-surge", "p2")
	assert_true(_act("ability", "p2_a-harmonic", {"ability_id": "a-harmonic", "target": GUARD}).success)
	assert_eq(_range(CONDUCTOR, "ability"), 3, "spent by the first ability")


func test_psychic_undertow_push_or_pull() -> void:
	Fixture.put(SNIPER, Vector2i(3, 0))
	var conductor := Fixture.put(CONDUCTOR, Vector2i(3, 3))
	_draw("a-psychic-undertow")
	assert_true(_act("attack", SNIPER, {"target_id": CONDUCTOR, "undertow": "pull"}).success)
	assert_eq(conductor.position, Vector2i(3, 2))
	assert_eq(_act("attack", Fixture.BOGATYR, {"target_id": CONDUCTOR, "undertow": "push"}).reason,
			"no Psychic Undertow this turn", "first attack only")


func test_psychic_undertow_push() -> void:
	Fixture.put(Fixture.BOGATYR, Vector2i(3, 2))
	var conductor := Fixture.put(CONDUCTOR, Vector2i(3, 3))
	_draw("a-psychic-undertow")
	_act("attack", Fixture.BOGATYR, {"target_id": CONDUCTOR, "undertow": "push"})
	assert_eq(conductor.position, Vector2i(3, 4))


func test_crystal_tide_abilities_only_this_turn() -> void:
	Fixture.put(SEER, Vector2i(3, 3))
	_draw("a-crystal-tide")
	assert_eq(_range(SEER, "ability"), 4)
	assert_eq(_range(SEER, "attack"), 3)
	assert_eq(sys.ability_reach(_c(SEER), 3), 4)
	_act("end_turn", "p1")
	assert_eq(_range(SEER, "ability"), 3)


func test_dream_of_the_deep_city_choice() -> void:
	Fixture.state().shared_deck = ["x", "y"] as Array[String]
	_draw("a-dream-of-the-deep-city")
	assert_eq(RelicEventDeck.get_pending_choice("p1").revealed, "x")
	assert_true(_act("deck_choice", "p1", {"to_bottom": true}).success)
	assert_eq(Fixture.state().shared_deck, ["y", "x"] as Array[String])


func test_c9_one_turn_events_last_the_turn_they_are_drawn() -> void:
	# TurnManager draws before announcing the turn; the duration must not tick then.
	Fixture.put(SEER, Vector2i(3, 3))
	_act("end_turn", "p1")
	Fixture.state().shared_deck = ["a-crystal-tide"] as Array[String]
	_act("end_turn", "p2")                                 # p1 draws Crystal Tide
	assert_true(RelicEventDeck.is_active("a-crystal-tide"), "lasts the turn it was drawn")
	assert_eq(_range(SEER, "ability"), 4)
	_act("end_turn", "p1")
	assert_false(RelicEventDeck.is_active("a-crystal-tide"))
	assert_eq(_range(SEER, "ability"), 3)
