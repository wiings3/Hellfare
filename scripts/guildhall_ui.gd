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
	# The environment fills any unused letterbox area; the desk controls
	# retain an undistorted 1600x900 layout at every desktop resolution.
	var hall := TextureRect.new()
	hall.name = "GuildhallRoom"
	hall.texture = ROOM
	hall.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hall.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hall.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hall)
	stage = Control.new()
	stage.name = "GuildmasterDesk"
	stage.position = Vector2.ZERO
	stage.size = Vector2(1600, 900)
	stage.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(stage)
	resized.connect(_scale_stage)
	_scale_stage()

	# These full illustrations are drawn in aspect-correct bounds. Their art
	# isn't nine-stretched into a different aspect ratio.
	_picture(stage, GUILD_SIGN, 30, 6, 555, 185)
	_picture(stage, TREASURY, 741, 70, 275, 77)
	_picture(stage, TREASURY, 1022, 70, 275, 77)
	_picture(stage, TREASURY, 1304, 70, 275, 77)
	_print(stage, "TREASURY", 819, 82, 182, 20, 15, CREAM)
	gold_total = _print(stage, "0 G", 819, 104, 183, 29, 23, GOLD_LETTER)
	_print(stage, "COMPANY VALUE", 1100, 82, 180, 20, 14, CREAM)
	net_total = _print(stage, "0 G", 1100, 104, 184, 29, 23, GOLD_LETTER)
	_print(stage, "IN THE FIELD", 1383, 82, 180, 20, 14, CREAM)
	field_total = _print(stage, "0 / 1", 1383, 104, 181, 29, 23, GOLD_LETTER)
	header_gold = gold_total
	header_wealth = net_total
	header_jobs = field_total

	# This notice is empty at rest. Updated text appears above the desk.
	notice = _print(stage, "", 763, 155, 382, 22, 14, GOLD_LETTER, HORIZONTAL_ALIGNMENT_CENTER)

	# Painted contract board rendered at its source aspect ratio (4:3).
	# Move functional content below the crest and physically inside the paper.
	_picture(stage, DISPATCH, -12, 177, 355, 532)
	navigation = _region(stage, 16, 270, 290, 435)
	_picture(stage, BOARD, 324, 154, 886, 665)
	board_heading = _print(stage, "CONTRACTS", 526, 255, 446, 34, 20, INK, HORIZONTAL_ALIGNMENT_CENTER)
	central_area = _region(stage, 349, 319, 829, 401)
	content_host = central_area

	# Dispatcher art is a 2:3 portrait. All its labels are constrained to
	# the parchment interior, clear of banners, the crest and bottom rail.
	_picture(stage, DISPATCH, 1209, 180, 363, 544)
	details_heading = _print(stage, "DISPATCH PLAN", 1278, 261, 228, 30, 17, INK, HORIZONTAL_ALIGNMENT_CENTER)
	dispatch_area = _region(stage, 1272, 303, 241, 355)

	# Desk notes are laid over the lower frame like physical loose papers.
	notes_area = _region(stage, 345, 752, 1216, 137)
	_picture(stage, PAPER, 24, 741, 293, 162)
	_picture(stage, SEAL, 286, 740, 36, 36)
	_print(stage, "GUILD STATUS", 50, 771, 233, 28, 20, INK)

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
	# Only the painted, repeatable *material* is nine-sliced. The gilded
	# medallion in the navigation art and the memo's button bar are excluded
	# so they cannot stretch across wide buttons or ledger cells.
	var atlas := AtlasTexture.new()
	if style == "paper":
		atlas.atlas = PAPER
		atlas.region = Rect2(48, 38, 431, 179)
	else:
		atlas.atlas = WOOD
		atlas.region = Rect2(130, 17, 285, 86)
	var p := NinePatchRect.new()
	p.position = Vector2(x, y)
	p.size = Vector2(w, h)
	p.texture = atlas
	p.patch_margin_left = 17
	p.patch_margin_right = 17
	p.patch_margin_top = 14
	p.patch_margin_bottom = 14
	if style == "red":
		p.modulate = Color(1.0, 0.67, 0.64, 1.0)
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
		["hq", "OVERVIEW", "Guild HQ"],
		["harlow", "CONTRACTS", "Opportunities"],
		["roster", "MERCENARIES", "Your Crew"],
		["guildwork", "GUILD WORK", "Safe Orders"],
		["market", "TRADING POST", "Buy & Sell"],
		["finance", "LEDGER", "Finances"],
		["ledger", "CHRONICLE", "Reports"]
	]
	for i in range(entries.size()):
		var info: Array = entries[i]
		var id: String = str(info[0])
		var y: float = float(i * 59 + 3)
		_skin(navigation, "red" if page == id else "wood", 0, y, 284, 54)
		_print(navigation, str(info[1]), 22, y + 7, 245, 23, 17, CREAM)
		_print(navigation, str(info[2]), 24, y + 31, 234, 16, 12, Color("#ead4b0"))
		var hit := Button.new()
		hit.position = Vector2(0, y)
		hit.size = Vector2(284, 54)
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.add_theme_stylebox_override("normal", _transparent_style())
		hit.add_theme_stylebox_override("hover", _outline_style())
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
	status_lines = _region(stage, 50, 805, 235, 70)
	_print(status_lines, "%d EMPLOYED   /   %d READY" % [employed, game.free_crew()], 0, 0, 224, 20, 14, INK)
	_print(status_lines, "REPUTATION   %d" % game.reputation, 0, 21, 224, 20, 14, INK)
	_print(status_lines, "FIELD TEAMS   %d / %d" % [game.missions.size(), game.expedition_slots], 0, 42, 224, 20, 14, INK)


