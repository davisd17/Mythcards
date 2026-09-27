extends GutTest
# Russian-inspired abilities (LLD-ability-system.md 5.1–5.7, cases C1–C15), driven
# through RulesEngine.request_action with the real engine.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const GYMNAST := Fixture.GYMNAST
const TIGER := Fixture.TIGER
const SNIPER := Fixture.SNIPER
const GENERAL := Fixture.GENERAL
const BOGATYR := Fixture.BOGATYR
const ENGINEER := "p1_r-engineer"
const SEER := "p1_r-seer"
const GUARD := Fixture.GUARD           # HP 5
const ATTENDANT := Fixture.ATTENDANT   # HP 2
const CONDUCTOR := Fixture.CONDUCTOR   # HP 4, no damage reduction
const ORACLE := Fixture.ORACLE         # HP 5

var sys: AbilitySystem


func before_each() -> void:
	autofree(Fixture.start_match())
	Fixture.clear_board()
	_pool(4)
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


func _pool(ap: int) -> void:
	Fixture.state().get_player(Fixture.state().active_player_id).pool_ap_remaining = ap


# Levels a character up the real way (stat bonuses baked in).
func _level(id: String, level: int) -> CharacterInstance:
	var c := _c(id)
	while c.level < level:
		c.level += 1
		sys.apply_level_up_effects(c, c.level)
	return c


# Ends p1's turn and p2's, back to p1 with a fresh 4-AP pool.
func _next_p1_turn() -> void:
	_act("end_turn", "p1")
	_act("end_turn", "p2")


func _moves(id: String) -> Array[Vector2i]:
	return RulesEngine.get_legal_move_tiles(id)


# --- Gymnast (5.1) -----------------------------------------------------------------

func test_c1_vault_passes_one_ally_but_not_an_enemy() -> void:
	_put(GYMNAST, Vector2i(3, 3))      # MOVE 3
	_put(SNIPER, Vector2i(3, 4))
	assert_true(_moves(GYMNAST).has(Vector2i(3, 5)), "vaults the ally")
	Fixture.put(SNIPER, Vector2i(0, 0))   # move the ally out first: put() clears its old tile
	Fixture.put(GUARD, Vector2i(3, 4))
	assert_false(_moves(GYMNAST).has(Vector2i(3, 5)), "can't vault an enemy at L1")


func test_vault_passes_at_most_one_character() -> void:
	_put(GYMNAST, Vector2i(3, 2))
	_put(SNIPER, Vector2i(3, 3))
	_put(GENERAL, Vector2i(3, 4))
	assert_false(_moves(GYMNAST).has(Vector2i(3, 5)))


func test_c2_level_2_vaults_enemies() -> void:
	_put(GYMNAST, Vector2i(3, 3))
	_put(GUARD, Vector2i(3, 4))
	_level(GYMNAST, 2)
	assert_true(_moves(GYMNAST).has(Vector2i(3, 5)))


func test_level_2_extra_tile_only_after_vaulting() -> void:
	_put(GYMNAST, Vector2i(3, 0))
	_level(GYMNAST, 2)                  # MOVE 4
	_put(SNIPER, Vector2i(3, 1))
	var moves := _moves(GYMNAST)
	assert_true(moves.has(Vector2i(3, 5)), "5 tiles straight through the vault")
	assert_false(moves.has(Vector2i(0, 2)), "5 tiles without vaulting: no extra tile")
	assert_true(_act("move", GYMNAST, {"to": Vector2i(3, 5)}).success)


func test_c3_aurora_acrobat_free_attack_after_vaulting() -> void:
	_put(GYMNAST, Vector2i(3, 0))
	_level(GYMNAST, 3)
	_put(SNIPER, Vector2i(3, 1))
	Fixture.board().place_object(Vector2i(2, 0), "barricade", "p1")   # only way out is the vault
	Fixture.board().place_object(Vector2i(4, 0), "barricade", "p1")
	var guard := _put(GUARD, Vector2i(4, 2))
	assert_true(_act("move", GYMNAST, {"to": Vector2i(3, 2)}).success)
	var result := _act("reactive_bonus", GYMNAST, {"tag": "aurora_acrobat", "target_id": GUARD})
	assert_true(result.success)
	assert_eq(guard.current_hp, 4)
	assert_signal_emitted_with_parameters(EventBus, "attack_resolved", [GYMNAST, GUARD, 1, false])
	assert_eq(_act("reactive_bonus", GYMNAST, {"tag": "aurora_acrobat", "target_id": GUARD}).reason,
			"no bonus action available")


