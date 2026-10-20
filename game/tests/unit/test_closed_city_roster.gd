extends GutTest
# The Closed City team (LLD-closed-city-flood-roster.md 4), played through RulesEngine
# against the Flood Survivors.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const WORKER := "p1_r-reactor-worker"     # Common 3/1/2/1
const VERA := "p1_r-vera-7"               # Mount 4/1/3/1
const YURI := "p1_r-yuri-volkov"          # Warrior 4/2/2/2
const ORLOV := "p1_r-mikhail-orlov"       # Hero 5/1/2/3
const KARPOVA := "p1_r-irina-karpova"     # Leader 4/1/2/3
const ELENA := "p1_r-elena-morozova"      # Specialist 3/1/2/3
const ZOYA := "p1_r-zoya-miranova"        # Mystic 3/1/2/3
const LABORER := "p2_a-flood-survivor-stone-line-laborer"   # 2/1/2/1
const NAIA := "p2_a-flood-survivor-naia"                     # 4/2/3/1
const SAHU := "p2_a-flood-survivor-sahu-ren"                 # 5/1/2/3
const MERET := "p2_a-flood-survivor-meret-anu"               # 4/1/2/3
const CENTER := Vector2i(3, 3)

var sys: AbilitySystem


func before_each() -> void:
	autofree(Fixture.start_teams_match())
	Fixture.state().shared_deck.clear()
	Fixture.clear_board()
	Fixture.state().get_player("p1").pool_ap_remaining = 4
	sys = RulesEngine.systems().ability


func after_each() -> void:
	sys = null
	Fixture.teardown()


func _c(id: String) -> CharacterInstance:
	return Fixture.character(id)


func _act(action: String, actor: String, payload: Dictionary = {}) -> Dictionary:
	return RulesEngine.request_action(action, actor, payload)


func _ability(actor: String, payload: Dictionary, ability_id: String = "") -> Dictionary:
	payload["ability_id"] = ability_id if ability_id != "" else _c(actor).data.id
	return _act("ability", actor, payload)


func _level(id: String, level: int) -> CharacterInstance:
	var c := _c(id)
	for l in range(c.level + 1, level + 1):
		c.level = l
		sys.apply_level_up_effects(c, l)
	return c


func _pass_to_p1() -> void:
	_act("end_turn", "p1")
	_act("end_turn", "p2")


func test_team_is_the_closed_city_seven() -> void:
	var names := Fixture.state().get_player("p1").characters.map(func(c): return c.data.char_name)
	assert_eq(names, ["Reactor Worker", "VERA-7", "Major Yuri Volkov", "Dr. Mikhail Orlov",
			"Irina Vasilievna Karpova", "Dr. Elena Morozova", "Zoya Miranova"])
	assert_eq(Fixture.state().get_player("p1").team_id, "closed-city")


# --- Reactor Worker ---------------------------------------------------------------------

func test_reactor_worker_never_triggers_leaks() -> void:
	var worker := Fixture.put(WORKER, Vector2i(3, 0))
	sys.place_leak(Vector2i(3, 1))
	sys.place_leak(Vector2i(3, 2))
	assert_true(_act("move", WORKER, {"to": Vector2i(3, 2)}).success)
	assert_eq(worker.current_hp, 3)
	assert_true(sys.has_leak(Vector2i(3, 1)), "the Leak it crossed stays")
	assert_true(sys.has_leak(Vector2i(3, 2)), "it stands on a Leak")


func test_reactor_worker_levels() -> void:
	var worker := _level(WORKER, 2)
	assert_eq(worker.get_effective_move(), 3, "Lower Corridors")
	_level(WORKER, 3)
	Fixture.put(WORKER, Vector2i(0, 0))
	sys.place_leak(Vector2i(0, 2))
	sys.place_leak(Vector2i(2, 2))
	assert_true(_act("move", WORKER, {"to": Vector2i(0, 2)}).success)
	assert_eq(worker.character_ap_remaining, 1, "ending on a Leak gives +1 character AP")
	assert_true(_act("move", WORKER, {"to": Vector2i(2, 2)}).success, "so it can act again")
	assert_eq(worker.character_ap_remaining, 1, "no per-turn limit (ruling 2026-10-07)")


