extends GutTest


func test_vertical_slice_has_two_outfits_per_character() -> void:
	assert_eq(FigureCatalog.outfits("r-seer").size(), 2)
	assert_eq(FigureCatalog.outfits("a-harmonic").size(), 2)


func test_default_and_alternate_textures_load() -> void:
	assert_not_null(FigureCatalog.texture_for("r-seer", "default"))
	assert_not_null(FigureCatalog.texture_for("r-seer", "aurora-rite"))
	assert_not_null(FigureCatalog.texture_for("a-harmonic", "default"))
	assert_not_null(FigureCatalog.texture_for("a-harmonic", "drowned-seraph"))


func test_outfit_cycle_wraps_without_touching_character_data() -> void:
	assert_eq(FigureCatalog.next_outfit_id("r-seer", "default"), "aurora-rite")
	assert_eq(FigureCatalog.next_outfit_id("r-seer", "aurora-rite"), "default")
	assert_eq(FigureCatalog.outfit_name("r-seer", "aurora-rite"), "Aurora Rite")
	assert_false(ContentDB.get_character("r-seer").raw.has("outfit"))
