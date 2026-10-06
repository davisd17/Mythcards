extends GutTest


const CHARACTER_IDS := [
	"r-gymnast", "r-tiger", "r-sniper", "r-general", "r-hero", "r-engineer", "r-seer",
	"a-attendant", "a-glider", "a-guard", "a-conductor", "a-hero", "a-architect", "a-harmonic",
]


func test_all_board_characters_have_a_default_figure() -> void:
	for character_id in CHARACTER_IDS:
		assert_eq(FigureCatalog.outfits(character_id).size(), 1, character_id)
		assert_eq(FigureCatalog.default_outfit_id(character_id), "default", character_id)
		assert_not_null(FigureCatalog.texture_for(character_id, "default"), character_id)


func test_single_default_wraps_without_touching_character_data() -> void:
	assert_eq(FigureCatalog.next_outfit_id("r-seer", "default"), "default")
	assert_eq(FigureCatalog.outfit_name("r-seer", "default"), "Zoya Miranova")
	assert_false(ContentDB.get_character("r-seer").raw.has("outfit"))
