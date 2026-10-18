extends RefCounted
## Harlow Mines: a focused vertical-slice UI, built on the shared Money Mercs design system.
## All information here is derived from persistent game state; no mock decisions.

const CREAM := Color("#f2ebd9")
const MUTED := Color("#9caaa3")
const FAINT := Color("#70867c")
const BRASS := Color("#d6b47a")
const SUCCESS := Color("#97ceaa")
const DANGER := Color("#e3a093")
const SURFACE_2 := Color("#20312f")
const EDGE := Color("#33443e")

var ui: Control
var selected: Array[String] = []
var stance: String = "Balanced"
var clock_label: Label
var scout_clock: Label

func _init(owner: Control) -> void:
	ui = owner

func _text(value: String, size: int = 13, color: Color = Color("#f2ebd9")) -> Label:
	return ui._label(value, size, color)

func _tag(label_text: String, color: Color = Color("#d6b47a")) -> Label:
	return ui._tag(label_text, color)

func _headline(parent: Node, title: String, extra: String, tint: Color) -> void:
	var headline := ui._h(10)
	parent.add_child(headline)
	headline.add_child(ui._label(title, 15, tint, true))
	var right := ui._label(extra, 11, FAINT)
	right.size_flags_horizontal = Control.SIZE_SHRINK_END
	headline.add_child(right)

