extends Control
## Money Mercs V0.2 — rebuilt interface.
## UI only. Game economy, expeditions and user:// saves stay in game_state.gd.
const Art = preload("res://scripts/ui_art.gd")
const HarlowView = preload("res://scripts/harlow_ui.gd")

const BG := Color("#0e1516")
const RAIL := Color("#111d1e")
const SURFACE := Color("#182525")
const SURFACE_2 := Color("#20312f")
const SURFACE_HOVER := Color("#2a3c37")
const EDGE := Color("#33443e")
const CREAM := Color("#f2ebd9")
const MUTED := Color("#9caaa3")
const FAINT := Color("#70867c")
const BRASS := Color("#d6b47a")
const BRASS_DARK := Color("#91764d")
const SUCCESS := Color("#97ceaa")
const DANGER := Color("#e3a093")

const PAGES := [
	["hq", "THE OFFICE", "01"],
	["harlow", "HARLOW MINES", "02"],
	["expeditions", "OTHER SITES", "03"],
	["roster", "THE CREW", "04"],
	["market", "THE EXCHANGE", "05"],
	["ledger", "THE JOURNAL", "06"]
]

var harlow_view
var game: MoneyMercsState
var page: String = "hq"
var selected_region: String = "lowlands"
var selected_merc: String = ""
var selected_item: String = "iron"
var selected_report: int = 0
var roster_tab: String = "employed"
var selected_crew: Array[String] = []
var tactic: String = "Balanced"
var reset_armed: bool = false

var content_root: VBoxContainer
var inspector_root: VBoxContainer
var inspector_actions: VBoxContainer
var header_gold: Label
var header_wealth: Label
var header_jobs: Label
var footer_notice: Label
var navigation: VBoxContainer
var mission_timers: Dictionary = {}
var mission_bars: Dictionary = {}

func _ready() -> void:
	game = MoneyMercsState.new()
	var finished: int = game.complete_due()
	_selected_first_merc()
	_build_shell()
	harlow_view = HarlowView.new(self)
	if finished > 0:
		_toast("%d field team(s) returned while you were away." % finished)
	else:
		_toast("Operations desk is open. Your company is ready.")
	_refresh()
	var clock := Timer.new()
	clock.wait_time = 1.0
	clock.autostart = true
	add_child(clock)
	clock.timeout.connect(_on_clock)

func _style(fill: Color, border: Color = EDGE, radius: int = 9, pad: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = pad
	style.content_margin_right = pad
	style.content_margin_top = pad
	style.content_margin_bottom = pad
	return style

func _h(gap: int = 10) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", gap)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node

func _v(gap: int = 9) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", gap)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node

func _label(value: String, font_size: int = 14, ink: Color = CREAM, uppercase: bool = false) -> Label:
	var node := Label.new()
	node.text = value.to_upper() if uppercase else value
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", ink)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node

func _line(parent: Node, color: Color = EDGE) -> void:
	var rule := ColorRect.new()
	rule.color = color
	rule.custom_minimum_size.y = 1
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rule)

func _spacer(parent: Node, pixels: int = 10) -> void:
	var s := Control.new()
	s.custom_minimum_size.y = pixels
	parent.add_child(s)

func _button(title: String, action: Callable, emph: bool = false, small: bool = false) -> Button:
	var node := Button.new()
	node.text = title
	node.focus_mode = Control.FOCUS_ALL
	node.custom_minimum_size.y = 34 if small else 44
	node.add_theme_font_size_override("font_size", 12 if small else 13)
	node.add_theme_color_override("font_color", BG if emph else CREAM)
	node.add_theme_color_override("font_hover_color", BG if emph else CREAM)
	node.add_theme_color_override("font_pressed_color", BG if emph else CREAM)
	node.add_theme_color_override("font_focus_color", BG if emph else CREAM)
	node.add_theme_stylebox_override("normal", _style(BRASS if emph else SURFACE_2, BRASS_DARK if emph else EDGE, 6, 10))
	node.add_theme_stylebox_override("hover", _style(Color("#eccd97") if emph else SURFACE_HOVER, BRASS, 6, 10))
	node.add_theme_stylebox_override("pressed", _style(Color("#caa267") if emph else Color("#30493e"), BRASS_DARK, 6, 10))
	node.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, BRASS, 6, 10))
	node.add_theme_stylebox_override("disabled", _style(SURFACE, EDGE, 6, 10))
	node.add_theme_color_override("font_disabled_color", FAINT)
	node.pressed.connect(action)
	return node

func _frame(parent: Node, selected: bool = false, pad: int = 17) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(SURFACE_2 if selected else SURFACE, BRASS_DARK if selected else EDGE, 9, pad))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var inside := _v(10)
	panel.add_child(inside)
	return inside

func _tag(title: String, tone: Color = MUTED) -> Label:
	var tag := _label(title, 10, tone, true)
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tag.add_theme_stylebox_override("normal", _style(SURFACE_2, EDGE, 4, 5))
	return tag

func _portrait(parent: Node, name: String, scale: int = 64) -> void:
	var art: Control = Art.new()
	art.kind = "portrait"
	art.variant = int(name.hash())
	art.custom_minimum_size = Vector2(scale, scale)
	art.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	parent.add_child(art)

func _illustration(parent: Node, id: String, height: int = 130) -> void:
	var art: Control = Art.new()
	art.kind = id
	art.custom_minimum_size.y = height
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(art)

