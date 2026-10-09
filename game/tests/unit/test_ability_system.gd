extends GutTest
# AbilitySystem framework — shared mechanics every handler relies on
# (LLD-ability-system.md 3.3, 4.1). Per-card behavior is in test_abilities_*.gd.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const GYMNAST := Fixture.GYMNAST
const SNIPER := Fixture.SNIPER
const GENERAL := Fixture.GENERAL
const BOGATYR := Fixture.BOGATYR
const GUARD := Fixture.GUARD
const ATTENDANT := Fixture.ATTENDANT

var sys: AbilitySystem


func before_each() -> void:
	autofree(Fixture.start_match())
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


func test_every_original_card_has_a_handler() -> void:
	for p in Fixture.state().players:
		for c in p.characters:
			assert_true(AbilityRegistry.HANDLERS.has(c.data.id), c.data.id)


func test_unknown_card_gets_the_no_effect_handler() -> void:
	var handler := AbilityRegistry.get_handler("x-nobody")
	assert_push_error("x-nobody")
	assert_not_null(handler)


func test_free_move_bonus_moves_one_tile_without_ap() -> void:
	var sniper := Fixture.put(SNIPER, Vector2i(3, 3))
	sniper.character_ap_remaining = 0
	sys.offer_bonus(sniper, "free_move")
	assert_true(_act("reactive_bonus", SNIPER, {"tag": "free_move", "to": Vector2i(3, 4)}).success)
	assert_eq(sniper.position, Vector2i(3, 4))
	assert_true(sniper.ability_uses_this_turn.get("moved", false), "a free move is still a move")
	assert_signal_emitted_with_parameters(EventBus, "character_moved", [SNIPER, Vector2i(3, 3), Vector2i(3, 4)])
	assert_eq(_act("reactive_bonus", SNIPER, {"tag": "free_move", "to": Vector2i(3, 5)}).reason,
			"no bonus action available", "single use")


func test_free_move_rejects_more_than_one_tile() -> void:
	var sniper := Fixture.put(SNIPER, Vector2i(3, 3))
	sys.offer_bonus(sniper, "free_move")
	assert_eq(_act("reactive_bonus", SNIPER, {"tag": "free_move", "to": Vector2i(3, 5)}).reason, "illegal move")


func test_granted_los_exception_ignores_one_ally() -> void:
	var sniper := Fixture.put(SNIPER, Vector2i(3, 0))   # RANGE 4
	Fixture.put(GYMNAST, Vector2i(3, 1))
	Fixture.put(GUARD, Vector2i(3, 3))
	assert_false(RulesEngine.get_legal_attack_target_ids(SNIPER).has(GUARD))
	sys.add_status(sniper, "los_ignore_ally_granted", 1, "this_turn")
	assert_true(RulesEngine.get_legal_attack_target_ids(SNIPER).has(GUARD))


func test_range_override_applies_to_abilities_only_and_never_shortens() -> void:
	var general := Fixture.put(GENERAL, Vector2i(3, 3))   # RANGE 1
	sys.add_status(general, "range_override", 3, "this_turn")
	assert_eq(general.get_effective_range("ability", sys.get_conditional_range_bonus(general, "ability")), 3)
	assert_eq(general.get_effective_range("attack", sys.get_conditional_range_bonus(general, "attack")), 1)
	var sniper := Fixture.put(SNIPER, Vector2i(0, 0))     # RANGE 4
	sys.add_status(sniper, "range_override", 3, "this_turn")
	assert_eq(sniper.get_effective_range("ability", sys.get_conditional_range_bonus(sniper, "ability")), 4)


func test_ability_reach_adds_bonuses_to_the_printed_reach() -> void:
	var general := Fixture.put(GENERAL, Vector2i(3, 3))
	assert_eq(sys.ability_reach(general, 2), 2)
	sys.add_status(general, "temp_range", 1, "this_turn")
	assert_eq(sys.ability_reach(general, 2), 3)
	sys.add_status(general, "range_override", 4, "this_turn")
	assert_eq(sys.ability_reach(general, 2), 4)