func build() -> void:
	var game: MoneyMercsState = ui.game
	game.harlow_sync()
	var state: Dictionary = game.harlow
	var intel: Dictionary = state.get("report", {})
	var has_intel: bool = not intel.is_empty()
	ui._title("FIELD DOSSIER   /   ACTIVE REGION", "Harlow Mines", "The mountain changes. Your decisions determine who comes home.")

	# Hero illustration and restrained visual hierarchy.
	var hero := ui._frame(ui.content_root, true, 0)
	ui._illustration(hero, "ironworks", 167)
	var inset := MarginContainer.new()
	inset.add_theme_constant_override("margin_left", 18)
	inset.add_theme_constant_override("margin_right", 18)
	inset.add_theme_constant_override("margin_bottom", 16)
	hero.add_child(inset)
	var below := ui._v(9)
	inset.add_child(below)
	var status := ui._h(12)
	below.add_child(status)
	status.add_child(_tag("SURVEY COMPLETE" if has_intel else ("SCOUT IN THE FIELD" if int(state["scout_finish"]) > 0 else "UNSURVEYED"), SUCCESS if has_intel else BRASS))
	status.add_child(_tag("REGION 01  /  MINING DISTRICT", MUTED))
	var meta := ui._h(12)
	below.add_child(meta)
	_item_metric(meta, "NEXT ROTATION", _remaining(game.harlow_rotation_remaining()), BRASS)
	_item_metric(meta, "OPERATIONS RUNNING", "%d" % _harlow_jobs(), CREAM)
	_item_metric(meta, "SCOUT TIER", "%d / 3" % int(state.get("scout_level", 1)), SUCCESS)
	clock_label = meta.get_child(0).get_child(1) as Label

	ui._spacer(ui.content_root, 4)
	# Scouting represents the source of the expedition's knowledge.
	var report := ui._frame(ui.content_root, false, 19)
	_headline(report, "01  /  SCOUT'S REPORT", "INTELLIGENCE", BRASS)
	ui._line(report)
	if has_intel:
		_render_intelligence(report, state, intel)
	elif int(state["scout_finish"]) > 0:
		report.add_child(_text("A guild scout is surveying the lower shafts.", 17, CREAM))
		scout_clock = _text("", 13, SUCCESS)
		report.add_child(scout_clock)
		report.add_child(_text("The scout cannot die. Intelligence will be delivered even if you close the game.", 12, MUTED))
	else:
		report.add_child(_text("No current intelligence.", 18, CREAM))
		report.add_child(_text("You may send a crew blindly, but an upgraded scout will reveal valuable deposits and threats before you commit equipment.", 13, MUTED))
		var scout_button := ui._button("DISPATCH GUILD SCOUT   /   %s" % _remaining(game.harlow_scout_seconds()), _scout, true)
		report.add_child(scout_button)
	var upgrade_row := ui._h(8)
	report.add_child(upgrade_row)
	var upgrade_info := ui._v(3)
	upgrade_row.add_child(upgrade_info)
	upgrade_info.add_child(_text("SURVEY TRAINING", 11, FAINT))
	var tier: int = int(state.get("scout_level", 1))
	var cost: int = 200 if tier == 1 else 650
	upgrade_info.add_child(_text("Faster return, more accurate intel" if tier < 3 else "Master scout fully trained", 12, MUTED))
	if tier < 3:
		var upgrade := ui._button("TRAIN  •  %s" % ui._money(cost), _upgrade, false, true)
		upgrade.disabled = game.gold < cost or int(state["scout_finish"]) > 0
		upgrade_row.add_child(upgrade)
	else:
		upgrade_row.add_child(_tag("MAX LEVEL", SUCCESS))

	ui._spacer(ui.content_root, 5)
	# Role cards and predictable choices.
	var crew_box := ui._frame(ui.content_root, false, 18)
	_headline(crew_box, "02  /  DEPLOY YOUR CREW", "UP TO THREE", BRASS)
	ui._line(crew_box)
	var choices := ui._h(12)
	crew_box.add_child(choices)
	var guard_summary := ui._frame(choices, false, 12)
	guard_summary.add_child(_text("SHIELD   /   GUARD", 10, MUTED))
	guard_summary.add_child(_text("Protection", 18, CREAM))
	guard_summary.add_child(_text("Reduces the chance of fatal encounters.", 12, MUTED))
	var miner_summary := ui._frame(choices, false, 12)
	miner_summary.add_child(_text("PICKAXE   /   MINER", 10, MUTED))
	miner_summary.add_child(_text("Extraction", 18, CREAM))
	miner_summary.add_child(_text("Up to three ore veins per miner.", 12, MUTED))
	var available := 0
	for merc in game.crew:
		if not game.is_available(merc):
			continue
		if str(merc.get("role", "")) != "Miner" and str(merc.get("role", "")) != "Guard":
			continue
		available += 1
		_worker_entry(crew_box, merc)
	if available == 0:
		crew_box.add_child(_text("You have no miners or guards available. Recruit a miner and a guard to prepare Harlow Mines.", 13, DANGER))
		crew_box.add_child(ui._button("OPEN RECRUITMENT BOARD  →", _recruit, true))
	elif _selected_available().is_empty():
		crew_box.add_child(_text("Select at least one miner to start planning. Guards are strongly recommended.", 12, MUTED))
	ui._line(crew_box)
	var status_row := ui._h(7)
	crew_box.add_child(status_row)
	var selected_stats: Dictionary = game.harlow_crew_stats(_selected_available(), stance)
	status_row.add_child(_tag("%d MINERS" % int(selected_stats["miners"]), SUCCESS))
	status_row.add_child(_tag("%d GUARDS" % int(selected_stats["guards"]), BRASS))
	status_row.add_child(_tag("%d VEIN CAPACITY" % int(selected_stats["capacity"]), CREAM))

	ui._spacer(ui.content_root, 5)
	ui._section("IN PROGRESS")
	if _harlow_jobs() == 0:
		var empty := ui._frame(ui.content_root)
		empty.add_child(_text("No crews underground right now.", 13, MUTED))
	else:
		for mission in game.missions:
			if str(mission.get("region", "")) == "harlow":
				ui._mission_strip(ui.content_root, mission)

	_render_inspector(state, has_intel, selected_stats)
	update_clock()

func _item_metric(row: Node, label_text: String, value: String, shade: Color) -> void:
	var content := ui._v(4)
	row.add_child(content)
	content.add_child(ui._label(label_text, 10, FAINT, true))
	content.add_child(ui._label(value, 18, shade))

