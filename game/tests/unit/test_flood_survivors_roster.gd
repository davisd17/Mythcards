extends GutTest
# The Flood Survivors team (LLD-closed-city-flood-roster.md 4), played through RulesEngine
# against Closed City. Most tests start on Flood Survivors' (p2's) turn.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const LABORER := "p2_a-flood-survivor-stone-line-laborer"   # Common 2/1/2/1
const AHESU := "p2_a-flood-survivor-ahesu"                   # Mount 4/1/4/1
const NAIA := "p2_a-flood-survivor-naia"                     # Warrior 4/2/3/1
const SAHU := "p2_a-flood-survivor-sahu-ren"                 # Hero 5/1/2/3
const MERET := "p2_a-flood-survivor-meret-anu"               # Leader 4/1/2/3
const ISET := "p2_a-flood-survivor-iset-nara"                # Specialist 3/1/2/2
const THALASSA := "p2_a-flood-survivor-thalassa-nekh"        # Mystic 4/1/2/2
const WORKER := "p1_r-reactor-worker"     # 3/1/2/1
const YURI := "p1_r-yuri-volkov"          # 4/2/2/2
const ZOYA := "p1_r-zoya-miranova"        # 3/1/2/3

var sys: AbilitySystem


func before_each() -> void:
	autofree(Fixture.start_teams_match())
	Fixture.state().shared_deck.clear()
	Fixture.clear_board()
	sys = RulesEngine.systems().ability
	_act("end_turn", "p1")    # Flood Survivors to act, with a full 4-AP pool


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


func _pass_to_p2() -> void:
	_act("end_turn", "p2")
	_act("end_turn", "p1")


func _hit(target: CharacterInstance, amount: int, attacker_id: String = YURI) -> Dictionary:
	return sys.combat().apply_damage(_c(attacker_id), target, amount, false)


func test_team_is_the_flood_survivors_seven() -> void:
	var names := Fixture.state().get_player("p2").characters.map(func(c): return c.data.char_name)
	assert_eq(names, ["Stone-Line Laborer", "Ahesu, the Stone-Current Serpent", "Naia of the Black Sarcophagus",
			"Sahu-Ren, Last Memory-Keeper", "Queen Meret-Anu, Keeper of the Buried Tide",
			"Iset-Nara, Architect of the Hidden Vault", "Thalassa-Nekh, Vessel of the Drowned Seraph"])


# --- Stone-Line Laborer -------------------------------------------------------------------

func test_stone_line() -> void:
	Fixture.put(LABORER, Vector2i(3, 6))
	assert_true(_ability(LABORER, {"target": Vector2i(3, 5)}).success)
	var stone := Fixture.board().get_placed_object(Vector2i(3, 5))
	assert_eq([stone.type_id, stone.owner_player_id, stone.max_hp], ["stone", "p2", 1])
	_level(LABORER, 2)
	_pass_to_p2()
	assert_true(_ability(LABORER, {"target": Vector2i(2, 6), "target_2": Vector2i(4, 6)}).success, "Causeway Crew: 2 Stones")


func test_route_to_the_surface() -> void:
	var laborer := _level(LABORER, 3)              # MOVE 3
	Fixture.put(LABORER, Vector2i(3, 6))
	Fixture.board().place_object(Vector2i(3, 5), "stone", "p2")
	assert_true(_act("move", LABORER, {"to": Vector2i(3, 3)}).success, "through the Stone")
	assert_true(laborer.has_status("shield"), "after moving through a Stone")


# --- Ahesu ---------------------------------------------------------------------------------

func test_stone_current_passes_allied_stones_only() -> void:
	Fixture.put(AHESU, Vector2i(3, 6))
	Fixture.board().place_object(Vector2i(3, 5), "stone", "p2")
	Fixture.board().place_object(Vector2i(3, 3), "stone", "p2")
	assert_true(RulesEngine.get_legal_move_tiles(AHESU).has(Vector2i(3, 2)), "any number of allied Stones")
	Fixture.board().place_object(Vector2i(2, 5), "barricade", "p1")
	Fixture.put(AHESU, Vector2i(2, 6))
	assert_false(RulesEngine.get_legal_move_tiles(AHESU).has(Vector2i(2, 4)), "not an enemy object")


