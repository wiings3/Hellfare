extends "res://scripts/ledger_ui.gd"
## Money Mercs: Guildmaster's Desk (original wood/parchment UI).
## The artwork is separate from real Godot controls; all values and actions are live.
## 1600x900 authoring canvas, scaled to the current viewport without clipping.

const ROOM: Texture2D = preload("res://assets/ui/guildhall_desk.svg")
const PAPER: Texture2D = preload("res://assets/ui/skin_parchment.svg")
const WOOD: Texture2D = preload("res://assets/ui/skin_wood.svg")
const RED_WOOD: Texture2D = preload("res://assets/ui/skin_burgundy.svg")
const SEAL: Texture2D = preload("res://assets/ui/skin_wax_seal.svg")
const MINE_INK: Texture2D = preload("res://assets/ui/harlow_ink_sketch.svg")

const INK := Color("#35271d")
const INK_SOFT := Color("#6d5038")
const CREAM := Color("#f8e9cb")
const GOLD_LETTER := Color("#e6bf79")
const MUTED_GOLD := Color("#c9a371")
const DARK_WOOD := Color("#301a10")
const WINE := Color("#762822")
const FOREST := Color("#244532")

var stage: Control
var navigation: Control
var central_area: Control
var dispatch_area: Control
var notes_area: Control
var gold_total: Label
var net_total: Label
var field_total: Label
var guild_book_font: SystemFont
var status_lines: Control

func _ready() -> void:
	page = "hq"
	super._ready()

func _build_shell() -> void:
	guild_book_font = SystemFont.new()
	guild_book_font.font_names = PackedStringArray(["Georgia", "Palatino Linotype", "Times New Roman", "Liberation Serif", "Noto Serif"])
	stage = Control.new()
	stage.name = "GuildmasterDesk"
	stage.position = Vector2.ZERO
	stage.size = Vector2(1600, 900)
	stage.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(stage)
	resized.connect(_scale_stage)
	_scale_stage()

	var scene: TextureRect = _picture(stage, ROOM, 0, 0, 1600, 900)
	scene.name = "WarmGuildhallBackdrop"
	# Sign, burgundy crest, and live company name.
	_skin(stage, "wood", 19, 13, 550, 141)
	_skin(stage, "red", 33, 33, 97, 122)
	_picture(stage, CREST, 43, 41, 76, 88)
	_print(stage, "MONEY MERCS", 145, 43, 405, 64, 49, GOLD_LETTER)
	_print(stage, "THE CONTRACTOR'S GUILD", 157, 107, 387, 28, 22, CREAM)
	# The three brass-framed treasury plaques use the actual save state.
	_skin(stage, "wood", 766, 57, 250, 94)
	_skin(stage, "wood", 1024, 57, 250, 94)
	_skin(stage, "wood", 1282, 57, 293, 94)
	_picture(stage, GOLD_ICON, 777, 79, 57, 54)
	_print(stage, "TREASURY  /  GOLD", 838, 70, 164, 24, 16, CREAM)
	gold_total = _print(stage, "0 G", 838, 94, 166, 48, 28, GOLD_LETTER)
	_picture(stage, GOLD_ICON, 1035, 80, 55, 54)
	_print(stage, "COMPANY VALUE", 1095, 70, 162, 24, 16, CREAM)
	net_total = _print(stage, "0 G", 1095, 94, 155, 48, 28, GOLD_LETTER)
	_picture(stage, CREST, 1297, 81, 57, 53)
	_print(stage, "EXPEDITIONS IN FIELD", 1358, 70, 204, 24, 16, CREAM)
	field_total = _print(stage, "0 / 1", 1358, 94, 185, 48, 28, GOLD_LETTER)
	# Strong asymmetrical wood framework, not desktop navigation widgets.
	_skin(stage, "wood", 21, 167, 298, 556)
	_print(stage, "THE GUILD'S RECORDS", 48, 180, 240, 25, 19, MUTED_GOLD)
	navigation = _region(stage, 30, 214, 279, 487)
	# Main board, paper face, separately pinned contract/warrant sheets.
	_skin(stage, "wood", 324, 167, 881, 562)
	_skin(stage, "paper", 335, 180, 859, 538)
	_print(stage, "❖    CONTRACTS & OPPORTUNITIES    ❖", 361, 191, 809, 40, 25, INK, HORIZONTAL_ALIGNMENT_CENTER)
	central_area = _region(stage, 349, 242, 828, 460)
	_skin(stage, "wood", 1200, 167, 380, 563)
	_skin(stage, "paper", 1212, 180, 354, 540)
	_print(stage, "CONTRACT DETAILS", 1235, 193, 301, 32, 22, INK, HORIZONTAL_ALIGNMENT_CENTER)
	dispatch_area = _region(stage, 1230, 237, 319, 469)
	# Tactile pieces of loose paperwork across the bottom of the desk.
	notes_area = _region(stage, 344, 736, 1217, 149)
	_skin(stage, "paper", 26, 739, 294, 143)
	_picture(stage, SEAL, 277, 722, 45, 45)
	_print(stage, "GUILD STATUS", 53, 757, 222, 30, 25, INK)
	_print(stage, "━━━━━━━━━━━━━━━━", 51, 783, 227, 12, 11, INK_SOFT)

