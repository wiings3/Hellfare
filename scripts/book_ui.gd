extends "res://scripts/book_shell.gd"
## Active book screens: page content and interactions only.
## Every page layout is an editor scene under scenes/journal/pages/; this script
## only binds live game data, connects buttons and instances repeating rows.

const COMPANY_LEFT := preload("res://scenes/journal/pages/company_left.tscn")
const COMPANY_RIGHT := preload("res://scenes/journal/pages/company_right.tscn")
const FINANCE_LEFT := preload("res://scenes/journal/pages/finance_left.tscn")
const FINANCE_RIGHT := preload("res://scenes/journal/pages/finance_right.tscn")
const HARLOW_LEFT := preload("res://scenes/journal/pages/harlow_left.tscn")
const HARLOW_RIGHT := preload("res://scenes/journal/pages/harlow_right.tscn")
const EXCHANGE_LEFT := preload("res://scenes/journal/pages/exchange_left.tscn")
const EXCHANGE_RIGHT := preload("res://scenes/journal/pages/exchange_right.tscn")
const GUILDWORK_LEFT := preload("res://scenes/journal/pages/guildwork_left.tscn")
const GUILDWORK_RIGHT := preload("res://scenes/journal/pages/guildwork_right.tscn")
const CHRONICLE_LEFT := preload("res://scenes/journal/pages/chronicle_left.tscn")
const CHRONICLE_RIGHT := preload("res://scenes/journal/pages/chronicle_right.tscn")
const REGIONS_LEFT := preload("res://scenes/journal/pages/regions_left.tscn")
const REGIONS_RIGHT := preload("res://scenes/journal/pages/regions_right.tscn")
const PERSONNEL_TABS := preload("res://scenes/journal/pages/personnel_tabs.tscn")
const PERSONNEL_EMPLOYEES_LEFT := preload("res://scenes/journal/pages/personnel_employed_left.tscn")
const PERSONNEL_EMPLOYEES_RIGHT := preload("res://scenes/journal/pages/personnel_employed_right.tscn")
const PERSONNEL_RECRUITS_LEFT := preload("res://scenes/journal/pages/personnel_recruits_left.tscn")
const PERSONNEL_RECRUITS_RIGHT := preload("res://scenes/journal/pages/personnel_recruits_right.tscn")
const PERSONNEL_ARMORY_LEFT := preload("res://scenes/journal/pages/personnel_armory_left.tscn")
const PERSONNEL_ARMORY_RIGHT := preload("res://scenes/journal/pages/personnel_armory_right.tscn")
const ROW_CREW_SLOT := preload("res://scenes/journal/rows/crew_slot.tscn")
const ROW_ROSTER_CARD := preload("res://scenes/journal/rows/roster_card.tscn")
const ROW_EXPEDITION := preload("res://scenes/journal/rows/expedition_row.tscn")
const ROW_EMPTY_EXPEDITION := preload("res://scenes/journal/rows/empty_expedition.tscn")
const ITEM_SLOT := preload("res://scenes/journal/widgets/item_slot.tscn")
const ROW_EMPLOYEE := preload("res://scenes/journal/rows/employee.tscn")
const ROW_CANDIDATE := preload("res://scenes/journal/rows/candidate.tscn")
const ROW_ARMORY_CREW := preload("res://scenes/journal/rows/armory_crew.tscn")
const ROW_STASH := preload("res://scenes/journal/rows/stash.tscn")
const ROW_EMPTY_STASH := preload("res://scenes/journal/rows/empty_stash.tscn")
const ROW_CATALOG := preload("res://scenes/journal/rows/catalog.tscn")
const ROW_MARKET := preload("res://scenes/journal/rows/market.tscn")
const ROW_GUILD_WORKER := preload("res://scenes/journal/rows/guild_worker.tscn")
const ROW_REPORT := preload("res://scenes/journal/rows/report.tscn")
const ROW_REGION := preload("res://scenes/journal/rows/region.tscn")
const ROW_WAREHOUSE := preload("res://scenes/journal/rows/warehouse.tscn")
const ROW_EMPTY_WAREHOUSE := preload("res://scenes/journal/rows/empty_warehouse.tscn")
const ROW_EVENT := preload("res://scenes/journal/rows/event.tscn")
const ROW_EMPTY_EVENT := preload("res://scenes/journal/rows/empty_event.tscn")

const BUSTS := {
	"Miner": preload("res://assets/ui/portraits/miner_bust.png"),
	"Guard": preload("res://assets/ui/portraits/guard_bust.png"),
	"Scout": preload("res://assets/ui/portraits/scout_bust.png"),
}
const ROLE_ICONS := {
	"Miner": preload("res://assets/ui/icons/pickaxe.png"),
	"Guard": preload("res://assets/ui/icons/helmet.png"),
}
const SIGN_PLUS := preload("res://assets/ui/kit/sign_plus.png")
const SIGN_CHECK := preload("res://assets/ui/kit/sign_check.png")
const SIGN_CROSS := preload("res://assets/ui/kit/sign_cross.png")
const ICON_FIELD := preload("res://assets/ui/tab_icons/expeditions.png")
const ICON_GUILD := preload("res://assets/ui/tab_icons/company.png")
## Pages that have not been redesigned yet sit slightly inset from the page edge.
const LEGACY_PAGE_OFFSET := Vector2(10, 10)
const PAGE_TITLES := {
	"hq": "The Company",
	"harlow": "Harlow Mines",
	"expeditions": "Regional Contracts",
	"roster": "Personnel",
	"guildwork": "Guild Work",
	"market": "The Exchange",
	"finance": "Treasury & Accounts",
	"ledger": "The Chronicle",
}

## Callables run once a second to move timers and bars without rebuilding pages.
var live_updaters: Array[Callable] = []

func _ready() -> void:
	page = "hq"
	super._ready()

func _refresh() -> void:
	if not is_instance_valid(stage):
		return
	_update_header()
	live_updaters.clear()
	_clear(left_leaf)
	_clear(right_leaf)
	_restore_tab_art()
	title_label.text = str(PAGE_TITLES.get(page, "The Company"))
	match page:
		"hq": _draw_company()
		"harlow": _draw_harlow()
		"expeditions": _draw_regions()
		"roster": _draw_people()
		"guildwork": _draw_guild_jobs()
		"market": _draw_exchange()
		"finance": _draw_accounts()
		"ledger": _draw_history()
		_: _draw_company()

