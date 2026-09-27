extends GutTest
# Atlantean abilities (LLD-ability-system.md 5.8–5.14, cases C16–C25 and C22B),
# driven through RulesEngine.request_action with the real engine. Atlanteans are p2,
# so most cases start by handing the turn to p2.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const ATTENDANT := Fixture.ATTENDANT   # HP 2 ATK 1
const GLIDER := Fixture.GLIDER         # HP 3 MOVE 4
const GUARD := Fixture.GUARD           # HP 5
const CONDUCTOR := Fixture.CONDUCTOR   # RANGE 3
const ORACLE := Fixture.ORACLE         # HP 5
const ARCHITECT := "p2_a-architect"    # RANGE 2
const HARMONIC := "p2_a-harmonic"      # RANGE 3
const GYMNAST := Fixture.GYMNAST
const SNIPER := Fixture.SNIPER         # ATK 2 RANGE 4
const GENERAL := Fixture.GENERAL
const BOGATYR := Fixture.BOGATYR
const TIGER := Fixture.TIGER

var sys: AbilitySystem


func before_each() -> void:
	autofree(Fixture.start_match())
	Fixture.clear_board()
	sys = RulesEngine.systems().ability
	watch_signals(EventBus)


func after_each() -> void:
	sys = null
	Fixture.teardown()


func _c(id: String) -> CharacterInstance:
	return Fixture.character(id)


func _put(id: String, pos: Vector2i) -> CharacterInstance:
	return Fixture.put(id, pos)


func _act(action: String, actor: String, payload: Dictionary = {}) -> Dictionary:
	return RulesEngine.request_action(action, actor, payload)


func _ability(actor: String, payload: Dictionary = {}) -> Dictionary:
	var p := payload.duplicate()
	if not p.has("ability_id"):
		p["ability_id"] = _c(actor).data.id
	return _act("ability", actor, p)


func _level(id: String, level: int) -> CharacterInstance:
	var c := _c(id)
	while c.level < level:
		c.level += 1
		sys.apply_level_up_effects(c, c.level)
	return c


func _p2_turn() -> void:
	_act("end_turn", Fixture.state().active_player_id)
	if Fixture.state().active_player_id != "p2":
		_act("end_turn", Fixture.state().active_player_id)


# --- Quartz Attendant (5.8) --------------------------------------------------------

func test_c16_synchronize_next_to_an_atlantean_ally() -> void:
	var attendant := _put(ATTENDANT, Vector2i(3, 3))
	assert_eq(sys.get_conditional_atk_bonus(attendant), 0)
	_put(GUARD, Vector2i(3, 4))
	assert_eq(sys.get_conditional_atk_bonus(attendant), 1)


func test_c16a_synchronize_ignores_enemy_atlanteans() -> void:
	# Mirror match: the adjacent Atlantean belongs to the other player.
	Fixture.teardown()
	var setup: Node = autofree(Fixture.SetupFlowScript.new())
	TurnManager.relic_event_deck = Fixture.NullDeck.new()
	TurnManager.victory_checker = Fixture.NullChecker.new()
	setup.select_culture("p1", "Atlantean")
	setup.select_culture("p2", "Atlantean")
	for id in ["p1", "p2"]:
		var x := 0
		for c in setup.get_player(id).characters:
			setup.place_character(id, c.instance_id, Vector2i(x, 0 if id == "p1" else 6))
			x += 1
	setup.start_match()
	Fixture.clear_board()
	sys = RulesEngine.systems().ability
	var mine := Fixture.put("p1_a-attendant", Vector2i(3, 3))
	Fixture.put("p2_a-guard", Vector2i(3, 4))
	assert_eq(sys.get_conditional_atk_bonus(mine), 0)


func test_synchronize_adds_to_a_real_attack() -> void:
	_p2_turn()
	_put(ATTENDANT, Vector2i(3, 3))
	_put(GUARD, Vector2i(2, 3))
	var gymnast := _put(GYMNAST, Vector2i(3, 4))       # HP 2
	assert_eq(_act("attack", ATTENDANT, {"target_id": GYMNAST}).damage, 2)
	assert_true(gymnast.defeated)


