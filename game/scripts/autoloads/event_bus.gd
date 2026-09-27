extends Node
# Autoload name: EventBus — cross-module signal hub (HLD 5.3). Modules emit here after
# mutating state; UI, DebugPanel, and other modules listen. Declared in full now so the
# contract is visible even before every emitter exists.
@warning_ignore_start("unused_signal")

signal turn_started(player_id: String)
signal turn_ended(player_id: String)
signal pool_ap_changed(player_id: String, remaining: int)
signal character_ap_changed(character_id: String, remaining: int)

signal action_requested(action_type: String, actor_id: String, payload: Dictionary)
signal action_resolved(action_type: String, actor_id: String, result: Dictionary)
signal character_moved(character_id: String, from: Vector2i, to: Vector2i)
signal attack_resolved(attacker_id: String, target_id: String, damage: int, defeated: bool)
signal character_defeated(character_id: String)

signal character_leveled_up(character_id: String, new_level: int)
signal spirit_ember_picked_up(character_id: String)
signal spirit_ember_delivered(character_id: String)

signal relic_drawn(player_id: String, card_id: String)
signal relic_slot_changed(player_id: String, card_id: String)  # "" when the slot empties
signal event_resolved(card_id: String)

signal hero_capture_checked(player_id: String, has_legal_move: bool)
signal match_ended(winner_id: String, condition: String)
