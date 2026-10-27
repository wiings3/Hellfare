extends Control
## Escape menu. The journal shuts onto its back cover, slides to the middle of the desk,
## and a bookplate on the cover offers Resume, Settings and Quit.
## Layout lives in scenes/journal/pause_menu.tscn. The frames are the BookUI close
## animation mirrored onto the back cover (tools/bake_close.py).

signal quit_requested
signal replay_tutorial_requested
signal rename_requested(new_name: String)
signal new_guild_requested

const FRAMES := "res://assets/ui/book/close/"
const FRAME_COUNT := 6
const FRAME_TIME := 0.045
const SLIDE_TIME := 0.18
const FADE_TIME := 0.12

enum State { CLOSED, MOVING, OPEN }

## Book parts hidden while the cover is shown (set in the shell scene).
@export var book_nodes: Array[NodePath] = []
## How far the closed book slides to sit in the middle of the stage.
@export var slide: Vector2 = Vector2(178, 0)

var state: State = State.CLOSED
var frames: Array[Texture2D] = []
var cover_home: Vector2
var _hidden: Dictionary = {}

@onready var shade: ColorRect = $Shade
@onready var cover: TextureRect = $Cover
@onready var plate: Control = $Cover/Plate
@onready var subtitle: Control = $Cover/Plate/Margin/Content/Subtitle
@onready var hint: Label = $Cover/Plate/Margin/Content/Hint
@onready var main_view: Control = $Cover/Plate/Margin/Content/Main
@onready var settings_view: Control = $Cover/Plate/Margin/Content/Settings
@onready var resume_button: Button = $Cover/Plate/Margin/Content/Main/Resume
@onready var settings_button: Button = $Cover/Plate/Margin/Content/Main/SettingsButton
@onready var quit_button: Button = $Cover/Plate/Margin/Content/Main/Quit
@onready var back_button: Button = $Cover/Plate/Margin/Content/Settings/Back
@onready var fullscreen_toggle: Button = $Cover/Plate/Margin/Content/Settings/Fullscreen/Toggle
@onready var vsync_toggle: Button = $Cover/Plate/Margin/Content/Settings/VSync/Toggle
@onready var animation_toggle: Button = $Cover/Plate/Margin/Content/Settings/Animations/Toggle
@onready var sound_button: Button = $Cover/Plate/Margin/Content/Settings/SoundButton
@onready var replay_button: Button = $Cover/Plate/Margin/Content/Settings/ReplayTutorial
@onready var new_guild_button: Button = $Cover/Plate/Margin/Content/Settings/NewGuild
## "Start a new guild" asks twice: the first press arms it.
var _new_guild_armed: bool = false
@onready var guild_box: LineEdit = $Cover/Plate/Margin/Content/Settings/Guild/Name
@onready var rename_button: Button = $Cover/Plate/Margin/Content/Settings/Guild/Rename
@onready var sound_view: Control = $Cover/Plate/Margin/Content/Sound
@onready var sound_back: Button = $Cover/Plate/Margin/Content/Sound/Back
@onready var away_toggle: Button = $Cover/Plate/Margin/Content/Sound/Away/Toggle


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	cover_home = cover.position
	for i in range(1, FRAME_COUNT + 1):
		frames.append(load(FRAMES + "%d.png" % i))
	resume_button.pressed.connect(resume)
	settings_button.pressed.connect(_show_settings.bind(true))
	back_button.pressed.connect(_show_settings.bind(false))
	quit_button.pressed.connect(func() -> void: quit_requested.emit())
	fullscreen_toggle.toggled.connect(_set_fullscreen)
	vsync_toggle.toggled.connect(_set_vsync)
	animation_toggle.toggled.connect(_set_animations)
	sound_button.pressed.connect(_show_sound.bind(true))
	replay_button.pressed.connect(func() -> void:
		resume()
		replay_tutorial_requested.emit())
	sound_back.pressed.connect(_show_sound.bind(false))
	rename_button.pressed.connect(func() -> void: rename_requested.emit(guild_box.text))
	new_guild_button.pressed.connect(_new_guild_pressed)
	guild_box.text_submitted.connect(func(t: String) -> void: rename_requested.emit(t))
	away_toggle.toggled.connect(_set_alerts_away)
	for group in GameSettings.VOLUME_DEFAULTS:
		var row := sound_view.get_node(str(group))
		var slider := row.get_node("Slider") as HSlider
		slider.value_changed.connect(_slide_volume.bind(str(group)))
		slider.drag_ended.connect(func(_changed: bool) -> void: _volume_set(str(group)))

## The book tells the menu the guild's current name (Settings shows it to edit).
func show_guild_name(n: String) -> void:
	if guild_box and not guild_box.has_focus():
		guild_box.text = n

func is_open() -> bool:
	return state != State.CLOSED

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if state == State.CLOSED:
		open()
	elif state == State.OPEN:
		if sound_view.visible:
			_show_sound(false)
		elif settings_view.visible:
			_show_settings(false)
		else:
			resume()