func _overview() -> void:
	_contract_tabs()
	var known: Dictionary = game.harlow.get("report", {})
	_print(central_area, "REGION 01   /   %s" % ("UNSURVEYED" if known.is_empty() else "SURVEY COMPLETE"),
		386, 12, 380, 22, 14, INK_SOFT)
	_picture(central_area, SEAL, 766, 5, 39, 39)
	# Source engraving is 738x435. 335x198 is proportional.
	_picture(central_area, MINE_INK, 411, 45, 336, 198)
	_print(central_area, "Rich ore hides beyond unstable", 386, 243, 397, 22, 16, INK)
	_print(central_area, "tunnels and dangerous creatures.", 386, 266, 399, 22, 16, INK)
	_ruling(central_area, 382, 301, 414)
	_print(central_area, "YIELD", 386, 307, 136, 21, 13, INK_SOFT)
	_print(central_area, "RISK", 541, 307, 93, 21, 13, INK_SOFT)
	_print(central_area, "ROTATION", 658, 307, 136, 21, 13, INK_SOFT)
	_print(central_area, "Ore", 386, 330, 121, 24, 18, INK)
	_print(central_area, "Unknown", 541, 330, 100, 24, 17, WINE)
	_print(central_area, _duration(game.harlow_rotation_remaining()), 658, 330, 135, 24, 17, INK)
	_touch(central_area, "OPEN HARLOW DOSSIER   →",
		382, 365, 414, 33, _nav_to.bind("harlow"), "wood", GOLD_LETTER, 16)
	_draw_warrant(false)