func _update_header() -> void:
	money_label.text = _money(game.gold)
	worth_label.text = "Worth  " + _money(game.wealth())
	missions_label.text = "%d / %d" % [game.missions.size(), game.expedition_slots]

func _live_tick() -> void:
	_update_header()
	for updater in live_updaters:
		if updater.is_valid():
			updater.call()

func _notify(message: String) -> void:
	if message.begins_with("Guild office open."):
		return
	notification_text(message)

func notification_text(message: String) -> void:
	toast_label.text = message
	toast.visible = true
	clear_notice_at = Time.get_ticks_msec() + 6000

func _on_clock() -> void:
	super._on_clock()
	if clear_notice_at > 0 and Time.get_ticks_msec() >= clear_notice_at:
		clear_notice_at = 0
		toast.visible = false

# --- Shared helpers ---------------------------------------------------------

func _now() -> int:
	return int(Time.get_unix_time_from_system())

func _mount_page(scene: PackedScene, leaf: Control) -> Control:
	var root := scene.instantiate() as Control
	leaf.add_child(root)
	return root

## Pages still using the pre-redesign layout.
func _mount_legacy(scene: PackedScene, leaf: Control) -> Control:
	var root := _mount_page(scene, leaf)
	root.position = LEGACY_PAGE_OFFSET
	return root

func _make_row(scene: PackedScene, list: VBoxContainer) -> Control:
	var record := scene.instantiate() as PanelContainer
	list.add_child(record)
	return record.get_node("Content") as Control

func _row_text(row: Control, node_name: String, content: String) -> Label:
	var field := row.get_node(node_name) as Label
	field.text = content
	return field

func _row_button(row: Control, node_name: String, title: String, action: Callable,
		enabled: bool = true, active: bool = false, primary: bool = false) -> Button:
	var btn := row.get_node(node_name) as Button
	btn.text = title.replace(">", ">")
	btn.disabled = not enabled
	if not primary:
		btn.theme_type_variation = &"PaperButton"
		if active:
			btn.add_theme_color_override("font_color", OXBLOOD)
	btn.pressed.connect(action)
	return btn

func _page_value(root: Control, key: String, value: String) -> void:
	(root.get_node(key + "Value") as Label).text = value

func _page_visibility(root: Control, names: Array, shown: bool) -> void:
	for path in names:
		(root.get_node(path) as CanvasItem).visible = shown

func _item_icon(key: String) -> Texture2D:
	var path := "res://assets/ui/icons/%s.png" % key
	return load(path) as Texture2D if ResourceLoader.exists(path) else null

func _resource_name(key: String) -> String:
	return str(MoneyMercsState.RESOURCE_NAMES.get(key, key.capitalize()))

func _mission_name(mission: Dictionary) -> String:
	var region: String = str(mission.get("region", ""))
	match region:
		"harlow": return "Harlow Mines"
		"guild_work": return "Guild work"
	return str(game.region_by_id(region).get("name", "Contract"))

func _crew_names(ids: Array) -> String:
	var names: Array[String] = []
	for id in ids:
		var merc: Dictionary = game.merc_by_id(str(id))
		if not merc.is_empty():
			names.append(str(merc.get("name", "?")))
	return ", ".join(names) if not names.is_empty() else "Guild clerk"

func _plural(count: int, word: String) -> String:
	return "%d %s%s" % [count, word, "" if count == 1 else "s"]

## Fill an expedition row and keep its bar and countdown moving.
func _bind_expedition_row(row: Control, mission: Dictionary) -> void:
	(row.get_node("Row/Info/Top/Name") as Label).text = _mission_name(mission)
	var detail: String = _crew_names(mission.get("ids", []))
	if mission.has("tactic"):
		detail += "  ·  " + str(mission["tactic"])
	(row.get_node("Row/Info/Crew") as Label).text = detail
	(row.get_node("Row/IconSlot/Icon") as TextureRect).texture = ICON_GUILD if str(mission.get("region", "")) == "guild_work" else ICON_FIELD
	var bar := row.get_node("Row/Info/Bar") as ProgressBar
	var time_label := row.get_node("Row/Info/Top/Time") as Label
	var started: int = int(mission.get("started", _now()))
	var finish: int = int(mission.get("finish", _now()))
	var update := func() -> void:
		var total: float = maxf(1.0, float(finish - started))
		bar.value = clampf(float(_now() - started) / total, 0.0, 1.0) * 100.0
		time_label.text = "back in " + _duration(maxi(0, finish - _now()))
	update.call()
	live_updaters.append(update)
	row.tooltip_text = "Returns automatically, even while the game is closed."

# --- Company overview -------------------------------------------------------