func _field(parent: Node, heading: String, value: String, tint: Color = CREAM) -> void:
	var wrapper := _v(3)
	wrapper.add_child(_label(heading, 10, FAINT, true))
	wrapper.add_child(_label(value, 17, tint))
	parent.add_child(wrapper)

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _build_shell() -> void:
	var base := ColorRect.new()
	base.color = BG
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	var shell := _v(0)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shell)

	# Minimal, persistent treasury strip.
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", _style(RAIL, RAIL, 0, 0))
	shell.add_child(top)
	var top_pad := MarginContainer.new()
	top_pad.add_theme_constant_override("margin_left", 24)
	top_pad.add_theme_constant_override("margin_right", 27)
	top_pad.add_theme_constant_override("margin_top", 16)
	top_pad.add_theme_constant_override("margin_bottom", 16)
	top.add_child(top_pad)
	var top_row := _h(24)
	top_pad.add_child(top_row)
	var mark := _v(0)
	mark.custom_minimum_size.x = 198
	mark.add_child(_label("M / M", 26, BRASS))
	mark.add_child(_label("THE CONTRACTOR'S GUILD", 9, FAINT, true))
	top_row.add_child(mark)
	var intro := _v(1)
	intro.add_child(_label("MONEY MERCS", 18, CREAM, true))
	intro.add_child(_label("Build a fortune. Leave the danger to others.", 12, MUTED))
	top_row.add_child(intro)
	var flex := Control.new()
	flex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(flex)
	var money := _v(2)
	money.custom_minimum_size.x = 137
	money.add_child(_label("CASH ON HAND", 10, FAINT, true))
	header_gold = _label("—", 21, BRASS)
	money.add_child(header_gold)
	top_row.add_child(money)
	var worth := _v(2)
	worth.custom_minimum_size.x = 147
	worth.add_child(_label("COMPANY VALUE", 10, FAINT, true))
	header_wealth = _label("—", 21)
	worth.add_child(header_wealth)
	top_row.add_child(worth)
	var jobs := _v(2)
	jobs.custom_minimum_size.x = 110
	jobs.add_child(_label("IN THE FIELD", 10, FAINT, true))
	header_jobs = _label("—", 21, SUCCESS)
	jobs.add_child(header_jobs)
	top_row.add_child(jobs)

	var top_rule := ColorRect.new()
	top_rule.color = BRASS_DARK
	top_rule.custom_minimum_size.y = 2
	shell.add_child(top_rule)

	var layout := _h(0)
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(layout)
	# Navigation rail
	var nav_panel := PanelContainer.new()
	nav_panel.custom_minimum_size.x = 205
	nav_panel.add_theme_stylebox_override("panel", _style(RAIL, RAIL, 0, 0))
	layout.add_child(nav_panel)
	var nav_pad := MarginContainer.new()
	nav_pad.add_theme_constant_override("margin_left", 14)
	nav_pad.add_theme_constant_override("margin_right", 14)
	nav_pad.add_theme_constant_override("margin_top", 28)
	nav_pad.add_theme_constant_override("margin_bottom", 18)
	nav_panel.add_child(nav_pad)
	navigation = _v(11)
	nav_pad.add_child(navigation)

	# Work area. Content is scrollable, inspector stays in place.
	var center_margin := MarginContainer.new()
	center_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_margin.add_theme_constant_override("margin_left", 31)
	center_margin.add_theme_constant_override("margin_right", 31)
	center_margin.add_theme_constant_override("margin_top", 25)
	center_margin.add_theme_constant_override("margin_bottom", 17)
	layout.add_child(center_margin)
	var center_column := _v(18)
	center_margin.add_child(center_column)
	content_root = _v(14)
	var content_scroll := ScrollContainer.new()
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	center_column.add_child(content_scroll)
	content_scroll.add_child(content_root)

	# Right-hand contextual workbench.
	var inspect_panel := PanelContainer.new()
	inspect_panel.custom_minimum_size.x = 326
	inspect_panel.add_theme_stylebox_override("panel", _style(Color("#142220"), EDGE, 0, 0))
	layout.add_child(inspect_panel)
	var inspect_pad := MarginContainer.new()
	inspect_pad.add_theme_constant_override("margin_left", 21)
	inspect_pad.add_theme_constant_override("margin_right", 21)
	inspect_pad.add_theme_constant_override("margin_top", 27)
	inspect_pad.add_theme_constant_override("margin_bottom", 24)
	inspect_panel.add_child(inspect_pad)
	var inspect_column := _v(13)
	inspect_pad.add_child(inspect_column)
	inspect_column.add_child(_label("THE DESK / DETAILS", 11, BRASS, true))
	_line(inspect_column)
	var inspect_scroller := ScrollContainer.new()
	inspect_scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspect_scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inspect_column.add_child(inspect_scroller)
	inspector_root = _v(14)
	inspect_scroller.add_child(inspector_root)
	_line(inspect_column)
	inspector_actions = _v(9)
	inspect_column.add_child(inspector_actions)

	# Action feedback always stays visible.
	var bottom := PanelContainer.new()
	bottom.add_theme_stylebox_override("panel", _style(RAIL, RAIL, 0, 0))
	shell.add_child(bottom)
	var bottom_pad := MarginContainer.new()
	bottom_pad.add_theme_constant_override("margin_left", 22)
	bottom_pad.add_theme_constant_override("margin_right", 22)
	bottom_pad.add_theme_constant_override("margin_top", 8)
	bottom_pad.add_theme_constant_override("margin_bottom", 8)
	bottom.add_child(bottom_pad)
	var bottom_row := _h(10)
	bottom_pad.add_child(bottom_row)
	footer_notice = _label("Records ready.", 12, SUCCESS)
	bottom_row.add_child(footer_notice)
	var footer_tag := _label("LOCAL COMPANY  •  AUTOSAVE  •  V0.2", 10, FAINT, true)
	footer_tag.size_flags_horizontal = Control.SIZE_SHRINK_END
	bottom_row.add_child(footer_tag)

