extends Control

const BACKGROUND := Color("#0b1117")
const SIDEBAR := Color("#101a21")
const PANEL := Color("#17232b")
const PANEL_2 := Color("#20313a")
const BORDER := Color("#31434b")
const INK := Color("#e9e8dc")
const SUBTLE := Color("#a2b1b5")
const GOLD := Color("#ebc578")
const GREEN := Color("#76d0ab")
const RED := Color("#e58b7e")

var game: MoneyMercsState
var _page: String = "overview"
var _planning_region: String = ""
var _selected_ids: Array[String] = []
var _tactic: String = "Balanced"
var _reset_armed: bool = false

var _main_area: VBoxContainer
var _body: VBoxContainer
var _gold_display: Label
var _wealth_display: Label
var _notice_display: Label
var _nav_column: VBoxContainer
var _timer_labels: Dictionary = {}

func _ready() -> void:
	game = MoneyMercsState.new()
	game.complete_due()
	_make_shell()
	_render_page()
	var clock := Timer.new()
	clock.wait_time = 1.0
	clock.autostart = true
	add_child(clock)
	clock.timeout.connect(_clock_tick)

func _style(fill: Color, outline: Color, radius: int = 12, margin: int = 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = outline
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin
	s.content_margin_bottom = margin
	return s

func _col(space: int = 10) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.add_theme_constant_override("separation", space)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c

func _row(space: int = 12) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", space)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return r

func _text(value: String, size: int = 15, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _button(label: String, fn: Callable, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = label
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 39)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", BACKGROUND if primary else INK)
	b.add_theme_color_override("font_hover_color", BACKGROUND if primary else INK)
	b.add_theme_color_override("font_pressed_color", BACKGROUND if primary else INK)
	b.add_theme_stylebox_override("normal", _style(GOLD if primary else PANEL_2, GOLD if primary else BORDER, 8, 11))
	b.add_theme_stylebox_override("hover", _style(Color("#f7d895") if primary else Color("#30434d"), GOLD, 8, 11))
	b.add_theme_stylebox_override("pressed", _style(Color("#d5a952") if primary else Color("#3a5059"), GOLD, 8, 11))
	b.add_theme_stylebox_override("disabled", _style(Color("#20282c"), BORDER, 8, 11))
	b.pressed.connect(fn)
	return b

func _card(parent: Node, padding: int = 16) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(PANEL, BORDER, 12, padding))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var inside := _col(9)
	panel.add_child(inside)
	return inside

func _rule(parent: Node) -> void:
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", _style(BORDER, BORDER, 0, 0))
	parent.add_child(sep)

func _space(parent: Node, amount: float = 10.0) -> void:
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, amount)
	parent.add_child(sp)

func _pill(text_value: String, shade: Color = GOLD) -> Label:
	var p := Label.new()
	p.text = text_value.to_upper()
	p.add_theme_font_size_override("font_size", 11)
	p.add_theme_color_override("font_color", shade)
	p.add_theme_stylebox_override("normal", _style(PANEL_2, BORDER, 6, 6))
	return p

func _make_shell() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = BACKGROUND
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var frame := VBoxContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("separation", 0)
	add_child(frame)

	var upper := PanelContainer.new()
	upper.add_theme_stylebox_override("panel", _style(SIDEBAR, BORDER, 0, 15))
	frame.add_child(upper)
	var header := _row(24)
	upper.add_child(header)
	var identity := _col(0)
	identity.custom_minimum_size.x = 230
	identity.add_child(_text("MONEY / MERCS", 22, GOLD))
	identity.add_child(_text("YOUR FORTUNE. THEIR RISK.", 10, SUBTLE))
	header.add_child(identity)
	var stretch := Control.new()
	stretch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(stretch)
	var gold_box := _col(1)
	gold_box.custom_minimum_size.x = 145
	gold_box.add_child(_text("AVAILABLE GOLD", 10, SUBTLE))
	_gold_display = _text("", 23, GOLD)
	gold_box.add_child(_gold_display)
	header.add_child(gold_box)
	var wealth_box := _col(1)
	wealth_box.custom_minimum_size.x = 160
	wealth_box.add_child(_text("COMPANY VALUE", 10, SUBTLE))
	_wealth_display = _text("", 23, INK)
	wealth_box.add_child(_wealth_display)
	header.add_child(wealth_box)
	header.add_child(_button("SAVE COMPANY", func() -> void:
		game.save_game()
		_notify("Company records saved.")
	))

	var layout := _row(0)
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(layout)
	var side_panel := PanelContainer.new()
	side_panel.custom_minimum_size.x = 230
	side_panel.add_theme_stylebox_override("panel", _style(SIDEBAR, BORDER, 0, 16))
	layout.add_child(side_panel)
	_nav_column = _col(10)
	side_panel.add_child(_nav_column)
	
	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 27)
	content_margin.add_theme_constant_override("margin_right", 27)
	content_margin.add_theme_constant_override("margin_top", 21)
	content_margin.add_theme_constant_override("margin_bottom", 18)
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(content_margin)

	_main_area = _col(12)
	content_margin.add_child(_main_area)
	_notice_display = _text("Welcome to Money Mercs. Hire a crew to begin.", 13, GOLD)
	_notice_display.custom_minimum_size.y = 22
	frame.add_child(_notice_display)
	_notice_display.add_theme_stylebox_override("normal", _style(SIDEBAR, SIDEBAR, 0, 9))

