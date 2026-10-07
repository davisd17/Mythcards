extends GutTest


# The 14 playtest characters (teams.json); figure folders are keyed by card id.
const CHARACTER_IDS := [
	"r-reactor-worker", "r-vera-7", "r-yuri-volkov", "r-mikhail-orlov", "r-irina-karpova",
	"r-elena-morozova", "r-zoya-miranova",
	"a-flood-survivor-stone-line-laborer", "a-flood-survivor-ahesu", "a-flood-survivor-naia",
	"a-flood-survivor-sahu-ren", "a-flood-survivor-meret-anu", "a-flood-survivor-iset-nara",
	"a-flood-survivor-thalassa-nekh",
]


func test_all_board_characters_have_a_default_figure() -> void:
	for character_id in CHARACTER_IDS:
		assert_eq(FigureCatalog.outfits(character_id).size(), 1, character_id)
		assert_eq(FigureCatalog.default_outfit_id(character_id), "default", character_id)
		assert_not_null(FigureCatalog.texture_for(character_id, "default"), character_id)


func test_single_default_wraps_without_touching_character_data() -> void:
	assert_eq(FigureCatalog.next_outfit_id("r-zoya-miranova", "default"), "default")
	assert_eq(FigureCatalog.outfit_name("r-zoya-miranova", "default"), "Zoya Miranova")
	assert_false(ContentDB.get_character("r-zoya-miranova").raw.has("outfit"))


func test_figure_names_match_the_characters_they_stand_for() -> void:
	# Playtest 2026-10-07: figures had been mapped onto the old characters' ids.
	for character_id in CHARACTER_IDS:
		var card := ContentDB.get_character(character_id)
		assert_not_null(card, character_id)
		assert_true(card.char_name.begins_with(FigureCatalog.outfit_name(character_id, "default").split(",")[0]),
				"%s figure '%s' vs card '%s'" % [character_id, FigureCatalog.outfit_name(character_id, "default"), card.char_name])