func test_aurora_acrobat_needs_a_vault() -> void:
	_put(GYMNAST, Vector2i(3, 0))
	_level(GYMNAST, 3)
	_put(GUARD, Vector2i(4, 2))
	assert_true(_act("move", GYMNAST, {"to": Vector2i(3, 2)}).success)
	assert_eq(_act("reactive_bonus", GYMNAST, {"tag": "aurora_acrobat", "target_id": GUARD}).reason,
			"no bonus action available")


# --- White Siberian Tiger (5.2) -----------------------------------------------------

func test_pounce_marks_the_next_attack_after_moving() -> void:
	var tiger := _put(TIGER, Vector2i(3, 2))          # ATK 2
	var general := _put(GENERAL, Vector2i(3, 1))
	var conductor := _put(CONDUCTOR, Vector2i(3, 4))  # HP 4
	assert_true(_ability(TIGER).success)
	assert_true(tiger.has_status("pounce_mark"))
	_next_p1_turn()
	# Command's free move lets the Tiger move and still attack this turn.
	assert_true(_ability(GENERAL, {"target": TIGER, "choice": "move"}).success)
	assert_true(_act("reactive_bonus", TIGER, {"tag": "free_move", "to": Vector2i(3, 3)}).success)
	assert_eq(_act("attack", TIGER, {"target_id": CONDUCTOR}), {"success": true, "damage": 4, "defeated": true})
	assert_false(tiger.has_status("pounce_mark"), "used up")
	assert_true(general.character_ap_remaining == 0)


func test_pounce_mark_waits_if_the_tiger_has_not_moved() -> void:
	var tiger := _put(TIGER, Vector2i(3, 3))
	var conductor := _put(CONDUCTOR, Vector2i(3, 4))
	tiger.status_effects.append(StatusEffect.new("pounce_mark", 2, "until_used"))
	assert_eq(_act("attack", TIGER, {"target_id": CONDUCTOR}).damage, 2)
	assert_true(tiger.has_status("pounce_mark"), "still waiting for an attack after moving")
	_next_p1_turn()
	assert_true(tiger.has_status("pounce_mark"), "survives turn changes")


func test_c4_pounce_rules() -> void:
	var tiger := _put(TIGER, Vector2i(3, 3))
	tiger.status_effects.append(StatusEffect.new("pounce_mark", 2, "until_used"))
	assert_eq(_ability(TIGER).reason, "ability unavailable", "already marked")
	tiger.status_effects.clear()
	_put(GENERAL, Vector2i(3, 2))
	Fixture.mount_pair(GENERAL, TIGER)
	assert_eq(_ability(TIGER).reason, "carrying a rider")


func test_c5_level_2_pounce_pushes() -> void:
	var tiger := _put(TIGER, Vector2i(3, 2))
	_level(TIGER, 2)
	var guard := _put(GUARD, Vector2i(3, 3))
	tiger.status_effects.append(StatusEffect.new("pounce_mark", 2, "until_used"))
	tiger.ability_uses_this_turn["moved"] = true
	assert_eq(_act("attack", TIGER, {"target_id": GUARD}).damage, 4)
	assert_eq(guard.position, Vector2i(3, 4))


