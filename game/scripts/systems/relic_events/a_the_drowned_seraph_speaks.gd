extends RelicEventHandler
# The Drowned Seraph Speaks (Event, 1 round): choose your Mystic (each side fields one,
# so it's picked automatically). Until the start of your next turn, the first enemy that
# damages your Mystic becomes Marked after the attack resolves. If your Mystic is
# Thalassa-Nekh, she also gains Shield.

const CARD := "a-flood-survivor-the-drowned-seraph-speaks"
const THALASSA := "a-flood-survivor-thalassa-nekh"


func on_activate(sys, player_id: String) -> Dictionary:
	for c in own_live(sys, player_id):
		if c.data.type == "Mystic":
			if c.data.id == THALASSA:
				sys.add_status(c, "shield", 1, "this_round")
			return {"mystic_id": c.instance_id, "triggered": false}
	return {}


func on_attack_resolved(sys, owner_id: String, attacker_id: String, target_id: String, damage: int, _defeated: bool) -> void:
	var data := RelicEventDeck.active_data(CARD)
	if data.is_empty() or data.get("triggered", true) or target_id != data.get("mystic_id", "") or damage <= 0:
		return
	var attacker: CharacterInstance = sys.find(attacker_id)
	if attacker != null and attacker.player_id != owner_id:
		data["triggered"] = true
		sys.add_status(attacker, "marked", 1, "this_round")