func _nav_to(next_page: String) -> void:
	page = next_page
	reset_armed = false
	_refresh()

func _update_navigation() -> void:
	_clear(navigation)
	navigation.add_child(_label("COMPANY RECORDS", 10, FAINT, true))
	_spacer(navigation, 7)
	for entry in PAGES:
		var key: String = str(entry[0])
		var title: String = str(entry[1])
		var index: String = str(entry[2])
		var btn := _button("%s   %s" % [index, title], _nav_to.bind(key), false, false)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if page == key:
			btn.add_theme_stylebox_override("normal", _style(SURFACE_2, BRASS_DARK, 7, 10))
			btn.add_theme_color_override("font_color", BRASS)
		else:
			btn.add_theme_stylebox_override("normal", _style(RAIL, RAIL, 7, 10))
		navigation.add_child(btn)
	_spacer(navigation, 25)
	_line(navigation)
	_spacer(navigation, 9)
	navigation.add_child(_label("YOUR CONTRACTORS", 10, FAINT, true))
	navigation.add_child(_label("%d employed  /  %d ready" % [game.crew.size(), game.free_crew()], 13))
	navigation.add_child(_label("%d reputation" % game.reputation, 12, MUTED))
	navigation.add_child(_label("%d / %d expedition slots" % [game.missions.size(), game.expedition_slots], 12, MUTED))

func _refresh() -> void:
	header_gold.text = _money(game.gold)
	header_gold.add_theme_color_override("font_color", DANGER if game.gold < 0 else BRASS)
	header_wealth.text = _money(game.wealth())
	header_jobs.text = "%d / %d" % [game.missions.size(), game.expedition_slots]
	_update_navigation()
	_clear(content_root)
	_clear(inspector_root)
	_clear(inspector_actions)
	mission_timers.clear()
	mission_bars.clear()
	match page:
		"hq": _home()
		"harlow": harlow_view.build()
		"expeditions": _expeditions()
		"roster": _roster()
		"market": _market()
		"ledger": _journal()

func _toast(message: String) -> void:
	if footer_notice != null:
		footer_notice.text = "●  " + message

func _action(message: String) -> void:
	_refresh()
	_toast(message)

func _title(overline: String, heading: String, caption: String) -> void:
	var block := _v(6)
	content_root.add_child(block)
	block.add_child(_label(overline, 11, BRASS, true))
	block.add_child(_label(heading, 31, CREAM))
	block.add_child(_label(caption, 14, MUTED))
	_spacer(content_root, 4)

func _inspector_title(overline: String, title: String, explanation: String = "") -> void:
	inspector_root.add_child(_label(overline, 10, BRASS, true))
	inspector_root.add_child(_label(title, 23, CREAM))
	if not explanation.is_empty():
		inspector_root.add_child(_label(explanation, 13, MUTED))

func _inspector_note(label_text: String, content: String, tone: Color = CREAM) -> void:
	var field := _v(3)
	field.add_child(_label(label_text, 10, FAINT, true))
	field.add_child(_label(content, 15, tone))
	inspector_root.add_child(field)

func _section(label_text: String) -> void:
	var line := _h(9)
	content_root.add_child(line)
	line.add_child(_label(label_text, 11, BRASS, true))
	_spacer(content_root, 1)