func _scale_stage() -> void:
	if stage == null or not is_instance_valid(stage):
		return
	var window_size: Vector2 = size
	if window_size.x <= 0 or window_size.y <= 0:
		window_size = get_viewport_rect().size
	stage.scale = Vector2(window_size.x / 1600.0, window_size.y / 900.0)

func _region(parent: Node, x: float, y: float, w: float, h: float) -> Control:
	var r := Control.new()
	r.position = Vector2(x, y)
	r.size = Vector2(w, h)
	r.clip_contents = true
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(r)
	return r

func _picture(parent: Node, tex: Texture2D, x: float, y: float, w: float, h: float) -> TextureRect:
	var p := TextureRect.new()
	p.texture = tex
	p.position = Vector2(x, y)
	p.size = Vector2(w, h)
	p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p.stretch_mode = TextureRect.STRETCH_SCALE
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p

func _skin(parent: Node, style: String, x: float, y: float, w: float, h: float) -> NinePatchRect:
	var p := NinePatchRect.new()
	p.position = Vector2(x, y)
	p.size = Vector2(w, h)
	p.texture = PAPER if style == "paper" else (RED_WOOD if style == "red" else WOOD)
	p.patch_margin_left = 30 if style == "paper" else 19
	p.patch_margin_right = 30 if style == "paper" else 19
	p.patch_margin_top = 30 if style == "paper" else 19
	p.patch_margin_bottom = 30 if style == "paper" else 19
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p

func _print(parent: Node, value: String, x: float, y: float, w: float, h: float,
		font_size: int = 17, color: Color = INK,
		align_text: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, wrap_text: bool = false) -> Label:
	var t := Label.new()
	t.position = Vector2(x, y)
	t.size = Vector2(w, h)
	t.text = value
	t.add_theme_font_override("font", guild_book_font)
	t.add_theme_font_size_override("font_size", font_size)
	t.add_theme_color_override("font_color", color)
	t.horizontal_alignment = align_text
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap_text else TextServer.AUTOWRAP_OFF
	t.clip_text = not wrap_text
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t

func _touch(parent: Node, label: String, x: float, y: float, w: float, h: float,
		action: Callable, style: String = "wood", ink_color: Color = CREAM,
		font_size: int = 17, active: bool = true) -> Button:
	_skin(parent, style, x, y, w, h)
	var button := Button.new()
	button.position = Vector2(x + 6, y + 6)
	button.size = Vector2(w - 12, h - 12)
	button.text = label
	button.add_theme_font_override("font", guild_book_font)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", ink_color)
	button.add_theme_color_override("font_hover_color", Color("#fff5d4") if style != "paper" else INK)
	button.add_theme_color_override("font_pressed_color", ink_color)
	button.add_theme_color_override("font_disabled_color", ink_color.darkened(0.25))
	var empty := StyleBoxFlat.new()
	empty.bg_color = Color.TRANSPARENT
	empty.border_width_bottom = 0
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#ffcd83", 0.12)
	hover.border_color = MUTED_GOLD
	hover.border_width_bottom = 2
	hover.border_width_left = 2
	hover.border_width_right = 2
	hover.border_width_top = 2
	hover.corner_radius_top_left = 4
	hover.corner_radius_top_right = 4
	hover.corner_radius_bottom_left = 4
	hover.corner_radius_bottom_right = 4
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("disabled", empty)
	button.disabled = not active
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _refresh() -> void:
	if not is_instance_valid(stage):
		return
	gold_total.text = _money(game.gold)
	net_total.text = _money(game.wealth())
	field_total.text = "%d / %d" % [game.missions.size(), game.expedition_slots]
	_clear(navigation)
	_clear(central_area)
	_clear(dispatch_area)
	_clear(notes_area)
	_draw_navigation()
	_draw_status()
	match page:
		"hq": _overview()
		"harlow": _harlow_dossier()
		"guildwork": _guild_jobs()
		"finance": _financial_ledger()
		_:
			_other_page()
	_draw_note_cards()