func _draw_company() -> void:
	var left := _mount_page(COMPANY_LEFT, left_leaf)
	var right := _mount_page(COMPANY_RIGHT, right_leaf)
	var c := "Margin/Content/"
	# Worth and what it is made of.
	var coin: int = maxi(0, game.gold)
	var goods: int = 0
	for key in MoneyMercsState.RESOURCE_ORDER:
		goods += int(game.resources.get(str(key), 0)) * game.sell_price(str(key))
	var gear: int = game.owned_equipment_value()
	for merc in game.crew:
		gear += int(merc.get("gear", 0)) * 60
	(left.get_node(c + "Hero/Worth/WorthValue") as Label).text = _money(game.wealth())
	var total: float = maxf(1.0, float(coin + goods + gear))
	var bar := c + "Hero/Worth/BarFrame/Bar/"
	(left.get_node(bar + "Coin") as Control).size_flags_stretch_ratio = coin / total
	(left.get_node(bar + "Goods") as Control).size_flags_stretch_ratio = goods / total
	(left.get_node(bar + "Gear") as Control).size_flags_stretch_ratio = gear / total
	var legend := c + "Hero/Worth/Legend/"
	(left.get_node(legend + "CoinKey/CoinValue") as Label).text = "Coin %d" % coin
	(left.get_node(legend + "GoodsKey/GoodsValue") as Label).text = "Goods %d" % goods
	(left.get_node(legend + "GearKey/GearValue") as Label).text = "Gear %d" % gear
	# Stat tiles.
	var crew_tile := left.get_node(c + "Stats/Crew")
	crew_tile.value = "%d  (%d free)" % [game.crew.size(), game.free_crew()] if not game.crew.is_empty() else "None"
	left.get_node(c + "Stats/Reputation").value = str(game.reputation)
	var debt := left.get_node(c + "Stats/Debt")
	debt.value = "None" if game.relief_debt <= 0 else _money(game.relief_debt)
	debt.tone = "accent" if game.relief_debt > 0 else "normal"
	var pieces: int = game.equipment_inventory.size()
	for merc in game.crew:
		pieces += (merc.get("equipment", {}) as Dictionary).size()
	left.get_node(c + "Stats/Gear").value = _plural(pieces, "piece")
	# Warehouse slots.
	for key in MoneyMercsState.RESOURCE_ORDER:
		var slot := left.get_node(c + "Goods/" + str(key))
		var amount: int = int(game.resources.get(str(key), 0))
		slot.count = amount if amount > 0 else -1
		slot.dim = amount <= 0
		slot.tooltip_text = "%s: %d stored\nSells for %d G each" % [_resource_name(str(key)), amount, game.sell_price(str(key))]
	_bind_advice(left)
	# Right page: expeditions in the field, then the latest report.
	var list := right.get_node(c + "Expeditions") as VBoxContainer
	for mission in game.missions:
		var row := ROW_EXPEDITION.instantiate() as Control
		list.add_child(row)
		_bind_expedition_row(row, mission)
	for i in range(maxi(0, game.expedition_slots - game.missions.size())):
		var empty := ROW_EMPTY_EXPEDITION.instantiate() as Control
		list.add_child(empty)
		(empty.get_node("Row/Plan") as Button).pressed.connect(_turn_to.bind("harlow"))
	_bind_latest_report(right)
	var guild := right.get_node(c + "GuildWork") as Button
	guild.visible = game.can_accept_guild_work()
	guild.pressed.connect(_turn_to.bind("guildwork"))

## The guildmaster's note: one clear next step for the player.
func _bind_advice(left: Control) -> void:
	var c := "Margin/Content/"
	var advice := left.get_node(c + "Advice")
	var action := left.get_node(c + "AdviceAction") as Button
	var surveyed: bool = not (game.harlow.get("report", {}) as Dictionary).is_empty()
	var scouting: bool = int(game.harlow.get("scout_finish", 0)) > 0
	var miners: int = 0
	for merc in game.available_guild_workers():
		if str(merc.get("role", "")) == "Miner":
			miners += 1
	var note: String
	var kind: String = "alert"
	var label: String = ""
	var target: Callable
	if game.crew.is_empty():
		note = "The company has no mercenaries. Hire a miner, and ideally a guard, to start working Harlow Mines."
		label = "Hire mercenaries"
		target = _open_recruitment
		kind = "plus"
	elif game.missions.size() >= game.expedition_slots:
		note = "Every team is in the field. They return on their own, even while the game is closed."
		kind = "check"
	elif scouting:
		note = "Your scout is surveying Harlow Mines. Wait for the report before you risk a crew."
		label = "View Harlow"
		target = _turn_to.bind("harlow")
	elif not surveyed:
		note = "Harlow Mines is unscouted. A free survey reveals the ore and the threat before you commit a crew."
		label = "Scout Harlow"
		target = _turn_to.bind("harlow")
	elif miners == 0:
		note = "No miner is free for work. Heal the injured or hire another miner in Personnel."
		label = "Personnel"
		target = _turn_to.bind("roster")
	else:
		note = "Harlow Mines is surveyed and a crew is ready. Fund an expedition to start earning."
		label = "Plan expedition"
		target = _turn_to.bind("harlow")
		kind = "coin"
	advice.text = note
	advice.icon_kind = kind
	action.visible = not label.is_empty()
	if action.visible:
		action.text = label
		action.pressed.connect(target)

func _bind_latest_report(right: Control) -> void:
	var c := "Margin/Content/"
	var empty: bool = game.reports.is_empty()
	(right.get_node(c + "Report") as Control).visible = not empty
	(right.get_node(c + "EmptyReport") as Control).visible = empty
	if empty:
		return
	var report: Dictionary = game.reports[0]
	var body := c + "Report/Body/"
	var won: bool = bool(report.get("won", false))
	var casualties: Array = report.get("casualties", [])
	var injured: Array = report.get("injured", [])
	(right.get_node(body + "Top/Seal") as TextureRect).texture = SIGN_CHECK if won else SIGN_CROSS
	(right.get_node(body + "Top/Title/Place") as Label).text = str(report.get("region", "Expedition"))
	var outcome: String = "Returned safely"
	if won and not casualties.is_empty():
		outcome = "Success, with losses"
	elif not won:
		outcome = "Partial haul" if bool(report.get("partial", false)) else "Failed"
	var ago: int = _now() - int(report.get("time", _now()))
	var when: String = "just now" if ago < 60 else _duration(ago) + " ago"
	(right.get_node(body + "Top/Title/Outcome") as Label).text = "%s  ·  %s" % [outcome, when]
	var profit: int = int(report.get("cash", 0)) - int(report.get("cost", 0))
	var net := right.get_node(body + "Top/Net/Value") as Label
	net.text = ("+" if profit >= 0 else "") + _money(profit)
	net.add_theme_color_override("font_color", GOOD if profit >= 0 else OXBLOOD)
	var loot: Dictionary = report.get("loot", {})
	var loot_row := right.get_node(body + "Loot") as HBoxContainer
	for key in loot:
		var slot := ITEM_SLOT.instantiate()
		loot_row.add_child(slot)
		slot.icon = _item_icon(str(key))
		slot.count = int(loot[key])
		slot.tooltip_text = "%d %s" % [int(loot[key]), _resource_name(str(key))]
	(right.get_node(body + "Loot") as Control).visible = not loot.is_empty()
	(right.get_node(body + "NoLoot") as Control).visible = loot.is_empty()
	var losses := right.get_node(body + "Losses") as Label
	var parts: Array[String] = []
	if not casualties.is_empty():
		parts.append("Killed: " + ", ".join(casualties))
	if not injured.is_empty():
		parts.append("Injured: " + ", ".join(injured))
	if parts.is_empty():
		losses.text = "No casualties."
		losses.theme_type_variation = &"LabelGood"
	else:
		losses.text = "\n".join(parts)
	(right.get_node(body + "Read") as Button).pressed.connect(func() -> void:
		selected_report_index = 0
		_turn_to("ledger"))

