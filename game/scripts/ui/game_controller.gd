class_name GameController
extends RefCounted
# Tap logic for the game screen (LLD-presentation.md 4.1, adapted in its 9A). Kept free
# of UI nodes so tests can drive it directly; GameScreen draws whatever this reports.
#
# Setup: pick one of your characters from the tray, then tap a tile on your back row.
# Match: tap one of your characters to select it. Green tiles move it, red targets attack.
# Abilities, free bonus actions, mounting, relic powers, and drawn-card choices run as a
# "flow": one pick at a time (AbilityHandler.next_step), each pick a highlighted tile or
# character or an option button, until the action is complete and sent.

const SetupFlowScript := preload("res://scripts/scenes/setup_flow.gd")

var setup: Node = null            # SetupFlow while players deploy; null once the match starts
var placing_player := "p1"
var seed_next := -1   # TestBridge: the seed a click-started match uses (-1: random)
var placing_id := ""              # tray character picked for placement
var selected_id := ""             # the active player's character being commanded
var inspect_id := ""              # whichever character's card is shown
var flow: Dictionary = {}         # {kind, actor, id, payload}, or {} when none
var message := ""
var ai_players: Dictionary = {}   # player_id -> AIPlayer for sides the computer plays (LLD-ai-opponent.md 5)
var net: NetSession = null        # an online match (LLD-network-match.md 3.5); null for hotseat and AI


# --- Setup -------------------------------------------------------------------------

# Teams default to the matchup in teams.json (Closed City vs Flood Survivors).
# ai_side: "" for hotseat, or the player the AI controls ("p1" / "p2").
func begin_setup(p1_team: String = "", p2_team: String = "", ai_side: String = "") -> Node:
	GameState.reset()
	ai_players = {}
	net = null
	if ai_side != "":
		ai_players[ai_side] = AIPlayer.new(ai_side, null, randi())
	if setup != null:
		setup.free()
	var matchup := ContentDB.get_matchup()
	setup = SetupFlowScript.new()
	setup.select_team("p1", p1_team if p1_team != "" else matchup[0])
	setup.select_team("p2", p2_team if p2_team != "" else matchup[1])
	placing_player = "p1"
	placing_id = ""
	selected_id = ""
	inspect_id = ""
	flow = {}
	message = "Player 1: pick a character below, then tap a highlighted tile on your back row."
	_pick_first()
	if ai_players.has("p1"):
		ai_players.p1.place_squad(setup)   # the AI deploys at once; the human deploys next
		placing_player = "p2"
		message = "Player 2: pick a character below, then tap a highlighted tile on your back row."
		_pick_first()
	return setup


func in_setup() -> bool:
	return setup != null


func tray() -> Array[CharacterInstance]:
	var result: Array[CharacterInstance] = []
	if setup == null:
		return result
	for c in setup.get_player(placing_player).characters:
		if not c.is_placed():
			result.append(c)
	return result


func pick_from_tray(instance_id: String) -> void:
	placing_id = instance_id
	inspect_id = instance_id


func placement_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if setup == null or placing_id == "":
		return result
	for x in BoardModel.BOARD_SIZE:
		var pos := Vector2i(x, _back_row(placing_player))
		if setup.get_placement_error(placing_player, placing_id, pos) == "":
			result.append(pos)
	return result


func auto_place() -> void:
	for c in tray():
		for x in BoardModel.BOARD_SIZE:
			if setup.place_character(placing_player, c.instance_id, Vector2i(x, _back_row(placing_player))):
				break
	placing_id = ""


func placement_done() -> bool:
	return setup != null and setup.is_player_ready(placing_player)


# Hands deployment to player 2, or starts the match once both are ready.
func confirm_placement(deck_seed: int = -1) -> void:
	if not placement_done():
		message = "Place all 7 characters first."
		return
	placing_id = ""
	if net != null:
		if not net.deploys.has(placing_player):
			message = "Waiting for your friend to deploy."
			var placements := {}
			for c in setup.get_player(placing_player).characters:
				placements[c.instance_id] = c.position
			net.submit_deploy(placements)
		return
	if placing_player == "p1" and ai_players.has("p2"):
		ai_players.p2.place_squad(setup)
		placing_player = "p2"
	if placing_player == "p1":
		placing_player = "p2"
		message = "Player 2: pick a character below, then tap a highlighted tile on your back row."
		_pick_first()
		return
	_start_from_setup(deck_seed)