func test_living_causeway_and_teeth() -> void:
	var ahesu := _level(AHESU, 2)                  # MOVE 5
	Fixture.put(AHESU, Vector2i(3, 6))
	Fixture.put(NAIA, Vector2i(3, 5))
	Fixture.put(SAHU, Vector2i(3, 3))
	assert_false(RulesEngine.get_legal_move_tiles(AHESU).has(Vector2i(3, 4)), "no Stone next to it yet")
	Fixture.board().place_object(Vector2i(2, 6), "stone", "p2")
	var moves := RulesEngine.get_legal_move_tiles(AHESU)
	assert_true(moves.has(Vector2i(3, 4)), "started next to a Stone: passes 1 ally")
	assert_false(moves.has(Vector2i(3, 2)), "but not 2")
	_level(AHESU, 3)
	assert_eq(ahesu.get_effective_atk(), 3)
	assert_eq(sys.get_effective_max_hp(ahesu), 5)


# --- Naia --------------------------------------------------------------------------------------

func test_tomb_sentinel_first_damage_each_turn() -> void:
	var naia := Fixture.put(NAIA, Vector2i(3, 3))
	Fixture.board().place_object(Vector2i(3, 4), "stone", "p2")
	assert_eq(_hit(naia, 2).damage, 1, "next to a placed object: -1")
	assert_eq(_hit(naia, 2).damage, 2, "only the first damage this turn")
	_act("end_turn", "p2")
	assert_eq(_hit(naia, 2).damage, 1, "each turn, including the opponent's")


func test_sarcophagus_oath_and_open_the_sarcophagus() -> void:
	var naia := _level(NAIA, 3)
	Fixture.put(NAIA, Vector2i(3, 3))
	var yuri := Fixture.put(YURI, Vector2i(3, 4))
	sys.place_leak(Vector2i(2, 3))                  # a Leak counts as a placed object
	assert_true(_act("attack", NAIA, {"target_id": YURI}).success)
	assert_true(yuri.has_status("marked"), "Sarcophagus Oath")
	naia.current_hp = 1
	var hit := _hit(naia, 5)
	assert_false(hit.defeated)
	assert_eq(naia.current_hp, 1, "stays at 1 HP once per match")
	assert_eq(yuri.sum_status("marked"), 2, "the adjacent attacker is Marked again")


# --- Sahu-Ren ---------------------------------------------------------------------------------

func test_living_archive() -> void:
	var sahu := Fixture.put(SAHU, Vector2i(3, 3))
	var naia := Fixture.put(NAIA, Vector2i(3, 5))
	_hit(naia, 1)
	assert_eq(sys.memory_count(sahu), 1, "an ally within 2 took damage")
	_hit(naia, 1)
	assert_eq(sys.memory_count(sahu), 1, "only the first time each turn")
	_act("end_turn", "p2")
	_hit(naia, 1)
	_act("end_turn", "p1")
	_hit(naia, 1)
	assert_eq(sys.memory_count(sahu), 3, "holds up to 3")
	_act("end_turn", "p2")
	_hit(naia, 1)
	assert_eq(sys.memory_count(sahu), 3)


func test_forbidden_testimony_and_last_memory() -> void:
	var sahu := _level(SAHU, 3)
	Fixture.put(SAHU, Vector2i(3, 3))
	var yuri := Fixture.put(YURI, Vector2i(3, 0))
	for i in 3:
		sahu.ability_uses_this_match.erase("archive_turn")
		sys.give_memory(sahu)
	assert_true(RulesEngine.get_offered_bonus_tags(SAHU).has("forbidden_testimony"))
	assert_true(_act("reactive_bonus", SAHU, {"tag": "forbidden_testimony", "target_id": YURI}).success)
	assert_true(yuri.has_status("marked"))
	assert_eq(sys.memory_count(sahu), 2)
	var result := _ability(SAHU, {"target": YURI, "target_2": YURI}, "a-flood-survivor-sahu-ren_l3")
	assert_true(result.success, str(result))
	assert_eq(yuri.current_hp, 1, "2 damage, +1 from the Mark")
	assert_eq(sys.memory_count(sahu), 0)