func test_aurora_predator_after_a_pounce_kill() -> void:
	var tiger := _put(TIGER, Vector2i(3, 2))
	_level(TIGER, 3)                                   # ATK 3
	_put(ATTENDANT, Vector2i(3, 3))
	tiger.status_effects.append(StatusEffect.new("pounce_mark", 2, "until_used"))
	tiger.ability_uses_this_turn["moved"] = true
	assert_true(_act("attack", TIGER, {"target_id": ATTENDANT}).defeated)
	assert_eq(tiger.character_ap_remaining, 0)
	assert_true(_act("reactive_bonus", TIGER, {"tag": "aurora_predator", "to": Vector2i(3, 4)}).success)
	assert_eq(tiger.position, Vector2i(3, 4))
	assert_eq(tiger.character_ap_remaining, 1, "1 character AP refreshed")


# --- Sniper (5.3) -------------------------------------------------------------------

func test_c6_c7_aim_adds_range_only_while_unmoved() -> void:
	_put(SNIPER, Vector2i(3, 0))                       # RANGE 4
	_put(CONDUCTOR, Vector2i(3, 5))                    # 5 tiles
	assert_true(RulesEngine.get_legal_attack_target_ids(SNIPER).has(CONDUCTOR))
	_c(SNIPER).ability_uses_this_turn["moved"] = true
	assert_false(RulesEngine.get_legal_attack_target_ids(SNIPER).has(CONDUCTOR))


func test_c7a_aim_is_attack_only() -> void:
	var sniper := _put(SNIPER, Vector2i(3, 0))
	assert_eq(sys.get_conditional_range_bonus(sniper, "ability"), 0)


func test_c8_level_2_shoots_past_one_ally() -> void:
	_put(SNIPER, Vector2i(3, 0))
	_level(SNIPER, 2)
	_put(GYMNAST, Vector2i(3, 1))
	_put(CONDUCTOR, Vector2i(3, 3))
	assert_true(RulesEngine.get_legal_attack_target_ids(SNIPER).has(CONDUCTOR))
	_put(GENERAL, Vector2i(3, 2))
	assert_false(RulesEngine.get_legal_attack_target_ids(SNIPER).has(CONDUCTOR), "only one ally")


func test_level_2_piercing_shot() -> void:
	var sniper := _level(SNIPER, 2)
	assert_eq(sys.get_penetration(sniper), {"ignore_reduction": 1, "ignore_shield": 0})


func test_dead_lane_marks_a_distant_target() -> void:
	_put(SNIPER, Vector2i(3, 0))
	_level(SNIPER, 3)                                  # ATK 3
	var oracle := _put(ORACLE, Vector2i(3, 3))         # HP 5, 3 tiles away
	assert_eq(_act("attack", SNIPER, {"target_id": ORACLE}).damage, 3)
	assert_true(oracle.has_status("marked"))
	_put(GYMNAST, Vector2i(3, 4))                      # ATK 1 +1 from the mark
	assert_eq(_act("attack", GYMNAST, {"target_id": ORACLE}).damage, 2)
	assert_false(oracle.has_status("marked"))


func test_dead_lane_needs_three_tiles() -> void:
	_put(SNIPER, Vector2i(3, 1))
	_level(SNIPER, 3)
	var oracle := _put(ORACLE, Vector2i(3, 3))
	_act("attack", SNIPER, {"target_id": ORACLE})
	assert_false(oracle.has_status("marked"))


# --- Army General (5.4) ---------------------------------------------------------------

func test_c9_command_atk_is_spent_by_the_next_attack() -> void:
	_put(GENERAL, Vector2i(3, 1))
	var gymnast := _put(GYMNAST, Vector2i(3, 3))        # 2 tiles away
	_put(CONDUCTOR, Vector2i(3, 4))
	assert_true(_ability(GENERAL, {"target": GYMNAST, "choice": "atk"}).success)
	assert_eq(gymnast.sum_status("temp_atk"), 1)
	assert_eq(_act("attack", GYMNAST, {"target_id": CONDUCTOR}).damage, 2)
	assert_eq(gymnast.sum_status("temp_atk"), 0)


func test_command_move_grants_a_free_tile() -> void:
	_put(GENERAL, Vector2i(3, 1))
	var sniper := _put(SNIPER, Vector2i(3, 2))
	_ability(GENERAL, {"target": SNIPER, "choice": "move"})
	assert_true(_act("reactive_bonus", SNIPER, {"tag": "free_move", "to": Vector2i(4, 2)}).success)
	assert_eq(sniper.character_ap_remaining, 1, "the ally still has its own action")


