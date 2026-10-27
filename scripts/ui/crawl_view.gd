extends Control
## The crawl screen: a crypt run the player leads, floor by floor. Heroes stand on the left,
## monsters on the right; on a hero's turn the player picks a foe (click it) and an action.
## Everything the engine does (scripts/crawl.gd) comes back as events, played here one by one:
## a lunge, a flash, a number rising off whoever was hit, a sound, a line in the log.
##
## The scene is scenes/journal/widgets/crawl_view.tscn. book_ui.gd opens it (open()) and
## refreshes the book when it closes.

signal closed

const FIGHTER := preload("res://scenes/journal/rows/crawl_fighter.tscn")
const CrawlSprite := preload("res://scripts/ui/crawl_sprite.gd")
## Book pixels per sprite pixel (the book is drawn at twice its size on a 1080p screen, so
## ordinary fighters show at 4x and the 128-pixel bosses at 3x).
const SCALE := {64: 2.0, 128: 1.5}
## How long each kind of event holds the screen (seconds).
const BEAT := {"hit": 0.32, "crit": 0.45, "struck": 0.32, "heavy": 0.5, "dodge": 0.26, "parry": 0.26, "kill": 0.35, "death": 0.6,
	"stun": 0.2, "guard": 0.22, "potion": 0.3, "wind": 0.55, "lucky": 0.4, "stunned": 0.2, "round": 0.0, "end": 0.15}

var game
var target: int = -1
var busy: bool = false
## Set by the prologue: called instead of the normal end of a run (see prologue.gd).
var custom_fight: Dictionary = {}
var on_turn_done: Callable
## Set by the prologue: a line of advice for the hero whose turn it is (st, hero index) -> text.
var coach: Callable

@onready var body: Control = $Frame/Margin/Body
@onready var title: Label = $Frame/Margin/Body/Head/Title
@onready var round_label: Label = $Frame/Margin/Body/Head/Round
@onready var release_btn: Button = $Frame/Margin/Body/Head/Release
@onready var arena: Control = $Frame/Margin/Body/Arena
@onready var back: TextureRect = $Frame/Margin/Body/Arena/Back
@onready var party_box: HBoxContainer = $Frame/Margin/Body/Arena/Party
@onready var foes_box: HBoxContainer = $Frame/Margin/Body/Arena/Foes
@onready var floaters: Control = $Frame/Margin/Body/Arena/Floaters
@onready var callout: Label = $Frame/Margin/Body/Arena/Callout
@onready var turn_box: Control = $Frame/Margin/Body/Turn
@onready var prompt: Label = $Frame/Margin/Body/Turn/Left/Prompt
@onready var hint: Label = $Frame/Margin/Body/Turn/Left/Hint
@onready var log_text: RichTextLabel = $Frame/Margin/Body/Turn/Log/Margin/Text
@onready var stairs: Control = $Frame/Margin/Body/Stairs

func _ready() -> void:
	for id in ["Strike", "Skill", "Guard", "Potion", "Retreat"]:
		var b := get_node("Frame/Margin/Body/Turn/Left/Actions/" + id) as Button
		b.set_meta("tut", "crawl:" + id.to_lower())
		b.pressed.connect(_do.bind(id.to_lower()))
		b.mouse_entered.connect(func() -> void: hint.text = b.tooltip_text)
		b.mouse_exited.connect(_set_hint)
	release_btn.pressed.connect(_release)
	release_btn.set_meta("tut", "crawl:release")

# --- Opening -------------------------------------------------------------------------

## Show the run the player is leading (or the fight the prologue hands over).
func open(state, fight: Dictionary = {}) -> void:
	game = state
	custom_fight = fight
	visible = true
	busy = false
	log_text.text = ""
	callout.text = ""
	target = -1
	release_btn.visible = custom_fight.is_empty()
	(get_node("Frame/Margin/Body/Turn/Left/Actions/Retreat") as Control).visible = custom_fight.is_empty()
	_show()

func _fight() -> Dictionary:
	return custom_fight if not custom_fight.is_empty() else game.lead_fight()

