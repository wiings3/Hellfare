extends "res://scripts/ledger_ui.gd"
## Money Mercs / Guild Operations v0.7
## Reference-led production UI. Painted setting, restrained functional surfaces.
## Native interactive controls. Existing saved games and callbacks retained.

const HALL: Texture2D = preload("res://assets/ui/painted/guildhall_background.webp")
const SIGN: Texture2D = preload("res://assets/ui/painted/guild_sign.webp")
const MINE_ART: Texture2D = preload("res://assets/ui/painted/harlow_engraving.webp")

const INK := Color("#181e1c")
const NIGHT := Color("#161c1b")
const SURFACE := Color("#222a29")
const SURFACE_RAISED := Color("#2b3330")
const EDGE := Color("#665d4b")
const RULE := Color("#504b3f")
const IVORY := Color("#f3e7cd")
const PAPER := Color("#e3d6b9")
const GOLD := Color("#e1be76")
const MUTED := Color("#b5ae9e")
const BURGUNDY := Color("#733d38")
const SUCCESS := Color("#a6c19c")
const DANGER := Color("#d99585")
const FAINT := Color("#868d82")

var canvas: Control
var nav_area: Control
var work_area: Control
var side_area: Control
var report_banner: Label
var heading: Label
var heading_caption: Label
var headline_gold: Label
var headline_worth: Label
var headline_missions: Label
var serif: SystemFont
var sans: SystemFont
var message_until: int = 0

func _ready() -> void:
	page = "hq"
	super._ready()

func _build_shell() -> void:
	serif = SystemFont.new()
	serif.font_names = PackedStringArray(["Noto Serif", "DejaVu Serif", "Georgia", "Liberation Serif"])
	sans = SystemFont.new()
	sans.font_names = PackedStringArray(["Noto Sans", "Inter", "DejaVu Sans", "Liberation Sans"])
	canvas = Control.new()
	canvas.name = "GuildOperations"
	canvas.size = Vector2(1600, 900)
	canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(canvas)
	resized.connect(_fit_canvas)
	_fit_canvas()

	var background := TextureRect.new()
	background.texture = HALL
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.size = Vector2(1600, 900)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(background)
	# Darkening the painting keeps fantasy atmosphere without compromising legibility.
	_block(canvas, 0, 0, 1600, 900, Color("#0b100f", 0.37))
	_block(canvas, 0, 0, 1600, 128, Color("#101713", 0.89))
	_block(canvas, 0, 128, 1600, 2, GOLD.darkened(0.4))

	# Original guild sign is the one elaborate decorative element.
	_picture(canvas, SIGN, 25, 12, 415, 105)
	_stat_plate(468, "TREASURY", "gold")
	_stat_plate(756, "COMPANY VALUE", "worth")
	_stat_plate(1044, "ACTIVE EXPEDITIONS", "missions")
	# Right edge is a restrained guild seal / build identity.
	_label(canvas, "GUILD OPERATIONS", 1380, 58, 195, 24, 14, GOLD, false, HORIZONTAL_ALIGNMENT_RIGHT)

	_ui_panel(canvas, 28, 157, 244, 676, "dark")
	_ui_panel(canvas, 289, 157, 955, 676, "main")
	_ui_panel(canvas, 1260, 157, 312, 676, "dark")
	_label(canvas, "COMPANY RECORDS", 48, 180, 200, 26, 14, GOLD, true)
	_hline(canvas, 48, 214, 204)
	heading = _label(canvas, "OVERVIEW", 318, 181, 790, 46, 31, IVORY, true)
	heading_caption = _label(canvas, "", 320, 224, 883, 30, 15, MUTED)
	_hline(canvas, 318, 262, 895)
	_label(canvas, "THE DESK", 1283, 180, 255, 26, 14, GOLD, true)
	_hline(canvas, 1282, 214, 264)
	nav_area = _region(canvas, 43, 229, 215, 574)
	work_area = _region(canvas, 312, 275, 916, 535)
	side_area = _region(canvas, 1278, 230, 277, 570)
	_label(canvas, "THE CONTRACTOR'S GUILD", 29, 854, 400, 24, 14, PAPER, true)
	_label(canvas, "Company records are saved automatically", 1130, 854, 442, 24, 13, MUTED, false, HORIZONTAL_ALIGNMENT_RIGHT)
	report_banner = _label(canvas, "", 436, 133, 728, 28, 14, IVORY, false, HORIZONTAL_ALIGNMENT_CENTER)
	report_banner.visible = false
	notice = report_banner
	header_gold = headline_gold
	header_wealth = headline_worth
	header_jobs = headline_missions

func _fit_canvas() -> void:
	if not is_instance_valid(canvas):
		return
	var dims: Vector2 = size
	if dims.x <= 0 or dims.y <= 0:
		dims = get_viewport_rect().size
	var scale_factor: float = minf(dims.x / 1600.0, dims.y / 900.0)
	canvas.scale = Vector2(scale_factor, scale_factor)
	canvas.position = (dims - Vector2(1600, 900) * scale_factor) * 0.5

func _region(parent: Node, x: float, y: float, w: float, h: float) -> Control:
	var rect := Control.new()
	rect.position = Vector2(x, y)
	rect.size = Vector2(w, h)
	rect.clip_contents = true
	rect.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(rect)
	return rect