# --- VERA-7 ---------------------------------------------------------------------------------

func test_vera_protected_passenger() -> void:
	var orlov := Fixture.put(ORLOV, Vector2i(3, 0))
	Fixture.put(VERA, Vector2i(3, 1))
	assert_true(_act("mount", ORLOV, {"mount_id": VERA}).success)
	assert_eq(sys.get_effective_max_hp(orlov), 7, "+2 max HP while riding VERA-7 (balance pass 2026-10-19)")
	assert_eq(orlov.current_hp, 7)
	_pass_to_p1()
	assert_true(_act("dismount", ORLOV, {"to": Vector2i(2, 1)}).success)
	assert_eq(sys.get_effective_max_hp(orlov), 5)
	assert_eq(orlov.current_hp, 5)


func test_vera_l2_passes_one_ally_or_object() -> void:
	_level(VERA, 2)                                   # MOVE 4
	Fixture.put(VERA, Vector2i(3, 0))
	Fixture.put(WORKER, Vector2i(3, 1))
	Fixture.board().place_object(Vector2i(3, 3), "stone", "p2")
	var moves := RulesEngine.get_legal_move_tiles(VERA)
	assert_true(moves.has(Vector2i(3, 2)), "through the ally")
	assert_false(moves.has(Vector2i(3, 4)), "only one pass per move")


func test_vera_l3_passenger_signal() -> void:
	_level(VERA, 3)
	Fixture.put(VERA, Vector2i(3, 1))
	var worker := Fixture.put(WORKER, Vector2i(3, 0))
	assert_true(RulesEngine.get_offered_bonus_tags(VERA).has("passenger_signal"))
	# Every two tiles next to VERA-7 are diagonal to each other, so the ally moves to any
	# other empty tile next to her ([NEED: confirm] in the LLD).
	assert_true(_act("reactive_bonus", VERA, {"tag": "passenger_signal", "target_id": WORKER, "to": Vector2i(2, 1)}).success)
	assert_eq(worker.position, Vector2i(2, 1))
	assert_eq(Fixture.state().get_player("p1").pool_ap_remaining, 4, "free")
	assert_false(RulesEngine.get_offered_bonus_tags(VERA).has("passenger_signal"), "once per turn")


# --- Major Yuri Volkov --------------------------------------------------------------------------

func test_containment_shot_marks_next_to_a_leak() -> void:
	Fixture.put(YURI, Vector2i(3, 0))
	var sahu := Fixture.put(SAHU, Vector2i(3, 3))
	sys.place_leak(Vector2i(4, 3))
	var result := _ability(YURI, {"target": SAHU})
	assert_true(result.success, str(result))
	assert_eq(sahu.current_hp, 4)
	assert_true(sahu.has_status("marked"))


func test_containment_shot_marks_next_to_any_placed_object() -> void:
	Fixture.put(YURI, Vector2i(3, 0))
	var sahu := Fixture.put(SAHU, Vector2i(3, 3))
	var naia := Fixture.put(NAIA, Vector2i(0, 3))
	Fixture.board().place_object(Vector2i(4, 3), "stone", "p2")
	assert_true(_ability(YURI, {"target": SAHU}).success)
	assert_true(sahu.has_status("marked"), "an enemy Stone counts (balance pass 2026-10-19)")
	_pass_to_p1()
	Fixture.put(YURI, Vector2i(0, 1))
	assert_true(_ability(YURI, {"target": NAIA}).success)
	assert_false(naia.has_status("marked"), "nothing placed next to it")


func test_containment_shot_levels() -> void:
	var yuri := _level(YURI, 2)
	assert_eq(sys.get_effective_max_hp(yuri), 5)
	_level(YURI, 3)
	assert_eq(yuri.get_effective_atk(), 3)
	Fixture.put(YURI, Vector2i(1, 1))
	Fixture.put(SAHU, Vector2i(3, 3))
	assert_true(sys.get_legal_ability_targets(yuri, yuri.data.id).has(SAHU), "Seal The Breach: diagonal")
	Fixture.put(WORKER, Vector2i(2, 2))
	assert_false(sys.get_legal_ability_targets(yuri, yuri.data.id).has(SAHU), "blocked diagonal")


