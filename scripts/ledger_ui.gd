extends Control
## Money Mercs — Guild Ledger interface
## A complete native-Godot UI replacement; existing gameplay and saves are retained.

const C_BG := Color("#121219")
const C_BG2 := Color("#1a1b23")
const C_IRON := Color("#25252b")
const C_LEATHER := Color("#302523")
const C_EDGE := Color("#725947")
const C_GOLD := Color("#d8b075")
const C_COPPER := Color("#d48555")
const C_IVORY := Color("#f1e5d0")
const C_DIM := Color("#ac9f93")
const C_PAPER := Color("#e6d2ae")
const C_PAPER2 := Color("#f2e4c5")
const C_INK := Color("#302b28")
const C_PAPER_DIM := Color("#706352")
const C_CRIMSON := Color("#b94d47")
const C_SAFE := Color("#80af8d")
const C_BLUE := Color("#8caec1")
const C_FOG := Color("#81818b")

const TAB_DATA := [
	["hq","THE GUILD"],
	["harlow","HARLOW MINES"],
	["roster","MERCENARIES"],
	["market","TRADING POST"],
	["expeditions","OTHER CONTRACTS"],
	["ledger","THE CHRONICLE"]
]
const HERO := preload("res://assets/ui/harlow_landscape.svg")
const GUILDHALL := preload("res://assets/ui/guildhall.svg")
const RESOURCE_ICONS := {
	"copper": preload("res://assets/ui/resource_copper.svg"),
	"iron": preload("res://assets/ui/resource_iron.svg"),
	"timber": preload("res://assets/ui/resource_timber.svg"),
	"herbs": preload("res://assets/ui/resource_herbs.svg"),
	"silver": preload("res://assets/ui/resource_silver.svg"),
	"crystal": preload("res://assets/ui/resource_crystal.svg"),
	"relic": preload("res://assets/ui/resource_relic.svg"),
	"sovereign": preload("res://assets/ui/resource_sovereign.svg")
}
const CREST := preload("res://assets/ui/guild_crest.svg")
const GOLD_ICON := preload("res://assets/ui/gold_coin.svg")
const MINER := preload("res://assets/ui/portrait_miner.svg")
const GUARD := preload("res://assets/ui/portrait_guard.svg")
const SCOUT := preload("res://assets/ui/portrait_scout.svg")
const WOLF := preload("res://assets/ui/dire_wolf.svg")
const GOBLINS := preload("res://assets/ui/goblin_prospectors.svg")
const SPIDER := preload("res://assets/ui/cave_spider.svg")
const TROLL := preload("res://assets/ui/cave_troll.svg")

var game: MoneyMercsState
var page: String = "harlow"
var roster_tab: String = "employed"
var selected_crew: Array[String] = []
var tactic: String = "Balanced"
var selected_region: String = "lowlands"
var selected_item: String = "copper"
var selected_merc: String = ""
var selected_report: int = 0
var _reset_confirm: bool = false

var header_gold: Label
var header_wealth: Label
var header_jobs: Label
var notice: Label
var content_host: Control
var nav_row: HBoxContainer
var harlow_view: HarlowController

# Preserves a small, explicit and typed view controller surface for test / action plumbing.
class HarlowController:
	extends RefCounted
	var owner: Control
	var selected: Array[String] = []
	var stance: String = "Balanced"
	func _init(parent: Control) -> void:
		owner = parent
	func _dispatch() -> void:
		owner._dispatch_harlow()

func _ready() -> void:
	game = MoneyMercsState.new()
	game.harlow_sync()
	var returned: int = game.complete_due()
	harlow_view = HarlowController.new(self)
	selected_crew = harlow_view.selected
	_build_shell()
	_refresh()
	if returned > 0:
		_notify("%d expedition(s) returned while you were away. Their reports await." % returned)
	else:
		_notify("Guild office open. All company records are saved automatically.")
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_clock)
	add_child(timer)

func _style(fill: Color, edge: Color = C_EDGE, radius: int = 6, pad: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = edge
	sb.border_width_bottom = 1
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad
	sb.content_margin_bottom = pad
	return sb

func _v(gap: int = 9) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", gap)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node

func _h(gap: int = 12) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", gap)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node

func _lab(s: String, size: int = 14, ink: Color = C_IVORY, wrap_text: bool = false) -> Label:
	var node := Label.new()
	node.text = s
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", ink)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap_text else TextServer.AUTOWRAP_OFF
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL if wrap_text else Control.SIZE_SHRINK_BEGIN
	return node

func _grow(node: Control) -> void:
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _cover(node: Control) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _gap(parent: Node, pixels: int = 9) -> void:
	var node := Control.new()
	node.custom_minimum_size.y = pixels
	parent.add_child(node)

func _rule(parent: Node, tint: Color = C_EDGE) -> void:
	var line := ColorRect.new()
	line.color = tint
	line.custom_minimum_size.y = 1
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)

func _panel(parent: Node, paper: bool = false, inset: int = 16, highlighted: bool = false) -> VBoxContainer:
	var shell := PanelContainer.new()
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.add_theme_stylebox_override("panel", _style(C_PAPER if paper else C_IRON, C_GOLD if highlighted else (Color("#ad936a") if paper else C_EDGE), 5, inset))
	parent.add_child(shell)
	var content := _v(9)
	shell.add_child(content)
	return content

func _button(s: String, action: Callable, emphasis: bool = false, small: bool = false, paper: bool = false) -> Button:
	var b := Button.new()
	b.text = s
	b.custom_minimum_size.y = 32 if small else 43
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 12 if small else 14)
	var fill: Color = C_COPPER if emphasis else (C_PAPER2 if paper else C_LEATHER)
	var ink: Color = Color("#201a17") if emphasis or paper else C_IVORY
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink)
	b.add_theme_color_override("font_pressed_color", ink)
	b.add_theme_color_override("font_disabled_color", C_FOG)
	b.add_theme_stylebox_override("normal", _style(fill, C_GOLD if emphasis else C_EDGE, 4, 9))
	b.add_theme_stylebox_override("hover", _style(fill.lightened(0.13), C_GOLD, 4, 9))
	b.add_theme_stylebox_override("pressed", _style(fill.darkened(0.10), C_GOLD, 4, 9))
	b.add_theme_stylebox_override("disabled", _style(C_BG2, C_EDGE.darkened(0.35), 4, 9))
	b.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, C_GOLD, 4, 9))
	b.pressed.connect(action)
	return b