func _update_nav() -> void:
	for child in _nav_column.get_children():
		_nav_column.remove_child(child)
		child.queue_free()
	_nav_column.add_child(_text("OPERATIONS", 11, SUBTLE))
	var pages := [
		["overview", "01   Headquarters"],
		["expeditions", "02   Expeditions"],
		["roster", "03   Mercenaries"],
		["market", "04   Marketplace"],
		["vault", "05   Resource Vault"],
		["ledger", "06   Company Ledger"]
	]
	for page in pages:
		var key: String = page[0]
		var label_value: String = page[1]
		var active := _page == key or (_page == "prepare" and key == "expeditions")
		var b := _button(label_value, _navigate.bind(key))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if active:
			b.add_theme_stylebox_override("normal", _style(PANEL_2, GOLD, 8, 11))
			b.add_theme_color_override("font_color", GOLD)
		_nav_column.add_child(b)
	_space(_nav_column, 10)
	_nav_column.add_child(_text("FIELD STATUS", 11, SUBTLE))
	var alive: int = game.crew.size()
	var active: int = game.missions.size()
	_nav_column.add_child(_text("%d / %d expeditions deployed" % [active, game.expedition_slots], 13, INK))
	_nav_column.add_child(_text("%d mercenaries on payroll" % alive, 13, SUBTLE))
	_space(_nav_column, 16)
	_nav_column.add_child(_text("LOCAL PROTOTYPE  •  V0.1", 10, SUBTLE))

func _navigate(page: String) -> void:
	_page = page
	_reset_armed = false
	_render_page()

func _render_page() -> void:
	_update_nav()
	_gold_display.text = _money(game.gold)
	_wealth_display.text = _money(game.wealth())
	for child in _main_area.get_children():
		_main_area.remove_child(child)
		child.queue_free()
	_timer_labels.clear()
	var head := _col(3)
	_main_area.add_child(head)
	var description: Dictionary = {
		"overview": ["HEADQUARTERS", "Build a company worth more than the mercenaries who risk their lives for it."],
		"expeditions": ["EXPEDITIONS", "Fund a crew, set standing orders, and bring the haul home."],
		"prepare": ["EXPEDITION BRIEFING", "A profitable mission is won before anybody leaves the gates."],
		"roster": ["MERCENARY ROSTER", "Experienced labor is expensive. Inexperienced labor is risky."],
		"market": ["TRADE EXCHANGE", "Buy low, sell high, and keep enough capital for tomorrow's wages."],
		"vault": ["RESOURCE VAULT", "Every handful of ore is one step closer to extraordinary wealth."],
		"ledger": ["COMPANY LEDGER", "Know exactly where every coin came from—and where it went."]
	}
	var title_data: Array = description.get(_page, description["overview"])
	head.add_child(_text(str(title_data[0]), 28, INK))
	head.add_child(_text(str(title_data[1]), 14, SUBTLE))
	var scroller := ScrollContainer.new()
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_main_area.add_child(scroller)
	_body = _col(17)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.add_child(_body)
	match _page:
		"overview": _overview()
		"expeditions": _expeditions()
		"prepare": _prepare()
		"roster": _roster()
		"market": _market()
		"vault": _vault()
		"ledger": _ledger()

func _notify(message: String) -> void:
	_notice_display.text = "  ◈   " + message

