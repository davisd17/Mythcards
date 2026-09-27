class_name CombatResolver
extends RefCounted
# Placeholder for HLD build step 9 (LLD-combat-mount.md). The signature is the contract
# RulesEngine._handle_attack calls; damage, shields, and defeat land in step 9.

var board: BoardModel


func _init(p_board: BoardModel) -> void:
	board = p_board


func resolve_attack(_attacker: CharacterInstance, _defender: CharacterInstance) -> Dictionary:
	push_error("CombatResolver.resolve_attack: combat arrives in build step 9")
	return {"damage": 0, "defeated": false}