func _chip(title: String, color: Color = C_GOLD, paper: bool = false) -> Label:
	var node := _lab(title.to_upper(), 11, color)
	node.add_theme_stylebox_override("normal", _style(C_PAPER2 if paper else C_BG2, Color("#9e8360") if paper else C_EDGE, 3, 6))
	return node

func _portrait(role: String, side: int) -> TextureRect:
	var tx := TextureRect.new()
	var tex: Texture2D = MINER
	if role == "Guard":
		tex = GUARD
	elif role == "Scout":
		tex = SCOUT
	tx.texture = tex
	tx.custom_minimum_size = Vector2(side, side)
	tx.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	return tx

func _image(path_texture: Texture2D, height: int) -> TextureRect:
	var tx := TextureRect.new()
	tx.texture = path_texture
	tx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tx.custom_minimum_size.y = height
	if height <= 100:
		tx.custom_minimum_size.x = height
		tx.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	else:
		tx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return tx

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _build_shell() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = C_BG
	_cover(backdrop)
	add_child(backdrop)
	var all := _v(0)
	_cover(all)
	add_child(all)

	var mast := PanelContainer.new()
	mast.add_theme_stylebox_override("panel", _style(Color("#201e23"), Color("#201e23"), 0, 0))
	all.add_child(mast)
	var mast_margin := MarginContainer.new()
	for name in ["left","right"]:
		mast_margin.add_theme_constant_override("margin_"+name, 27)
	mast_margin.add_theme_constant_override("margin_top", 12)
	mast_margin.add_theme_constant_override("margin_bottom", 11)
	mast.add_child(mast_margin)
	var mast_row := _h(14)
	mast_margin.add_child(mast_row)
	var emblem := _image(CREST, 60)
	emblem.custom_minimum_size.x = 60
	emblem.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mast_row.add_child(emblem)
	var identity := _v(1)
	identity.custom_minimum_size.x = 260
	mast_row.add_child(identity)
	identity.add_child(_lab("MONEY MERCS", 28, C_GOLD))
	identity.add_child(_lab("THE CONTRACTOR'S GUILD   •   EST. 01", 10, C_DIM))
	var blank := Control.new()
	blank.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mast_row.add_child(blank)
	var gold_icon := _image(GOLD_ICON, 38)
	gold_icon.custom_minimum_size.x = 38
	gold_icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mast_row.add_child(gold_icon)
	var gold_pair := _v(2)
	gold_pair.custom_minimum_size.x = 142
	mast_row.add_child(gold_pair)
	gold_pair.add_child(_lab("TREASURY / GOLD", 10, C_DIM))
	header_gold = _lab("", 21, C_GOLD)
	gold_pair.add_child(header_gold)
	var value_pair := _v(2)
	value_pair.custom_minimum_size.x = 151
	mast_row.add_child(value_pair)
	value_pair.add_child(_lab("EST. TOTAL WORTH", 10, C_DIM))
	header_wealth = _lab("", 21, C_IVORY)
	value_pair.add_child(header_wealth)
	var jobs_pair := _v(2)
	jobs_pair.custom_minimum_size.x = 104
	mast_row.add_child(jobs_pair)
	jobs_pair.add_child(_lab("EXPEDITIONS", 10, C_DIM))
	header_jobs = _lab("", 21, C_IVORY)
	jobs_pair.add_child(header_jobs)

	var golden_rule := ColorRect.new()
	golden_rule.color = C_GOLD
	golden_rule.custom_minimum_size.y = 2
	all.add_child(golden_rule)

	var nav_shell := PanelContainer.new()
	nav_shell.add_theme_stylebox_override("panel", _style(C_BG2, C_BG2, 0, 0))
	all.add_child(nav_shell)
	var nav_margin := MarginContainer.new()
	nav_margin.add_theme_constant_override("margin_left", 22)
	nav_margin.add_theme_constant_override("margin_right", 22)
	nav_margin.add_theme_constant_override("margin_top", 7)
	nav_margin.add_theme_constant_override("margin_bottom", 7)
	nav_shell.add_child(nav_margin)
	nav_row = _h(5)
	nav_margin.add_child(nav_row)

	# Full-width content field. Unlike the old screen, there is no narrow left rail.
	var outer := MarginContainer.new()
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("margin_left", 25)
	outer.add_theme_constant_override("margin_right", 25)
	outer.add_theme_constant_override("margin_top", 21)
	outer.add_theme_constant_override("margin_bottom", 16)
	all.add_child(outer)
	content_host = outer

	var footer := PanelContainer.new()
	footer.add_theme_stylebox_override("panel", _style(C_BG2, Color("#75563c"), 0, 0))
	all.add_child(footer)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 25)
	pad.add_theme_constant_override("margin_right", 25)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 8)
	footer.add_child(pad)
	var frow := _h()
	pad.add_child(frow)
	notice = _lab("", 12, C_GOLD, true)
	_grow(notice)
	frow.add_child(notice)
	frow.add_child(_lab("AUTOSAVE    /    CONTRACTOR'S RECORDS", 10, C_DIM))

func _refresh() -> void:
	header_gold.text = _money(game.gold)
	header_wealth.text = _money(game.wealth())
	header_jobs.text = "%d / %d" % [game.missions.size(), game.expedition_slots]
	_clear(nav_row)
	for item in TAB_DATA:
		var key: String = str(item[0])
		var active: bool = page == key
		var btn := _button(str(item[1]), _nav_to.bind(key), active, true)
		btn.custom_minimum_size.y = 39
		if not active:
			btn.add_theme_stylebox_override("normal", _style(C_BG2, Color("#433d3b"), 3, 8))
		nav_row.add_child(btn)
	_clear(content_host)
	match page:
		"harlow": _draw_harlow()
		"hq": _draw_office()
		"roster": _draw_roster()
		"market": _draw_market()
		"expeditions": _draw_contracts()
		"ledger": _draw_journal()

func _nav_to(destination: String) -> void:
	page = destination
	_refresh()

func _notify(message: String) -> void:
	notice.text = "✦   " + message

func _action(result: String) -> void:
	_refresh()
	_notify(result)

func _scroller(target: Node) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	target.add_child(scroll)
	var body := _v(15)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	return body

func _heading(parent: Node, over: String, title: String, note: String = "") -> void:
	parent.add_child(_lab(over.to_upper(), 11, C_COPPER))
	parent.add_child(_lab(title, 31, C_IVORY))
	if not note.is_empty():
		var desc := _lab(note, 13, C_DIM, true)
		_grow(desc)
		parent.add_child(desc)

