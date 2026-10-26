extends RefCounted
class_name Sound
## How game scripts reach the sound player: Sound.play("crew_back"). It finds the Sfx autoload
## at call time, so scripts that compile before the autoload exists (tools, tests) still work,
## and with no player running every call does nothing.

static func _sfx() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("Sfx") if tree != null and tree.root != null else null

static func play(sound: String, volume_db: float = 0.0) -> void:
	var s := _sfx()
	if s != null:
		s.play(sound, volume_db)

static func ambience(levels: Dictionary) -> void:
	var s := _sfx()
	if s != null:
		s.ambience(levels)

static func stop_all() -> void:
	var s := _sfx()
	if s != null:
		s.stop_all()

## "hall", or "descent" while a crew is below: what the next piece of music will be.
static func music_mood(mood: String) -> void:
	var s := _sfx()
	if s != null:
		s.music_mood = mood

static func music_cue(piece: String, force: bool = false) -> void:
	var s := _sfx()
	if s != null:
		s.music_cue(piece, force)

static func music_end(piece: String = "") -> void:
	var s := _sfx()
	if s != null:
		s.music_end(piece)

static func refresh() -> void:
	var s := _sfx()
	if s != null:
		s.refresh()

static func pressed_within(ms: int) -> bool:
	var s := _sfx()
	return s != null and s.pressed_within(ms)

static func alerted_within(ms: int) -> bool:
	var s := _sfx()
	return s != null and s.alerted_within(ms)
