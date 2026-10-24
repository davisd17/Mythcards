extends Node
# Reproducible art QA scene. Uses fixture state, never included in normal gameplay.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const NEKH := "p2_a-flood-survivor-thalassa-nekh"
var board: GameBoardView
var output := "res://../docs/art-specs/form-change/a-flood-survivor-thalassa-nekh/qa"


func _ready() -> void:
	get_window().content_scale_size = Vector2i.ZERO
	get_window().size = Vector2i(1280, 960)
	var setup := Fixture.start_teams_match()
	Fixture.put(NEKH, Vector2i(3, 3))
	board = GameBoardView.new()
	board.controller = GameController.new()
	board.size = Vector2(1280, 960)
	add_child(board)
	board.set_process(false)
	board.fx.clear()
	Settings.motion = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	await _capture("desktop-human")
	var c := Fixture.character(NEKH)
	var human_rect := board.figure_rect(c, board.tile_rect(c.position), FigureCatalog.texture_for(c.data.id, "default"), false)
	c.ability_uses_this_match["seraph_form"] = true
	await _capture("desktop-seraph")
	assert(human_rect == board.figure_rect(c, board.tile_rect(c.position), FigureCatalog.texture_for(c.data.id, "default"), false))
	Settings.motion = true
	board.fx.lunges[NEKH] = {"start": 0.0, "duration": 0.60, "framed": true, "toward": Vector2i(5, 3)}
	board.fx.now = 0.35
	await _capture("desktop-impact-right")
	board.fx.lunges[NEKH].toward = Vector2i(1, 3)
	await _capture("desktop-impact-left")
	board.fx.clear()
	Settings.motion = false
	Fixture.put(NEKH, Vector2i(3, 6))
	await _capture("desktop-back-row")
	Fixture.put(NEKH, Vector2i(3, 3))
	get_window().size = Vector2i(390, 844)
	board.size = Vector2(390, 844)
	await _capture("mobile-seraph")
	board.queue_free()
	setup.free()
	Fixture.teardown()
	await get_tree().process_frame
	get_tree().quit()


func _capture(label: String) -> void:
	board.queue_redraw()
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := output.path_join(label + ".png")
	var error := image.save_png(path)
	assert(error == OK, "Could not save " + path)
	print("Seraph visual review: " + ProjectSettings.globalize_path(path))
