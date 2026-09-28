extends RelicEventHandler
# The Black Sarcophagus (Relic): your Warrior and Hero each gain +1 maximum HP. Once each
# round, when an enemy adjacent to one of your placed objects attacks, Mark that enemy
# after the attack resolves.

const CARD := "a-flood-survivor-black-sarcophagus"
const TYPES := ["Warrior", "Hero"]


func get_max_hp_bonus(_sys, owner_id: String, target: CharacterInstance) -> int:
	return 1 if target.player_id == owner_id and TYPES.has(target.data.type) else 0


func on_attack_resolved(sys, owner_id: String, attacker_id: String, _target_id: String, _damage: int, _defeated: bool) -> void:
	_maybe_mark(sys, owner_id, attacker_id)


func on_object_attacked(sys, owner_id: String, attacker_id: String, _pos: Vector2i, _damage: int, _destroyed: bool) -> void:
	_maybe_mark(sys, owner_id, attacker_id)


func _maybe_mark(sys, owner_id: String, attacker_id: String) -> void:
	var attacker: CharacterInstance = sys.find(attacker_id)
	if attacker == null or attacker.player_id == owner_id:
		return
	var s := RelicEventDeck.relic_state(owner_id, CARD)
	if s.has("used_turn") and sys.state().turn_number - int(s.used_turn) < 2:
		return   # once each round
	for n in sys.neighbors(attacker.position):
		var obj: PlacedObjectInstance = sys.board.get_placed_object(n)
		if obj != null and obj.owner_player_id == owner_id:
			s["used_turn"] = sys.state().turn_number
			sys.add_status(attacker, "marked", 1, "this_round")
			return
