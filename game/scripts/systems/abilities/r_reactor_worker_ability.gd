extends AbilityHandler
# Reactor Worker (Closed City Common) — LLD-closed-city-flood-roster.md 4.
# L1 Passive: ignores Leak damage. Designer ruling 2026-10-07: it never triggers a Leak,
#    so the Leak stays and the Worker can stand on it.
# L2 Lower Corridors: +1 MOVE.
# L3 Open The Sealed Door: when it ends a move on a Leak marker, +1 character AP. No
#    per-turn limit (designer ruling 2026-10-07); the 4-AP pool still caps it.


func level_bonuses() -> Dictionary:
	return {2: {"move": 1}}


func ignores_leaks(_sys, _instance: CharacterInstance) -> bool:
	return true


func on_character_moved(sys, instance: CharacterInstance, mover: CharacterInstance,
		_from: Vector2i, to: Vector2i, _required_pass: bool) -> void:
	if mover != instance or instance.level < 3 or not sys.has_leak(to):
		return
	instance.character_ap_remaining += 1
	EventBus.character_ap_changed.emit(instance.instance_id, instance.character_ap_remaining)