func _take_action(message: String) -> void:
	_notify(message)
	_render_page()

func _money(amount: int) -> String:
	return "%s g" % _commas(amount)

func _commas(amount: int) -> String:
	var negative := amount < 0
	var raw := str(absi(amount))
	var result := ""
	for i in range(raw.length()):
		if i > 0 and (raw.length() - i) % 3 == 0:
			result += ","
		result += raw[i]
	return ("-" if negative else "") + result

func _stat_card(parent: Node, title_value: String, value: String, helper: String, hue: Color = INK) -> void:
	var card := _card(parent)
	card.add_child(_text(title_value.to_upper(), 11, SUBTLE))
	card.add_child(_text(value, 24, hue))
	card.add_child(_text(helper, 12, SUBTLE))

func _overview() -> void:
	var hero := _card(_body, 22)
	hero.add_child(_pill("A COMPANY BUILT FROM NOTHING", GOLD))
	hero.add_child(_text("Fortune favors the prepared.", 26, INK))
	hero.add_child(_text("Recruit mercenaries, finance dangerous journeys, collect valuable materials, and grow your contracting business. Expeditions keep running when the game is closed.", 15, SUBTLE))
	var commands := _row()
	commands.add_child(_button("VIEW EXPEDITIONS  →", _navigate.bind("expeditions"), true))
	commands.add_child(_button("MANAGE MERCENARIES", _navigate.bind("roster")))
	hero.add_child(commands)
	var stats := _row()
	_body.add_child(stats)
	_stat_card(stats, "Available capital", _money(game.gold), "Cash pays wages and supplies.", GOLD)
	_stat_card(stats, "Reputation", str(game.reputation), "Unlocks harder contracts.")
	_stat_card(stats, "Mercenaries", str(game.crew.size()), "%d available for deployment" % game.free_crew())
	_stat_card(stats, "Vault valuation", _money(game.wealth() - game.gold), "Liquidation estimate + outfitting.")
	var columns := _row(16)
	_body.add_child(columns)
	var left := _col(15)
	var right := _col(15)
	columns.add_child(left)
	columns.add_child(right)
	var dispatch_card := _card(left)
	dispatch_card.add_child(_text("OPERATIONS BOARD", 17, GOLD))
	dispatch_card.add_child(_text("%d of %d expedition slots occupied" % [game.missions.size(), game.expedition_slots], 14))
	if game.missions.is_empty():
		dispatch_card.add_child(_text("No teams deployed. Hire someone, then send them to the Mossward Lowlands.", 13, SUBTLE))
	else:
		for mission in game.missions:
			var region := game.region_by_id(str(mission["region"]))
			dispatch_card.add_child(_text("• %s" % str(region.get("name", "Unknown region")), 13, INK))
	dispatch_card.add_child(_button("OPEN EXPEDITION BOARD", _navigate.bind("expeditions")))
	var company_card := _card(left)
	company_card.add_child(_text("CAPACITY EXPANSION", 17, GOLD))
	company_card.add_child(_text("A second expedition team means more opportunities, but also more up-front expenses.", 13, SUBTLE))
	var expansion_cost: int = 900 if game.expedition_slots == 1 else 4200
	if game.expedition_slots >= 3:
		company_card.add_child(_pill("MAXIMUM CAPACITY", GREEN))
	else:
		company_card.add_child(_button("PURCHASE SLOT  •  %s" % _money(expansion_cost), func() -> void:
			_take_action(game.expand_operations())
		))
	var company_note := _card(right)
	company_note.add_child(_text("LATEST DISPATCH REPORT", 17, GOLD))
	if game.reports.is_empty():
		company_note.add_child(_text("Your company's story has yet to be written. The first completed expedition will appear here.", 14, SUBTLE))
	else:
		var latest: Dictionary = game.reports[0]
		company_note.add_child(_pill("SUCCESS" if bool(latest["won"]) else "COSTLY RETURN", GREEN if bool(latest["won"]) else RED))
		company_note.add_child(_text(str(latest["region"]), 17))
		company_note.add_child(_text(_loot_text(latest["loot"]), 13, SUBTLE))
		company_note.add_child(_text("Commission: %s" % _money(int(latest["commission"])), 13, SUBTLE))
		company_note.add_child(_button("OPEN THE LEDGER", _navigate.bind("ledger")))
	var advice := _card(right)
	advice.add_child(_text("CONTRACTOR'S NOTES", 17, GOLD))
	advice.add_child(_text("Mercenary wages and supplies are paid before deployment. Each crew's negotiated share of the recovered value is settled when they return.", 13, SUBTLE))
	advice.add_child(_text("If a rare discovery creates a commission debt, sell part of your vault to fund the next job. A valuable haul isn't always liquid cash.", 13, SUBTLE))
	advice.add_child(_text("Your game saves after every transaction and automatically resolves overdue expeditions when reopened.", 12, GREEN))

