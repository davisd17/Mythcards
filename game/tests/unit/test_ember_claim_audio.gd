extends GutTest

const Fixture := preload("res://tests/helpers/match_fixture.gd")
const WORKER := "p1_r-reactor-worker"
const VERA := "p1_r-vera-7"
var _saved: Array = []


func before_each() -> void:
	_saved = [Settings.sound, Settings.haptics]
	Settings.sound = true
	Settings.haptics = false
	autofree(Fixture.start_teams_match())


func after_each() -> void:
	Fixture.teardown()
	Settings.sound = _saved[0]
	Settings.haptics = _saved[1]


func test_all_fourteen_roster_characters_have_short_mono_stings() -> void:
	var count := 0
	for team in ["closed-city", "flood-survivors"]:
		for data in ContentDB.get_team_characters(team):
			var path := "res://assets/sfx/%s/claim.wav" % data.id
			assert_true(ResourceLoader.exists(path), data.id)
			var stream := load(path) as AudioStreamWAV
			assert_not_null(stream, data.id)
			if stream == null:
				continue
			assert_false(stream.stereo, data.id)
			assert_eq(stream.mix_rate, 44100, data.id)
			assert_between(stream.get_length(), .4, .901, data.id)
			assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_DISABLED, data.id)
			count += 1
	assert_eq(count, 14)


func test_claim_waits_for_attack_impact_plus_landing_and_does_not_double_play() -> void:
	var sfx: Sfx = add_child_autofree(Sfx.new())
	sfx.impact_for = func(_id): return .25
	EventBus.action_requested.emit("attack", WORKER, {})
	EventBus.spirit_ember_picked_up.emit(WORKER)
	EventBus.action_resolved.emit("attack", WORKER, {"success": true})
	assert_eq(sfx.played, [] as Array[String])
	await wait_seconds(.55)
	assert_eq(sfx.played, [] as Array[String], "No early claim at the attack impact")
	await wait_seconds(.30)
	assert_eq(sfx.played, ["claim:r-reactor-worker"] as Array[String])
	assert_almost_eq(sfx._claim_player.volume_db, -8.0, .01)
	assert_almost_eq(sfx._claim_player.pitch_scale, 1.0, .001)


func test_new_claim_cancels_older_pending_and_interrupts_current_audio() -> void:
	var sfx: Sfx = add_child_autofree(Sfx.new())
	EventBus.spirit_ember_picked_up.emit(WORKER)
	EventBus.spirit_ember_picked_up.emit(VERA)
	await wait_seconds(.60)
	assert_eq(sfx.played, ["claim:r-vera-7"] as Array[String])
	assert_true(sfx._claim_player.playing)
	EventBus.spirit_ember_picked_up.emit(WORKER)
	assert_false(sfx._claim_player.playing, "Interrupt the old sting immediately")
	await wait_seconds(.60)
	assert_eq(sfx.played.back(), "claim:r-reactor-worker")
	assert_eq(sfx.played.size(), 2)


func test_sound_off_cancels_pending_and_active_claims() -> void:
	var sfx: Sfx = add_child_autofree(Sfx.new())
	EventBus.spirit_ember_picked_up.emit(WORKER)
	Settings.sound = false
	sfx.apply_settings()
	await wait_seconds(.60)
	assert_eq(sfx.played, [] as Array[String])
	Settings.sound = true
	sfx.apply_settings()
	sfx._play_claim(sfx._claim_serial, Fixture.state(), "r-vera-7")
	assert_true(sfx._claim_player.playing)
	Settings.sound = false
	sfx.apply_settings()
	assert_false(sfx._claim_player.playing)


func test_reset_cancels_old_match_claims_but_final_defeat_can_still_be_heard() -> void:
	var sfx: Sfx = add_child_autofree(Sfx.new())
	var old_state := Fixture.state()
	EventBus.spirit_ember_picked_up.emit(WORKER)
	var serial := sfx._claim_serial
	GameState.reset()
	sfx._play_claim(serial, old_state, "r-reactor-worker")
	assert_eq(sfx.played, [] as Array[String])
	GameState.start_match(old_state)
	old_state.phase = "ended"
	sfx._play_claim(sfx._claim_serial, old_state, "r-reactor-worker")
	assert_eq(sfx.played, ["claim:r-reactor-worker"] as Array[String])


func test_unscored_character_falls_back_and_delivery_keeps_its_existing_sound() -> void:
	var sfx: Sfx = add_child_autofree(Sfx.new())
	sfx._play_claim(sfx._claim_serial, Fixture.state(), "r-general")
	assert_eq(sfx.played, ["ember"] as Array[String])
	assert_same(sfx._claim_player.stream, sfx.streams.ember)
	EventBus.spirit_ember_delivered.emit(WORKER)
	assert_eq(sfx.played, ["ember", "ember"] as Array[String])


func test_defeat_alone_does_not_schedule_a_claim() -> void:
	var sfx: Sfx = add_child_autofree(Sfx.new())
	var serial := sfx._claim_serial
	EventBus.character_defeated.emit(WORKER, "", "direct")
	assert_eq(sfx._claim_serial, serial, "Hazard/no-Ember defeat has no pickup signal")
	assert_eq(sfx.played, ["defeat"] as Array[String])
	assert_false(sfx._claim_player.playing)