func _start_from_setup(deck_seed: int) -> void:
	var flow_node := setup
	setup = null
	# One seed drives the deck and the coin flip, so an online room agrees on both.
	var match_seed := deck_seed if deck_seed >= 0 else (seed_next if seed_next >= 0 else randi())
	flow_node.start_match(match_seed, flow_node.coin_flip(match_seed))
	flow_node.free()
	var first := GameState.match_state.get_player(GameState.match_state.first_player_id)
	message = "Coin flip: %s goes first." % str(ContentDB.get_team(first.team_id).get("name", first.culture))
	_start_pending_choice()


# --- Online setup (LLD-network-match.md 3.5) -------------------------------------------------

# Setup with the room's teams; this device places only its own seat.
func begin_online(session: NetSession) -> Node:
	begin_setup(str(session.room.teams.p1), str(session.room.teams.p2))
	net = session
	placing_player = session.seat
	placing_id = ""
	message = "Pick a character below, then tap a highlighted tile on your back row."
	_pick_first()
	return setup


# placements: {instance_id: Vector2i}. A piece already on its tile stays put.
func place_deploy(player_id: String, placements: Dictionary) -> void:
	for id in placements:
		setup.place_character(player_id, id, placements[id])
	if player_id == placing_player:
		placing_id = ""
		message = "Waiting for your friend to deploy."


# Both formations are in: start exactly as hotseat does, with the room's seed.
func apply_remote_deploys(deploys: Dictionary, deck_seed: int) -> void:
	for player_id in deploys:
		place_deploy(player_id, deploys[player_id])
	_start_from_setup(deck_seed)


func is_remote_turn() -> bool:
	return net != null and setup == null and GameState.is_match_active() and not net.is_my_decision()


# Input is off: the AI or the friend online is deciding, this device's formation is in and
# the other isn't yet, or the online match is out of sync (LLD-network-match.md 3.5).
func is_waiting() -> bool:
	if net != null and (net.desynced or (setup != null and not net.is_my_decision())):
		return true
	return is_ai_turn() or is_remote_turn()


func _tap_setup(pos: Vector2i) -> void:
	var occupant := _setup_occupant(pos)
	if occupant != null:
		inspect_id = occupant.instance_id
		if occupant.player_id == placing_player:
			setup.unplace_character(placing_player, occupant.instance_id)
			placing_id = occupant.instance_id
		return
	if placing_id == "":
		message = "Pick a character from the tray first."
		return
	var error: String = setup.get_placement_error(placing_player, placing_id, pos)
	if error != "":
		message = error.capitalize() + "."
		return
	setup.place_character(placing_player, placing_id, pos)
	placing_id = ""
	_pick_first()


func _pick_first() -> void:
	var rest := tray()
	if not rest.is_empty():
		pick_from_tray(rest[0].instance_id)


# Only the deploying player's own pieces answer a tap; the other formation stays hidden.
func _setup_occupant(pos: Vector2i) -> CharacterInstance:
	var id: String = setup.board.get_tile(pos).occupant_id
	return setup.get_player(placing_player).find_character(id)


static func _back_row(player_id: String) -> int:
	return BoardModel.PLAYER_A_EDGE_ROW if player_id == "p1" else BoardModel.PLAYER_B_EDGE_ROW


# --- What to draw ---------------------------------------------------------------------

func board() -> BoardModel:
	if setup != null:
		return setup.board
	return GameState.match_state.board if GameState.match_state != null else null


# During setup only the deploying player's squad: nobody sees the other formation until
# the match starts (playtest 2026-10-13).
func characters() -> Array[CharacterInstance]:
	var result: Array[CharacterInstance] = []
	if setup != null:
		result.append_array(setup.get_player(placing_player).characters)
		return result
	for player_id in GameEnums.PLAYER_IDS:
		var p: PlayerState = setup.get_player(player_id) if setup != null \
				else (GameState.match_state.get_player(player_id) if GameState.match_state != null else null)
		if p != null:
			result.append_array(p.characters)
	return result


func find(instance_id: String) -> CharacterInstance:
	for c in characters():
		if c.instance_id == instance_id:
			return c
	return null


# Tiles and characters to highlight: {move, attack_ids, attack_objects, pick_tiles, pick_ids}.
func highlights() -> Dictionary:
	var h := {"move": [], "attack_ids": [], "attack_objects": [], "pick_tiles": [], "pick_ids": []}
	if setup != null:
		h.pick_tiles = placement_tiles()
		return h
	if not flow.is_empty():
		var step := current_step()
		h.pick_tiles = step.get("tiles", [])
		h.pick_ids = step.get("characters", [])
		return h
	if _selected() != null:
		h.move = RulesEngine.get_legal_move_tiles(selected_id)
		h.attack_ids = RulesEngine.get_legal_attack_target_ids(selected_id)
		h.attack_objects = RulesEngine.get_legal_attack_object_tiles(selected_id)
	return h