func _run() -> Dictionary:
	return {} if not custom_fight.is_empty() else game.lead_run()

## Draw everything from the current state.
func _show() -> void:
	var run: Dictionary = _run()
	var st: Dictionary = _fight()
	stairs.visible = false
	turn_box.visible = true
	if custom_fight.is_empty():
		if run.is_empty():
			_finished()
			return
		var d: Dictionary = Dungeons.by_id(str(run["dungeon"]))
		var floors: Array = d["floors"]
		var i: int = int(run["floor_i"])
		title.text = "%s  ·  Floor %d of %d  ·  %s" % [str(d["name"]), i + 1, floors.size(), str(floors[i]["name"])]
		back.texture = _backdrop(floors[i], d)
		if str(run["stage"]) == "led_between":
			_build_cards({"party": game._run_crew(run), "foes": []})
			_show_stairs(run, d)
			return
	else:
		title.text = str(custom_fight.get("title", "The fight"))
		back.texture = load(str(custom_fight.get("backdrop", ""))) as Texture2D
	_build_cards(st)
	_update_turn(st)

func _backdrop(floor: Dictionary, d: Dictionary) -> Texture2D:
	var path: String = str(floor.get("backdrop", d.get("art", "")))
	return load(path) as Texture2D if ResourceLoader.exists(path) else null

# --- Fighters ------------------------------------------------------------------------

func _build_cards(st: Dictionary) -> void:
	# Out of the boxes now, not at the end of the frame: the new cards reuse the names H0, F0...
	for c in party_box.get_children() + foes_box.get_children():
		c.get_parent().remove_child(c)
		c.queue_free()
	var party: Array = st.get("party", [])
	for i in range(party.size()):
		var card := FIGHTER.instantiate()
		party_box.add_child(card)
		card.name = "H%d" % i
		_paint_card(card, party[i], true)
	var foes: Array = st.get("foes", [])
	for i in range(foes.size()):
		var card := FIGHTER.instantiate()
		foes_box.add_child(card)
		card.name = "F%d" % i
		card.set_meta("tut", "crawl:foe%d" % i)
		_paint_card(card, foes[i], false)
		card.gui_input.connect(_on_foe_input.bind(i))
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _paint_card(card: Control, f: Dictionary, hero: bool) -> void:
	(card.get_node("Name") as Label).text = str(f.get("name", "?"))
	var top: float = maxf(1.0, float(f.get("max_hp", 100.0)))
	var hp: float = maxf(0.0, float(f.get("hp", 0.0)))
	var bar := card.get_node("Bar") as ProgressBar
	bar.max_value = top
	bar.value = hp
	bar.theme_type_variation = &"GreenBar" if hp / top >= 0.5 else (&"GoldBar" if hp / top >= 0.25 else &"")
	(card.get_node("HP") as Label).text = "%d / %d" % [int(ceil(hp)), int(top)]
	var status: Array[String] = []
	if bool(f.get("guard", false)):
		status.append("Guarding")
	if int(f.get("stun", 0)) > 0:
		status.append("Stunned")
	if bool(f.get("winding", false)):
		status.append("Winding up!")
	if hero and int(f.get("cd", 0)) > 0:
		status.append("Skill in %d" % int(f["cd"]))
	(card.get_node("Status") as Label).text = "  ".join(status)
	var key: String = str(f.get("sprite", f.get("cls", "knight") if hero else f.get("kind", "skeleton")))
	key = str(card.get_meta("skin", key))
	if not CrawlSprite.has(key):
		key = "knight" if hero else "skeleton"
	var sprite := card.get_node("Sprite") as TextureRect
	var cell: int = CrawlSprite.cell_of(key)
	sprite.custom_minimum_size = Vector2.ONE * float(cell) * float(SCALE.get(cell, 1.0))
	sprite.flip_h = not hero
	sprite.show_fighter(key, hp <= 0.0)
	card.size_flags_vertical = Control.SIZE_SHRINK_END
	card.modulate = Color(1, 1, 1, 1) if hp > 0.0 else Color(0.45, 0.4, 0.4, 0.55)
	card.tooltip_text = _fighter_tip(f, hero)

