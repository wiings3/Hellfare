extends "res://scripts/book_shell.gd"
## Active book screens. Page content and interactions only.
## Shared book art, tab animation, input hitboxes, and drawing primitives live in book_shell.gd.

const JOURNAL_RECORD := preload("res://scenes/journal/widgets/journal_record.tscn")
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
func _record(parent: Node, height: int, width: int = 465) -> Control:
	var frame := JOURNAL_RECORD.instantiate() as PanelContainer
	frame.custom_minimum_size = Vector2(width, height)
	parent.add_child(frame)
	var contents := frame.get_node("Content") as Control
	contents.custom_minimum_size = Vector2(width, height)
	return contents

# Add a hand-authored page directly into its fixed editor leaf region.
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
	for merc in game.available_guild_workers():
		if str(merc.get("role", "")) not in ["Miner", "Guard"]:
			continue
		var entry := _record(roster, 61, 449)
		var id: String = str(merc["id"])
		var assigned: bool = selected_crew.has(id)
		_text(entry, "%s  (%s)" % [str(merc["name"]), str(merc["role"])],
			8, 4, 275, 27, 17, true)
		_text(entry, "Health %d%%   •   Gear %d/2" % [
			int(merc.get("health", 100)), _equipped_count(merc)],
			8, 32, 288, 22, 13, false, INK_SOFT)
		_book_button(entry, "REMOVE" if assigned else "ASSIGN", 313, 10, 122, 42,
			_toggle_crew.bind(not assigned, id))
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
	var forecast: String = "Unknown — scout first" if not intel else "%d%% success chance" % int(round(float(stats["success"]) * 100.0))
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
		var row := _record(roster, 75, 462)
		_text(row, str(person["name"]), 10, 5, 242, 29, 18, true,
			BLUE if id == selected_merc else INK)
		_text(row, "%s  •  %d%% health" % [str(person["role"]), int(person.get("health", 100))],
			11, 39, 274, 25, 14, false, INK_SOFT)
		_text_button(row, "VIEW  →", 334, 16, 119, 39,
			_focus_person.bind(id), id == selected_merc)
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
		var record := _record(offers, 87, 462)
		_text(record, str(candidate["name"]), 8, 7, 266, 30, 19, true)
		_text(record, "%s  •  Skill %d  •  Wage %d G" % [
			str(candidate["role"]), int(candidate["skill"]), int(candidate["wage"])],
			9, 37, 320, 24, 14, false, INK_SOFT)
		var hire_button := _text_button(record, "HIRE %d G" % int(candidate["hire"]),
			320, 22, 142, 41, _hire.bind(str(candidate["id"])))
		hire_button.disabled = game.gold < int(candidate["hire"])
	_page_value(right, "Treasury", _money(game.gold))
	_page_value(right, "Workers", str(game.crew.size()))

func _draw_armory_page() -> void:
	var left := _mount_page(PERSONNEL_ARMORY_LEFT, left_leaf)
	var right := _mount_page(PERSONNEL_ARMORY_RIGHT, right_leaf)
	if selected_merc.is_empty() and not game.crew.is_empty():
		selected_merc = str(game.crew[0]["id"])
	var crew_picker := left.get_node("CrewPicker/Items") as VBoxContainer
	for person in game.crew:
		var row := _record(crew_picker, 60, 459)
		var id: String = str(person["id"])
		_text(row, "%s / %s" % [str(person["name"]), str(person["role"])],
			7, 9, 303, 34, 16, true)
		_text_button(row, "SELECT", 335, 10, 118, 39,
			_choose_worker.bind(id), id == selected_merc)
	var stash := left.get_node("Stash/Items") as VBoxContainer
	var owner: Dictionary = game.merc_by_id(selected_merc)
	for item in game.equipment_inventory:
		var definition: Dictionary = game.item_definition(str(item.get("key", "")))
		var row := _record(stash, 59, 462)
		_text(row, str(definition.get("name", "Unknown")), 9, 4, 244, 28, 16, true)
		_text(row, "Owned  /  %s" % str(definition.get("slot", "tool")), 9, 28, 277, 22, 13, false, INK_SOFT)
		var equip_button := _text_button(row, "EQUIP", 278, 8, 89, 40,
			_equip.bind(selected_merc, str(item.get("uid", ""))))
		equip_button.disabled = owner.is_empty() or not game.is_available(owner) or not MercsV05.validate_role(str(item.get("key", "")), owner)
		_text_button(row, "SELL", 375, 8, 83, 40,
			_sell_equipment.bind(str(item.get("uid", ""))))
	if game.equipment_inventory.is_empty():
		var empty := _record(stash, 63, 460)
		_text(empty, "No equipment in storage.", 10, 12, 431, 39, 16, false, INK_SOFT)
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
		var row := _record(catalog, 63, 444)
		_text(row, str(definition.get("name", "")), 7, 4, 273, 28, 16, true)
		_text(row, "%s  •  %s" % [str(definition.get("role", "")), str(definition.get("slot", ""))],
			8, 29, 281, 21, 13, false, INK_SOFT)
		_text_button(row, "%d G" % int(definition["cost"]), 310, 10, 126, 40,
			_buy_equipment.bind(str(key)))

