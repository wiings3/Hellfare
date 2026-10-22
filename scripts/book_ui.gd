extends "res://scripts/book_shell.gd"
## Active book screens. Page content and interactions only.
## Shared book art, tab animation, input hitboxes, and drawing primitives live in book_shell.gd.

const JOURNAL_SCROLL := preload("res://scenes/journal/widgets/journal_scroll.tscn")
const JOURNAL_RECORD := preload("res://scenes/journal/widgets/journal_record.tscn")

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
func _scroll(parent: Node, x: float, y: float, w: float, h: float) -> VBoxContainer:
	var wrapper := JOURNAL_SCROLL.instantiate() as ScrollContainer
	wrapper.position = Vector2(x, y)
	wrapper.size = Vector2(w, h)
	parent.add_child(wrapper)
	var content := wrapper.get_node("Items") as VBoxContainer
	content.custom_minimum_size.x = w - 21
	return content

func _record(parent: Node, height: int, width: int = 465) -> Control:
	var frame := JOURNAL_RECORD.instantiate() as PanelContainer
	frame.custom_minimum_size = Vector2(width, height)
	parent.add_child(frame)
	var contents := frame.get_node("Content") as Control
	contents.custom_minimum_size = Vector2(width, height)
	return contents

func _page_heading(parent: Node, heading_text: String, small: String = "") -> void:
	_text(parent, heading_text, 6, 1, 464, 37, 22, true)
	if not small.is_empty():
		_text(parent, small, 7, 38, 464, 24, 14, false, INK_SOFT)
	_label_rule(parent, 5, 68, 466)

func _field(parent: Node, caption: String, value: String, y: int) -> void:
	_text(parent, caption, 9, y, 244, 26, 16, false, INK_SOFT)
	_text(parent, value, 270, y, 204, 29, 18, true, INK)
	_label_rule(parent, 8, y + 35, 464)

func _draw_company() -> void:
	_page_heading(left_leaf, "Guild Balance Sheet", "An honest account of the company.")
	_field(left_leaf, "Cash in treasury", _money(game.gold), 88)
	_field(left_leaf, "Total company value", _money(game.wealth()), 141)
	_field(left_leaf, "Contractors employed", str(game.crew.size()), 194)
	_field(left_leaf, "Ready for work", str(game.free_crew()), 247)
	_field(left_leaf, "Outstanding debt", _money(game.relief_debt), 300)
	_book_button(left_leaf, "Review Harlow Mines", 20, 371, 300, 42,
		_turn_to.bind("harlow"))
	_text(left_leaf, "The company grows by earning its way back.", 22, 441, 462, 48,
		16, false, INK_SOFT, true)
	_page_heading(right_leaf, "Today's Business", "Your field teams and their reports.")
	_field(right_leaf, "Active expeditions", str(game.missions.size()), 89)
	_field(right_leaf, "Reputation", str(game.reputation), 141)
	_text(right_leaf, "MOST RECENT REPORT", 9, 214, 457, 24, 15, true, BLUE)
	if game.reports.is_empty():
		_text(right_leaf, "No completed expeditions are in the journal yet.",
			10, 249, 460, 60, 17, false, INK_SOFT, true)
	else:
		var last: Dictionary = game.reports[0]
		_text(right_leaf, str(last.get("region", "Unnamed expedition")),
			10, 249, 442, 28, 20, true)
		_text(right_leaf, "Returned safely" if bool(last.get("won", false)) else "Costly return",
			10, 287, 444, 26, 16, false, OXBLOOD if not bool(last.get("won", false)) else BLUE)
		_text(right_leaf, _loot_text(last.get("loot", {})), 10, 320, 440, 56,
			15, false, INK_SOFT, true)
	_book_button(right_leaf, "Read the Chronicle", 16, 383, 275, 42,
		_turn_to.bind("ledger"))
	_text_button(right_leaf, "Safe Guild Work  →", 18, 447, 235, 36,
		_turn_to.bind("guildwork"))