func _fighter_tip(f: Dictionary, hero: bool) -> String:
	if hero:
		var bits: Array[String] = ["Damage %d" % int(round(float(f["damage"]))), "speed %.2f" % float(f["speed"]),
			"crit %d%% (x%.1f)" % [int(round(float(f["crit"]) * 100.0)), float(f["crit_damage"])], "armour %d" % int(f["armour"])]
		if float(f.get("pen", 0.0)) > 0.0:
			bits.append("pierces %d%%" % int(round(float(f["pen"]) * 100.0)))
		if float(f.get("dodge", 0.0)) > 0.0 or float(f.get("parry", 0.0)) > 0.0 or float(f.get("block", 0.0)) > 0.0:
			bits.append("dodge %d%% · parry %d%% · block %d%%" % [int(round(float(f["dodge"]) * 100.0)), int(round(float(f["parry"]) * 100.0)), int(round(float(f["block"]) * 100.0))])
		return "%s\n%s" % [str(f["name"]), "\n".join(bits)]
	return "%s\nHealth %d, hits for about %d, armour %d.%s" % [str(f["name"]), int(f["max_hp"]), int(f["damage"]), int(f["armour"]),
		"\nEvery third blow is a heavy one: Guard when it winds up." if bool(f.get("boss", false)) else ""]

func _card(code: String) -> Control:
	if code.length() < 2:
		return null
	var box: Control = party_box if code.begins_with("h") else foes_box
	return box.get_node_or_null(code.to_upper()) as Control

func _refresh_cards(st: Dictionary) -> void:
	for i in range((st["party"] as Array).size()):
		var c := _card("h%d" % i)
		if c:
			_paint_card(c, st["party"][i], true)
	for i in range((st["foes"] as Array).size()):
		var c := _card("f%d" % i)
		if c:
			_paint_card(c, st["foes"][i], false)
	_mark_target(st)

func _on_foe_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var st: Dictionary = _fight()
		if st.is_empty() or i >= (st["foes"] as Array).size() or float(st["foes"][i]["hp"]) <= 0.0:
			return
		target = i
		Sound.play("toggle")
		_mark_target(st)
		_set_hint()

func _mark_target(st: Dictionary) -> void:
	if target < 0 or target >= (st["foes"] as Array).size() or float(st["foes"][target]["hp"]) <= 0.0:
		target = Crawl._weakest(st["foes"])
	for i in range((st["foes"] as Array).size()):
		var c := _card("f%d" % i)
		if c:
			(c.get_node("Mark") as Control).visible = i == target and not Crawl.done(st)

# --- Turns -----------------------------------------------------------------------------

func _update_turn(st: Dictionary) -> void:
	round_label.text = "Round %d" % int(st.get("round", 0))
	_refresh_cards(st)
	var hi: int = Crawl.turn_of(st)
	var actions := get_node("Frame/Margin/Body/Turn/Left/Actions") as Control
	for b in actions.get_children():
		(b as Button).disabled = true
	if hi < 0:
		prompt.text = ""
		return
	var h: Dictionary = st["party"][hi]
	var c: Dictionary = Heroes.CLASSES.get(str(h.get("cls", "")), {})
	for a in Crawl.actions(st, hi):
		var b := actions.get_node(str(a["id"]).capitalize()) as Button
		b.disabled = busy or not bool(a["ok"])
		if str(a["id"]) == "skill":
			b.text = str(a["label"]) if bool(a["ok"]) else "%s (%s)" % [str(a["label"]), str(a["why"]).to_lower()]
			b.tooltip_text = "%s: %s Then it needs %d turns to ready again." % [str(c.get("skill_name", "Skill")), str(c.get("skill_text", "")), Crawl.SKILL_COOLDOWN]
		elif str(a["id"]) == "potion":
			b.text = "Potion" if bool(a["ok"]) else "Potion (%s)" % str(a["why"]).to_lower()
	var foes: Array = st["foes"]
	var winding: bool = foes.any(func(f): return bool(f["winding"]) and float(f["hp"]) > 0.0)
	prompt.text = "%s's turn.%s" % [str(h["name"]), "  Something is winding up a heavy blow: Guard!" if winding else ""]
	if coach.is_valid():
		var advice: String = str(coach.call(st, hi))
		if advice != "":
			prompt.text = advice
	_set_hint()