func _render_intelligence(parent: Node, state: Dictionary, intel: Dictionary) -> void:
	var headline := ui._h(12)
	parent.add_child(headline)
	var primary := ui._v(5)
	headline.add_child(primary)
	primary.add_child(_text("KNOWN ORE", 10, FAINT))
	primary.add_child(_text("At least %d %s veins" % [int(intel.get("minimum", 0)), str(MoneyMercsState.RESOURCE_NAMES.get(str(intel["primary"]), "ore"))], 19, SUCCESS))
	primary.add_child(_text("Measured this rotation  ·  available deposits decline after extraction", 12, MUTED))
	var creature := ui._v(5)
	headline.add_child(creature)
	creature.add_child(_text("CONFIRMED THREAT", 10, FAINT))
	creature.add_child(_text(str(intel.get("creature", "Unknown")), 18, DANGER))
	creature.add_child(_text(str((state.get("enemy", {}) as Dictionary).get("note", "Threat detected")), 12, MUTED))
	if intel.has("all_ore"):
		ui._line(parent)
		var deposits: Dictionary = intel["all_ore"]
		var names: Array[String] = []
		for id in ["copper", "iron", "silver", "crystal"]:
			if int(deposits.get(id, 0)) > 0:
				var quantity: String = "%d" % int(deposits[id])
				if not bool(intel.get("exact", false)):
					quantity += "+"
				names.append("%s %s" % [quantity, str(MoneyMercsState.RESOURCE_NAMES.get(id,id))])
		parent.add_child(_text("ADDITIONAL INTEL  •  " + ", ".join(names), 12, CREAM))
	parent.add_child(_text("Your report is a lower bound, not a full guarantee of safety or total resources." if not bool(intel.get("exact", false)) else "Master scout: resource counts are exact at report time; other expeditions can still deplete them.", 12, MUTED))

func _worker_entry(parent: Node, merc: Dictionary) -> void:
	var id: String = str(merc["id"])
	var row := ui._h(10)
	parent.add_child(row)
	var checkbox := CheckBox.new()
	checkbox.text = "%s   /   %s" % [str(merc["name"]), str(merc["role"])]
	checkbox.custom_minimum_size.x = 250
	checkbox.set_pressed_no_signal(selected.has(id))
	checkbox.add_theme_font_size_override("font_size", 13)
	checkbox.add_theme_color_override("font_color", CREAM)
	checkbox.add_theme_color_override("font_hover_color", CREAM)
	checkbox.add_theme_color_override("font_pressed_color", CREAM)
	checkbox.toggled.connect(_toggle.bind(id))
	row.add_child(checkbox)
	var details: Label = _text("LVL %d GEAR   /   %d%% HEALTH" % [int(merc.get("gear", 0)), int(merc.get("health", 100))], 11, MUTED)
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(details)

func _toggle(active: bool, id: String) -> void:
	if active and not selected.has(id):
		selected.append(id)
	elif not active:
		selected.erase(id)
	call_deferred("_refresh")

func _selected_available() -> Array[String]:
	var game: MoneyMercsState = ui.game
	var result: Array[String] = []
	for id in selected:
		var merc: Dictionary = game.merc_by_id(id)
		if not merc.is_empty() and game.is_available(merc) and (str(merc.get("role")) == "Miner" or str(merc.get("role")) == "Guard"):
			result.append(id)
	return result

