extends GutTest
# CombatResolver — LLD-combat-mount.md Section 8, cases C1–C8 and C13, plus marks,
# penetration, and the distance-based "ranged" rule.

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const SNIPER := Fixture.SNIPER
const GYMNAST := Fixture.GYMNAST
const GENERAL := Fixture.GENERAL
const TIGER := Fixture.TIGER
const GUARD := Fixture.GUARD
const ATTENDANT := Fixture.ATTENDANT


class FakeAbility extends AbilitySystem:
	var reduction := 0
	var ranged_only_reduction := false
	var penetration := {"ignore_reduction": 0, "ignore_shield": 0}
	var intercept := {"triggered": false}
	var atk_bonus := 0
	func get_passive_damage_reduction(_d, _a, is_ranged: bool) -> int:
		return reduction if (is_ranged or not ranged_only_reduction) else 0
	func get_penetration(_i) -> Dictionary:
		return penetration
	func intercept_lethal_damage(_d, _c) -> Dictionary:
		return intercept
	func get_conditional_atk_bonus(_i) -> int:
		return atk_bonus


var ability: FakeAbility
var combat: CombatResolver


func before_each() -> void:
	autofree(Fixture.start_match())
	Fixture.clear_board()
	ability = FakeAbility.new(Fixture.board())
	combat = CombatResolver.new(Fixture.board(), ability, MountSystem.new(Fixture.board()))
	watch_signals(EventBus)


func after_each() -> void:
	Fixture.teardown()


func _c(id: String) -> CharacterInstance:
	return Fixture.character(id)


# --- Damage pipeline -----------------------------------------------------------

func test_c1_plain_damage() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))   # HP 5
	assert_eq(combat.apply_damage(_c(SNIPER), guard, 2, false), {"damage": 2, "defeated": false})
	assert_eq(guard.current_hp, 3)


func test_c2_shield_absorbs_and_is_used_up() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	Fixture.shield(GUARD, 1)
	assert_eq(combat.apply_damage(_c(SNIPER), guard, 2, false).damage, 1)
	assert_eq(guard.current_hp, 4)
	assert_false(guard.has_status("shield"))


func test_c3_partial_shield_use_keeps_the_rest() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	var se := Fixture.shield(GUARD, 3)
	assert_eq(combat.apply_damage(_c(SNIPER), guard, 1, false).damage, 0)
	assert_eq(se.value, 2)
	assert_eq(guard.current_hp, 5)


func test_c3a_newest_shield_is_used_first() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	var older := Fixture.shield(GUARD, 1, "this_round")
	var newer := Fixture.shield(GUARD, 1, "this_turn")
	combat.apply_damage(_c(SNIPER), guard, 1, false)
	assert_false(guard.status_effects.has(newer), "newer shield consumed")
	assert_true(guard.status_effects.has(older), "older shield survives")
	assert_eq(older.value, 1)


func test_stacked_shields_drain_across_entries() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	var older := Fixture.shield(GUARD, 2)
	Fixture.shield(GUARD, 1)
	assert_eq(combat.apply_damage(_c(SNIPER), guard, 2, false).damage, 0)
	assert_eq(guard.status_effects, [older] as Array[StatusEffect])
	assert_eq(older.value, 1)


func test_c4_passive_reduction() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	ability.reduction = 1
	assert_eq(combat.apply_damage(_c(SNIPER), guard, 1, false).damage, 0)
	assert_eq(guard.current_hp, 5)


func test_reduction_applies_before_shields() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	ability.reduction = 1
	var se := Fixture.shield(GUARD, 2)
	assert_eq(combat.apply_damage(_c(SNIPER), guard, 2, false).damage, 0)
	assert_eq(se.value, 1, "only the 1 damage left after reduction hits the shield")


func test_penetration_ignores_one_point_of_reduction() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	ability.reduction = 2
	ability.penetration = {"ignore_reduction": 1, "ignore_shield": 0}
	assert_eq(combat.apply_damage(_c(SNIPER), guard, 3, false).damage, 2)


func test_penetration_can_ignore_shields() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	Fixture.shield(GUARD, 1)
	ability.penetration = {"ignore_reduction": 0, "ignore_shield": 1}
	assert_eq(combat.apply_damage(_c(SNIPER), guard, 1, false).damage, 1)