func _draw_harlow() -> void:
	_page_heading(left_leaf, "I. Site Intelligence", "Scouting is safe. Expeditions are not.")
	var report: Dictionary = game.harlow.get("report", {})
	var waiting: bool = int(game.harlow.get("scout_finish", 0)) > 0
	_text(left_leaf, "HARLOW MINES", 9, 87, 442, 31, 21, true)
	if report.is_empty():
		_text(left_leaf, "Survey in progress" if waiting else "Not yet surveyed",
			9, 131, 433, 29, 18, false, OXBLOOD)
		_text(left_leaf, "A scout returns with intelligence. Improve your scout to learn more.",
			9, 174, 433, 69, 16, false, INK_SOFT, true)
		if waiting:
			_text(left_leaf, "Returns in %s" % _duration(maxi(0, int(game.harlow["scout_finish"]) - int(Time.get_unix_time_from_system()))),
				10, 254, 425, 28, 16, false, BLUE)
		_book_button(left_leaf, "Dispatch Scout" if not waiting else "Scout Away",
			10, 300, 241, 42, _scout, not waiting)
	else:
		_field(left_leaf, "Confirmed veins", "At least %d" % int(report.get("minimum", 0)), 135)
		_text(left_leaf, "THREAT OBSERVED", 9, 202, 430, 24, 15, false, INK_SOFT)
		_text(left_leaf, str(report.get("creature", "Unknown")), 9, 232, 436, 34,
			20, true, OXBLOOD)
		_text(left_leaf, "Report expires when the mine rotates.", 9, 288, 430, 29,
			15, false, INK_SOFT)
	var level: int = int(game.harlow.get("scout_level", 1))
	_text(left_leaf, "SCOUT TRAINING  %d / 3" % level, 10, 362, 427, 27, 16, true)
	if level < 3:
		var price: int = 200 if level == 1 else 650
		_book_button(left_leaf, "Train Scout  /  %d G" % price,
			10, 406, 269, 40, _train_scout, game.gold >= price)
	_text_button(left_leaf, "Other regional contracts  →", 10, 468, 337, 32,
		_turn_to.bind("expeditions"))
	_page_heading(right_leaf, "II. Expedition Orders", "Choose miners, guards and your risk.")
	var roster := _scroll(right_leaf, 5, 78, 475, 199)
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
	_text(right_leaf, "Standing Orders", 9, 293, 214, 24, 15, true)
	var stance := OptionButton.new()
	stance.position = Vector2(230, 295)
	stance.size = Vector2(239, 32)
	stance.add_theme_font_override("font", body_font)
	stance.add_theme_font_size_override("font_size", 15)
	for t in MoneyMercsState.TACTICS:
		stance.add_item(str(t))
	stance.select(maxi(0, MoneyMercsState.TACTICS.find(tactic)))
	stance.item_selected.connect(func(i: int) -> void:
		_set_tactic(str(MoneyMercsState.TACTICS[i]))
	)
	right_leaf.add_child(stance)
	_field(right_leaf, "Mining capacity", "%d veins" % int(stats["capacity"]), 337)
	_field(right_leaf, "Dispatch cost", _money(int(stats["wage"])), 379)
	var intel: bool = not report.is_empty()
	var forecast: String = "Unknown — scout first" if not intel else "%d%% success chance" % int(round(float(stats["success"]) * 100.0))
	_text(right_leaf, forecast, 9, 420, 466, 28, 16, true, OXBLOOD if not intel else BLUE)
	var ore_count: int = 0
	for amount in (game.harlow.get("deposits", {}) as Dictionary).values():
		ore_count += int(amount)
	var possible: bool = int(stats["miners"]) > 0 and ids.size() <= 3 and ore_count > 0 and game.gold >= int(stats["wage"]) and game.missions.size() < game.expedition_slots
	_text(right_leaf, "Mercenary deaths and lost equipment are permanent.",
		11, 445, 464, 23, 14, false, OXBLOOD)
	_book_button(right_leaf, "Fund Expedition", 11, 473, 295, 42,
		_dispatch_harlow, possible)