func open() -> void:
	if state != State.CLOSED:
		return
	state = State.MOVING
	get_tree().paused = true
	Sound.music_cue("mus_title")
	_show_settings(false)
	_sync_toggles()
	cover.position = cover_home
	cover.texture = frames[0]
	plate.visible = false
	plate.modulate.a = 0.0
	visible = true
	_set_book_visible(false)
	if GameSettings.book_animations:
		shade.modulate.a = 0.0
		create_tween().tween_property(shade, "modulate:a", 1.0, FRAME_TIME * FRAME_COUNT)
		for picture in frames:
			cover.texture = picture
			await get_tree().create_timer(FRAME_TIME).timeout
		var move := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		move.tween_property(cover, "position", cover_home + slide, SLIDE_TIME)
		await move.finished
	else:
		shade.modulate.a = 1.0
		cover.texture = frames[-1]
		cover.position = cover_home + slide
	plate.visible = true
	if GameSettings.book_animations:
		create_tween().tween_property(plate, "modulate:a", 1.0, FADE_TIME)
	else:
		plate.modulate.a = 1.0
	state = State.OPEN

func resume() -> void:
	if state != State.OPEN:
		return
	state = State.MOVING
	Sound.music_end("mus_title")
	if GameSettings.book_animations:
		var fade := create_tween()
		fade.tween_property(plate, "modulate:a", 0.0, FADE_TIME)
		await fade.finished
		plate.visible = false
		var move := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		move.tween_property(cover, "position", cover_home, SLIDE_TIME)
		await move.finished
		create_tween().tween_property(shade, "modulate:a", 0.0, FRAME_TIME * FRAME_COUNT)
		for i in range(frames.size() - 1, -1, -1):
			cover.texture = frames[i]
			await get_tree().create_timer(FRAME_TIME).timeout
	visible = false
	_set_book_visible(true)
	get_tree().paused = false
	state = State.CLOSED

func _new_guild_pressed() -> void:
	if not _new_guild_armed:
		_new_guild_armed = true
		new_guild_button.text = "Sure? Press again to start over"
		return
	_disarm_new_guild()
	resume()
	new_guild_requested.emit()

func _disarm_new_guild() -> void:
	_new_guild_armed = false
	new_guild_button.text = "Start a new guild"

func _show_settings(on: bool) -> void:
	_disarm_new_guild()
	main_view.visible = not on
	settings_view.visible = on
	sound_view.visible = false
	subtitle.set("text", "Settings" if on else "Paused")
	hint.text = "Esc to go back" if on else "Esc to resume"

func _sync_toggles() -> void:
	fullscreen_toggle.set_pressed_no_signal(GameSettings.fullscreen)
	vsync_toggle.set_pressed_no_signal(GameSettings.vsync)
	animation_toggle.set_pressed_no_signal(GameSettings.book_animations)
	for toggle in [fullscreen_toggle, vsync_toggle, animation_toggle]:
		toggle.text = "On" if toggle.button_pressed else "Off"

func _set_fullscreen(on: bool) -> void:
	GameSettings.fullscreen = on
	_save_settings()

func _set_vsync(on: bool) -> void:
	GameSettings.vsync = on
	_save_settings()

func _set_animations(on: bool) -> void:
	GameSettings.book_animations = on
	_save_settings()

func _save_settings() -> void:
	GameSettings.save_settings()
	GameSettings.apply()
	_sync_toggles()

func _set_book_visible(on: bool) -> void:
	for path in book_nodes:
		var node := get_node_or_null(path) as CanvasItem
		if node == null:
			continue
		if on:
			node.visible = bool(_hidden.get(path, true))
		else:
			_hidden[path] = node.visible
			node.visible = false

## The Sound page of Settings: a volume per group and the background rule.
func _show_sound(on: bool) -> void:
	sound_view.visible = on
	settings_view.visible = not on
	subtitle.set("text", "Sound" if on else "Settings")
	_sync_sound()
	(sound_back if on else sound_button).grab_focus()

func _sync_sound() -> void:
	for group in GameSettings.VOLUME_DEFAULTS:
		var row := sound_view.get_node(str(group))
		var v: float = float(GameSettings.volumes[group])
		(row.get_node("Value") as Label).text = "Off" if v <= 0.001 else "%d%%" % int(round(v * 100.0))
		(row.get_node("Slider") as HSlider).set_value_no_signal(round(v * 100.0))
	away_toggle.set_pressed_no_signal(GameSettings.alerts_away)
	away_toggle.text = "On" if GameSettings.alerts_away else "Off"

## A slider moved: the new level is heard at once (music and ambience keep playing under it).
func _slide_volume(value: float, group: String) -> void:
	GameSettings.volumes[group] = clampf(value / 100.0, 0.0, 1.0)
	Sound.refresh()
	(sound_view.get_node(group + "/Value") as Label).text = "Off" if value < 0.5 else "%d%%" % int(round(value))
	if not (sound_view.get_node(group + "/Slider") as HSlider).has_focus() or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	_volume_set(group)  # a key press: no drag to end, so settle now

## The level is settled: save it and play a sample of the group.
func _volume_set(group: String) -> void:
	GameSettings.save_settings()
	if group == "Interface":
		Sound.play("coin_spend")
	elif group == "Alerts":
		Sound.play("crew_waiting")

func _set_alerts_away(on: bool) -> void:
	GameSettings.alerts_away = on
	GameSettings.save_settings()
	Sound.refresh()
	_sync_sound()
