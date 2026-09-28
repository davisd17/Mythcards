extends GutTest
# Playtest report 2026-09-28: "attacking with the Sniper (ATK 2) only took 1 life".
# At Level 1, with no shields, Memory, or relics, a Sniper deals its full 2 to every
# Atlantean except the Resonance Guard, whose Quartz Armor takes 1 off ranged attacks
# (attacker and target more than 1 tile apart). Adjacent, the Guard takes the full 2.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const SNIPER := Fixture.SNIPER


func before_each() -> void:
	autofree(Fixture.start_match())
	Fixture.state().shared_deck.clear()
	Fixture.clear_board()
	Fixture.state().get_player("p1").pool_ap_remaining = 4


func after_each() -> void:
	Fixture.teardown()


func _shot(target_id: String, from: Vector2i, at: Vector2i) -> int:
	Fixture.clear_board()
	Fixture.put(SNIPER, from)
	var target := Fixture.put(target_id, at)
	target.current_hp = 5
	Fixture.character(SNIPER).character_ap_remaining = 1
	Fixture.state().get_player("p1").pool_ap_remaining = 4
	var result := RulesEngine.request_action("attack", SNIPER, {"target_id": target_id})
	assert_true(result.success, str(result))
	return 5 - target.current_hp


func test_full_damage_at_range_against_every_atlantean_but_the_guard() -> void:
	for id in ["p2_a-attendant", "p2_a-glider", "p2_a-conductor", "p2_a-hero", "p2_a-architect", "p2_a-harmonic"]:
		assert_eq(_shot(id, Vector2i(3, 0), Vector2i(3, 3)), 2, id)


func test_quartz_armor_takes_one_off_a_ranged_shot_only() -> void:
	assert_eq(_shot(Fixture.GUARD, Vector2i(3, 0), Vector2i(3, 3)), 1, "ranged: Quartz Armor")
	assert_eq(_shot(Fixture.GUARD, Vector2i(3, 2), Vector2i(3, 3)), 2, "adjacent: not a ranged attack")