# --- Dr. Mikhail Orlov ----------------------------------------------------------------------------

func test_reactor_leak() -> void:
	var orlov := Fixture.put(ORLOV, Vector2i(3, 0))
	assert_true(_ability(ORLOV, {"target": Vector2i(3, 2)}).success)
	assert_true(sys.has_leak(Vector2i(3, 2)))
	assert_false(_ability(ORLOV, {"target": Vector2i(3, 3)}).success, "out of reach (or no AP)")
	_level(ORLOV, 2)
	_pass_to_p1()
	assert_eq(orlov.get_effective_range("attack"), 4)
	assert_true(_ability(ORLOV, {"target": Vector2i(2, 0), "target_2": Vector2i(3, 3)}).success, "2 Leaks, reach 3")


func test_slumber_leaves_and_returns() -> void:
	_level(ORLOV, 3)
	var orlov := Fixture.put(ORLOV, Vector2i(3, 2))
	Fixture.put(WORKER, Vector2i(0, 0))
	assert_true(_ability(ORLOV, {}, "r-mikhail-orlov_l3").success)
	assert_false(orlov.is_placed(), "off the board")
	assert_false(Fixture.board().is_occupied_by_character(Vector2i(3, 2)))
	TurnManager.victory_checker = null
	VictoryChecker.check_hero_capture("p1")
	assert_eq(Fixture.state().phase, "in_progress", "an off-board Hero isn't captured")
	TurnManager.victory_checker = Fixture.NullChecker.new()
	_pass_to_p1()
	assert_true(RulesEngine.get_offered_bonus_tags(ORLOV).has("return"))
	assert_eq(_act("move", WORKER, {"to": Vector2i(0, 1)}).reason, "return your character to the board first")
	assert_false(_act("reactive_bonus", ORLOV, {"tag": "return", "to": Vector2i(6, 6)}).success, "within 2 of where he left")
	assert_true(_act("reactive_bonus", ORLOV, {"tag": "return", "to": Vector2i(3, 3), "leak": Vector2i(3, 4)}).success)
	assert_eq(orlov.position, Vector2i(3, 3))
	assert_true(sys.has_leak(Vector2i(3, 4)))
	assert_false(_ability(ORLOV, {}, "r-mikhail-orlov_l3").success, "once per match")


# --- Irina Karpova -------------------------------------------------------------------------------

func test_access_granted() -> void:
	Fixture.put(KARPOVA, Vector2i(3, 0))
	var yuri := Fixture.put(YURI, Vector2i(3, 2))
	var naia := Fixture.put(NAIA, Vector2i(3, 4))
	assert_true(_ability(KARPOVA, {"target": YURI}).success)
	assert_eq(_act("attack", YURI, {"target_id": NAIA}).damage, 3, "ATK 2 + 1")
	assert_true(yuri.has_status("temp_atk"), "lasts the whole turn")
	assert_eq(naia.current_hp, 1)


func test_access_granted_level_1_needs_reach_and_line_of_sight() -> void:
	Fixture.put(KARPOVA, Vector2i(3, 0))
	Fixture.put(YURI, Vector2i(6, 6))
	Fixture.put(WORKER, Vector2i(3, 1))
	Fixture.put(ZOYA, Vector2i(3, 2))
	var targets := sys.get_legal_ability_targets(_c(KARPOVA), "r-irina-karpova")
	assert_false(targets.has(YURI), "out of reach")
	assert_false(targets.has(ZOYA), "behind the Worker")