# Buttons for the selected character: [{label, kind, id, enabled}].
func actions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var actor := _selected()
	if actor == null or not flow.is_empty():
		return result
	var sys: AbilitySystem = RulesEngine.systems().ability
	var can_act := _has_ap(actor)
	for id in RulesEngine.get_usable_ability_ids(selected_id):
		result.append({"label": sys.ability_label(actor, id), "kind": "ability", "id": id, "enabled": can_act})
	for tag in RulesEngine.get_offered_bonus_tags(selected_id):
		result.append({"label": sys.bonus_label(actor, tag) + " (free)", "kind": "bonus", "id": tag, "enabled": true})
	if not RulesEngine.get_legal_mount_ids(selected_id).is_empty():
		result.append({"label": "Mount", "kind": "mount", "id": "", "enabled": can_act})
	if not RulesEngine.get_legal_dismount_tiles(selected_id).is_empty():
		result.append({"label": "Dismount", "kind": "dismount", "id": "", "enabled": can_act})
	return result


func relic_power_label() -> String:
	var state := GameState.match_state
	if state == null or setup != null or not flow.is_empty() or not GameState.is_match_active():
		return ""
	var spec := RelicEventDeck.power_spec(state.active_player_id)
	if spec.is_empty():
		return ""
	var card := ContentDB.get_relic_event(str(spec.get("card_id", "")))
	return "Use " + (card.card_name if card != null else "relic")


# --- Taps and buttons --------------------------------------------------------------------

func is_ai_turn() -> bool:
	var state := GameState.match_state
	return setup == null and state != null and GameState.is_match_active() and ai_players.has(RelicEventDeck.decision_player())


func is_ai(player_id: String) -> bool:
	return ai_players.has(player_id)


# One AI decision, sent like a tap would send it. Returns what it did (for the screen).
func ai_step() -> Dictionary:
	if not is_ai_turn():
		return {}
	var ai: AIPlayer = ai_players[RelicEventDeck.decision_player()]
	var action := ai.next_action()
	if action.is_empty():
		return {}
	flow = {}
	_send(action.action_type, action.actor_id, action.payload)
	message = "AI: %s" % action.get("why", action.action_type)
	return action


func tap_tile(pos: Vector2i) -> void:
	if is_waiting():
		return
	message = ""
	if setup != null:
		_tap_setup(pos)
		return
	var state := GameState.match_state
	if state == null or not GameState.is_match_active():
		return
	var occupant := _occupant(pos)
	if not flow.is_empty():
		_tap_in_flow(pos, occupant)
		return
	if _selected() != null:
		var h := highlights()
		if h.move.has(pos):
			_send("move", selected_id, {"to": pos})
			return
		if occupant != null and h.attack_ids.has(occupant.instance_id):
			_send("attack", selected_id, {"target_id": occupant.instance_id})
			return
		if h.attack_objects.has(pos):
			_send("attack", selected_id, {"target_pos": pos})
			return
	if occupant == null:
		selected_id = ""
		return
	inspect_id = occupant.instance_id
	if occupant.player_id == state.active_player_id and occupant.instance_id != selected_id:
		selected_id = occupant.instance_id
	elif occupant.instance_id == selected_id:
		selected_id = ""


func start_action(kind: String, id: String = "") -> void:
	if _selected() == null or is_waiting():
		return
	flow = {"kind": kind, "actor": selected_id, "id": id, "payload": {}}
	message = ""
	_advance()


func use_relic() -> void:
	var state := GameState.match_state
	if relic_power_label() == "" or is_waiting():
		return
	flow = {"kind": "power", "actor": state.active_player_id, "id": "", "payload": {},
			"spec": RelicEventDeck.power_spec(state.active_player_id)}
	_advance()


func press_option(index: int) -> void:
	var options: Array = current_step().get("options", [])
	if index >= 0 and index < options.size():
		_choose(options[index].value)


func skip() -> void:
	var step := current_step()
	if step.get("optional", false):
		flow.payload[step.key] = null
		_advance()


func can_cancel() -> bool:
	return not flow.is_empty() and flow.kind != "deck" and not flow.get("required", false)