func test_command_reach_and_target_count_by_level() -> void:
	_put(GENERAL, Vector2i(3, 0))
	_put(GYMNAST, Vector2i(3, 3))                       # 3 tiles
	_put(SNIPER, Vector2i(3, 1))
	assert_eq(_ability(GENERAL, {"target": GYMNAST, "choice": "atk"}).reason, "illegal ability target")
	_put(SNIPER, Vector2i(4, 0))
	assert_eq(_ability(GENERAL, {"targets": [{"id": GYMNAST, "choice": "atk"}, {"id": SNIPER, "choice": "move"}]}).reason,
			"too many targets")
	_level(GENERAL, 2)
	assert_true(_ability(GENERAL, {"targets": [{"id": GYMNAST, "choice": "atk"}, {"id": SNIPER, "choice": "move"}]}).success)


func test_command_needs_line_of_sight_and_a_choice() -> void:
	_put(GENERAL, Vector2i(3, 0))
	_put(CONDUCTOR, Vector2i(3, 1))
	_put(GYMNAST, Vector2i(3, 2))
	assert_eq(_ability(GENERAL, {"target": GYMNAST, "choice": "atk"}).reason, "illegal ability target")
	_put(CONDUCTOR, Vector2i(6, 6))
	assert_eq(_ability(GENERAL, {"target": GYMNAST, "choice": "fly"}).reason, "choose atk or move")


func test_tactical_mastery_after_a_commanded_kill() -> void:
	var general := _put(GENERAL, Vector2i(3, 1))
	_level(GENERAL, 3)
	var gymnast := _put(GYMNAST, Vector2i(3, 2))
	_put(ATTENDANT, Vector2i(3, 3))                     # HP 2
	_ability(GENERAL, {"target": GYMNAST, "choice": "atk"})
	assert_true(_act("attack", GYMNAST, {"target_id": ATTENDANT}).defeated)
	assert_eq(gymnast.character_ap_remaining, 0)
	assert_true(_act("reactive_bonus", GENERAL, {"tag": "tactical_mastery", "target_id": GYMNAST}).success)
	assert_eq(gymnast.character_ap_remaining, 1)
	assert_eq(general.character_ap_remaining, 0, "General's own action was the Command")


# --- Bogatyr Champion (5.5) ------------------------------------------------------------

func test_c10_stand_firm_near_the_center() -> void:
	var hero := _put(BOGATYR, Vector2i(3, 1))          # HP 6
	assert_true(_act("move", BOGATYR, {"to": Vector2i(3, 2)}).success)
	assert_eq(hero.current_hp, 7)
	assert_eq(sys.get_effective_max_hp(hero), 7)
	_next_p1_turn()
	_act("move", BOGATYR, {"to": Vector2i(3, 0)})
	assert_eq(hero.current_hp, 6)


func test_leaving_the_center_never_drops_below_1_hp() -> void:
	var hero := _put(BOGATYR, Vector2i(3, 3))
	sys.sync_conditional_hp(hero)
	hero.current_hp = 1
	_act("move", BOGATYR, {"to": Vector2i(3, 5)})
	assert_eq(hero.current_hp, 1)


func test_heroic_guard_bonus_and_aura() -> void:
	var hero := _put(BOGATYR, Vector2i(3, 2))
	_level(BOGATYR, 2)
	assert_eq(hero.current_hp, 8, "+2 near the center at Level 2, not +3")
	var gymnast := _put(GYMNAST, Vector2i(4, 2))
	assert_eq(sys.get_passive_damage_reduction(gymnast, _c(GUARD), false), 1)
	_put(GYMNAST, Vector2i(5, 2))
	assert_eq(sys.get_passive_damage_reduction(gymnast, _c(GUARD), false), 0, "not adjacent")


