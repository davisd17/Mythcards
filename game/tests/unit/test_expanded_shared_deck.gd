extends GutTest

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const COMMON := "p1_r-gymnast"
const ENEMY_COMMON := "p2_a-attendant"
const SPECIALIST := "p1_r-engineer"
const MYSTIC := "p1_r-seer"
const WARRIOR := "p1_r-sniper"
const MOUNT := "p1_r-tiger"
var sys: AbilitySystem


func before_each() -> void:
	autofree(Fixture.start_match())
	Fixture.clear_board()
	Fixture.state().shared_deck.clear()
	Fixture.state().get_player("p1").pool_ap_remaining = 4
	TurnManager.relic_event_deck = null
	sys = RulesEngine.systems().ability
	RelicEventDeck.build_deck("Russian-inspired", "Atlantean", 42)
	Fixture.state().shared_deck.clear()


func after_each() -> void:
	sys = null
	Fixture.teardown()


func _act(action: String, actor: String, payload: Dictionary = {}) -> Dictionary:
	return RulesEngine.request_action(action, actor, payload)


func _relic(id: String) -> void:
	Fixture.state().get_player("p1").active_relic_id = id


func _draw(id: String) -> void:
	Fixture.state().shared_deck.push_front(id)
	RelicEventDeck.draw_for("p1")


func test_dream_monitors_swaps_both_commons_for_no_ap() -> void:
	var a := Fixture.put(COMMON, Vector2i(0, 1))
	var b := Fixture.put(ENEMY_COMMON, Vector2i(6, 5))
	_draw("r-dream-monitors-synchronize")
	assert_true(_act("deck_choice", "p1", {"swap": true}).success)
	assert_eq(a.position, Vector2i(6, 5))
	assert_eq(b.position, Vector2i(0, 1))
	assert_eq(Fixture.board().get_tile(a.position).occupant_id, COMMON)
	assert_eq(Fixture.state().get_player("p1").pool_ap_remaining, 4)


func test_dream_monitors_may_be_declined_and_needs_both_commons() -> void:
	var a := Fixture.put(COMMON, Vector2i(0, 1))
	Fixture.put(ENEMY_COMMON, Vector2i(6, 5))
	_draw("r-dream-monitors-synchronize")
	assert_true(_act("deck_choice", "p1", {"swap": false}).success)
	assert_eq(a.position, Vector2i(0, 1))
	Fixture.character(ENEMY_COMMON).defeated = true
	_draw("r-dream-monitors-synchronize")
	assert_false(RelicEventDeck.has_pending_choice("p1"))


func test_exiles_moves_two_distinct_allies_for_no_ap_and_can_skip() -> void:
	var a := Fixture.put(COMMON, Vector2i(1, 1))
	var b := Fixture.put(SPECIALIST, Vector2i(2, 2))
	Fixture.board().place_object(Vector2i(1, 2), "stone", "p1")
	_draw("a-flood-survivor-exiles-walk-beneath-egypt")
	assert_true(_act("deck_choice", "p1", {"target_id": COMMON, "to": Vector2i(2, 1)}).success)
	assert_true(RelicEventDeck.has_pending_choice("p1"))
	assert_false(_act("deck_choice", "p1", {"target_id": COMMON, "to": Vector2i(3, 1)}).success)
	assert_true(_act("deck_choice", "p1", {"target_id": SPECIALIST, "to": Vector2i(3, 2)}).success)
	assert_false(RelicEventDeck.has_pending_choice("p1"))
	assert_eq(a.position, Vector2i(2, 1))
	assert_eq(b.position, Vector2i(3, 2))
	assert_eq(Fixture.state().get_player("p1").pool_ap_remaining, 4)
	_draw("a-flood-survivor-exiles-walk-beneath-egypt")
	if RelicEventDeck.has_pending_choice("p1"):
		assert_true(_act("deck_choice", "p1", {}).success)


func test_helmet_grants_hp_and_prevents_marks_only_for_mount_and_warrior() -> void:
	_relic("r-cosmonaut-helmet-second-shadow")
	for id in [MOUNT, WARRIOR]:
		var c := Fixture.put(id, Vector2i(1, 1) if id == MOUNT else Vector2i(2, 1))
		assert_eq(sys.get_effective_max_hp(c), c.base_max_hp + 1)
		sys.add_status(c, "marked", 1, "until_used")
		assert_false(c.has_status("marked"))
	var c := Fixture.put(COMMON, Vector2i(3, 1))
	sys.add_status(c, "marked", 1, "until_used")
	assert_true(c.has_status("marked"))
	_relic("")
	sys.add_status(Fixture.character(WARRIOR), "marked", 1, "until_used")
	assert_true(Fixture.character(WARRIOR).has_status("marked"))


