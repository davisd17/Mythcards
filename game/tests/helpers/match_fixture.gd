extends RefCounted
# Shared test setup: a real Closed City vs Flood Survivors match via SetupFlow, with
# the relic/event deck and victory checker stubbed out, plus board-arrangement helpers.
# Not collected by GUT (no test_ prefix). Use: const Fixture := preload(...).

const SetupFlowScript := preload("res://scripts/scenes/setup_flow.gd")

# Closed City (p1)
const WORKER := "p1_r-reactor-worker"   # Common  HP 2 ATK 1 MOVE 2 RANGE 1
const VERA := "p1_r-vera-7"             # Mount   HP 4 ATK 1 MOVE 4 RANGE 1
const YURI := "p1_r-yuri-volkov"        # Warrior HP 4 ATK 2 MOVE 2 RANGE 2
const IRINA := "p1_r-irina-karpova"     # Leader  HP 4 ATK 1 MOVE 2 RANGE 3
const ORLOV := "p1_r-mikhail-orlov"     # Hero    HP 5 ATK 1 MOVE 2 RANGE 3
# Flood Survivors (p2)
const NAIA := "p2_a-flood-survivor-naia"                  # Warrior HP 4 ATK 2 MOVE 3 RANGE 1
const LABORER := "p2_a-flood-survivor-stone-line-laborer" # Common  HP 2
const AHESU := "p2_a-flood-survivor-ahesu"                # Mount   HP 4 MOVE 4
const MERET := "p2_a-flood-survivor-meret-anu"            # Leader  HP 4
const SAHU := "p2_a-flood-survivor-sahu-ren"              # Hero    HP 5


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