func test_zero_damage_does_nothing() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	assert_eq(combat.apply_damage(_c(SNIPER), guard, 0, false), {"damage": 0, "defeated": false})
	assert_eq(guard.current_hp, 5)


# --- Marks ---------------------------------------------------------------------

func _mark(target_id: String, source_id: String, value: int = 1) -> StatusEffect:
	var se := StatusEffect.new("marked", value, "this_round")
	se.source_character_id = source_id
	_c(target_id).status_effects.append(se)
	return se


func test_ally_applied_mark_adds_damage_once() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	_mark(GUARD, GYMNAST)   # marked by p1
	assert_eq(combat.apply_damage(_c(SNIPER), guard, 2, false).damage, 3)
	assert_false(guard.has_status("marked"), "single use")
	assert_eq(combat.apply_damage(_c(SNIPER), guard, 1, false).damage, 1)


func test_mark_from_the_defenders_own_side_does_not_help() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	var se := _mark(GUARD, ATTENDANT)   # marked by p2's own piece
	assert_eq(combat.apply_damage(_c(SNIPER), guard, 2, false).damage, 2)
	assert_true(guard.status_effects.has(se), "unused mark stays")


func test_sourceless_mark_helps_any_attacker() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	_mark(GUARD, "")   # e.g. The Flood Reaches The Walls marks edge tiles
	assert_eq(combat.apply_damage(_c(SNIPER), guard, 2, false).damage, 3)


# --- Defeat --------------------------------------------------------------------

func test_c5_exact_lethal_defeats_and_clears_tile() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	assert_eq(combat.apply_damage(_c(SNIPER), guard, 5, false), {"damage": 5, "defeated": true})
	assert_eq(guard.current_hp, 0)
	assert_true(guard.defeated)
	assert_false(Fixture.board().is_occupied_by_character(Vector2i(3, 3)))
	assert_signal_emit_count(EventBus, "character_defeated", 1)
	assert_signal_emitted_with_parameters(EventBus, "character_defeated", [GUARD, SNIPER, "direct"])


func test_overkill_clamps_hp_at_zero() -> void:
	var attendant := Fixture.put(ATTENDANT, Vector2i(3, 3))   # HP 2
	assert_eq(combat.apply_damage(_c(SNIPER), attendant, 5, false).damage, 5)
	assert_eq(attendant.current_hp, 0)


func test_c6_defeating_a_rider_also_defeats_the_mount() -> void:
	Fixture.put(GENERAL, Vector2i(3, 3))
	Fixture.mount_pair(GENERAL, TIGER)
	var result := combat.apply_damage(_c(Fixture.GUARD), _c(GENERAL), 5, false)   # General HP 5
	assert_true(result.defeated)
	assert_true(_c(GENERAL).defeated)
	assert_true(_c(TIGER).defeated)
	assert_eq(_c(TIGER).current_hp, 4, "the Mount keeps its HP; the flag marks the defeat")
	assert_false(Fixture.board().is_occupied_by_character(Vector2i(3, 3)))
	assert_eq(_c(GENERAL).mounted_with_id, "")
	assert_eq(_c(TIGER).mounted_with_id, "")
	assert_signal_emit_count(EventBus, "character_defeated", 2)
	assert_eq(get_signal_parameters(EventBus, "character_defeated", 0), [GENERAL, GUARD, "direct"])
	assert_eq(get_signal_parameters(EventBus, "character_defeated", 1), [TIGER, GUARD, "mount_propagation"])


func test_c13_lethal_interception_survives() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	ability.intercept = {"triggered": true, "final_hp": 2}
	var result := combat.apply_damage(_c(SNIPER), guard, 9, false)
	assert_false(result.defeated)
	assert_eq(guard.current_hp, 2)
	assert_false(guard.defeated)
	assert_signal_not_emitted(EventBus, "character_defeated")


# --- resolve_attack ------------------------------------------------------------