func cancel() -> void:
	if can_cancel():
		flow = {}
		message = ""


# The player's Hero is on the board with no legal move: if that's still true when they end
# their turn, they lose by Hero capture (BR-034). The same query VictoryChecker uses.
func hero_trapped(player_id: String) -> bool:
	var state := GameState.match_state
	if state == null or setup != null or state.phase == "ended":
		return false
	for c in state.get_player(player_id).characters:
		if c.data.type == "Hero":
			return not c.defeated and c.is_placed() and RulesEngine.get_legal_move_tiles(c.instance_id).is_empty()
	return false


func end_turn() -> void:
	var state := GameState.match_state
	if state == null or setup != null or not flow.is_empty() or is_waiting():
		return
	selected_id = ""
	_send("end_turn", state.active_player_id, {})


# --- Flows ---------------------------------------------------------------------------------

# The pick the current flow is waiting for, or {} when it's complete (or there is none).
func current_step() -> Dictionary:
	if flow.is_empty():
		return {}
	var payload: Dictionary = flow.payload
	var sys: AbilitySystem = RulesEngine.systems().ability
	match flow.kind:
		"ability":
			return sys.ability_step(find(flow.actor), flow.id, payload)
		"bonus":
			return sys.bonus_step(find(flow.actor), flow.id, payload)
		"mount":
			if payload.has("mount_id"):
				return {}
			return AbilityHandler.target_step("mount_id", "Mount which ally?", RulesEngine.get_legal_mount_ids(flow.actor))
		"dismount":
			if payload.has("to"):
				return {}
			return AbilityHandler.target_step("to", "The Mount steps out onto which tile?",
					RulesEngine.get_legal_dismount_tiles(flow.actor))
		"deck", "power":
			var step := spec_step(flow.spec, payload)
			if not step.is_empty() and str(flow.spec.get("revealed", "")) != "":
				step["revealed"] = flow.spec.revealed   # a peeked card the screen shows in full
			return step
	return {}


# Turns a RelicEventDeck choice/power spec into one pick at a time.
static func spec_step(spec: Dictionary, payload: Dictionary) -> Dictionary:
	var prompt: String = spec.get("prompt", "")
	var options: Array = spec.get("options", []).map(func(o): return {"label": o.label, "value": o.payload})
	match spec.get("pick", "option"):
		"tiles":
			var chosen: Array = payload.get("tiles", [])
			var count: int = spec.get("count", 1)
			if chosen.size() >= count:
				return {}
			var left: Array = spec.get("tiles", []).filter(func(t): return not chosen.has(t))
			var step := AbilityHandler.target_step("tiles", "%s (%d of %d)" % [prompt, chosen.size() + 1, count], left)
			step["pick"] = "tile"
			step["append"] = true
			return step
		"character":
			if not payload.has("target_id"):
				var step := AbilityHandler.target_step("target_id", prompt, spec.get("characters", []))
				step["pick"] = "character"
				return step
		"character_tile":
			if not payload.has("target_id"):
				var step := AbilityHandler.target_step("target_id", prompt, spec.get("characters", []), spec.get("optional", false))
				step["pick"] = "character"
				return step
			if payload.target_id == null:
				return {}
			var tiles: Array = spec.get("tiles_by_character", {}).get(payload.target_id, [])
			if payload.has("to") or tiles.is_empty():
				return {}
			var to_step := AbilityHandler.target_step("to", "Move it to which tile?", tiles)
			to_step["pick"] = "tile"
			return to_step
	if options.is_empty() or payload.has("_option"):
		return {}
	return AbilityHandler.option_step("_option", prompt, options)


func _tap_in_flow(pos: Vector2i, occupant: CharacterInstance) -> void:
	var step := current_step()
	if step.get("pick") == "tile" and step.get("tiles", []).has(pos):
		_choose(pos)
	elif step.get("pick") == "character" and occupant != null and step.get("characters", []).has(occupant.instance_id):
		_choose(occupant.instance_id)
	elif occupant != null:
		inspect_id = occupant.instance_id


func _choose(value) -> void:
	var step := current_step()
	if step.is_empty():
		return
	if step.get("append", false):
		var list: Array = flow.payload.get(step.key, [])
		list.append(value)
		flow.payload[step.key] = list
	else:
		flow.payload[step.key] = value
	_advance()