func _section(parent: Node, index: String, name: String, sub: String = "") -> void:
	var row := _h(10)
	parent.add_child(row)
	row.add_child(_lab(index, 14, C_COPPER))
	row.add_child(_lab(name, 20, C_IVORY))
	if not sub.is_empty():
		var filler := Control.new()
		filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(filler)
		row.add_child(_lab(sub.to_upper(), 11, C_DIM))

func _metric(parent: Node, title: String, value: String, color: Color, paper: bool = false) -> void:
	var box := _v(3)
	_grow(box)
	parent.add_child(box)
	box.add_child(_lab(title.to_upper(), 10, C_PAPER_DIM if paper else C_DIM))
	var number := _lab(value, 21, color)
	box.add_child(number)

func _money(amount: int) -> String:
	var s: String = str(absi(amount))
	var result := ""
	for i in range(s.length()):
		if i > 0 and (s.length() - i) % 3 == 0:
			result += ","
		result += s[i]
	return ("-" if amount < 0 else "") + result + " G"

func _duration(seconds: int) -> String:
	if seconds >= 3600:
		return "%dh %02dm" % [int(seconds / 3600), int(seconds / 60) % 60]
	if seconds >= 60:
		return "%dm %02ds" % [int(seconds / 60), seconds % 60]
	return "%ds" % maxi(0, seconds)

func _texture_hero(parent: Node, office: bool = false) -> void:
	var hero := Control.new()
	hero.clip_contents = true
	hero.custom_minimum_size.y = 216
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(hero)
	var scene := _image(GUILDHALL if office else HERO, 216)
	_cover(scene)
	hero.add_child(scene)
	var veil := ColorRect.new()
	veil.color = Color("#141419", 0.61)
	veil.anchor_left = 0.0
	veil.anchor_right = 0.52
	veil.anchor_top = 0.0
	veil.anchor_bottom = 1.0
	hero.add_child(veil)
	var trim := ColorRect.new()
	trim.color = C_GOLD
	trim.anchor_top = 1.0
	trim.anchor_right = 1.0
	trim.offset_top = -3
	hero.add_child(trim)
	var overlay := MarginContainer.new()
	_cover(overlay)
	overlay.add_theme_constant_override("margin_left", 24)
	overlay.add_theme_constant_override("margin_top", 19)
	overlay.add_theme_constant_override("margin_bottom", 17)
	hero.add_child(overlay)
	var stack := _v(6)
	stack.alignment = BoxContainer.ALIGNMENT_END
	overlay.add_child(stack)
	stack.add_child(_chip("HEAD OFFICE  /  THE CONTRACTORS GUILD" if office else "REGION 01  /  THE NORTHERN CLAIMS", C_GOLD))
	stack.add_child(_lab("THE GUILDHALL" if office else "HARLOW MINES", 38, C_IVORY))
	stack.add_child(_lab("Every fortune begins here." if office else "The deeper the seam, the greater the danger.", 14, C_IVORY))
	var tier := _h(7)
	stack.add_child(tier)
	tier.add_child(_chip("OPERATIONS OPEN" if office else "MINING CONTRACT", C_COPPER))
	tier.add_child(_chip("ACCOUNTS IN ORDER" if office else "ROTATION ACTIVE", C_SAFE))

func _draw_harlow() -> void:
	game.harlow_sync()
	var field := _h(18)
	content_host.add_child(field)
	var body := _scroller(field)
	var dossier := _v(15)
	body.add_child(dossier)
	_texture_hero(dossier)

	var details := _h(13)
	dossier.add_child(details)
	# Paper intelligence sheet occupies the majority of the report row.
	var paper := _panel(details, true, 15)
	paper.custom_minimum_size.x = 390
	var report_header := _h(7)
	paper.add_child(report_header)
	report_header.add_child(_lab("I / THE SURVEY", 17, C_INK))
	var grow := Control.new()
	grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_header.add_child(grow)
	report_header.add_child(_chip("SCOUT'S FIELD NOTES", C_PAPER_DIM, true))
	_rule(paper, Color("#b19a77"))
	var report: Dictionary = game.harlow.get("report", {})
	var level: int = int(game.harlow.get("scout_level", 1))
	if report.is_empty():
		var waiting: bool = int(game.harlow.get("scout_finish", 0)) > 0
		paper.add_child(_lab("The mines have not been surveyed.", 20, C_INK, true))
		paper.add_child(_lab("Every rotation changes the ore and whatever lurks inside. Scout before you risk your payroll.", 13, C_PAPER_DIM, true))
		if waiting:
			paper.add_child(_lab("SCOUT IN FIELD  ·  %s REMAINING" % _duration(maxi(0, int(game.harlow["scout_finish"]) - int(Time.get_unix_time_from_system()))), 14, Color("#825b37")))
		else:
			paper.add_child(_button("SEND SCOUT  /  %s" % _duration(game.harlow_scout_seconds()), _scout, true, false, true))
	else:
		var ore: String = str(report.get("primary", "copper"))
		var num: int = int(report.get("minimum", 0))
		paper.add_child(_lab("AT LEAST %d VEINS" % num, 28, C_INK))
		paper.add_child(_lab("Confirmed %s deposits" % str(MoneyMercsState.RESOURCE_NAMES.get(ore, ore)), 14, Color("#8b4b2c")))
		paper.add_child(_lab("SURVEY RELIABILITY: %s" % ("EXACT COUNTS" if bool(report.get("exact", false)) else "PARTIAL INTELLIGENCE"), 11, C_PAPER_DIM))
		if report.has("threat_note"):
			paper.add_child(_lab("THREAT INTEL: %s  ·  %s" % [
				str(report.get("danger_band", "Unknown")), str(report["threat_note"])], 12, C_PAPER_DIM, true))
		var additional: Dictionary = report.get("all_ore", {})
		if not additional.is_empty():
			var findings: Array[String] = []
			for id in ["copper","iron","silver","crystal"]:
				if int(additional.get(id, 0)) > 0:
					findings.append("%d%s %s" % [int(additional[id]), "" if level == 3 else "+", str(MoneyMercsState.RESOURCE_NAMES[id])])
			if not findings.is_empty():
				paper.add_child(_lab("ALSO REPORTED: " + "  ·  ".join(findings), 12, C_PAPER_DIM, true))
	_rule(paper, Color("#b19a77"))
	var training := _h(8)
	paper.add_child(training)
	var note := _v(2)
	training.add_child(note)
	note.add_child(_lab("GUILD SCOUT  •  TIER %d / 3" % level, 11, C_INK))
	note.add_child(_lab("Always returns. Better training reveals more.", 11, C_PAPER_DIM, true))
	var cost: int = 200 if level == 1 else 650
	if level < 3:
		var train := _button("TRAIN  /  %d G" % cost, _train_scout, false, true, true)
		train.disabled = game.gold < cost or int(game.harlow.get("scout_finish",0)) > 0
		training.add_child(train)

	var danger := _panel(details, false, 14)
	danger.custom_minimum_size.x = 240
	var label := _h(7)
	danger.add_child(label)
	label.add_child(_lab("II / THREAT ASSESSMENT", 15, C_CRIMSON))
	var has_report: bool = not report.is_empty()
	if has_report:
		var enemy_name: String = str(report.get("creature", "Unknown creature"))
		var enemy: Dictionary = game.harlow.get("enemy", {})
		var threat_art: Texture2D = WOLF
		if "Goblin" in enemy_name:
			threat_art = GOBLINS
		elif "Spider" in enemy_name:
			threat_art = SPIDER
		elif "Troll" in enemy_name:
			threat_art = TROLL
		var preview := _image(threat_art, 116)
		danger.add_child(preview)
		var threat_title := _lab(enemy_name, 17, C_IVORY, true)
		_grow(threat_title)
		danger.add_child(threat_title)
		var tagline := _lab(str(enemy.get("note", "Hostile movement reported.")), 12, C_DIM, true)
		_grow(tagline)
		danger.add_child(tagline)
	else:
		danger.add_child(_lab("UNKNOWN", 25, C_CRIMSON))
		danger.add_child(_lab("No confirmed enemy sightings.", 13, C_DIM, true))
		danger.add_child(_lab("Dispatching blind is permitted, but no reliable forecast is available.", 12, C_DIM, true))

	_section(dossier, "III", "SELECT YOUR COMPANY", "MINERS EXTRACT. GUARDS PROTECT.")
	var roster := GridContainer.new()
	roster.columns = 2
	roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster.add_theme_constant_override("h_separation", 12)
	roster.add_theme_constant_override("v_separation", 12)
	dossier.add_child(roster)
	var count := 0
	for merc in game.crew:
		if not game.is_available(merc):
			continue
		if str(merc.get("role")) != "Miner" and str(merc.get("role")) != "Guard":
			continue
		_crew_card(roster, merc)
		count += 1
	if count == 0:
		var empty := _panel(dossier)
		empty.add_child(_lab("NO AVAILABLE MINERS OR GUARDS", 17, C_GOLD))
		var help := _lab("You need at least one miner for Harlow. Recruit contractors before deploying.", 13, C_DIM, true)
		_grow(help)
		empty.add_child(help)
		empty.add_child(_button("GO TO RECRUITMENT", _open_recruitment, true))

	_section(dossier, "IV", "ONGOING OPERATIONS")
	var running: int = 0
	for mission in game.missions:
		if str(mission.get("region", "")) != "harlow":
			continue
		running += 1
		var run := _panel(dossier)
		var row := _h(12)
		run.add_child(row)
		row.add_child(_chip("IN THE FIELD", C_SAFE))
		row.add_child(_lab("%d workers  /  %s standing orders" % [mission["ids"].size(), str(mission["tactic"])], 13, C_IVORY))
		row.add_child(_lab("RETURNS IN %s" % _duration(maxi(0,int(mission["finish"])-int(Time.get_unix_time_from_system()))), 13, C_GOLD))
	if running == 0:
		var no_jobs := _panel(dossier)
		no_jobs.add_child(_lab("No crew is currently working this claim.", 13, C_DIM))
	_gap(dossier, 12)
	_build_dispatch(field, has_report)