func _contract_tabs() -> void:
	var sheets: Array = [
		["HARLOW MINES", "Rotating mining claim", "harlow"],
		["THE OFFICE", "Headquarters", "hq"],
		["OTHER SITES", "Additional contracts", "expeditions"],
		["THE CREW", "Hire and equip", "roster"],
		["THE EXCHANGE", "Trade resources", "market"],
		["THE JOURNAL", "Expedition reports", "ledger"]
	]
	for i in range(sheets.size()):
		var info: Array = sheets[i]
		var y: float = float(4 + i * 65)
		_skin(central_area, "red" if i == 0 else "paper", 0, y, 362, 59)
		_print(central_area, "%02d" % (i + 1), 15, y + 9, 42, 36, 19,
			CREAM if i == 0 else INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		_print(central_area, str(info[0]), 65, y + 7, 274, 24, 19, CREAM if i == 0 else INK)
		_print(central_area, str(info[1]), 66, y + 31, 273, 20, 13,
			Color("#eddab9") if i == 0 else INK_SOFT)
		var hit := Button.new()
		hit.position = Vector2(0, y)
		hit.size = Vector2(362, 59)
		hit.flat = true
		hit.add_theme_stylebox_override("normal", _transparent_style())
		hit.add_theme_stylebox_override("hover", _outline_style())
		hit.pressed.connect(_nav_to.bind(str(info[2])))
		central_area.add_child(hit)

func _ruling(parent: Node, x: float, y: float, w: float) -> void:
	var line := ColorRect.new()
	line.position = Vector2(x, y)
	line.size = Vector2(w, 1)
	line.color = Color("#b48c58", 0.75)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)

func _draw_warrant(detailed: bool) -> void:
	_print(dispatch_area, "Compare profit against risk", 8, 7, 224, 24, 15, INK)
	_print(dispatch_area, "before dispatching your crew.", 8, 28, 224, 24, 15, INK)
	_print(dispatch_area, "STANDING ORDERS", 9, 58, 220, 25, 16, INK_SOFT)
	var dropdown := OptionButton.new()
	dropdown.position = Vector2(8, 86)
	dropdown.size = Vector2(225, 37)
	for option in MoneyMercsState.TACTICS:
		dropdown.add_item(str(option))
	dropdown.select(maxi(0, MoneyMercsState.TACTICS.find(tactic)))
	dropdown.add_theme_font_override("font", guild_book_font)
	dropdown.add_theme_font_size_override("font_size", 16)
	dropdown.add_theme_color_override("font_color", INK)
	var parchment_bg := StyleBoxFlat.new()
	parchment_bg.bg_color = Color("#ead3a7")
	parchment_bg.border_color = Color("#ac8750")
	for side in ["left", "right", "top", "bottom"]:
		parchment_bg.set("border_width_" + side, 1)
	dropdown.add_theme_stylebox_override("normal", parchment_bg)
	dropdown.item_selected.connect(func(idx: int) -> void:
		_set_tactic(str(MoneyMercsState.TACTICS[idx]))
	)
	dispatch_area.add_child(dropdown)
	_ruling(dispatch_area, 9, 135, 223)
	_print(dispatch_area, "EXPECTED OUTCOME", 9, 144, 220, 21, 15, INK_SOFT)
	var report: Dictionary = game.harlow.get("report", {})
	var workers: Array[String] = _selected_available()
	var stats: Dictionary = game.harlow_crew_stats(workers, tactic)
	var has_intel: bool = not report.is_empty()
	var outcome: String = "Survey required for odds" if not has_intel else "%d%% success chance" % int(round(float(stats["success"]) * 100.0))
	_print(dispatch_area, outcome, 9, 169, 222, 30, 18,
		WINE if not has_intel else FOREST, HORIZONTAL_ALIGNMENT_LEFT, true)
	if detailed:
		var fatal: float = 0.0
		for odds in (stats.get("death", {}) as Dictionary).values():
			fatal = maxf(fatal, float(odds))
		_print(dispatch_area,
			"Highest fatality risk: %d%%" % int(round(fatal * 100.0)) if has_intel else "Unknown field threats",
			9, 207, 221, 25, 14, WINE, HORIZONTAL_ALIGNMENT_LEFT, true)
	else:
		_print(dispatch_area, "Choose miners and guards", 9, 206, 218, 23, 14, INK)
	_ruling(dispatch_area, 9, 239, 223)
	_print(dispatch_area, "CAPACITY   /   COST", 9, 247, 218, 20, 14, INK_SOFT)
	_print(dispatch_area, "%d veins     /     %s" % [
		int(stats["capacity"]), _money(int(stats["wage"]))], 9, 268, 224, 29, 18, INK)
	var deposits_remaining: int = 0
	for ore in (game.harlow.get("deposits", {}) as Dictionary).values():
		deposits_remaining += int(ore)
	var available: bool = (int(stats["miners"]) > 0 and workers.size() <= 3 and
		game.gold >= int(stats["wage"]) and deposits_remaining > 0 and
		game.missions.size() < game.expedition_slots)
	_print(dispatch_area, "Permanent death is possible.", 9, 295, 221, 20, 13, WINE)
	var go := _touch(dispatch_area, "FUND EXPEDITION", 8, 320, 225, 34,
		_dispatch_harlow, "wood", GOLD_LETTER, 16, available)
	go.add_theme_color_override("font_color", Color("#e9e1b1"))