# --- Harlow Mines -----------------------------------------------------------

func _draw_harlow() -> void:
	var left := _mount_page(HARLOW_LEFT, left_leaf)
	var right := _mount_page(HARLOW_RIGHT, right_leaf)
	_bind_harlow_site(left)
	_bind_harlow_plan(right)

func _bind_harlow_site(left: Control) -> void:
	var c := "Margin/Content/"
	var report: Dictionary = game.harlow.get("report", {})
	var surveyed: bool = not report.is_empty()
	var finish: int = int(game.harlow.get("scout_finish", 0))
	var scouting: bool = finish > 0
	var level: int = int(game.harlow.get("scout_level", 1))
	# Site picture and its state.
	(left.get_node(c + "Site/Veil") as Control).visible = not surveyed
	(left.get_node(c + "Site/Status") as Control).visible = not surveyed
	(left.get_node(c + "Site/Status/Text/Title") as Label).text = "Surveying..." if scouting else "Unsurveyed"
	(left.get_node(c + "Site/Status/Text/Hint") as Label).text = "Your scout is mapping the shafts" if scouting else "Send your scout to learn what lies below"
	var remaining_ore: int = 0
	for amount in (game.harlow.get("deposits", {}) as Dictionary).values():
		remaining_ore += int(amount)
	var badge := left.get_node(c + "Site/Badge") as Control
	badge.visible = surveyed
	(left.get_node(c + "Site/Badge/Text") as Label).text = "Surveyed" if remaining_ore > 0 else "Exhausted"
	# Ore estimates.
	var ore_known: Dictionary = report.get("all_ore", {})
	var exact: bool = bool(report.get("exact", false))
	for key in ["copper", "iron", "silver", "crystal"]:
		var slot := left.get_node(c + "Intel/Ore/Slots/" + key)
		var count: int = -2
		if surveyed:
			if ore_known.has(key):
				count = int(ore_known[key])
			elif str(report.get("primary", "")) == key:
				count = int(report.get("minimum", 0))
		slot.count = count
		slot.dim = count == 0
		var what: String = "unknown"
		if count >= 0:
			what = ("%d" if exact else "about %d") % count
			if not exact and str(report.get("primary", "")) == key and not ore_known.has(key):
				what = "at least %d" % count
		slot.tooltip_text = "%s: %s" % [_resource_name(key), what]
	# Threat.
	var threat_name := left.get_node(c + "Intel/Threat/Body/Name") as Label
	threat_name.text = str(report.get("creature", "Unknown")) if surveyed else "Unknown"
	threat_name.tooltip_text = str(report.get("threat_note", ""))
	var danger := left.get_node(c + "Intel/Threat/Body/Danger")
	danger.value = int(report.get("danger", -1)) if report.has("danger") else -1
	var threat_caption := left.get_node(c + "Intel/Threat/Body/Caption") as Label
	threat_caption.text = "Threat  ·  " + str(report.get("danger_band")) if report.has("danger_band") else "Threat"
	var note := left.get_node(c + "IntelNote") as Label
	if not surveyed:
		note.text = "Nothing is known yet. Going in blind is a gamble."
	elif level == 1:
		note.text = "A rough count: at least %d %s. Train your scout for a full survey." % [
			int(report.get("minimum", 0)), _resource_name(str(report.get("primary", "copper"))).to_lower()]
	elif not exact:
		note.text = str(report.get("threat_note", "")) + ". Counts are approximate."
	else:
		note.text = str(report.get("threat_note", "")) + ". The survey is exact."
	# Scout.
	var scout := c + "Scout/Row/Info/"
	left.get_node(scout + "Top/Level").value = level
	(left.get_node(scout + "Top/Level") as Control).tooltip_text = "Scout training %d / 3" % level
	var send := left.get_node(scout + "SendScout") as Button
	send.visible = not surveyed and not scouting
	send.text = "Send scout  ·  %ds" % game.harlow_scout_seconds()
	send.pressed.connect(_scout)
	var progress := left.get_node(scout + "Progress") as Control
	progress.visible = scouting
	(left.get_node(scout + "Done") as Control).visible = surveyed
	if scouting:
		var bar := left.get_node(scout + "Progress/Bar") as ProgressBar
		var time_label := left.get_node(scout + "Progress/Time") as Label
		var duration: int = game.harlow_scout_seconds()
		var update := func() -> void:
			var left_s: int = maxi(0, finish - _now())
			bar.value = clampf(1.0 - float(left_s) / float(maxi(1, duration)), 0.0, 1.0) * 100.0
			time_label.text = "Surveying  ·  back in " + _duration(left_s)
		update.call()
		live_updaters.append(update)
	var train := left.get_node(scout + "Train") as Button
	train.visible = level < 3
	if level < 3:
		var price: int = 200 if level == 1 else 650
		train.text = "Train scout  ·  %d G" % price
		train.disabled = game.gold < price or scouting
		train.tooltip_text = ("Level %d scouts survey faster and report more: " % (level + 1)) + \
			("approximate counts of every ore and the threat's nature." if level == 1 else "exact counts and the threat's danger level.")
		if scouting:
			train.tooltip_text += "\nWait for the current survey to finish."
		train.pressed.connect(_train_scout)
	# Footer.
	var rotation := left.get_node(c + "Footer/Rotation") as Label
	var rotate := func() -> void:
		rotation.text = "Site shifts in " + _duration(game.harlow_rotation_remaining())
	rotate.call()
	live_updaters.append(rotate)
	(left.get_node(c + "Footer/OtherContracts") as Button).pressed.connect(_turn_to.bind("expeditions"))

