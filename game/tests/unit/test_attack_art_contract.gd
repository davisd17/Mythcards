extends GutTest
# The attack art spec (docs/art-specs/attack-windup-spec.html) as an automatic check.
# Every outfit in wardrobe.json that lists attack frames must meet it, so a delivery is
# verified the moment it is registered: six poses, one impact on pose 4 (Fire), the same
# 512 x 768 canvas as the outfit's idle figure, feet on y = 756, nothing in the margins.

const POSES := 6
const IMPACT_POSE := 3          # pose 4, Fire (0-based)
const FOOT_LINE := 756
const FOOT_TOLERANCE := 4       # px: the lowest visible pixel of the feet
const SIDE_MARGIN := 24
const TOP_MARGIN := 18


func _outfits_with_art() -> Array:
	var result := []
	var catalog = JSON.parse_string(FileAccess.get_file_as_string(FigureCatalog.CATALOG_PATH))
	for character_id in catalog:
		for entry in catalog[character_id]:
			if entry is Dictionary and entry.has("attack"):
				result.append({"character": character_id, "outfit": str(entry.id), "entry": entry})
	return result


func test_at_least_the_pilot_is_registered() -> void:
	var names := _outfits_with_art().map(func(o): return "%s/%s" % [o.character, o.outfit])
	assert_has(names, "r-yuri-volkov/default")


func test_every_attack_sequence_has_six_poses_and_one_impact_on_fire() -> void:
	for o in _outfits_with_art():
		var label := "%s/%s" % [o.character, o.outfit]
		var frames: Array = o.entry.attack
		assert_eq(frames.size(), POSES, label)
		var impacts := []
		for i in frames.size():
			if frames[i].get("impact", false):
				impacts.append(i)
			assert_gt(int(frames[i].get("ms", 0)), 0, "%s pose %d has a hold" % [label, i + 1])
		assert_eq(impacts, [IMPACT_POSE], "%s: exactly one impact, on pose 4 (Fire)" % label)


func test_every_frame_matches_the_canvas_foot_line_and_margins() -> void:
	for o in _outfits_with_art():
		var label := "%s/%s" % [o.character, o.outfit]
		var idle := load(str(o.entry.texture)) as Texture2D
		assert_not_null(idle, label + " idle figure")
		for f in o.entry.attack:
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
