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


func _opaque_row(image: Image, y: int, left := 0, right := -1) -> bool:
	for x in range(left, image.get_width() if right < 0 else right):
		if image.get_pixel(x, y).a >= 0.5:
			return true
	return false


func _opaque_body_height(texture: Texture2D, head_left := 0, head_right := -1) -> int:
	var image := texture.get_image()
	var used := image.get_used_rect()
	var top := used.position.y
	var bottom := used.end.y - 1
	while top < bottom and not _opaque_row(image, top, head_left, head_right):
		top += 1
	while bottom > top and not _opaque_row(image, bottom):
		bottom -= 1
	return bottom - top + 1


func _opaque_column(image: Image, x: int) -> bool:
	for y in image.get_height():
		if image.get_pixel(x, y).a >= 0.5:
			return true
	return false


func _opaque_body_width(texture: Texture2D) -> int:
	var image := texture.get_image()
	var used := image.get_used_rect()
	var left := used.position.x
	var right := used.end.x - 1
	while left < right and not _opaque_column(image, left):
		left += 1
	while right > left and not _opaque_column(image, right):
		right -= 1
	return right - left + 1


func test_orlov_attack_keeps_idle_body_height() -> void:
	# Orlov's glow and hands sit below his crown, so height measures his body,
	# not the reach of an effect. Packing the old impact shrank all six poses.
	var idle := load("res://assets/figures/r-mikhail-orlov/default.png") as Texture2D
	var idle_height := _opaque_body_height(idle)
	for frame in FigureCatalog.attack_frames("r-mikhail-orlov", "default"):
		var texture: Texture2D = frame.texture
		var height := _opaque_body_height(texture)
		assert_between(height, idle_height - 2, idle_height + 2,
			texture.resource_path + ": body height stays at idle scale")


func test_zoya_attack_keeps_idle_body_height() -> void:
	# Reviewed static strands and hands remain below the crown and above soles.
	var idle := load("res://assets/figures/r-zoya-miranova/default.png") as Texture2D
	var idle_height := _opaque_body_height(idle)
	for frame in FigureCatalog.attack_frames("r-zoya-miranova", "default"):
		var texture: Texture2D = frame.texture
		assert_between(_opaque_body_height(texture), idle_height - 2, idle_height + 2,
			texture.resource_path + ": body height stays at idle scale")


func test_stone_line_laborer_attack_keeps_idle_body_height() -> void:
	# The compact hammer remains below his crown in all six reviewed poses.
	var id := "a-flood-survivor-stone-line-laborer"
	var idle := load("res://assets/figures/" + id + "/default.png") as Texture2D
	var idle_height := _opaque_body_height(idle)
	for frame in FigureCatalog.attack_frames(id, "default"):
		var texture: Texture2D = frame.texture
		assert_between(_opaque_body_height(texture), idle_height - 2, idle_height + 2,
			texture.resource_path + ": body height stays at idle scale")


func test_ahesu_attack_keeps_cleaned_idle_coil_width() -> void:
	# Reviewed heads remain inside the lower coil's horizontal span.
	var id := "a-flood-survivor-ahesu"
	var idle := load("res://assets/figures/" + id + "/default.png") as Texture2D
	var idle_width := _opaque_body_width(idle)
	for frame in FigureCatalog.attack_frames(id, "default"):
		var texture: Texture2D = frame.texture
		assert_between(_opaque_body_width(texture), idle_width - 2, idle_width + 2,
			texture.resource_path + ": coil width stays at idle scale")


func test_ahesu_idle_has_no_rover_fragment_at_left_edge() -> void:
	var idle := load("res://assets/figures/a-flood-survivor-ahesu/default.png") as Texture2D
	var former_fragment := idle.get_image().get_region(Rect2i(0, 0, 48, 768))
	assert_eq(former_fragment.get_used_rect().size, Vector2i.ZERO,
		"the old left-edge rover wheel and detached debris must stay removed")


func test_thalassa_attack_keeps_idle_body_height_beneath_water_effects() -> void:
	var id := "a-flood-survivor-thalassa-nekh"
	var idle := load("res://assets/figures/" + id + "/default.png") as Texture2D
	var idle_height := _opaque_body_height(idle)
	for frame in FigureCatalog.attack_frames(id, "default"):
		var texture: Texture2D = frame.texture
		assert_between(_opaque_body_height(texture), idle_height - 2, idle_height + 2,
			texture.resource_path + ": larger water effects must not shrink her body")


func test_iset_attack_keeps_idle_height_and_off_center_footprint() -> void:
	var id := "a-flood-survivor-iset-nara"
	var idle := load("res://assets/figures/" + id + "/default.png") as Texture2D
	var idle_height := _opaque_body_height(idle)
	var foot_band := Rect2i(0, 730, 512, 38)
	var idle_feet := idle.get_image().get_region(foot_band).get_used_rect()
	for frame in FigureCatalog.attack_frames(id, "default"):
		var texture: Texture2D = frame.texture
		assert_between(_opaque_body_height(texture), idle_height - 2, idle_height + 2,
			texture.resource_path + ": divider reach must not shrink the body")
		var feet := texture.get_image().get_region(foot_band).get_used_rect()
		assert_between(feet.position.x, idle_feet.position.x - 12, idle_feet.position.x + 12,
			texture.resource_path + ": retain the idle left sandal position")
		assert_between(feet.end.x, idle_feet.end.x - 12, idle_feet.end.x + 12,
			texture.resource_path + ": do not recenter the idle footprint")


func test_sahu_attack_keeps_idle_body_height() -> void:
	var id := "a-flood-survivor-sahu-ren"
	var idle := load("res://assets/figures/" + id + "/default.png") as Texture2D
	var idle_height := _opaque_body_height(idle)
	for frame in FigureCatalog.attack_frames(id, "default"):
		var texture: Texture2D = frame.texture
		assert_between(_opaque_body_height(texture), idle_height - 2, idle_height + 2,
			texture.resource_path + ": fingertip reach must not shrink body height")


func test_meret_attack_keeps_idle_crown_to_hem_height() -> void:
	var id := "a-flood-survivor-meret-anu"
	var idle := load("res://assets/figures/" + id + "/default.png") as Texture2D
	var idle_height := _opaque_body_height(idle, 210, 280)
	for frame in FigureCatalog.attack_frames(id, "default"):
		var texture: Texture2D = frame.texture
		assert_between(_opaque_body_height(texture, 210, 280), idle_height - 2, idle_height + 2,
			texture.resource_path + ": crown-to-hem height excludes palm effects")


func test_naia_attack_keeps_idle_body_height_excluding_raised_blade() -> void:
	# The stronger brace brings the blade over the old head band; sample the
	# exposed crown to its right so weapon reach is not mistaken for body height.
	var id := "a-flood-survivor-naia"
	var idle := load("res://assets/figures/" + id + "/default.png") as Texture2D
	var idle_height := _opaque_body_height(idle, 240, 300)
	for frame in FigureCatalog.attack_frames(id, "default"):
		var texture: Texture2D = frame.texture
		var head_left := 292 if texture.resource_path.ends_with("attack-3-brace.png") else 240
		assert_between(_opaque_body_height(texture, head_left, 300), idle_height - 2, idle_height + 2,
			texture.resource_path + ": body height excludes weapon reach")