func _crew_card(parent: Node, merc: Dictionary) -> void:
	var id: String = str(merc["id"])
	var role: String = str(merc["role"])
	var active: bool = selected_crew.has(id)
	var wrap := PanelContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_theme_stylebox_override("panel", _style(C_LEATHER if active else C_IRON, C_GOLD if active else C_EDGE, 6, 12))
	parent.add_child(wrap)
	var stack := _v(8)
	wrap.add_child(stack)
	var row := _h(10)
	stack.add_child(row)
	row.add_child(_portrait(role, 72))
	var details := _v(3)
	row.add_child(details)
	details.add_child(_lab(str(merc["name"]), 20, C_IVORY))
	details.add_child(_lab(role.to_upper() + "  /  " + str(merc["title"]), 11, C_GOLD, true))
	var worn: Dictionary = merc.get("equipment", {})
	details.add_child(_lab("HEALTH %d%%   ·   %s" % [
		int(merc.get("health",100)), _equipment_name(worn.get("tool", {}))], 11, C_DIM, true))
	var status := _h(8)
	stack.add_child(status)
	status.add_child(_chip("ASSIGNED" if active else "AVAILABLE", C_GOLD if active else C_SAFE))
	var btn := _button("REMOVE FROM PARTY" if active else "ADD TO PARTY   +", _toggle_crew.bind(not active, id), active, true)
	stack.add_child(btn)