func _choose_commodity(id: String) -> void:
	selected_market_item = id
	_refresh()

func _draw_exchange() -> void:
	var left := _mount_page(EXCHANGE_LEFT, left_leaf)
	var right := _mount_page(EXCHANGE_RIGHT, right_leaf)
	var stock := left.get_node("Stock/Items") as VBoxContainer
	for id in MoneyMercsState.RESOURCE_ORDER:
		var key: String = str(id)
		var row := _record(stock, 61, 462)
		if key == selected_market_item:
			_tint(row, 0, 0, 462, 61, Color("#762c37", 0.10))
		_text(row, str(MoneyMercsState.RESOURCE_NAMES[key]), 9, 6, 296, 27,
			17, true, BLUE if selected_market_item == key else INK)
		_text(row, "Stored: %d    |    Sell: %d G" % [
			int(game.resources.get(key, 0)), game.sell_price(key)],
			9, 31, 290, 22, 14, false, INK_SOFT)
		_text_button(row, "INSPECT  →", 316, 12, 141, 39,
			_choose_commodity.bind(key), selected_market_item == key)
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
		var line := _record(stores, 49, 452)
		_text(line, str(MoneyMercsState.RESOURCE_NAMES.get(str(id), str(id))),
			11, 8, 285, 29, 17, true)
		_text(line, str(quantity) + " owned", 320, 8, 123, 29,
			15, false, INK_SOFT)
		owned += 1
	if owned == 0:
		var blank := _record(stores, 74, 450)
		_text(blank, "Nothing stored in the warehouse.", 10, 13, 420, 46,
			16, false, INK_SOFT)

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
		var row := _record(workers, 72, 444)
		var who: String = str(member.get("name", "Contractor"))
		_text(row, who, 10, 5, 276, 32, 17, true)
		_text(row, "No injury or equipment risk", 10, 34, 292, 22,
			14, false, INK_SOFT)
		_book_button(row, "ASSIGN", 320, 14, 112, 42,
			_guild_work.bind(str(member["id"])), can_take)
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
		var row := _record(records, 74, 459)
		if i == selected_report_index:
			_tint(row, 0, 0, 459, 74, Color("#762c37", 0.10))
		_text(row, str(entry.get("region", "Unknown assignment")),
			9, 7, 302, 30, 17, true)
		_text(row, "Completed" if bool(entry.get("won", false)) else "Costly return",
			10, 39, 290, 24, 14, false, BLUE if bool(entry.get("won", false)) else OXBLOOD)
		_text_button(row, "READ", 342, 17, 109, 39,
			_choose_report.bind(i), i == selected_report_index)
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
		var note := _record(events, 60, 444)
		_text(note, str(event), 8, 3, 428, 54, 13, false, INK_SOFT, true)
	if (report.get("events", []) as Array).is_empty():
		var blank := _record(events, 57, 444)
		_text(blank, _loot_text(report.get("loot", {})), 8, 7, 427, 45,
			14, false, INK_SOFT, true)

func _draw_regions() -> void:
	var left := _mount_page(REGIONS_LEFT, left_leaf)
	var right := _mount_page(REGIONS_RIGHT, right_leaf)
	var regions := left.get_node("Regions/Items") as VBoxContainer
	for region in MoneyMercsState.REGIONS:
		var entry := _record(regions, 107, 464)
		var id: String = str(region["id"])
		_text(entry, str(region["name"]), 9, 4, 442, 33, 18, true)
		_text(entry, str(region.get("tagline", "")), 9, 37, 440, 28,
			14, false, INK_SOFT)
		_text_button(entry, "INSPECT  →", 314, 69, 138, 32,
			_select_region.bind(id), selected_region == id)
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