# Sends the flow's action once nothing is left to pick.
# Picks made one step at a time -> the payload to send: skipped (null) picks dropped, and
# a chosen card option's payload merged in. Shared with the AI (ActionGenerator).
static func finalize_payload(picks: Dictionary) -> Dictionary:
	var payload := {}
	for key in picks:
		if picks[key] != null and key != "_option":
			payload[key] = picks[key]
	if picks.get("_option") is Dictionary:
		payload.merge(picks._option, true)
	return payload


func _advance() -> void:
	if not current_step().is_empty():
		return
	var done := flow
	var payload := finalize_payload(done.payload)
	flow = {}
	match done.kind:
		"ability":
			payload["ability_id"] = done.id
			_send("ability", done.actor, payload)
		"bonus":
			payload["tag"] = done.id
			_send("reactive_bonus", done.actor, payload)
		"mount", "dismount":
			_send(done.kind, done.actor, payload)
		"deck":
			_send("deck_choice", done.actor, payload)
		"power":
			_send("use_relic", done.actor, payload)


func _send(action: String, actor: String, payload: Dictionary) -> void:
	var result := RulesEngine.request_action(action, actor, payload)
	if net != null and result.get("success", false):
		net.submit(action, actor, payload)   # failed actions are never sent
	if not result.get("success", false):
		message = str(result.get("reason", "That didn't work.")).capitalize() + "."
	elif action == "attack" and payload.has("target_id"):
		message = describe_attack(find(actor), find(payload.target_id), result,
				RulesEngine.systems().combat.last_attack_breakdown)
	if _selected() == null:
		selected_id = ""
	_start_pending_choice()


# "Sniper hit Resonance Guard for 1 (ATK 2, -1 Resonance Guard's armor)." Says why a hit
# did less than the attacker's ATK, so reductions never look like a bug.
static func describe_attack(attacker: CharacterInstance, target: CharacterInstance, result: Dictionary,
		b: Dictionary) -> String:
	var text := "%s hit %s for %d" % [attacker.data.char_name, target.data.char_name, result.get("damage", 0)]
	var parts: Array[String] = []
	if int(b.get("reduced", 0)) > 0:
		var who: Array = b.get("reduced_by", [])
		parts.append("-%d %s" % [b.reduced, ("%s's armor" % " and ".join(who)) if not who.is_empty() else "damage reduction"])
	if int(b.get("shielded", 0)) > 0:
		parts.append("-%d shield" % b.shielded)
	if b.get("memory", false):
		parts.append("-1 Memory")
	if not parts.is_empty():
		text += " (ATK %d, %s)" % [b.get("atk", 0), ", ".join(parts)]
	if result.get("defeated", false):
		text += " and defeated it"
	return text + "."


# Catches up with actions sent around the screen (TestBridge): drops a card flow that was
# answered elsewhere and picks up one that is waiting.
func sync() -> void:
	if flow.get("kind") == "deck" and not RelicEventDeck.has_pending_choice(flow.actor):
		flow = {}
	if flow.get("required", false) and not find(flow.actor).ability_uses_this_turn.get("return_available", false):
		flow = {}
	_start_pending_choice()


# A drawn card (or relic power) waiting on the active player becomes the current flow.
func _start_pending_choice() -> void:
	var state := GameState.match_state
	if state == null or not flow.is_empty() or not GameState.is_match_active():
		return
	var player := RelicEventDeck.decision_player()
	if ai_players.has(player) or (net != null and player != net.seat):
		return   # the AI, or the friend online, answers their own choices
	if RelicEventDeck.has_pending_choice(player):
		flow = {"kind": "deck", "actor": player, "id": "", "payload": {}, "spec": RelicEventDeck.choice_spec(player)}
		return
	# An off-board character (Slumber, Missing In The Signal) must come back first.
	for c in state.get_player(player).characters:
		if c.ability_uses_this_turn.get("return_available", false):
			flow = {"kind": "bonus", "actor": c.instance_id, "id": "return", "payload": {}, "required": true}
			return


func _selected() -> CharacterInstance:
	if selected_id == "" or GameState.match_state == null or setup != null:
		return null
	var c := GameState.match_state.find_character(selected_id)
	if c == null or c.defeated or c.player_id != GameState.match_state.active_player_id:
		return null
	return c


func _has_ap(actor: CharacterInstance) -> bool:
	return actor.character_ap_remaining > 0 \
			and GameState.match_state.get_player(actor.player_id).pool_ap_remaining > 0


func _occupant(pos: Vector2i) -> CharacterInstance:
	var tile := GameState.match_state.board.get_tile(pos)
	if tile == null or tile.occupant_id == "":
		return null
	return GameState.match_state.find_character(tile.occupant_id)