func _home() -> void:
	_title("THE OFFICE  /  YOUR COMPANY", "Every fortune starts somewhere.", "A guild is built on good contracts—and the judgment to know when to walk away.")
	# This illustrated title piece is intentionally not a dashboard card.
	var banner := _frame(content_root, false, 0)
	_illustration(banner, "banner", 176)
	var banner_info := _v(8)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 19)
	margin.add_theme_constant_override("margin_right", 19)
	margin.add_theme_constant_override("margin_bottom", 17)
	banner.add_child(margin)
	margin.add_child(banner_info)
	banner_info.add_child(_label("THE NEXT CONTRACT IS WAITING", 11, BRASS, true))
	var sentence: String = "Your crew is idle. Time to send them to work." if game.missions.is_empty() else "%d expedition(s) are under way. Your standing orders are in effect." % game.missions.size()
	banner_info.add_child(_label(sentence, 17))
	var banner_buttons := _h(10)
	banner_info.add_child(banner_buttons)
	banner_buttons.add_child(_button("PLAN HARLOW MINES  →", _nav_to.bind("harlow"), true))
	banner_buttons.add_child(_button("RECRUIT", _open_recruitment, false))
	_section("ACTIVE CONTRACTS")
	if game.missions.is_empty():
		var empty := _frame(content_root)
		empty.add_child(_label("NO TEAMS IN THE FIELD", 15))
		empty.add_child(_label("Dispatch a mercenary team to start earning. Time passes even while the game is closed.", 13, MUTED))
	else:
		for mission in game.missions:
			_mission_strip(content_root, mission)
	_section("YOUR BUSINESS AT A GLANCE")
	var overview := _h(12)
	content_root.add_child(overview)
	var cash_frame := _frame(overview)
	_field(cash_frame, "READY TO WORK", "%d mercenaries" % game.free_crew(), SUCCESS)
	_field(cash_frame, "COMPANY STANDING", "%d reputation" % game.reputation)
	var vault_frame := _frame(overview)
	_field(vault_frame, "UNSOLD INVENTORY", _money(_inventory_value()), BRASS)
	_field(vault_frame, "OPERATING CAPACITY", "%d team(s)" % game.expedition_slots)
	# Inspector: status and decisive quick actions.
	_inspector_title("YOUR DAY", "Contractor's desk", "Your next move should be obvious.")
	_line(inspector_root)
	if game.crew.is_empty():
		_inspector_note("FIRST PRIORITY", "Hire your first mercenary.", BRASS)
		_inspector_note("STARTING CAPITAL", _money(game.gold))
		inspector_actions.add_child(_button("VIEW RECRUITS  →", _open_recruitment, true))
	elif game.free_crew() > 0 and game.missions.size() < game.expedition_slots:
		_inspector_note("AVAILABLE CREW", "%d mercenary(s) ready" % game.free_crew(), SUCCESS)
		_inspector_note("READY TO DISPATCH", "Mossward Lowlands and unlocked expeditions are available.")
		inspector_actions.add_child(_button("PLAN HARLOW MINES  →", _nav_to.bind("harlow"), true))
	else:
		_inspector_note("FIELD ACTIVITY", "%d expedition(s) running" % game.missions.size(), BRASS)
		_inspector_note("DURING THE WAIT", "Review recent returns or turn your stash into working capital.")
		inspector_actions.add_child(_button("OPEN THE EXCHANGE  →", _nav_to.bind("market"), true))
	_line(inspector_root)
	_inspector_note("EXPEDITION SLOTS", "%d of 3 purchased" % game.expedition_slots)
	if game.expedition_slots < 3:
		var price: int = 900 if game.expedition_slots == 1 else 4200
		inspector_root.add_child(_label("Next slot: %s" % _money(price), 12, MUTED))
		inspector_actions.add_child(_button("BUY ADDITIONAL SLOT", func() -> void:
			_action(game.expand_operations())
		))

func _open_recruitment() -> void:
	roster_tab = "recruits"
	for candidate in MoneyMercsState.RECRUITS:
		if game.merc_by_id(str(candidate["id"])).is_empty():
			selected_merc = str(candidate["id"])
			break
	_nav_to("roster")

func _mission_strip(parent: Node, mission: Dictionary) -> void:
	var container := _frame(parent)
	var top := _h(12)
	container.add_child(top)
	var description := _v(3)
	var region: Dictionary = game.region_by_id(str(mission["region"]))
	description.add_child(_label("Harlow Mines" if str(mission.get("region", "")) == "harlow" else str(region.get("name", "Unknown site")), 17))
	description.add_child(_label("%d crew  ·  %s tactics" % [mission["ids"].size(), str(mission["tactic"])], 12, MUTED))
	top.add_child(description)
	var eta := _label("—", 15, BRASS)
	eta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(eta)
	mission_timers[str(mission["id"])] = eta
	var progress := ProgressBar.new()
	progress.custom_minimum_size.y = 7
	progress.show_percentage = false
	progress.add_theme_stylebox_override("background", _style(BG, BG, 3, 0))
	progress.add_theme_stylebox_override("fill", _style(BRASS, BRASS, 3, 0))
	container.add_child(progress)
	mission_bars[str(mission["id"])] = progress
	_update_timers()

func _expeditions() -> void:
	_title("OTHER SITES  /  EARLY PROTOTYPE", "Additional contracts", "These sites use the old expedition rules while Harlow Mines tests the new scouting and casualty system.")
	_section("CONTRACTS AVAILABLE")
	for region in MoneyMercsState.REGIONS:
		var id: String = str(region["id"])
		var unlocked: bool = game.reputation >= int(region["rep"])
		var card := _frame(content_root, selected_region == id, 12)
		var row := _h(16)
		card.add_child(row)
		var artwork := Art.new()
		artwork.kind = id
		artwork.custom_minimum_size = Vector2(158, 118)
		artwork.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		row.add_child(artwork)
		var col := _v(6)
		row.add_child(col)
		col.add_child(_label(str(region["name"]), 19, CREAM if unlocked else MUTED))
		col.add_child(_label("Threat %d   /   %s   /   supplies %s" % [int(region["threat"]), _duration(int(region["time"])), _money(int(region["supplies"]))], 12, MUTED))
		col.add_child(_label(_region_yield(region), 12, SUCCESS if unlocked else FAINT))
		var button_label := "SELECT CONTRACT   →" if unlocked else "REQUIRES %d REPUTATION" % int(region["rep"])
		var action_button := _button(button_label, _select_region.bind(id))
		action_button.disabled = not unlocked
		col.add_child(action_button)
	_section("OUT ON CONTRACT")
	if game.missions.is_empty():
		var info := _frame(content_root)
		info.add_child(_label("No deployed teams.", 14, MUTED))
	else:
		for mission in game.missions:
			_mission_strip(content_root, mission)
	_expedition_desk()

func _select_region(id: String) -> void:
	selected_region = id
	_refresh()