func _draw_people() -> void:
	var subtabs: Array = [["employed", "EMPLOYEES"], ["recruits", "RECRUITMENT"], ["armory", "ARMORY"]]
	for i in range(subtabs.size()):
		var tab: Array = subtabs[i]
		_text_button(left_leaf, str(tab[1]), 2 + i * 169, 0, 160, 38,
			_set_roster_tab.bind(str(tab[0])), roster_tab == str(tab[0]))
	_label_rule(left_leaf, 5, 44, 464)
	match roster_tab:
		"employed": _draw_employees()
		"recruits": _draw_recruitment()
		"armory": _draw_armory_page()

func _focus_person(id: String) -> void:
	selected_merc = id
	_refresh()

func _draw_employees() -> void:
	_text(left_leaf, "UNDER CONTRACT", 10, 57, 450, 28, 18, true)
	var roster := _scroll(left_leaf, 4, 97, 493, 396)
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
	if game.crew.is_empty():
		_text(left_leaf, "The payroll is empty. Recruit a miner or a guard to begin.",
			9, 105, 449, 98, 17, false, INK_SOFT, true)
		_book_button(left_leaf, "Open Recruitment", 10, 223, 274, 45,
			_set_roster_tab.bind("recruits"))
	_page_heading(right_leaf, "Employee Dossier", "Read contracts before assigning crews.")
	var person: Dictionary = game.merc_by_id(selected_merc)
	if person.is_empty():
		_text(right_leaf, "Select a contractor to inspect their dossier.",
			8, 104, 461, 63, 17, false, INK_SOFT, true)
		return
	_text(right_leaf, str(person["name"]), 10, 84, 453, 44, 25, true)
	_field(right_leaf, "Occupation", str(person["role"]), 145)
	_field(right_leaf, "Skill", str(int(person.get("skill", 0))), 190)
	_field(right_leaf, "Health", "%d%%" % int(person.get("health", 100)), 235)
	_field(right_leaf, "Daily wage", _money(int(person.get("wage", 0))), 280)
	var equipped: Dictionary = person.get("equipment", {})
	_text(right_leaf, "TOOL: %s" % _equipment_name(equipped.get("tool", {})),
		12, 342, 460, 26, 15, false, INK_SOFT)
	_text(right_leaf, "ARMOR: %s" % _equipment_name(equipped.get("armor", {})),
		12, 375, 460, 26, 15, false, INK_SOFT)
	_book_button(right_leaf, "Open Armory", 10, 431, 225, 43,
		_outfit.bind(selected_merc))
	_book_button(right_leaf, "Renegotiate Terms", 244, 431, 228, 43,
		_terms.bind(selected_merc))
	if int(person.get("health", 100)) < 100:
		_text_button(right_leaf, "Pay for treatment  →", 16, 479, 278, 31,
			_heal.bind(selected_merc))

func _draw_recruitment() -> void:
	_text(left_leaf, "APPLICANTS", 10, 58, 440, 32, 19, true)
	_text(left_leaf, "Candidates change regularly.", 10, 90, 450, 23, 14, false, INK_SOFT)
	var offers := _scroll(left_leaf, 4, 126, 492, 382)
	for candidate in game.recruitment_board():
		var record := _record(offers, 87, 462)
		_text(record, str(candidate["name"]), 8, 7, 266, 30, 19, true)
		_text(record, "%s  •  Skill %d  •  Wage %d G" % [
			str(candidate["role"]), int(candidate["skill"]), int(candidate["wage"])],
			9, 37, 320, 24, 14, false, INK_SOFT)
		var hire_button := _text_button(record, "HIRE %d G" % int(candidate["hire"]),
			320, 22, 142, 41, _hire.bind(str(candidate["id"])))
		hire_button.disabled = game.gold < int(candidate["hire"])
	_page_heading(right_leaf, "The Signing Desk", "Contractors are hired, not summoned.")
	_text(right_leaf, "HIRING", 9, 95, 454, 26, 17, true)
	_text(right_leaf, "An applicant's signing fee is paid immediately. Wages and a share of recovered wealth follow after each expedition.",
		10, 134, 447, 126, 17, false, INK_SOFT, true)
	_field(right_leaf, "Treasury available", _money(game.gold), 278)
	_field(right_leaf, "Workers employed", str(game.crew.size()), 329)
	_text(right_leaf, "A fallen mercenary cannot be rehired. The company must replace them from new applicants.",
		10, 393, 455, 94, 16, false, OXBLOOD, true)

