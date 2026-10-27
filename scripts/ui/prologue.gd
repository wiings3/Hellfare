extends Control
## The prologue. A new guild opens on the guild you used to have: the Lantern Company at its
## height, deep in the Brimstone Reach. You lead its champion, Ser Aldren Vane, and his rogue,
## Mira Holt, through one fight at the Ember Gate — big blows, heavy armour, the crawl taught by
## doing. Then Aldren betrays you, becomes Death's First Blade, and you start again in Last
## Lantern with nothing, choosing the hero who'll lead your new guild below.
##
## The scene is scenes/journal/widgets/prologue_view.tscn; book_ui.gd starts it (play()) when the
## tutorial is at its "prologue" step and founds the hero when it finishes.

## The new guild's first hero: class and name. Empty when the prologue was a replay.
signal finished(hero_class: String, hero_name: String)

const INTRO_TITLE := "The Lantern Company"
const INTRO := "Twelve years ago the Lantern Company was the greatest guild in Last Lantern. Its crews worked every layer of the Maw, and its champion, Ser Aldren Vane, had walked deeper than anyone alive.\n\nYou were its guild master. Tonight you went down with him, to open the Ember Gate."
const AFTER_TITLE := "The Ember Gate"
const AFTER := "The Gatekeeper falls, and the gate stands open. Beyond it something vast breathes in the dark, and says Aldren's name.\n\nAldren lowers his sword. He doesn't look at you."
const BETRAYAL_TITLE := "The First Blade"
const BETRAYAL := "\"Twelve years I've carried your lantern,\" he says. \"Death pays better.\"\n\nHe cuts Mira down before she can draw. He takes the guild's seal from your belt, and with it the strongroom, the charters and every name on the payroll. Then he walks through the gate, and the dark closes behind him."
const AFTERMATH_TITLE := "Last Lantern, three weeks later"
const AFTERMATH := "The Lantern Company is gone. Its hall and its people answer to the First Blade's men now. You have a rented room above the Lantern Street stables, a few coins, and the right to call yourself a guild.\n\nSomewhere at the bottom of the Maw, Aldren is waiting at Death's side. Start again."

## The fight at the Ember Gate.
const GATE := {
	"name": "The Ember Gate",
	"foes": [
		{"name": "Brimstone imp", "kind": "imp", "hp": 70, "damage": 16, "speed": 1.0, "armour": 10},
		{"name": "The Gatekeeper", "kind": "devil", "hp": 300, "damage": 26, "speed": 0.9, "armour": 22, "boss": true},
		{"name": "Brimstone imp", "kind": "imp", "hp": 70, "damage": 16, "speed": 1.0, "armour": 10},
	],
}
const ALDREN := {"id": "aldren", "name": "Ser Aldren Vane", "cls": "knight", "sprite": "aldren", "hero": true, "porter": false,
	"hp": 260.0, "max_hp": 260.0, "damage": 34.0, "speed": 1.0, "crit": 0.25, "crit_damage": 2.0, "pen": 0.3, "first": 0.0,
	"armour": 70.0, "dodge": 0.0, "parry": 0.1, "block": 0.25, "lucky": false, "heal": 80, "stun": 0.1}
const MIRA := {"id": "mira", "name": "Mira Holt", "cls": "rogue", "sprite": "mira", "hero": true, "porter": false,
	"hp": 150.0, "max_hp": 150.0, "damage": 20.0, "speed": 1.6, "crit": 0.4, "crit_damage": 2.2, "pen": 0.2, "first": 0.3,
	"armour": 30.0, "dodge": 0.25, "parry": 0.0, "block": 0.0, "lucky": false, "heal": 60, "stun": 0.0}

var game
var crawl: Control
var replay: bool = false
var hero_class: String = ""
var hero_name: String = ""
var _won: bool = false
var _skipped: bool = false
var _names_rng := RandomNumberGenerator.new()

@onready var veil: ColorRect = $Veil
@onready var card: Control = $Card
@onready var kicker: Label = $Card/Margin/Body/Kicker
@onready var title_label: Label = $Card/Margin/Body/Title
@onready var text_label: Label = $Card/Margin/Body/Text
@onready var next_btn: Button = $Card/Margin/Body/Buttons/Next
@onready var skip_btn: Button = $Card/Margin/Body/Buttons/Skip
@onready var choice: Control = $Choice

signal _next_pressed
signal _fight_over

func _ready() -> void:
	next_btn.pressed.connect(func() -> void: _next_pressed.emit())
	skip_btn.pressed.connect(_skip)
	next_btn.set_meta("tut", "prologue:next")
	for cls in ["Knight", "Rogue"]:
		var b := get_node("Choice/Options/%s/Margin/Body/Choose" % cls) as Button
		b.pressed.connect(_choose.bind(cls.to_lower()))
		var c: Dictionary = Heroes.CLASSES[cls.to_lower()]
		(get_node("Choice/Options/%s/Margin/Body/Blurb" % cls) as Label).text = str(c["blurb"])
		(get_node("Choice/Options/%s/Margin/Body/Skill" % cls) as Label).text = "%s: %s" % [str(c["skill_name"]), str(c["skill_text"])]
		(get_node("Choice/Options/%s/Margin/Body/Wants" % cls) as Label).text = "Gets the most from %s." % str(c["wants"])
	(get_node("Choice/NameRow/Another") as Button).pressed.connect(_reroll_name)