func test_shared_pulse_reduces_the_first_hit_only() -> void:
	_put(ATTENDANT, Vector2i(3, 3))
	_level(ATTENDANT, 2)
	var guard := _put(GUARD, Vector2i(3, 4))
	var combat := RulesEngine.systems().combat as CombatResolver
	assert_eq(combat.apply_damage(_c(SNIPER), guard, 2, false).damage, 1, "first hit reduced")
	assert_eq(combat.apply_damage(_c(SNIPER), guard, 2, false).damage, 2, "once per turn")


func test_collective_node_counts_as_a_pylon_and_widens_synchronize() -> void:
	var attendant := _put(ATTENDANT, Vector2i(3, 3))
	_level(ATTENDANT, 3)
	assert_true(sys.is_pylon_source(Vector2i(3, 3), "p2"))
	assert_false(sys.is_pylon_source(Vector2i(3, 3), "p1"), "own side only")
	_put(GUARD, Vector2i(3, 5))                          # 2 tiles away
	assert_eq(sys.get_conditional_atk_bonus(attendant), 1)


# --- Manta Glider (5.9) --------------------------------------------------------------

func test_c17_glide_passes_any_number_of_characters() -> void:
	_p2_turn()
	_put(GLIDER, Vector2i(3, 6))                         # MOVE 4
	_put(GYMNAST, Vector2i(3, 5))
	_put(SNIPER, Vector2i(3, 4))
	_put(GUARD, Vector2i(3, 3))
	assert_true(RulesEngine.get_legal_move_tiles(GLIDER).has(Vector2i(3, 2)), "over three characters")


func test_a_ridden_glider_glides_its_rider() -> void:
	_p2_turn()
	_put(CONDUCTOR, Vector2i(3, 6))
	Fixture.mount_pair(CONDUCTOR, GLIDER)
	_put(GYMNAST, Vector2i(3, 5))
	assert_true(RulesEngine.get_legal_move_tiles(CONDUCTOR).has(Vector2i(3, 4)))


func test_level_2_glide_over_a_character_buffs_the_next_attack() -> void:
	_p2_turn()
	var glider := _put(GLIDER, Vector2i(3, 6))
	_level(GLIDER, 2)
	_put(GYMNAST, Vector2i(3, 5))
	# Walled in, so the only way out is over the Gymnast. The engine knows destinations,
	# not paths: a move counts as "over a character" when no pass-free route reaches it.
	Fixture.board().place_object(Vector2i(2, 6), "barricade", "p1")
	Fixture.board().place_object(Vector2i(4, 6), "barricade", "p1")
	assert_true(_act("move", GLIDER, {"to": Vector2i(3, 4)}).success)
	assert_eq(glider.sum_status("temp_atk"), 1)
	# Designer ruling 2026-09-27: it lasts until the next attack, across turns, and
	# gliding again first doesn't stack it.
	_act("end_turn", "p2")
	_act("end_turn", "p1")
	assert_eq(glider.sum_status("temp_atk"), 1, "survives into the next turn")
	assert_true(_act("move", GLIDER, {"to": Vector2i(3, 6)}).success)
	_act("end_turn", "p2")
	_act("end_turn", "p1")
	assert_eq(glider.sum_status("temp_atk"), 1)
	_put(GYMNAST, Vector2i(3, 5))
	assert_eq(_act("attack", GLIDER, {"target_id": GYMNAST}).damage, 2, "ATK 1 + glide")
	assert_eq(glider.sum_status("temp_atk"), 0, "spent")


func test_level_2_glide_with_a_pass_free_route_earns_nothing() -> void:
	_p2_turn()
	var glider := _put(GLIDER, Vector2i(3, 6))
	_level(GLIDER, 2)
	_put(GYMNAST, Vector2i(3, 5))
	assert_true(_act("move", GLIDER, {"to": Vector2i(3, 4)}).success)
	assert_eq(glider.sum_status("temp_atk"), 0, "could have gone around")