func _build_dispatch(parent: Node, has_report: bool) -> void:
	var side := PanelContainer.new()
	side.custom_minimum_size.x = 347
	side.size_flags_horizontal = Control.SIZE_SHRINK_END
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_theme_stylebox_override("panel", _style(C_PAPER, Color("#c5a577"), 4, 15))
	parent.add_child(side)
	var sidebar := _v(9)
	side.add_child(sidebar)
	var briefing_scroll := ScrollContainer.new()
	briefing_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	briefing_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar.add_child(briefing_scroll)
	var column := _v(11)
	briefing_scroll.add_child(column)
	var emblem_line := _h(9)
	column.add_child(emblem_line)
	emblem_line.add_child(_image(CREST, 45))
	var title_text := _v(3)
	emblem_line.add_child(title_text)
	title_text.add_child(_lab("DISPATCH WARRANT", 20, C_INK))
	title_text.add_child(_lab("CONTRACT NO. H-01  /  QUARTERMASTER", 10, C_PAPER_DIM))
	_rule(column, Color("#ad916c"))
	column.add_child(_lab("PARTY ASSEMBLY", 11, C_PAPER_DIM))
	for i in range(3):
		var members: Array[String] = _selected_available()
		var slot := _h(9)
		column.add_child(slot)
		if i < members.size():
			var worker: Dictionary = game.merc_by_id(members[i])
			slot.add_child(_portrait(str(worker.get("role", "Miner")), 43))
			var designation := _v(2)
			slot.add_child(designation)
			designation.add_child(_lab(str(worker["name"]), 15, C_INK))
			designation.add_child(_lab("%s · %s" % [
				str(worker["role"]), _equipment_name((worker.get("equipment", {}) as Dictionary).get("tool", {}))], 11, C_PAPER_DIM))
		else:
			var vacant := _lab("○    EMPTY CONTRACTOR SLOT", 12, Color("#9b8c76"))
			slot.add_child(vacant)
	_rule(column, Color("#ad916c"))
	column.add_child(_lab("STANDING ORDERS", 11, C_PAPER_DIM))
	for option in MoneyMercsState.TACTICS:
		var selected: bool = tactic == str(option)
		var desc: String = "Safeguard crew" if option == "Cautious" else ("Profit / risk balance" if option == "Balanced" else "More yield, more deaths")
		var opt := _button("%s    ·    %s" % [str(option).to_upper(), desc], _set_tactic.bind(str(option)), selected, true, true)
		opt.alignment = HORIZONTAL_ALIGNMENT_LEFT
		column.add_child(opt)
	_rule(column, Color("#ad916c"))
	var stats: Dictionary = game.harlow_crew_stats(_selected_available(), tactic)
	var risks: Dictionary = stats.get("death", {})
	var maximum: float = 0.0
	for id in risks:
		maximum = maxf(maximum, float(risks[id]))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 12)
	column.add_child(grid)
	_mini_stat(grid, "ORE CAPACITY", "%d veins" % int(stats["capacity"]), Color("#85512e"))
	_mini_stat(grid, "UPFRONT WAGES", _money(int(stats["wage"])), C_INK)
	_mini_stat(grid, "OBJECTIVE SUCCESS", "%d%%" % int(round(float(stats["success"])*100.0)) if has_report else "Unscouted", Color("#3e7958") if has_report else C_CRIMSON)
	_mini_stat(grid, "HIGHEST PERSONAL RISK", "%d%%" % int(round(maximum*100.0)) if has_report else "Unknown", C_CRIMSON)
	_mini_stat(grid, "GEAR EXPOSED TO LOSS", _money(int(stats["gear_value"])), C_INK)
	_mini_stat(grid, "MISSION LENGTH", _duration(int(stats["duration"])), C_INK)
	if has_report and not risks.is_empty():
		for id in risks:
			var member: Dictionary = game.merc_by_id(str(id))
			if not member.is_empty():
				column.add_child(_lab("%s: %d%% fatality estimate" % [
					str(member["name"]), int(round(float(risks[id])*100.0))], 12, C_PAPER_DIM))
	_rule(column, Color("#ad916c"))
	var caution := _lab("PERMADEATH   /   Dead mercenaries and equipped gear are lost forever.", 12, Color("#a44039"), true)
	_grow(caution)
	sidebar.add_child(caution)
	var total_deposits := 0
	var deposits: Dictionary = game.harlow.get("deposits", {})
	for id in deposits:
		total_deposits += int(deposits[id])
	var available: Array[String] = _selected_available()
	var can_dispatch: bool = available.size() >= 1 and available.size() <= 3 and int(stats["miners"]) >= 1 and game.gold >= int(stats["wage"]) and total_deposits > 0 and game.missions.size() < game.expedition_slots
	var go := _button("SIGN & FUND EXPEDITION   →", _dispatch_harlow, true)
	go.custom_minimum_size.y = 54
	go.disabled = not can_dispatch
	sidebar.add_child(go)
	var reason := "Select a miner to begin." if int(stats["miners"]) == 0 else ("Too many workers (maximum 3)." if available.size() > 3 else ("Insufficient gold to fund wages." if game.gold < int(stats["wage"]) else ("Current rotation depleted." if total_deposits == 0 else ("All operation slots occupied." if game.missions.size() >= game.expedition_slots else "Orders hold even while you are offline."))))
	var help := _lab(reason, 12, C_PAPER_DIM, true)
	_grow(help)
	sidebar.add_child(help)

func _mini_stat(parent: Node, name: String, value: String, color: Color) -> void:
	var card := _v(3)
	card.custom_minimum_size.x = 145
	parent.add_child(card)
	card.add_child(_lab(name, 10, C_PAPER_DIM))
	card.add_child(_lab(value, 18, color, true))

func _selected_available() -> Array[String]:
	var clean: Array[String] = []
	for id in selected_crew:
		var merc: Dictionary = game.merc_by_id(id)
		if not merc.is_empty() and game.is_available(merc):
			clean.append(id)
	return clean

func _toggle_crew(on: bool, id: String) -> void:
	if on and not selected_crew.has(id):
		selected_crew.append(id)
	if not on:
		selected_crew.erase(id)
	harlow_view.selected = selected_crew.duplicate()
	_refresh()

func _set_tactic(new_tactic: String) -> void:
	tactic = new_tactic
	harlow_view.stance = new_tactic
	_refresh()

func _scout() -> void:
	_action(game.harlow_send_scout())

func _train_scout() -> void:
	_action(game.harlow_upgrade_scout())

func _dispatch_harlow() -> void:
	var result: String = game.harlow_dispatch(_selected_available(), tactic)
	if result.begins_with("Harlow expedition funded"):
		selected_crew.clear()
		harlow_view.selected.clear()
	_action(result)

func _open_recruitment() -> void:
	roster_tab = "recruits"
	_nav_to("roster")

