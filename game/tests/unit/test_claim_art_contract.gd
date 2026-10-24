extends GutTest
# The Ember claim art spec (docs/art-specs/ember-claim/SPEC.md 4A) as an automatic check:
# every outfit listing claim frames has three poses (gather 120, hold 360, settle 120 ms)
# on the idle figure's 512 x 768 canvas, feet on y = 756, nothing in the margins.

const HOLDS := [120, 360, 120]
const FOOT_LINE := 756
const FOOT_TOLERANCE := 4
const SIDE_MARGIN := 24
const TOP_MARGIN := 18
const ROSTER := ["r-reactor-worker", "r-vera-7", "r-yuri-volkov", "r-irina-karpova", "r-mikhail-orlov",
	"r-elena-morozova", "r-zoya-miranova", "a-flood-survivor-stone-line-laborer", "a-flood-survivor-ahesu",
	"a-flood-survivor-naia", "a-flood-survivor-meret-anu", "a-flood-survivor-sahu-ren",
	"a-flood-survivor-iset-nara", "a-flood-survivor-thalassa-nekh"]


func _outfits_with_claims() -> Array:
	var result := []
	var catalog = JSON.parse_string(FileAccess.get_file_as_string(FigureCatalog.CATALOG_PATH))
	for character_id in catalog:
		for entry in catalog[character_id]:
			if entry is Dictionary and entry.has("claim"):
				result.append({"character": character_id, "outfit": str(entry.id), "entry": entry})
	return result


func test_all_fourteen_defaults_are_registered() -> void:
	var names := _outfits_with_claims().map(func(o): return "%s/%s" % [o.character, o.outfit])
	for id in ROSTER:
		assert_has(names, id + "/default")
		assert_eq(FigureCatalog.claim_frames(id, "default").size(), 3, id + " loads its claim poses")


func test_every_claim_has_gather_hold_settle() -> void:
	for o in _outfits_with_claims():
		var holds: Array = o.entry.claim.map(func(f): return int(f.get("ms", 0)))
		assert_eq(holds, HOLDS, "%s/%s" % [o.character, o.outfit])


func test_every_claim_frame_matches_the_canvas_foot_line_and_margins() -> void:
	for o in _outfits_with_claims():
		var idle := load(str(o.entry.texture)) as Texture2D
		for f in o.entry.claim:
			var path := str(f.texture)
			var texture := load(path) as Texture2D
			assert_not_null(texture, path)
			if texture == null:
				continue
			assert_eq(texture.get_size(), idle.get_size(), path + ": same canvas as the idle figure")
			var image := texture.get_image()
			var used := image.get_used_rect()
			assert_between(used.end.y - 1, FOOT_LINE - FOOT_TOLERANCE, FOOT_LINE + FOOT_TOLERANCE,
					path + ": feet on y = 756")
			assert_gte(used.position.x, SIDE_MARGIN, path + ": left margin")
			assert_lte(used.end.x, image.get_width() - SIDE_MARGIN, path + ": right margin")
			assert_gte(used.position.y, TOP_MARGIN, path + ": top margin")


func test_every_roster_character_has_both_lines() -> void:
	for id in ROSTER:
		assert_ne(EmberLines.line_for(id, false), "", id + " claim line")
		assert_ne(EmberLines.line_for(id, true), "", id + " big-claim line")
	assert_eq(EmberLines.line_for("r-reactor-worker", true), "Time to go before I push my luck", "verbatim")