func test_private_favors() -> void:
	var irina := _level(KARPOVA, 2)
	assert_eq(sys.get_effective_max_hp(irina), 5, "+1 HP at Level 2 (balance pass 2026-10-19)")
	Fixture.put(KARPOVA, Vector2i(3, 0))
	Fixture.put(WORKER, Vector2i(3, 1))
	var yuri := Fixture.put(YURI, Vector2i(6, 6))
	var zoya := Fixture.put(ZOYA, Vector2i(3, 2))
	var targets := sys.get_legal_ability_targets(irina, "r-irina-karpova")
	assert_true(targets.has(YURI), "anywhere on the board")
	assert_true(targets.has(ZOYA), "line of sight doesn't matter")
	assert_true(_ability(KARPOVA, {"target": YURI, "target_2": ZOYA}).success)
	assert_true(yuri.has_status("temp_atk"))
	assert_false(zoya.has_status("temp_atk"), "the second target is ignored")
	assert_false(yuri.has_status("ignore_leak_move"), "no Leak immunity any more")



func test_price_of_access_delivers_then_defeats_a_distant_shielded_enemy_for_free() -> void:
	var irina := _level(KARPOVA, 3)
	Fixture.put(KARPOVA, Vector2i(3, 2))
	var naia := Fixture.put(NAIA, Vector2i(6, 6))
	var sahu := Fixture.put(SAHU, Vector2i(0, 6))
	_level(NAIA, 3)
	sys.add_status(naia, "shield", 20, "until_used")
	sys.give_memory(naia)
	irina.spirit_ember_count = 1
	assert_false(RulesEngine.get_usable_ability_ids(KARPOVA).has("r-irina-karpova_l3"))
	assert_true(_act("move", KARPOVA, {"to": CENTER}).success)
	assert_true(RulesEngine.get_offered_bonus_tags(KARPOVA).has("price_of_access"))
	var pool := Fixture.state().get_player("p1").pool_ap_remaining
	var ap := irina.character_ap_remaining
	var step := sys.bonus_step(irina, "price_of_access", {})
	assert_true(step.characters.has(NAIA))
	assert_false(step.characters.has(KARPOVA))
	assert_false(_act("reactive_bonus", KARPOVA, {"tag": "price_of_access", "target": KARPOVA}).success)
	assert_true(_act("reactive_bonus", KARPOVA, {"tag": "price_of_access", "target": NAIA}).success)
	assert_true(naia.defeated, "direct defeat bypasses Shield, Memory and Naia's survival")
	assert_eq(naia.current_hp, 0)
	assert_eq(sys.board.get_tile(Vector2i(6, 6)).occupant_id, "")
	assert_eq(Fixture.state().get_player("p1").pool_ap_remaining, pool)
	assert_eq(irina.character_ap_remaining, ap)
	assert_eq(Fixture.state().get_player("p1").embers_delivered, 2, "defeat's Ember also banks on center")
	assert_false(RulesEngine.get_offered_bonus_tags(KARPOVA).has("price_of_access"), "no recursive offer")
	assert_false(_act("reactive_bonus", KARPOVA, {"tag": "price_of_access", "target": SAHU}).success)
	assert_false(sahu.defeated)


func test_price_of_access_triggers_on_a_defeat_that_levels_irina_and_delivers() -> void:
	var irina := _level(KARPOVA, 2)
	Fixture.put(KARPOVA, CENTER)
	var laborer := Fixture.put(LABORER, Vector2i(3, 4))
	Fixture.put(NAIA, Vector2i(6, 6))
	laborer.current_hp = 1
	assert_true(_act("attack", KARPOVA, {"target_id": LABORER}).success)
	assert_eq(irina.level, 3)
	assert_eq(irina.current_hp, 6, "+1 HP at Level 2 and Level 3")
	assert_eq(Fixture.state().get_player("p1").embers_delivered, 1)
	assert_true(RulesEngine.get_offered_bonus_tags(KARPOVA).has("price_of_access"))
	irina.character_ap_remaining = 0
	Fixture.state().get_player("p1").pool_ap_remaining = 0
	assert_true(_act("reactive_bonus", KARPOVA, {"tag": "price_of_access", "target": NAIA}).success)