func _set_hint() -> void:
	var st: Dictionary = _fight()
	if st.is_empty() or Crawl.done(st):
		return
	var t: int = target
	if t >= 0 and t < (st["foes"] as Array).size():
		hint.text = "Target: %s. Click another monster to change it." % str(st["foes"][t]["name"])
	else:
		hint.text = "Click a monster to choose who to hit."

func _do(action: String) -> void:
	if busy:
		return
	var st: Dictionary = _fight()
	if st.is_empty() or Crawl.turn_of(st) < 0:
		return
	busy = true
	_update_turn(st)
	# Keep this fight: when it ends, the run moves on and lets go of it.
	var events: Array
	if custom_fight.is_empty():
		events = game.lead_act(action, target)
	else:
		events = Crawl.act(custom_fight, action, target)
	await _play(events, st)
	busy = false
	if not visible:
		return
	if not custom_fight.is_empty():
		if Crawl.done(custom_fight):
			_refresh_cards(custom_fight)
			turn_box.visible = false
			if on_turn_done.is_valid():
				on_turn_done.call()
			return
		_update_turn(custom_fight)
		return
	var run: Dictionary = game.lead_run()
	if run.is_empty() or str(run["stage"]) != "led":
		await get_tree().create_timer(0.5).timeout
		_show()
		return
	_update_turn(game.lead_fight())

# --- Playing events -------------------------------------------------------------------

func _play(events: Array, st: Dictionary) -> void:
	for e in events:
		var kind: String = str(e["kind"])
		_log(e)
		var beat: float = float(BEAT.get(kind, 0.2))
		var src := _card(str(e["src"]))
		var dst := _card(str(e["dst"]))
		match kind:
			"hit", "crit":
				_lunge(src, 1 if str(e["src"]).begins_with("h") else -1)
				_animate(src, "skill" if str(e.get("skill", "")) != "" else "attack")
				_animate(dst, "hurt")
				_flash(dst)
				_float(dst, ("CRIT %d" if kind == "crit" else "%d") % int(e["amount"]), Color(1, 0.85, 0.35) if kind == "crit" else Color(1, 1, 1), kind == "crit")
				Sound.play("crit" if kind == "crit" else "hit")
				if kind == "crit":
					_shake()
			"struck", "heavy":
				_lunge(src, -1)
				_animate(src, "skill" if kind == "heavy" else "attack")
				_animate(dst, "hurt")
				_flash(dst)
				_float(dst, "%d" % int(e["amount"]), Color(1, 0.45, 0.35), kind == "heavy")
				Sound.play("struck" if kind == "struck" else "crit")
				if str(e["text"]).contains("(blocked)"):
					Sound.play("blocked")
				if kind == "heavy":
					_shake()
			"dodge", "parry":
				_lunge(src, -1)
				_animate(src, "attack")
				_float(dst, "Dodged" if kind == "dodge" else "Parried", Color(0.7, 0.9, 1.0), false)
				Sound.play("dodge")
			"kill":
				Sound.play("foe_down")
			"death":
				Sound.play("death")
			"stun":
				_float(dst, "Stunned", Color(1, 0.8, 0.5), false)
			"guard":
				_float(src, "Guard", Color(0.75, 0.85, 1.0), false)
				Sound.play("guard_up")
			"potion":
				_float(src, "+%d" % int(e["amount"]), Color(0.55, 1.0, 0.55), false)
				Sound.play("drink")
			"wind":
				callout.text = str(e["text"])
				Sound.play("wind_up")
			"lucky":
				_float(src, "Lucky!", Color(1, 0.9, 0.5), true)
		_refresh_cards(st)
		if beat > 0.0:
			await get_tree().create_timer(beat).timeout
		if kind == "wind":
			pass
		elif kind in ["hit", "crit", "struck", "heavy"] and callout.text != "" and not (st["foes"] as Array).any(func(f): return bool(f["winding"])):
			callout.text = ""
	if Crawl.done(st):
		match str(st["result"]):
			"cleared":
				callout.text = "Cleared"
				Sound.play("boss_down" if (st["foes"] as Array).any(func(f): return bool(f["boss"])) else "floor_cleared")
			"fled":
				callout.text = "Backed out"
				Sound.play("retreat")
			"wiped":
				callout.text = "Fallen"
				Sound.play("crew_wiped")

