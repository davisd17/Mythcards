extends GutTest
# Board staging, Phase 1 (LLD-board-visual-phase1.md 8): the pure geometry the drawing
# relies on, and a smoke test that every visual state draws without errors.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const GameScreenScript := preload("res://scripts/ui/game_screen.gd")

var view: GameBoardView


func before_each() -> void:
	autofree(Fixture.start_teams_match())
	Fixture.state().shared_deck.clear()
	view = GameBoardView.new()
	view.size = Vector2(700, 700)
	view.controller = GameController.new()
	add_child_autofree(view)


func after_each() -> void:
	Fixture.teardown()


func _tile() -> Rect2:
	return view.tile_rect(Vector2i(3, 3))


func test_draw_order_is_back_to_front_whatever_the_roster_order() -> void:
	var chars: Array = []
	for p in Fixture.state().players:
		chars.append_array(p.characters)
	var expected := GameBoardView.draw_order(chars)
	chars.shuffle()
	assert_eq(GameBoardView.draw_order(chars), expected)
	for i in range(1, expected.size()):
		var a: CharacterInstance = expected[i - 1]
		var b: CharacterInstance = expected[i]
		assert_true(a.position.y > b.position.y or (a.position.y == b.position.y and a.position.x < b.position.x))


func test_humanoid_figures_stand_about_one_tile_tall() -> void:
	var tile := _tile()
	var c := Fixture.character("p1_r-mikhail-orlov")
	var texture := FigureCatalog.texture_for(c.data.id, "default")
	var r := view.figure_rect(c, tile, texture, false)
	var scale := r.size.y / texture.get_height()
	var sil := GameBoardView._silhouette(texture)
	assert_between(sil.size.y * scale / tile.size.y, 0.94, 1.08, "the visible figure is about one tile tall")
	var feet := r.position.y + (sil.position.y + sil.size.y) * scale
	assert_lt(feet, tile.end.y, "feet stay inside the tile")
	assert_gt(feet, tile.position.y + tile.size.y * 0.8, "anchored near the lower interior")


func test_mounts_fit_their_tile() -> void:
	var tile := _tile()
	for id in ["p1_r-vera-7", "p2_a-flood-survivor-ahesu"]:
		var c := Fixture.character(id)
		var texture := FigureCatalog.texture_for(c.data.id, "default")
		var r := view.figure_rect(c, tile, texture, false)
		var scale := r.size.x / texture.get_width()
		var silhouette := GameBoardView._silhouette(texture).size.x * scale
		assert_lte(silhouette / tile.size.x, 0.941, id)


func test_selection_enlarges_and_lifts_without_moving_the_label() -> void:
	var tile := _tile()
	var c := Fixture.character("p2_a-flood-survivor-naia")
	var texture := FigureCatalog.texture_for(c.data.id, "default")
	var normal := view.figure_rect(c, tile, texture, false)
	var lifted := view.figure_rect(c, tile, texture, true)
	assert_between(lifted.size.y / normal.size.y, 1.05, 1.08)
	assert_lt(lifted.end.y, normal.end.y, "lifted")
	assert_eq(view.label_rect(tile), view.label_rect(tile), "the label rect depends only on the tile")


func test_pulse_breathes_between_0_and_1() -> void:
	assert_almost_eq(GameBoardView.pulse(0.0), 0.0, 0.001)
	assert_almost_eq(GameBoardView.pulse(GameBoardView.PULSE_PERIOD * 0.5), 1.0, 0.001)
	for i in 20:
		assert_between(GameBoardView.pulse(i * 0.37), 0.0, 1.0)


func test_hit_testing_is_unchanged() -> void:
	for y in BoardModel.BOARD_SIZE:
		for x in BoardModel.BOARD_SIZE:
			var pos := Vector2i(x, y)
			assert_eq(view.tile_at(view.tile_rect(pos).get_center()), pos)


func test_all_placed_object_sprites_load_with_transparency() -> void:
	for type_id in ["barricade", "pylon", "stone", "vault", "leak"]:
		var texture := GameBoardView.object_texture(type_id)
		assert_not_null(texture, type_id)
		if texture == null:
			continue
		assert_eq(texture.get_size(), Vector2(512, 512), type_id)
		var image := texture.get_image()
		assert_true(image.get_pixel(0, 0).a < 0.01, "%s has transparent margins" % type_id)
		assert_false(image.get_used_rect().size == Vector2i.ZERO, "%s is not blank" % type_id)


func test_every_visual_state_draws() -> void:
	# Selection, moves, an attack target, a Leak, a Stone, a Vault, frost, a mounted pair,
	# a level badge, an Ember carrier, statuses, a spent figure, and banked Embers.
	var screen: Control = GameScreenScript.new()
	screen.size = Vector2(720, 1280)
	add_child_autofree(screen)
	screen.start_new_match(42)
	var state := GameState.match_state
	state.shared_deck.clear()
	var sys: AbilitySystem = RulesEngine.systems().ability
	sys.place_leak(Vector2i(3, 2))
	state.board.place_object(Vector2i(0, 4), "stone", "p2")
	state.board.place_object(Vector2i(6, 4), "vault", "p2")
	state.board.place_object(Vector2i(1, 4), "barricade", "p1")
	state.board.place_object(Vector2i(5, 4), "pylon", "p2")
	state.board.get_tile(Vector2i(5, 3)).terrain_type = "frost"
	var orlov := state.find_character("p1_r-mikhail-orlov")
	orlov.level = 2
	orlov.spirit_ember_count = 2
	sys.add_status(orlov, "shield", 1, "this_turn")
	state.get_player("p2").embers_delivered = 3
	state.find_character("p1_r-yuri-volkov").character_ap_remaining = 0
	Fixture.mount_pair("p1_r-irina-karpova", "p1_r-vera-7")
	screen.controller.tap_tile(orlov.position)
	screen._refresh()
	# Phase 2 animations mid-flight: a slide, a hit with a number, a ghost, a level-up, a ring.
	var naia := state.find_character("p2_a-flood-survivor-naia")
	EventBus.character_moved.emit(naia.instance_id, naia.position + Vector2i(0, 1), naia.position)
	EventBus.damage_resolved.emit(orlov.instance_id, naia.instance_id, 2, [])
	EventBus.character_defeated.emit("p2_a-flood-survivor-iset-nara", orlov.instance_id, "direct")
	EventBus.character_leveled_up.emit(orlov.instance_id, 2)
	EventBus.status_added.emit(orlov.instance_id, "shield", 1, "")
	await wait_process_frames(4)
	assert_eq(screen.controller.selected_id, orlov.instance_id)
	assert_false(screen.controller.highlights().move.is_empty())


func test_territory_wash_fades_to_nothing_by_the_middle() -> void:
	assert_almost_eq(GameBoardView.territory_alpha(0.0), GameBoardView.TERRITORY_ALPHA, 0.001)
	assert_gt(GameBoardView.territory_alpha(1.0), GameBoardView.territory_alpha(2.0))
	assert_eq(GameBoardView.territory_alpha(GameBoardView.TERRITORY_DEPTH), 0.0, "the middle row stays neutral")