func _draw_office() -> void:
	var body := _scroller(content_host)
	_heading(body, "THE GUILD OFFICE  /  COMPANY AFFAIRS", "An empire begins with a single contract.", "Your fortune is not made in one night. Study the job, hire wisely, and survive long enough to grow.")
	_texture_hero(body, true)
	_section(body, "I", "COMPANY LEDGER", "YOUR NUMBERS")
	var row := _h(12)
	body.add_child(row)
	for item in [["SPENDABLE GOLD",_money(game.gold)],["COMPANY APPRAISAL",_money(game.wealth())],["REPUTATION",str(game.reputation)],["AVAILABLE WORKERS",str(game.free_crew())]]:
		var p := _panel(row)
		p.add_child(_lab(str(item[0]), 11, C_DIM))
		p.add_child(_lab(str(item[1]), 25, C_GOLD))
	_section(body, "II", "THE NEXT OPPORTUNITY")
	var actions := _h(12)
	body.add_child(actions)
	var left := _panel(actions, true, 20)
	left.add_child(_lab("HARLOW MINES", 25, C_INK))
	left.add_child(_lab("A changing claim with ore deposits and dangerous residents. Scout it, equip a crew, and risk the expedition.", 14, C_PAPER_DIM, true))
	left.add_child(_button("OPEN THE HARLOW DOSSIER  →", _nav_to.bind("harlow"), true))
	var right := _panel(actions, false, 20)
	right.add_child(_lab("CONTRACTOR RECRUITMENT", 25, C_IVORY))
	right.add_child(_lab("A miner earns your gold. A guard keeps your miner alive. Neither is cheap to replace.", 14, C_DIM, true))
	right.add_child(_button("RECRUIT A MERCENARY  →", _open_recruitment, true))
	_section(body, "III", "RECENT FIELD REPORTS")
	if game.reports.is_empty():
		var blank := _panel(body)
		blank.add_child(_lab("No expeditions have returned yet.", 15, C_DIM))
	else:
		for i in range(mini(2, game.reports.size())):
			var report: Dictionary = game.reports[i]
			var plate := _panel(body)
			plate.add_child(_lab("%s   /   %s" % [str(report["region"]), "SUCCESS" if bool(report["won"]) else "FAILED"], 16, C_IVORY))
			plate.add_child(_lab(_loot_text(report["loot"]), 12, C_DIM))
	var expand := _panel(body)
	expand.add_child(_lab("EXPANSION / FIELD TEAM CAPACITY", 15, C_GOLD))
	expand.add_child(_lab("%d of 3 expedition slots available. Expansion costs increase as your guild grows." % game.expedition_slots, 12, C_DIM, true))
	if game.relief_debt > 0:
		expand.add_child(_lab("Guild recovery debt: %s. Trade proceeds above a protected 120 gold repay it." % _money(game.relief_debt), 12, C_COPPER, true))
	if game.missions.is_empty() and game.gold < 28 and game.relief_debt < 440:
		expand.add_child(_button("REQUEST EMERGENCY GUILD ADVANCE  /  90 G", func() -> void:
			_action(game.guild_relief())
		, true))
	if game.expedition_slots < 3:
		expand.add_child(_button("PURCHASE SLOT   •   %s" % _money(900 if game.expedition_slots == 1 else 4200), func() -> void:
			_action(game.expand_operations())
		, true))
	_gap(body, 18)

func _draw_roster() -> void:
	var body := _scroller(content_host)
	_heading(body, "PERSONNEL FILES  /  SIGNED CONTRACTORS", "Your mercenaries are your greatest expense.", "The more experience they accumulate, the more painful it is to lose them.")
	var tabs := _h(8)
	body.add_child(tabs)
	tabs.add_child(_button("UNDER CONTRACT  /  %d" % game.crew.size(), _set_roster_tab.bind("employed"), roster_tab == "employed"))
	tabs.add_child(_button("RECRUITMENT BOARD", _set_roster_tab.bind("recruits"), roster_tab == "recruits"))
	tabs.add_child(_button("THE ARMORY", _set_roster_tab.bind("armory"), roster_tab == "armory"))
	if roster_tab == "armory":
		_draw_armory(body)
		return
	var roster := GridContainer.new()
	roster.columns = 2
	roster.add_theme_constant_override("h_separation", 14)
	roster.add_theme_constant_override("v_separation", 14)
	roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(roster)
	if roster_tab == "recruits":
		for candidate in game.recruitment_board():
			if game.merc_by_id(str(candidate["id"])).is_empty():
				_person_card(roster, candidate, false)
	else:
		for merc in game.crew:
			_person_card(roster, merc, true)
	if roster.get_child_count() == 0:
		var empty := _panel(body)
		empty.add_child(_lab("No files found on this board.", 15, C_DIM))
	_gap(body, 20)

func _set_roster_tab(tab: String) -> void:
	roster_tab = tab
	_refresh()

func _person_card(parent: Node, merc: Dictionary, employed: bool) -> void:
	var p := _panel(parent, false, 15)
	var top := _h(12)
	p.add_child(top)
	top.add_child(_portrait(str(merc["role"]), 104))
	var desc := _v(5)
	top.add_child(desc)
	desc.add_child(_lab(str(merc["name"]), 25, C_IVORY))
	desc.add_child(_lab(str(merc["title"]), 13, C_GOLD))
	desc.add_child(_chip(str(merc["role"]).to_upper(), C_COPPER))
	_rule(p)
	var numbers := _h()
	p.add_child(numbers)
	if employed:
		_metric(numbers, "HEALTH", "%d%%" % int(merc.get("health",100)), C_SAFE)
		_metric(numbers, "EQUIPMENT", "%d / 2" % _equipped_count(merc), C_GOLD)
		_metric(numbers, "EXPERIENCE", str(int(merc.get("xp",0))), C_IVORY)
	else:
		_metric(numbers, "HIRE COST", _money(int(merc["hire"])), C_GOLD)
		_metric(numbers, "BASE SKILL", str(int(merc["skill"])), C_IVORY)
		_metric(numbers, "LOOT SHARE", "%d%%" % int(round(float(merc["share"])*100.0)), C_COPPER)
	if employed:
		p.add_child(_lab("%s  /  %s" % [str(merc.get("contract","Balanced")), "In the field" if not game.is_available(merc) else "Ready for work"], 12, C_DIM))
		var actions := _h(7)
		p.add_child(actions)
		actions.add_child(_button("TERMS", _terms.bind(str(merc["id"])), false, true))
		actions.add_child(_button("OUTFIT", _outfit.bind(str(merc["id"])), false, true))
		if int(merc.get("health",100)) < 100:
			actions.add_child(_button("HEAL", _heal.bind(str(merc["id"])), false, true))
		var equipped: Dictionary = merc.get("equipment", {})
		p.add_child(_lab("Tool: %s   ·   Armor: %s" % [
			_equipment_name(equipped.get("tool", {})), _equipment_name(equipped.get("armor", {}))], 11, C_DIM, true))
	else:
		var recruit := _button("SIGN CONTRACT  /  %s" % _money(int(merc["hire"])), _hire.bind(str(merc["id"])), true)
		recruit.disabled = game.gold < int(merc["hire"])
		p.add_child(recruit)

func _hire(id: String) -> void:
	var text: String = game.hire(id)
	if text.contains("joined"):
		roster_tab = "employed"
	_action(text)

func _equipped_count(merc: Dictionary) -> int:
	var worn: Dictionary = merc.get("equipment", {})
	var result: int = 0
	for slot in ["tool", "armor"]:
		if not (worn.get(slot, {}) as Dictionary).is_empty():
			result += 1
	return result

func _equipment_name(item: Dictionary) -> String:
	if item.is_empty():
		return "Empty"
	return str(game.item_definition(str(item.get("key", ""))).get("name", "Unknown"))

func _outfit(id: String) -> void:
	selected_merc = id
	roster_tab = "armory"
	page = "roster"
	_refresh()