func _log(e: Dictionary) -> void:
	var kind: String = str(e["kind"])
	if kind == "round":
		log_text.append_text("[color=#9a8070]— %s —[/color]\n" % str(e["text"]).trim_suffix("."))
		return
	var color: String = {"crit": "#a8361e", "heavy": "#a8361e", "kill": "#6a3a10", "death": "#8a1a1a", "potion": "#2e6a2a",
		"wind": "#a8361e", "guard": "#2a4a6a", "dodge": "#2a4a6a", "parry": "#2a4a6a", "end": "#3d2824"}.get(kind, "#3d2824")
	log_text.append_text("[color=%s]%s[/color]\n" % [color, str(e["text"])])

func _animate(card: Control, which: String) -> void:
	if card:
		(card.get_node("Sprite") as CrawlSprite).play(which)

func _lunge(card: Control, dir: int) -> void:
	if card == null:
		return
	var sprite := card.get_node("Sprite") as Control
	var tw := create_tween()
	tw.tween_property(sprite, "position:x", sprite.position.x + 10.0 * dir, 0.07)
	tw.tween_property(sprite, "position:x", sprite.position.x, 0.12)

func _flash(card: Control) -> void:
	if card == null:
		return
	var sprite := card.get_node("Sprite") as CanvasItem
	sprite.self_modulate = Color(2.2, 1.6, 1.4, 1)
	var tw := create_tween()
	tw.tween_property(sprite, "self_modulate", Color(1, 1, 1, 1), 0.25)

func _float(card: Control, text: String, color: Color, big: bool) -> void:
	if card == null:
		return
	var l := Label.new()
	l.theme_type_variation = &"DeskTitle"
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.03))
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_font_size_override("font_size", 26 if big else 18)
	floaters.add_child(l)
	var sprite := card.get_node("Sprite") as Control
	var at: Vector2 = sprite.get_global_rect().get_center() - floaters.get_global_rect().position
	l.position = at - Vector2(l.get_combined_minimum_size().x / 2.0, 30)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 34.0, 0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tw.chain().tween_callback(l.queue_free)

func _shake() -> void:
	var tw := create_tween()
	var x: float = arena.position.x
	for k in [4.0, -3.0, 2.0, 0.0]:
		tw.tween_property(arena, "position:x", x + k, 0.04)

# --- Between floors and the end --------------------------------------------------------

func _show_stairs(run: Dictionary, d: Dictionary) -> void:
	turn_box.visible = false
	stairs.visible = true
	var floors: Array = d["floors"]
	var i: int = int(run["floor_i"])
	var b := "Frame/Margin/Body/Stairs/Margin/Body/"
	(get_node(b + "Title") as Label).text = "%s cleared" % str(floors[i]["name"])
	var health: Array[String] = []
	for f in game._run_crew(run):
		health.append("%s %d/%d" % [str(f["name"]), int(ceil(float(f["hp"]))), int(f["max_hp"])])
	var nxt: Dictionary = floors[i + 1]
	(get_node(b + "Text") as Label).text = "You carry %s.  %s.\nNext: %s — %s%s, hit for about %d, armour %d.%s" % [
		_money(game.dungeon_carry_value(run["carry"])), ", ".join(health), str(nxt["name"]),
		"%d " % int(nxt["count"]) if int(nxt["count"]) > 1 else "", str(nxt["foe"]).to_lower() if int(nxt["count"]) > 1 else str(nxt["foe"]),
		int(nxt["damage"]), int(nxt["armour"]), "\nA boss: every third blow is a heavy one." if bool(nxt.get("boss", false)) else ""]
	var carry_row := get_node(b + "Carry") as HBoxContainer
	for c in carry_row.get_children():
		c.queue_free()
	var push := get_node(b + "Buttons/Push") as Button
	var leave := get_node(b + "Buttons/Leave") as Button
	push.visible = true
	push.text = "Go down to %s" % str(nxt["name"])
	leave.text = "Take it out"
	push.set_meta("tut", "crawl:push")
	leave.set_meta("tut", "crawl:leave")
	_rebind(push, func() -> void:
		Sound.play("choice_bold")
		game.lead_choose(true)
		log_text.text = ""
		callout.text = ""
		_show())
	_rebind(leave, func() -> void:
		Sound.play("retreat")
		game.lead_choose(false)
		_finished())