func _expeditions() -> void:
	_body.add_child(_text("IN THE FIELD", 16, GOLD))
	if game.missions.is_empty():
		var empty := _card(_body)
		empty.add_child(_text("All crews are currently home.", 16))
		empty.add_child(_text("Assign one to a region below. You can safely close the game while they're away.", 13, SUBTLE))
	else:
		for mission in game.missions:
			var region := game.region_by_id(str(mission["region"]))
			var c := _card(_body)
			var r := _row()
			var info := _col(3)
			info.add_child(_text(str(region.get("name", "Unknown")), 18))
			info.add_child(_text("%d mercenaries  •  %s  •  %s funded" % [mission["ids"].size(), str(mission["tactic"]), _money(int(mission["cost"]))], 13, SUBTLE))
			r.add_child(info)
			var time_label := _text("", 17, GOLD)
			r.add_child(time_label)
			_timer_labels[str(mission["id"])] = time_label
			c.add_child(r)
			var bar := ProgressBar.new()
			bar.show_percentage = false
			bar.custom_minimum_size.y = 9
			var duration: float = maxf(1.0, float(int(mission["finish"]) - int(mission["started"])))
			bar.value = clampf(100.0 * float(Time.get_unix_time_from_system() - float(mission["started"])) / duration, 0.0, 100.0)
			c.add_child(bar)
		_update_countdowns()
	_body.add_child(_text("AVAILABLE REGIONS", 16, GOLD))
	for region in MoneyMercsState.REGIONS:
		var c := _card(_body, 19)
		var upper := _row(14)
		var descriptor := _col(4)
		descriptor.add_child(_text(str(region["name"]), 19))
		descriptor.add_child(_text(str(region["tagline"]), 14, SUBTLE))
		var meta := _row(7)
		meta.add_child(_pill("THREAT %d" % int(region["threat"])))
		meta.add_child(_pill("SUPPLIES %d G" % int(region["supplies"]), GREEN))
		meta.add_child(_pill("MIN. REP %d" % int(region["rep"])))
		descriptor.add_child(meta)
		upper.add_child(descriptor)
		var details := _col(5)
		details.custom_minimum_size.x = 240
		details.add_child(_text("MISSION TIME  •  %s" % _time_string(int(region["time"])), 13, GOLD))
		details.add_child(_text("Typical materials: %s" % _drop_text(region["loot"]), 12, SUBTLE))
		upper.add_child(details)
		c.add_child(upper)
		var can_go: bool = game.reputation >= int(region["rep"])
		var enter := _button("PLAN EXPEDITION  →" if can_go else "LOCKED  •  REPUTATION %d" % int(region["rep"]), _open_briefing.bind(str(region["id"])), can_go)
		enter.disabled = not can_go
		c.add_child(enter)

func _open_briefing(id: String) -> void:
	_planning_region = id
	_selected_ids.clear()
	for merc in game.crew:
		if game.is_available(merc) and _selected_ids.size() < 2:
			_selected_ids.append(str(merc["id"]))
	_tactic = "Balanced"
	_navigate("prepare")

func _on_crew_changed(pressed: bool, id: String) -> void:
	if pressed:
		if not _selected_ids.has(id):
			_selected_ids.append(id)
	else:
		_selected_ids.erase(id)
	call_deferred("_render_page")

func _on_tactic_changed(index: int) -> void:
	_tactic = MoneyMercsState.TACTICS[index]
	call_deferred("_render_page")