func test_consume_on_attack_buff_is_spent_by_the_next_attack() -> void:
	var sniper := Fixture.put(SNIPER, Vector2i(3, 1))
	Fixture.put(Fixture.CONDUCTOR, Vector2i(3, 3))   # no Quartz Armor
	sys.add_status(sniper, "temp_atk", 1, "this_turn", null, true)
	sys.add_status(sniper, "temp_atk", 1, "this_turn")
	assert_eq(_act("attack", SNIPER, {"target_id": Fixture.CONDUCTOR}).damage, 4, "ATK 2 + both buffs")
	assert_eq(sniper.sum_status("temp_atk"), 1, "only the single-use buff is gone")


func test_level_up_bakes_bonuses_and_restores_full_hp() -> void:
	# Designer ruling 2026-10-06: every level-up restores the character to full HP.
	var gymnast := _c(GYMNAST)          # L2: +1 MOVE, no HP
	gymnast.current_hp = 1
	sys.apply_level_up_effects(gymnast, 2)
	assert_eq(gymnast.move_bonus, 1)
	assert_eq(gymnast.current_hp, 2, "healed to full even with no HP bonus")
	var tiger := _c(Fixture.TIGER)      # L2: +1 HP, +1 MOVE
	tiger.current_hp = 1
	sys.apply_level_up_effects(tiger, 2)
	assert_eq(tiger.base_max_hp, 5)
	assert_eq(tiger.current_hp, 5)


func test_level_up_heals_to_the_effective_maximum() -> void:
	# Relic bonuses count: The Black Sarcophagus gives your Warrior +1 maximum HP.
	Fixture.state().get_player("p1").active_relic_id = "a-flood-survivor-black-sarcophagus"
	var sniper := _c(SNIPER)            # Warrior, HP 3
	sniper.current_hp = 1
	sys.apply_level_up_effects(sniper, 3)
	assert_eq(sniper.current_hp, sys.get_effective_max_hp(sniper))
	assert_eq(sniper.current_hp, 4)


func test_deck_peek_and_move_to_bottom() -> void:
	Fixture.state().shared_deck = ["a", "b", "c"] as Array[String]
	assert_eq(RelicEventDeck.peek_next(), "a")
	RelicEventDeck.move_top_to_bottom()
	assert_eq(Fixture.state().shared_deck, ["b", "c", "a"] as Array[String])



func test_max_hp_rise_lifts_a_full_character_only() -> void:
	# Designer ruling 2026-10-09: at full HP, current HP rises with max HP; a damaged
	# character keeps its HP. The Black Sarcophagus gives Warriors +1 maximum HP.
	var sniper := _c(SNIPER)                       # Warrior, HP 3, full
	var guard := _c(Fixture.GUARD)                 # p2 Warrior, HP 5
	guard.current_hp = 3
	Fixture.state().get_player("p1").active_relic_id = "a-flood-survivor-black-sarcophagus"
	Fixture.state().get_player("p2").active_relic_id = "a-flood-survivor-black-sarcophagus"
	sys.sync_all_max_hp()
	assert_eq(sniper.current_hp, 4, "full: rises to the new maximum")
	assert_eq(guard.current_hp, 3, "damaged: unchanged")
	Fixture.state().get_player("p1").active_relic_id = ""
	sys.sync_all_max_hp()
	assert_eq(sniper.current_hp, 3, "trimmed when the maximum falls")


func test_max_hp_syncs_after_every_action() -> void:
	var sniper := _c(SNIPER)
	Fixture.state().get_player("p1").active_relic_id = "a-flood-survivor-black-sarcophagus"
	RulesEngine.request_action("end_turn", "p1", {})
	assert_eq(sniper.current_hp, 4)