func test_phase_current_moves_through_everything_and_hits_one_enemy() -> void:
	_p2_turn()
	var glider := _put(GLIDER, Vector2i(3, 6))
	_level(GLIDER, 3)                                    # MOVE 5
	Fixture.board().place_object(Vector2i(3, 5), "barricade", "p1")
	var gymnast := _put(GYMNAST, Vector2i(3, 4))
	Fixture.board().get_tile(Vector2i(3, 3)).terrain_type = "frost"
	var result := _ability(GLIDER, {"ability_id": "a-glider_l3", "to": Vector2i(3, 2), "over_id": GYMNAST})
	assert_true(result.success)
	assert_eq(glider.position, Vector2i(3, 2))
	assert_eq(gymnast.current_hp, 1)
	assert_eq(_ability(GLIDER, {"ability_id": "a-glider_l3", "to": Vector2i(3, 1)}).reason, "no character AP remaining")


func test_phase_current_is_level_3() -> void:
	_p2_turn()
	_put(GLIDER, Vector2i(3, 6))
	assert_eq(_ability(GLIDER, {"ability_id": "a-glider_l3", "to": Vector2i(3, 5)}).reason, "ability unavailable")


func test_phase_current_damage_needs_the_enemy_on_the_way() -> void:
	_p2_turn()
	_put(GLIDER, Vector2i(3, 6))
	_level(GLIDER, 3)
	_put(GYMNAST, Vector2i(0, 0))
	assert_eq(_ability(GLIDER, {"ability_id": "a-glider_l3", "to": Vector2i(3, 4), "over_id": GYMNAST}).reason,
			"that enemy isn't on the way")


# --- Resonance Guard (5.10) ------------------------------------------------------------

func test_c18_quartz_armor_reduces_ranged_only() -> void:
	var guard := _put(GUARD, Vector2i(3, 3))
	assert_eq(sys.get_passive_damage_reduction(guard, _c(SNIPER), true), 1)
	assert_eq(sys.get_passive_damage_reduction(guard, _c(SNIPER), false), 0)


func test_quartz_armor_against_a_real_sniper_shot() -> void:
	_put(SNIPER, Vector2i(3, 0))
	var guard := _put(GUARD, Vector2i(3, 3))
	assert_eq(_act("attack", SNIPER, {"target_id": GUARD}).damage, 1)
	assert_eq(guard.current_hp, 4)


func test_c22b_piercing_shot_ignores_one_point_of_reduction() -> void:
	# Guard L2 armor (1) + an armored neighbor's... use two sources: own armor and an
	# adjacent Guard-granted armor don't stack on the Guard itself, so pair the Guard's
	# own armor with the Attendant's Shared Pulse for 2 points.
	_put(SNIPER, Vector2i(3, 0))
	_level(SNIPER, 2)                                     # ATK 2, pierces 1
	var guard := _put(GUARD, Vector2i(3, 3))
	_put(ATTENDANT, Vector2i(4, 3))
	_level(ATTENDANT, 2)
	assert_eq(_act("attack", SNIPER, {"target_id": GUARD}).damage, 1, "2 reduction - 1 pierced")
	assert_eq(guard.current_hp, 4)


func test_c18a_level_2_armor_covers_adjacent_allies() -> void:
	var guard := _put(GUARD, Vector2i(3, 3))
	_level(GUARD, 2)
	var attendant := _put(ATTENDANT, Vector2i(3, 4))
	assert_eq(sys.get_passive_damage_reduction(attendant, _c(SNIPER), true), 1)
	assert_eq(sys.get_passive_damage_reduction(attendant, _c(SNIPER), false), 0)
	_put(ATTENDANT, Vector2i(3, 5))
	assert_eq(sys.get_passive_damage_reduction(attendant, _c(SNIPER), true), 0)


func test_c18b_resonant_bastion_reflects_once() -> void:
	_put(GUARD, Vector2i(3, 3))
	_level(GUARD, 3)
	_put(ATTENDANT, Vector2i(3, 4))                       # armored by the Guard
	var gymnast := _put(GYMNAST, Vector2i(3, 5))          # HP 2
	assert_true(_act("attack", GYMNAST, {"target_id": ATTENDANT}).success)
	assert_eq(gymnast.current_hp, 1, "exactly 1 reflected")