func _draw_armory(body: VBoxContainer) -> void:
	_section(body, "I", "QUARTERMASTER'S STORES", "%d UNASSIGNED ITEMS" % game.equipment_inventory.size())
	var chooser := _panel(body, true, 15)
	chooser.add_child(_lab("OUTFITTING ORDER / CHOOSE A MERCENARY", 16, C_INK))
	var employees := _h(7)
	chooser.add_child(employees)
	var picked: Dictionary = game.merc_by_id(selected_merc)
	if picked.is_empty() and not game.crew.is_empty():
		selected_merc = str(game.crew[0]["id"])
		picked = game.crew[0]
	for member in game.crew:
		var id: String = str(member["id"])
		var choose := _button(str(member["name"]), _choose_worker.bind(id), id == selected_merc, true, true)
		employees.add_child(choose)
	if not picked.is_empty():
		chooser.add_child(_lab("OUTFITTING: %s   /   %s" % [str(picked["name"]), str(picked["role"])], 16, C_INK))
		var worn: Dictionary = picked.get("equipment", {})
		for slot in ["tool", "armor"]:
			var line := _h(9)
			chooser.add_child(line)
			line.add_child(_lab("%s: %s" % [slot.capitalize(), _equipment_name(worn.get(slot, {}))], 13, C_INK))
			var spacer := Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(spacer)
			if not (worn.get(slot, {}) as Dictionary).is_empty():
				var remove := _button("UNEQUIP", _unequip.bind(selected_merc, slot), false, true, true)
				remove.disabled = not game.is_available(picked)
				line.add_child(remove)
	else:
		chooser.add_child(_lab("Hire a mercenary before equipping your gear.", 14, C_PAPER_DIM))
	_section(body, "II", "AVAILABLE EQUIPMENT")
	if game.equipment_inventory.is_empty():
		var vacant := _panel(body)
		vacant.add_child(_lab("No loose equipment in your armory.", 13, C_DIM))
	for item in game.equipment_inventory:
		var uid: String = str(item.get("uid", ""))
		var key: String = str(item.get("key", ""))
		var definition: Dictionary = game.item_definition(key)
		var store := _panel(body, false, 12)
		var row := _h(10)
		store.add_child(row)
		row.add_child(_lab(str(definition.get("name", "Unknown")), 16, C_IVORY))
		var expand := Control.new()
		expand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(expand)
		row.add_child(_chip(str(definition.get("slot", "tool"))))
		var assign := _button("EQUIP  →", _equip.bind(selected_merc, uid), true, true)
		assign.disabled = picked.is_empty() or not game.is_available(picked) or not MercsV05.validate_role(key, picked)
		row.add_child(assign)
		row.add_child(_button("SELL", _sell_equipment.bind(uid), false, true))
	_section(body, "III", "QUARTERMASTER'S CATALOGUE", "PRICES IN GOLD")
	for key in MercsV05.ITEMS:
		var definition: Dictionary = MercsV05.ITEMS[key]
		var offer := _panel(body, false, 10)
		var row := _h(9)
		offer.add_child(row)
		var name: String = str(definition["name"])
		var text_line := _lab("%s   •   %s / %s" % [name, str(definition["role"]), str(definition["slot"])], 14, C_IVORY)
		row.add_child(text_line)
		var grow := Control.new()
		grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(grow)
		var cost: int = int(definition["cost"])
		var buy := _button("BUY   %s" % _money(cost), _buy_equipment.bind(str(key)), true, true)
		buy.disabled = game.gold < cost
		row.add_child(buy)
		offer.add_child(_lab("Mining +%d   Guard +%d   Protection +%d" % [
			int(definition["mining"]), int(definition["guard"]), int(definition["protection"])], 11, C_DIM))
	_gap(body, 16)

func _choose_worker(id: String) -> void:
	selected_merc = id
	_refresh()

func _buy_equipment(key: String) -> void:
	_action(game.buy_equipment(key))

func _equip(id: String, uid: String) -> void:
	_action(game.equip_item(id, uid))

func _sell_equipment(uid: String) -> void:
	_action(game.sell_equipment(uid))

func _unequip(id: String, slot: String) -> void:
	_action(game.unequip_item(id, slot))

func _terms(id: String) -> void:
	_action(game.switch_contract(id))
func _upgrade_gear(id: String) -> void:
	_action(game.improve_gear(id))
func _heal(id: String) -> void:
	_action(game.treat(id))

func _draw_market() -> void:
	var body := _scroller(content_host)
	_heading(body, "THE TRADE EXCHANGE / GUILD VAULT", "Everything has a price.", "Gold is the standard. Expertise determines whether you got a bargain.")
	var header := _h(12)
	body.add_child(header)
	var cash := _panel(header, true, 16)
	cash.add_child(_lab("TREASURY GOLD", 11, C_PAPER_DIM))
	cash.add_child(_lab(_money(game.gold), 28, C_INK))
	cash.add_child(_lab("Physical bags and storage are planned for a future build.", 12, C_PAPER_DIM, true))
	var total := _panel(header, false, 16)
	total.add_child(_lab("ESTIMATED VAULT VALUE", 11, C_DIM))
	total.add_child(_lab(_money(game.wealth()-game.gold), 28, C_GOLD))
	total.add_child(_lab("Merchant sale prices, not guaranteed player-trade proceeds.", 12, C_DIM, true))
	_section(body, "I", "STORED RESOURCES", "NPC EXCHANGE  /  PROTOTYPE")
	for id in MoneyMercsState.RESOURCE_ORDER:
		var p := _panel(body, id == selected_item, 12, id == selected_item)
		var r := _h(12)
		p.add_child(r)
		var icon_texture: Texture2D = RESOURCE_ICONS.get(id, CREST)
		var icon := _image(icon_texture, 44)
		icon.custom_minimum_size.x = 44
		icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		r.add_child(icon)
		var title := _v(3)
		r.add_child(title)
		title.add_child(_lab(str(MoneyMercsState.RESOURCE_NAMES[id]), 19, C_INK if id == selected_item else C_IVORY))
		title.add_child(_lab("%d held  •  %s selling price" % [int(game.resources.get(id,0)), _money(game.sell_price(id))], 12, C_PAPER_DIM if id == selected_item else C_DIM))
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(spacer)
		var sell := _button("SELL 1", _trade.bind(id, false, 1), false, true, id == selected_item)
		sell.disabled = int(game.resources.get(id,0)) == 0
		r.add_child(sell)
		var all := _button("SELL ALL", _trade.bind(id, false, int(game.resources.get(id,0))), false, true, id == selected_item)
		all.disabled = int(game.resources.get(id,0)) == 0
		r.add_child(all)
		if id != "sovereign" and id != "relic":
			var buy := _button("BUY 1  /  %s" % _money(game.buy_price(id)), _trade.bind(id, true, 1), true, true)
			buy.disabled = game.gold < game.buy_price(id)
			r.add_child(buy)
	_gap(body, 15)

