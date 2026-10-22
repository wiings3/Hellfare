extends "res://scripts/book_shell.gd"
## Active book screens. Page content and interactions only.
## Shared book art, tab animation, input hitboxes, and drawing primitives live in book_shell.gd.

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
const ROW_HARLOW_CREW := preload("res://scenes/journal/rows/harlow_crew.tscn")
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

func _ready() -> void:
	page = "hq"
	super._ready()

func _refresh() -> void:
	if not is_instance_valid(stage):
		return
	money_label.text = "GOLD  " + _money(game.gold)
	worth_label.text = "WORTH  " + _money(game.wealth())
	missions_label.text = "%d / %d  IN THE FIELD" % [game.missions.size(), game.expedition_slots]
	_clear(left_leaf)
	_clear(right_leaf)
	_restore_tab_art()
	var headings: Dictionary = {
		"hq": ["Company Records", "Keeping the guild solvent"],
		"harlow": ["Harlow Mines", "Contract dossier and dispatch"],
		"expeditions": ["Regional Contracts", "Other assignments"],
		"roster": ["Personnel Register", "Employees, recruitment and gear"],
		"guildwork": ["Guild Work Orders", "Safe work and recovery"],
		"market": ["Exchange Ledger", "Buying and selling goods"],
		"finance": ["Treasury & Assets", "Accounts and net worth"],
		"ledger": ["Field Chronicle", "Expeditions and casualties"]
	}
	var caption: Array = headings.get(page, headings["hq"])
	title_label.text = str(caption[0])
	subheading.text = str(caption[1])
	var right_titles: Dictionary = {
		"hq": "CURRENT ACCOUNTS",
		"harlow": "EXPEDITION LEDGER",
		"expeditions": "FIELD CONTRACTS",
		"roster": "PERSONNEL FILES",
		"guildwork": "WORK ASSIGNMENTS",
		"market": "MARKET RECORDS",
		"finance": "COMPANY ACCOUNTS",
		"ledger": "AFTER-ACTION RECORDS"
	}
	right_heading.text = str(right_titles.get(page, "CURRENT ACCOUNTS"))
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

func _notify(message: String) -> void:
	if message.begins_with("Guild office open."):
		return
	notification.text = message
	notification.visible = true
	clear_notice_at = Time.get_ticks_msec() + 6500

func _on_clock() -> void:
	super._on_clock()
	if clear_notice_at > 0 and Time.get_ticks_msec() >= clear_notice_at:
		clear_notice_at = 0
		notification.visible = false

# Variable-length lists use editable row and scroll PackedScenes.
# Variable-length collections instance editable row scenes instead of
# creating labels and placing controls in GDScript.
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
	btn.text = title
	btn.disabled = not enabled
	if not primary:
		btn.add_theme_color_override("font_color", BLUE if active else INK)
	btn.pressed.connect(action)
	return btn

func _mount_page(scene: PackedScene, leaf: Control) -> Control:
	var root := scene.instantiate() as Control
	leaf.add_child(root)
	return root

func _page_value(root: Control, key: String, value: String) -> void:
	(root.get_node(key + "Value") as Label).text = value

func _page_visibility(root: Control, names: Array, shown: bool) -> void:
	for path in names:
		(root.get_node(path) as CanvasItem).visible = shown

func _draw_company() -> void:
	var left := _mount_page(COMPANY_LEFT, left_leaf)
	var right := _mount_page(COMPANY_RIGHT, right_leaf)
	_page_value(left, "Gold", _money(game.gold))
	_page_value(left, "Worth", _money(game.wealth()))
	_page_value(left, "Crew", str(game.crew.size()))
	_page_value(left, "Ready", str(game.free_crew()))
	_page_value(left, "Debt", _money(game.relief_debt))
	(left.get_node("OpenHarlow") as Button).pressed.connect(_turn_to.bind("harlow"))
	_page_value(right, "Expeditions", str(game.missions.size()))
	_page_value(right, "Reputation", str(game.reputation))
	var empty: bool = game.reports.is_empty()
	(right.get_node("EmptyReport") as Label).visible = empty
	(right.get_node("ReportSeal") as TextureRect).visible = not empty
	var report_name := right.get_node("ReportName") as Label
	var report_outcome := right.get_node("ReportOutcome") as Label
	var report_loot := right.get_node("ReportLoot") as Label
	report_name.visible = not empty
	report_outcome.visible = not empty
	report_loot.visible = not empty
	if not empty:
		var recent: Dictionary = game.reports[0]
		report_name.text = str(recent.get("region", "Unnamed expedition"))
		var won: bool = bool(recent.get("won", false))
		report_outcome.text = "Returned safely" if won else "Costly return"
		report_outcome.add_theme_color_override("font_color", BLUE if won else OXBLOOD)
		report_loot.text = _loot_text(recent.get("loot", {}))
	(right.get_node("OpenChronicle") as Button).pressed.connect(_turn_to.bind("ledger"))
	(right.get_node("OpenGuildWork") as Button).pressed.connect(_turn_to.bind("guildwork"))