func test_c11_c12_last_oath_once_per_match() -> void:
	var hero := _put(BOGATYR, Vector2i(0, 3))          # away from the center
	_level(BOGATYR, 3)                                 # max HP 8
	var attendant := _put(ATTENDANT, Vector2i(1, 3))
	var combat := RulesEngine.systems().combat as CombatResolver
	var result := combat.apply_damage(_c(GUARD), hero, 20, false)
	assert_false(result.defeated)
	assert_eq(hero.current_hp, 2)
	assert_eq(attendant.current_hp, 1, "adjacent enemy took 1")
	assert_true(combat.apply_damage(_c(GUARD), hero, 20, false).defeated, "only once")


# --- Winter Engineer (5.6) ---------------------------------------------------------------

func test_c13_barricade_builds_and_blocks() -> void:
	_put(ENGINEER, Vector2i(3, 3))
	assert_true(_ability(ENGINEER, {"target": Vector2i(3, 4)}).success)
	var obj := Fixture.board().get_placed_object(Vector2i(3, 4))
	assert_eq(obj.type_id, "barricade")
	assert_eq(obj.current_hp, 2)
	assert_true(Fixture.board().is_blocked_for_movement(Vector2i(3, 4)))


func test_barricade_repairs_own_objects() -> void:
	_put(ENGINEER, Vector2i(3, 3))
	Fixture.board().place_object(Vector2i(3, 4), "barricade", "p1")
	Fixture.board().get_placed_object(Vector2i(3, 4)).current_hp = 1
	assert_true(_ability(ENGINEER, {"target": Vector2i(3, 4)}).success)
	assert_eq(Fixture.board().get_placed_object(Vector2i(3, 4)).current_hp, 2)


func test_c14_fortified_works_two_tiles_three_hp() -> void:
	_put(ENGINEER, Vector2i(3, 3))
	Fixture.board().place_object(Vector2i(2, 3), "barricade", "p1")
	_level(ENGINEER, 2)
	assert_eq(Fixture.board().get_placed_object(Vector2i(2, 3)).max_hp, 3, "existing barricades fortified")
	assert_true(_ability(ENGINEER, {"targets": [Vector2i(3, 4), Vector2i(4, 3)]}).success)
	assert_eq(Fixture.board().get_placed_object(Vector2i(3, 4)).current_hp, 3)
	assert_eq(Fixture.board().get_placed_object(Vector2i(4, 3)).current_hp, 3)


func test_level_1_builds_one_tile_only() -> void:
	_put(ENGINEER, Vector2i(3, 3))
	assert_eq(_ability(ENGINEER, {"targets": [Vector2i(3, 4), Vector2i(4, 3)]}).reason, "choose 1 tile")


func test_frozen_redoubt_frost_stops_movement() -> void:
	_put(ENGINEER, Vector2i(3, 1))
	_level(ENGINEER, 3)
	assert_true(_ability(ENGINEER, {"ability_id": "r-engineer_l3", "target": Vector2i(3, 3), "kind": "frost"}).success)
	assert_eq(Fixture.board().get_tile(Vector2i(3, 3)).terrain_type, "frost")
	_put(GYMNAST, Vector2i(3, 2))
	assert_false(_moves(GYMNAST).has(Vector2i(3, 4)), "entering frost ends the move")
	assert_eq(_ability(ENGINEER, {"ability_id": "r-engineer_l3", "target": Vector2i(3, 0), "kind": "barricade"}).reason,
			"no character AP remaining", "the Engineer already acted")


func test_frozen_redoubt_is_level_3_and_once_per_turn() -> void:
	var engineer := _put(ENGINEER, Vector2i(3, 1))
	assert_eq(_ability(ENGINEER, {"ability_id": "r-engineer_l3", "target": Vector2i(3, 3), "kind": "frost"}).reason,
			"ability unavailable")
	_level(ENGINEER, 3)
	engineer.character_ap_max = 2
	engineer.character_ap_remaining = 2
	assert_true(_ability(ENGINEER, {"ability_id": "r-engineer_l3", "target": Vector2i(3, 3), "kind": "barricade"}).success)
	assert_eq(_ability(ENGINEER, {"ability_id": "r-engineer_l3", "target": Vector2i(1, 1), "kind": "frost"}).reason,
			"ability unavailable")


