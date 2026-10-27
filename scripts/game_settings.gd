extends RefCounted
class_name GameSettings
## Player preferences. Stored apart from the company save so settings never touch save data.

const PATH := "user://settings.cfg"

static var fullscreen: bool = false
static var vsync: bool = true
static var book_animations: bool = true
## Sound: volume per group, 0 to 1 (the groups are the buses in default_bus_layout.tres).
## The slider is perceptual: the level heard follows its square, so the quiet end has room to tune.
const VOLUME_DEFAULTS := {"Alerts": 0.9, "Interface": 0.75, "Ambience": 0.6, "Music": 0.45}
static var volumes: Dictionary = VOLUME_DEFAULTS.duplicate()
## Keep playing alerts while the game window is in the background (everything else goes quiet).
static var alerts_away: bool = true

## The game was called Money Mercs before Hellfare, and Godot keeps each game's files in a
## folder named after it. The first time Hellfare runs, files are copied from the old folder so
## saves and settings carry over. Only once: a marker file records that it happened, so deleting
## your save later (to start a new guild) really starts a new guild.
const OLD_NAME := "Money Mercs"
const CARRIED := "user://carried_over"

static func carry_over(path: String) -> void:
	if FileAccess.file_exists(path):
		return
	# Hellfare has run here before (it has settings or the marker): nothing to carry.
	if FileAccess.file_exists(CARRIED) or (path != PATH and FileAccess.file_exists(PATH) and not _carrying):
		_mark_carried()
		return
	_carrying = true
	var old: String = OS.get_user_data_dir().get_base_dir().path_join(OLD_NAME).path_join(path.trim_prefix("user://"))
	if old != ProjectSettings.globalize_path(path) and FileAccess.file_exists(old):
		DirAccess.copy_absolute(old, ProjectSettings.globalize_path(path))

## Set while this run is still doing its first carry-over (settings, then the save).
static var _carrying: bool = false

static func _mark_carried() -> void:
	if not FileAccess.file_exists(CARRIED):
		var f := FileAccess.open(CARRIED, FileAccess.WRITE)
		if f:
			f.store_string("Files from the Money Mercs folder were carried over (or there were none).\n")

static func load_settings() -> void:
	carry_over(PATH)
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	fullscreen = bool(cfg.get_value("display", "fullscreen", fullscreen))
	vsync = bool(cfg.get_value("display", "vsync", vsync))
	book_animations = bool(cfg.get_value("interface", "book_animations", book_animations))
	for group in VOLUME_DEFAULTS:
		volumes[group] = clampf(float(cfg.get_value("sound", group.to_lower(), volumes[group])), 0.0, 1.0)
	alerts_away = bool(cfg.get_value("sound", "alerts_away", alerts_away))

static func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "vsync", vsync)
	cfg.set_value("interface", "book_animations", book_animations)
	for group in volumes:
		cfg.set_value("sound", str(group).to_lower(), float(volumes[group]))
	cfg.set_value("sound", "alerts_away", alerts_away)
	cfg.save(PATH)

## Push display settings to the window. Skipped when running headless (tests, CI).
static func apply() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)

## Push the volumes to the sound groups. Runs headless too (the dummy audio driver takes them).
static func apply_volumes() -> void:
	for group in volumes:
		var bus: int = AudioServer.get_bus_index(str(group))
		if bus < 0:
			continue
		var v: float = float(volumes[group])
		AudioServer.set_bus_mute(bus, v <= 0.001)
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(v * v, 0.000001)))
