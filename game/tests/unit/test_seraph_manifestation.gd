extends GutTest

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const NEKH := "p2_a-flood-survivor-thalassa-nekh"
var fx: BoardFx


func before_each() -> void:
	autofree(Fixture.start_teams_match())
	Fixture.state().shared_deck.clear()
	fx = BoardFx.new()
	fx.connect_signals()
	RulesEngine.request_action("end_turn", "p1", {})


func after_each() -> void:
	Fixture.teardown()


func _activate() -> Dictionary:
	var c := Fixture.character(NEKH)
	for level in range(c.level + 1, 4):
		c.level = level
		RulesEngine.systems().ability.apply_level_up_effects(c, level)
	return RulesEngine.request_action("ability", NEKH, {"ability_id": SeraphManifestation.ABILITY_ID})


func test_level_or_outfit_alone_does_not_manifest() -> void:
	var c := Fixture.character(NEKH)
	c.level = 3
	assert_false(SeraphManifestation.is_active(c))
	assert_eq(SeraphManifestation.opacity(c, fx, true), 0.0)
	assert_eq(FigureCatalog.default_outfit_id(c.data.id), "default")


func test_success_reveals_once_and_persists_without_timer() -> void:
	assert_true(_activate().success)
	var c := Fixture.character(NEKH)
	assert_true(SeraphManifestation.is_active(c))
	assert_true(fx.manifestations.has(NEKH))
	assert_eq(SeraphManifestation.opacity(c, fx, true), 0.0)
	fx.advance(0.30)
	assert_almost_eq(SeraphManifestation.opacity(c, fx, true), SeraphManifestation.REST_ALPHA / 2.0, 0.001)
	fx.advance(1.0)
	assert_false(fx.manifestations.has(NEKH))
	assert_eq(SeraphManifestation.opacity(c, BoardFx.new(), true), SeraphManifestation.REST_ALPHA,
			"fresh view of restored model shows final form, not activation again")
	assert_eq(c.get_effective_atk(), 3)
	assert_eq(c.get_effective_range("attack"), 4)
	RulesEngine.request_action("end_turn", "p2", {})
	RulesEngine.request_action("end_turn", "p1", {})
	assert_false(_activate().success)
	assert_false(fx.manifestations.has(NEKH), "failed repeat does not replay reveal")
	assert_eq(c.get_effective_atk(), 3, "no duplicated stat grant")


func test_failed_activation_does_not_reveal() -> void:
	assert_false(RulesEngine.request_action("ability", NEKH, {"ability_id": SeraphManifestation.ABILITY_ID}).success)
	assert_false(fx.manifestations.has(NEKH))
	assert_false(SeraphManifestation.is_active(Fixture.character(NEKH)))


func test_motion_off_is_immediate_and_impact_is_brightest() -> void:
	assert_true(_activate().success)
	var c := Fixture.character(NEKH)
	assert_eq(SeraphManifestation.opacity(c, fx, false), SeraphManifestation.REST_ALPHA)
	fx.advance(1.0)
	fx.attack_art = func(_id): return {"impact": 0.33}
	fx.lunges[NEKH] = {"start": fx.now, "duration": 0.6, "framed": true}
	var anticipation := SeraphManifestation.opacity(c, fx, true)
	fx.advance(0.33)
	assert_gt(SeraphManifestation.opacity(c, fx, true), anticipation)
	assert_eq(SeraphManifestation.opacity(c, fx, false), SeraphManifestation.REST_ALPHA)
	fx.clear()
	assert_true(fx.manifestations.is_empty())


func test_spirit_fits_without_changing_human_rectangle() -> void:
	var human := Rect2(-25, -75, 50, 76)
	var before := human
	var spirit := SeraphManifestation.local_rect(human, 200)
	assert_eq(human, before)
	assert_gt(spirit.size.y, human.size.y)
	assert_almost_eq(spirit.get_center().x, 0.0, 0.001)
	assert_gte(SeraphManifestation.local_rect(human, 80).position.y, -80.0)
	assert_gt(SeraphManifestation.local_rect(human, 80).get_center().x, 0.0, "face remains visible beside vessel at the back edge")
	assert_lt(SeraphManifestation.local_rect(human, 80, -1.0).get_center().x, 0.0, "right edge uses inner shoulder")
	var texture := SeraphManifestation.texture()
	assert_not_null(texture)
	assert_eq(texture.get_size(), Vector2(512, 768))
	assert_lt(texture.get_image().get_pixel(0, 0).a, 0.01)