func test_c18c_no_reflect_before_level_3() -> void:
	_put(GUARD, Vector2i(3, 3))
	_level(GUARD, 2)
	_put(ATTENDANT, Vector2i(3, 4))
	var gymnast := _put(GYMNAST, Vector2i(3, 5))
	_act("attack", GYMNAST, {"target_id": ATTENDANT})
	assert_eq(gymnast.current_hp, 2)


# --- Divine Conductor (5.11) ------------------------------------------------------------

func test_c19_link_mind_lends_range_for_abilities_only() -> void:
	_p2_turn()
	_put(CONDUCTOR, Vector2i(3, 6))                       # RANGE 3
	var architect := _put(ARCHITECT, Vector2i(3, 4))      # RANGE 2
	assert_true(_ability(CONDUCTOR, {"target": ARCHITECT}).success)
	assert_eq(sys.ability_reach(architect, 2), 3)
	assert_eq(architect.get_effective_range("attack", sys.get_conditional_range_bonus(architect, "attack")), 2)


func test_link_mind_lets_an_ally_target_past_one_ally() -> void:
	_p2_turn()
	_put(CONDUCTOR, Vector2i(0, 6))
	var harmonic := _put(HARMONIC, Vector2i(3, 6))
	_put(GUARD, Vector2i(3, 5))
	_put(ATTENDANT, Vector2i(3, 4))
	assert_false(sys.get_legal_ability_targets(harmonic, "a-harmonic").has(ATTENDANT), "Guard is in the way")
	_ability(CONDUCTOR, {"target": HARMONIC})
	assert_true(sys.get_legal_ability_targets(harmonic, "a-harmonic").has(ATTENDANT))


func test_link_mind_level_2_links_two() -> void:
	_p2_turn()
	_put(CONDUCTOR, Vector2i(3, 6))
	_put(ARCHITECT, Vector2i(3, 4))
	_put(HARMONIC, Vector2i(4, 6))
	assert_eq(_ability(CONDUCTOR, {"targets": [ARCHITECT, HARMONIC]}).reason, "too many targets")
	_level(CONDUCTOR, 2)
	assert_true(_ability(CONDUCTOR, {"targets": [ARCHITECT, HARMONIC]}).success)


func test_perfect_chord_refreshes_a_linked_killer() -> void:
	_p2_turn()
	_put(CONDUCTOR, Vector2i(3, 6))
	_level(CONDUCTOR, 3)
	var guard := _put(GUARD, Vector2i(3, 5))
	var gymnast := _put(GYMNAST, Vector2i(3, 4))
	gymnast.current_hp = 1
	_ability(CONDUCTOR, {"target": GUARD})
	assert_true(_act("attack", GUARD, {"target_id": GYMNAST}).defeated)
	assert_eq(guard.character_ap_remaining, 1, "refreshed")


# --- Oracle Sovereign (5.12) --------------------------------------------------------------

func test_c20_foresight_sends_the_top_card_to_the_bottom() -> void:
	_p2_turn()
	Fixture.state().shared_deck = ["x", "y", "z"] as Array[String]
	_put(ORACLE, Vector2i(3, 6))
	var guard := _put(GUARD, Vector2i(3, 5))
	var result := _ability(ORACLE, {"ally_id": GUARD, "to_bottom": true})
	assert_eq(result.revealed, "x")
	assert_eq(Fixture.state().shared_deck, ["y", "z", "x"] as Array[String])
	assert_eq(guard.sum_status("shield"), 1)


func test_foresight_can_leave_the_card_on_top_at_level_1() -> void:
	# Designer ruling 2026-09-27: sending it to the bottom is optional at every level.
	_p2_turn()
	Fixture.state().shared_deck = ["x", "y"] as Array[String]
	_put(ORACLE, Vector2i(3, 6))
	assert_eq(_ability(ORACLE).revealed, "x")
	assert_eq(Fixture.state().shared_deck, ["x", "y"] as Array[String])


func test_spirit_mantle_shields_at_turn_start() -> void:
	var oracle := _put(ORACLE, Vector2i(3, 6))
	var guard := _put(GUARD, Vector2i(3, 5))
	_level(ORACLE, 2)
	_p2_turn()
	assert_eq(oracle.sum_status("shield"), 1)
	assert_true(_act("reactive_bonus", ORACLE, {"tag": "spirit_mantle", "target_id": GUARD}).success)
	assert_eq(guard.sum_status("shield"), 1)