func _draw_armory_page() -> void:
	_text(left_leaf, "THE QUARTERMASTER", 10, 56, 446, 32, 20, true)
	_text(left_leaf, "Choose a worker, then assign stored gear.", 10, 89, 451, 30, 14, false, INK_SOFT)
	if selected_merc.is_empty() and not game.crew.is_empty():
		selected_merc = str(game.crew[0]["id"])
	var crew_picker := _scroll(left_leaf, 5, 130, 491, 174)
	for person in game.crew:
		var row := _record(crew_picker, 60, 459)
		var id: String = str(person["id"])
		_text(row, "%s / %s" % [str(person["name"]), str(person["role"])],
			7, 9, 303, 34, 16, true)
		_text_button(row, "SELECT", 335, 10, 118, 39, _choose_worker.bind(id), id == selected_merc)
	_text(left_leaf, "UNASSIGNED EQUIPMENT", 10, 317, 455, 27, 16, true)
	var stash := _scroll(left_leaf, 5, 348, 492, 155)
	var owner: Dictionary = game.merc_by_id(selected_merc)
	for item in game.equipment_inventory:
		var def: Dictionary = game.item_definition(str(item.get("key", "")))
		var row := _record(stash, 59, 462)
		_text(row, str(def.get("name", "Unknown")), 9, 4, 244, 28, 16, true)
		_text(row, "Owned  /  %s" % str(def.get("slot", "tool")), 9, 28, 277, 22, 13, false, INK_SOFT)
		var equip_button := _text_button(row, "EQUIP", 278, 8, 89, 40,
			_equip.bind(selected_merc, str(item.get("uid", ""))))
		equip_button.disabled = owner.is_empty() or not game.is_available(owner) or not MercsV05.validate_role(str(item.get("key", "")), owner)
		_text_button(row, "SELL", 375, 8, 83, 40,
			_sell_equipment.bind(str(item.get("uid", ""))))
	if game.equipment_inventory.is_empty():
		var empty := _record(stash, 63, 460)
		_text(empty, "No equipment in storage.", 10, 12, 431, 39, 16, false, INK_SOFT)
	_page_heading(right_leaf, "Arms & Provisions", "Purchased equipment belongs to the guild.")
	if not owner.is_empty():
		var worn: Dictionary = owner.get("equipment", {})
		_text(right_leaf, "OUTFITTING: %s" % str(owner.get("name", "")), 9, 81, 453, 28, 17, true)
		for i in range(2):
			var slot: String = "tool" if i == 0 else "armor"
			var equipped: Dictionary = worn.get(slot, {})
			var y: float = 117.0 + float(i) * 48.0
			_text(right_leaf, "%s: %s" % [slot.capitalize(), _equipment_name(equipped)],
				9, y, 332, 35, 15)
			if not equipped.is_empty():
				_text_button(right_leaf, "REMOVE", 348, y, 112, 35,
					_unequip.bind(selected_merc, slot))
	_label_rule(right_leaf, 8, 214, 459)
	_text(right_leaf, "PURCHASE EQUIPMENT", 10, 221, 460, 29, 17, true)
	var catalog := _scroll(right_leaf, 6, 262, 478, 244)
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
	_page_heading(left_leaf, "Merchant Stock", "Select an item for its buying and selling price.")
	var stock := _scroll(left_leaf, 5, 83, 491, 429)
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
	_page_heading(right_leaf, "The Exchange Desk", "All prices settled in gold.")
	var name: String = str(MoneyMercsState.RESOURCE_NAMES.get(selected_market_item, "Unknown item"))
	_text(right_leaf, name, 9, 91, 457, 43, 24, true)
	_text(right_leaf, str(MoneyMercsState.RESOURCE_DESC.get(selected_market_item, "")),
		10, 139, 457, 74, 15, false, INK_SOFT, true)
	_field(right_leaf, "Quantity owned", str(game.resources.get(selected_market_item, 0)), 228)
	_field(right_leaf, "Merchant sells for", _money(game.buy_price(selected_market_item)), 279)
	_field(right_leaf, "Merchant buys for", _money(game.sell_price(selected_market_item)), 329)
	_book_button(right_leaf, "Buy One", 10, 387, 202, 45,
		_trade.bind(selected_market_item, true, 1),
		game.gold >= game.buy_price(selected_market_item))
	_book_button(right_leaf, "Sell One", 224, 387, 200, 45,
		_trade.bind(selected_market_item, false, 1),
		int(game.resources.get(selected_market_item, 0)) > 0)
	var sell_all := _text_button(right_leaf, "Sell all in storage  →", 13, 446, 341, 36,
		_trade.bind(selected_market_item, false, int(game.resources.get(selected_market_item, 0))))
	sell_all.disabled = int(game.resources.get(selected_market_item, 0)) <= 0
	_text(right_leaf, "Markets between players are not implemented yet.", 12, 489,
		462, 29, 13, false, INK_LIGHT)