func test_frozen_redoubt_aura_reduces_ranged_damage_near_objects() -> void:
	_put(ENGINEER, Vector2i(0, 0))
	_level(ENGINEER, 3)
	var sniper := _put(SNIPER, Vector2i(3, 3))
	Fixture.board().place_object(Vector2i(3, 4), "barricade", "p1")
	assert_eq(sys.get_passive_damage_reduction(sniper, _c(CONDUCTOR), true), 1)
	assert_eq(sys.get_passive_damage_reduction(sniper, _c(CONDUCTOR), false), 0, "ranged only")


# --- Frost Seer (5.7) --------------------------------------------------------------------

func test_c15_chill_damages_and_slows_on_the_targets_next_turn() -> void:
	_put(SEER, Vector2i(3, 0))                         # RANGE 3
	var conductor := _put(CONDUCTOR, Vector2i(3, 3))
	assert_eq(_ability(SEER, {"target": CONDUCTOR}), {"success": true, "damage": 1, "defeated": false})
	assert_eq(conductor.current_hp, 3)
	_act("end_turn", "p1")                             # p2's turn: slowed
	assert_eq(conductor.get_effective_move(), 1)
	assert_eq(_act("move", CONDUCTOR, {"to": Vector2i(3, 5)}).reason, "illegal move")
	_act("end_turn", "p2")
	_act("end_turn", "p1")                             # p2's following turn: normal again
	assert_eq(conductor.get_effective_move(), 2)


func test_chill_blocks_mounting_next_turn() -> void:
	_put(SEER, Vector2i(3, 0))
	_put(CONDUCTOR, Vector2i(3, 3))
	_put("p2_a-glider", Vector2i(4, 3))
	_ability(SEER, {"target": CONDUCTOR})
	_act("end_turn", "p1")
	assert_eq(_act("mount", CONDUCTOR, {"mount_id": "p2_a-glider"}).reason, "cannot mount right now")


func test_chill_range_and_line_of_sight() -> void:
	_put(SEER, Vector2i(3, 0))
	_put(CONDUCTOR, Vector2i(3, 4))
	assert_eq(_ability(SEER, {"target": CONDUCTOR}).reason, "illegal ability target", "4 tiles")
	_put(CONDUCTOR, Vector2i(3, 2))
	_put(GYMNAST, Vector2i(3, 1))
	assert_eq(_ability(SEER, {"target": CONDUCTOR}).reason, "illegal ability target", "blocked")


func test_winter_veil_shields_an_ally() -> void:
	_put(SEER, Vector2i(3, 0))
	_level(SEER, 2)
	_put(CONDUCTOR, Vector2i(3, 3))
	var sniper := _put(SNIPER, Vector2i(5, 0))
	assert_true(_ability(SEER, {"target": CONDUCTOR, "ally_id": SNIPER}).success)
	assert_eq(sniper.sum_status("shield"), 1)
	assert_true(sniper.has_status("no_push"))


func test_winter_veil_needs_level_2() -> void:
	_put(SEER, Vector2i(3, 0))
	_put(CONDUCTOR, Vector2i(3, 3))
	_put(SNIPER, Vector2i(5, 0))
	assert_eq(_ability(SEER, {"target": CONDUCTOR, "ally_id": SNIPER}).reason, "Winter Veil needs Level 2")


func test_deep_freeze_stops_an_already_slowed_target() -> void:
	var seer := _put(SEER, Vector2i(3, 0))
	_level(SEER, 3)                                    # RANGE 4
	var conductor := _put(CONDUCTOR, Vector2i(3, 4))
	_ability(SEER, {"target": CONDUCTOR})              # first Chill: slowed
	seer.character_ap_remaining = 1
	_ability(SEER, {"target": CONDUCTOR})              # second: frozen
	assert_true(conductor.has_status("no_reaction"))
	_act("end_turn", "p1")
	assert_eq(conductor.get_effective_move(), 0)
	assert_eq(RulesEngine.get_legal_move_tiles(CONDUCTOR), [] as Array[Vector2i])