func test_price_of_access_requires_irinas_own_level_3_delivery() -> void:
	var irina := _level(KARPOVA, 2)
	Fixture.put(KARPOVA, Vector2i(3, 2))
	Fixture.put(NAIA, Vector2i(6, 6))
	irina.spirit_ember_count = 1
	assert_true(_act("move", KARPOVA, {"to": CENTER}).success)
	assert_false(RulesEngine.get_offered_bonus_tags(KARPOVA).has("price_of_access"))
	_level(KARPOVA, 3)
	var worker := Fixture.put(WORKER, Vector2i(2, 3))
	worker.spirit_ember_count = 1
	Fixture.put(KARPOVA, Vector2i(3, 2))
	assert_true(_act("move", WORKER, {"to": CENTER}).success)
	assert_false(RulesEngine.get_offered_bonus_tags(KARPOVA).has("price_of_access"))
	assert_false(_act("reactive_bonus", KARPOVA, {"tag": "price_of_access", "target": NAIA}).success)


func test_price_of_access_defeats_a_mounted_pair_and_only_once() -> void:
	var irina := _level(KARPOVA, 3)
	Fixture.put(KARPOVA, Vector2i(3, 2))
	var meret := Fixture.put(MERET, Vector2i(0, 5))
	var mount_id := "p2_a-flood-survivor-ahesu"
	var ahesu := Fixture.put(mount_id, Vector2i(0, 6))
	sys.combat().mount_system.mount(meret, ahesu)
	Fixture.put(NAIA, Vector2i(6, 5))
	irina.spirit_ember_count = 1
	assert_true(_act("move", KARPOVA, {"to": CENTER}).success)
	var step := sys.bonus_step(irina, "price_of_access", {})
	assert_false(step.characters.has(mount_id), "target the visible mounted pair via its rider")
	assert_true(_act("reactive_bonus", KARPOVA, {"tag": "price_of_access", "target": MERET}).success)
	assert_true(meret.defeated)
	assert_true(ahesu.defeated)
	assert_eq(Fixture.state().get_player("p1").embers_delivered, 3)
	_pass_to_p1()
	irina.spirit_ember_count = 1
	sys.reposition_character(irina, CENTER, "test")
	assert_false(RulesEngine.get_offered_bonus_tags(KARPOVA).has("price_of_access"))


# --- Dr. Elena Morozova -------------------------------------------------------------------------

func test_dream_link_swaps_a_nearby_ally_with_a_distant_ally() -> void:
	Fixture.put(ELENA, Vector2i(3, 0))
	var yuri := Fixture.put(YURI, Vector2i(3, 2))
	var worker := Fixture.put(WORKER, Vector2i(6, 5))
	sys.add_status(yuri, "shield", 1, "this_turn")
	var ap_before := _c(ELENA).character_ap_remaining
	var pool_before := Fixture.state().get_player("p1").pool_ap_remaining
	assert_true(_ability(ELENA, {"target": YURI, "other": WORKER}).success)
	assert_eq(yuri.position, Vector2i(6, 5))
	assert_eq(worker.position, Vector2i(3, 2))
	assert_eq(sys.board.get_tile(yuri.position).occupant_id, YURI)
	assert_eq(sys.board.get_tile(worker.position).occupant_id, WORKER)
	assert_true(yuri.has_status("shield"), "markers stay with their characters")
	assert_eq(_c(ELENA).character_ap_remaining, ap_before - 1)
	assert_eq(Fixture.state().get_player("p1").pool_ap_remaining, pool_before - 1)


func test_dream_link_level_1_rejects_distant_first_ally_and_enemies() -> void:
	Fixture.put(ELENA, Vector2i(3, 0))
	Fixture.put(YURI, Vector2i(3, 3))
	Fixture.put(WORKER, Vector2i(2, 0))
	Fixture.put(SAHU, Vector2i(6, 5))
	var pool_before := Fixture.state().get_player("p1").pool_ap_remaining
	assert_false(_ability(ELENA, {"target": YURI, "other": WORKER}).success)
	assert_false(_ability(ELENA, {"target": WORKER, "other": SAHU}).success)
	assert_false(_ability(ELENA, {"target": WORKER, "other": WORKER}).success)
	assert_eq(Fixture.state().get_player("p1").pool_ap_remaining, pool_before)