# --- Queen Meret-Anu ------------------------------------------------------------------------

func test_memory_discipline() -> void:
	var meret := Fixture.put(MERET, Vector2i(3, 6))
	var naia := Fixture.put(NAIA, Vector2i(0, 0))   # any ally, anywhere
	assert_true(_ability(MERET, {"target": NAIA}).success)
	assert_eq(sys.memory_count(naia), 1)
	assert_eq(sys.memory_count(meret), 1, "she gains one too")
	assert_eq(_hit(naia, 2).damage, 1, "Memory blocks 1")


func test_tide_sealed_archive() -> void:
	_level(MERET, 3)
	Fixture.put(MERET, Vector2i(3, 6))
	var naia := Fixture.put(NAIA, Vector2i(3, 3))
	sys.give_memory(naia)
	assert_true(_ability(MERET, {}, "a-flood-survivor-meret-anu_l3").success)
	_act("end_turn", "p2")
	var hit := _hit(naia, 10)
	assert_false(hit.defeated)
	assert_eq(naia.current_hp, 1)
	assert_eq(sys.memory_count(naia), 0)
	_hit(naia, 5)
	assert_true(naia.defeated, "no Memory left")


# --- Iset-Nara ----------------------------------------------------------------------------------

func test_hidden_geometry_moves_any_object() -> void:
	Fixture.put(ISET, Vector2i(3, 3))
	sys.place_leak(Vector2i(3, 4))
	assert_true(_ability(ISET, {"target": Vector2i(3, 4), "to": Vector2i(3, 6)}).success)
	assert_true(sys.has_leak(Vector2i(3, 6)))
	assert_false(sys.has_leak(Vector2i(3, 4)))


func test_vault_surveyor_and_hidden_vault() -> void:
	_level(ISET, 3)
	var iset := Fixture.put(ISET, Vector2i(3, 3))
	Fixture.board().place_object(Vector2i(3, 5), "barricade", "p1")
	assert_true(sys.get_legal_ability_targets(iset, iset.data.id).has(Vector2i(3, 5)), "within 2")
	Fixture.board().place_object(Vector2i(0, 5), "stone", "p2")
	var naia := Fixture.put(NAIA, Vector2i(0, 3))
	assert_true(_ability(ISET, {"target": Vector2i(0, 4)}, "a-flood-survivor-iset-nara_l3").success)
	var vault := Fixture.board().get_placed_object(Vector2i(0, 4))
	assert_eq([vault.type_id, vault.max_hp, vault.owner_player_id], ["vault", 3, "p2"])
	_pass_to_p2()
	assert_true(naia.has_status("shield"), "next to the Vault at the start of your turn")


# --- Thalassa-Nekh -------------------------------------------------------------------------------

func test_black_water_communion_and_drowned_judgment() -> void:
	_level(THALASSA, 2)
	Fixture.put(THALASSA, Vector2i(3, 6))
	var naia := Fixture.put(NAIA, Vector2i(3, 4))
	assert_true(_ability(THALASSA, {"target": NAIA}).success)
	assert_eq(sys.memory_count(naia), 1)
	_act("end_turn", "p2")
	var zoya := Fixture.put(ZOYA, Vector2i(3, 1))
	assert_true(_act("attack", ZOYA, {"target_id": NAIA}).success)
	assert_true(zoya.has_status("marked"), "the attacker that made Naia spend Memory")


func test_seraph_form() -> void:
	var thalassa := _level(THALASSA, 3)
	Fixture.put(THALASSA, Vector2i(3, 6))
	assert_true(_ability(THALASSA, {}, "a-flood-survivor-thalassa-nekh_l3").success)
	assert_eq(thalassa.get_effective_atk(), 3)
	assert_eq(thalassa.get_effective_range("attack"), 4, "2 + L2 + Seraph")
	_pass_to_p2()
	assert_false(_ability(THALASSA, {}, "a-flood-survivor-thalassa-nekh_l3").success, "once per match")