func _bind_harlow_plan(right: Control) -> void:
	var c := "Margin/Content/"
	var plan := c + "Planning/"
	var report: Dictionary = game.harlow.get("report", {})
	var surveyed: bool = not report.is_empty()
	var busy: bool = game.missions.size() >= game.expedition_slots
	# A team already underground.
	var in_field := right.get_node(c + "InField") as Control
	in_field.visible = false
	var field_mission: Dictionary = {}
	for mission in game.missions:
		if str(mission.get("region", "")) == "harlow":
			field_mission = mission
			in_field.visible = true
			_bind_expedition_row(in_field, mission)
			(in_field.get_node("Row/Info/Top/Name") as Label).text = "Team underground"
			break
	# While a Harlow team is out, the planner shows that team read-only.
	var watching: bool = busy and not field_mission.is_empty()
	# Assigned crew slots.
	var ids: Array[String] = _selected_available()
	if watching:
		ids.clear()
		for id in field_mission.get("ids", []):
			ids.append(str(id))
		(right.get_node(plan + "CrewCaption/Label") as Label).text = "Crew underground"
	var miners: int = 0
	var guards: int = 0
	for i in range(3):
		var slot := right.get_node(plan + "Slots/Slot" + str(i)) as Button
		var bust := slot.get_node("Body/Bust") as TextureRect
		if i < ids.size():
			var merc: Dictionary = game.merc_by_id(ids[i])
			var role: String = str(merc.get("role", ""))
			miners += 1 if role == "Miner" else 0
			guards += 1 if role == "Guard" else 0
			bust.texture = BUSTS.get(role, BUSTS["Scout"])
			bust.modulate = Color.WHITE
			(slot.get_node("Body/Name") as Label).text = str(merc.get("name", "?"))
			(slot.get_node("Body/Role") as Label).text = role
			if watching:
				slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			else:
				slot.tooltip_text = "Click to remove %s from the crew." % str(merc.get("name", ""))
				slot.pressed.connect(_toggle_crew.bind(false, ids[i]))
		else:
			bust.texture = SIGN_PLUS
			bust.modulate = Color(1, 1, 1, 0.45)
			(slot.get_node("Body/Name") as Label).text = "Empty"
			(slot.get_node("Body/Role") as Label).text = "Not sent" if watching else "Choose below"
			slot.disabled = true
	(right.get_node(plan + "CrewCaption/Roles") as Label).text = "%s  ·  %s" % [_plural(miners, "miner"), _plural(guards, "guard")]
	# Available roster.
	var list := right.get_node(plan + "Roster/Items") as VBoxContainer
	var eligible: int = 0
	for merc in game.available_guild_workers():
		var role: String = str(merc.get("role", ""))
		if role not in ["Miner", "Guard"]:
			continue
		eligible += 1
		var id: String = str(merc["id"])
		var assigned: bool = ids.has(id)
		var health: int = int(merc.get("health", 100))
		var card := ROW_ROSTER_CARD.instantiate() as Button
		list.add_child(card)
		card.toggle_mode = true
		card.button_pressed = assigned
		(card.get_node("Body/RoleIcon") as TextureRect).texture = ROLE_ICONS.get(role, ROLE_ICONS["Miner"])
		(card.get_node("Body/Info/Name") as Label).text = str(merc.get("name", "?"))
		(card.get_node("Body/Info/Details") as Label).text = "%s  ·  Skill %d  ·  Gear %d/2" % [role, int(merc.get("skill", 0)), _equipped_count(merc)]
		(card.get_node("Body/Health/HealthText") as Label).text = "Health %d%%" % health
		var hp := card.get_node("Body/Health/HealthBar") as ProgressBar
		hp.value = health
		hp.theme_type_variation = &"GreenBar" if health >= 60 else (&"GoldBar" if health >= 25 else &"")
		var tag := card.get_node("Body/Tag") as Label
		if assigned:
			tag.text = "Assigned"
			card.tooltip_text = "Click to remove from the crew."
		elif health < 25:
			tag.text = "Too hurt"
			card.disabled = true
			card.tooltip_text = "Below 25% health. Heal in Personnel before deploying."
		elif ids.size() >= 3:
			tag.text = "Crew full"
			card.disabled = true
		else:
			tag.text = "+ Assign"
			card.tooltip_text = "Add %s to the crew." % str(merc.get("name", ""))
		card.pressed.connect(_toggle_crew.bind(not assigned, id))
	(right.get_node(plan + "Roster") as Control).visible = eligible > 0 and not watching
	(right.get_node(plan + "RosterCaption") as Control).visible = eligible > 0 and not watching
	var no_crew := right.get_node(plan + "NoCrew") as Control
	no_crew.visible = eligible == 0 and not watching
	var hire := right.get_node(plan + "Hire") as Button
	hire.visible = no_crew.visible
	hire.pressed.connect(_open_recruitment)
	# Standing orders.
	var orders: String = str(field_mission.get("tactic", tactic)) if watching else tactic
	for pair in [["Cautious", "Cautious"], ["Balanced", "Balanced"], ["DeepPush", "Deep Push"]]:
		var btn := right.get_node(plan + "Orders/" + str(pair[0])) as Button
		btn.set_pressed_no_signal(orders == str(pair[1]))
		if watching:
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			btn.pressed.connect(_set_tactic.bind(str(pair[1])))
	# Forecast (for a team already out, the odds they left with).
	var stats: Dictionary = game.harlow_crew_stats(ids, tactic)
	if watching:
		stats = {"capacity": int(field_mission.get("capacity", 0)), "wage": int(field_mission.get("cost", 0)),
			"success": float(field_mission.get("chance", 0.0)), "miners": 1}
	right.get_node(plan + "Forecast/Haul").value = _plural(int(stats["capacity"]), "vein")
	right.get_node(plan + "Forecast/Cost").value = _money(int(stats["wage"]))
	var odds := right.get_node(plan + "Forecast/Odds")
	var odds_bar := right.get_node(plan + "OddsBar") as ProgressBar
	var success: float = float(stats["success"])
	odds_bar.visible = not ids.is_empty() and surveyed
	if ids.is_empty():
		odds.value = "-"
		odds.tone = "normal"
		odds_bar.value = 0
	elif not surveyed:
		odds.value = "?"
		odds.tone = "accent"
		odds_bar.value = 0
		odds.tooltip_text = "Unknown until the site is scouted."
	else:
		odds.value = "%d%%" % int(round(success * 100.0))
		odds.tone = "good" if success >= 0.6 else ("accent" if success < 0.35 else "normal")
		odds_bar.value = success * 100.0
		odds_bar.theme_type_variation = &"GreenBar" if success >= 0.6 else (&"GoldBar" if success >= 0.35 else &"")
	# Fund button and the reason it may be unavailable.
	var fund := right.get_node(c + "Fund") as Button
	var reason := right.get_node(c + "Reason") as Label
	var ore_left: int = 0
	for amount in (game.harlow.get("deposits", {}) as Dictionary).values():
		ore_left += int(amount)
	var wage: int = int(stats["wage"])
	var why: String = ""
	if busy:
		why = "All expedition slots are busy. Wait for your team to return."
	elif ids.is_empty() and eligible == 0:
		why = "Hire a miner in Personnel to start."
	elif ids.is_empty():
		why = "Choose a crew: click mercenaries in the list above."
	elif int(stats["miners"]) == 0:
		why = "Add a miner. Guards protect the crew but cannot dig."
	elif ore_left <= 0:
		why = "The mine is exhausted until the site shifts."
	elif game.gold < wage:
		why = "Not enough gold: wages and provisions cost %s." % _money(wage)
	fund.text = "Fund expedition  ·  " + _money(wage) if not busy else "Expedition underway"
	fund.disabled = not why.is_empty()
	fund.pressed.connect(_dispatch_harlow)
	if why.is_empty() and not surveyed:
		why = "Unscouted: you are sending them in blind."
	reason.text = why
	reason.visible = not why.is_empty()
	(right.get_node(c + "Warning") as Control).visible = not busy