func _draw_accounts() -> void:
	_page_heading(left_leaf, "Company Balance", "Gold is the working capital of your guild.")
	_field(left_leaf, "Gold on hand", _money(game.gold), 87)
	_field(left_leaf, "Appraised net worth", _money(game.wealth()), 142)
	_field(left_leaf, "Equipment valuation", _money(game.owned_equipment_value()), 197)
	_field(left_leaf, "Outstanding loans", _money(game.relief_debt), 252)
	_field(left_leaf, "Guild reputation", str(game.reputation), 307)
	_book_button(left_leaf, "Visit the Exchange", 9, 393, 279, 44, _turn_to.bind("market"))
	_text(left_leaf, "Stored ore and weapons raise your company's value; they do not pay wages until sold.",
		10, 451, 471, 66, 15, false, INK_SOFT, true)
	_page_heading(right_leaf, "Storehouse Register", "Commodities held by the company.")
	var stores := _scroll(right_leaf, 4, 91, 478, 338)
	var owned: int = 0
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
	_text(right_leaf, "Remember: running out of liquid gold doesn't mean your company has no assets.",
		10, 446, 463, 61, 15, false, INK_SOFT, true)

func _draw_guild_jobs() -> void:
	_page_heading(left_leaf, "Reliable Contracts", "When the mines go badly, honest wages remain.")
	_text(left_leaf, "Guild work is risk-free, requires no equipment and continues while you are away.",
		10, 98, 455, 86, 17, false, INK_SOFT, true)
	var can_take: bool = game.can_accept_guild_work() and game.missions.size() < game.expedition_slots
	_text(left_leaf, "OFFICE PAPERWORK", 10, 208, 425, 30, 18, true)
	_text(left_leaf, "Three minutes  •  Earn 9 G  •  No workers needed",
		10, 246, 461, 28, 15, false, INK_SOFT)
	_book_button(left_leaf, "Accept Office Work", 11, 292, 314, 44,
		_guild_work.bind(""), can_take)
	_label_rule(left_leaf, 10, 359, 451)
	_text(left_leaf, "CONTRACTOR LABOR", 10, 375, 438, 26, 18, true)
	_text(left_leaf, "Two and a half minutes  •  Earn 18 G",
		10, 410, 455, 27, 15, false, INK_SOFT)
	_text_button(left_leaf, "Return to Harlow Mines  →", 10, 465, 330, 34,
		_turn_to.bind("harlow"))
	_page_heading(right_leaf, "Assign a Safe Job", "A small but guaranteed payment.")
	var workers := _scroll(right_leaf, 5, 88, 479, 310)
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
	if count == 0:
		_text(right_leaf, "No available mercenaries. You can still complete office paperwork alone.",
			10, 114, 450, 89, 17, false, INK_SOFT, true)
	_text(right_leaf, "Eligibility: below 120 G cash and 250 G in net worth.",
		10, 426, 458, 67, 15, false, INK_SOFT, true)

func _choose_report(index: int) -> void:
	selected_report_index = index
	_refresh()

