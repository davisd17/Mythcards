extends GutTest
# TestBridge's pure halves (LLD-test-bridge.md cases C1–C6). The JS glue itself is
# exercised by the Playwright suite in e2e/ against a Web export.

const Fixture := preload("res://tests/helpers/match_fixture.gd")


func before_each() -> void:
	autofree(Fixture.start_match())
	Fixture.state().get_player("p1").pool_ap_remaining = 4


func after_each() -> void:
	Fixture.teardown()


func test_c1_state_matches_the_schema() -> void:
	var s := TestBridge.serialize_state()
	assert_eq(s.phase, "in_progress")
	assert_eq(s.turn_number, 1)
	assert_eq(s.active_player_id, "p1")
	assert_eq(s.players.keys(), ["p1", "p2"])
	assert_eq(s.players.p1.characters.size(), 7)
	var gymnast: Dictionary = s.players.p1.characters[0]
	assert_eq(gymnast.instance_id, "p1_r-gymnast")
	assert_eq(gymnast.position, {"x": 0, "y": 0})
	assert_eq(gymnast.current_hp, 2)
	assert_true(JSON.stringify(s).length() > 0, "JSON-safe")
	assert_eq(JSON.parse_string(JSON.stringify(s)).players.p1.characters[0].position.x, 0.0)


func test_state_includes_objects_frost_and_pending_choice() -> void:
	Fixture.board().place_object(Vector2i(2, 2), "barricade", "p1")
	Fixture.board().get_tile(Vector2i(4, 4)).terrain_type = "frost"
	Fixture.state().get_player("p1").active_relic_id = "r-reactor-core-fragment"
	Fixture.state().shared_deck = ["r-karpovas-black-key"] as Array[String]
	TurnManager.relic_event_deck = null
	RelicEventDeck.draw_for("p1")
	var s := TestBridge.serialize_state()
	assert_eq(s.objects, [{"type": "barricade", "position": {"x": 2, "y": 2}, "current_hp": 2, "max_hp": 2, "owner": "p1"}])
	assert_eq(s.frost, [{"x": 4, "y": 4}])
	assert_eq(s.pending_choice.kind, "relic")
	assert_eq(s.pending_choice.card_id, "r-karpovas-black-key")
	assert_eq(s.pending_choice.options.size(), 2)


func test_c2_no_match_gives_the_empty_shape() -> void:
	Fixture.teardown()
	assert_eq(TestBridge.serialize_state(), {"phase": "", "turn_number": 0, "active_player_id": "",
			"winner_id": "", "win_condition": "", "players": {}})


func test_c3_c6_dispatch_converts_positions_and_round_trips() -> void:
	Fixture.clear_board()
	Fixture.put(Fixture.GYMNAST, Vector2i(3, 0))
	var result := TestBridge.dispatch_action(
			'{"action_type":"move","actor_id":"p1_r-gymnast","payload":{"to":{"x":3,"y":2}}}')
	assert_eq(result, {"success": true})
	assert_eq(Fixture.character(Fixture.GYMNAST).position, Vector2i(3, 2))
	var moved: Dictionary = TestBridge.serialize_state().players.p1.characters[0]
	assert_eq(moved.position, {"x": 3, "y": 2})


func test_positions_inside_lists_convert_too() -> void:
	Fixture.clear_board()
	Fixture.put("p1_r-engineer", Vector2i(3, 3))
	Fixture.character("p1_r-engineer").level = 2
	var result := TestBridge.dispatch_action(JSON.stringify({"action_type": "ability", "actor_id": "p1_r-engineer",
			"payload": {"ability_id": "r-engineer", "targets": [{"x": 3, "y": 4}, {"x": 4, "y": 3}]}}))
	assert_true(result.success, str(result))
	assert_not_null(Fixture.board().get_placed_object(Vector2i(4, 3)))


func test_c4_malformed_json_never_reaches_the_engine() -> void:
	watch_signals(EventBus)
	assert_eq(TestBridge.dispatch_action("{not json"), {"success": false, "reason": "malformed action JSON"})
	assert_eq(TestBridge.dispatch_action('{"actor_id": "p1"}'), {"success": false, "reason": "malformed action JSON"})
	assert_eq(TestBridge.dispatch_action('{"action_type": "end_turn", "actor_id": "p1", "payload": 3}'),
			{"success": false, "reason": "malformed action JSON"})
	assert_signal_not_emitted(EventBus, "action_requested")


func test_invalid_actions_pass_through_the_engine() -> void:
	assert_eq(TestBridge.dispatch_action('{"action_type":"end_turn","actor_id":"p2"}'),
			{"success": false, "reason": "not your turn"})


func test_c5_vector_results_become_json_safe() -> void:
	assert_eq(TestBridge._to_json_safe({"success": true, "landed": Vector2i(1, 2), "path": [Vector2i(0, 0)]}),
			{"success": true, "landed": {"x": 1, "y": 2}, "path": [{"x": 0, "y": 0}]})


func test_bridge_is_inert_outside_the_tagged_web_export() -> void:
	# GUT runs in desktop Godot: no web feature, so no JS callbacks were registered.
	assert_false(OS.has_feature("web"))
	assert_eq(TestBridge._callbacks, [])