# --- Chapters not yet redesigned (converted legacy layouts) ----------------

func _draw_people() -> void:
	# Individual personnel spreads are scenes, sharing one editable tab bar.
	match roster_tab:
		"employed": _draw_employees()
		"recruits": _draw_recruitment()
		"armory": _draw_armory_page()
		_: _draw_employees()
	var tabs := _mount_legacy(PERSONNEL_TABS, left_leaf)
	for tab in [["EmployeesTab", "employed"], ["RecruitmentTab", "recruits"], ["ArmoryTab", "armory"]]:
		var btn := tabs.get_node(str(tab[0])) as Button
		btn.add_theme_color_override("font_color", BLUE if roster_tab == str(tab[1]) else INK)
		btn.pressed.connect(_set_roster_tab.bind(str(tab[1])))

func _focus_person(id: String) -> void:
	selected_merc = id
	_refresh()

func _draw_employees() -> void:
	var left := _mount_legacy(PERSONNEL_EMPLOYEES_LEFT, left_leaf)
	var right := _mount_legacy(PERSONNEL_EMPLOYEES_RIGHT, right_leaf)
	var roster := left.get_node("Employed/Items") as VBoxContainer
	if selected_merc.is_empty() and not game.crew.is_empty():
		selected_merc = str(game.crew[0]["id"])
	for person in game.crew:
		var id: String = str(person["id"])
		var row := _make_row(ROW_EMPLOYEE, roster)
		var name_label := _row_text(row, "Name", str(person["name"]))
		name_label.add_theme_color_override("font_color", BLUE if id == selected_merc else INK)
		_row_text(row, "Details", "%s  •  %d%% health" % [str(person["role"]), int(person.get("health", 100))])
		_row_button(row, "View", "VIEW  >", _focus_person.bind(id), true, id == selected_merc)
	var empty_crew: bool = game.crew.is_empty()
	(left.get_node("EmptyCrew") as Label).visible = empty_crew
	var recruit := left.get_node("Recruit") as Button
	recruit.visible = empty_crew
	recruit.pressed.connect(_set_roster_tab.bind("recruits"))
	var person: Dictionary = game.merc_by_id(selected_merc)
	var no_selection: bool = person.is_empty()
	(right.get_node("EmptyDossier") as Label).visible = no_selection
	_page_visibility(right, ["PersonName", "OccupationCaption", "OccupationValue", "OccupationRule",
		"SkillCaption", "SkillValue", "SkillRule", "HealthCaption", "HealthValue", "HealthRule",
		"WageCaption", "WageValue", "WageRule", "Tool", "Armor",
		"OpenArmory", "ChangeTerms", "Heal"], not no_selection)
	if no_selection:
		return
	(right.get_node("PersonName") as Label).text = str(person["name"])
	_page_value(right, "Occupation", str(person["role"]))
	_page_value(right, "Skill", str(int(person.get("skill", 0))))
	_page_value(right, "Health", "%d%%" % int(person.get("health", 100)))
	_page_value(right, "Wage", _money(int(person.get("wage", 0))))
	var equipped: Dictionary = person.get("equipment", {})
	(right.get_node("Tool") as Label).text = "TOOL: %s" % _equipment_name(equipped.get("tool", {}))
	(right.get_node("Armor") as Label).text = "ARMOR: %s" % _equipment_name(equipped.get("armor", {}))
	(right.get_node("OpenArmory") as Button).pressed.connect(_outfit.bind(selected_merc))
	(right.get_node("ChangeTerms") as Button).pressed.connect(_terms.bind(selected_merc))
	var heal := right.get_node("Heal") as Button
	heal.visible = int(person.get("health", 100)) < 100
	if heal.visible:
		heal.pressed.connect(_heal.bind(selected_merc))

func _draw_recruitment() -> void:
	var left := _mount_legacy(PERSONNEL_RECRUITS_LEFT, left_leaf)
	var right := _mount_legacy(PERSONNEL_RECRUITS_RIGHT, right_leaf)
	var offers := left.get_node("Offers/Items") as VBoxContainer
	for candidate in game.recruitment_board():
		var record := _make_row(ROW_CANDIDATE, offers)
		_row_text(record, "Name", str(candidate["name"]))
		_row_text(record, "Details", "%s  •  Skill %d  •  Wage %d G" % [
			str(candidate["role"]), int(candidate["skill"]), int(candidate["wage"])])
		_row_button(record, "Hire", "HIRE %d G" % int(candidate["hire"]),
			_hire.bind(str(candidate["id"])), game.gold >= int(candidate["hire"]))
	_page_value(right, "Treasury", _money(game.gold))
	_page_value(right, "Workers", str(game.crew.size()))