func _draw_history() -> void:
	_page_heading(left_leaf, "After-action Reports", "Good fortune and costly lessons alike.")
	var records := _scroll(left_leaf, 5, 83, 491, 420)
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
	if game.reports.is_empty():
		_text(left_leaf, "No field reports have been filed yet.",
			11, 110, 453, 59, 17, false, INK_SOFT, true)
		_book_button(left_leaf, "Inspect Contracts", 10, 192, 283, 44,
			_turn_to.bind("harlow"))
	_page_heading(right_leaf, "Return & Losses", "The firm's permanent record.")
	if game.reports.is_empty():
		_text(right_leaf, "Reports are filed here when field teams return.",
			10, 109, 448, 73, 17, false, INK_SOFT, true)
		return
	var idx: int = clampi(selected_report_index, 0, game.reports.size() - 1)
	var report: Dictionary = game.reports[idx]
	_text(right_leaf, str(report.get("region", "Unknown expedition")),
		8, 91, 445, 39, 21, true)
	_field(right_leaf, "Outcome", "Success" if bool(report.get("won", false)) else "Failed",
		149)
	_field(right_leaf, "Gold recovered", _money(int(report.get("cash", 0))), 195)
	_field(right_leaf, "Mission costs", _money(int(report.get("cost", 0))), 241)
	var deaths: Array = report.get("casualties", [])
	_field(right_leaf, "Casualties", str(deaths.size()), 287)
	_text(right_leaf, "EVENT LOG", 9, 341, 447, 27, 16, true, BLUE)
	var events := _scroll(right_leaf, 6, 371, 477, 135)
	for event in report.get("events", []):
		var note := _record(events, 60, 444)
		_text(note, str(event), 8, 3, 428, 54,
			13, false, INK_SOFT, true)
	if (report.get("events", []) as Array).is_empty():
		var blank := _record(events, 57, 444)
		_text(blank, _loot_text(report.get("loot", {})), 8, 7, 427, 45,
			14, false, INK_SOFT, true)

func _draw_regions() -> void:
	_page_heading(left_leaf, "Open Assignments", "Some routes remain under old dispatch rules.")
	var regions := _scroll(left_leaf, 4, 89, 490, 403)
	for region in MoneyMercsState.REGIONS:
		var entry := _record(regions, 107, 464)
		var id: String = str(region["id"])
		_text(entry, str(region["name"]), 9, 4, 442, 33, 18, true)
		_text(entry, str(region.get("tagline", "")), 9, 37, 440, 28,
			14, false, INK_SOFT)
		_text_button(entry, "INSPECT  →", 314, 69, 138, 32,
			_select_region.bind(id), selected_region == id)
	_page_heading(right_leaf, "Dispatch Order", "Review required supplies and threat level.")
	var site: Dictionary = {}
	for r in MoneyMercsState.REGIONS:
		if str(r["id"]) == selected_region:
			site = r
	if site.is_empty():
		return
	_text(right_leaf, str(site["name"]), 10, 89, 445, 59, 20, true, INK, true)
	_field(right_leaf, "Threat rating", str(site.get("threat", 0)), 165)
	_field(right_leaf, "Supply cost", _money(int(site.get("supplies", 0))), 219)
	_field(right_leaf, "Required reputation", str(site.get("rep", 0)), 273)
	_text(right_leaf, str(site.get("tagline", "")), 12, 335, 454, 66,
		16, false, INK_SOFT, true)
	var can_start: bool = game.free_crew() > 0 and game.reputation >= int(site.get("rep", 0)) and game.missions.size() < game.expedition_slots
	_book_button(right_leaf, "Dispatch Crew", 12, 427, 280, 45,
		_old_dispatch.bind(str(site["id"])), can_start)
	_text_button(right_leaf, "Harlow Mines  →", 14, 483, 245, 33,
		_turn_to.bind("harlow"))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var pages: Array[String] = ["hq", "harlow", "roster", "market", "finance", "ledger", "guildwork"]
		var index: int = int(event.keycode) - int(KEY_1)
		if index >= 0 and index < pages.size():
			_turn_to(pages[index])