## Leaving the tree mid-story (quitting from the prologue): let the waiting steps run out, so
## nothing is left suspended holding the guild.
func _exit_tree() -> void:
	_skipped = true
	_next_pressed.emit()
	_fight_over.emit()

## Run the prologue. `replay`: the guild already exists (Settings, Replay tutorial): nothing is
## founded at the end.
func play(state, crawl_view: Control, is_replay: bool = false) -> void:
	game = state
	crawl = crawl_view
	replay = is_replay
	_won = false
	_skipped = false
	visible = true
	choice.visible = false
	veil.color.a = 1.0
	Sound.music_cue("mus_title", true)
	await _story("Prologue", INTRO_TITLE, INTRO, "Go down")
	if _skipped or not visible:
		return
	await _fight()
	if _skipped or not visible:
		return
	# The betrayal plays out on the crawl screen, the story over it.
	veil.color.a = 0.0
	await _story("", AFTER_TITLE, AFTER, "Aldren?")
	if _skipped or not visible:
		return
	crawl.callout.text = ""
	crawl.reskin("h0", "first_blade")
	Sound.play("wind_up")
	await get_tree().create_timer(0.5).timeout
	crawl.fell("h1")
	Sound.play("death")
	await get_tree().create_timer(0.8).timeout
	await _story("", BETRAYAL_TITLE, BETRAYAL, "Climb out")
	if _skipped or not visible:
		return
	var tw := create_tween()
	tw.tween_property(veil, "color:a", 1.0, 1.2)
	await tw.finished
	crawl.close()
	Sound.music_end()
	await _story("", AFTERMATH_TITLE, AFTERMATH, "Start again")
	if _skipped or not visible:
		return
	if replay:
		_finish()
		return
	_show_choice()

# --- Story cards -----------------------------------------------------------------------

func _story(kick: String, title: String, text: String, button: String) -> void:
	kicker.text = kick
	kicker.visible = kick != ""
	title_label.text = title
	text_label.text = text
	next_btn.text = button
	skip_btn.visible = kick != "" and not replay
	card.visible = true
	card.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 0.5)
	await _next_pressed
	Sound.play("page_turn")
	card.visible = false

func _skip() -> void:
	_skipped = true
	Sound.play("page_turn")
	card.visible = false
	if crawl and crawl.visible:
		crawl.close()
	veil.color.a = 1.0
	if replay:
		_finish()
		return
	_show_choice()
	_next_pressed.emit()

# --- The fight ---------------------------------------------------------------------

func _fight() -> void:
	var party: Array = [ALDREN.duplicate(true), MIRA.duplicate(true)]
	var st: Dictionary = Crawl.start(party, GATE, 1077, true)
	st["title"] = "The Brimstone Reach  ·  The Ember Gate"
	st["backdrop"] = "res://assets/ui/art/crawl/ember_gate.png"
	var tw := create_tween()
	tw.tween_property(veil, "color:a", 0.0, 0.6)
	card.visible = false
	crawl.coach = _coach
	crawl.on_turn_done = func() -> void: _fight_over.emit()
	crawl.open(game, st)
	visible = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await _fight_over
	mouse_filter = Control.MOUSE_FILTER_STOP
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	_won = str(st["result"]) == "cleared"

## A line of advice for each turn of the prologue fight.
func _coach(st: Dictionary, hero_i: int) -> String:
	var h: Dictionary = st["party"][hero_i]
	var foes: Array = st["foes"]
	if foes.any(func(f): return bool(f["winding"]) and float(f["hp"]) > 0.0):
		return "The Gatekeeper is winding up a heavy blow. Press Guard: %s will take a fraction of it." % str(h["name"]).get_slice(" ", 0)
	var round_n: int = int(st["round"])
	if hero_i == 0 and round_n <= 1:
		return "Ser Aldren's turn. Click a monster to choose it, then press Strike. His greatsword cuts through their armour."
	if hero_i == 1 and round_n <= 2:
		return "Mira is a rogue. Press Backstab: a heavy blow with twice the chance to crit."
	if hero_i == 0 and int(h.get("cd", 0)) <= 0 and round_n <= 4:
		return "Aldren's Shield Bash stuns a monster for a turn. Use it on the Gatekeeper."
	return ""

# --- Your first hero ----------------------------------------------------------------

func _show_choice() -> void:
	card.visible = false
	choice.visible = true
	choice.modulate.a = 0.0
	_names_rng.seed = Time.get_ticks_usec()
	_reroll_name()
	var tw := create_tween()
	tw.tween_property(choice, "modulate:a", 1.0, 0.5)

func _reroll_name() -> void:
	hero_name = Names.pick(_names_rng)
	(get_node("Choice/NameRow/Name") as Label).text = hero_name

func _choose(cls: String) -> void:
	hero_class = cls
	Sound.play("hire")
	_finish()

func _finish() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	await tw.finished
	visible = false
	modulate.a = 1.0
	choice.visible = false
	finished.emit("" if replay else hero_class, "" if replay else hero_name)
