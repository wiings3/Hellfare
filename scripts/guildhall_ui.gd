extends "res://scripts/ledger_ui.gd"
## Money Mercs: Guildmaster's Desk (original wood/parchment UI).
## The artwork is separate from real Godot controls; all values and actions are live.
## 1600x900 authoring canvas, scaled to the current viewport without clipping.

const ROOM: Texture2D = preload("res://assets/ui/painted/guildhall_background.webp")
const PAPER: Texture2D = preload("res://assets/ui/painted/desk_note.webp")
const WOOD: Texture2D = preload("res://assets/ui/painted/navigation_plaque.webp")
const RED_WOOD: Texture2D = preload("res://assets/ui/painted/navigation_plaque.webp")
const SEAL: Texture2D = preload("res://assets/ui/painted/wax_seal.webp")
const MINE_INK: Texture2D = preload("res://assets/ui/painted/harlow_engraving.webp")

const GUILD_SIGN: Texture2D = preload("res://assets/ui/painted/guild_sign.webp")
const TREASURY: Texture2D = preload("res://assets/ui/painted/treasury_plaque.webp")
const BOARD: Texture2D = preload("res://assets/ui/painted/contracts_board.webp")
const CONTRACT_SLIP: Texture2D = preload("res://assets/ui/painted/contract_slip.webp")
const DISPATCH: Texture2D = preload("res://assets/ui/painted/dispatch_panel.webp")

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
var guild_display_font: SystemFont
var status_lines: Control
var board_heading: Label
var details_heading: Label

func _ready() -> void:
	page = "hq"
	super._ready()

func _build_shell() -> void:
	guild_book_font = SystemFont.new()
	guild_book_font.font_names = PackedStringArray(["Book Antiqua", "Palatino Linotype", "Georgia", "Noto Serif", "Liberation Serif"])
	guild_display_font = SystemFont.new()
	guild_display_font.font_names = PackedStringArray(["Cinzel", "Trajan Pro", "Copperplate Gothic", "Baskerville", "Palatino Linotype", "Georgia", "Noto Serif"])
	var letterbox := ColorRect.new()
	letterbox.color = Color("#21140e")
	letterbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	letterbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(letterbox)
	stage = Control.new()
	stage.name = "GuildmasterDesk"
	stage.position = Vector2.ZERO
	stage.size = Vector2(1600, 900)
	stage.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(stage)
	resized.connect(_scale_stage)
	_scale_stage()

	var scene: NinePatchRect = _picture(stage, ROOM, 0, 0, 1600, 900)
	scene.name = "WarmGuildhallBackdrop"
	# Hand-painted UI elements supplied as individual raster textures.
	# Text and click zones remain live Godot controls.
	_picture(stage, GUILD_SIGN, 17, 8, 633, 153)
	_picture(stage, TREASURY, 761, 52, 261, 99)
	_picture(stage, TREASURY, 1019, 52, 261, 99)
	_picture(stage, TREASURY, 1278, 52, 299, 99)
	_print(stage, "TREASURY  /  GOLD", 846, 70, 163, 24, 13, CREAM)
	gold_total = _print(stage, "0 G", 842, 98, 164, 39, 26, GOLD_LETTER)
	_print(stage, "COMPANY VALUE", 1101, 70, 156, 24, 13, CREAM)
	net_total = _print(stage, "0 G", 1098, 98, 161, 39, 26, GOLD_LETTER)
	_print(stage, "EXPEDITIONS IN FIELD", 1369, 70, 187, 24, 13, CREAM)
	field_total = _print(stage, "0 / 1", 1364, 98, 194, 39, 26, GOLD_LETTER)
	header_gold = gold_total
	header_wealth = net_total
	header_jobs = field_total
	notice = _print(stage, "Guild records updated.", 604, 156, 510, 18, 12, GOLD_LETTER, HORIZONTAL_ALIGNMENT_CENTER)
	# Artwork occupies the physical framework; real controls occupy its
	# readable interior. No procedural drawing is used for the art.
	_picture(stage, DISPATCH, 15, 166, 306, 572)
	navigation = _region(stage, 30, 248, 279, 476)
	_picture(stage, BOARD, 323, 165, 886, 568)
	board_heading = _print(stage, "CONTRACTS", 535, 235, 231, 29, 18, INK, HORIZONTAL_ALIGNMENT_CENTER)
	central_area = _region(stage, 350, 262, 825, 445)
	content_host = central_area
	_picture(stage, DISPATCH, 1200, 168, 380, 566)
	details_heading = _print(stage, "DISPATCH PLAN", 1262, 240, 249, 30, 17, INK, HORIZONTAL_ALIGNMENT_CENTER)
	dispatch_area = _region(stage, 1244, 258, 294, 455)
	# Loose desk notes and the wax-sealed guild status note.
	notes_area = _region(stage, 345, 737, 1214, 151)
	_picture(stage, PAPER, 26, 737, 294, 152)
	_picture(stage, SEAL, 278, 725, 40, 40)
	_print(stage, "GUILD STATUS", 51, 757, 222, 30, 21, INK)