func test_dream_link_level_2_extends_first_pick_but_keeps_allied_swaps() -> void:
	var elena := _level(ELENA, 2)
	Fixture.put(ELENA, Vector2i(3, 0))
	Fixture.put(YURI, Vector2i(3, 4))
	Fixture.put(SAHU, Vector2i(6, 5))
	assert_false(_ability(ELENA, {"target": YURI, "other": SAHU}).success)
	assert_true(_ability(ELENA, {"target": YURI, "other": ELENA}).success)
	assert_eq(elena.position, Vector2i(3, 4))
	assert_eq(_c(YURI).position, Vector2i(3, 0))


func test_dream_link_level_3_swaps_enemies_repeatedly_and_gains_hp() -> void:
	var elena := _level(ELENA, 3)
	assert_eq(elena.current_hp, 4)
	assert_eq(elena.range_bonus, 0)
	Fixture.put(ELENA, Vector2i(3, 0))
	var worker := Fixture.put(WORKER, Vector2i(3, 2))
	var sahu := Fixture.put(SAHU, Vector2i(6, 5))
	assert_false(_ability(ELENA, {"target": SAHU, "other": WORKER}).success)
	assert_true(_ability(ELENA, {"target": WORKER, "other": SAHU}).success)
	assert_eq(worker.position, Vector2i(6, 5))
	assert_eq(sahu.position, Vector2i(3, 2))
	_pass_to_p1()
	Fixture.put(WORKER, Vector2i(2, 0))
	assert_true(_ability(ELENA, {"target": WORKER, "other": SAHU}).success)
	assert_eq(sahu.position, Vector2i(2, 0))


func test_dream_link_respects_line_of_sight_and_forced_movement_protection() -> void:
	_level(ELENA, 3)
	Fixture.put(ELENA, Vector2i(3, 0))
	Fixture.put(YURI, Vector2i(3, 3))
	Fixture.put(WORKER, Vector2i(3, 1))
	var sahu := Fixture.put(SAHU, Vector2i(6, 5))
	assert_false(_ability(ELENA, {"target": YURI, "other": SAHU}).success)
	sys.add_status(sahu, "no_push", 1, "this_turn")
	assert_false(_ability(ELENA, {"target": WORKER, "other": SAHU}).success)


func test_dream_link_moves_a_mounted_pair_and_levels_both_arrivals() -> void:
	Fixture.put(ELENA, Vector2i(3, 0))
	var orlov := Fixture.put(ORLOV, Vector2i(3, 2))
	var vera := Fixture.put(VERA, Vector2i(3, 3))
	var worker := Fixture.put(WORKER, Vector2i(6, 6))
	assert_true(_act("mount", ORLOV, {"mount_id": VERA}).success)
	# Mounting moved Orlov to VERA; bring the pair back into Dream Link range.
	sys.reposition_character(orlov, Vector2i(3, 2), "test")
	var step := sys.ability_step(_c(ELENA), "r-elena-morozova", {"target": ORLOV})
	assert_false(step.characters.has(VERA), "a carried mount is not a separate swap target")
	assert_true(_ability(ELENA, {"target": ORLOV, "other": WORKER}).success)
	assert_eq(orlov.position, Vector2i(6, 6))
	assert_eq(vera.position, orlov.position)
	assert_eq(worker.position, Vector2i(3, 2))
	assert_eq(orlov.level, 2)
	assert_eq(vera.level, 2)
	assert_eq(sys.board.get_tile(orlov.position).occupant_id, ORLOV)


# --- Zoya Miranova ------------------------------------------------------------------------------

func test_voice_under_static_pulls_into_a_leak() -> void:
	Fixture.put(ZOYA, Vector2i(3, 0))
	var laborer := Fixture.put(LABORER, Vector2i(3, 3))
	sys.place_leak(Vector2i(3, 2))
	assert_true(_ability(ZOYA, {"target": LABORER}).success)
	assert_eq(laborer.position, Vector2i(3, 2))
	assert_eq(laborer.current_hp, 0, "the Leak it was pulled onto deals 2")
	assert_true(laborer.defeated, "a 2-HP Laborer doesn't survive a Leak")