func _expedition_desk() -> void:
	var region: Dictionary = game.region_by_id(selected_region)
	if region.is_empty():
		return
	_inspector_title("EXPEDITION BRIEF", str(region["name"]), str(region["tagline"]))
	_illustration(inspector_root, str(region["id"]), 120)
	_inspector_note("RECOMMENDED", "%s specialist · threat %d" % [str(region["focus"]), int(region["threat"])])
	_line(inspector_root)
	inspector_root.add_child(_label("ASSIGN A CREW  /  UP TO THREE", 11, BRASS, true))
	var available: int = 0
	for merc in game.crew:
		if not game.is_available(merc):
			continue
		available += 1
		var id: String = str(merc["id"])
		var toggle := CheckBox.new()
		toggle.text = "%s  ·  %s" % [str(merc["name"]), str(merc["role"])]
		toggle.add_theme_font_size_override("font_size", 13)
		toggle.add_theme_color_override("font_color", CREAM)
		toggle.add_theme_color_override("font_hover_color", CREAM)
		toggle.set_pressed_no_signal(selected_crew.has(id))
		toggle.toggled.connect(_toggle_crew.bind(id))
		inspector_root.add_child(toggle)
	if available == 0:
		inspector_root.add_child(_label("No crew available. Hire or await their return.", 13, DANGER))
	inspector_root.add_child(_label("ORDERS", 11, BRASS, true))
	var order := OptionButton.new()
	for mode in MoneyMercsState.TACTICS:
		order.add_item(str(mode))
	order.select(maxi(0, MoneyMercsState.TACTICS.find(tactic)))
	order.add_theme_font_size_override("font_size", 13)
	order.add_theme_color_override("font_color", CREAM)
	order.add_theme_stylebox_override("normal", _style(SURFACE_2, EDGE, 6, 7))
	order.custom_minimum_size.y = 36
	order.item_selected.connect(_change_tactic)
	inspector_root.add_child(order)
	var selected: Array[String] = _valid_selected_crew()
	var chance: float = game.success_chance(region, selected, tactic)
	var cost: int = game.expedition_cost(region, selected)
	var share: float = 0.0
	for id in selected:
		var employee: Dictionary = game.merc_by_id(id)
		share += float(game.terms(employee)["cut"])
	_line(inspector_root)
	_inspector_note("ESTIMATED CHANCE", "%d%%" % int(round(chance * 100.0)), SUCCESS if chance >= 0.67 else DANGER)
	_inspector_note("UPFRONT COST", _money(cost), BRASS)
	_inspector_note("CREW SHARE OF HAUL", "%d%%" % int(round(minf(share, 0.85) * 100.0)))
	_inspector_note("DURATION", _duration(game.expedition_seconds(region, tactic)))
	var can_dispatch: bool = not selected.is_empty() and selected.size() <= 3 and game.gold >= cost and game.missions.size() < game.expedition_slots and game.reputation >= int(region["rep"])
	var submit := _button("FUND & DISPATCH   →", _dispatch, true)
	submit.disabled = not can_dispatch
	inspector_actions.add_child(submit)
	if selected.is_empty():
		inspector_actions.add_child(_label("Select at least one available mercenary.", 12, MUTED))
	elif selected.size() > 3:
		inspector_actions.add_child(_label("Maximum three mercenaries per job.", 12, DANGER))
	elif game.missions.size() >= game.expedition_slots:
		inspector_actions.add_child(_label("No operation slots available.", 12, DANGER))
	elif game.gold < cost:
		inspector_actions.add_child(_label("Insufficient gold to fund this mission.", 12, DANGER))

func _valid_selected_crew() -> Array[String]:
	var result: Array[String] = []
	for id in selected_crew:
		var merc: Dictionary = game.merc_by_id(id)
		if not merc.is_empty() and game.is_available(merc):
			result.append(id)
	return result

func _toggle_crew(on: bool, id: String) -> void:
	if on and not selected_crew.has(id):
		selected_crew.append(id)
	elif not on:
		selected_crew.erase(id)
	call_deferred("_refresh")

func _change_tactic(index: int) -> void:
	tactic = str(MoneyMercsState.TACTICS[index])
	call_deferred("_refresh")

func _dispatch() -> void:
	var selected: Array[String] = _valid_selected_crew()
	var message: String = game.dispatch(selected_region, selected, tactic)
	if message.begins_with("Expedition funded"):
		selected_crew.clear()
	_action(message)

func _selected_first_merc() -> void:
	for merc in game.crew:
		selected_merc = str(merc["id"])
		return
	selected_merc = "garrick"

func _roster() -> void:
	_title("PERSONNEL  /  CONTRACTS", "Good hands. Expensive promises.", "Build reliable crews without spending all your working capital.")
	var tabs := _h(10)
	content_root.add_child(tabs)
	var active_button := _button("ON PAYROLL  (%d)" % game.crew.size(), _roster_mode.bind("employed"), roster_tab == "employed")
	var recruit_button := _button("RECRUITMENT BOARD", _roster_mode.bind("recruits"), roster_tab == "recruits")
	tabs.add_child(active_button)
	tabs.add_child(recruit_button)
	if roster_tab == "employed":
		if game.crew.is_empty():
			var welcome := _frame(content_root)
			welcome.add_child(_label("YOUR ROSTER IS EMPTY", 18))
			welcome.add_child(_label("Hire a contractor. The cheapest hands make the first journeys possible.", 13, MUTED))
			welcome.add_child(_button("GO TO RECRUITMENT  →", _open_recruitment, true))
		for merc in game.crew:
			_merc_strip(merc, true)
	else:
		var found := false
		for merc in MoneyMercsState.RECRUITS:
			if not game.merc_by_id(str(merc["id"])).is_empty():
				continue
			found = true
			_merc_strip(merc, false)
		if not found:
			var done := _frame(content_root)
			done.add_child(_label("No remaining applicants.", 14, MUTED))
	_merc_desk()

