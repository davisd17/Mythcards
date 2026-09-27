extends GutTest
# ContentDB — LLD-content-board.md Section 8, cases C1–C6a, against the original
# 14-card prototype roster (PRD Section 8).

const ContentDBScript := preload("res://scripts/autoloads/content_db.gd")

const RUSSIAN := "Russian-inspired"
const ATLANTEAN := "Atlantean"

var db


func before_each() -> void:
	db = autofree(ContentDBScript.new())


func _load_real_data() -> void:
	db.load_all()


# A complete, valid 7-character culture, used as the base for broken fixtures.
func _valid_culture(culture: String, prefix: String) -> Array:
	var entries := []
	for t in GameEnums.CHARACTER_TYPES:
		entries.append({
			"id": "%s-%s" % [prefix, t.to_lower()],
			"faction": culture,
			"culture": culture,
			"sub_area": "Test Area",
			"name": "%s %s" % [culture, t],
			"type": t,
			"stats": [3, 1, 2, 1],
		})
	return entries


# --- Real committed data -----------------------------------------------------

func test_c1_loads_all_14_playable_characters() -> void:
	_load_real_data()
	assert_eq(db.characters.size(), 14)
	var gymnast: CharacterData = db.get_character("r-gymnast")
	assert_not_null(gymnast)
	assert_eq(gymnast.hp, 2)
	assert_eq(gymnast.atk, 1)
	assert_eq(gymnast.move, 3)
	assert_eq(gymnast.range, 1)
	assert_eq(gymnast.char_name, "Gymnast")


func test_c1_stats_map_in_hp_atk_move_range_order() -> void:
	_load_real_data()
	var sniper: CharacterData = db.get_character("r-sniper")  # stats [3, 2, 2, 4]
	assert_eq([sniper.hp, sniper.atk, sniper.move, sniper.range], [3, 2, 2, 4])


func test_c2_each_culture_has_one_of_each_type() -> void:
	_load_real_data()
	for culture in [RUSSIAN, ATLANTEAN]:
		var chars: Array[CharacterData] = db.get_characters_by_culture(culture)
		assert_eq(chars.size(), 7, "%s squad size" % culture)
		var types := chars.map(func(c): return c.type)
		for t in GameEnums.CHARACTER_TYPES:
			assert_eq(types.count(t), 1, "%s has exactly one %s" % [culture, t])


func test_c2_prototype_roster_is_the_original_14() -> void:
	_load_real_data()
	for id in ["r-gymnast", "r-tiger", "r-sniper", "r-general", "r-hero", "r-engineer", "r-seer",
			"a-attendant", "a-glider", "a-guard", "a-conductor", "a-hero", "a-architect", "a-harmonic"]:
		assert_not_null(db.get_character(id), id)


func test_c6a_committed_sub_areas_are_single_values() -> void:
	# The four formerly combined entries (LLD-content-board Section 9).
	_load_real_data()
	assert_eq(db.get_character("r-hero").sub_area, "Winter Front")
	assert_eq(db.get_character("r-engineer").sub_area, "Winter Front")
	assert_eq(db.get_character("a-attendant").sub_area, "First Mind")
	assert_eq(db.get_character("a-harmonic").sub_area, "First Mind")


func test_c4_loads_14_playable_relic_events_with_no_review_status() -> void:
	_load_real_data()
	assert_eq(db.relic_events.size(), 14)
	for r: RelicEventData in db.relic_events.values():
		assert_eq(r.review_status, "", r.id)
		assert_eq(db.get_relic_event(r.id), r)


func test_each_faction_contributes_3_relics_and_4_events() -> void:
	# PRD Section 9 deck construction (BR-027A).
	_load_real_data()
	for faction in ["Russian-Inspired", "Atlantean"]:
		var cards: Array[RelicEventData] = db.get_playable_relic_events_by_faction(faction)
		assert_eq(cards.filter(func(r): return r.is_relic()).size(), 3, "%s relics" % faction)
		assert_eq(cards.filter(func(r): return r.is_event()).size(), 4, "%s events" % faction)


func test_c5_review_drafts_load_separately_from_playable() -> void:
	_load_real_data()
	assert_gt(db.draft_relic_events.size(), 0, "draft relic/events loaded")
	assert_gt(db.draft_characters.size(), 0, "draft characters loaded")
	for r: RelicEventData in db.draft_relic_events.values():
		assert_eq(r.review_status, ContentDBScript.DRAFT_STATUS, r.id)
	# A draft-only card is reachable only through the draft accessor (BR-043A).
	var draft_only := "a-flood-survivor-ley-stones-align"
	assert_not_null(db.get_draft_relic_event(draft_only))
	assert_null(db.get_relic_event(draft_only))
	var playable_ids: Array = db.get_playable_relic_events_by_faction("Atlantean").map(func(r): return r.id)
	assert_false(playable_ids.has(draft_only))