func _scale_stage() -> void:
	if stage == null or not is_instance_valid(stage):
		return
	var window_size: Vector2 = size
	if window_size.x <= 0 or window_size.y <= 0:
		window_size = get_viewport_rect().size
	# Keep font and artwork proportions intact on 16:10 and ultrawide monitors.
	# Independent X/Y scaling squeezed serif letters at the default 1440x900 size.
	var factor: float = minf(window_size.x / 1600.0, window_size.y / 900.0)
	stage.scale = Vector2(factor, factor)
	stage.position = (window_size - Vector2(1600.0, 900.0) * factor) * 0.5

func _region(parent: Node, x: float, y: float, w: float, h: float) -> Control:
	var r := Control.new()
	r.position = Vector2(x, y)
	r.size = Vector2(w, h)
	r.clip_contents = true
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(r)
	return r

func _picture(parent: Node, tex: Texture2D, x: float, y: float, w: float, h: float) -> NinePatchRect:
	# Zero-patch NinePatchRect guarantees the art fits its exact bounds.
	# TextureRect on GL Compatibility previously drew SVGs at native size.
	var p := NinePatchRect.new()
	p.texture = tex
	p.position = Vector2(x, y)
	p.size = Vector2(w, h)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p

func _skin(parent: Node, style: String, x: float, y: float, w: float, h: float) -> NinePatchRect:
	# Nine-slicing the generated images preserves painted corners.
	var p := NinePatchRect.new()
	p.position = Vector2(x, y)
	p.size = Vector2(w, h)
	p.texture = PAPER if style == "paper" else WOOD
	p.patch_margin_left = 18
	p.patch_margin_right = 18
	p.patch_margin_top = 12
	p.patch_margin_bottom = 12
	if style == "red":
		p.modulate = Color(1.0, 0.72, 0.69, 1.0)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p

# Measure the actual loaded font, not estimated character counts.
# Automatically reduce oversized titles, prices and labels to fit their plaques.
func _fitted_text_size(value: String, font: Font, requested: int,
		w: float, h: float, wrap_text: bool = false) -> int:
	var candidate: int = maxi(11, requested)
	var usable_width: float = maxf(10.0, w - 9.0)
	var usable_height: float = maxf(10.0, h - 3.0)
	while candidate > 11:
		var measured: Vector2 = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, candidate)
		if not wrap_text:
			if measured.x <= usable_width and font.get_height(candidate) <= usable_height:
				break
		else:
			var lines: int = 0
			for paragraph in value.split("\n", true):
				var current := ""
				for word in paragraph.split(" ", false):
					var next_word: String = word if current.is_empty() else current + " " + word
					if not current.is_empty() and font.get_string_size(next_word, HORIZONTAL_ALIGNMENT_LEFT, -1.0, candidate).x > usable_width:
						lines += 1
						current = word
					else:
						current = next_word
				lines += 1
			if float(lines) * font.get_height(candidate) <= usable_height:
				break
		candidate -= 1
	return candidate

