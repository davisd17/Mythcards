extends GutTest
# teams.json (LLD-closed-city-flood-roster.md 2): the playtest matchup, the hidden original
# teams, and team validation.

const SetupFlowScript := preload("res://scripts/scenes/setup_flow.gd")


func after_each() -> void:
	GameState.reset()


func test_the_game_plays_closed_city_vs_flood_survivors() -> void:
	assert_eq(ContentDB.get_matchup(), ["closed-city", "flood-survivors"] as Array[String])
	assert_eq(ContentDB.get_team("closed-city").name, "Closed City")
	assert_eq(ContentDB.get_team_characters("flood-survivors").size(), 7)


func test_team_cards_are_playable_but_unlisted_drafts_are_not() -> void:
	assert_not_null(ContentDB.get_character("r-reactor-worker"), "listed in a team")
	assert_null(ContentDB.get_character("r-hospital-orderly"), "an alternate draft stays a draft")
	assert_not_null(ContentDB.get_draft_character("r-hospital-orderly"))


func test_original_teams_are_hidden_but_still_playable() -> void:
	assert_false(ContentDB.get_team("original-russian").offered)
	var setup: Node = autofree(SetupFlowScript.new())
	setup.select_team("p1", "original-russian")
	assert_eq(setup.get_player("p1").characters[0].data.char_name, "Gymnast")


func test_select_team_builds_the_squad_in_team_order() -> void:
	var setup: Node = autofree(SetupFlowScript.new())
	setup.select_team("p2", "flood-survivors")
	var player: PlayerState = setup.get_player("p2")
	assert_eq(player.team_id, "flood-survivors")
	assert_eq(player.culture, "Atlantean")
	assert_eq(player.characters[3].instance_id, "p2_a-flood-survivor-sahu-ren")


func test_validation_reports_a_broken_team() -> void:
	var saved: Dictionary = ContentDB.teams.duplicate(true)
	ContentDB.teams["broken"] = {"name": "Broken", "culture": "Atlantean", "characters": ["a-flood-survivor-naia"]}
	var errors := ContentDB.validate()
	ContentDB.teams = saved
	assert_true(errors.any(func(e): return e.contains("team 'broken' has 0 Common")), str(errors))


func test_board_tags_are_unique_in_the_matchup() -> void:
	var seen := {}
	for team_id in ContentDB.get_matchup():
		for data in ContentDB.get_team_characters(team_id):
			var tag := DebugPanel.abbreviation(data)
			assert_false(seen.has(tag), "%s and %s share %s" % [seen.get(tag, ""), data.char_name, tag])
			seen[tag] = data.char_name
	assert_eq(DebugPanel.abbreviation(ContentDB.get_character("a-flood-survivor-sahu-ren")), "SR")