func _roster_mode(tab: String) -> void:
	roster_tab = tab
	if tab == "employed":
		_selected_first_merc()
	else:
		for candidate in MoneyMercsState.RECRUITS:
			if game.merc_by_id(str(candidate["id"])).is_empty():
				selected_merc = str(candidate["id"])
				break
	_refresh()

func _merc_strip(merc: Dictionary, hired: bool) -> void:
	var id: String = str(merc["id"])
	var card := _frame(content_root, selected_merc == id, 12)
	var line := _h(12)
	card.add_child(line)
	_portrait(line, id, 72)
	var info := _v(5)
	line.add_child(info)
	info.add_child(_label(str(merc["name"]), 19, CREAM))
	info.add_child(_label("%s  ·  %s" % [str(merc["title"]), str(merc["role"])], 12, MUTED))
	var detail := "%d skill    /    %d gold hiring fee" % [int(merc["skill"]), int(merc["hire"])]
	if hired:
		detail = "%d health    /    gear tier %d    /    %s" % [int(merc.get("health", 100)), int(merc.get("gear", 0)), "AVAILABLE" if game.is_available(merc) else "IN FIELD"]
	info.add_child(_label(detail, 12, SUCCESS if hired and game.is_available(merc) else MUTED))
	var select_btn := _button("DETAILS  →", _select_merc.bind(id))
	select_btn.custom_minimum_size.x = 112
	line.add_child(select_btn)

func _select_merc(id: String) -> void:
	selected_merc = id
	_refresh()

func _merc_desk() -> void:
	var merc: Dictionary = game.merc_by_id(selected_merc) if roster_tab == "employed" else game.recruit_by_id(selected_merc)
	if merc.is_empty():
		_inspector_title("PERSONNEL FILE", "No selection", "Select a contractor to see the details.")
		return
	var hired: bool = roster_tab == "employed"
	_inspector_title("SIGNED CONTRACTOR" if hired else "AVAILABLE FOR HIRE", str(merc["name"]), str(merc["title"]))
	var portrait_line := _h(12)
	_portrait(portrait_line, str(merc["id"]), 96)
	var details := _v(5)
	details.add_child(_tag(str(merc["role"]), BRASS))
	details.add_child(_label("Base skill %d" % int(merc["skill"]), 15))
	details.add_child(_label("Hiring fee %s" % _money(int(merc["hire"])), 13, MUTED))
	portrait_line.add_child(details)
	inspector_root.add_child(portrait_line)
	_line(inspector_root)
	if hired:
		_inspector_note("STATUS", "In the field" if not game.is_available(merc) else "Available", BRASS if not game.is_available(merc) else SUCCESS)
		_inspector_note("HEALTH", "%d / 100" % int(merc["health"]), SUCCESS if int(merc["health"]) >= 70 else DANGER)
		_inspector_note("EXPERIENCE", str(int(merc["xp"])))
		_inspector_note("EQUIPMENT TIER", "%d / 4" % int(merc["gear"]))
		var terms: Dictionary = game.terms(merc)
		_line(inspector_root)
		_inspector_note("PAY AGREEMENT", str(merc["contract"]), BRASS)
		_inspector_note("WAGE PER MISSION", _money(int(terms["wage"])))
		_inspector_note("SHARE OF RECOVERED VALUE", "%d%%" % int(round(float(terms["cut"]) * 100.0)))
		inspector_actions.add_child(_button("CYCLE CONTRACT TERMS", func() -> void:
			_action(game.switch_contract(str(merc["id"])))
		))
		var tier: int = int(merc["gear"])
		if tier < 4:
			var cost: Dictionary = game.gear_cost(tier)
			inspector_actions.add_child(_button("IMPROVE GEAR", func() -> void:
				_action(game.improve_gear(str(merc["id"])))
			, true))
			inspector_actions.add_child(_label(game.cost_text(cost), 12, MUTED))
		else:
			inspector_actions.add_child(_tag("MYTHICAL EQUIPMENT", BRASS))
		if int(merc["health"]) < 100:
			inspector_actions.add_child(_button("TREAT WOUNDS", func() -> void:
				_action(game.treat(str(merc["id"])))
			))
	else:
		_inspector_note("ROLE", str(merc["role"]))
		_inspector_note("ASKING PRICE", _money(int(merc["hire"])), BRASS)
		_inspector_note("WAGE PER JOB", _money(int(merc["wage"])))
		_inspector_note("INITIAL LOOT SHARE", "%d%%" % int(round(float(merc["share"]) * 100.0)))
		inspector_root.add_child(_label("Contract type may be renegotiated after signing. Higher guaranteed wages reduce a contractor's share.", 12, MUTED))
		var hire_button := _button("SIGN CONTRACT  •  %s" % _money(int(merc["hire"])), _hire.bind(str(merc["id"])), true)
		hire_button.disabled = game.gold < int(merc["hire"])
		inspector_actions.add_child(hire_button)

func _hire(id: String) -> void:
	var result: String = game.hire(id)
	if result.contains("joined"):
		roster_tab = "employed"
		selected_merc = id
	_action(result)