func _print(parent: Node, value: String, x: float, y: float, w: float, h: float,
		font_size: int = 17, color: Color = INK,
		align_text: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, wrap_text: bool = false) -> Label:
	var label := Label.new()
	label.position = Vector2(x, y)
	label.size = Vector2(w, h)
	label.text = value
	var font: Font = guild_display_font if font_size >= 22 or (value == value.to_upper() and font_size >= 17) else guild_book_font
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", _fitted_text_size(value, font, font_size, w, h, wrap_text))
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = align_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap_text else TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _touch(parent: Node, label: String, x: float, y: float, w: float, h: float,
		action: Callable, style: String = "wood", ink_color: Color = CREAM,
		font_size: int = 17, active: bool = true) -> Button:
	_skin(parent, style, x, y, w, h)
	var button := Button.new()
	# The medallion occupies the left quarter of the painted button.
	button.position = Vector2(x + 12, y + 6)
	button.size = Vector2(w - 24, h - 12)
	button.text = label
	button.add_theme_font_override("font", guild_display_font)
	button.add_theme_font_size_override("font_size",
		_fitted_text_size(label, guild_display_font, font_size, button.size.x - 9.0, button.size.y - 3.0))
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
	var headings: Dictionary = {
		"hq": "CONTRACTS", "harlow": "HARLOW MINES",
		"roster": "MERCENARIES", "guildwork": "GUILD WORK",
		"market": "TRADING POST", "finance": "LEDGER",
		"ledger": "CHRONICLE", "expeditions": "REGIONS"
	}
	board_heading.text = str(headings.get(page, "GUILD RECORDS"))
	details_heading.text = "DISPATCH PLAN" if page in ["hq", "harlow"] else "GUILDMASTER'S NOTES"
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
		_print(navigation, str(info[2]), 72, y + 12, 190, 25, 16, CREAM)
		_print(navigation, str(info[3]), 73, y + 36, 188, 17, 12, Color("#e3cba8"))
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
	status_lines = _region(stage, 51, 787, 232, 64)
	_print(status_lines, "%d EMPLOYED   /   %d READY" % [employed, game.free_crew()], 0, 0, 224, 20, 14, INK)
	_print(status_lines, "REPUTATION   %d" % game.reputation, 0, 21, 224, 20, 14, INK)
	_print(status_lines, "FIELD TEAMS   %d / %d" % [game.missions.size(), game.expedition_slots], 0, 42, 224, 20, 14, INK)