func _block(parent: Node, x: float, y: float, w: float, h: float, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = Vector2(x, y)
	rect.size = Vector2(w, h)
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect

func _picture(parent: Node, source: Texture2D, x: float, y: float, w: float, h: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = source
	icon.position = Vector2(x, y)
	icon.size = Vector2(w, h)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	return icon

func _box_style(kind: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SURFACE
	style.border_color = EDGE
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(0)
	match kind:
		"dark":
			style.bg_color = Color("#171d1b", 0.98)
			style.border_color = Color("#4f4d40")
		"main":
			style.bg_color = Color("#202622", 0.99)
			style.border_color = Color("#827153")
		"row":
			style.bg_color = Color("#30372f")
			style.border_color = Color("#4c5144")
		"row_selected":
			style.bg_color = Color("#51443b")
			style.border_color = GOLD
		"soft":
			style.bg_color = Color("#292f2b")
			style.border_color = Color("#444b40")
		"danger":
			style.bg_color = Color("#3d2925")
			style.border_color = Color("#97675d")
		"paper":
			style.bg_color = PAPER
			style.border_color = GOLD.darkened(0.45)
	return style

func _ui_panel(parent: Node, x: float, y: float, w: float, h: float, kind: String = "soft") -> Panel:
	var rect := Panel.new()
	rect.position = Vector2(x, y)
	rect.size = Vector2(w, h)
	rect.add_theme_stylebox_override("panel", _box_style(kind))
	parent.add_child(rect)
	return rect

func _text_size(value: String, font: Font, starting: int, maximum_width: float) -> int:
	var size_px: int = starting
	while size_px > 12 and font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size_px).x > maximum_width - 5:
		size_px -= 1
	return size_px

func _label(parent: Node, label: String, x: float, y: float, w: float, h: float,
		font_size: int = 16, color: Color = IVORY, use_serif: bool = false,
		alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, wrap: bool = false) -> Label:
	var text_line := Label.new()
	text_line.text = label
	text_line.position = Vector2(x, y)
	text_line.size = Vector2(w, h)
	var f: Font = serif if use_serif else sans
	text_line.add_theme_font_override("font", f)
	text_line.add_theme_font_size_override("font_size", _text_size(label, f, font_size, w) if not wrap else font_size)
	text_line.add_theme_color_override("font_color", color)
	text_line.horizontal_alignment = alignment
	text_line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	text_line.clip_text = true
	text_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(text_line)
	return text_line

func _hline(parent: Node, x: float, y: float, length: float) -> void:
	_block(parent, x, y, length, 1, RULE)

func _ui_button(parent: Node, title: String, x: float, y: float, w: float, h: float,
		callback: Callable, kind: String = "secondary", enabled: bool = true) -> Button:
	var button := Button.new()
	button.position = Vector2(x, y)
	button.size = Vector2(w, h)
	button.text = title
	button.disabled = not enabled
	button.add_theme_font_override("font", sans)
	button.add_theme_font_size_override("font_size", _text_size(title, sans, 16, w - 24))
	button.add_theme_color_override("font_color", IVORY)
	button.add_theme_color_override("font_hover_color", Color("#fff7e7"))
	button.add_theme_color_override("font_pressed_color", Color("#fff7e7"))
	button.add_theme_color_override("font_disabled_color", FAINT)
	button.add_theme_stylebox_override("normal", _button_style(kind))
	button.add_theme_stylebox_override("hover", _button_style(kind + "_hover"))
	button.add_theme_stylebox_override("pressed", _button_style(kind + "_pressed"))
	button.add_theme_stylebox_override("disabled", _button_style("disabled"))
	button.add_theme_stylebox_override("focus", _button_style("focus"))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _button_style(variant: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(3)
	style.set_border_width_all(1)
	style.set_content_margin_all(4)
	style.bg_color = Color("#383f37")
	style.border_color = Color("#7b806d")
	match variant:
		"primary":
			style.bg_color = Color("#8d6736")
			style.border_color = GOLD
		"primary_hover", "primary_pressed":
			style.bg_color = Color("#ac8046")
			style.border_color = Color("#ffe1a3")
		"secondary_hover", "secondary_pressed":
			style.bg_color = Color("#555f51")
			style.border_color = GOLD
		"quiet":
			style.bg_color = Color("#262e28")
			style.border_color = Color("#444b41")
		"quiet_hover", "quiet_pressed":
			style.bg_color = Color("#3c493e")
			style.border_color = GOLD
		"disabled":
			style.bg_color = Color("#242a26")
			style.border_color = Color("#464941")
		"danger":
			style.bg_color = BURGUNDY
			style.border_color = DANGER
		"danger_hover", "danger_pressed":
			style.bg_color = Color("#96534b")
			style.border_color = IVORY
		"focus":
			style.bg_color = Color.TRANSPARENT
			style.border_color = GOLD
	return style

func _stat_plate(x: float, caption: String, key: String) -> void:
	_ui_panel(canvas, x, 33, 267, 73, "soft")
	_block(canvas, x, 33, 4, 73, GOLD)
	_label(canvas, caption, x + 20, 41, 229, 21, 13, MUTED, true)
	var number := _label(canvas, "0", x + 20, 65, 230, 34, 25, GOLD, true)
	match key:
		"gold": headline_gold = number
		"worth": headline_worth = number
		"missions": headline_missions = number

func _refresh() -> void:
	if not is_instance_valid(canvas):
		return
	headline_gold.text = _money(game.gold)
	headline_worth.text = _money(game.wealth())
	headline_missions.text = "%d / %d" % [game.missions.size(), game.expedition_slots]
	_clear(nav_area)
	_clear(work_area)
	_clear(side_area)
	_render_navigation()
	_render_heading()
	match page:
		"hq": _render_overview()
		"harlow": _render_harlow()
		"roster": _render_roster()
		"market": _render_market()
		"guildwork": _render_guild_work()
		"finance": _render_finance()
		"ledger": _render_chronicle()
		"expeditions": _render_regions()
		_: _render_overview()

func _render_heading() -> void:
	var titles := {
		"hq": ["Company Overview", "What needs your attention today."],
		"harlow": ["Harlow Mines", "Scout the claim, assemble a team, dispatch on your terms."],
		"roster": ["Mercenaries & Equipment", "Hire, outfit, and keep your contractors alive."],
		"market": ["Trading Post", "Buy and sell commodities using the company's treasury."],
		"guildwork": ["Guild Work Orders", "Guaranteed low-paid work when the company needs to recover."],
		"finance": ["Company Ledger", "Know exactly where your money and assets are."],
		"ledger": ["Expedition Chronicle", "Recorded returns, casualties and recovered goods."],
		"expeditions": ["Regional Contracts", "Other contracts beyond Harlow Mines."]
	}
	var descriptor: Array = titles.get(page, titles["hq"])
	heading.text = str(descriptor[0])
	heading_caption.text = str(descriptor[1])

func _render_navigation() -> void:
	var entries: Array = [
		["hq", "Overview", "Company at a glance"],
		["harlow", "Contracts", "Scout & dispatch"],
		["roster", "Mercenaries", "Crew & equipment"],
		["guildwork", "Guild Work", "Guaranteed wages"],
		["market", "Trading Post", "Buy & sell"],
		["finance", "Ledger", "Company finances"],
		["ledger", "Chronicle", "Field reports"]
	]
	for i in range(entries.size()):
		var entry: Array = entries[i]
		var y: float = float(i * 67)
		if str(entry[0]) == page:
			_ui_panel(nav_area, 0, y, 213, 62, "row_selected")
			_block(nav_area, 0, y, 4, 62, GOLD)
		else:
			_ui_panel(nav_area, 0, y, 213, 62, "soft")
		_label(nav_area, str(entry[1]), 17, y + 10, 190, 26, 17, IVORY, true)
		_label(nav_area, str(entry[2]), 17, y + 36, 192, 17, 12, MUTED)
		var hit := Button.new()
		hit.position = Vector2(0, y)
		hit.size = Vector2(213, 62)
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color.TRANSPARENT
		var hover := StyleBoxFlat.new()
		hover.bg_color = Color("#c39a61", 0.10)
		hover.border_color = GOLD
		hover.border_width_bottom = 2
		hit.add_theme_stylebox_override("normal", flat)
		hit.add_theme_stylebox_override("hover", hover)
		hit.pressed.connect(_nav_to.bind(str(entry[0])))
		nav_area.add_child(hit)
	_hline(nav_area, 0, 480, 210)
	_label(nav_area, "%d CONTRACTORS  /  %d READY" % [game.crew.size(), game.free_crew()],
		4, 490, 209, 25, 13, GOLD)
	_label(nav_area, "Reputation  %d" % game.reputation, 4, 518, 209, 23, 14, MUTED)

func _notify(message: String) -> void:
	if message.begins_with("Guild office open."):
		return
	report_banner.text = message
	report_banner.visible = true
	message_until = Time.get_ticks_msec() + 7000

func _on_clock() -> void:
	super._on_clock()
	if message_until > 0 and Time.get_ticks_msec() > message_until:
		message_until = 0
		report_banner.visible = false

func _ui_metric(parent: Node, title: String, value: String, x: float, y: float, w: float) -> void:
	_ui_panel(parent, x, y, w, 92, "soft")
	_label(parent, title, x + 17, y + 13, w - 32, 20, 13, MUTED)
	_label(parent, value, x + 17, y + 37, w - 32, 42, 27, IVORY, true)

func _render_overview() -> void:
	_ui_panel(work_area, 12, 10, 890, 246, "row")
	_block(work_area, 12, 10, 4, 246, GOLD)
	_label(work_area, "FEATURED CONTRACT  /  REGION 01", 33, 30, 460, 25, 14, GOLD)
	_label(work_area, "Harlow Mines", 32, 66, 441, 52, 33, IVORY, true)
	_label(work_area, "Changing ore deposits. Uncertain threats.", 33, 126, 420, 28, 17, MUTED)
	_label(work_area, "A scout's report helps you decide whether the crew is worth risking.",
		33, 159, 415, 48, 15, IVORY, false, HORIZONTAL_ALIGNMENT_LEFT, true)
	_ui_button(work_area, "INSPECT CONTRACT", 32, 211, 280, 37, _nav_to.bind("harlow"), "primary")
	_picture(work_area, MINE_ART, 527, 22, 347, 216)
	_ui_metric(work_area, "CASH ON HAND", _money(game.gold), 12, 270, 286)
	_ui_metric(work_area, "ASSET VALUE", _money(game.wealth()), 314, 270, 286)
	_ui_metric(work_area, "READY WORKERS", str(game.free_crew()), 616, 270, 286)
	_ui_panel(work_area, 12, 375, 890, 148, "soft")
	_label(work_area, "MOST RECENT FIELD REPORT", 32, 392, 600, 27, 15, GOLD)
	if game.reports.is_empty():
		_label(work_area, "No completed expeditions. Start by inspecting Harlow Mines.",
			32, 425, 820, 32, 17, MUTED)
	else:
		var r: Dictionary = game.reports[0]
		_label(work_area, "%s  —  %s" % [
			str(r.get("region", "Unknown")), "Returned" if bool(r.get("won", false)) else "Costly return"],
			32, 422, 720, 28, 19, IVORY, true)
		_label(work_area, "Recovered: %s  •  Gold found: %d G" % [
			_loot_text(r.get("loot", {})), int(r.get("cash", 0))],
			32, 456, 760, 25, 15, MUTED)
	_ui_button(work_area, "VIEW CHRONICLE", 640, 483, 242, 31, _nav_to.bind("ledger"), "quiet")
	_context_title("TODAY'S WORK")
	_context_line("Company cash", _money(game.gold), 52)
	_context_line("Standing contractors", str(game.crew.size()), 100)
	_context_line("Operations in field", str(game.missions.size()), 148)
	_context_line("Outstanding guild debt", _money(game.relief_debt), 196)
	_ui_button(side_area, "SCOUT HARLOW MINES", 14, 280, 248, 45, _nav_to.bind("harlow"), "primary")
	_ui_button(side_area, "MANAGE YOUR CREW", 14, 336, 248, 43, _nav_to.bind("roster"), "secondary")
	_ui_button(side_area, "SAFE GUILD WORK", 14, 390, 248, 43, _nav_to.bind("guildwork"), "quiet")
	_label(side_area, "Your company grows by returning safely, not just by finding ore.",
		16, 461, 242, 75, 14, MUTED, false, HORIZONTAL_ALIGNMENT_LEFT, true)

func _context_title(text: String) -> void:
	_label(side_area, text, 13, 7, 250, 32, 18, IVORY, true)
	_hline(side_area, 13, 45, 248)

func _context_line(label: String, value: String, y: float) -> void:
	_label(side_area, label, 14, y, 247, 19, 13, MUTED)
	_label(side_area, value, 14, y + 19, 245, 30, 20, IVORY, true)
	_hline(side_area, 14, y + 54, 248)

func _render_harlow() -> void:
	var report: Dictionary = game.harlow.get("report", {})
	_ui_panel(work_area, 10, 8, 891, 215, "soft")
	_label(work_area, "SCOUTING REPORT", 27, 23, 560, 29, 17, GOLD, true)
	_picture(work_area, MINE_ART, 568, 14, 310, 189)
	if report.is_empty():
		var searching: bool = int(game.harlow.get("scout_finish", 0)) > 0
		_label(work_area, "Scout surveying the mine" if searching else "No current intelligence", 27, 62, 532, 35, 22, IVORY, true)
		_label(work_area, "Your scouts always return safely.", 27, 103, 502, 27, 15, MUTED)
		if searching:
			_label(work_area, "Expected return: %s" % _duration(maxi(0,
				int(game.harlow.get("scout_finish", 0)) - int(Time.get_unix_time_from_system()))),
				27, 139, 515, 25, 15, GOLD)
		else:
			_ui_button(work_area, "SEND SCOUT", 27, 153, 230, 43, _scout, "primary")
	else:
		_label(work_area, "At least %d veins of %s" % [
			int(report.get("minimum", 0)),
			str(MoneyMercsState.RESOURCE_NAMES.get(str(report.get("primary", "copper")), "ore"))],
			27, 68, 520, 30, 21, IVORY)
		_label(work_area, "Threat spotted: %s" % str(report.get("creature", "Unknown")), 27, 105, 512, 30, 16, DANGER)
		_label(work_area, "This report expires when the site rotates.", 27, 144, 525, 25, 14, MUTED)
	var scout_level: int = int(game.harlow.get("scout_level", 1))
	_label(work_area, "SCOUT LEVEL  %d / 3" % scout_level, 283, 180, 220, 27, 14, MUTED)
	if scout_level < 3:
		var upgrade_cost: int = 200 if scout_level == 1 else 650
		_ui_button(work_area, "UPGRADE SCOUT  /  %d G" % upgrade_cost,
			27, 177, 228, 29, _train_scout, "quiet", game.gold >= upgrade_cost)
	_label(work_area, "ASSIGN AVAILABLE CREW", 13, 234, 725, 30, 20, IVORY, true)
	_label(work_area, "Miners extract ore. Guards improve survival. Lost gear cannot be recovered.",
		13, 263, 873, 30, 14, MUTED)
	var list: VBoxContainer = _ui_scroller(work_area, 13, 302, 890, 217)
	var displayed: int = 0
	for person in game.available_guild_workers():
		if str(person.get("role", "")) not in ["Miner", "Guard"]:
			continue
		var card: Control = _record(list, 72)
		var role: String = str(person["role"])
		var role_icon: Texture2D = MINER if role == "Miner" else GUARD
		_picture(card, role_icon, 10, 7, 53, 53)
		_label(card, str(person["name"]), 74, 8, 328, 27, 19, IVORY, true)
		_label(card, "%s  •  HP %d%%  •  Equipment %d/2" % [
			role, int(person.get("health", 100)), _equipped_count(person)],
			75, 38, 455, 21, 14, MUTED)
		var on_team: bool = selected_crew.has(str(person["id"]))
		_ui_button(card, "REMOVE" if on_team else "ASSIGN", 720, 16, 140, 38,
			_toggle_crew.bind(not on_team, str(person["id"])),
			"danger" if on_team else "secondary")
		displayed += 1
	if displayed == 0:
		var empty: Control = _record(list, 74)
		_label(empty, "No available miners or guards.", 16, 13, 550, 34, 18, MUTED)
		_ui_button(empty, "RECRUIT", 712, 13, 148, 39, _open_recruitment, "primary")
	_render_dispatch()

func _render_dispatch() -> void:
	_context_title("DISPATCH ORDERS")
	var selector := OptionButton.new()
	selector.position = Vector2(13, 69)
	selector.size = Vector2(248, 44)
	for order in MoneyMercsState.TACTICS:
		selector.add_item(str(order))
	selector.select(maxi(0, MoneyMercsState.TACTICS.find(tactic)))
	selector.add_theme_font_override("font", sans)
	selector.add_theme_font_size_override("font_size", 16)
	selector.add_theme_color_override("font_color", IVORY)
	selector.add_theme_stylebox_override("normal", _button_style("secondary"))
	selector.item_selected.connect(func(index: int) -> void:
		_set_tactic(str(MoneyMercsState.TACTICS[index]))
	)
	side_area.add_child(selector)
	var ids: Array[String] = _selected_available()
	var forecast: Dictionary = game.harlow_crew_stats(ids, tactic)
	var intel: bool = not (game.harlow.get("report", {}) as Dictionary).is_empty()
	_context_line("Selected mercenaries", "%d (miners: %d, guards: %d)" % [
		ids.size(), int(forecast["miners"]), int(forecast["guards"])], 139)
	_context_line("Maximum ore extraction", "%d veins" % int(forecast["capacity"]), 218)
	_context_line("Dispatch cost", _money(int(forecast["wage"])), 297)
	if intel:
		_label(side_area, "Estimated success: %d%%" %
			int(round(float(forecast["success"]) * 100.0)),
			14, 374, 249, 28, 17, SUCCESS)
	else:
		_label(side_area, "Risk unknown — scout first", 14, 374, 249, 28, 16, DANGER)
	_label(side_area, "Death and lost equipment are permanent.", 14, 406, 248, 48,
		14, MUTED, false, HORIZONTAL_ALIGNMENT_LEFT, true)
	var ore_left: int = 0
	for amount in (game.harlow.get("deposits", {}) as Dictionary).values():
		ore_left += int(amount)
	var can_go: bool = (int(forecast["miners"]) >= 1 and ids.size() <= 3 and ore_left > 0
		and game.gold >= int(forecast["wage"]) and game.missions.size() < game.expedition_slots)
	_ui_button(side_area, "FUND EXPEDITION", 13, 464, 249, 49,
		_dispatch_harlow, "primary", can_go)
	_ui_button(side_area, "GUILD WORK / RECOVERY", 13, 526, 249, 36,
		_nav_to.bind("guildwork"), "quiet")

func _ui_scroller(parent: Node, x: float, y: float, w: float, h: float) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(x, y)
	scroll.size = Vector2(w, h)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	parent.add_child(scroll)
	var content := VBoxContainer.new()
	content.custom_minimum_size.x = w - 23.0
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 7)
	scroll.add_child(content)
	return content

func _record(list: Node, h: int = 74) -> Control:
	var holder := PanelContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.custom_minimum_size.y = h
	holder.add_theme_stylebox_override("panel", _box_style("row"))
	list.add_child(holder)
	var body := Control.new()
	body.custom_minimum_size.y = h - 2
	body.custom_minimum_size.x = 869
	holder.add_child(body)
	return body

func _render_roster() -> void:
	var tabset: Array = [["employed", "YOUR CREW"], ["recruits", "RECRUITMENT"], ["armory", "ARMORY"]]
	for i in range(tabset.size()):
		var tab: Array = tabset[i]
		_ui_button(work_area, str(tab[1]), 12 + i * 299, 11, 288, 46,
			_set_roster_tab.bind(str(tab[0])),
			"primary" if roster_tab == str(tab[0]) else "quiet")
	var list := _ui_scroller(work_area, 12, 74, 891, 447)
	if roster_tab == "recruits":
		for applicant in game.recruitment_board():
			var row := _record(list, 91)
			_picture(row, MINER if str(applicant["role"]) == "Miner" else GUARD,
				12, 12, 64, 64)
			_label(row, str(applicant["name"]), 85, 7, 400, 35, 20, IVORY, true)
			_label(row, "%s  •  Skill %d  •  Wage %d G" % [
				str(applicant["role"]), int(applicant["skill"]), int(applicant["wage"])],
				86, 43, 491, 25, 15, MUTED)
			_ui_button(row, "HIRE  /  %d G" % int(applicant["hire"]), 683, 22, 175, 43,
				_hire.bind(str(applicant["id"])), "primary",
				game.gold >= int(applicant["hire"]))
	elif roster_tab == "armory":
		_render_armory(list)
	else:
		for merc in game.crew:
			var row := _record(list, 102)
			_picture(row, MINER if str(merc["role"]) == "Miner" else GUARD, 12, 13, 72, 73)
			_label(row, str(merc["name"]), 94, 9, 445, 31, 22, IVORY, true)
			_label(row, "%s  •  Health %d%%  •  Experience %d" % [
				str(merc["role"]), int(merc.get("health", 100)), int(merc.get("xp", 0))],
				95, 42, 481, 22, 15, MUTED)
			_label(row, "Equipped %d / 2   •   Wage %d G" % [
				_equipped_count(merc), int(merc.get("wage", 0))],
				95, 68, 482, 20, 14, GOLD)
			_ui_button(row, "OUTFIT", 683, 12, 175, 36,
				_outfit.bind(str(merc["id"])), "primary")
			_ui_button(row, "CONTRACT", 683, 53, 175, 35,
				_terms.bind(str(merc["id"])), "quiet")
			if int(merc.get("health", 100)) < 100:
				_ui_button(row, "TREAT", 551, 53, 125, 35,
					_heal.bind(str(merc["id"])), "secondary")
	if list.get_child_count() == 0:
		var empty := _record(list, 94)
		_label(empty, "Nothing to display here yet.", 18, 19, 630, 38, 18, MUTED)
	_context_title("PERSONNEL OFFICE")
	_context_line("Contractors on payroll", str(game.crew.size()), 61)
	_context_line("Ready for work", str(game.free_crew()), 137)
	_context_line("Stored equipment", str(game.equipment_inventory.size()), 213)
	_ui_button(side_area, "YOUR CREW", 13, 310, 248, 43,
		_set_roster_tab.bind("employed"), "secondary")
	_ui_button(side_area, "RECRUITMENT", 13, 365, 248, 43,
		_set_roster_tab.bind("recruits"), "secondary")
	_ui_button(side_area, "OPEN ARMORY", 13, 420, 248, 43,
		_set_roster_tab.bind("armory"), "primary")
	_label(side_area, "Employees are assets. Skilled workers and equipped gear are expensive to replace.",
		15, 477, 247, 75, 14, MUTED, false, HORIZONTAL_ALIGNMENT_LEFT, true)

func _render_armory(list: VBoxContainer) -> void:
	for person in game.crew:
		var picker := _record(list, 75)
		var id: String = str(person["id"])
		var worn: Dictionary = person.get("equipment", {})
		_label(picker, "%s  /  %s" % [str(person["name"]), str(person["role"])],
			14, 9, 530, 27, 18, IVORY, true)
		_label(picker, "%s  •  %s" % [
			_equipment_name(worn.get("tool", {})), _equipment_name(worn.get("armor", {}))],
			15, 38, 565, 24, 14, MUTED)
		_ui_button(picker, "SELECTED" if selected_merc == id else "SELECT",
			690, 17, 167, 40, _choose_worker.bind(id),
			"primary" if selected_merc == id else "quiet")
	if selected_merc.is_empty() and not game.crew.is_empty():
		selected_merc = str(game.crew[0]["id"])
	var assigned: Dictionary = game.merc_by_id(selected_merc)
	if not assigned.is_empty() and game.is_available(assigned):
		var worn: Dictionary = assigned.get("equipment", {})
		for slot in ["tool", "armor"]:
			var item: Dictionary = worn.get(slot, {})
			if not item.is_empty():
				var equipped := _record(list, 66)
				_label(equipped, "EQUIPPED: %s" % _equipment_name(item),
					14, 11, 616, 37, 17, GOLD)
				_ui_button(equipped, "UNEQUIP", 690, 13, 167, 39,
					_unequip.bind(selected_merc, slot), "secondary")
	for item in game.equipment_inventory:
		var key: String = str(item.get("key", ""))
		var def: Dictionary = game.item_definition(key)
		var stock := _record(list, 74)
		_label(stock, str(def.get("name", "Unknown item")), 14, 7, 486, 32, 19, IVORY, true)
		_label(stock, "Stored • resale %d G" % int(float(def.get("cost", 0)) * 0.65),
			15, 40, 499, 21, 14, MUTED)
		_ui_button(stock, "EQUIP", 569, 14, 138, 43,
			_equip.bind(selected_merc, str(item["uid"])), "primary",
			not assigned.is_empty() and game.is_available(assigned) and MercsV05.validate_role(key, assigned))
		_ui_button(stock, "SELL", 714, 14, 141, 43,
			_sell_equipment.bind(str(item["uid"])), "secondary")
	var heading_row := _record(list, 49)
	_label(heading_row, "QUARTERMASTER'S CATALOGUE", 14, 4, 811, 38, 17, GOLD, true)
	for key in MercsV05.ITEMS:
		var def: Dictionary = MercsV05.ITEMS[key]
		var purchase := _record(list, 74)
		_label(purchase, str(def["name"]), 14, 5, 535, 30, 19, IVORY, true)
		_label(purchase, "%s  •  Mining +%d  •  Combat +%d  •  Armor +%d" % [
			str(def["role"]), int(def["mining"]), int(def["guard"]), int(def["protection"])],
			14, 38, 582, 25, 14, MUTED)
		_ui_button(purchase, "BUY  /  %d G" % int(def["cost"]), 672, 14, 182, 41,
			_buy_equipment.bind(str(key)), "primary", game.gold >= int(def["cost"]))

func _render_market() -> void:
	_label(work_area, "COMMODITIES", 18, 13, 510, 28, 18, IVORY, true)
	_label(work_area, "Inventory", 447, 13, 110, 28, 14, MUTED)
	_label(work_area, "Buy price", 567, 13, 112, 28, 14, MUTED)
	_label(work_area, "Sell price", 690, 13, 109, 28, 14, MUTED)
	_hline(work_area, 13, 49, 889)
	var list := _ui_scroller(work_area, 11, 59, 894, 460)
	for item_id in MoneyMercsState.RESOURCE_ORDER:
		var id: String = str(item_id)
		var count: int = int(game.resources.get(id, 0))
		var row := _record(list, 80)
		_picture(row, RESOURCE_ICONS.get(id, GOLD_ICON), 9, 12, 54, 54)
		_label(row, str(MoneyMercsState.RESOURCE_NAMES[id]),
			74, 9, 328, 31, 19, IVORY, true)
		_label(row, str(MoneyMercsState.RESOURCE_DESC.get(id, "")),
			74, 42, 330, 26, 13, MUTED)
		_label(row, "%d" % count, 434, 20, 93, 36, 21, IVORY, true)
		_label(row, "%d G" % game.buy_price(id), 551, 20, 100, 36, 19, GOLD)
		_label(row, "%d G" % game.sell_price(id), 673, 20, 90, 36, 19, GOLD)
		_ui_button(row, "BUY", 762, 8, 96, 30, _trade.bind(id, true, 1),
			"primary", game.gold >= game.buy_price(id))
		_ui_button(row, "SELL", 762, 42, 96, 30, _trade.bind(id, false, 1),
			"secondary", count > 0)
	_context_title("MERCHANT TERMS")
	_context_line("Spendable gold", _money(game.gold), 61)
	_context_line("Known commodities", str(MoneyMercsState.RESOURCE_ORDER.size()), 142)
	_ui_button(side_area, "COMPANY LEDGER", 13, 280, 249, 47,
		_nav_to.bind("finance"), "primary")
	_label(side_area, "Buy prices include a merchant premium. Selling converts goods to gold immediately.",
		15, 358, 243, 95, 15, MUTED, false, HORIZONTAL_ALIGNMENT_LEFT, true)
	_label(side_area, "The player market is a future feature.", 15, 487, 246, 53,
		14, GOLD, false, HORIZONTAL_ALIGNMENT_LEFT, true)

func _render_finance() -> void:
	var entries: Array = [
		["TREASURY", _money(game.gold)],
		["COMPANY NET WORTH", _money(game.wealth())],
		["EQUIPMENT ASSETS", _money(game.owned_equipment_value())],
		["GUILD DEBT", _money(game.relief_debt)],
		["REPUTATION", str(game.reputation)],
		["ACTIVE EXPEDITIONS", "%d / %d" % [game.missions.size(), game.expedition_slots]]
	]
	for i in range(entries.size()):
		var pair: Array = entries[i]
		_ui_metric(work_area, str(pair[0]), str(pair[1]),
			14 + float(i % 2) * 448, 16 + float(i / 2) * 125, 429)
	_ui_panel(work_area, 14, 398, 887, 121, "soft")
	_label(work_area, "ACCOUNTING NOTE", 31, 415, 840, 27, 15, GOLD)
	_label(work_area, "Gold pays wages. Stored resources and equipment count toward company value,",
		32, 449, 847, 27, 17, IVORY)
	_label(work_area, "but only liquid gold can fund a new expedition.", 32, 477, 845, 24, 16, MUTED)
	_context_title("THE TREASURY")
	_context_line("Gold available", _money(game.gold), 59)
	_context_line("Net worth", _money(game.wealth()), 144)
	_context_line("Debt owed", _money(game.relief_debt), 229)
	_ui_button(side_area, "OPEN TRADING POST", 13, 337, 248, 48,
		_nav_to.bind("market"), "primary")
	_ui_button(side_area, "MANAGE CONTRACTORS", 13, 397, 248, 46,
		_nav_to.bind("roster"), "secondary")

func _render_guild_work() -> void:
	_ui_panel(work_area, 12, 12, 890, 126, "soft")
	_label(work_area, "GET BACK ON YOUR FEET", 32, 29, 812, 35, 21, IVORY, true)
	_label(work_area, "Work orders pay a guaranteed wage. No deaths, supply fees or lost gear.",
		32, 76, 809, 35, 17, MUTED)
	var eligible: bool = game.can_accept_guild_work() and game.missions.size() < game.expedition_slots
	_ui_panel(work_area, 12, 151, 890, 81, "row")
	_label(work_area, "Office paperwork", 28, 162, 527, 30, 21, IVORY, true)
	_label(work_area, "3 minutes  •  No employees required", 29, 197, 575, 24, 15, MUTED)
	_ui_button(work_area, "ACCEPT  /  9 G", 700, 170, 186, 46,
		_guild_work.bind(""), "primary", eligible)
	var index: int = 0
	for person in game.available_guild_workers():
		if index >= 3:
			break
		var y: float = 245.0 + float(index) * 93.0
		_ui_panel(work_area, 12, y, 890, 83, "row")
		_label(work_area, "Guild labor  •  %s" % str(person["name"]),
			28, y + 9, 622, 31, 20, IVORY, true)
		_label(work_area, "2m 30s  •  Guaranteed pay  •  No combat",
			29, y + 42, 596, 25, 15, MUTED)
		_ui_button(work_area, "ASSIGN  /  18 G", 700, y + 17, 186, 46,
			_guild_work.bind(str(person["id"])), "primary", eligible)
		index += 1
	if index == 0:
		_label(work_area, "No workers available. You can still complete office paperwork.",
			20, 268, 833, 60, 17, MUTED, false, HORIZONTAL_ALIGNMENT_LEFT, true)
	_context_title("RECOVERY CONTRACTS")
	_context_line("Cash", _money(game.gold), 64)
	_context_line("Appraised company", _money(game.wealth()), 143)
	_label(side_area, "Work is available while cash is below 120 G and company value below 250 G.",
		15, 245, 244, 87, 15, MUTED, false, HORIZONTAL_ALIGNMENT_LEFT, true)
	_ui_button(side_area, "RETURN TO CONTRACTS", 13, 381, 249, 47,
		_nav_to.bind("harlow"), "secondary")

func _render_chronicle() -> void:
	var history := _ui_scroller(work_area, 12, 13, 893, 508)
	for report in game.reports:
		var row := _record(history, 112)
		_label(row, str(report.get("region", "Unknown expedition")), 15, 10, 596, 34,
			21, IVORY, true)
		var good: bool = bool(report.get("won", false))
		_label(row, "SUCCESS" if good else "COSTLY RETURN", 674, 11, 181, 29,
			14, SUCCESS if good else DANGER)
		_label(row, "Recovered: %s" % _loot_text(report.get("loot", {})),
			15, 47, 813, 25, 16, MUTED)
		var dead: Array = report.get("casualties", [])
		_label(row, "Cash found %d G  •  Cost %d G  •  Deaths %d" % [
			int(report.get("cash", 0)), int(report.get("cost", 0)), dead.size()],
			15, 76, 817, 24, 15, GOLD if dead.is_empty() else DANGER)
	if game.reports.is_empty():
		var empty := _record(history, 100)
		_label(empty, "No expeditions have returned yet.", 20, 25, 700, 42, 19, MUTED)
	_context_title("FIELD RECORDS")
	_context_line("Completed reports", str(game.reports.size()), 64)
	_context_line("Current expeditions", str(game.missions.size()), 143)
	_ui_button(side_area, "INSPECT HARLOW MINES", 13, 289, 247, 48,
		_nav_to.bind("harlow"), "primary")
	_ui_button(side_area, "VIEW COMPANY LEDGER", 13, 349, 247, 44,
		_nav_to.bind("finance"), "secondary")

func _render_regions() -> void:
	_label(work_area, "Other sites currently use the original expedition rules.",
		14, 14, 879, 31, 17, MUTED)
	var jobs := _ui_scroller(work_area, 12, 64, 895, 456)
	for location in MoneyMercsState.REGIONS:
		var row := _record(jobs, 138)
		_label(row, str(location["name"]), 15, 10, 654, 35, 22, IVORY, true)
		_label(row, str(location.get("tagline", "")), 15, 48, 691, 28, 16, MUTED)
		_label(row, "Threat %d  •  Supplies %d G  •  Reputation %d" % [
			int(location["threat"]), int(location["supplies"]), int(location["rep"])],
			15, 86, 680, 25, 15, GOLD)
		_ui_button(row, "DISPATCH", 679, 78, 174, 45,
			_old_dispatch.bind(str(location["id"])), "primary",
			game.free_crew() > 0 and game.reputation >= int(location["rep"]) and
			game.missions.size() < game.expedition_slots)
	_context_title("REGIONAL BOARD")
	_label(side_area, "Higher rewards demand better-paid, better-equipped teams.",
		15, 71, 242, 84, 16, MUTED, false, HORIZONTAL_ALIGNMENT_LEFT, true)
	_ui_button(side_area, "HARLOW MINES", 13, 210, 249, 48,
		_nav_to.bind("harlow"), "primary")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var destinations: Array[String] = ["hq", "harlow", "roster", "guildwork", "market", "finance", "ledger"]
		var index: int = int(event.keycode) - int(KEY_1)
		if index >= 0 and index < destinations.size():
			_nav_to(destinations[index])
