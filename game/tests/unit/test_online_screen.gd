extends GutTest
# The game screen in an online match (LLD-network-match.md 3.5-3.6): input waits for the
# friend, the prompt says why, a replay is silent, and the online menu's helpers. The
# screen's session runs on a LoopbackTransport; the friend is a second NetSession whose
# moves the screen's device picks up by rebuilding from the log.

const GameScreenScript := preload("res://scripts/ui/game_screen.gd")
const TEST_STORE := "user://test_online_screen.cfg"

var screen: Control
var loop: LoopbackTransport
var mine: NetSession     # this device, p1
var friend: NetSession   # p2


func before_each() -> void:
	NetStore.path = TEST_STORE
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_STORE))
	GameState.reset()
	screen = GameScreenScript.new()
	screen.size = Vector2(720, 1280)
	add_child_autofree(screen)
	loop = LoopbackTransport.new()
	loop.next_seed = 42
	mine = NetSession.new(loop, screen.controller)
	mine.build_version = "test1"
	mine.poll_seconds = 0.0
	screen.add_child(mine)
	friend = autofree(NetSession.new(loop, GameController.new()))
	friend.build_version = "test1"
	friend.poll_seconds = 0.0


func after_each() -> void:
	if friend.controller.setup != null:
		friend.controller.setup.free()
	TurnManager.relic_event_deck = null
	TurnManager.victory_checker = null
	GameState.reset()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_STORE))
	NetStore.path = "user://net_matches.cfg"


# Created and joined; this device has deployed and waits for the friend.
func _created_and_deployed() -> void:
	assert_true(await mine.create("closed-city"))
	screen._adopt(mine)
	assert_true(await friend.join(mine.code))
	screen.controller.auto_place()
	screen.controller.confirm_placement()
	screen._refresh()


# Both deployed; this device is back on its own view of the match, p1 to move.
func _started() -> void:
	await _created_and_deployed()
	await friend.resync()
	friend.controller.auto_place()
	friend.controller.confirm_placement()
	await mine.resync()


func test_waiting_for_the_friend_to_deploy_turns_input_off() -> void:
	await _created_and_deployed()
	assert_true(screen.controller.in_setup())
	assert_true(screen.controller.is_waiting())
	assert_true(screen._primary.disabled, "Done placing is off once sent")
	assert_string_contains(screen._prompt.text, "Waiting for your friend")
	assert_string_contains(screen._prompt.text, mine.code)


func test_their_turn_has_no_commands_and_says_so() -> void:
	await _started()
	screen._refresh()
	assert_false(screen.controller.is_waiting(), "p1 moves first")
	assert_string_contains(screen._turn_label.text, "Your turn")
	screen.controller.end_turn()
	screen._refresh()
	await wait_process_frames(1)
	assert_true(screen.controller.is_waiting())
	assert_true(screen._primary.disabled)
	assert_string_contains(screen._turn_label.text, "Their turn")
	assert_string_contains(screen._prompt.text, "Their turn")
	assert_eq(screen._side.get_children().filter(func(c): return not c.is_queued_for_deletion()), [])
	var before := ActionCodec.state_hash()
	screen.controller.tap_tile(Vector2i(3, 3))
	assert_eq(ActionCodec.state_hash(), before)


func test_a_rebuild_plays_no_sound_and_leaves_no_effects() -> void:
	await _started()
	screen.controller.end_turn()
	var was := Settings.sound
	Settings.sound = true
	var sounds: int = screen._sfx.played.size()
	await mine.resync()
	assert_eq(screen._sfx.played.size(), sounds, "replayed actions are silent")
	screen._sfx.play("win")
	assert_eq(screen._sfx.played.size(), sounds + 1, "sound works again after the replay")
	Settings.sound = was
	assert_false(screen._board.fx.active())
	assert_false(screen._popup.visible, "no drawn-card popups from the replay")


func test_out_of_sync_offers_the_log() -> void:
	await _started()
	loop.inject(mine.code, {"seat": "p2", "kind": "action", "hash_after": "0000000000000000",
			"action": ActionCodec.encode("end_turn", "p2", {})})
	screen.controller.end_turn()   # the forged entry takes this seq: a conflict, then the rebuild fails
	await wait_process_frames(2)
	assert_true(mine.desynced)
	screen._refresh()
	assert_true(screen.controller.is_waiting())
	assert_string_contains(screen._prompt.text, "Out of sync")
	var labels: Array = screen._options.get_children().map(func(b): return b.text)
	assert_has(labels, "Copy log")


func test_chooser_offers_play_a_friend_online() -> void:
	var labels := []
	for b in screen._chooser.find_children("*", "Button", true, false):
		labels.append(b.text)
	assert_has(labels, "Play a friend online")
	screen._open_online_menu()
	assert_true(screen._online.visible)


func test_codes_are_normalized() -> void:
	assert_eq(OnlineMenu.normalize_code(" abc-def "), "ABCDEF")
	assert_eq(OnlineMenu.normalize_code("abcdefgh"), "ABCDEF")
	assert_eq(OnlineMenu.normalize_code("ab1c"), "ABC")


func test_match_list_status() -> void:
	var saved := {"seat": "p2", "version": "b1", "ended": false}
	assert_eq(OnlineMenu.status_text(saved, {"status": "waiting_for_join", "entries": []}, "b1"), "Waiting for your friend to join")
	assert_eq(OnlineMenu.status_text(saved, {"status": "deploying", "entries": [{"kind": "deploy_hidden", "seat": "p1"}]}, "b1"),
			"Deploy your squad")
	assert_eq(OnlineMenu.status_text(saved, {"status": "deploying", "entries": [{"kind": "deploy", "seat": "p2"}]}, "b1"),
			"Waiting for your friend to deploy")
	var one_turn := {"status": "playing", "entries": [{"kind": "action", "action": {"action_type": "end_turn"}}]}
	assert_eq(OnlineMenu.status_text(saved, one_turn, "b1"), "Your turn", "p1 ended turn 1")
	assert_eq(OnlineMenu.status_text({"seat": "p1", "version": "b1", "ended": false}, one_turn, "b1"), "Their turn")
	assert_eq(OnlineMenu.status_text(saved, one_turn, "b2"), "Started on another build")
	assert_eq(OnlineMenu.status_text({"seat": "p1", "version": "b1", "ended": true}, {}, "b1"), "Ended")
