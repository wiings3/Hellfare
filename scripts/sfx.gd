extends Node
## The game's one sound player (autoload "Sfx"). Everything plays a sound by its name from the
## Hellfare sound list: Sfx.play("crew_back"). The names, files, groups and levels live in
## assets/audio/sounds.json (written by tools/make_sounds.py), so a sound is replaced by
## dropping in new files, never by changing code.
##
## Groups are the buses in default_bus_layout.tres (Alerts, Interface, Ambience, Music), each with
## a volume in Settings. While the window is in the background only alerts play (if allowed).
## Every button clicks on its own: buttons are wired as they enter the tree.

const TABLE := "res://assets/audio/sounds.json"
const VOICES := 6
## The same sound twice within this many milliseconds plays once.
const REPEAT_MS := 50
const FADE := 2.0

var sounds: Dictionary = {}
## The last sounds played, newest last (for tests and debugging).
var played: Array[String] = []
var _streams: Dictionary = {}
var _voices: Dictionary = {}
var _next_voice: Dictionary = {}
var _last_at: Dictionary = {}
var _last_take: Dictionary = {}
var _loops: Dictionary = {}
var _loop_level: Dictionary = {}
var _last_alert_ms: int = -100000
var _away: bool = false
var _last_press_ms: int = -100000
## Headless runs (tests, CI, the simulator) have no speakers: sounds are recorded in `played`
## but never started, so nothing is left mid-playback when they quit.
var silent: bool = false

# --- Music: a piece now and then, never wallpaper -----------------------------------------
## Seconds before the first piece, and the silence between pieces.
const MUSIC_FIRST := [60.0, 120.0]
const MUSIC_GAP := [300.0, 900.0]
## Music drops this much under an alert, for ALERT_DUCK seconds.
const DUCK_DB := -9.0
const ALERT_DUCK := 2.5
## What plays when the next piece is due: "hall", or "descent" while a crew is below.
var music_mood: String = "hall"
## The piece playing now ("" for silence), and when the next one may start (msec).
var music_now: String = ""
var _music_next_ms: int = 0
var _music_until_ms: int = 0
var _music: AudioStreamPlayer
var _music_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	silent = DisplayServer.get_name() == "headless"
	if FileAccess.file_exists(TABLE):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TABLE))
		if parsed is Dictionary:
			sounds = parsed
	for group in ["Alerts", "Interface", "Ambience", "Music"]:
		var list: Array[AudioStreamPlayer] = []
		for i in range(VOICES):
			var p := AudioStreamPlayer.new()
			p.bus = group
			add_child(p)
			list.append(p)
		_voices[group] = list
		_next_voice[group] = 0
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_music.finished.connect(_music_ended)
	_music_next_ms = Time.get_ticks_msec() + int(randf_range(MUSIC_FIRST[0], MUSIC_FIRST[1]) * 1000.0)
	refresh()
	get_tree().node_added.connect(_on_node_added)

func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	if music_now != "" and silent and now >= _music_until_ms:
		_music_ended()
	if music_now == "" and now >= _music_next_ms:
		music_cue("mus_descent" if music_mood == "descent" else "mus_hall")

## Start a piece now, unless one is already playing. Returns whether it started.
func music_cue(piece: String, force: bool = false) -> bool:
	var s: Dictionary = sounds.get(piece, {})
	if s.is_empty() or (music_now != "" and not force):
		return false
	var stream: AudioStream = _stream(str(s["files"][0]))
	if stream == null:
		return false
	music_now = piece
	_music_until_ms = Time.get_ticks_msec() + int(stream.get_length() * 1000.0)
	_music.stream = stream
	_music.volume_db = float(s.get("db", 0.0))
	if not silent:
		_music.play()
	played.append(piece)
	return true

## Fade out `piece` if it is the one playing ("" = whatever is playing).
func music_end(piece: String = "") -> void:
	if music_now == "" or (piece != "" and piece != music_now):
		return
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", -60.0, FADE)
	_music_tween.tween_callback(_music.stop)
	_music_ended()

func _music_ended() -> void:
	music_now = ""
	_music_next_ms = Time.get_ticks_msec() + int(randf_range(MUSIC_GAP[0], MUSIC_GAP[1]) * 1000.0)

func _duck_music() -> void:
	if music_now == "" or silent:
		return
	if _music_tween:
		_music_tween.kill()
	var base: float = float(sounds[music_now].get("db", 0.0))
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", base + DUCK_DB, 0.15)
	_music_tween.tween_interval(ALERT_DUCK)
	_music_tween.tween_property(_music, "volume_db", base, 1.0)