func test_notebook_boosts_attacks_and_abilities_for_only_leader_and_specialist() -> void:
	_relic("r-lead-sealed-notebook")
	for id in ["p1_r-general", SPECIALIST]:
		var c := Fixture.character(id)
		assert_eq(sys.get_conditional_range_bonus(c, "attack"), 1)
		assert_eq(sys.ability_reach(c, 3), 4)
	assert_eq(sys.get_conditional_range_bonus(Fixture.character(MYSTIC), "attack"), 0)


func test_compass_passes_only_one_allied_object_on_every_movement() -> void:
	_relic("a-flood-survivor-basalt-ley-compass")
	Fixture.put(SPECIALIST, Vector2i(0, 2))
	Fixture.board().place_object(Vector2i(1, 2), "stone", "p1")
	Fixture.board().place_object(Vector2i(3, 2), "stone", "p1")
	assert_eq(sys.get_move_bonus(Fixture.character(SPECIALIST)), 1)
	assert_true(RulesEngine.get_legal_move_tiles(SPECIALIST).has(Vector2i(2, 2)))
	assert_false(sys.moves_for(Fixture.character(SPECIALIST), 5).has(Vector2i(4, 2)))
	assert_true(_act("move", SPECIALIST, {"to": Vector2i(2, 2)}).success)
	Fixture.character(SPECIALIST).character_ap_remaining = 1
	assert_true(RulesEngine.get_legal_move_tiles(SPECIALIST).has(Vector2i(4, 2)), "pass resets each movement")
	Fixture.board().get_placed_object(Vector2i(3, 2)).owner_player_id = "p2"
	assert_false(RulesEngine.get_legal_move_tiles(SPECIALIST).has(Vector2i(4, 2)))


func test_veil_owner_can_choose_shield_during_opponents_turn_once_per_round() -> void:
	_relic("a-flood-survivor-seraphic-burial-veil")
	var mystic := Fixture.put(MYSTIC, Vector2i(1, 1))
	assert_eq(sys.get_effective_max_hp(mystic), mystic.base_max_hp + 1)
	_act("end_turn", "p1")
	sys.add_status(mystic, "marked", 1, "until_used")
	assert_eq(RelicEventDeck.decision_player(), "p1")
	assert_false(_act("end_turn", "p2").success)
	assert_true(_act("deck_choice", "p1", {"protect": true}).success)
	assert_false(mystic.has_status("marked"))
	assert_true(mystic.has_status("shield"))
	sys.add_status(mystic, "marked", 1, "until_used")
	assert_true(mystic.has_status("marked"), "only one conversion in the round")
	assert_eq(RelicEventDeck.decision_player(), "p2")


func test_veil_may_be_declined_without_spending_protection() -> void:
	_relic("a-flood-survivor-seraphic-burial-veil")
	var mystic := Fixture.put(MYSTIC, Vector2i(1, 1))
	sys.add_status(mystic, "marked", 1, "until_used")
	assert_true(_act("deck_choice", "p1", {"protect": false}).success)
	assert_true(mystic.has_status("marked"))
	sys.add_status(mystic, "marked", 1, "until_used")
	assert_true(RelicEventDeck.has_pending_choice("p1"))
	assert_true(_act("deck_choice", "p1", {"protect": true}).success)
	assert_eq(mystic.sum_status("marked"), 1, "does not remove the earlier accepted Mark")


func test_duration_event_copies_expire_independently() -> void:
	var mystic := Fixture.put(MYSTIC, Vector2i(1, 1))
	_draw("a-flood-survivor-the-drowned-seraph-speaks")
	_draw("a-flood-survivor-the-drowned-seraph-speaks")
	assert_eq(mystic.sum_status("temp_atk"), 2)
	assert_eq(RelicEventDeck.active_event_ids().size(), 2)
	_act("end_turn", "p1")
	assert_eq(mystic.sum_status("temp_atk"), 0)
	assert_eq(mystic.sum_status("shield"), 2)