func _market() -> void:
	_title("TRADE DESK  /  COMPANY STORES", "The exchange.", "Liquid gold keeps the company moving. Decide what deserves a place in your vault.")
	var intro := _frame(content_root)
	var top := _h(12)
	intro.add_child(top)
	_field(top, "UNSOLD RESOURCES", _money(_inventory_value()), BRASS)
	_field(top, "AVAILABLE CASH", _money(game.gold), SUCCESS if game.gold >= 0 else DANGER)
	_line(intro)
	intro.add_child(_label("MERCHANTS BUY AT 90% OF MARKET VALUE AND SELL AT 112%. PRICES SHIFT EVERY SIX HOURS.", 10, FAINT))
	_section("RESOURCE INVENTORY")
	var headings := _h(10)
	content_root.add_child(headings)
	var nm := _label("COMMODITY", 10, FAINT, true)
	headings.add_child(nm)
	var qty := _label("OWNED", 10, FAINT, true)
	qty.custom_minimum_size.x = 68
	qty.size_flags_horizontal = Control.SIZE_SHRINK_END
	headings.add_child(qty)
	var sell := _label("SELL / UNIT", 10, FAINT, true)
	sell.custom_minimum_size.x = 86
	sell.size_flags_horizontal = Control.SIZE_SHRINK_END
	headings.add_child(sell)
	for id in MoneyMercsState.RESOURCE_ORDER:
		var row := _frame(content_root, selected_item == id, 8)
		var cells := _h(10)
		row.add_child(cells)
		var title := _v(3)
		title.add_child(_label(str(MoneyMercsState.RESOURCE_NAMES[id]), 16, BRASS if id == "sovereign" else CREAM))
		title.add_child(_label("Exceptional" if id == "sovereign" else ("Rare" if id == "relic" else "Trade material"), 11, MUTED))
		cells.add_child(title)
		var count := _label(str(int(game.resources.get(id, 0))), 16)
		count.custom_minimum_size.x = 70
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.size_flags_horizontal = Control.SIZE_SHRINK_END
		cells.add_child(count)
		var value := _label(_money(game.sell_price(id)), 15, SUCCESS)
		value.custom_minimum_size.x = 86
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.size_flags_horizontal = Control.SIZE_SHRINK_END
		cells.add_child(value)
		cells.add_child(_button("VIEW", _select_item.bind(id), false, true))
	_market_desk()

func _select_item(id: String) -> void:
	selected_item = id
	_refresh()

func _market_desk() -> void:
	var id: String = selected_item
	_inspector_title("COMMODITY FILE", str(MoneyMercsState.RESOURCE_NAMES.get(id, id)), str(MoneyMercsState.RESOURCE_DESC.get(id, "")))
	var tint: Color = BRASS if id == "sovereign" else SUCCESS
	var orb := PanelContainer.new()
	orb.custom_minimum_size.y = 102
	orb.add_theme_stylebox_override("panel", _style(SURFACE, EDGE, 9, 0))
	inspector_root.add_child(orb)
	var glyph := _label("◆", 54, tint)
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	orb.add_child(glyph)
	_inspector_note("IN YOUR VAULT", "%d units" % int(game.resources.get(id, 0)))
	_inspector_note("MERCHANT BUYS AT", _money(game.sell_price(id)), SUCCESS)
	_inspector_note("MERCHANT SELLS AT", "Unavailable" if id == "sovereign" or id == "relic" else _money(game.buy_price(id)))
	_line(inspector_root)
	_inspector_note("TOTAL LIQUIDATION VALUE", _money(game.sell_price(id) * int(game.resources.get(id, 0))), BRASS)
	var amount: int = int(game.resources.get(id, 0))
	var sell_one := _button("SELL 1", _trade.bind(id, false, 1))
	sell_one.disabled = amount < 1
	inspector_actions.add_child(sell_one)
	var sell_all := _button("SELL ALL  •  %s" % _money(game.sell_price(id) * amount), _trade.bind(id, false, amount), true)
	sell_all.disabled = amount < 1
	inspector_actions.add_child(sell_all)
	if id != "sovereign" and id != "relic":
		var buy_one := _button("BUY 1  •  %s" % _money(game.buy_price(id)), _trade.bind(id, true, 1))
		buy_one.disabled = game.gold < game.buy_price(id)
		inspector_actions.add_child(buy_one)
	else:
		inspector_actions.add_child(_label("This commodity is unavailable from NPC merchants.", 12, FAINT))

func _trade(item: String, buying: bool, count: int) -> void:
	_action(game.trade(item, buying, count))

func _journal() -> void:
	_title("THE JOURNAL  /  COMPANY RECORDS", "Every job leaves a story.", "A running record of what the crew brought back, and what it really cost.")
	_section("RECENT EXPEDITION REPORTS")
	if game.reports.is_empty():
		var blank := _frame(content_root)
		blank.add_child(_label("THE JOURNAL IS EMPTY", 16, CREAM))
		blank.add_child(_label("When a mission finishes, its full result is filed here.", 13, MUTED))
	for index in range(game.reports.size()):
		var report: Dictionary = game.reports[index]
		var card := _frame(content_root, selected_report == index, 13)
		var row := _h(10)
		card.add_child(row)
		var info := _v(5)
		info.add_child(_label(str(report["region"]), 17))
		info.add_child(_label("SUCCESSFUL RETURN" if bool(report["won"]) else "FAILED EXPEDITION", 10, SUCCESS if bool(report["won"]) else DANGER, true))
		info.add_child(_label(_loot_text(report["loot"]), 12, MUTED))
		row.add_child(info)
		row.add_child(_button("READ REPORT", _select_report.bind(index), false, true))
	_journal_desk()

