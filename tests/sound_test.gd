extends SceneTree
## Sound: the name table, every file loads, the groups and volumes, clicks on buttons, ambience
## loops, and the alerts the game plays when crews come back. Touches no save or settings file.
var failures: int = 0

func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error("Sound check failed: " + what)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var sfx: Node = root.get_node_or_null("Sfx")
	check(sfx != null, "the Sfx autoload is running")
	if sfx == null:
		quit(1)
		return
	# The table and the files.
	var must: Array = ["event_open", "event_tick", "crew_waiting", "crew_back", "death", "crew_wiped", "sale",
		"page_turn", "click", "toggle", "denied", "coin_spend", "coin_earn", "send_down", "hire",
		"outcome_good", "outcome_bad", "floor_cleared", "amb_hall", "amb_maw"]
	for name in must:
		check(sfx.has(name), "sound %s is in the table" % name)
	var files: int = 0
	for name in sfx.sounds:
		var s: Dictionary = sfx.sounds[name]
		check(str(s["group"]) in ["alerts", "interface", "ambience", "music"], "%s has a known group" % name)
		for f in s["files"]:
			files += 1
			check(load(str(f)) is AudioStream, "%s loads" % f)
	check(files >= 50, "at least 50 sound files (%d)" % files)
	# Groups and volumes.
	for group in ["Alerts", "Interface", "Ambience", "Music"]:
		check(AudioServer.get_bus_index(group) > 0, "bus %s exists" % group)
	var saved: Dictionary = GameSettings.volumes.duplicate()
	GameSettings.volumes["Interface"] = 0.5
	GameSettings.volumes["Music"] = 0.0
	sfx.refresh()
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Interface")) - linear_to_db(0.25)) < 0.01, "interface volume follows the square of the slider (half = a quarter)")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "volume 0 mutes the group")
	GameSettings.volumes = saved
	sfx.refresh()
	# Playing by name.
	sfx.played.clear()
	sfx.play("crew_back")
	sfx.play("crew_back")
	sfx.play("no_such_sound")
	check(sfx.played == ["crew_back"], "a sound plays once, repeats within 50 ms and unknown names are ignored (%s)" % str(sfx.played))
	check(sfx.alerted_within(1000), "an alert is remembered")
	# Every button clicks; toggles click differently; a button can opt out.
	var b := Button.new()
	root.add_child(b)
	var t := Button.new()
	t.toggle_mode = true
	root.add_child(t)
	var quiet := Button.new()
	quiet.set_meta("sfx", "")
	root.add_child(quiet)
	await process_frame
	sfx.played.clear()
	b.button_down.emit()
	await create_timer(0.06).timeout
	t.button_down.emit()
	quiet.button_down.emit()
	check(sfx.played == ["click", "toggle"], "buttons click (%s)" % str(sfx.played))
	check(sfx.pressed_within(1000), "a press is remembered")
	# Ambience loops fade in and keep looping.
	sfx.ambience({"amb_hall": 1.0, "amb_maw": 0.6})
	var loops: Dictionary = sfx.get("_loops")
	check(loops.has("amb_hall") and loops.has("amb_maw"), "ambience loops start")
	check(bool((loops["amb_hall"] as AudioStreamPlayer).stream.get("loop")), "ambience loops loop")
	sfx.ambience({"amb_hall": 1.0})
	check(is_equal_approx(float(sfx.get("_loop_level")["amb_maw"]), 0.0), "a loop not named fades out")
	# Music: a piece now and then, cues, and a fade out.
	for piece in ["mus_hall", "mus_descent", "mus_crypt", "mus_title"]:
		check(sfx.has(piece), "music %s is in the table" % piece)
	check(sfx.music_now == "", "no music at the start")
	check(sfx.music_cue("mus_crypt"), "a cue starts a piece")
	check(not sfx.music_cue("mus_title"), "a cue waits while another piece plays")
	sfx.music_end("mus_hall")
	check(sfx.music_now == "mus_crypt", "ending another piece leaves this one")
	sfx.music_end("mus_crypt")
	check(sfx.music_now == "", "a piece fades out on request")
	check(int(sfx.get("_music_next_ms")) - Time.get_ticks_msec() >= int(sfx.MUSIC_GAP[0] * 1000.0) - 50, "silence follows a piece")
	sfx.set("_music_next_ms", 0)
	sfx.music_mood = "descent"
	await create_timer(0.1).timeout
	check(sfx.music_now == "mus_descent", "the due piece follows the mood (%s)" % sfx.music_now)
	if failures > 0:
		push_error("%d sound checks failed." % failures)
		quit(1)
		return
	print("Sound checks passed.")
	quit(0)