func _prepare() -> void:
	var region: Dictionary = game.region_by_id(_planning_region)
	if region.is_empty():
		_body.add_child(_text("Select a region from the expedition board.", 15, SUBTLE))
		return
	var title_card := _card(_body)
	title_card.add_child(_text(str(region["name"]), 23, GOLD))
	title_card.add_child(_text(str(region["tagline"]), 14, SUBTLE))
	title_card.add_child(_text("Threat %d   •   Recommended specialist: %s   •   Supplies: %s" % [int(region["threat"]), str(region["focus"]), _money(int(region["supplies"]))], 13))
	var c := _card(_body)
	c.add_child(_text("ASSIGN CREW (1 TO 3)", 16, GOLD))
	if game.free_crew() == 0:
		c.add_child(_text("Nobody is available. Recruit someone or await a returning crew.", 13, RED))
	for merc in game.crew:
		if not game.is_available(merc):
			continue
		var box := CheckBox.new()
		box.text = "%s   •   %s   •   Power %d   •   Health %d%%" % [str(merc["name"]), str(merc["role"]), game.merc_power(merc, region), int(merc["health"])]
		box.button_pressed = _selected_ids.has(str(merc["id"]))
		box.add_theme_font_size_override("font_size", 14)
		box.toggled.connect(_on_crew_changed.bind(str(merc["id"])))
		c.add_child(box)
	var tactics := _card(_body)
	tactics.add_child(_text("STANDING ORDERS", 16, GOLD))
	var pick := OptionButton.new()
	for tactic in MoneyMercsState.TACTICS:
		pick.add_item(tactic)
	pick.select(MoneyMercsState.TACTICS.find(_tactic))
	pick.item_selected.connect(_on_tactic_changed)
	tactics.add_child(pick)
	tactics.add_child(_text("Cautious: safer, slower, lower yield. Balanced: standard. Deep Push: faster with greater yield and casualty risk. Standing orders resolve the same way online or offline.", 13, SUBTLE))
	var summary := _card(_body)
	summary.add_child(_text("FINANCIAL & RISK FORECAST", 16, GOLD))
	var total_cost: int = game.expedition_cost(region, _selected_ids)
	var combined_share: float = 0.0
	for id in _selected_ids:
		var merc := game.merc_by_id(id)
		if not merc.is_empty():
			combined_share += float(game.terms(merc)["cut"])
	var rows := _row()
	_stat_card(rows, "Success estimate", "%d%%" % int(round(game.success_chance(region, _selected_ids, _tactic) * 100.0)), "Not a guaranteed outcome", GREEN)
	_stat_card(rows, "Upfront expense", _money(total_cost), "Wages plus supplies", GOLD)
	_stat_card(rows, "Crew's loot share", "%d%%" % int(round(minf(combined_share, 0.85) * 100.0)), "Settled on return")
	summary.add_child(rows)
	summary.add_child(_text("Estimated duration: %s  •  Slots in use: %d/%d" % [_time_string(game.expedition_seconds(region, _tactic)), game.missions.size(), game.expedition_slots], 13, SUBTLE))
	if _selected_ids.size() > 3:
		summary.add_child(_text("Maximum of three mercenaries per expedition.", 13, RED))
	var actions := _row()
	summary.add_child(actions)
	actions.add_child(_button("←  BACK TO BOARD", _navigate.bind("expeditions")))
	actions.add_child(_button("FUND & DISPATCH EXPEDITION", _send_expedition, true))

func _send_expedition() -> void:
	var result: String = game.dispatch(_planning_region, _selected_ids, _tactic)
	if result.begins_with("Expedition funded"):
		_page = "expeditions"
		_selected_ids.clear()
	_take_action(result)