func _draw_navigation() -> void:
	var entries: Array = [
		["hq", "⌂", "OVERVIEW", "Guild HQ"],
		["harlow", "⚒", "CONTRACTS", "Opportunities"],
		["roster", "♟", "MERCENARIES", "Your Crew"],
		["guildwork", "⚒", "GUILD WORK", "Safe Orders"],
		["market", "⚖", "TRADING POST", "Buy & Sell"],
		["finance", "◈", "LEDGER", "Finances"],
		["ledger", "▣", "CHRONICLE", "Reports"]
	]
	for i in range(entries.size()):
		var info: Array = entries[i]
		var id: String = str(info[0])
		var y: float = 2.0 + i * 69.0
		var active: bool = (page == id) or (page == "expeditions" and id == "harlow")
		if active:
			_skin(navigation, "red", 0, y, 278, 64)
		else:
			_skin(navigation, "wood", 0, y, 278, 64)
		_print(navigation, str(info[1]), 17, y + 6, 39, 39, 33, GOLD_LETTER, HORIZONTAL_ALIGNMENT_CENTER)
		_print(navigation, str(info[2]), 65, y + 7, 201, 26, 18, CREAM)
		_print(navigation, str(info[3]), 66, y + 34, 200, 20, 14, Color("#c8b29a"))
		var hit := Button.new()
		hit.flat = true
		hit.position = Vector2(0, y)
		hit.size = Vector2(278, 64)
		hit.focus_mode = Control.FOCUS_NONE
		hit.add_theme_stylebox_override("hover", _outline_style())
		hit.add_theme_stylebox_override("normal", _transparent_style())
		hit.pressed.connect(_nav_to.bind(id))
		navigation.add_child(hit)

func _transparent_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color.TRANSPARENT
	return s

func _outline_style() -> StyleBoxFlat:
	var s := _transparent_style()
	s.border_color = GOLD_LETTER
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.border_width_top = 2
	return s

func _draw_status() -> void:
	var employed: int = game.crew.size()
	# Previous status elements are tracked by putting live metrics in a dedicated container.
	if status_lines != null and is_instance_valid(status_lines):
		status_lines.queue_free()
	status_lines = _region(stage, 51, 797, 235, 77)
	_print(status_lines, "⚒  %d employed / %d ready" % [employed, game.free_crew()], 0, 0, 235, 25, 17, INK)
	_print(status_lines, "★  %d reputation" % game.reputation, 0, 26, 235, 24, 17, INK)
	_print(status_lines, "▣  %d / %d field teams" % [game.missions.size(), game.expedition_slots], 0, 51, 235, 23, 17, INK)