func test_c21_collective_ascension_once_per_match() -> void:
	_p2_turn()
	var oracle := _put(ORACLE, Vector2i(3, 6))
	_level(ORACLE, 3)
	var guard := _put(GUARD, Vector2i(0, 6))
	guard.current_hp = 2
	assert_true(_ability(ORACLE, {"ability_id": "a-hero_l3"}).success)
	assert_eq(guard.current_hp, 4)
	assert_eq(guard.sum_status("shield"), 1)
	assert_eq(guard.get_effective_move(), 3)
	_act("end_turn", "p2")
	_act("end_turn", "p1")
	assert_eq(_ability(ORACLE, {"ability_id": "a-hero_l3"}).reason, "ability unavailable")


func test_collective_ascension_heals_only_to_max() -> void:
	_p2_turn()
	var oracle := _put(ORACLE, Vector2i(3, 6))
	_level(ORACLE, 3)
	_ability(ORACLE, {"ability_id": "a-hero_l3"})
	assert_eq(oracle.current_hp, oracle.base_max_hp)


# --- Crystal Architect (5.13) ---------------------------------------------------------------

func test_pylon_placement_and_move() -> void:
	_p2_turn()
	var architect := _put(ARCHITECT, Vector2i(3, 5))
	assert_true(_ability(ARCHITECT, {"target": Vector2i(3, 4)}).success)
	assert_eq(Fixture.board().get_placed_object(Vector2i(3, 4)).type_id, "pylon")
	assert_eq(_ability(ARCHITECT, {"target": Vector2i(3, 2)}).reason, "no character AP remaining")
	_act("end_turn", "p2")
	_act("end_turn", "p1")
	assert_true(_ability(ARCHITECT, {"move_from": Vector2i(3, 4), "target": Vector2i(2, 4)}).success)
	assert_null(Fixture.board().get_placed_object(Vector2i(3, 4)))
	assert_eq(Fixture.board().get_placed_object(Vector2i(2, 4)).type_id, "pylon")


func test_level_1_pylon_only_adjacent() -> void:
	_p2_turn()
	_put(ARCHITECT, Vector2i(3, 5))
	assert_eq(_ability(ARCHITECT, {"target": Vector2i(3, 3)}).reason, "illegal ability target")


func test_c22_c22a_pylon_range_bonus_by_level() -> void:
	var architect := _put(ARCHITECT, Vector2i(0, 6))
	Fixture.board().place_object(Vector2i(3, 5), "pylon", "p2")
	var harmonic := _put(HARMONIC, Vector2i(3, 3))        # 2 tiles from the pylon
	assert_eq(sys.get_conditional_range_bonus(harmonic, "ability"), 1)
	assert_eq(sys.get_conditional_range_bonus(harmonic, "attack"), 0, "abilities only at L1")
	_level(ARCHITECT, 2)
	assert_eq(sys.get_conditional_range_bonus(harmonic, "attack"), 1)
	assert_eq(Fixture.board().get_placed_object(Vector2i(3, 5)).max_hp, 2, "L2 pylons have 2 HP")


func test_relay_gate_teleports_between_pylons() -> void:
	_p2_turn()
	_put(ARCHITECT, Vector2i(0, 6))
	_level(ARCHITECT, 3)
	Fixture.board().place_object(Vector2i(3, 5), "pylon", "p2")
	Fixture.board().place_object(Vector2i(3, 2), "pylon", "p2")   # 3 tiles apart
	var guard := _put(GUARD, Vector2i(4, 5))
	assert_true(_ability(ARCHITECT, {"ability_id": "a-architect_l3", "target": GUARD, "to": Vector2i(3, 1)}).success)
	assert_eq(guard.position, Vector2i(3, 1))
	assert_eq(guard.sum_status("shield"), 1)
	assert_signal_emitted_with_parameters(EventBus, "character_repositioned", [GUARD, Vector2i(4, 5), Vector2i(3, 1), "teleport"])