func _roster() -> void:
	_body.add_child(_text("SIGNED CONTRACTORS  •  %d EMPLOYEES" % game.crew.size(), 16, GOLD))
	if game.crew.is_empty():
		var tip := _card(_body)
		tip.add_child(_text("Your company's roster is empty.", 17))
		tip.add_child(_text("Hiring is the first expense in the road to wealth. Garrick is an affordable starting recruit.", 13, SUBTLE))
	for merc in game.crew:
		var card := _card(_body)
		var upper := _row()
		var identity := _col(3)
		identity.add_child(_text("%s  /  %s" % [str(merc["name"]), str(merc["role"])], 19, INK))
		identity.add_child(_text(str(merc["title"]), 13, SUBTLE))
		upper.add_child(identity)
		var status: String = "AVAILABLE" if game.is_available(merc) else "ON EXPEDITION"
		upper.add_child(_pill(status, GREEN if game.is_available(merc) else GOLD))
		card.add_child(upper)
		var t: Dictionary = game.terms(merc)
		card.add_child(_text("Base power %d  •  Gear tier %d  •  Health %d%%  •  Experience %d" % [int(merc["skill"]), int(merc["gear"]), int(merc["health"]), int(merc["xp"])], 13, SUBTLE))
		card.add_child(_text("Contract: %s   |   %d gold per mission + %d%% of recovered value" % [str(merc["contract"]), int(t["wage"]), int(round(float(t["cut"]) * 100.0))], 13))
		var actions := _row()
		var merc_id: String = str(merc["id"])
		actions.add_child(_button("RENEGOTIATE", func() -> void:
			_take_action(game.switch_contract(merc_id))
		))
		var tier: int = int(merc["gear"])
		if tier < 4:
			actions.add_child(_button("UPGRADE GEAR  •  " + game.cost_text(game.gear_cost(tier)), func() -> void:
				_take_action(game.improve_gear(merc_id))
			))
		else:
			actions.add_child(_pill("MYTHICAL GEAR", GOLD))
		if int(merc["health"]) < 100:
			actions.add_child(_button("TREAT INJURY", func() -> void:
				_take_action(game.treat(merc_id))
			))
		card.add_child(actions)
	_body.add_child(_text("RECRUITMENT OFFICE", 16, GOLD))
	for candidate in MoneyMercsState.RECRUITS:
		if not game.merc_by_id(str(candidate["id"])).is_empty():
			continue
		var card := _card(_body)
		var row := _row()
		var info := _col(4)
		info.add_child(_text("%s   •   %s" % [str(candidate["name"]), str(candidate["role"])], 18))
		info.add_child(_text("%s  |  Base power %d  |  Wage %d gold  |  Standard share %d%%" % [str(candidate["title"]), int(candidate["skill"]), int(candidate["wage"]), int(round(float(candidate["share"]) * 100.0))], 13, SUBTLE))
		row.add_child(info)
		var price_button := _button("HIRE  •  %s" % _money(int(candidate["hire"])), func() -> void:
			_take_action(game.hire(str(candidate["id"])))
		, true)
		row.add_child(price_button)
		card.add_child(row)

func _market() -> void:
	var intro := _card(_body)
	intro.add_child(_text("MERCHANT EXCHANGE", 18, GOLD))
	intro.add_child(_text("NPC merchants provide baseline liquidity. Buying costs 12% above current valuation; selling returns 90%. Prices drift every six hours. Exceptional artifacts are expedition-only in this prototype.", 13, SUBTLE))
	for item in MoneyMercsState.RESOURCE_ORDER:
		var card := _card(_body, 14)
		var row := _row()
		var info := _col(3)
		info.add_child(_text(str(MoneyMercsState.RESOURCE_NAMES[item]), 17))
		info.add_child(_text("Held: %d   |   Merchant buys: %s   |   Merchant sells: %s" % [int(game.resources.get(item, 0)), _money(game.sell_price(item)), _money(game.buy_price(item))], 13, SUBTLE))
		row.add_child(info)
		row.add_child(_button("SELL 1", _trade.bind(item, false, 1)))
		row.add_child(_button("SELL ALL", _trade_all.bind(item)))
		if item != "sovereign" and item != "relic":
			row.add_child(_button("BUY 1", _trade.bind(item, true, 1)))
		card.add_child(row)

func _trade(item: String, buy: bool, amount: int) -> void:
	_take_action(game.trade(item, buy, amount))

func _trade_all(item: String) -> void:
	_take_action(game.trade(item, false, int(game.resources.get(item, 0))))

func _vault() -> void:
	var vault_total: int = 0
	for item in MoneyMercsState.RESOURCE_ORDER:
		vault_total += int(game.resources.get(item, 0)) * game.sell_price(item)
	var total_card := _card(_body)
	total_card.add_child(_text("ESTIMATED LIQUIDATION VALUE", 12, SUBTLE))
	total_card.add_child(_text(_money(vault_total), 28, GOLD))
	total_card.add_child(_text("A stash full of materials isn't the same thing as cash. Expedition commissions must still be settled in gold.", 13, SUBTLE))
	for item in MoneyMercsState.RESOURCE_ORDER:
		var amount: int = int(game.resources.get(item, 0))
		var card := _card(_body, 14)
		var row := _row()
		var info := _col(2)
		info.add_child(_text(str(MoneyMercsState.RESOURCE_NAMES[item]), 18, GOLD if item == "sovereign" else INK))
		info.add_child(_text(str(MoneyMercsState.RESOURCE_DESC[item]), 12, SUBTLE))
		row.add_child(info)
		var count := _col(2)
		count.custom_minimum_size.x = 135
		count.add_child(_text("IN VAULT", 10, SUBTLE))
		count.add_child(_text("%s units" % _commas(amount), 17))
		row.add_child(count)
		var worth := _col(2)
		worth.custom_minimum_size.x = 140
		worth.add_child(_text("SELL VALUE", 10, SUBTLE))
		worth.add_child(_text(_money(amount * game.sell_price(item)), 17, GREEN))
		row.add_child(worth)
		card.add_child(row)