func _render_inspector(state: Dictionary, has_intel: bool, stats: Dictionary) -> void:
	var game: MoneyMercsState = ui.game
	ui._inspector_title("THE QUARTERMASTER   /   LIVE FORECAST", "Dispatch plan", "Compare yield against risk before you send anyone into danger.")
	ui._line(ui.inspector_root)
	ui._inspector_note("STANDING ORDERS", "How hard should the crew push?", BRASS)
	var picker := OptionButton.new()
	for option in MoneyMercsState.TACTICS:
		picker.add_item(str(option))
	picker.select(maxi(0, MoneyMercsState.TACTICS.find(stance)))
	picker.add_theme_font_size_override("font_size", 13)
	picker.add_theme_color_override("font_color", CREAM)
	picker.add_theme_stylebox_override("normal", ui._style(SURFACE_2, EDGE, 6, 8))
	picker.custom_minimum_size.y = 38
	picker.item_selected.connect(_stance_change)
	ui.inspector_root.add_child(picker)
	ui._line(ui.inspector_root)
	ui._inspector_note("MAXIMUM ORE VEINS", str(int(stats["capacity"])), SUCCESS)
	if has_intel:
		ui._inspector_note("FULL OBJECTIVE SUCCESS", "%d%% estimated" % int(round(float(stats["success"]) * 100.0)), SUCCESS if float(stats["success"]) >= 0.70 else DANGER)
		ui._inspector_note("PER-WORKER DEATH RISK", "~%d%% estimated" % int(round(float(stats["death"]) * 100.0)), DANGER)
	else:
		ui._inspector_note("SUCCESS / FATALITY RISK", "Unknown · survey required", DANGER)
		ui.inspector_root.add_child(_text("You may deploy without a report, but no estimated odds are shown until you scout.", 12, MUTED))
	ui._inspector_note("COST TO DISPATCH", ui._money(int(stats["wage"])), BRASS)
	ui._inspector_note("EXPECTED DURATION", _remaining(int(stats["duration"])), CREAM)
	var gear_at_risk := 0
	var commission := 0.0
	for merc_id in _selected_available():
		var merc: Dictionary = game.merc_by_id(merc_id)
		gear_at_risk += int(merc.get("gear", 0))
		commission += float(game.terms(merc)["cut"])
	ui._inspector_note("GEAR EXPOSED TO LOSS", "%d equipped upgrade tiers" % gear_at_risk)
	ui._inspector_note("CREW SHARE OF FINDINGS", "%d%%" % int(round(minf(commission, 0.85) * 100.0)))
	ui._line(ui.inspector_root)
	var warning := ui._frame(ui.inspector_root)
	warning.add_child(_text("PERMANENT CASUALTIES", 11, DANGER))
	warning.add_child(_text("Mercenaries can die. Their experience and equipped gear will be lost permanently.", 12, MUTED))
	var valid: Array[String] = _selected_available()
	var veins := 0
	for key in (state.get("deposits", {}) as Dictionary):
		veins += int((state["deposits"] as Dictionary)[key])
	var can_send: bool = valid.size() >= 1 and valid.size() <= 3 and int(stats["miners"]) >= 1 and veins > 0 and game.gold >= int(stats["wage"]) and game.missions.size() < game.expedition_slots
	var go := ui._button("FUND EXPEDITION   →", _dispatch, true)
	go.disabled = not can_send
	ui.inspector_actions.add_child(go)
	if valid.size() > 3:
		ui.inspector_actions.add_child(_text("Only three mercenaries can deploy together.", 12, DANGER))
	elif int(stats["miners"]) == 0:
		ui.inspector_actions.add_child(_text("At least one miner must be assigned.", 12, MUTED))
	elif game.gold < int(stats["wage"]):
		ui.inspector_actions.add_child(_text("Insufficient gold. Sell a resource or reduce crew cost.", 12, DANGER))
	elif veins <= 0:
		ui.inspector_actions.add_child(_text("All ore deposits are exhausted until rotation.", 12, MUTED))
	elif game.missions.size() >= game.expedition_slots:
		ui.inspector_actions.add_child(_text("All operation slots are occupied.", 12, MUTED))
	else:
		ui.inspector_actions.add_child(_text("Standing orders execute the same way while you are offline.", 12, MUTED))

func _remaining(seconds: int) -> String:
	if seconds >= 3600:
		return "%dh %02dm" % [int(seconds / 3600), int(seconds / 60) % 60]
	if seconds >= 60:
		return "%dm %02ds" % [int(seconds / 60), seconds % 60]
	return "%ds" % maxi(0, seconds)

func _harlow_jobs() -> int:
	var total := 0
	for job in ui.game.missions:
		if str(job.get("region", "")) == "harlow":
			total += 1
	return total

func _scout() -> void:
	_action(ui.game.harlow_send_scout())

func _upgrade() -> void:
	_action(ui.game.harlow_upgrade_scout())

func _dispatch() -> void:
	var response: String = ui.game.harlow_dispatch(_selected_available(), stance)
	if response.begins_with("Harlow expedition funded"):
		selected.clear()
	_action(response)

func _stance_change(index: int) -> void:
	stance = str(MoneyMercsState.TACTICS[index])
	call_deferred("_refresh")

func _recruit() -> void:
	ui._open_recruitment()

func _refresh() -> void:
	ui._refresh()

func _action(message: String) -> void:
	ui._action(message)

func update_clock() -> void:
	if clock_label != null and is_instance_valid(clock_label):
		clock_label.text = _remaining(ui.game.harlow_rotation_remaining())
	if scout_clock != null and is_instance_valid(scout_clock):
		var finished: int = int(ui.game.harlow.get("scout_finish", 0))
		scout_clock.text = "REPORT IN  " + _remaining(maxi(0, finished - int(Time.get_unix_time_from_system())))