func _draw_harlow() -> void:
	var left := _mount_page(HARLOW_LEFT, left_leaf)
	var right := _mount_page(HARLOW_RIGHT, right_leaf)
	var report: Dictionary = game.harlow.get("report", {})
	var surveyed: bool = not report.is_empty()
	(left.get_node("SurveyVeil") as ColorRect).visible = not surveyed
	(left.get_node("SurveyedStamp") as Label).visible = surveyed
	var waiting: bool = int(game.harlow.get("scout_finish", 0)) > 0
	(left.get_node("SurveyStatus") as Label).text = "Survey in progress" if waiting else "Not yet surveyed"
	_page_visibility(left, ["SurveyStatus", "SurveyHelp", "DispatchScout"], not surveyed)
	(left.get_node("ReturnTime") as Label).visible = not surveyed and waiting
	if waiting:
		(left.get_node("ReturnTime") as Label).text = "Returns in %s" % _duration(maxi(0,
			int(game.harlow["scout_finish"]) - int(Time.get_unix_time_from_system())))
	var scout_btn := left.get_node("DispatchScout") as Button
	scout_btn.text = "Scout Away" if waiting else "Dispatch Scout"
	scout_btn.disabled = waiting
	scout_btn.pressed.connect(_scout)
	_page_visibility(left, ["VeinsCaption", "VeinsValue", "VeinsRule",
		"ThreatCaption", "ThreatValue", "ExpiryNote"], surveyed)
	if surveyed:
		_page_value(left, "Veins", "At least %d" % int(report.get("minimum", 0)))
		(left.get_node("ThreatValue") as Label).text = str(report.get("creature", "Unknown"))
	var level: int = int(game.harlow.get("scout_level", 1))
	(left.get_node("Training") as Label).text = "SCOUT TRAINING  %d / 3" % level
	var training := left.get_node("TrainScout") as Button
	training.visible = level < 3
	if level < 3:
		var price: int = 200 if level == 1 else 650
		training.text = "Train Scout  /  %d G" % price
		training.disabled = game.gold < price
		training.pressed.connect(_train_scout)
	(left.get_node("OtherContracts") as Button).pressed.connect(_turn_to.bind("expeditions"))
	var roster := right.get_node("Crew/Items") as VBoxContainer
	var eligible_workers: int = 0
	for merc in game.available_guild_workers():
		if str(merc.get("role", "")) not in ["Miner", "Guard"]:
			continue
		eligible_workers += 1
		var entry := _make_row(ROW_HARLOW_CREW, roster)
		var id: String = str(merc["id"])
		var assigned: bool = selected_crew.has(id)
		_row_text(entry, "Name", "%s  (%s)" % [str(merc["name"]), str(merc["role"])])
		_row_text(entry, "Details", "Health %d%%   •   Gear %d/2" % [
			int(merc.get("health", 100)), _equipped_count(merc)])
		_row_button(entry, "Assign", "REMOVE" if assigned else "ASSIGN",
			_toggle_crew.bind(not assigned, id), true, false, true)
	(right.get_node("NoCrew") as Label).visible = eligible_workers == 0
	var ids: Array[String] = _selected_available()
	var stats: Dictionary = game.harlow_crew_stats(ids, tactic)
	var stance := right.get_node("Stance") as OptionButton
	for t in MoneyMercsState.TACTICS:
		stance.add_item(str(t))
	stance.select(maxi(0, MoneyMercsState.TACTICS.find(tactic)))
	stance.item_selected.connect(func(i: int) -> void:
		_set_tactic(str(MoneyMercsState.TACTICS[i]))
	)
	_page_value(right, "Capacity", "%d veins" % int(stats["capacity"]))
	_page_value(right, "Cost", _money(int(stats["wage"])))
	var intel: bool = surveyed
	var forecast: String = "Scout first" if not intel else "%d%%" % int(round(float(stats["success"]) * 100.0))
	var forecast_label := right.get_node("Forecast") as Label
	forecast_label.text = forecast
	forecast_label.add_theme_color_override("font_color", OXBLOOD if not intel else BLUE)
	var ore_count: int = 0
	for amount in (game.harlow.get("deposits", {}) as Dictionary).values():
		ore_count += int(amount)
	var possible: bool = int(stats["miners"]) > 0 and ids.size() <= 3 and ore_count > 0 and game.gold >= int(stats["wage"]) and game.missions.size() < game.expedition_slots
	var dispatch_btn := right.get_node("FundExpedition") as Button
	dispatch_btn.disabled = not possible
	dispatch_btn.pressed.connect(_dispatch_harlow)