func _select_report(index: int) -> void:
	selected_report = index
	_refresh()

func _journal_desk() -> void:
	if game.reports.is_empty():
		_inspector_title("FIELD REPORT", "Awaiting news", "Your first return will be recorded here.")
	else:
		var index: int = clampi(selected_report, 0, game.reports.size() - 1)
		var r: Dictionary = game.reports[index]
		_inspector_title("AFTER-ACTION REPORT", str(r["region"]), "Successful expedition" if bool(r["won"]) else "Expedition ended in failure")
		_line(inspector_root)
		_inspector_note("RECOVERED MATERIALS", _loot_text(r["loot"]))
		_inspector_note("GOLD DISCOVERED", _money(int(r["cash"])), SUCCESS)
		_inspector_note("APPRAISED HAUL", _money(int(r["gross"])), BRASS)
		_inspector_note("PAID UPFRONT", _money(int(r["cost"])), DANGER)
		_inspector_note("CREW COMMISSION", _money(int(r["commission"])), DANGER)
		_line(inspector_root)
		_inspector_note("PROVISIONAL NET VALUE", _money(int(r["gross"]) - int(r["cost"]) - int(r["commission"])), SUCCESS if int(r["gross"]) >= int(r["cost"]) + int(r["commission"]) else DANGER)
		var dead: Array = r.get("casualties", [])
		var hurt: Array = r.get("injured", [])
		if not dead.is_empty():
			_line(inspector_root)
			_inspector_note("PERMANENT CASUALTIES / LOST GEAR", ", ".join(dead), DANGER)
		if not hurt.is_empty():
			_inspector_note("WOUNDED CONTRACTORS", ", ".join(hurt), DANGER)
		inspector_root.add_child(_label("Net value includes materials retained in the vault. It is not spendable cash.", 12, MUTED))
	if OS.is_debug_build():
		_spacer(inspector_root, 8)
		_line(inspector_root)
		inspector_root.add_child(_label("DEVELOPER TOOLS", 11, FAINT, true))
		inspector_root.add_child(_label("Test offline returns without waiting. These options are hidden in release builds.", 12, MUTED))
		inspector_actions.add_child(_button("ADVANCE TIME 15 MIN", func() -> void:
			_action(game.debug_skip(900))
		))
		if reset_armed:
			inspector_actions.add_child(_button("CONFIRM COMPANY RESET", _reset_company))
		else:
			inspector_actions.add_child(_button("RESET TEST SAVE...", _arm_reset))

func _arm_reset() -> void:
	reset_armed = true
	_refresh()
	_toast("Reset requires a second confirmation.")

func _reset_company() -> void:
	game.reset_company()
	selected_crew.clear()
	selected_report = 0
	roster_tab = "employed"
	_selected_first_merc()
	reset_armed = false
	_nav_to("hq")
	_toast("Company reset. New start: 350 gold.")

func _inventory_value() -> int:
	var value: int = 0
	for id in MoneyMercsState.RESOURCE_ORDER:
		value += int(game.resources.get(id, 0)) * game.sell_price(id)
	return value

func _region_yield(region: Dictionary) -> String:
	var names: Array[String] = []
	for item in region["loot"]:
		names.append(str(MoneyMercsState.RESOURCE_NAMES.get(item, item)))
	return "Yields: " + ", ".join(names)

func _loot_text(loot: Dictionary) -> String:
	var finds: Array[String] = []
	for id in loot:
		finds.append("%d %s" % [int(loot[id]), str(MoneyMercsState.RESOURCE_NAMES.get(id, id))])
	return ", ".join(finds) if not finds.is_empty() else "Nothing recovered."

func _money(value: int) -> String:
	var digits: String = str(absi(value))
	var result := ""
	for index in range(digits.length()):
		if index > 0 and (digits.length() - index) % 3 == 0:
			result += ","
		result += digits[index]
	return ("−" if value < 0 else "") + result + " G"

func _duration(seconds: int) -> String:
	if seconds <= 0:
		return "Returned"
	if seconds >= 3600:
		return "%dh %02dm" % [int(seconds / 3600), int(seconds / 60) % 60]
	if seconds >= 60:
		return "%dm %02ds" % [int(seconds / 60), seconds % 60]
	return "%ds" % seconds

func _update_timers() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	for mission in game.missions:
		var key: String = str(mission["id"])
		var remaining: int = maxi(0, int(mission["finish"]) - now)
		if mission_timers.has(key):
			var node: Label = mission_timers[key]
			if is_instance_valid(node):
				node.text = "RETURN IN " + _duration(remaining)
		if mission_bars.has(key):
			var bar: ProgressBar = mission_bars[key]
			if is_instance_valid(bar):
				var length: int = maxi(1, int(mission["finish"]) - int(mission["started"]))
				bar.value = clampf(100.0 * float(now - int(mission["started"])) / float(length), 0.0, 100.0)

func _on_clock() -> void:
	var changed: bool = game.harlow_sync()
	var finished: int = game.complete_due()
	if finished > 0:
		_refresh()
		_toast("%d team(s) returned. Their findings are in the journal." % finished)
	elif changed and page == "harlow":
		_refresh()
	else:
		_update_timers()
		if page == "harlow" and harlow_view != null:
			harlow_view.update_clock()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _nav_to("hq")
			KEY_2: _nav_to("harlow")
			KEY_3: _nav_to("expeditions")
			KEY_4: _nav_to("roster")
			KEY_5: _nav_to("market")
			KEY_6: _nav_to("ledger")