func _harlow_dossier() -> void:
	var report: Dictionary = game.harlow.get("report", {})
	_picture(central_area, MINE_INK, 15, 30, 303, 179)
	_print(central_area, "I. THE SURVEY", 337, 10, 468, 31, 22, INK)
	if report.is_empty():
		var waiting: bool = int(game.harlow.get("scout_finish", 0)) > 0
		_print(central_area,
			"Scout exploring." if waiting else "No field intelligence.",
			338, 49, 451, 25, 17, WINE)
		var time: int = maxi(0, int(game.harlow.get("scout_finish", 0)) - int(Time.get_unix_time_from_system()))
		_print(central_area, "Returns in %s" % _duration(time) if waiting else "Scouting is always safe.",
			338, 82, 452, 25, 16, INK)
		_touch(central_area, "SEND SCOUT" if not waiting else "SCOUT IN FIELD",
			339, 145, 445, 38, _scout, "wood", GOLD_LETTER, 17, not waiting)
	else:
		_print(central_area, "At least %d veins of %s" % [
			int(report.get("minimum", 0)),
			str(MoneyMercsState.RESOURCE_NAMES.get(str(report.get("primary", "copper")), "ore"))],
			338, 49, 445, 30, 17, INK, HORIZONTAL_ALIGNMENT_LEFT, true)
		_print(central_area, "THREAT: %s" % str(report.get("creature", "Unknown")),
			338, 86, 446, 30, 16, WINE, HORIZONTAL_ALIGNMENT_LEFT, true)
		_print(central_area, "Rotation: %s remaining" % _duration(game.harlow_rotation_remaining()),
			338, 126, 446, 25, 15, INK_SOFT)
	var level: int = int(game.harlow.get("scout_level", 1))
	var price: int = 200 if level == 1 else 650
	_print(central_area, "SCOUT TIER %d / 3" % level, 20, 215, 267, 24, 16, INK_SOFT)
	if level < 3:
		_touch(central_area, "TRAIN SCOUT  /  %d G" % price, 357, 210, 432, 35,
			_train_scout, "wood", GOLD_LETTER, 16,
			game.gold >= price and int(game.harlow.get("scout_finish", 0)) == 0)
	_ruling(central_area, 15, 252, 783)
	_print(central_area, "II. ASSIGN MINERS AND GUARDS", 17, 257, 775, 26, 20, INK)
	var shown: int = 0
	for merc in game.available_guild_workers():
		if str(merc.get("role", "")) not in ["Miner", "Guard"]:
			continue
		if shown >= 4:
			break
		var col: int = shown % 2
		var row: int = shown / 2
		var x: float = 13.0 + float(col) * 401.0
		var y: float = 288.0 + float(row) * 57.0
		_skin(central_area, "paper", x, y, 393, 53)
		_picture(central_area, MINER if str(merc["role"]) == "Miner" else GUARD, x + 8, y + 7, 40, 40)
		_print(central_area, "%s  /  %s" % [str(merc["name"]), str(merc["role"])],
			x + 55, y + 4, 227, 23, 17, INK)
		_print(central_area, "HP %d%%  ·  Gear %d/2" % [
			int(merc.get("health", 100)), _equipped_count(merc)],
			x + 55, y + 29, 221, 16, 13, INK_SOFT)
		_touch(central_area, "REMOVE" if selected_crew.has(str(merc["id"])) else "ADD",
			x + 285, y + 8, 99, 37,
			_toggle_crew.bind(not selected_crew.has(str(merc["id"])), str(merc["id"])),
			"red" if selected_crew.has(str(merc["id"])) else "wood", CREAM, 14)
		shown += 1
	if shown == 0:
		_print(central_area, "No available crews. Recruit miners and guards.",
			17, 301, 765, 29, 18, WINE)
		_touch(central_area, "OPEN RECRUITMENT", 18, 350, 340, 36,
			_open_recruitment, "wood", GOLD_LETTER, 16)
	_draw_warrant(true)

