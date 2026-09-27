extends RefCounted
# Shared test setup: a real Russian-inspired vs Atlantean match (original 14) via SetupFlow, with
# the relic/event deck and victory checker stubbed out, plus board-arrangement helpers.
# Not collected by GUT (no test_ prefix). Use: const Fixture := preload(...).

const SetupFlowScript := preload("res://scripts/scenes/setup_flow.gd")

# Russian-inspired (p1)
const GYMNAST := "p1_r-gymnast"      # Common     HP 2 ATK 1 MOVE 3 RANGE 1
const TIGER := "p1_r-tiger"          # Mount      HP 4 ATK 2 MOVE 4 RANGE 1
const SNIPER := "p1_r-sniper"        # Warrior    HP 3 ATK 2 MOVE 2 RANGE 4
const GENERAL := "p1_r-general"      # Leader     HP 5 ATK 1 MOVE 2 RANGE 1
const BOGATYR := "p1_r-hero"         # Hero       HP 6 ATK 2 MOVE 2 RANGE 1
# Atlantean (p2)
const GUARD := "p2_a-guard"          # Warrior    HP 5 ATK 1 MOVE 2 RANGE 1
const ATTENDANT := "p2_a-attendant"  # Common     HP 2 ATK 1 MOVE 2 RANGE 1
const GLIDER := "p2_a-glider"        # Mount      HP 3 ATK 1 MOVE 4 RANGE 1
const CONDUCTOR := "p2_a-conductor"  # Leader     HP 4 ATK 1 MOVE 2 RANGE 3
const ORACLE := "p2_a-hero"          # Hero       HP 5 ATK 1 MOVE 2 RANGE 3


class NullDeck:
	func build_deck(_a, _b, _c) -> void:
		pass
	func draw_for(_p) -> void:
		pass


class NullChecker:
	func check_hero_capture(_p) -> void:
		pass


# Starts a match with both squads on their back rows (p1's first turn, 2 pool AP).
# Returns the SetupFlow node; the caller must free it (autofree in GUT).
static func start_match() -> Node:
	TurnManager.relic_event_deck = NullDeck.new()
	TurnManager.victory_checker = NullChecker.new()
	var setup: Node = SetupFlowScript.new()
	setup.select_culture("p1", "Russian-inspired")
	setup.select_culture("p2", "Atlantean")
	for id in ["p1", "p2"]:
		var x := 0
		for c in setup.get_player(id).characters:
			setup.place_character(id, c.instance_id, Vector2i(x, 0 if id == "p1" else 6))
			x += 1
	setup.start_match()
	return setup


static func teardown() -> void:
	GameState.reset()
	TurnManager.relic_event_deck = null
	TurnManager.victory_checker = null


static func state() -> MatchState:
	return GameState.match_state


static func board() -> BoardModel:
	return GameState.match_state.board


static func character(id: String) -> CharacterInstance:
	return GameState.match_state.find_character(id)


# Takes every character off the board so a test can place only what it needs.
static func clear_board() -> void:
	for p in state().players:
		for c in p.characters:
			if c.is_placed():
				board().clear_occupant(c.position)
				c.position = CharacterInstance.UNPLACED


static func put(id: String, pos: Vector2i) -> CharacterInstance:
	var c := character(id)
	if c.is_placed():
		board().clear_occupant(c.position)
	board().set_occupant(pos, id)
	c.position = pos
	return c


# Arranges a mounted pair directly, bypassing the mount action.
static func mount_pair(rider_id: String, mount_id: String) -> void:
	var rider := character(rider_id)
	var mount_char := character(mount_id)
	rider.mounted_with_id = mount_id
	rider.is_mounted_rider = true
	mount_char.mounted_with_id = rider_id
	if mount_char.is_placed():
		board().clear_occupant(mount_char.position)
	mount_char.position = rider.position


static func shield(id: String, value: int, expires: String = "this_turn") -> StatusEffect:
	var se := StatusEffect.new("shield", value, expires)
	character(id).status_effects.append(se)
	return se
