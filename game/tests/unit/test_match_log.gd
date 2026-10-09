extends GutTest
# MatchLog (playtest 2026-10-09): every action, with each bonus and reduction named by
# where it came from.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const YURI := "p1_r-yuri-volkov"
const KARPOVA := "p1_r-irina-karpova"
const WORKER := "p1_r-reactor-worker"
const NAIA := "p2_a-flood-survivor-naia"


func before_each() -> void:
	autofree(Fixture.start_teams_match())
	Fixture.state().shared_deck.clear()
	Fixture.clear_board()
	Fixture.state().get_player("p1").pool_ap_remaining = 4


func after_each() -> void:
	Fixture.teardown()


func _act(action: String, actor: String, payload: Dictionary = {}) -> Dictionary:
	return RulesEngine.request_action(action, actor, payload)


func _last() -> Dictionary:
	return MatchLog.entries[-1]


func test_a_new_match_starts_a_new_log() -> void:
	assert_eq(MatchLog.entries.size(), 1)
	assert_string_contains(MatchLog.entries[0].text, "Player 1 (Closed City)'s turn begins (2 AP)")


func test_an_attack_names_every_bonus_and_reduction() -> void:
	Fixture.put(KARPOVA, Vector2i(3, 0))
	Fixture.put(YURI, Vector2i(3, 2))
	Fixture.put(NAIA, Vector2i(3, 3))
	Fixture.board().place_object(Vector2i(4, 3), "stone", "p2")
	_act("ability", KARPOVA, {"ability_id": "r-irina-karpova", "target": YURI})
	assert_eq(_last().text, "Irina Vasilievna Karpova uses Access Granted on Major Yuri Volkov")
	assert_eq(_last().lines, ["Major Yuri Volkov gains +ATK 1 (from Irina Vasilievna Karpova)"])
	_act("attack", YURI, {"target_id": NAIA})
	assert_eq(_last().text, "Major Yuri Volkov attacks Naia of the Black Sarcophagus")
	var line: String = _last().lines[0]
	assert_string_contains(line, "deals 2 to Naia of the Black Sarcophagus")
	assert_string_contains(line, "ATK 2 (printed)")
	assert_string_contains(line, "+1 from Irina Vasilievna Karpova")
	assert_string_contains(line, "adjacent attack")
	assert_string_contains(line, "-1 Naia of the Black Sarcophagus's own ability")


func test_moves_failures_and_leaks_are_logged() -> void:
	Fixture.put(WORKER, Vector2i(3, 0))
	_act("move", WORKER, {"to": Vector2i(6, 6)})
	assert_true(_last().failed)
	assert_string_contains(_last().text, "(failed: illegal move)")
	RulesEngine.systems().ability.place_leak(Vector2i(0, 1))
	Fixture.put("p1_r-zoya-miranova", Vector2i(0, 0))
	_act("move", "p1_r-zoya-miranova", {"to": Vector2i(0, 2)})
	assert_eq(_last().text, "Zoya Miranova moves 2 up")
	assert_eq(_last().lines[0], "Zoya Miranova triggers a Leak")
	assert_string_contains(_last().lines[1], "Zoya Miranova takes 1: 1 hazard damage (no attacker)")


func test_text_groups_by_turn() -> void:
	_act("end_turn", "p1")
	var text := MatchLog.as_text()
	assert_string_contains(text, "Turn 1\n")
	assert_string_contains(text, "Turn 2\n")
	assert_string_contains(text, "Player 1 (Closed City) ends the turn")


func test_ending_the_turn_closes_before_the_next_turn_begins() -> void:
	TurnManager.relic_event_deck = null
	Fixture.state().shared_deck = ["r-seventeen-seconds"] as Array[String]
	_act("end_turn", "p1")
	var n := MatchLog.entries.size()
	assert_string_contains(MatchLog.entries[n - 2].text, "Player 1 (Closed City) ends the turn")
	assert_eq(MatchLog.entries[n - 2].turn, 1)
	assert_string_contains(_last().text, "Player 2 (Flood Survivors)'s turn begins")
	assert_string_contains(_last().lines[0], "draws Seventeen Seconds (event)")
	var turns := MatchLog.entries.map(func(e): return e.turn)
	var sorted := turns.duplicate()
	sorted.sort()
	assert_eq(turns, sorted, "turn headings never go backwards")


func test_tile_targets_say_where() -> void:
	Fixture.put("p1_r-mikhail-orlov", Vector2i(3, 0))
	_act("ability", "p1_r-mikhail-orlov", {"ability_id": "r-mikhail-orlov", "target": Vector2i(3, 2)})
	assert_eq(_last().text, "Dr. Mikhail Orlov uses Reactor Leak on the tile 2 up")