func _draw_armory_page() -> void:
	var left := _mount_legacy(PERSONNEL_ARMORY_LEFT, left_leaf)
	var right := _mount_legacy(PERSONNEL_ARMORY_RIGHT, right_leaf)
	if selected_merc.is_empty() and not game.crew.is_empty():
		selected_merc = str(game.crew[0]["id"])
	var crew_picker := left.get_node("CrewPicker/Items") as VBoxContainer
	for person in game.crew:
		var row := _make_row(ROW_ARMORY_CREW, crew_picker)
		var id: String = str(person["id"])
		_row_text(row, "Name", "%s / %s" % [str(person["name"]), str(person["role"])])
		_row_button(row, "Select", "SELECT", _choose_worker.bind(id), true, id == selected_merc)
	var stash := left.get_node("Stash/Items") as VBoxContainer
	var owner: Dictionary = game.merc_by_id(selected_merc)
	for item in game.equipment_inventory:
		var definition: Dictionary = game.item_definition(str(item.get("key", "")))
		var row := _make_row(ROW_STASH, stash)
		_row_text(row, "Name", str(definition.get("name", "Unknown")))
		_row_text(row, "Details", "Owned  /  %s" % str(definition.get("slot", "tool")))
		var can_equip: bool = not owner.is_empty() and game.is_available(owner) and MercsV05.validate_role(str(item.get("key", "")), owner)
		_row_button(row, "Equip", "EQUIP", _equip.bind(selected_merc, str(item.get("uid", ""))), can_equip)
		_row_button(row, "Sell", "SELL", _sell_equipment.bind(str(item.get("uid", ""))))
	if game.equipment_inventory.is_empty():
		var empty := _make_row(ROW_EMPTY_STASH, stash)
		_row_text(empty, "Note", "No equipment in storage.")
	var has_owner: bool = not owner.is_empty()
	_page_visibility(right, ["Outfitting", "Tool", "Armor", "RemoveTool", "RemoveArmor"], has_owner)
	if has_owner:
		(right.get_node("Outfitting") as Label).text = "OUTFITTING: %s" % str(owner.get("name", ""))
		var worn: Dictionary = owner.get("equipment", {})
		for slot in ["tool", "armor"]:
			var equipped: Dictionary = worn.get(slot, {})
			(right.get_node(slot.capitalize()) as Label).text = "%s: %s" % [slot.capitalize(), _equipment_name(equipped)]
			var remove := right.get_node("Remove" + slot.capitalize()) as Button
			remove.visible = not equipped.is_empty()
			if remove.visible:
				remove.pressed.connect(_unequip.bind(selected_merc, slot))
	var catalog := right.get_node("Catalog/Items") as VBoxContainer
	for key in MercsV05.ITEMS:
		var definition: Dictionary = MercsV05.ITEMS[key]
		var row := _make_row(ROW_CATALOG, catalog)
		_row_text(row, "Name", str(definition.get("name", "")))
		_row_text(row, "Details", "%s  •  %s" % [str(definition.get("role", "")), str(definition.get("slot", ""))])
		_row_button(row, "Price", "%d G" % int(definition["cost"]), _buy_equipment.bind(str(key)))

func _choose_commodity(id: String) -> void:
	selected_market_item = id
	_refresh()

func _draw_exchange() -> void:
	var left := _mount_legacy(EXCHANGE_LEFT, left_leaf)
	var right := _mount_legacy(EXCHANGE_RIGHT, right_leaf)
	var stock := left.get_node("Stock/Items") as VBoxContainer
	for id in MoneyMercsState.RESOURCE_ORDER:
		var key: String = str(id)
		var row := _make_row(ROW_MARKET, stock)
		var selected: bool = key == selected_market_item
		(row.get_node("Selected") as ColorRect).visible = selected
		var name := _row_text(row, "Name", str(MoneyMercsState.RESOURCE_NAMES[key]))
		name.add_theme_color_override("font_color", BLUE if selected else INK)
		_row_text(row, "Details", "Stored: %d    |    Sell: %d G" % [
			int(game.resources.get(key, 0)), game.sell_price(key)])
		_row_button(row, "Inspect", "INSPECT  >", _choose_commodity.bind(key), true, selected)
	var name: String = str(MoneyMercsState.RESOURCE_NAMES.get(selected_market_item, "Unknown item"))
	(right.get_node("ItemName") as Label).text = name
	(right.get_node("ItemDesc") as Label).text = str(MoneyMercsState.RESOURCE_DESC.get(selected_market_item, ""))
	_page_value(right, "Quantity", str(game.resources.get(selected_market_item, 0)))
	_page_value(right, "SellsFor", _money(game.buy_price(selected_market_item)))
	_page_value(right, "BuysFor", _money(game.sell_price(selected_market_item)))
	var buy_btn := right.get_node("BuyOne") as Button
	buy_btn.disabled = game.gold < game.buy_price(selected_market_item)
	buy_btn.pressed.connect(_trade.bind(selected_market_item, true, 1))
	var sell_btn := right.get_node("SellOne") as Button
	sell_btn.disabled = int(game.resources.get(selected_market_item, 0)) <= 0
	sell_btn.pressed.connect(_trade.bind(selected_market_item, false, 1))
	var sell_all := right.get_node("SellAll") as Button
	sell_all.disabled = int(game.resources.get(selected_market_item, 0)) <= 0
	sell_all.pressed.connect(_trade.bind(selected_market_item, false,
		int(game.resources.get(selected_market_item, 0))))

func _draw_accounts() -> void:
	var left := _mount_legacy(FINANCE_LEFT, left_leaf)
	var right := _mount_legacy(FINANCE_RIGHT, right_leaf)
	_page_value(left, "Gold", _money(game.gold))
	_page_value(left, "Worth", _money(game.wealth()))
	_page_value(left, "Equipment", _money(game.owned_equipment_value()))
	_page_value(left, "Debt", _money(game.relief_debt))
	_page_value(left, "Reputation", str(game.reputation))
	(left.get_node("OpenExchange") as Button).pressed.connect(_turn_to.bind("market"))
	var stores := right.get_node("Stores/Items") as VBoxContainer
	var owned := 0
	for id in MoneyMercsState.RESOURCE_ORDER:
		var quantity: int = int(game.resources.get(str(id), 0))
		if quantity <= 0:
			continue
		var line := _make_row(ROW_WAREHOUSE, stores)
		_row_text(line, "Name", str(MoneyMercsState.RESOURCE_NAMES.get(str(id), str(id))))
		_row_text(line, "Count", str(quantity) + " owned")
		owned += 1
	if owned == 0:
		var blank := _make_row(ROW_EMPTY_WAREHOUSE, stores)
		_row_text(blank, "Note", "Nothing stored in the warehouse.")