func _trade(item: String, buying: bool, count: int) -> void:
	_action(game.trade(item,buying,count))
func _select_item(item: String) -> void:
	selected_item = item
	_refresh()

func _draw_contracts() -> void:
	var body := _scroller(content_host)
	_heading(body, "PUBLIC JOB BOARD  /  ADDITIONAL CLAIMS", "Other contracts.", "These legacy locations still use simpler expedition rules while Harlow's new systems are expanded.")
	_section(body, "I", "EXPEDITION BOARD")
	for region in MoneyMercsState.REGIONS:
		var p := _panel(body, false, 18)
		p.add_child(_lab(str(region["name"]), 23, C_GOLD))
		var caption := _lab(str(region["tagline"]), 13, C_DIM, true)
		_grow(caption)
		p.add_child(caption)
		p.add_child(_lab("Threat %d  /  Duration %s  /  Supplies %d G  /  Min. reputation %d" % [int(region["threat"]),_duration(int(region["time"])),int(region["supplies"]),int(region["rep"])], 12, C_IVORY))
		var chosen: Array[String] = []
		for merc in game.crew:
			if game.is_available(merc) and chosen.size() < 2:
				chosen.append(str(merc["id"]))
		var send := _button("SEND AVAILABLE CREW  →", _old_dispatch.bind(str(region["id"])), true)
		send.disabled = chosen.is_empty() or game.reputation < int(region["rep"]) or game.missions.size() >= game.expedition_slots
		p.add_child(send)
	_gap(body, 12)

func _old_dispatch(id: String) -> void:
	selected_region = id
	var team: Array[String] = []
	for merc in game.crew:
		if game.is_available(merc) and team.size() < 2:
			team.append(str(merc["id"]))
	_action(game.dispatch(id, team, "Balanced"))

func _select_region(id: String) -> void:
	selected_region = id
	_refresh()

func _draw_journal() -> void:
	var body := _scroller(content_host)
	_heading(body, "COMPANY CHRONICLE / RECORDS", "The cost of ambition.", "Every job, every casualty, and every coin eventually ends up in this ledger.")
	_section(body, "I", "AFTER-ACTION REPORTS")
	if game.reports.is_empty():
		var blank := _panel(body,true,20)
		blank.add_child(_lab("The chronicle is empty.", 23, C_INK))
		blank.add_child(_lab("Reports appear here when your mercenaries return.", 13, C_PAPER_DIM))
	for report in game.reports:
		var p := _panel(body, false, 17)
		var heading := _h(9)
		p.add_child(heading)
		heading.add_child(_lab(str(report["region"]), 21, C_IVORY))
		var space := Control.new()
		space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(space)
		heading.add_child(_chip("SUCCESS" if bool(report["won"]) else "COSTLY RETURN", C_SAFE if bool(report["won"]) else C_CRIMSON))
		p.add_child(_lab("RECOVERED   " + _loot_text(report["loot"]), 13, C_DIM, true))
		var details := _h(8)
		p.add_child(details)
		_metric(details, "FOUND GOLD",_money(int(report["cash"])),C_GOLD)
		_metric(details, "GROSS HAUL",_money(int(report["gross"])),C_IVORY)
		_metric(details, "CREW COMMISSION",_money(int(report["commission"])),C_COPPER)
		var casualties: Array = report.get("casualties", [])
		var injured: Array = report.get("injured", [])
		if not casualties.is_empty():
			p.add_child(_lab("FALLEN CONTRACTORS: "+", ".join(casualties),14,C_CRIMSON))
		if not injured.is_empty():
			p.add_child(_lab("WOUNDED: "+", ".join(injured),13,C_COPPER))
		if bool(report.get("partial", false)):
			p.add_child(_chip("PARTIAL HAUL / RETREAT", C_COPPER))
		var lost: Array = report.get("lost_items", [])
		if not lost.is_empty():
			p.add_child(_lab("LOST EQUIPMENT: " + ", ".join(lost), 13, C_CRIMSON, true))
		var found_items: Array = report.get("found_items", [])
		if not found_items.is_empty():
			p.add_child(_lab("EQUIPMENT DISCOVERED: " + ", ".join(found_items), 14, C_GOLD, true))
		var story: Array = report.get("events", [])
		if not story.is_empty():
			var narrative := _panel(p, true, 14)
			narrative.add_child(_lab("AFTER-ACTION ACCOUNT", 13, C_INK))
			for entry in story:
				narrative.add_child(_lab("•  " + str(entry), 12, C_PAPER_DIM, true))
		p.add_child(_lab("Net appraisal includes unsold resources; it is not equivalent to gold available for wages.", 11, C_DIM, true))
	if OS.is_debug_build():
		_section(body, "II", "DEV TESTING")
		var debug := _panel(body)
		debug.add_child(_lab("Advance existing expedition timers to test return reports, or reset the local test company.", 13,C_DIM,true))
		var actions := _h(10)
		debug.add_child(actions)
		actions.add_child(_button("SIMULATE +15 MIN", func() -> void:
			_action(game.debug_skip(900))
		))
		actions.add_child(_button("CONFIRM RESET" if _reset_confirm else "RESET TEST COMPANY", _reset, _reset_confirm))
	_gap(body, 15)

func _reset() -> void:
	if not _reset_confirm:
		_reset_confirm = true
		_action("Reset armed. Press confirm to permanently reset this test company.")
		return
	game.reset_company()
	selected_crew.clear()
	_reset_confirm = false
	_action("Test company reset.")

func _select_report(index: int) -> void:
	selected_report = index
	_refresh()

func _loot_text(items: Dictionary) -> String:
	var results: Array[String] = []
	for key in items:
		results.append("%d %s" % [int(items[key]), str(MoneyMercsState.RESOURCE_NAMES.get(key,key))])
	return ", ".join(results) if not results.is_empty() else "No resources returned."

func _on_clock() -> void:
	var changed: bool = game.harlow_sync()
	var returned: int = game.complete_due()
	if returned > 0:
		_refresh()
		_notify("%d field team(s) returned. See The Chronicle for full findings." % returned)
	elif changed and page == "harlow":
		_refresh()
	# Refresh time text periodically when on Harlow without disturbing selection.
	elif page == "harlow" and (int(Time.get_unix_time_from_system()) % 5 == 0):
		_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_6:
			_nav_to(str(TAB_DATA[int(event.keycode) - int(KEY_1)][0]))