## The run is over: what came of it, from the report it wrote.
func _finished() -> void:
	turn_box.visible = false
	stairs.visible = true
	var b := "Frame/Margin/Body/Stairs/Margin/Body/"
	var rep: Dictionary = game.reports[0] if not game.reports.is_empty() else {}
	var out: String = str(rep.get("outcome", "out"))
	(get_node(b + "Title") as Label).text = {"cleared": "The crypt is cleared", "wiped": "Nobody came back", "loss": "Back up, with losses"}.get(out, "Back up")
	var bits: Array[String] = []
	if int(rep.get("cash", 0)) > 0:
		bits.append("%s in coin" % _money(int(rep["cash"])))
	var goods: Array[String] = []
	for good in rep.get("loot", {}):
		goods.append("%d %s" % [int(rep["loot"][good]), str(game.RESOURCE_NAMES.get(good, good)).to_lower()])
	if not goods.is_empty():
		bits.append(", ".join(goods))
	for f in rep.get("found_items", []):
		bits.append(str(f))
	var text: String = "Brought out: %s." % (", ".join(bits) if not bits.is_empty() else "nothing")
	if not (rep.get("casualties", []) as Array).is_empty():
		text += "\n%s did not come back." % ", ".join(rep["casualties"])
	text += "\nThe full account is in the Ledger's reports."
	(get_node(b + "Text") as Label).text = text
	var push := get_node(b + "Buttons/Push") as Button
	push.visible = false
	var leave := get_node(b + "Buttons/Leave") as Button
	leave.text = "Back to the guild"
	leave.set_meta("tut", "crawl:close")
	_rebind(leave, close)

func close() -> void:
	visible = false
	custom_fight = {}
	coach = Callable()
	on_turn_done = Callable()
	closed.emit()

## For the prologue: change how a fighter looks (and flash it), or drop one where they stand.
func reskin(code: String, sprite_key: String) -> void:
	var c := _card(code)
	if c == null:
		return
	var sprite := c.get_node("Sprite") as CrawlSprite
	sprite.key = ""
	c.set_meta("skin", sprite_key)
	sprite.show_fighter(sprite_key, false)
	var cell: int = CrawlSprite.cell_of(sprite_key)
	sprite.custom_minimum_size = Vector2.ONE * float(cell) * float(SCALE.get(cell, 1.0))
	_flash(c)
	_shake()

func fell(code: String) -> void:
	var c := _card(code)
	if c:
		(c.get_node("Sprite") as CrawlSprite).show_fighter((c.get_node("Sprite") as CrawlSprite).key, true)
		var tw := create_tween()
		tw.tween_property(c, "modulate", Color(0.45, 0.4, 0.4, 0.55), 0.6)

func _release() -> void:
	if busy:
		return
	Sound.play("retreat")
	game.lead_release()
	close()

func _rebind(b: Button, f: Callable) -> void:
	for c in b.pressed.get_connections():
		b.pressed.disconnect(c["callable"])
	b.pressed.connect(f)

static func _money(n: int) -> String:
	return "%d G" % n