func _overview() -> void:
	_contract_tabs()
	# Central dossier: Harlow drawn in sepia ink, paper rather than a combat HUD.
	_print(central_area, "⚒", 343, 4, 50, 44, 39, INK)
	_print(central_area, "HARLOW MINES", 395, 1, 396, 47, 32, INK)
	var known: Dictionary = game.harlow.get("report", {})
	var state: String = "UNSURVEYED" if known.is_empty() else "SCOUTED THIS ROTATION"
	_print(central_area, "REGION 01  ·  %s" % state, 395, 46, 376, 22, 15, INK_SOFT)
	_picture(central_area, SEAL, 747, 3, 72, 72)
	_picture(central_area, MINE_INK, 343, 79, 474, 191)
	_print(central_area, "An old mine, opened up again. Reports of rich ore veins,", 347, 270, 469, 27, 17, INK)
	_print(central_area, "unstable tunnels, and dangerous creatures in the dark.", 347, 294, 469, 27, 17, INK)
	_print(central_area, "A profitable opportunity for a carefully equipped crew.", 347, 318, 469, 27, 17, INK)
	_ruling(central_area, 347, 354, 464)
	_print(central_area, "ESTIMATED YIELD", 348, 364, 168, 19, 14, INK_SOFT)
	_print(central_area, "RISK LEVEL", 540, 364, 136, 19, 14, INK_SOFT)
	_print(central_area, "ROTATION", 696, 364, 117, 19, 14, INK_SOFT)
	_print(central_area, "Moderate to high", 348, 384, 190, 29, 19, INK)
	_print(central_area, "Uncertain", 540, 384, 150, 29, 18, WINE)
	_print(central_area, _duration(game.harlow_rotation_remaining()), 696, 384, 123, 29, 18, INK)
	_touch(central_area, "INSPECT MINE & SEND SCOUT  →", 350, 418, 469, 43, _nav_to.bind("harlow"), "red", CREAM, 17)
	_draw_warrant(false)

func _contract_tabs() -> void:
	var sheets: Array = [
		["HARLOW MINES", "Region 01  •  Rotating mine", "harlow"],
		["THE OFFICE", "Your headquarters", "hq"],
		["OTHER SITES", "Additional contracts", "expeditions"],
		["THE CREW", "Hire & outfit", "roster"],
		["THE EXCHANGE", "Trade your resources", "market"],
		["THE JOURNAL", "Recorded expeditions", "ledger"]
	]
	for i in range(sheets.size()):
		var info: Array = sheets[i]
		var y: float = float(i * 72 + 5)
		_skin(central_area, "red" if i == 0 else "paper", 0, y, 321, 65)
		_print(central_area, str(i + 1).pad_zeros(2), 19, y + 7, 46, 39, 23, CREAM if i == 0 else INK_SOFT)
		_print(central_area, str(info[0]), 69, y + 6, 239, 27, 21, CREAM if i == 0 else INK)
		_print(central_area, str(info[1]), 69, y + 34, 242, 19, 13, Color("#ecd1b4") if i == 0 else INK_SOFT)
		var b := Button.new()
		b.position = Vector2(0, y)
		b.size = Vector2(321, 64)
		b.flat = true
		b.add_theme_stylebox_override("normal", _transparent_style())
		b.add_theme_stylebox_override("hover", _outline_style())
		b.pressed.connect(_nav_to.bind(str(info[2])))
		central_area.add_child(b)

func _ruling(parent: Node, x: float, y: float, w: float) -> void:
	var line := ColorRect.new()
	line.position = Vector2(x, y)
	line.size = Vector2(w, 1)
	line.color = Color("#b48c58", 0.75)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)