func _draw_people() -> void:
	# Individual personnel spreads are scenes, sharing one editable tab bar.
	match roster_tab:
		"employed": _draw_employees()
		"recruits": _draw_recruitment()
		"armory": _draw_armory_page()
		_: _draw_employees()
	var tabs := _mount_page(PERSONNEL_TABS, left_leaf)
	for tab in [["EmployeesTab", "employed"], ["RecruitmentTab", "recruits"], ["ArmoryTab", "armory"]]:
		var btn := tabs.get_node(str(tab[0])) as Button
		btn.add_theme_color_override("font_color", BLUE if roster_tab == str(tab[1]) else INK)
		btn.pressed.connect(_set_roster_tab.bind(str(tab[1])))

func _focus_person(id: String) -> void:
	selected_merc = id
	_refresh()

func _draw_employees() -> void:
	var left := _mount_page(PERSONNEL_EMPLOYEES_LEFT, left_leaf)
	var right := _mount_page(PERSONNEL_EMPLOYEES_RIGHT, right_leaf)
	var roster := left.get_node("Employed/Items") as VBoxContainer
	if selected_merc.is_empty() and not game.crew.is_empty():
		selected_merc = str(game.crew[0]["id"])
	for person in game.crew:
		var id: String = str(person["id"])
		var row := _make_row(ROW_EMPLOYEE, roster)
		var name_label := _row_text(row, "Name", str(person["name"]))
		name_label.add_theme_color_override("font_color", BLUE if id == selected_merc else INK)
		_row_text(row, "Details", "%s  •  %d%% health" % [str(person["role"]), int(person.get("health", 100))])
		_row_button(row, "View", "VIEW  →", _focus_person.bind(id), true, id == selected_merc)
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
	var left := _mount_page(PERSONNEL_RECRUITS_LEFT, left_leaf)
	var right := _mount_page(PERSONNEL_RECRUITS_RIGHT, right_leaf)
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
	var left := _mount_page(PERSONNEL_ARMORY_LEFT, left_leaf)
	var right := _mount_page(PERSONNEL_ARMORY_RIGHT, right_leaf)
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
	var left := _mount_page(EXCHANGE_LEFT, left_leaf)
	var right := _mount_page(EXCHANGE_RIGHT, right_leaf)
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
		_row_button(row, "Inspect", "INSPECT  →", _choose_commodity.bind(key), true, selected)
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
	var left := _mount_page(FINANCE_LEFT, left_leaf)
	var right := _mount_page(FINANCE_RIGHT, right_leaf)
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
	var left := _mount_page(GUILDWORK_LEFT, left_leaf)
	var right := _mount_page(GUILDWORK_RIGHT, right_leaf)
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
	var left := _mount_page(CHRONICLE_LEFT, left_leaf)
	var right := _mount_page(CHRONICLE_RIGHT, right_leaf)
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
	var left := _mount_page(REGIONS_LEFT, left_leaf)
	var right := _mount_page(REGIONS_RIGHT, right_leaf)
	var regions := left.get_node("Regions/Items") as VBoxContainer
	for region in MoneyMercsState.REGIONS:
		var entry := _make_row(ROW_REGION, regions)
		var id: String = str(region["id"])
		_row_text(entry, "Name", str(region["name"]))
		_row_text(entry, "Tagline", str(region.get("tagline", "")))
		_row_button(entry, "Inspect", "INSPECT  →", _select_region.bind(id), true, selected_region == id)
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