func test_resolve_attack_uses_effective_atk_and_emits_attack_resolved() -> void:
	var sniper := Fixture.put(SNIPER, Vector2i(3, 2))   # ATK 2
	Fixture.put(GUARD, Vector2i(3, 3))
	sniper.status_effects.append(StatusEffect.new("temp_atk", 1))
	ability.atk_bonus = 1
	assert_eq(combat.resolve_attack(sniper, _c(GUARD)), {"damage": 4, "defeated": false})
	assert_signal_emitted_with_parameters(EventBus, "attack_resolved", [SNIPER, GUARD, 4, false])


func test_ranged_means_more_than_one_tile_apart() -> void:
	# Reduction that applies only to ranged attacks (e.g. Quartz Armor).
	ability.reduction = 1
	ability.ranged_only_reduction = true
	var sniper := Fixture.put(SNIPER, Vector2i(3, 1))   # RANGE 4, ATK 2
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	assert_eq(combat.resolve_attack(sniper, guard).damage, 1, "2 tiles apart: ranged")
	Fixture.put(SNIPER, Vector2i(3, 2))
	assert_eq(combat.resolve_attack(sniper, guard).damage, 2, "adjacent: not ranged, despite RANGE 4")


# --- apply_push ----------------------------------------------------------------

func test_c7_push_moves_target_away() -> void:
	Fixture.put(SNIPER, Vector2i(3, 2))
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	Fixture.put(ATTENDANT, Vector2i(3, 5))
	assert_eq(combat.apply_push(guard, Vector2i(3, 2), 1), Vector2i(3, 4))
	assert_eq(guard.position, Vector2i(3, 4))
	assert_true(Fixture.board().is_occupied_by_character(Vector2i(3, 4)))
	assert_false(Fixture.board().is_occupied_by_character(Vector2i(3, 3)))


func test_push_reports_repositioned_not_moved() -> void:
	# "After moving" abilities must not fire from being pushed.
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	combat.apply_push(guard, Vector2i(3, 2), 1)
	assert_signal_emitted_with_parameters(EventBus, "character_repositioned", [GUARD, Vector2i(3, 3), Vector2i(3, 4), "push"])
	assert_signal_not_emitted(EventBus, "character_moved")


func test_zero_distance_push_reports_nothing() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	Fixture.put(ATTENDANT, Vector2i(3, 4))
	combat.apply_push(guard, Vector2i(3, 2), 1)
	assert_signal_not_emitted(EventBus, "character_repositioned")


func test_c8_blocked_push_leaves_target() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	Fixture.put(ATTENDANT, Vector2i(3, 4))
	assert_eq(combat.apply_push(guard, Vector2i(3, 2), 1), Vector2i(3, 3))
	assert_eq(Fixture.board().get_tile(Vector2i(3, 3)).occupant_id, GUARD)


func test_push_stops_at_edge_and_objects() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 5))
	assert_eq(combat.apply_push(guard, Vector2i(3, 4), 3), Vector2i(3, 6), "stops at the board edge")
	var attendant := Fixture.put(ATTENDANT, Vector2i(1, 3))
	Fixture.board().place_object(Vector2i(3, 3), "barricade", "p1")
	assert_eq(combat.apply_push(attendant, Vector2i(0, 3), 3), Vector2i(2, 3), "stops before a blocking object")


func test_push_through_non_blocking_object() -> void:
	var attendant := Fixture.put(ATTENDANT, Vector2i(1, 3))
	Fixture.board().place_object(Vector2i(2, 3), "pylon", "p2")
	assert_eq(combat.apply_push(attendant, Vector2i(0, 3), 1), Vector2i(2, 3))


func test_no_push_status_prevents_push() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	guard.status_effects.append(StatusEffect.new("no_push", 0, "this_turn"))
	assert_eq(combat.apply_push(guard, Vector2i(3, 2), 1), Vector2i(3, 3))


func test_push_from_off_line_is_rejected() -> void:
	var guard := Fixture.put(GUARD, Vector2i(3, 3))
	assert_eq(combat.apply_push(guard, Vector2i(2, 2), 1), Vector2i(3, 3))
	assert_push_error("orthogonal")


func test_pushing_a_rider_moves_the_mount_too() -> void:
	var general := Fixture.put(GENERAL, Vector2i(3, 3))
	Fixture.mount_pair(GENERAL, TIGER)
	combat.apply_push(general, Vector2i(3, 2), 1)
	assert_eq(_c(TIGER).position, Vector2i(3, 4))