## Re-apply the volumes from GameSettings (and the background rule).
func refresh() -> void:
	GameSettings.apply_volumes()
	if _away:
		for group in ["Interface", "Ambience", "Music"]:
			AudioServer.set_bus_mute(AudioServer.get_bus_index(group), true)
		if not GameSettings.alerts_away:
			AudioServer.set_bus_mute(AudioServer.get_bus_index("Alerts"), true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_away = true
		refresh()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_away = false
		refresh()

## Stop every sound now (before quitting).
func stop_all() -> void:
	for group in _voices:
		for p in _voices[group]:
			(p as AudioStreamPlayer).stop()
	for sound in _loops:
		(_loops[sound] as AudioStreamPlayer).stop()
	if _music:
		_music.stop()

## Let go of the loaded sounds when the game closes.
func _exit_tree() -> void:
	for group in _voices:
		for p in _voices[group]:
			(p as AudioStreamPlayer).stop()
			(p as AudioStreamPlayer).stream = null
	for sound in _loops:
		(_loops[sound] as AudioStreamPlayer).stop()
		(_loops[sound] as AudioStreamPlayer).stream = null
	if _music:
		_music.stop()
		_music.stream = null
	_streams.clear()

func has(sound: String) -> bool:
	return sounds.has(sound)

## Play a one-shot sound by name. Unknown names are ignored (a sound not made yet).
func play(sound: String, volume_db: float = 0.0) -> void:
	var s: Dictionary = sounds.get(sound, {})
	if s.is_empty() or bool(s.get("loop", false)):
		return
	var now: int = Time.get_ticks_msec()
	if now - int(_last_at.get(sound, -100000)) < REPEAT_MS:
		return
	_last_at[sound] = now
	var group: String = _group(s)
	if group == "Alerts":
		_last_alert_ms = now
		_duck_music()
	var files: Array = s.get("files", [])
	if files.is_empty():
		return
	var take: int = randi() % files.size()
	if files.size() > 1 and take == int(_last_take.get(sound, -1)):
		take = (take + 1) % files.size()
	_last_take[sound] = take
	var stream: AudioStream = _stream(str(files[take]))
	if stream == null:
		return
	var list: Array = _voices[group]
	var i: int = int(_next_voice[group])
	_next_voice[group] = (i + 1) % list.size()
	var p: AudioStreamPlayer = list[i]
	p.stream = stream
	p.volume_db = float(s.get("db", 0.0)) + volume_db
	var spread: float = float(s.get("pitch", 0.0))
	p.pitch_scale = 1.0 + randf_range(-spread, spread)
	if not silent:
		p.play()
	played.append(sound)
	if played.size() > 50:
		played.pop_front()

## True if an alert played in the last `ms` milliseconds (smaller sounds can stay quiet then).
func alerted_within(ms: int) -> bool:
	return Time.get_ticks_msec() - _last_alert_ms < ms

## The ambience loops that should be playing, with a level each (1 = full): {"amb_hall": 1.0}.
## Loops not named fade out; new ones fade in.
func ambience(levels: Dictionary) -> void:
	for sound in levels:
		var s: Dictionary = sounds.get(str(sound), {})
		if s.is_empty() or not bool(s.get("loop", false)):
			continue
		if not _loops.has(sound):
			var stream: AudioStream = _stream(str(s["files"][0]))
			if stream == null:
				continue
			if "loop" in stream:
				stream.set("loop", true)
			var p := AudioStreamPlayer.new()
			p.bus = _group(s)
			p.stream = stream
			p.volume_db = -60.0
			add_child(p)
			if not silent:
				p.play()
			_loops[sound] = p
		_fade_to(str(sound), float(levels[sound]))
	for sound in _loops.keys():
		if not levels.has(sound):
			_fade_to(str(sound), 0.0)

func _fade_to(sound: String, level: float) -> void:
	if is_equal_approx(float(_loop_level.get(sound, -1.0)), level):
		return
	_loop_level[sound] = level
	var p: AudioStreamPlayer = _loops[sound]
	var target: float = float(sounds[sound].get("db", 0.0)) + (linear_to_db(level) if level > 0.001 else -60.0)
	var tween := create_tween()
	tween.tween_property(p, "volume_db", target, FADE)

func _group(s: Dictionary) -> String:
	return str(s.get("group", "interface")).capitalize()

func _stream(path: String) -> AudioStream:
	if not _streams.has(path):
		_streams[path] = load(path) if ResourceLoader.exists(path) else null
	return _streams[path]

# --- Every button clicks ----------------------------------------------------------------------
## Buttons click on press: toggles with "toggle", others with "click". A press on a disabled
## button thuds ("denied"). A button with the meta "sfx" plays that sound instead ("" = silent).
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		var b := node as BaseButton
		b.button_down.connect(_on_button_down.bind(b))
		b.gui_input.connect(_on_button_input.bind(b))

## True if the player pressed a button in the last `ms` milliseconds.
func pressed_within(ms: int) -> bool:
	return Time.get_ticks_msec() - _last_press_ms < ms

func _on_button_down(b: BaseButton) -> void:
	_last_press_ms = Time.get_ticks_msec()
	var sound: String = str(b.get_meta("sfx")) if b.has_meta("sfx") else ("toggle" if b.toggle_mode else "click")
	if sound != "":
		play(sound)

func _on_button_input(event: InputEvent, b: BaseButton) -> void:
	if b.disabled and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		play("denied")