func _draw_guild_jobs() -> void:
	var left := _mount_legacy(GUILDWORK_LEFT, left_leaf)
	var right := _mount_legacy(GUILDWORK_RIGHT, right_leaf)
	var can_take: bool = game.can_accept_guild_work() and game.missions.size() < game.expedition_slots
	var office := left.get_node("AcceptOffice") as Button
	office.disabled = not can_take
	office.pressed.connect(_guild_work.bind(""))
	(left.get_node("ReturnHarlow") as Button).pressed.connect(_turn_to.bind("harlow"))
	var workers := right.get_node("Workers/Items") as VBoxContainer
	var count: int = 0
	for member in game.available_guild_workers():
		var row := _make_row(ROW_GUILD_WORKER, workers)
		_row_text(row, "Name", str(member.get("name", "Contractor")))
		_row_text(row, "Details", "No injury or equipment risk")
		_row_button(row, "Assign", "ASSIGN", _guild_work.bind(str(member["id"])), can_take, false, true)
		count += 1
	(right.get_node("NoWorkers") as Label).visible = count == 0

func _choose_report(index: int) -> void:
	selected_report_index = index
	_refresh()

func _draw_history() -> void:
	var left := _mount_legacy(CHRONICLE_LEFT, left_leaf)
	var right := _mount_legacy(CHRONICLE_RIGHT, right_leaf)
	var records := left.get_node("Reports/Items") as VBoxContainer
	for i in range(game.reports.size()):
		var entry: Dictionary = game.reports[i]
		var row := _make_row(ROW_REPORT, records)
		(row.get_node("Selected") as ColorRect).visible = i == selected_report_index
		_row_text(row, "Name", str(entry.get("region", "Unknown assignment")))
		var outcome := _row_text(row, "Outcome", "Completed" if bool(entry.get("won", false)) else "Costly return")
		outcome.add_theme_color_override("font_color", BLUE if bool(entry.get("won", false)) else OXBLOOD)
		_row_button(row, "Read", "READ", _choose_report.bind(i), true, i == selected_report_index)
	var empty: bool = game.reports.is_empty()
	_page_visibility(left, ["NoReports", "InspectContracts"], empty)
	(left.get_node("InspectContracts") as Button).pressed.connect(_turn_to.bind("harlow"))
	(right.get_node("NoReports") as Label).visible = empty
	_page_visibility(right, ["ReportTitle", "OutcomeCaption", "OutcomeValue", "OutcomeRule",
		"RecoveredCaption", "RecoveredValue", "RecoveredRule",
		"CostsCaption", "CostsValue", "CostsRule",
		"CasualtiesCaption", "CasualtiesValue", "CasualtiesRule",
		"EventLogTitle", "Events"], not empty)
	if empty:
		return
	var idx: int = clampi(selected_report_index, 0, game.reports.size() - 1)
	var report: Dictionary = game.reports[idx]
	(right.get_node("ReportTitle") as Label).text = str(report.get("region", "Unknown expedition"))
	_page_value(right, "Outcome", "Success" if bool(report.get("won", false)) else "Failed")
	_page_value(right, "Recovered", _money(int(report.get("cash", 0))))
	_page_value(right, "Costs", _money(int(report.get("cost", 0))))
	var deaths: Array = report.get("casualties", [])
	_page_value(right, "Casualties", str(deaths.size()))
	var events := right.get_node("Events/Items") as VBoxContainer
	for event in report.get("events", []):
		var note := _make_row(ROW_EVENT, events)
		_row_text(note, "Note", str(event))
	if (report.get("events", []) as Array).is_empty():
		var blank := _make_row(ROW_EMPTY_EVENT, events)
		_row_text(blank, "Note", _loot_text(report.get("loot", {})))

func _draw_regions() -> void:
	var left := _mount_legacy(REGIONS_LEFT, left_leaf)
	var right := _mount_legacy(REGIONS_RIGHT, right_leaf)
	var regions := left.get_node("Regions/Items") as VBoxContainer
	for region in MoneyMercsState.REGIONS:
		var entry := _make_row(ROW_REGION, regions)
		var id: String = str(region["id"])
		_row_text(entry, "Name", str(region["name"]))
		_row_text(entry, "Tagline", str(region.get("tagline", "")))
		_row_button(entry, "Inspect", "INSPECT  >", _select_region.bind(id), true, selected_region == id)
	var site: Dictionary = {}
	for region in MoneyMercsState.REGIONS:
		if str(region["id"]) == selected_region:
			site = region
	if site.is_empty():
		_page_visibility(right, ["SiteName", "ThreatCaption", "ThreatValue", "ThreatRule",
			"SuppliesCaption", "SuppliesValue", "SuppliesRule",
			"ReputationCaption", "ReputationValue", "ReputationRule",
			"SiteTagline", "DispatchCrew", "GoHarlow"], false)
		return
	(right.get_node("SiteName") as Label).text = str(site["name"])
	_page_value(right, "Threat", str(site.get("threat", 0)))
	_page_value(right, "Supplies", _money(int(site.get("supplies", 0))))
	_page_value(right, "Reputation", str(site.get("rep", 0)))
	(right.get_node("SiteTagline") as Label).text = str(site.get("tagline", ""))
	var can_start: bool = game.free_crew() > 0 and game.reputation >= int(site.get("rep", 0)) and game.missions.size() < game.expedition_slots
	var dispatch := right.get_node("DispatchCrew") as Button
	dispatch.disabled = not can_start
	dispatch.pressed.connect(_old_dispatch.bind(str(site["id"])))
	(right.get_node("GoHarlow") as Button).pressed.connect(_turn_to.bind("harlow"))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var pages: Array[String] = ["hq", "harlow", "roster", "market", "finance", "ledger", "guildwork"]
		var index: int = int(event.keycode) - int(KEY_1)
		if index >= 0 and index < pages.size():
			_turn_to(pages[index])
