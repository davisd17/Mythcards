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
	assert_eq(sys.get_effective_max_hp(orlov), 6, "+1 max HP while riding VERA-7")
	assert_eq(orlov.current_hp, 6)
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


func test_private_favors_and_the_door() -> void:
	_level(KARPOVA, 3)
	Fixture.put(KARPOVA, Vector2i(3, 0))
	var worker := Fixture.put(WORKER, Vector2i(3, 2))
	var zoya := Fixture.put(ZOYA, Vector2i(2, 0))
	Fixture.put(LABORER, Vector2i(0, 6))
	assert_true(_ability(KARPOVA, {"target": ZOYA, "target_2": WORKER}).success)
	sys.place_leak(Vector2i(2, 1))
	assert_true(_act("move", ZOYA, {"to": Vector2i(2, 2)}).success)
	assert_eq(zoya.current_hp, 3, "ignores Leak damage on its next move")
	assert_true(sys.has_leak(Vector2i(2, 1)))
	_pass_to_p1()
	assert_true(_ability(KARPOVA, {"target": WORKER}, "r-irina-karpova_l3").success)
	assert_true(_act("reactive_bonus", WORKER, {"tag": "free_move", "to": Vector2i(3, 3)}).success)
	assert_eq(worker.position, Vector2i(3, 3))


# --- Dr. Elena Morozova -------------------------------------------------------------------------

func test_dream_link_moves_a_marker_between_allies() -> void:
	Fixture.put(ELENA, Vector2i(3, 0))
	var yuri := Fixture.put(YURI, Vector2i(3, 2))
	var worker := Fixture.put(WORKER, Vector2i(4, 2))
	sys.add_status(yuri, "shield", 1, "this_turn")
	var step := sys.ability_step(_c(ELENA), "r-elena-morozova", {"target": YURI, "other": WORKER})
	assert_eq(step.options.size(), 1)
	assert_true(_ability(ELENA, {"target": YURI, "other": WORKER, "marker": step.options[0].value}).success)
	assert_false(yuri.has_status("shield"))
	assert_true(worker.has_status("shield"))


func test_signal_breach_steals_memory_and_shields_elena() -> void:
	var elena := _level(ELENA, 2)
	Fixture.put(ELENA, Vector2i(3, 0))
	var sahu := Fixture.put(SAHU, Vector2i(3, 3))
	var worker := Fixture.put(WORKER, Vector2i(2, 0))
	sys.give_memory(sahu)
	assert_true(_ability(ELENA, {"target": SAHU, "other": WORKER,
			"marker": {"from": SAHU, "type": "memory", "index": 0}}).success, "Memory moves (ruling 2026-10-07)")
	assert_eq(sys.memory_count(sahu), 0)
	assert_eq(sys.memory_count(worker), 1)
	_pass_to_p1()
	sys.add_status(worker, "marked", 1, "until_used")
	assert_true(_ability(ELENA, {"target": WORKER, "other": SAHU,
			"marker": {"from": WORKER, "type": "marked", "index": 0}}).success)
	assert_true(sahu.has_status("marked"))
	assert_true(elena.has_status("shield"), "a harmful marker moved onto an enemy")


func test_missing_in_the_signal() -> void:
	var elena := _level(ELENA, 3)
	Fixture.put(ELENA, Vector2i(3, 2))
	Fixture.put(WORKER, Vector2i(0, 0))
	assert_true(_ability(ELENA, {}, "r-elena-morozova_l3").success)
	assert_false(elena.is_placed())
	_pass_to_p1()
	assert_false(sys.return_tiles(elena).has(Vector2i(5, 5)), "next to an ally")
	assert_true(_act("reactive_bonus", ELENA, {"tag": "return", "to": Vector2i(1, 0)}).success)
	assert_eq(elena.position, Vector2i(1, 0))


# --- Zoya Miranova ------------------------------------------------------------------------------

func test_voice_under_static_pulls_into_a_leak() -> void:
	Fixture.put(ZOYA, Vector2i(3, 0))
	var laborer := Fixture.put(LABORER, Vector2i(3, 3))
	sys.place_leak(Vector2i(3, 2))
	assert_true(_ability(ZOYA, {"target": LABORER}).success)
	assert_eq(laborer.position, Vector2i(3, 2))
	assert_eq(laborer.current_hp, 1, "the Leak it was pulled onto")


func test_subject_three_and_too_many_names() -> void:
	_level(ZOYA, 3)
	Fixture.put(ZOYA, Vector2i(3, 0))
	var naia := Fixture.put(NAIA, Vector2i(3, 4))
	assert_true(_ability(ZOYA, {"target": NAIA}).success)
	assert_eq(naia.position, Vector2i(3, 3))
	assert_true(naia.has_status("marked"), "Subject Three")
	assert_true(RulesEngine.get_offered_bonus_tags(ZOYA).has("too_many_names"))
	assert_true(_act("reactive_bonus", ZOYA, {"tag": "too_many_names", "target": NAIA}).success)
	assert_eq(naia.position, Vector2i(3, 2), "a free second pull")
	assert_eq(Fixture.state().get_player("p1").pool_ap_remaining, 3)