func _draw_warrant(detailed: bool) -> void:
	_print(dispatch_area, "✦", 5, 6, 43, 41, 33, INK)
	_print(dispatch_area, "Dispatch Plan", 48, 6, 266, 36, 25, INK)
	_print(dispatch_area, "Compare potential yield against risk", 13, 44, 295, 27, 16, INK, HORIZONTAL_ALIGNMENT_LEFT)
	_print(dispatch_area, "before sending anyone into danger.", 13, 69, 295, 24, 16, INK)
	_print(dispatch_area, "HOW HARD SHOULD THE CREW PUSH?", 14, 105, 285, 27, 17, INK)
	var dropdown := OptionButton.new()
	dropdown.position = Vector2(14, 137)
	dropdown.size = Vector2(285, 39)
	for option in MoneyMercsState.TACTICS:
		dropdown.add_item(str(option))
	dropdown.select(maxi(0, MoneyMercsState.TACTICS.find(tactic)))
	dropdown.add_theme_font_override("font", guild_book_font)
	dropdown.add_theme_font_size_override("font_size", 19)
	dropdown.add_theme_color_override("font_color", INK)
	var parchment_bg := StyleBoxFlat.new()
	parchment_bg.bg_color = Color("#ecd5ac")
	parchment_bg.border_color = Color("#af8e5a")
	parchment_bg.border_width_left = 2
	parchment_bg.border_width_bottom = 2
	parchment_bg.border_width_right = 2
	parchment_bg.border_width_top = 2
	dropdown.add_theme_stylebox_override("normal", parchment_bg)
	dropdown.item_selected.connect(func(idx: int) -> void:
		_set_tactic(str(MoneyMercsState.TACTICS[idx]))
	)
	dispatch_area.add_child(dropdown)
	_ruling(dispatch_area, 15, 188, 284)
	_print(dispatch_area, "EXPECTED OUTCOME", 15, 200, 275, 24, 17, INK_SOFT)
	var report: Dictionary = game.harlow.get("report", {})
	var miners: Array[String] = _selected_available()
	var stats: Dictionary = game.harlow_crew_stats(miners, tactic)
	var has_intel: bool = not report.is_empty()
	var outcome: String = ("Survey first for reliable odds" if not has_intel else "%d%% objective success" % int(round(float(stats["success"]) * 100.0)))
	_print(dispatch_area, outcome, 17, 228, 278, 35, 21, WINE if not has_intel else FOREST)
	if detailed:
		var fatal: float = 0.0
		for odds in (stats.get("death", {}) as Dictionary).values():
			fatal = maxf(fatal, float(odds))
		_print(dispatch_area, "Worst individual fatality risk: %d%%" % int(round(fatal*100.0)) if has_intel else "Threats are currently unconfirmed.", 15, 268, 287, 38, 15, INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	else:
		_print(dispatch_area, "Assign miners and guards to inspect", 15, 269, 287, 36, 16, INK)
		_print(dispatch_area, "capacity, risk, and expected costs.", 15, 301, 287, 31, 16, INK)
	_ruling(dispatch_area, 15, 342, 284)
	_print(dispatch_area, "MAXIMUM ORE VEINS", 15, 348, 280, 24, 15, INK_SOFT)
	_print(dispatch_area, "⚒  %d     /     %s" % [int(stats["capacity"]), _money(int(stats["wage"]))], 16, 374, 283, 27, 19, INK)
	var available: bool = (stats["miners"] > 0 and miners.size() <= 3 and game.gold >= int(stats["wage"]) and game.missions.size() < game.expedition_slots)
	var go := _touch(dispatch_area, "FUND EXPEDITION   →", 15, 412, 286, 43, _dispatch_harlow, "wood", GOLD_LETTER, 20, available)
	go.add_theme_color_override("font_color", Color("#cce6c2"))
	_print(dispatch_area, "Requires a miner. Casualties are permanent.", 15, 458, 290, 18, 13, WINE)

func _harlow_dossier() -> void:
	# The board switches to a real guild scouting sheet and a 3-person manifest.
	_print(central_area, "FIELD DOSSIER     /     HARLOW MINES", 8, 0, 812, 44, 28, INK)
	var report: Dictionary = game.harlow.get("report", {})
	_ruling(central_area, 9, 47, 801)
	_picture(central_area, MINE_INK, 6, 57, 391, 160)
	_print(central_area, "I. THE SURVEY", 410, 58, 375, 32, 22, INK)
	if report.is_empty():
		var waiting: bool = int(game.harlow.get("scout_finish", 0)) > 0
		_print(central_area, "Scout currently exploring." if waiting else "No field intelligence available.", 411, 98, 389, 29, 18, WINE, HORIZONTAL_ALIGNMENT_LEFT, true)
		var time: int = maxi(0, int(game.harlow.get("scout_finish", 0)) - int(Time.get_unix_time_from_system()))
		_print(central_area, "Returns in %s" % _duration(time) if waiting else "A scout always returns safely.", 411, 134, 379, 26, 16, INK)
		_touch(central_area, "DISPATCH SCOUT →" if not waiting else "SCOUT IN THE FIELD", 414, 175, 370, 39, _scout, "red", CREAM, 17, not waiting)
	else:
		_print(central_area, "At least %d veins of %s" % [int(report.get("minimum", 0)), str(MoneyMercsState.RESOURCE_NAMES.get(str(report.get("primary","copper")),"ore"))], 410, 98, 387, 30, 19, INK, HORIZONTAL_ALIGNMENT_LEFT, true)
		_print(central_area, "SPOTTED: %s" % str(report.get("creature","Unknown")), 410, 136, 392, 35, 18, WINE, HORIZONTAL_ALIGNMENT_LEFT, true)
		_print(central_area, "Rotation resets in %s" % _duration(game.harlow_rotation_remaining()), 411, 183, 366, 25, 16, INK_SOFT)
	var level: int = int(game.harlow.get("scout_level",1))
	var price: int = 200 if level == 1 else 650
	_print(central_area, "SCOUT TIER %d / 3" % level, 8, 224, 300, 28, 17, INK_SOFT)
	if level < 3:
		_touch(central_area, "TRAIN SCOUT   /   %d G" % price, 399, 222, 405, 37, _train_scout, "wood", GOLD_LETTER, 16,
			game.gold >= price and int(game.harlow.get("scout_finish",0)) == 0)
	_ruling(central_area, 8, 267, 801)
	_print(central_area, "II. SELECT FIELD CREW   •   MINERS EXTRACT / GUARDS PROTECT", 9, 274, 801, 33, 22, INK)
	var available_crew: Array[Dictionary] = game.available_guild_workers()
	var shown: int = 0
	for merc in available_crew:
		if str(merc.get("role","")) not in ["Miner","Guard"]:
			continue
		if shown >= 4:
			break
		var col: float = float(shown % 2)
		var row: float = float(shown / 2) if shown < 2 else 1.0
		var x: float = col * 401.0 + 10.0
		var y: float = 314.0 + row * 70.0
		_skin(central_area, "paper", x, y, 393, 65)
		_picture(central_area, MINER if str(merc["role"])=="Miner" else GUARD, x+9, y+7, 46, 49)
		_print(central_area, "%s · %s" % [str(merc["name"]), str(merc["role"])], x+62, y+7, 226, 26, 18, INK)
		_print(central_area, "HP %d%%  ·  Outfitted %d/2" % [int(merc.get("health",100)), _equipped_count(merc)], x+62, y+33, 223, 20, 14, INK_SOFT)
		_touch(central_area, "REMOVE" if selected_crew.has(str(merc["id"])) else "ADD", x+288, y+10, 93, 44, _toggle_crew.bind(not selected_crew.has(str(merc["id"])),str(merc["id"])), "red" if selected_crew.has(str(merc["id"])) else "wood", CREAM, 15)
		shown += 1
	if shown == 0:
		_print(central_area, "No ready miners or guards. Hire a new crew.", 15, 331, 750, 30, 20, WINE)
		_touch(central_area, "OPEN RECRUITMENT →", 17, 376, 379, 43, _open_recruitment, "red", CREAM, 17)
	elif shown < 3:
		_print(central_area, "Only ready contractors can be assigned.", 14, 395, 766, 25, 15, INK_SOFT)
	_draw_warrant(true)

func _guild_jobs() -> void:
	_legacy_board_title("GUILD WORK ORDERS", "Safe wages for struggling companies.")
	var y: float = 92
	_print(central_area, "When you've lost a crew, you still have a company to run.", 18, y, 771, 31, 19, INK)
	_print(central_area, "Work continues in the guildhall without risking anyone's life.", 18, y+33, 774, 26, 17, INK_SOFT)
	var eligible: bool = game.can_accept_guild_work() and game.missions.size() < game.expedition_slots
	_touch(central_area, "OFFICE PAPERWORK    ·    9 G / 3 MIN", 20, 207, 782, 61, _guild_work.bind(""), "wood", GOLD_LETTER, 20, eligible)
	var row := 0
	for person in game.available_guild_workers():
		if row >= 3:
			break
		_touch(central_area, "%s    ·    18 G / 2M 30S" % str(person["name"]).to_upper(), 20, 282 + row*61, 782, 58, _guild_work.bind(str(person["id"])), "wood", GOLD_LETTER, 19, eligible)
		row += 1
	_simple_right("GUILD WORK", ["No entry cost", "Zero injury or death risk", "Paid when workers return", "For companies below 120 G cash", "and 250 G estimated net worth."])
	_touch(dispatch_area, "RETURN TO CONTRACTS →", 12, 404, 294, 48, _nav_to.bind("harlow"), "red", CREAM, 17)

func _financial_ledger() -> void:
	_legacy_board_title("COMPANY LEDGER", "Every coin earned and every expense recorded.")
	var cells := [
		["GOLD ON HAND", _money(game.gold)],
		["COMPANY NET WORTH", _money(game.wealth())],
		["EQUIPMENT VALUE", _money(game.owned_equipment_value())],
		["GUILD DEBT", _money(game.relief_debt)],
		["REPUTATION", str(game.reputation)],
		["ACTIVE OPERATIONS", "%d / %d" % [game.missions.size(),game.expedition_slots]]
	]
	for i in range(cells.size()):
		var x: float = 14 + float(i % 2) * 401.0
		var y: float = 90 + float(i / 2) * 114.0
		_skin(central_area,"paper",x,y,393,103)
		_print(central_area,str(cells[i][0]),x+21,y+15,348,27,17,INK_SOFT)
		_print(central_area,str(cells[i][1]),x+21,y+43,348,51,30,INK)
	_simple_right("TREASURY NOTES", ["Gold is the principal currency.", "Rare items have appraised values,", "but only coins can pay wages.", "Money bags and physical vaults", "remain a future milestone."])

func _legacy_board_title(title: String, subtitle: String) -> void:
	_print(central_area, title, 15, 8, 784, 48, 29, INK)
	_print(central_area, subtitle, 15, 53, 781, 26, 17, INK_SOFT)
	_ruling(central_area, 15, 85, 795)

func _other_page() -> void:
	# Preserve every existing v0.5 action rather than replacing working systems
	# with pictures. A raised leather ledger sits on the parchment board.
	_print(central_area,"THE GUILD'S BOOKS",10,0,806,35,27,INK)
	var darker := PanelContainer.new()
	darker.position = Vector2(9,43)
	darker.size = Vector2(808,404)
	darker.add_theme_stylebox_override("panel",_style(Color("#291f1b"),Color("#a57a4a"),5,12))
	central_area.add_child(darker)
	content_host = darker
	match page:
		"roster": super._draw_roster()
		"market": super._draw_market()
		"expeditions": super._draw_contracts()
		"ledger": super._draw_journal()
		_: super._draw_office()
	_simple_right("QUARTERMASTER", ["Manage your accounts,", "inspect equipment,", "review contracts and", "send crews on guild business."])
	_touch(dispatch_area,"OPEN HARLOW MINES  →",13,408,294,44,_nav_to.bind("harlow"),"wood",GOLD_LETTER,17)

func _simple_right(heading: String, lines: Array) -> void:
	_print(dispatch_area,heading,17,18,286,43,25,INK)
	_ruling(dispatch_area,18,73,281)
	for i in range(lines.size()):
		_print(dispatch_area,str(lines[i]),19,92+i*38,283,35,17,INK,HORIZONTAL_ALIGNMENT_LEFT,true)

func _draw_note_cards() -> void:
	# These are actual links, not painted mockup buttons.
	var note_titles: Array = [
		["GUILD WORK ORDERS", "Reliable wages · Lower risk", "VIEW WORK ORDERS  →", "guildwork"],
		["RECENT REPORTS", "Review expedition outcomes", "OPEN CHRONICLE  →", "ledger"],
		["MERCENARIES", "%d employed / %d ready" % [game.crew.size(),game.free_crew()], "MANAGE CREW  →", "roster"]
	]
	for i in range(3):
		var n: Array = note_titles[i]
		var x: float = float(i)*407.0
		_skin(notes_area,"paper",x,0,396,147)
		_print(notes_area,str(n[0]),x+24,13,355,30,21,INK)
		_print(notes_area,str(n[1]),x+24,45,355,23,15,INK_SOFT)
		if i == 1 and not game.reports.is_empty():
			var report: Dictionary = game.reports[0]
			_print(notes_area,"%s  ·  %s" % [str(report.get("region","Unknown")),("Successful" if bool(report.get("won",false)) else "Costly return")],x+24,68,348,23,15,INK)
		elif i == 0:
			_print(notes_area,"Safe contracts available to the needy",x+24,69,343,21,14,INK)
		elif i == 2:
			_print(notes_area,"Hire, outfit and assign your employees",x+24,69,345,21,14,INK)
		_touch(notes_area,str(n[2]),x+72,98,250,38,_nav_to.bind(str(n[3])),"wood",GOLD_LETTER,16)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var destinations: Array[String] = ["hq","harlow","roster","guildwork","market","finance","ledger"]
		var index: int = int(event.keycode) - int(KEY_1)
		if index >= 0 and index < destinations.size():
			_nav_to(destinations[index])