func test_relay_gate_rules() -> void:
	_p2_turn()
	_put(ARCHITECT, Vector2i(0, 6))
	_level(ARCHITECT, 3)
	Fixture.board().place_object(Vector2i(3, 6), "pylon", "p2")
	Fixture.board().place_object(Vector2i(3, 0), "pylon", "p2")   # 6 tiles apart: too far
	_put(GUARD, Vector2i(4, 6))
	assert_eq(_ability(ARCHITECT, {"ability_id": "a-architect_l3", "target": GUARD, "to": Vector2i(3, 1)}).reason,
			"needs an empty tile next to another pylon within 4")
	_put(GUARD, Vector2i(5, 5))
	assert_eq(_ability(ARCHITECT, {"ability_id": "a-architect_l3", "target": GUARD, "to": Vector2i(3, 1)}).reason,
			"needs an ally next to a pylon")


func test_relay_gate_onto_the_opponents_edge_levels_up() -> void:
	_p2_turn()
	_put(ARCHITECT, Vector2i(6, 6))
	_level(ARCHITECT, 3)
	Fixture.board().place_object(Vector2i(3, 4), "pylon", "p2")
	Fixture.board().place_object(Vector2i(3, 1), "pylon", "p2")
	var guard := _put(GUARD, Vector2i(3, 5))
	_ability(ARCHITECT, {"ability_id": "a-architect_l3", "target": GUARD, "to": Vector2i(3, 0)})
	assert_eq(guard.level, 2, "teleported onto p2's opponent edge")


# --- Astral Harmonic (5.14) -------------------------------------------------------------

func test_c23_c24_resonance_shield_size() -> void:
	_p2_turn()
	_put(HARMONIC, Vector2i(3, 6))
	var guard := _put(GUARD, Vector2i(3, 4))
	assert_true(_ability(HARMONIC, {"target": GUARD}).success)
	assert_eq(guard.sum_status("shield"), 1)
	_act("end_turn", "p2")
	_act("end_turn", "p1")
	var conductor := _put(CONDUCTOR, Vector2i(4, 6))
	Fixture.put(GUARD, Vector2i(0, 0))
	Fixture.mount_pair(CONDUCTOR, GLIDER)
	_put(CONDUCTOR, Vector2i(3, 4))
	_c(GLIDER).position = Vector2i(3, 4)
	assert_true(_ability(HARMONIC, {"target": CONDUCTOR}).success)
	assert_eq(conductor.sum_status("shield"), 2, "a mounted ally gets 2")


func test_c25_harmonic_bind() -> void:
	_p2_turn()
	_put(HARMONIC, Vector2i(3, 6))
	_level(HARMONIC, 2)
	var guard := _put(GUARD, Vector2i(3, 4))
	_ability(HARMONIC, {"target": GUARD})
	assert_eq(guard.sum_status("shield"), 2)
	assert_true(guard.has_status("no_push"))


func test_astral_echo_damages_and_frees_a_move() -> void:
	_p2_turn()
	_put(HARMONIC, Vector2i(3, 6))
	_level(HARMONIC, 3)
	var guard := _put(GUARD, Vector2i(3, 4))
	var gymnast := _put(GYMNAST, Vector2i(3, 2))           # 2 tiles from the Guard
	assert_true(_ability(HARMONIC, {"target": GUARD, "echo_target_id": GYMNAST}).success)
	assert_eq(gymnast.current_hp, 1)
	assert_true(_act("reactive_bonus", GUARD, {"tag": "free_move", "to": Vector2i(4, 4)}).success)


func test_astral_echo_needs_level_3_and_a_nearby_enemy() -> void:
	_p2_turn()
	_put(HARMONIC, Vector2i(3, 6))
	_put(GUARD, Vector2i(3, 4))
	_put(GYMNAST, Vector2i(3, 2))
	assert_eq(_ability(HARMONIC, {"target": GUARD, "echo_target_id": GYMNAST}).reason, "Astral Echo needs Level 3")
	_level(HARMONIC, 3)
	_put(GYMNAST, Vector2i(0, 0))
	assert_eq(_ability(HARMONIC, {"target": GUARD, "echo_target_id": GYMNAST}).reason,
			"needs an enemy within 2 of the shielded ally")