func test_subject_three_marks_the_pulled_enemy() -> void:
	_level(ZOYA, 2)
	Fixture.put(ZOYA, Vector2i(3, 0))
	var naia := Fixture.put(NAIA, Vector2i(3, 4))
	assert_true(_ability(ZOYA, {"target": NAIA}).success)
	assert_eq(naia.position, Vector2i(3, 3))
	assert_true(naia.has_status("marked"), "Subject Three")


func test_too_many_names_pulls_then_charms_once_per_match() -> void:
	var zoya := _level(ZOYA, 3)
	assert_eq(sys.get_effective_max_hp(zoya), 4)
	Fixture.put(ZOYA, Vector2i(3, 0))
	Fixture.put(YURI, Vector2i(0, 0))
	var naia := Fixture.put(NAIA, Vector2i(3, 4))
	var laborer := Fixture.put(LABORER, Vector2i(3, 6))
	var result := _ability(ZOYA, {"target": NAIA})
	assert_true(result.success and result.get("charmed", false), str(result))
	assert_eq(naia.position, Vector2i(3, 3), "pulled first")
	assert_eq(naia.player_id, "p1", "then joins Zoya's side")
	assert_true(Fixture.state().get_player("p1").characters.has(naia))
	assert_false(Fixture.state().get_player("p2").characters.has(naia))
	assert_false(naia.has_status("marked"), "no Mark on a new ally")
	assert_eq(naia.character_ap_remaining, 0, "it acts from your next turn")
	assert_string_contains(" ".join(MatchLog.entries[-1].lines), "is charmed and joins")
	_pass_to_p1()
	assert_eq(naia.position, Vector2i(3, 3), "still ours after their turn")
	assert_eq(naia.character_ap_remaining, 1, "refreshes on its new owner's turn")
	Fixture.put(LABORER, Vector2i(5, 0))
	assert_true(_ability(ZOYA, {"target": LABORER}).success)
	assert_eq(laborer.player_id, "p2", "once per match")


func test_too_many_names_never_charms_a_hero_and_waits_for_a_valid_target() -> void:
	_level(ZOYA, 3)
	Fixture.put(ZOYA, Vector2i(3, 0))
	var sahu := Fixture.put(SAHU, Vector2i(3, 3))
	assert_true(_ability(ZOYA, {"target": SAHU}).success)
	assert_eq(sahu.player_id, "p2", "a Hero can't be charmed")
	assert_eq(sahu.position, Vector2i(3, 2), "but it is still pulled")
	_pass_to_p1()
	var naia := Fixture.put(NAIA, Vector2i(0, 0))
	Fixture.put(ZOYA, Vector2i(0, 3))
	assert_true(_ability(ZOYA, {"target": NAIA}).get("charmed", false), "the charm wasn't spent on the Hero")


func test_too_many_names_charms_a_mounted_pair_together() -> void:
	_level(ZOYA, 3)
	var ahesu_id := "p2_a-flood-survivor-ahesu"
	var meret := Fixture.put(MERET, Vector2i(3, 4))
	var ahesu := Fixture.put(ahesu_id, Vector2i(3, 5))
	Fixture.put(SAHU, Vector2i(6, 6))
	_act("end_turn", "p1")
	assert_true(_act("mount", MERET, {"mount_id": ahesu_id}).success)
	_act("end_turn", "p2")
	Fixture.put(ZOYA, Vector2i(3, 2))
	assert_true(_ability(ZOYA, {"target": MERET}).get("charmed", false))
	assert_eq(meret.player_id, "p1")
	assert_eq(ahesu.player_id, "p1", "the Mount comes with its rider")


func test_charming_the_last_enemy_piece_is_army_defeat() -> void:
	_level(ZOYA, 3)
	Fixture.put(ZOYA, Vector2i(3, 0))
	var naia := Fixture.put(NAIA, Vector2i(3, 4))
	for c in Fixture.state().get_player("p2").characters:
		if c != naia:
			c.defeated = true
	assert_true(_ability(ZOYA, {"target": NAIA}).get("charmed", false))
	assert_eq(Fixture.state().phase, "ended")
	assert_eq(Fixture.state().winner_id, "p1")
	assert_eq(Fixture.state().win_condition, "army_defeat")