func _guild_jobs() -> void:
	_print(central_area, "SAFE GUILD CONTRACTS", 17, 14, 770, 30, 23, INK)
	_print(central_area, "Guaranteed wages to rebuild after difficult expeditions.",
		18, 53, 776, 26, 17, INK_SOFT)
	_print(central_area, "No crew deaths, supply fees or equipment requirements.",
		18, 82, 776, 26, 16, INK)
	var eligible: bool = game.can_accept_guild_work() and game.missions.size() < game.expedition_slots
	_touch(central_area, "OFFICE PAPERWORK   ·   9 G   /   3 MIN",
		20, 132, 785, 53, _guild_work.bind(""), "wood", GOLD_LETTER, 18, eligible)
	var index: int = 0
	for person in game.available_guild_workers():
		if index >= 3:
			break
		_touch(central_area,
			"%s   ·   18 G   /   2M 30S" % str(person["name"]).to_upper(),
			20, 202 + index * 61, 785, 53,
			_guild_work.bind(str(person["id"])), "wood", GOLD_LETTER, 18, eligible)
		index += 1
	_simple_right("GUILD WORK", [
		"No entry fee",
		"No combat or injury",
		"Safe offline income",
		"Recovery for struggling",
		"companies only."
	])
	_touch(dispatch_area, "VIEW CONTRACTS", 8, 315, 225, 37,
		_nav_to.bind("harlow"), "wood", GOLD_LETTER, 15)

func _financial_ledger() -> void:
	_print(central_area, "ACCOUNTS OF THE CONTRACTORS' GUILD",
		17, 8, 791, 29, 18, INK_SOFT)
	var cells := [
		["GOLD ON HAND", _money(game.gold)],
		["COMPANY NET WORTH", _money(game.wealth())],
		["EQUIPMENT VALUE", _money(game.owned_equipment_value())],
		["GUILD DEBT", _money(game.relief_debt)],
		["REPUTATION", str(game.reputation)],
		["ACTIVE OPERATIONS", "%d / %d" % [game.missions.size(), game.expedition_slots]]
	]
	for i in range(cells.size()):
		var x: float = 11.0 + float(i % 2) * 409.0
		var y: float = 53.0 + float(i / 2) * 110.0
		_skin(central_area, "paper", x, y, 397, 98)
		_print(central_area, str(cells[i][0]),
			x + 23, y + 14, 346, 24, 15, INK_SOFT)
		_print(central_area, str(cells[i][1]),
			x + 24, y + 45, 343, 42, 27, INK)
	_simple_right("TREASURY NOTES", [
		"Gold is working capital.",
		"Equipment is appraised,",
		"but only coins pay wages.",
		"Physical vault storage",
		"will come later."
	])

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
	scroll.size = Vector2(805, maxf(80.0, central_area.size.y - y - 12.0))
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
	_ruling(dispatch_area, 8, 26, 222)
	for i in range(lines.size()):
		_print(dispatch_area, str(lines[i]), 10, 48 + i * 39,
			219, 33, 15, INK, HORIZONTAL_ALIGNMENT_LEFT, true)


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
