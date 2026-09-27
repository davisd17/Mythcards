class_name AbilityRegistry
# Character id -> handler script (LLD-ability-system.md 3.3). One file per card, so
# rewriting a card's text touches exactly one handler.

const HANDLER_DIR := "res://scripts/systems/abilities/"
const HANDLERS := {
	"r-gymnast": "r_gymnast_ability.gd",
	"r-tiger": "r_tiger_ability.gd",
	"r-sniper": "r_sniper_ability.gd",
	"r-general": "r_general_ability.gd",
	"r-hero": "r_hero_ability.gd",
	"r-engineer": "r_engineer_ability.gd",
	"r-seer": "r_seer_ability.gd",
	"a-attendant": "a_attendant_ability.gd",
	"a-glider": "a_glider_ability.gd",
	"a-guard": "a_guard_ability.gd",
	"a-conductor": "a_conductor_ability.gd",
	"a-hero": "a_hero_ability.gd",
	"a-architect": "a_architect_ability.gd",
	"a-harmonic": "a_harmonic_ability.gd",
}


# Never null: an unknown card gets the no-effect base handler, so callers need no
# null checks.
static func get_handler(character_id: String) -> AbilityHandler:
	if not HANDLERS.has(character_id):
		push_error("AbilityRegistry: no handler for character '%s'" % character_id)
		return AbilityHandler.new()
	var path: String = HANDLER_DIR + HANDLERS[character_id]
	if not ResourceLoader.exists(path):
		return AbilityHandler.new()
	return load(path).new()