func test_design_documents_in_drafts_dir_are_skipped() -> void:
	# tarot_area_mapping.json etc. are JSON objects, not card lists.
	_load_real_data()
	assert_eq(db._load_errors, [] as Array[String])


func test_committed_data_passes_validation() -> void:
	_load_real_data()
	assert_eq(db.validate(), [] as Array[String])


# --- Fixtures ----------------------------------------------------------------

func test_c3_missing_hero_is_reported() -> void:
	var entries := _valid_culture("Test Culture", "t").filter(func(e): return e.type != "Hero")
	db.add_character_entries(entries, false)
	var errors: Array[String] = db.validate()
	assert_eq(errors.size(), 1)
	assert_string_contains(errors[0], "0 Hero")


func test_c3_duplicate_type_in_culture_is_reported() -> void:
	var entries := _valid_culture("Test Culture", "t")
	var extra: Dictionary = entries[0].duplicate()
	extra.id = "t-second-common"
	entries.append(extra)
	db.add_character_entries(entries, false)
	var errors: Array[String] = db.validate()
	assert_eq(errors.size(), 1)
	assert_string_contains(errors[0], "2 Common")


func test_c6_duplicate_character_id_is_reported() -> void:
	var entries := _valid_culture("Test Culture", "t")
	entries.append(entries[0].duplicate())
	db.add_character_entries(entries, false)
	var errors: Array[String] = db.validate()
	assert_eq(errors.size(), 1)
	assert_string_contains(errors[0], "t-common")


func test_c6_duplicate_relic_event_id_is_reported() -> void:
	var card := {"id": "x-card", "faction": "X", "name": "Card", "kind": "Event", "duration": "1 turn"}
	db.add_relic_event_entries([card, card.duplicate()], false)
	var errors: Array[String] = db.validate()
	assert_eq(errors.size(), 1)
	assert_string_contains(errors[0], "x-card")


func test_c6a_combined_sub_area_is_reported() -> void:
	var entries := _valid_culture("Test Culture", "t")
	entries[4].sub_area = "Winter Front / Far North"
	db.add_character_entries(entries, false)
	var errors: Array[String] = db.validate()
	assert_eq(errors.size(), 1)
	assert_string_contains(errors[0], entries[4].id)


func test_unknown_type_and_kind_are_reported() -> void:
	var entries := _valid_culture("Test Culture", "t")
	entries.append({"id": "t-dragon", "culture": "Other", "type": "Dragon", "stats": [1, 1, 1, 1]})
	db.add_character_entries(entries, false)
	db.add_relic_event_entries([{"id": "x-omen", "kind": "Omen"}], false)
	var errors: Array[String] = db.validate()
	assert_true(errors.any(func(e): return e.contains("unknown type 'Dragon'")), str(errors))
	assert_true(errors.any(func(e): return e.contains("unknown kind 'Omen'")), str(errors))


func test_rare_relic_is_a_valid_relic_kind() -> void:
	db.add_relic_event_entries([{"id": "x-rare", "kind": "Rare Relic", "duration": "Persistent"}], false)
	assert_eq(db.validate(), [] as Array[String])
	assert_true(db.get_relic_event("x-rare").is_relic())


func test_malformed_stats_are_reported() -> void:
	var entries := _valid_culture("Test Culture", "t")
	entries[0].stats = [2, 1, 3]
	entries[1].stats = [2, 1, 3, 1.5]
	db.add_character_entries(entries, false)
	var errors: Array[String] = db.validate()
	assert_eq(errors.size(), 2, str(errors))


func test_draft_with_wrong_status_is_forced_to_draft_and_flagged() -> void:
	db.add_relic_event_entries([{"id": "x-draft", "kind": "Event", "review_status": "approved"}], true, "fixture.json")
	assert_push_error("x-draft")
	assert_eq(db.get_draft_relic_event("x-draft").review_status, ContentDBScript.DRAFT_STATUS)


func test_missing_file_fails_loudly() -> void:
	db.load_all("res://does/not/exist.json", "res://does/not/exist.json", "res://does/not/exist/")
	assert_push_error_count(3)
	assert_eq(db.characters.size(), 0)