func _overview() -> void:
	_contract_tabs()
	# Central dossier: Harlow drawn in sepia ink, paper rather than a combat HUD.
	var known: Dictionary = game.harlow.get("report", {})
	var state: String = "UNSURVEYED" if known.is_empty() else "SCOUTED THIS ROTATION"
	_print(central_area, "REGION 01  ·  %s" % state, 398, 53, 365, 20, 13, INK_SOFT)
	_picture(central_area, SEAL, 756, 8, 50, 50)
	_picture(central_area, MINE_INK, 343, 70, 470, 170)
	_print(central_area, "An old mine reopened for contract work. Rich ore lies", 351, 243, 457, 25, 16, INK)
	_print(central_area, "beyond unstable tunnels and dangerous creatures.", 351, 267, 457, 25, 16, INK)
	_print(central_area, "A prepared crew might turn the claim into profit.", 351, 291, 457, 25, 16, INK)
	_ruling(central_area, 347, 323, 464)
	_print(central_area, "POTENTIAL YIELD", 353, 326, 171, 22, 13, INK_SOFT)
	_print(central_area, "RISK", 550, 326, 122, 22, 13, INK_SOFT)
	_print(central_area, "ROTATION ENDS", 685, 326, 116, 22, 13, INK_SOFT)
	_print(central_area, "Ore deposits", 353, 350, 176, 25, 17, INK)
	_print(central_area, "Unknown", 550, 350, 135, 25, 17, WINE)
	_print(central_area, _duration(game.harlow_rotation_remaining()), 685, 350, 115, 25, 16, INK)
	_touch(central_area, "OPEN HARLOW DOSSIER   →", 351, 386, 460, 42, _nav_to.bind("harlow"), "red", CREAM, 16)
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
		_print(central_area, str(i + 1).pad_zeros(2), 22, y + 13, 37, 32, 19, CREAM if i == 0 else INK_SOFT)
		_print(central_area, str(info[0]), 73, y + 12, 226, 24, 17, CREAM if i == 0 else INK)
		_print(central_area, str(info[1]), 74, y + 35, 219, 17, 12, Color("#ecd1b4") if i == 0 else INK_SOFT)
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
	_print(dispatch_area, "Compare yield against risk before", 20, 17, 274, 27, 16, INK)
	_print(dispatch_area, "sending anyone into danger.", 20, 40, 274, 24, 16, INK)
	_print(dispatch_area, "STANDING ORDERS", 20, 80, 277, 25, 17, INK)
	var dropdown := OptionButton.new()
	dropdown.position = Vector2(17, 110)
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
	_ruling(dispatch_area, 15, 163, 284)
	_print(dispatch_area, "EXPECTED OUTCOME", 17, 171, 275, 24, 17, INK_SOFT)
	var report: Dictionary = game.harlow.get("report", {})
	var miners: Array[String] = _selected_available()
	var stats: Dictionary = game.harlow_crew_stats(miners, tactic)
	var has_intel: bool = not report.is_empty()
	var outcome: String = ("Survey first for reliable odds" if not has_intel else "%d%% objective success" % int(round(float(stats["success"]) * 100.0)))
	_print(dispatch_area, outcome, 18, 200, 278, 35, 21, WINE if not has_intel else FOREST)
	if detailed:
		var fatal: float = 0.0
		for odds in (stats.get("death", {}) as Dictionary).values():
			fatal = maxf(fatal, float(odds))
		_print(dispatch_area, "Worst individual fatality risk: %d%%" % int(round(fatal*100.0)) if has_intel else "Threats are currently unconfirmed.", 18, 237, 278, 38, 15, INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	else:
		_print(dispatch_area, "Assign miners and guards to inspect", 18, 237, 278, 36, 16, INK)
		_print(dispatch_area, "capacity, risk, and expected costs.", 18, 267, 278, 31, 16, INK)
	_ruling(dispatch_area, 15, 306, 284)
	_print(dispatch_area, "CAPACITY   /   COST", 18, 316, 267, 24, 15, INK_SOFT)
	_print(dispatch_area, "⚒  %d     /     %s" % [int(stats["capacity"]), _money(int(stats["wage"]))], 18, 343, 276, 27, 19, INK)
	var deposits_remaining: int = 0
	for ore in (game.harlow.get("deposits", {}) as Dictionary).values():
		deposits_remaining += int(ore)
	var available: bool = (stats["miners"] > 0 and miners.size() <= 3 and game.gold >= int(stats["wage"]) and deposits_remaining > 0 and game.missions.size() < game.expedition_slots)
	var go := _touch(dispatch_area, "FUND EXPEDITION", 15, 401, 286, 43, _dispatch_harlow, "wood", GOLD_LETTER, 17, available)
	go.add_theme_color_override("font_color", Color("#cce6c2"))
	_print(dispatch_area, "Mercenary death is permanent.", 20, 373, 271, 18, 13, WINE)

func _harlow_dossier() -> void:
	# The board switches to a real guild scouting sheet and a 3-person manifest.
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
		var y: float = 310.0 + row * 61.0
		_skin(central_area, "paper", x, y, 393, 58)
		_picture(central_area, MINER if str(merc["role"])=="Miner" else GUARD, x+9, y+7, 44, 44)
		_print(central_area, "%s · %s" % [str(merc["name"]), str(merc["role"])], x+61, y+5, 224, 24, 16, INK)
		_print(central_area, "HP %d%%  ·  Outfitted %d/2" % [int(merc.get("health",100)), _equipped_count(merc)], x+61, y+31, 225, 18, 13, INK_SOFT)
		_touch(central_area, "REMOVE" if selected_crew.has(str(merc["id"])) else "ADD", x+289, y+9, 92, 41, _toggle_crew.bind(not selected_crew.has(str(merc["id"])),str(merc["id"])), "red" if selected_crew.has(str(merc["id"])) else "wood", CREAM, 14)
		shown += 1
	if shown == 0:
		_print(central_area, "No ready miners or guards. Hire a new crew.", 15, 331, 750, 30, 20, WINE)
		_touch(central_area, "OPEN RECRUITMENT →", 17, 376, 379, 43, _open_recruitment, "red", CREAM, 17)
	elif shown < 3:
		_print(central_area, "Only ready contractors can be assigned.", 14, 395, 766, 25, 15, INK_SOFT)
	_draw_warrant(true)

func _guild_jobs() -> void:
	_print(central_area, "Guaranteed wages for struggling companies.", 15, 9, 785, 32, 18, INK_SOFT)
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
	_print(central_area, "Every coin earned and every expense recorded.", 15, 9, 785, 32, 18, INK_SOFT)
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
	match page:
		"roster": _parchment_roster()
		"market": _parchment_market()
		"expeditions": _parchment_sites()
		"ledger": _parchment_chronicle()
		_: _parchment_roster()
	_simple_right("THE QUARTERMASTER", [
		"Your guild is a business.",
		"Train, equip and pay your people.",
		"Treat every operation like an",
		"investment—not an adventure.",
		"Even a fine sword is only useful",
		"when it earns its keep."
	])
	_touch(dispatch_area,"OPEN HARLOW MINES  →",13,408,294,44,_nav_to.bind("harlow"),"wood",GOLD_LETTER,17)

func _paper_scroll(y: float = 91.0) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(12, y)
	scroll.size = Vector2(805, 446 - y)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	central_area.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",8)
	scroll.add_child(list)
	return list

func _record(list: Node, height: int = 85) -> Control:
	# Reusable painted parchment backing, cropped from generated note art.
	# Text and buttons are still real controls.
	var outer := Control.new()
	outer.custom_minimum_size = Vector2(790, height)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_child(outer)
	var crop := AtlasTexture.new()
	crop.atlas = PAPER
	crop.region = Rect2(35, 35, 449, 176)
	var painted := NinePatchRect.new()
	painted.texture = crop
	painted.size = Vector2(790, height)
	painted.patch_margin_left = 14
	painted.patch_margin_right = 14
	painted.patch_margin_top = 14
	painted.patch_margin_bottom = 14
	painted.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(painted)
	var rect := Control.new()
	rect.size = Vector2(790, height)
	rect.mouse_filter = Control.MOUSE_FILTER_PASS
	outer.add_child(rect)
	return rect

func _parchment_roster() -> void:
	var tabs: Array = [["employed","UNDER CONTRACT"],["recruits","RECRUITMENT"],["armory","THE ARMORY"]]
	for i in range(tabs.size()):
		var info: Array = tabs[i]
		_touch(central_area,str(info[1]), 11+i*268,14,257,42,
			_set_roster_tab.bind(str(info[0])),
			"red" if roster_tab == str(info[0]) else "wood",CREAM,16)
	var list: VBoxContainer = _paper_scroll(68)
	if roster_tab == "armory":
		_parchment_armory(list)
	elif roster_tab == "recruits":
		for candidate in game.recruitment_board():
			var card: Control = _record(list,102)
			_picture(card, MINER if str(candidate["role"])=="Miner" else GUARD,9,12,72,78)
			_print(card,str(candidate["name"]),90,6,400,31,24,INK)
			_print(card,"%s  ·  Skill %d  ·  %s" % [
				str(candidate["role"]),int(candidate["skill"]),str(candidate.get("title","Contractor"))],91,36,420,25,16,INK_SOFT)
			_print(card,"Signing fee: %s" % _money(int(candidate["hire"])),91,66,300,24,17,INK)
			_touch(card,"HIRE  →",636,25,144,48,_hire.bind(str(candidate["id"])),"red",CREAM,17,game.gold>=int(candidate["hire"]))
	else:
		for merc in game.crew:
			var card: Control = _record(list,116)
			_picture(card, MINER if str(merc["role"])=="Miner" else GUARD,9,12,78,88)
			_print(card,str(merc["name"]),102,7,380,32,25,INK)
			_print(card,"%s  ·  %s" % [str(merc["role"]),str(merc.get("title","Contractor"))],103,36,409,24,16,INK_SOFT)
			_print(card,"Health %d%%     Experience %d     Gear %d/2" % [
				int(merc.get("health",100)),int(merc.get("xp",0)),_equipped_count(merc)],103,66,510,25,16,INK)
			_touch(card,"OUTFIT",633,12,148,42,_outfit.bind(str(merc["id"])),"wood",GOLD_LETTER,16)
			_touch(card,"TERMS",633,61,148,41,_terms.bind(str(merc["id"])),"red",CREAM,16)
			if int(merc.get("health",100))<100:
				_touch(card,"TREAT",477,65,141,34,_heal.bind(str(merc["id"])),"wood",GOLD_LETTER,15)
	if list.get_child_count()==0:
		var empty: Control = _record(list,90)
		_print(empty,"No contractors on this page.",19,18,742,45,19,INK)

func _parchment_armory(list: VBoxContainer) -> void:
	var intro: Control = _record(list,73)
	_print(intro,"THE QUARTERMASTER'S ARMORY",18,8,700,35,22,INK)
	_print(intro,"Every pickaxe and sword is a company asset.",19,39,727,24,16,INK_SOFT)
	var crew: Array = game.crew
	for i in range(mini(crew.size(),4)):
		var merc: Dictionary = crew[i]
		var selector: Control = _record(list,65)
		_print(selector,"%s  ·  %s" % [str(merc["name"]),str(merc["role"])],18,8,420,31,20,INK)
		var worn: Dictionary = merc.get("equipment",{})
		_print(selector,"%s | %s" % [_equipment_name(worn.get("tool",{})),_equipment_name(worn.get("armor",{}))],19,33,530,24,15,INK_SOFT)
		_touch(selector,"SELECT" if selected_merc!=str(merc["id"]) else "SELECTED",623,7,162,49,
			_choose_worker.bind(str(merc["id"])),"red" if selected_merc==str(merc["id"]) else "wood",CREAM,15)
	if selected_merc.is_empty() and not crew.is_empty():
		selected_merc = str(crew[0]["id"])
	var owner: Dictionary = game.merc_by_id(selected_merc)
	for item in game.equipment_inventory:
		var key: String = str(item["key"])
		var definition: Dictionary = game.item_definition(key)
		var card: Control = _record(list,70)
		_print(card,"%s  ·  STORED" % str(definition["name"]),20,5,532,30,20,INK)
		_print(card,"Resale value: ~%d G" % int(float(definition["cost"])*0.65),20,35,444,25,15,INK_SOFT)
		_touch(card,"EQUIP",468,12,145,46,_equip.bind(selected_merc,str(item["uid"])),"wood",GOLD_LETTER,16,
			not owner.is_empty() and MercsV05.validate_role(key,owner) and game.is_available(owner))
		_touch(card,"SELL",628,12,156,46,_sell_equipment.bind(str(item["uid"])),"red",CREAM,16)
	var heading: Control = _record(list,55)
	_print(heading,"CATALOGUE  /  PURCHASE EQUIPMENT",17,9,742,37,21,INK)
	for key in MercsV05.ITEMS:
		var definition: Dictionary = MercsV05.ITEMS[key]
		var stock: Control = _record(list,66)
		_print(stock,"%s    ·   %s" % [str(definition["name"]),str(definition["role"])],16,8,536,29,19,INK)
		_print(stock,"Extraction %d   Combat %d   Protection %d" % [
			int(definition["mining"]),int(definition["guard"]),int(definition["protection"])],17,36,550,22,15,INK_SOFT)
		_touch(stock,"BUY %d G" % int(definition["cost"]),622,9,163,46,
			_buy_equipment.bind(str(key)),"wood",GOLD_LETTER,16,game.gold>=int(definition["cost"]))

func _parchment_market() -> void:
	_print(central_area,"MERCHANT PRICES  ·  COMPANY INVENTORY",18,8,772,26,14,INK_SOFT)
	var list: VBoxContainer = _paper_scroll(51)
	for item_id in MoneyMercsState.RESOURCE_ORDER:
		var id: String = str(item_id)
		var quantity: int = int(game.resources.get(id,0))
		var record: Control = _record(list,82)
		var res_icon: Texture2D = RESOURCE_ICONS.get(id, GOLD_ICON)
		_picture(record,res_icon,11,9,59,62)
		_print(record,str(MoneyMercsState.RESOURCE_NAMES[id]),83,7,364,30,22,INK)
		_print(record,"%d STORED   ·   SELL %d G   ·   BUY %d G" % [
			quantity,game.sell_price(id),game.buy_price(id)],83,39,457,25,15,INK_SOFT)
		_touch(record,"SELL",505,16,81,48,_trade.bind(id,false,1),"red",CREAM,16,quantity>0)
		_touch(record,"SELL ALL",597,16,93,48,_trade.bind(id,false,quantity),"wood",GOLD_LETTER,15,quantity>0)
		_touch(record,"BUY",700,16,86,48,_trade.bind(id,true,1),"wood",GOLD_LETTER,16,game.gold>=game.buy_price(id))

func _parchment_sites() -> void:
	_print(central_area,"These older sites still use the original expedition system.",13,8,780,26,17,INK_SOFT)
	var list: VBoxContainer = _paper_scroll(51)
	for region in MoneyMercsState.REGIONS:
		var contract: Control = _record(list,113)
		_print(contract,str(region["name"]),19,6,670,35,24,INK)
		_print(contract,str(region.get("tagline","Dangerous contract")),19,39,670,26,16,INK_SOFT)
		_print(contract,"Threat %d  ·  Cost %d G  ·  Required reputation %d" % [
			int(region["threat"]),int(region["supplies"]),int(region["rep"])],19,70,565,28,16,INK)
		_touch(contract,"DISPATCH →",611,53,176,48,_old_dispatch.bind(str(region["id"])),"red",CREAM,16,
			game.free_crew()>0 and game.reputation >= int(region["rep"]) and game.missions.size()<game.expedition_slots)

func _parchment_chronicle() -> void:
	_print(central_area,"Every earned coin and lost mercenary has a story.",12,8,781,28,17,INK_SOFT)
	var list: VBoxContainer = _paper_scroll(51)
	if game.reports.is_empty():
		var blank: Control = _record(list,85)
		_print(blank,"No expeditions have returned yet.",18,18,735,42,21,INK)
	for record in game.reports:
		var report: Dictionary = record
		var report_block: Control = _record(list,139)
		_print(report_block,str(report.get("region","Unknown Contract")),16,7,544,32,23,INK)
		_print(report_block,"SUCCESS" if bool(report.get("won",false)) else "COSTLY RETURN",598,7,179,31,16,FOREST if bool(report.get("won",false)) else WINE)
		_print(report_block,"Recovered: %s" % _loot_text(report.get("loot",{})),17,37,757,26,16,INK_SOFT)
		_print(report_block,"Found gold: %d G  ·  Mission cost: %d G" % [int(report.get("cash",0)),int(report.get("cost",0))],17,64,740,25,17,INK)
		var dead: Array = report.get("casualties",[])
		_print(report_block,"Losses: %s" % (", ".join(dead) if not dead.is_empty() else "None"),17,91,731,28,16,WINE if not dead.is_empty() else INK_SOFT)

func _simple_right(heading: String, lines: Array) -> void:
	_ruling(dispatch_area,18,26,281)
	for i in range(lines.size()):
		_print(dispatch_area,str(lines[i]),19,52+i*37,283,35,17,INK,HORIZONTAL_ALIGNMENT_LEFT,true)

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
		_print(notes_area,str(n[0]),x+27,15,344,27,19,INK)
		_print(notes_area,str(n[1]),x+27,46,343,22,14,INK_SOFT)
		if i == 1 and not game.reports.is_empty():
			var report: Dictionary = game.reports[0]
			_print(notes_area,"%s  ·  %s" % [str(report.get("region","Unknown")),("Successful" if bool(report.get("won",false)) else "Costly return")],x+24,68,348,23,15,INK)
		elif i == 0:
			_print(notes_area,"Safe contracts available to the needy",x+24,69,343,21,14,INK)
		elif i == 2:
			_print(notes_area,"Hire, outfit and assign your employees",x+24,69,345,21,14,INK)
		_touch(notes_area,str(n[2]),x+70,99,254,38,_nav_to.bind(str(n[3])),"wood",GOLD_LETTER,15)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var destinations: Array[String] = ["hq","harlow","roster","guildwork","market","finance","ledger"]
		var index: int = int(event.keycode) - int(KEY_1)
		if index >= 0 and index < destinations.size():
			_nav_to(destinations[index])