func _ledger() -> void:
	var instructions := _card(_body)
	instructions.add_child(_text("EXPEDITION REPORTS", 18, GOLD))
	instructions.add_child(_text("Crew wages and supplies are paid upfront. Recovered gold is deposited on return, while commission is assessed against the entire recovered haul at its prevailing market value.", 13, SUBTLE))
	if game.reports.is_empty():
		var none := _card(_body)
		none.add_child(_text("Nothing to report yet.", 16, SUBTLE))
	for report in game.reports:
		var card := _card(_body)
		var heading := _row()
		var left := _col(3)
		left.add_child(_text(str(report["region"]), 18, INK))
		left.add_child(_text("Approach: %s  •  Initial cost: %s" % [str(report["tactic"]), _money(int(report["cost"]))], 12, SUBTLE))
		heading.add_child(left)
		heading.add_child(_pill("SUCCESS" if bool(report["won"]) else "FAILED", GREEN if bool(report["won"]) else RED))
		card.add_child(heading)
		card.add_child(_text("RECEIVED: " + _loot_text(report["loot"]), 13))
		card.add_child(_text("Found gold: %s   |   Gross haul value: %s   |   Crew commission: %s" % [_money(int(report["cash"])), _money(int(report["gross"])), _money(int(report["commission"]))], 13, SUBTLE))
	_space(_body, 8)
	if OS.is_debug_build():
		var debug := _card(_body)
		debug.add_child(_text("DEVELOPER TEST TOOLS", 17, GOLD))
		debug.add_child(_text("Only visible in debug builds. Simulates elapsed expedition time to verify offline settlement.", 12, SUBTLE))
		debug.add_child(_button("ADVANCE EXPEDITIONS BY 15 MIN", func() -> void:
			_take_action(game.debug_skip(900))
		))
		if _reset_armed:
			debug.add_child(_button("CONFIRM FULL COMPANY RESET", func() -> void:
				game.reset_company()
				_reset_armed = false
				_take_action("Company reset. A new contractor begins with 350 gold.")
			))
		else:
			debug.add_child(_button("RESET TEST COMPANY", func() -> void:
				_reset_armed = true
				_render_page()
			))

func _drop_text(table: Dictionary) -> String:
	var names: Array[String] = []
	for id in table:
		names.append(str(MoneyMercsState.RESOURCE_NAMES.get(id, id)))
	return ", ".join(names)

func _loot_text(loot: Dictionary) -> String:
	if loot.is_empty():
		return "No materials recovered."
	var parts: Array[String] = []
	for item in loot:
		parts.append("%d %s" % [int(loot[item]), str(MoneyMercsState.RESOURCE_NAMES.get(item, item))])
	return ", ".join(parts)

func _time_string(seconds: int) -> String:
	if seconds <= 0:
		return "RETURNED"
	if seconds >= 3600:
		return "%dh %02dm" % [int(seconds / 3600), int(seconds / 60) % 60]
	if seconds >= 60:
		return "%dm %02ds" % [int(seconds / 60), seconds % 60]
	return "%ds" % seconds

func _update_countdowns() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	for mission in game.missions:
		var id: String = str(mission["id"])
		if _timer_labels.has(id) and is_instance_valid(_timer_labels[id]):
			var remaining: int = maxi(0, int(mission["finish"]) - now)
			(_timer_labels[id] as Label).text = "RETURN IN " + _time_string(remaining)

func _clock_tick() -> void:
	var finished: int = game.complete_due()
	if finished > 0:
		_notify("%d expedition(s) returned. Open the ledger to inspect the haul." % finished)
		_render_page()
	else:
		_update_countdowns()
