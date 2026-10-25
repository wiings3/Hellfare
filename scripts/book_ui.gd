extends "res://scripts/book_shell.gd"
## Active book screens: page content and interactions only.
## Every page layout is an editor scene under scenes/journal/pages/; this script
## only binds live game data, connects buttons and instances repeating rows.

const COMPANY_LEFT := preload("res://scenes/journal/pages/company_left.tscn")
const COMPANY_RIGHT := preload("res://scenes/journal/pages/company_right.tscn")
const COMPANY_MAP := preload("res://scenes/journal/pages/company_map.tscn")
const COMPANY_TABS := preload("res://scenes/journal/pages/company_tabs.tscn")
const ROW_FALLEN := preload("res://scenes/journal/rows/fallen_row.tscn")
## Most items listed on a fallen-gear card.
const FALLEN_ROWS := 6
const FINANCE_LEFT := preload("res://scenes/journal/pages/finance_left.tscn")
const FINANCE_RIGHT := preload("res://scenes/journal/pages/finance_right.tscn")
const EXCHANGE_LEFT := preload("res://scenes/journal/pages/exchange_left.tscn")
const EXCHANGE_RIGHT := preload("res://scenes/journal/pages/exchange_right.tscn")
const EXCHANGE_TABS := preload("res://scenes/journal/pages/exchange_tabs.tscn")
const HALL_LEFT := preload("res://scenes/journal/pages/hall_left.tscn")
const HALL_RIGHT := preload("res://scenes/journal/pages/hall_right.tscn")
const ROW_CHAT_LINE := preload("res://scenes/journal/rows/chat_line.tscn")
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

const BUSTS := {
	"Woodcutter": preload("res://assets/ui/portraits/miner_bust.png"),
	"Miner": preload("res://assets/ui/portraits/miner_bust.png"),
	"Guard": preload("res://assets/ui/portraits/guard_bust.png"),
	"Scout": preload("res://assets/ui/portraits/scout_bust.png"),
}
const ROLE_ICONS := {
	"Miner": preload("res://assets/ui/icons/pickaxe.png"),
	"Guard": preload("res://assets/ui/icons/helmet.png"),
	"Woodcutter": preload("res://assets/ui/icons/axe.png"),
	"Scout": preload("res://assets/ui/icons/herbs.png"),
}
const TRADE_ICONS := {
	"logging": preload("res://assets/ui/icons/axe.png"),
	"mining": preload("res://assets/ui/icons/pickaxe.png"),
	"foraging": preload("res://assets/ui/icons/herbs.png"),
	"combat": preload("res://assets/ui/icons/sword_steel.png"),
	"dungeon": preload("res://assets/ui/icons/relic.png"),
}
const BOARD_LEFT := preload("res://scenes/journal/pages/board_left.tscn")
const BOARD_RIGHT := preload("res://scenes/journal/pages/board_right.tscn")
const SITE_LEFT := preload("res://scenes/journal/pages/site_left.tscn")
const SITE_RIGHT := preload("res://scenes/journal/pages/site_right.tscn")
const SIGN_PLUS := preload("res://assets/ui/kit/sign_plus.png")
const SIGN_CHECK := preload("res://assets/ui/kit/sign_check.png")
const SIGN_CROSS := preload("res://assets/ui/kit/sign_cross.png")
const ICON_FIELD := preload("res://assets/ui/tab_icons/expeditions.png")
const ICON_GUILD := preload("res://assets/ui/tab_icons/company.png")
const PAGE_TITLES := {
	"hq": "The Company",
	"standing": "The Company",
	"harlow": "Harlow Mines",
	"expeditions": "Expeditions",
	"contracts": "Regional Contracts",
	"site": "Expedition",
	"roster": "Personnel",
	"guildwork": "Guild Work",
	"market": "The Exchange",
	"hall": "The Trade Hall",
	"finance": "Treasury & Accounts",
	"ledger": "The Chronicle",
}

## Callables run once a second to move timers and bars without rebuilding pages.
var live_updaters: Array[Callable] = []
var selected_site: String = "mossward_copse"
var market_sampled_at: int = 0

func _ready() -> void:
	page = "hq"
	super._ready()

func _refresh() -> void:
	if not is_instance_valid(stage):
		return
	_update_header()
	live_updaters.clear()
	_hide_link_card()
	_clear(left_leaf)
	_clear(right_leaf)
	_restore_tab_art()
	title_label.text = str(PAGE_TITLES.get(page, "The Company"))
	if page == "harlow":
		page = "site"
		selected_site = "harlow"
	if page == "site":
		title_label.text = str(TradeSites.by_id(selected_site).get("name", "Expedition"))
	match page:
		"hq": _draw_company()
		"standing": _draw_company()
		"harlow": _draw_site()  # Old links to the retired Harlow page open its planner.
		"expeditions": _draw_board()
		"site": _draw_site()
		"contracts": _draw_regions()
		"roster": _draw_people()
		"guildwork": _draw_guild_jobs()
		"market": _draw_exchange()
		"hall": _draw_hall()
		"finance": _draw_accounts()
		"ledger": _draw_history()
		_: _draw_company()

func _update_header() -> void:
	money_label.text = _money(game.gold)
	worth_label.text = "Worth  " + _money(game.wealth())
	missions_label.text = "%d / %d" % [game.missions.size(), game.expedition_slots]

func _live_tick() -> void:
	_update_header()
	_hall_clock()
	if _now() - market_sampled_at >= 60:
		market_sampled_at = _now()
		game.market_tick()
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
	return GameClock.now()

func _mount_page(scene: PackedScene, leaf: Control) -> Control:
	var root := scene.instantiate() as Control
	leaf.add_child(root)
	return root

func _item_icon(key: String) -> Texture2D:
	var path := "res://assets/ui/icons/%s.png" % key
	return load(path) as Texture2D if ResourceLoader.exists(path) else null

func _resource_name(key: String) -> String:
	return str(MoneyMercsState.RESOURCE_NAMES.get(key, key.capitalize()))

func _mission_name(mission: Dictionary) -> String:
	var region: String = str(mission.get("region", ""))
	match region:
		"harlow": return "Harlow Mines"
		"site": return str(TradeSites.by_id(str(mission.get("site", ""))).get("name", "Expedition"))
		"guild_work": return "Guild work"
	return str(game.region_by_id(region).get("name", "Contract"))

func _crew_names(ids: Array) -> String:
	var names: Array[String] = []
	for id in ids:
		var merc: Dictionary = game.merc_by_id(str(id))
		if not merc.is_empty():
			names.append(str(merc.get("name", "?")))
	return ", ".join(names) if not names.is_empty() else "Guild clerk"

## What an expedition brought home: coin plus goods at the merchant price on return.
func _report_value(report: Dictionary) -> int:
	if report.has("value"):
		return int(report["value"])
	var value: int = int(report.get("cash", 0))
	var loot: Dictionary = report.get("loot", {})
	for key in loot:
		value += int(loot[key]) * game.sell_price(str(key))
	return value

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
	var right := _mount_page(COMPANY_RIGHT, right_leaf)
	_bind_company_right(right)
	if page == "hq":
		_draw_region_map()
	else:
		_draw_standing()
	var tabs := _mount_page(COMPANY_TABS, left_leaf)
	for tab in [["MapTab", "hq"], ["StandingTab", "standing"]]:
		var btn := tabs.get_node("Tabs/" + str(tab[0])) as Button
		btn.set_pressed_no_signal(page == str(tab[1]))
		btn.pressed.connect(_nav_to.bind(str(tab[1])))

## The living map: crews walk out to the sites, work, and carry their haul home.
func _draw_region_map() -> void:
	var left := _mount_page(COMPANY_MAP, left_leaf)
	var map := left.get_node("Margin/Content/Map") as RegionMap
	map.describe = func(mission: Dictionary) -> String:
		var phase: float = clampf(float(_now() - int(mission.get("started", _now()))) / maxf(1.0, float(int(mission.get("finish", _now())) - int(mission.get("started", _now())))), 0.0, 1.0)
		var doing: String = "On the road" if phase < RegionMap.OUT else ("At work" if phase < RegionMap.BACK else "Heading home")
		var text: String = "%s: %s\n%s  ·  back in %s" % [_mission_name(mission), doing, _crew_names(mission.get("ids", [])), _duration(maxi(0, int(mission.get("finish", _now())) - _now()))]
		if phase >= RegionMap.FOUND_AT:
			for find in mission.get("finds", []):
				var who: String = str(game.merc_by_id(str(find.get("finder", ""))).get("name", "Someone"))
				text += "\n%s is carrying a %s found among the fallen." % [who, str(game.item_definition(str(find.get("key", ""))).get("name", "find"))]
		return text
	map.show_company(game.missions, game.free_crew())
	var sites := "Margin/Content/Map/Sites/"
	for site in TradeSites.SITES:
		var id: String = str(site["id"])
		if not left.has_node(sites + id):
			continue
		var btn := left.get_node(sites + id) as Button
		var trade: String = str(site["trade"])
		var best: int = int(_best_in(trade)["level"])
		var locked: bool = best < int(site["level"])
		var out: int = 0
		for mission in game.missions:
			if RegionMap.road_for(mission) == id:
				out += 1
		btn.text = str(site["name"]) + ("  ·  %s %d" % [TradeSkills.NAMES.get(trade, trade), int(site["level"])] if locked else "")
		btn.tooltip_text = "%s\n%s" % [str(site["name"]), "Needs %s level %d (yours: %d)." % [TradeSkills.NAMES.get(trade, trade), int(site["level"]), best] if locked else ("%d crew working here." % out if out > 0 else "Click to plan an expedition.")]
		if locked:
			btn.modulate = Color(1, 1, 1, 0.7)
		btn.pressed.connect(_open_site.bind(id))
	_bind_fallen(left)
	var town := left.get_node(sites + "town") as Button
	town.tooltip_text = "Mossward, home of the company.\n%d resting in town." % game.free_crew()
	town.pressed.connect(_nav_to.bind("standing"))
	var status := left.get_node("Margin/Content/Status") as Label
	var update := func() -> void:
		if game.missions.is_empty():
			status.text = "No crews out. Click a site on the map to send one." if game.free_crew() > 0 else "Nobody in the field."
			return
		var next: int = -1
		var name: String = ""
		for mission in game.missions:
			var left_s: int = int(mission.get("finish", _now())) - _now()
			if next < 0 or left_s < next:
				next = left_s
				name = _mission_name(mission)
		status.text = "%s in the field  ·  %s back in %s" % [_plural(game.missions.size(), "crew"), name, _duration(maxi(0, next))]
	update.call()
	live_updaters.append(update)

## Grave markers on the map: how much fallen gear this company could find at each site.
func _bind_fallen(left: Control) -> void:
	var map := "Margin/Content/Map/"
	var card := left.get_node(map + "FallenCard") as Control
	for marker in left.get_node(map + "Fallen").get_children():
		var site_id: String = str(marker.name)
		var badge := marker as Button
		badge.text = str(game.fallen.share(site_id, _now()).size())
		badge.mouse_entered.connect(_show_fallen.bind(card, site_id, badge))
		badge.mouse_exited.connect(func() -> void: card.visible = false)
		badge.pressed.connect(_open_site.bind(site_id))

func _show_fallen(card: Control, site_id: String, badge: Control) -> void:
	var now: int = _now()
	var share: Array[Dictionary] = game.fallen.share(site_id, now)
	var body := "Margin/Body/"
	var site_name: String = str(TradeSites.by_id(site_id).get("name", "the site"))
	(card.get_node(body + "Title") as Label).text = "Fallen at " + site_name
	(card.get_node(body + "Summary") as Label).text = "%d pieces lie here. %d %s within your reach today." % [game.fallen.size(site_id, now), share.size(), "is" if share.size() == 1 else "are"]
	var rows := card.get_node(body + "Rows") as VBoxContainer
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	for i in range(mini(share.size(), FALLEN_ROWS)):
		var item: Dictionary = share[i]
		var key: String = str(item["key"])
		var definition: Dictionary = game.item_definition(key)
		var row := ROW_FALLEN.instantiate()
		rows.add_child(row)
		(row.get_node("Slot/Icon") as TextureRect).texture = _gear_icon(key)
		var name_label := row.get_node("Info/Name") as Label
		name_label.text = str(definition.get("name", key))
		if bool(definition.get("found", false)):
			name_label.theme_type_variation = &"LabelAccent"
		var left_s: int = FallenGear.LIFETIME - (now - int(item["time"]))
		(row.get_node("Info/From") as Label).text = str(item.get("from", ""))
		(row.get_node("Side/Value") as Label).text = _money(int(definition.get("cost", 0)))
		(row.get_node("Side/Left") as Label).text = _duration(maxi(0, left_s)) + " left"
	(card.get_node(body + "Empty") as Control).visible = share.is_empty()
	var reshuffle: int = FallenGear.RESHUFFLE - now % FallenGear.RESHUFFLE
	var more: String = "And %d more. " % (share.size() - FALLEN_ROWS) if share.size() > FALLEN_ROWS else ""
	(card.get_node(body + "Hint") as Label).text = "%s%d%% a trip to find one, more on Deep Push. Yours only if the finder gets home. New share in %s." % [more, int(round(float(FallenGear.FIND_CHANCE["Balanced"]) * 100.0)), _duration(reshuffle)]
	card.visible = true
	card.reset_size()
	var map_size: Vector2 = (card.get_parent() as Control).size
	var card_size: Vector2 = card.get_combined_minimum_size()
	var x: float = clampf(badge.position.x - 10.0, 0.0, maxf(0.0, map_size.x - card_size.x))
	var y: float = badge.position.y + badge.size.y + 2.0
	if y + card_size.y > map_size.y:
		y = maxf(0.0, badge.position.y - card_size.y - 2.0)
	card.position = Vector2(x, y)

func _draw_standing() -> void:
	var left := _mount_page(COMPANY_LEFT, left_leaf)
	var c := "Margin/Content/"
	# Worth and what it is made of.
	var coin: int = maxi(0, game.gold)
	var goods: int = game.goods_value()
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

## Right page: expeditions in the field, then the latest report.
func _bind_company_right(right: Control) -> void:
	var c := "Margin/Content/"
	var list := right.get_node(c + "Expeditions") as VBoxContainer
	for mission in game.missions:
		var row := ROW_EXPEDITION.instantiate() as Control
		list.add_child(row)
		_bind_expedition_row(row, mission)
	for i in range(maxi(0, game.expedition_slots - game.missions.size())):
		var empty := ROW_EMPTY_EXPEDITION.instantiate() as Control
		list.add_child(empty)
		(empty.get_node("Row/Plan") as Button).pressed.connect(_turn_to.bind("expeditions"))
	_bind_latest_report(right)
	var guild := right.get_node(c + "GuildWork") as Button
	guild.visible = game.can_accept_guild_work()
	guild.pressed.connect(_turn_to.bind("guildwork"))

## The guildmaster's note: one clear next step for the player.
func _bind_advice(left: Control) -> void:
	var c := "Margin/Content/"
	var advice := left.get_node(c + "Advice")
	var action := left.get_node(c + "AdviceAction") as Button
	var free: int = game.free_crew()
	var stocked: int = 0
	for key in MoneyMercsState.RESOURCE_ORDER:
		stocked += int(game.resources.get(str(key), 0))
	var note: String
	var kind: String = "alert"
	var label: String = ""
	var target: Callable
	if game.crew.is_empty():
		note = "The company has no mercenaries. Hire a woodcutter: logging at Mossward Copse is safe work that pays from the first trip."
		label = "Hire mercenaries"
		target = _open_recruitment
		kind = "plus"
	elif game.missions.size() >= game.expedition_slots:
		note = "Every crew is in the field. They return on their own, even while the game is closed."
		kind = "check"
	elif stocked >= 20:
		note = "The warehouse holds %d goods. Selling turns them into gold; sell in batches so you don't flood the merchants." % stocked
		label = "Open the Exchange"
		target = _turn_to.bind("market")
		kind = "coin"
	elif free == 0:
		note = "Nobody is free for work. Heal the injured or hire another hand in Personnel."
		label = "Personnel"
		target = _turn_to.bind("roster")
	else:
		note = "A crew is ready. Choose a site on the expedition board and send them out to earn."
		label = "Plan expedition"
		target = _turn_to.bind("expeditions")
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
	var profit: int = _report_value(report) - int(report.get("cost", 0))
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
	var found_gear: Array = report.get("found_gear", [])
	for key in found_gear:
		var slot := ITEM_SLOT.instantiate()
		loot_row.add_child(slot)
		slot.icon = _gear_icon(str(key))
		slot.tooltip_text = "Found among the fallen: %s" % str(game.item_definition(str(key)).get("name", key))
	(right.get_node(body + "Loot") as Control).visible = not loot.is_empty() or not found_gear.is_empty()
	(right.get_node(body + "NoLoot") as Control).visible = loot.is_empty() and found_gear.is_empty()
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

# --- Shared chapter helpers ----------------------------------------------------

const ROW_LIST_CARD := preload("res://scenes/journal/rows/list_card.tscn")
const ROW_ITEM_CARD := preload("res://scenes/journal/rows/item_card.tscn")
const ROW_PORTRAIT_CARD := preload("res://scenes/journal/rows/portrait_card.tscn")
const SEAL_OK := preload("res://assets/ui/kit/seal_ok.png")
const SEAL_BAD := preload("res://assets/ui/kit/seal_bad.png")
const TREND_UP := preload("res://assets/ui/kit/trend_up.png")
const TREND_DOWN := preload("res://assets/ui/kit/trend_down.png")
const ITEM_ICONS := {
	"basic_pick": "pickaxe", "reinforced_pick": "pickaxe_reinforced",
	"rusted_sword": "sword_rusted", "steel_sword": "sword_steel",
	"leather": "armor_leather", "chainmail": "armor_iron",
	"hand_axe": "axe", "felling_axe": "axe_felling",
	"dwarven_pick": "pickaxe_dwarven", "wardens_axe": "axe_warden",
	"knights_blade": "sword_knight", "gilded_plate": "armor_gilded",
}
const EMPTY_SLOT_ICONS := {
	"tool": preload("res://assets/ui/icons/empty_glove.png"),
	"armor": preload("res://assets/ui/icons/empty_armor.png"),
}
const CONTRACT_NOTES := {
	"Balanced": "A standard wage and a modest share of each haul.",
	"Guaranteed Wage": "A higher wage, but a smaller share of the haul.",
	"Profit Share": "A low wage in exchange for a bigger cut of the haul.",
}
const ROLE_NOTES := {
	"Woodcutter": "Woodcutters fell timber at the logging sites. Safe, steady work.",
	"Miner": "Miners dig copper at Harlow Mines and iron and silver at Deepdelve.",
	"Guard": "Guards cannot dig, but they protect the crew from the site's threat.",
	"Scout": "Scouts travel ahead of the company.",
}

var selected_candidate: String = ""

func _gear_icon(key: String) -> Texture2D:
	return _item_icon(str(ITEM_ICONS.get(key, "")))

func _list_card(list: VBoxContainer, icon: Texture2D, title: String, details: String,
		side_caption: String, side_value: String, selected: bool, action: Callable) -> Button:
	var card := ROW_LIST_CARD.instantiate() as Button
	list.add_child(card)
	(card.get_node("Body/IconSlot/Icon") as TextureRect).texture = icon
	(card.get_node("Body/Info/Name") as Label).text = title
	(card.get_node("Body/Info/Details") as Label).text = details
	(card.get_node("Body/Side/Caption") as Label).text = side_caption
	(card.get_node("Body/Side/Caption") as Label).visible = not side_caption.is_empty()
	(card.get_node("Body/Side/Value/Text") as Label).text = side_value
	card.set_pressed_no_signal(selected)
	card.pressed.connect(action)
	return card

func _merc_status(merc: Dictionary) -> Array:
	## Returns [label, variation] describing what a mercenary is doing.
	if not game.is_available(merc):
		return ["In the field", &"LabelAccent"]
	if int(merc.get("health", 100)) < 25:
		return ["Too hurt to deploy", &"LabelAccent"]
	if int(merc.get("health", 100)) < 100:
		return ["Wounded", &"LabelAccent"]
	return ["Ready", &"LabelGood"]

func _set_bust(rect: TextureRect, role: String) -> void:
	rect.texture = BUSTS.get(role, BUSTS["Scout"])

# --- Personnel ----------------------------------------------------------------

func _draw_people() -> void:
	match roster_tab:
		"recruits": _draw_recruitment()
		"armory": _draw_armory_page()
		_: _draw_employees()
	var tabs := _mount_page(PERSONNEL_TABS, left_leaf)
	for tab in [["EmployeesTab", "employed"], ["RecruitmentTab", "recruits"], ["ArmoryTab", "armory"]]:
		var btn := tabs.get_node("Tabs/" + str(tab[0])) as Button
		btn.set_pressed_no_signal(roster_tab == str(tab[1]) or (str(tab[1]) == "employed" and roster_tab not in ["recruits", "armory"]))
		btn.pressed.connect(_set_roster_tab.bind(str(tab[1])))

func _focus_person(id: String) -> void:
	selected_merc = id
	_refresh()

func _draw_employees() -> void:
	var left := _mount_page(PERSONNEL_EMPLOYEES_LEFT, left_leaf)
	var right := _mount_page(PERSONNEL_EMPLOYEES_RIGHT, right_leaf)
	var c := "Margin/Content/"
	if (selected_merc.is_empty() or game.merc_by_id(selected_merc).is_empty()) and not game.crew.is_empty():
		selected_merc = str(game.crew[0]["id"])
	var grid := left.get_node(c + "List/Items") as GridContainer
	var payroll: int = 0
	for merc in game.crew:
		var id: String = str(merc["id"])
		var role: String = str(merc.get("role", ""))
		payroll += int(game.terms(merc)["wage"])
		var status: Array = _merc_status(merc)
		var health: int = int(merc.get("health", 100))
		var card := ROW_PORTRAIT_CARD.instantiate() as Button
		grid.add_child(card)
		_set_bust(card.get_node("Body/Bust") as TextureRect, role)
		(card.get_node("Body/Name") as Label).text = str(merc["name"])
		var role_label := card.get_node("Body/Role") as Label
		role_label.text = "%s  ·  %s" % [role, str(status[0])]
		if status[1] != &"LabelGood":
			role_label.theme_type_variation = status[1]
		var hp := card.get_node("Body/Health") as ProgressBar
		hp.value = health
		hp.theme_type_variation = &"GreenBar" if health >= 60 else (&"GoldBar" if health >= 25 else &"")
		card.tooltip_text = "%s  ·  Skill %d  ·  Health %d%%  ·  Gear %d/2" % [role, int(merc.get("skill", 0)), health, _equipped_count(merc)]
		card.set_pressed_no_signal(id == selected_merc)
		card.pressed.connect(_focus_person.bind(id))
	var empty: bool = game.crew.is_empty()
	(left.get_node(c + "Summary/Count") as Label).text = "%s  ·  %d ready" % ["%d hired" % game.crew.size(), game.free_crew()]
	(left.get_node(c + "Summary/Payroll") as Label).text = "Payroll %s" % _money(payroll)
	(left.get_node(c + "List") as Control).visible = not empty
	(left.get_node(c + "Empty") as Control).visible = empty
	var recruit := left.get_node(c + "Recruit") as Button
	recruit.visible = empty
	recruit.pressed.connect(_set_roster_tab.bind("recruits"))
	# Dossier.
	var merc: Dictionary = game.merc_by_id(selected_merc)
	var none: bool = merc.is_empty()
	for child in (right.get_node("Margin/Content") as Control).get_children():
		(child as CanvasItem).visible = (child.name == "Empty" or child.name == "Header") if none else child.name != "Empty"
	if none:
		return
	var role: String = str(merc.get("role", ""))
	_set_bust(right.get_node(c + "Head/Portrait/Bust") as TextureRect, role)
	(right.get_node(c + "Head/Id/Name") as Label).text = str(merc.get("name", ""))
	(right.get_node(c + "Head/Id/Title") as Label).text = str(merc.get("title", "Contractor"))
	(right.get_node(c + "Head/Id/Status/RoleIcon") as TextureRect).texture = ROLE_ICONS.get(role, ROLE_ICONS["Miner"])
	(right.get_node(c + "Head/Id/Status/Role") as Label).text = role
	var status: Array = _merc_status(merc)
	var state := right.get_node(c + "Head/Id/Status/State") as Label
	state.text = "·  " + str(status[0])
	state.theme_type_variation = status[1]
	var terms: Dictionary = game.terms(merc)
	right.get_node(c + "Stats/Skill").value = str(int(merc.get("skill", 0)))
	var main_trade: String = str(TradeSkills.ROLE_TRADE.get(role, "logging"))
	var exp_tile := right.get_node(c + "Stats/Experience")
	exp_tile.caption = "Main trade"
	exp_tile.value = "%s %d" % [TradeSkills.NAMES.get(main_trade, main_trade), TradeSkills.level_of(merc, main_trade)]
	right.get_node(c + "Stats/Wage").value = _money(int(terms["wage"]))
	right.get_node(c + "Stats/Share").value = "%d%%" % int(round(float(terms["cut"]) * 100.0))
	var health: int = int(merc.get("health", 100))
	var bar := right.get_node(c + "Health/Bar") as ProgressBar
	bar.value = health
	bar.theme_type_variation = &"GreenBar" if health >= 60 else (&"GoldBar" if health >= 25 else &"")
	(right.get_node(c + "Health/Value") as Label).text = "%d%%" % health
	var heal := right.get_node(c + "Health/Heal") as Button
	heal.visible = health < 100
	if heal.visible:
		var cost: int = maxi(12, int(ceil(float(100 - health) * 1.5)))
		heal.text = "Treat  ·  %d G" % cost
		heal.disabled = game.gold < cost or not game.is_available(merc)
		heal.pressed.connect(_heal.bind(selected_merc))
	for trade in ["logging", "mining", "combat"]:
		var base := c + "Skills/" + str(TradeSkills.NAMES[trade]) + "/"
		(right.get_node(base + "Level") as Label).text = "%s %d" % [TradeSkills.NAMES[trade], TradeSkills.level_of(merc, trade)]
		(right.get_node(base + "Bar") as ProgressBar).value = TradeSkills.progress(merc, trade) * 100.0
	var worn: Dictionary = merc.get("equipment", {})
	for slot in ["tool", "armor"]:
		var item: Dictionary = worn.get(slot, {})
		var cap: String = slot.capitalize()
		var slot_node := right.get_node(c + "Gear/%sSlot" % cap)
		slot_node.icon = EMPTY_SLOT_ICONS[slot] if item.is_empty() else _gear_icon(str(item.get("key", "")))
		slot_node.dim = item.is_empty()
		(right.get_node(c + "Gear/%sInfo/Name" % cap) as Label).text = _equipment_name(item)
	var contract: String = str(merc.get("contract", "Balanced"))
	(right.get_node(c + "Contract/Body/Top/Text/Name") as Label).text = contract
	(right.get_node(c + "Contract/Body/Explain") as Label).text = str(CONTRACT_NOTES.get(contract, ""))
	var change := right.get_node(c + "Contract/Body/Top/Change") as Button
	change.disabled = not game.is_available(merc)
	change.pressed.connect(_terms.bind(selected_merc))
	(right.get_node(c + "Actions/Armory") as Button).pressed.connect(_outfit.bind(selected_merc))

func _choose_candidate(id: String) -> void:
	selected_candidate = id
	_refresh()

func _draw_recruitment() -> void:
	var left := _mount_page(PERSONNEL_RECRUITS_LEFT, left_leaf)
	var right := _mount_page(PERSONNEL_RECRUITS_RIGHT, right_leaf)
	var c := "Margin/Content/"
	var board: Array[Dictionary] = game.recruitment_board()
	# Woodcutters first (the starter trade), then miners and guards, cheapest first.
	var role_order: Array[String] = ["Woodcutter", "Miner", "Guard", "Scout"]
	board.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ra: int = role_order.find(str(a["role"]))
		var rb: int = role_order.find(str(b["role"]))
		return ra < rb if ra != rb else int(a["hire"]) < int(b["hire"]))
	var chosen: Dictionary = {}
	for candidate in board:
		if str(candidate["id"]) == selected_candidate:
			chosen = candidate
	if chosen.is_empty() and not board.is_empty():
		chosen = board[0]
		selected_candidate = str(chosen["id"])
	var list := left.get_node(c + "List/Items") as VBoxContainer
	for candidate in board:
		var role: String = str(candidate["role"])
		var fee: int = int(candidate["hire"])
		var start: Dictionary = TradeSkills.starting_skills(role, int(candidate["skill"]))
		var main: String = str(TradeSkills.ROLE_TRADE.get(role, "logging"))
		var card := _list_card(list, ROLE_ICONS.get(role, ROLE_ICONS["Miner"]), str(candidate["name"]),
			"%s  ·  %s %d  ·  Wage %d G" % [role, TradeSkills.NAMES.get(main, main), TradeSkills.level_for_xp(int(start.get(main, 0))), int(candidate["wage"])],
			"Fee", _money(fee), str(candidate["id"]) == selected_candidate, _choose_candidate.bind(str(candidate["id"])))
		if game.gold < fee:
			(card.get_node("Body/Side/Value/Text") as Label).theme_type_variation = &"LabelMuted"
	(left.get_node(c + "Summary/Count") as Label).text = "%d waiting" % board.size()
	var refresh := left.get_node(c + "Summary/Refresh") as Label
	var tick := func() -> void:
		refresh.text = "New applicants in " + _duration(1800 - _now() % 1800)
	tick.call()
	live_updaters.append(tick)
	(left.get_node(c + "List") as Control).visible = not board.is_empty()
	(left.get_node(c + "Empty") as Control).visible = board.is_empty()
	var none: bool = chosen.is_empty()
	for child in (right.get_node("Margin/Content") as Control).get_children():
		(child as CanvasItem).visible = (child.name == "Empty" or child.name == "Header") if none else child.name != "Empty"
	if none:
		return
	var role: String = str(chosen["role"])
	_set_bust(right.get_node(c + "Head/Portrait/Bust") as TextureRect, role)
	(right.get_node(c + "Head/Id/Name") as Label).text = str(chosen["name"])
	(right.get_node(c + "Head/Id/Title") as Label).text = str(chosen.get("title", "Contractor"))
	(right.get_node(c + "Head/Id/Status/RoleIcon") as TextureRect).texture = ROLE_ICONS.get(role, ROLE_ICONS["Miner"])
	(right.get_node(c + "Head/Id/Status/Role") as Label).text = role
	right.get_node(c + "Stats/Skill").value = str(int(chosen["skill"]))
	right.get_node(c + "Stats/Fee").value = _money(int(chosen["hire"]))
	right.get_node(c + "Stats/Wage").value = _money(int(chosen["wage"]))
	right.get_node(c + "Stats/Share").value = "%d%%" % int(round(float(chosen.get("share", 0.1)) * 100.0))
	var start_skills: Dictionary = TradeSkills.starting_skills(role, int(chosen["skill"]))
	var main_trade: String = str(TradeSkills.ROLE_TRADE.get(role, "logging"))
	right.get_node(c + "RoleNote").text = "%s Starts at %s level %d." % [str(ROLE_NOTES.get(role, "")), TradeSkills.NAMES.get(main_trade, main_trade), TradeSkills.level_for_xp(int(start_skills.get(main_trade, 0)))]
	var fee: int = int(chosen["hire"])
	var hire := right.get_node(c + "Hire") as Button
	hire.text = "Hire %s  ·  %s" % [str(chosen["name"]).get_slice(" ", 0), _money(fee)]
	hire.disabled = game.gold < fee
	hire.pressed.connect(_hire.bind(str(chosen["id"])))
	var reason := right.get_node(c + "Reason") as Label
	reason.text = "Not enough gold: the fee is %s." % _money(fee) if game.gold < fee else ""
	reason.visible = not reason.text.is_empty()

func _draw_armory_page() -> void:
	var left := _mount_page(PERSONNEL_ARMORY_LEFT, left_leaf)
	var right := _mount_page(PERSONNEL_ARMORY_RIGHT, right_leaf)
	var c := "Margin/Content/"
	if (selected_merc.is_empty() or game.merc_by_id(selected_merc).is_empty()) and not game.crew.is_empty():
		selected_merc = str(game.crew[0]["id"])
	var owner: Dictionary = game.merc_by_id(selected_merc)
	var picker := left.get_node(c + "Crew/Items") as VBoxContainer
	for merc in game.crew:
		var id: String = str(merc["id"])
		var role: String = str(merc.get("role", ""))
		var away: bool = not game.is_available(merc)
		var card := _list_card(picker, ROLE_ICONS.get(role, ROLE_ICONS["Miner"]), str(merc["name"]),
			role + ("  ·  in the field" if away else ""), "Gear", "%d/2" % _equipped_count(merc), id == selected_merc, _choose_worker.bind(id))
		card.custom_minimum_size.y = 30
	(left.get_node(c + "Crew") as Control).custom_minimum_size.y = mini(game.crew.size(), 3) * 33
	var none: bool = owner.is_empty()
	(left.get_node(c + "Empty") as Control).visible = game.crew.is_empty()
	for path in ["Caption", "Crew", "LoadoutHeader", "Loadout", "Tip"]:
		(left.get_node(c + path) as Control).visible = not game.crew.is_empty()
	if not none:
		var available: bool = game.is_available(owner)
		(left.get_node(c + "Loadout/Body/Who") as Label).text = "%s  ·  %s" % [str(owner["name"]), str(owner.get("role", ""))]
		var worn: Dictionary = owner.get("equipment", {})
		for slot in ["tool", "armor"]:
			var item: Dictionary = worn.get(slot, {})
			var row := c + "Loadout/Body/%sRow/" % slot.capitalize()
			var slot_node := left.get_node(row + "Slot")
			slot_node.icon = EMPTY_SLOT_ICONS[slot] if item.is_empty() else _gear_icon(str(item.get("key", "")))
			slot_node.dim = item.is_empty()
			(left.get_node(row + "Info/Name") as Label).text = _equipment_name(item)
			var remove := left.get_node(row + "Remove") as Button
			remove.visible = not item.is_empty()
			remove.disabled = not available
			remove.pressed.connect(_unequip.bind(selected_merc, slot))
		var stats: Dictionary = MercsV05.equipment_stats(owner)
		(left.get_node(c + "Loadout/Body/Bonus") as Label).text = "Mining +%d  ·  Guard +%d  ·  Protection +%d" % [
			int(stats["mining"]), int(stats["guard"]), int(stats["protection"])]
	# Storeroom: loose gear, equip onto the selected mercenary or sell.
	var store := right.get_node(c + "Store/Items") as VBoxContainer
	for item in game.equipment_inventory:
		var key: String = str(item.get("key", ""))
		var definition: Dictionary = game.item_definition(key)
		var card := ROW_ITEM_CARD.instantiate()
		store.add_child(card)
		(card.get_node("Row/IconSlot/Icon") as TextureRect).texture = _gear_icon(key)
		(card.get_node("Row/Info/Name") as Label).text = str(definition.get("name", "Unknown"))
		(card.get_node("Row/Info/Details") as Label).text = _gear_summary(definition)
		var fits: bool = not none and game.is_available(owner) and MercsV05.validate_role(key, owner)
		var equip := card.get_node("Row/Primary") as Button
		equip.text = "Equip"
		equip.disabled = not fits
		equip.tooltip_text = "Equip on %s." % str(owner.get("name", "")) if fits else "Only a free %s can use this." % str(definition.get("role", "mercenary")).to_lower()
		equip.pressed.connect(_equip.bind(selected_merc, str(item.get("uid", ""))))
		var sell := card.get_node("Row/Secondary") as Button
		sell.visible = true
		var value: int = maxi(1, int(floor(float(definition.get("cost", 0)) * 0.65)))
		sell.text = "Sell %d" % value
		sell.tooltip_text = "Sell for %s (65%% of its price)." % _money(value)
		sell.pressed.connect(_sell_equipment.bind(str(item.get("uid", ""))))
	(right.get_node(c + "Store") as Control).visible = not game.equipment_inventory.is_empty()
	(right.get_node(c + "StoreEmpty") as Control).visible = game.equipment_inventory.is_empty()
	# Quartermaster: buy new gear (goes to the storeroom).
	var shop := right.get_node(c + "Shop/Items") as VBoxContainer
	for key in MercsV05.shop_keys():
		var definition: Dictionary = MercsV05.ITEMS[key]
		var card := ROW_ITEM_CARD.instantiate()
		shop.add_child(card)
		(card.get_node("Row/IconSlot/Icon") as TextureRect).texture = _gear_icon(str(key))
		(card.get_node("Row/Info/Name") as Label).text = str(definition["name"])
		(card.get_node("Row/Info/Details") as Label).text = _gear_summary(definition)
		var buy := card.get_node("Row/Primary") as Button
		buy.text = _money(int(definition["cost"]))
		buy.disabled = game.gold < int(definition["cost"])
		buy.tooltip_text = "Buy and place in the storeroom."
		buy.pressed.connect(_buy_equipment.bind(str(key)))

func _gear_summary(definition: Dictionary) -> String:
	var bonus: Array[String] = []
	for stat in ["logging", "mining", "guard", "protection"]:
		if int(definition.get(stat, 0)) > 0:
			bonus.append("+%d %s" % [int(definition[stat]), stat])
	var who: String = "Anyone" if str(definition.get("role", "")) == "Any" else str(definition.get("role", "")) + "s"
	return "%s  ·  %s" % [who, ", ".join(bonus)]

# --- Exchange -----------------------------------------------------------------

func _choose_commodity(id: String) -> void:
	selected_market_item = id
	_refresh()

func _draw_exchange() -> void:
	var left := _mount_page(EXCHANGE_LEFT, left_leaf)
	var right := _mount_page(EXCHANGE_RIGHT, right_leaf)
	var c := "Margin/Content/"
	var list := left.get_node(c + "List/Items") as VBoxContainer
	for id in MoneyMercsState.RESOURCE_ORDER:
		var key: String = str(id)
		var stored: int = int(game.resources.get(key, 0))
		var card := _list_card(list, _item_icon(key), _resource_name(key),
			"Stored %d" % stored if stored > 0 else "None stored", "", _money(game.sell_price(key)),
			key == selected_market_item, _choose_commodity.bind(key))
		var trend := card.get_node("Body/Side/Value/Trend") as TextureRect
		var base: int = int(MoneyMercsState.BASE_PRICE.get(key, 1))
		var now_price: int = game.price(key)
		trend.visible = now_price != base
		trend.texture = TREND_UP if now_price > base else TREND_DOWN
		card.tooltip_text = "Usual price %d G, today %d G." % [base, now_price]
	var shift := left.get_node(c + "Summary/Shift") as Label
	var tick := func() -> void:
		shift.text = "Prices shift in " + _duration(21600 - _now() % 21600)
	tick.call()
	live_updaters.append(tick)
	# Trade desk for the selected good.
	var key: String = selected_market_item
	var owned: int = int(game.resources.get(key, 0))
	var sell_price: int = game.sell_price(key)
	var buy_price: int = game.buy_price(key)
	(right.get_node(c + "Head/Slot/Center/Icon") as TextureRect).texture = _item_icon(key)
	(right.get_node(c + "Head/Id/Name") as Label).text = _resource_name(key)
	(right.get_node(c + "Head/Id/Desc") as Label).text = str(MoneyMercsState.RESOURCE_DESC.get(key, ""))
	right.get_node(c + "Prices/Sell").value = _money(sell_price)
	var buyable: bool = key != "relic" and key != "sovereign"
	right.get_node(c + "Prices/Buy").value = _money(buy_price) if buyable else "Not sold"
	right.get_node(c + "Prices/Owned").value = str(owned)
	# Why the price is what it is: the day's drift and news, and merchant saturation.
	var base: int = int(MoneyMercsState.BASE_PRICE.get(key, 1))
	var diff: int = int(round((float(game.price(key)) / float(base) - 1.0) * 100.0))
	var flood: float = game.market.saturation_factor(key)
	var trend := right.get_node(c + "Market/Trend") as TextureRect
	trend.visible = diff != 0 or absf(flood - 1.0) > 0.02
	trend.texture = TREND_UP if diff > 0 or flood > 1.02 else TREND_DOWN
	var notes: Array[String] = []
	if diff > 0:
		notes.append("%d%% above its usual price today." % diff)
	elif diff < 0:
		notes.append("%d%% below its usual price today." % -diff)
	if flood < 0.98:
		notes.append("Merchants are stocked up after recent sales and pay %d%% less; it recovers within a day." % int(round((1.0 - flood) * 100.0)))
	elif flood > 1.02:
		notes.append("Merchants are short after recent purchases and charge %d%% more." % int(round((flood - 1.0) * 100.0)))
	if notes.is_empty():
		notes.append("Trading at its usual price.")
	(right.get_node(c + "Market/Text") as Label).text = "  ".join(notes)
	# Price history bars.
	var samples: Array = game.market.price_history(key)
	var bars := right.get_node(c + "History/Body/Bars") as HBoxContainer
	var lo: int = 1 << 30
	var hi: int = 0
	for sample in samples:
		lo = mini(lo, int(sample["p"]))
		hi = maxi(hi, int(sample["p"]))
	for sample in samples:
		var p: int = int(sample["p"])
		var bar := ColorRect.new()
		var h: float = 30.0 if hi == lo else 6.0 + 24.0 * float(p - lo) / float(hi - lo)
		bar.custom_minimum_size = Vector2(4, h)
		bar.size_flags_vertical = Control.SIZE_SHRINK_END
		bar.color = Color("#d6a03e")
		bar.mouse_filter = Control.MOUSE_FILTER_PASS
		bar.tooltip_text = "%s: %s" % [_ago(int(sample["t"])), _money(p)]
		bars.add_child(bar)
	(right.get_node(c + "History/Body/Top/Range") as Label).text = "" if samples.is_empty() else "%s - %s" % [_money(lo), _money(hi)]
	(right.get_node(c + "History") as Control).visible = samples.size() >= 2
	# Trade desk: prices quoted for the whole batch, since big sales move the price.
	var desk := c + "Desk/Body/"
	for pair in [["One", 1], ["Ten", 10]]:
		var n: int = int(pair[1])
		var sell := right.get_node(desk + "SellRow/" + str(pair[0])) as Button
		sell.disabled = owned < n
		sell.tooltip_text = "+%s (%s each)" % [_money(game.sell_price(key, n) * n), _money(game.sell_price(key, n))]
		sell.pressed.connect(_trade.bind(key, false, n))
		var buy := right.get_node(desk + "BuyRow/" + str(pair[0])) as Button
		buy.disabled = not buyable or game.gold < game.buy_price(key, n) * n
		buy.tooltip_text = "-%s (%s each)" % [_money(game.buy_price(key, n) * n), _money(game.buy_price(key, n))] if buyable else "Merchants never sell these. Find them in the field."
		buy.pressed.connect(_trade.bind(key, true, n))
	var sell_all := right.get_node(desk + "SellRow/All") as Button
	sell_all.disabled = owned <= 0
	var all_each: int = game.sell_price(key, maxi(owned, 1))
	sell_all.tooltip_text = "+%s (%s each)" % [_money(all_each * owned), _money(all_each)]
	sell_all.pressed.connect(_trade.bind(key, false, owned))
	(right.get_node(desk + "Holding") as Label).text = "Selling all %d now brings %s." % [owned, _money(owned * all_each)] if owned > 0 else "You hold none."
	# Market news.
	var event: Dictionary = game.market.current_event()
	var note := right.get_node(c + "Note")
	if not event.is_empty():
		note.text = "Market news: %s Lasts %s more." % [str(event["news"]), _duration(game.market.event_ends_in())]
		note.icon_kind = "alert"
	else:
		note.text = "Merchants pay about 75% of fair value. Traders in the Trade Hall pay more, if you can wait for a buyer."
	_mount_exchange_tabs()

func _mount_exchange_tabs() -> void:
	var tabs := _mount_page(EXCHANGE_TABS, left_leaf)
	for tab in [["MerchantsTab", "market"], ["HallTab", "hall"]]:
		var btn := tabs.get_node("Tabs/" + str(tab[0])) as Button
		btn.set_pressed_no_signal(page == str(tab[1]))
		btn.pressed.connect(_nav_to.bind(str(tab[1])))

# --- Trade Hall -----------------------------------------------------------------
# The chat, inventory, private messages and trade window live in HallView.

var hall_view: HallView

func _hall() -> HallView:
	if hall_view == null:
		hall_view = HallView.new(self)
	return hall_view

## Runs every second from the clock: NPC chatter, replies, trade requests and trades.
func _hall_clock() -> void:
	_hall().clock()

func _draw_hall() -> void:
	_hall().draw()

func _link_card() -> PanelContainer:
	return stage.get_node_or_null("LinkCard") as PanelContainer if is_instance_valid(stage) else null

func _hide_link_card() -> void:
	var card := _link_card()
	if card != null:
		card.visible = false

func _show_link_card(ref: String) -> void:
	_hall().show_card(ref)

# --- Finances -----------------------------------------------------------------

func _draw_accounts() -> void:
	var left := _mount_page(FINANCE_LEFT, left_leaf)
	var right := _mount_page(FINANCE_RIGHT, right_leaf)
	var c := "Margin/Content/"
	var goods: int = 0
	for key in MoneyMercsState.RESOURCE_ORDER:
		goods += int(game.resources.get(str(key), 0)) * game.sell_price(str(key))
	var gear: int = game.owned_equipment_value()
	for merc in game.crew:
		gear += int(merc.get("gear", 0)) * 60
	(left.get_node(c + "Hero/Text/Gold") as Label).text = _money(game.gold)
	var rows := c + "Ledger/Rows/"
	(left.get_node(rows + "Coin/Value") as Label).text = _money(game.gold)
	(left.get_node(rows + "Goods/Value") as Label).text = _money(goods)
	(left.get_node(rows + "Gear/Value") as Label).text = _money(gear)
	(left.get_node(rows + "Debt/Value") as Label).text = "-" + _money(game.relief_debt) if game.relief_debt > 0 else "None"
	(left.get_node(rows + "Total/Value") as Label).text = _money(game.wealth())
	# Expedition capacity.
	left.get_node(c + "Slots/Text/Pips").value = game.expedition_slots
	(left.get_node(c + "Slots/Text/Caption") as Label).text = "Expedition slots  ·  %d of 3" % game.expedition_slots
	var expand := left.get_node(c + "Slots/Expand") as Button
	if game.expedition_slots >= 3:
		expand.text = "Fully expanded"
		expand.disabled = true
	else:
		var cost: int = game.expansion_cost()
		expand.text = "Expand  ·  %s" % _money(cost)
		expand.disabled = game.gold < cost
		expand.pressed.connect(func() -> void: _action(game.expand_operations()))
	var payroll: int = 0
	for merc in game.crew:
		payroll += int(game.terms(merc)["wage"])
	left.get_node(c + "Costs/Payroll").value = _money(payroll)
	left.get_node(c + "Costs/Reputation").value = str(game.reputation)
	# Guild relief and debt.
	var relief := left.get_node(c + "Relief")
	var relief_button := left.get_node(c + "ReliefButton") as Button
	var can_request: bool = game.missions.is_empty() and game.gold < 28 and game.relief_debt < 440 and game.wealth() <= 250
	if game.relief_debt > 0:
		relief.visible = true
		relief.text = "You owe the guild %s. It is repaid automatically from sales once the treasury holds more than 120 G." % _money(game.relief_debt)
		relief.icon_kind = "alert"
	elif can_request:
		relief.visible = true
		relief.text = "Too poor to fund an expedition? The guild will advance 90 G, repayable as 110 G, at a small cost in reputation."
		relief.icon_kind = "coin"
	relief_button.visible = can_request
	relief_button.pressed.connect(func() -> void: _action(game.guild_relief()))
	# Results chart from recent reports, oldest first.
	var recent: Array = game.reports.slice(0, mini(12, game.reports.size()))
	recent.reverse()
	var bars := right.get_node(c + "Chart/Body/Plot/Bars") as HBoxContainer
	var largest: int = 1
	var earned: int = 0
	var spent: int = 0
	for report in recent:
		largest = maxi(largest, absi(_report_value(report) - int(report.get("cost", 0))))
		earned += _report_value(report)
		spent += int(report.get("cost", 0))
	var half: float = 34.0
	for report in recent:
		var net: int = _report_value(report) - int(report.get("cost", 0))
		var h: float = maxf(1.0, round(absf(float(net)) / float(largest) * half))
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 0)
		column.custom_minimum_size = Vector2(12, 0)
		column.mouse_filter = Control.MOUSE_FILTER_PASS
		column.tooltip_text = "%s: %s%s" % [str(report.get("region", "")), "+" if net >= 0 else "", _money(net)]
		var top := Control.new()
		top.custom_minimum_size = Vector2(0, half - (h if net >= 0 else 0.0) + 2.0)
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bar := ColorRect.new()
		bar.custom_minimum_size = Vector2(12, h)
		bar.color = GOOD if net >= 0 else OXBLOOD
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(top)
		column.add_child(bar)
		bars.add_child(column)
	(right.get_node(c + "Chart/Body/Caption") as Label).text = "No expeditions yet" if recent.is_empty() else "Last %s" % _plural(recent.size(), "expedition")
	right.get_node(c + "Totals/Earned").value = _money(earned)
	right.get_node(c + "Totals/Spent").value = _money(spent)
	var net_tile := right.get_node(c + "Totals/Net")
	net_tile.value = ("+" if earned - spent >= 0 else "") + _money(earned - spent)
	net_tile.tone = "good" if earned - spent >= 0 else "accent"
	# Warehouse valuation.
	var stores := right.get_node(c + "Stores/Items") as VBoxContainer
	var owned: int = 0
	for id in MoneyMercsState.RESOURCE_ORDER:
		var key: String = str(id)
		var quantity: int = int(game.resources.get(key, 0))
		if quantity <= 0:
			continue
		owned += 1
		var card := _list_card(stores, _item_icon(key), _resource_name(key), "%d stored  ·  %s each" % [quantity, _money(game.sell_price(key))],
			"", _money(quantity * game.sell_price(key)), false, _open_market.bind(key))
		card.tooltip_text = "Open in the Exchange"
	(right.get_node(c + "Stores") as Control).visible = owned > 0
	(right.get_node(c + "StoresEmpty") as Control).visible = owned == 0

func _open_market(key: String) -> void:
	selected_market_item = key
	_turn_to("market")

# --- Guild work ---------------------------------------------------------------

func _draw_guild_jobs() -> void:
	var left := _mount_page(GUILDWORK_LEFT, left_leaf)
	var right := _mount_page(GUILDWORK_RIGHT, right_leaf)
	var c := "Margin/Content/"
	var slot_free: bool = game.missions.size() < game.expedition_slots
	var can_take: bool = game.can_accept_guild_work() and slot_free
	var rules := [
		["Cash", game.gold < 120, "Treasury below 120 G  (now %s)" % _money(game.gold)],
		["Worth", game.liquid_worth() < 250, "Cash, goods and spare gear below 250 G  (now %s)" % _money(game.liquid_worth())],
		["Slot", slot_free, "A free expedition slot"],
	]
	for rule in rules:
		var row := c + "Rules/Body/" + str(rule[0]) + "/"
		(left.get_node(row + "Mark") as TextureRect).texture = SIGN_CHECK if bool(rule[1]) else SIGN_CROSS
		(left.get_node(row + "Text") as Label).text = str(rule[2])
	var office := left.get_node(c + "Office/Row/Accept") as Button
	office.disabled = not can_take
	office.pressed.connect(_guild_work.bind(""))
	(left.get_node(c + "ReturnBoard") as Button).pressed.connect(_turn_to.bind("expeditions"))
	if not can_take:
		var why: String = "Not available: " + ("every expedition slot is busy." if not slot_free else "the guild only helps companies with under 120 G cash and under 250 G in cash, goods and spare gear.")
		var caption := right.get_node(c + "Caption") as Label
		caption.text = why
		caption.theme_type_variation = &"LabelAccent"
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var list := right.get_node(c + "List/Items") as VBoxContainer
	var count: int = 0
	for member in game.available_guild_workers():
		var role: String = str(member.get("role", ""))
		var card := _list_card(list, ROLE_ICONS.get(role, ROLE_ICONS["Miner"]), str(member.get("name", "Contractor")),
			role, "", "Assign" if can_take else "", false, _guild_work.bind(str(member["id"])))
		card.toggle_mode = false
		card.disabled = not can_take
		(card.get_node("Body/Side/Value/Text") as Label).theme_type_variation = &"LabelAccent"
		count += 1
	(right.get_node(c + "List") as Control).visible = count > 0
	(right.get_node(c + "Empty") as Control).visible = count == 0

# --- Chronicle ----------------------------------------------------------------

func _choose_report(index: int) -> void:
	selected_report_index = index
	_refresh()

func _report_outcome(report: Dictionary) -> String:
	var won: bool = bool(report.get("won", false))
	if won and not (report.get("casualties", []) as Array).is_empty():
		return "Success, with losses"
	if won:
		return "Returned safely"
	return "Partial haul" if bool(report.get("partial", false)) else "Failed"

func _ago(stamp: int) -> String:
	var seconds: int = maxi(0, _now() - stamp)
	if seconds < 60:
		return "just now"
	if seconds >= 86400:
		return "%dd ago" % int(seconds / 86400)
	return _duration(seconds) + " ago"

func _draw_history() -> void:
	var left := _mount_page(CHRONICLE_LEFT, left_leaf)
	var right := _mount_page(CHRONICLE_RIGHT, right_leaf)
	var c := "Margin/Content/"
	var empty: bool = game.reports.is_empty()
	var list := left.get_node(c + "List/Items") as VBoxContainer
	var safe: int = 0
	for i in range(game.reports.size()):
		var report: Dictionary = game.reports[i]
		var won: bool = bool(report.get("won", false))
		if won and (report.get("casualties", []) as Array).is_empty():
			safe += 1
		var net: int = _report_value(report) - int(report.get("cost", 0))
		var card := _list_card(list, SEAL_OK if won else SEAL_BAD, str(report.get("region", "Expedition")),
			"%s  ·  %s" % [_report_outcome(report), _ago(int(report.get("time", _now())))], "Profit",
			("+" if net >= 0 else "") + _money(net), i == selected_report_index, _choose_report.bind(i))
		(card.get_node("Body/Side/Value/Text") as Label).add_theme_color_override("font_color", GOOD if net >= 0 else OXBLOOD)
	(left.get_node(c + "Summary") as Label).text = "%s  ·  %d returned without losses" % [_plural(game.reports.size(), "report"), safe]
	(left.get_node(c + "Summary") as Control).visible = not empty
	(left.get_node(c + "List") as Control).visible = not empty
	(left.get_node(c + "Empty") as Control).visible = empty
	var go := left.get_node(c + "PlanExpedition") as Button
	go.visible = empty
	go.pressed.connect(_turn_to.bind("expeditions"))
	for child in (right.get_node("Margin/Content") as Control).get_children():
		(child as CanvasItem).visible = (child.name == "Empty" or child.name == "Header") if empty else child.name != "Empty"
	if empty:
		return
	var report: Dictionary = game.reports[clampi(selected_report_index, 0, game.reports.size() - 1)]
	var won: bool = bool(report.get("won", false))
	(right.get_node(c + "Head/Seal") as TextureRect).texture = SIGN_CHECK if won else SIGN_CROSS
	(right.get_node(c + "Head/Id/Place") as Label).text = str(report.get("region", "Expedition"))
	var subtitle: String = "%s  ·  %s" % [_report_outcome(report), _ago(int(report.get("time", _now())))]
	if report.has("tactic"):
		subtitle += "  ·  " + str(report["tactic"])
	(right.get_node(c + "Head/Id/Outcome") as Label).text = subtitle
	var cash: int = _report_value(report)
	var cost: int = int(report.get("cost", 0))
	right.get_node(c + "Money/Recovered").value = _money(cash)
	right.get_node(c + "Money/Costs").value = _money(cost)
	var profit := right.get_node(c + "Money/Profit")
	profit.value = ("+" if cash - cost >= 0 else "") + _money(cash - cost)
	profit.tone = "good" if cash - cost >= 0 else "accent"
	var loot: Dictionary = report.get("loot", {})
	var loot_row := right.get_node(c + "Loot") as HBoxContainer
	for key in loot:
		var slot := ITEM_SLOT.instantiate()
		loot_row.add_child(slot)
		slot.icon = _item_icon(str(key))
		slot.count = int(loot[key])
		slot.tooltip_text = "%d %s" % [int(loot[key]), _resource_name(str(key))]
	loot_row.visible = not loot.is_empty()
	(right.get_node(c + "NoLoot") as Control).visible = loot.is_empty()
	# Crew fates.
	var crew_box := right.get_node(c + "Crew") as VBoxContainer
	var casualties: Array = report.get("casualties", [])
	var injured: Array = report.get("injured", [])
	var names: Array[String] = []
	for id in report.get("crew", []):
		var merc: Dictionary = game.merc_by_id(str(id))
		names.append(str(merc.get("name", str(id).capitalize())))
	for name in casualties:
		if not names.has(str(name)):
			names.append(str(name))
	for name in names:
		var line := Label.new()
		if casualties.has(name):
			line.text = "%s  -  killed" % name
			line.theme_type_variation = &"LabelAccent"
		elif injured.has(name):
			line.text = "%s  -  injured" % name
			line.theme_type_variation = &"LabelAccent"
		else:
			line.text = "%s  -  returned" % name
			line.theme_type_variation = &"LabelGood"
		crew_box.add_child(line)
	(right.get_node(c + "CrewCaption") as Control).visible = not names.is_empty()
	var items_note: Array[String] = []
	for item in report.get("lost_items", []):
		items_note.append("Lost: " + (MercsV05.item_name(item) if item is Dictionary else str(item)))
	for item in report.get("found_items", []):
		items_note.append("Found: " + (MercsV05.item_name(item) if item is Dictionary else str(item)))
	var items_label := right.get_node(c + "Items") as Label
	items_label.text = "\n".join(items_note)
	items_label.visible = not items_note.is_empty()
	var events := right.get_node(c + "Events/Items") as VBoxContainer
	for event in report.get("events", []):
		var note := Label.new()
		note.text = "-  " + str(event)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size = Vector2(200, 0)
		events.add_child(note)
	var has_events: bool = not (report.get("events", []) as Array).is_empty()
	(right.get_node(c + "Events") as Control).visible = has_events
	(right.get_node(c + "EventsCaption") as Control).visible = has_events

# --- Regional contracts -------------------------------------------------------

func _draw_regions() -> void:
	var left := _mount_page(REGIONS_LEFT, left_leaf)
	var right := _mount_page(REGIONS_RIGHT, right_leaf)
	var c := "Margin/Content/"
	var list := left.get_node(c + "List/Items") as VBoxContainer
	var harlow := _list_card(list, ICON_FIELD, "All expeditions", "Logging, mining and more on the expedition board", "", "Open  >", false, _turn_to.bind("expeditions"))
	harlow.toggle_mode = false
	for region in MoneyMercsState.REGIONS:
		var id: String = str(region["id"])
		var rep: int = int(region.get("rep", 0))
		var locked: bool = game.reputation < rep
		var card := _list_card(list, ICON_FIELD, str(region["name"]), str(region.get("tagline", "")),
			"Reputation" if locked else "", "%d needed" % rep if locked else _duration(int(region.get("time", 60))),
			selected_region == id, _select_region.bind(id))
		if locked:
			(card.get_node("Body/Side/Value/Text") as Label).theme_type_variation = &"LabelAccent"
	var site: Dictionary = {}
	for region in MoneyMercsState.REGIONS:
		if str(region["id"]) == selected_region:
			site = region
	if site.is_empty():
		site = MoneyMercsState.REGIONS[0]
		selected_region = str(site["id"])
	(right.get_node(c + "Name") as Label).text = str(site["name"])
	(right.get_node(c + "Tagline") as Label).text = str(site.get("tagline", ""))
	right.get_node(c + "Stats/Threat").value = str(int(site.get("threat", 0)))
	right.get_node(c + "Stats/Duration").value = _duration(int(site.get("time", 60)))
	right.get_node(c + "Stats/Supplies").value = _money(int(site.get("supplies", 0)))
	var rep_tile := right.get_node(c + "Stats/Reputation")
	rep_tile.value = "%d  (you %d)" % [int(site.get("rep", 0)), game.reputation]
	rep_tile.tone = "accent" if game.reputation < int(site.get("rep", 0)) else "normal"
	var loot_row := right.get_node(c + "Loot") as HBoxContainer
	var loot: Dictionary = site.get("loot", {})
	for key in loot:
		var span: Array = loot[key]
		var slot := ITEM_SLOT.instantiate()
		loot_row.add_child(slot)
		slot.icon = _item_icon(str(key))
		slot.tooltip_text = "%s: %d to %d" % [_resource_name(str(key)), int(span[0]), int(span[1])]
	var bonus: String = str(site.get("bonus", ""))
	if not bonus.is_empty():
		var rare := ITEM_SLOT.instantiate()
		loot_row.add_child(rare)
		rare.icon = _item_icon(bonus)
		rare.theme_type_variation = &"GoldPanel"
		rare.tooltip_text = "Rare find: %s (%d%% chance)" % [_resource_name(bonus), int(round(float(site.get("bonus_odds", 0.0)) * 100.0))]
	var finds: Array[String] = []
	for key in loot:
		finds.append("%s %d-%d" % [_resource_name(str(key)), int(loot[key][0]), int(loot[key][1])])
	if not bonus.is_empty():
		finds.append("rare %s (%d%%)" % [_resource_name(bonus), int(round(float(site.get("bonus_odds", 0.0)) * 100.0))])
	(right.get_node(c + "Finds") as Label).text = "  ·  ".join(finds)
	(right.get_node(c + "Focus") as Label).text = "Suits %ss: they add the most strength here." % str(site.get("focus", "mercenary")).to_lower()
	var team: Array[String] = []
	var team_ids: Array[String] = []
	for merc in game.crew:
		if game.is_available(merc) and team.size() < 2:
			team.append(str(merc["name"]))
			team_ids.append(str(merc["id"]))
	(right.get_node(c + "Team") as Label).text = "Sends your first free mercenaries: " + (", ".join(team) if not team.is_empty() else "none available")
	var why: String = ""
	if game.missions.size() >= game.expedition_slots:
		why = "All expedition slots are busy."
	elif team.is_empty():
		why = "No mercenary is free."
	elif game.reputation < int(site.get("rep", 0)):
		why = "Needs %d reputation." % int(site.get("rep", 0))
	var dispatch := right.get_node(c + "Dispatch") as Button
	var total_cost: int = game.expedition_cost(site, team_ids) if not team_ids.is_empty() else int(site.get("supplies", 0))
	dispatch.text = "Dispatch crew  ·  " + _money(total_cost)
	dispatch.tooltip_text = "Supplies plus the crew's wages, paid up front."
	if why.is_empty() and game.gold < total_cost:
		why = "Not enough gold for supplies and wages."
	dispatch.disabled = not why.is_empty()
	dispatch.pressed.connect(_old_dispatch.bind(str(site["id"])))
	var reason := right.get_node(c + "Reason") as Label
	reason.text = why
	reason.visible = not why.is_empty()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Enter jumps into the trade chat box, as in most game chats.
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER] and page == "hall":
			if _hall().focus_composer():
				get_viewport().set_input_as_handled()
			return
		var pages: Array[String] = ["hq", "expeditions", "roster", "market", "finance", "ledger", "guildwork"]
		var index: int = int(event.keycode) - int(KEY_1)
		if index >= 0 and index < pages.size():
			_turn_to(pages[index])

# --- Expedition board ---------------------------------------------------------

func _open_site(id: String) -> void:
	var site: Dictionary = TradeSites.by_id(id)
	if selected_site != id:
		selected_crew.clear()
	selected_site = id
	if page == "site":
		_refresh()
	else:
		_turn_to("site")

## Best mercenary and level in a trade, for the board and planner captions.
func _best_in(trade: String) -> Dictionary:
	var best: Dictionary = {}
	var xp: int = 0
	for merc in game.crew:
		var x: int = TradeSkills.xp_of(merc, trade)
		if x > xp:
			xp = x
			best = merc
	return {"merc": best, "level": TradeSkills.level_for_xp(xp)}

func _draw_board() -> void:
	var left := _mount_page(BOARD_LEFT, left_leaf)
	var right := _mount_page(BOARD_RIGHT, right_leaf)
	var c := "Margin/Content/"
	var list := left.get_node(c + "List/Items") as VBoxContainer
	for entry in TradeSites.BOARD:
		var trade: String = str(entry["trade"])
		var heading := Label.new()
		heading.text = str(entry["name"])
		heading.theme_type_variation = &"LabelTitle"
		list.add_child(heading)
		if not bool(entry["ready"]):
			var soon := _list_card(list, TRADE_ICONS.get(trade), "Coming later", "New sites for this trade are being surveyed.", "", "", false, func() -> void: pass)
			soon.disabled = true
			continue
		var best: int = int(_best_in(trade)["level"])
		for site in TradeSites.for_trade(trade):
			var id: String = str(site["id"])
			var locked: bool = best < int(site["level"])
			var detail: String = "%s level %d  ·  %s" % [TradeSkills.NAMES.get(trade, trade), int(site["level"]), str(site["threat"]["name"]) if int(site["threat"]["danger"]) > 0 else "safe"]
			var busy: bool = false
			for mission in game.missions:
				if str(mission.get("site", "")) == id or (id == "harlow" and str(mission.get("region", "")) == "harlow"):
					busy = true
			var side: String = "Crew out" if busy else ("Locked" if locked else _duration(int(site["duration"])))
			var card := _list_card(list, TRADE_ICONS.get(trade), str(site["name"]), detail, "", side, false, _open_site.bind(id))
			card.toggle_mode = false
			card.tooltip_text = str(site.get("tagline", ""))
			if locked:
				(card.get_node("Body/Side/Value/Text") as Label).theme_type_variation = &"LabelAccent"
				card.tooltip_text += "\nNeeds a mercenary with %s level %d (yours: %d)." % [TradeSkills.NAMES.get(trade, trade), int(site["level"]), best]
			elif busy:
				(card.get_node("Body/Side/Value/Text") as Label).theme_type_variation = &"LabelAccent"
	# Company skills.
	for trade in ["logging", "mining", "foraging", "combat"]:
		var base := c + "Skills/" + str(TradeSkills.NAMES[trade]) + "/Row/"
		(right.get_node(base + "Icon") as TextureRect).texture = TRADE_ICONS.get(trade)
		var best: Dictionary = _best_in(trade)
		var merc: Dictionary = best["merc"]
		(right.get_node(base + "Text/Who") as Label).text = "Nobody trained yet" if merc.is_empty() else "Best: %s" % str(merc.get("name", ""))
		(right.get_node(base + "Level/Value") as Label).text = "Level %d" % int(best["level"])
		(right.get_node(base + "Level/Bar") as ProgressBar).value = 0.0 if merc.is_empty() else TradeSkills.progress(merc, trade) * 100.0
	# Other work.
	var other := right.get_node(c + "Other/Items") as VBoxContainer
	var guild_ok: bool = game.can_accept_guild_work()
	var guild := _list_card(other, ICON_GUILD, "Guild work", "Safe pay for struggling companies", "", "Open  >" if guild_ok else "Not eligible", false, _turn_to.bind("guildwork"))
	guild.toggle_mode = false
	(right.get_node(c + "Other") as Control).custom_minimum_size.y = 70
	(right.get_node(c + "Tip") as Control).visible = game.reports.is_empty()

# --- Generic site spread --------------------------------------------------------

func _draw_site() -> void:
	var site: Dictionary = TradeSites.by_id(selected_site)
	if site.is_empty() or site.has("special"):
		selected_site = "mossward_copse"
		site = TradeSites.by_id(selected_site)
	var left := _mount_page(SITE_LEFT, left_leaf)
	var right := _mount_page(SITE_RIGHT, right_leaf)
	_bind_site_info(left, site)
	_bind_site_plan(right, site)

func _bind_site_info(left: Control, site: Dictionary) -> void:
	var c := "Margin/Content/"
	var trade: String = str(site["trade"])
	(left.get_node(c + "Site/Art") as TextureRect).texture = load(str(site.get("art", ""))) as Texture2D
	(left.get_node(c + "Site/Badge/Text") as Label).text = "%s %d+" % [TradeSkills.NAMES.get(trade, trade), int(site["level"])]
	(left.get_node(c + "Tagline") as Label).text = str(site.get("tagline", ""))
	var slots := left.get_node(c + "Intel/Yields/Slots") as HBoxContainer
	var goods: Dictionary = (site.get("yields", {}) as Dictionary).duplicate()
	goods.merge(site.get("side", {}))
	for good in goods:
		var span: Array = goods[good]
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", -2)
		slots.add_child(box)
		var slot := ITEM_SLOT.instantiate()
		box.add_child(slot)
		slot.icon = _item_icon(str(good))
		slot.tooltip_text = "%s: %d to %d per worker, more with skill and tools.\nMerchants pay %s each today." % [_resource_name(str(good)), int(span[0]), int(span[1]), _money(game.sell_price(str(good)))]
		var amount := Label.new()
		amount.text = "%d-%d" % [int(span[0]), int(span[1])]
		amount.theme_type_variation = &"LabelCaption"
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(amount)
	var rare: Dictionary = site.get("rare", {})
	if not rare.is_empty():
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", -2)
		slots.add_child(box)
		var slot := ITEM_SLOT.instantiate()
		box.add_child(slot)
		slot.icon = _item_icon(str(rare["good"]))
		slot.theme_type_variation = &"GoldPanel"
		slot.tooltip_text = "Rare find: %s, about %.1f%% of trips. Worth %s to a merchant." % [str(rare.get("note", "")), float(rare["chance"]) * 100.0, _money(game.sell_price(str(rare["good"])))]
		var odds := Label.new()
		odds.text = "rare"
		odds.theme_type_variation = &"LabelAccent"
		odds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(odds)
	var threat: Dictionary = site.get("threat", {})
	var danger: int = int(threat.get("danger", 0))
	(left.get_node(c + "Intel/Threat/Body/Name") as Label).text = str(threat.get("name", "None"))
	(left.get_node(c + "Intel/Threat/Body/Name") as Label).theme_type_variation = &"LabelAccent" if danger > 0 else &"LabelGood"
	left.get_node(c + "Intel/Threat/Body/Danger").value = danger
	var notes: Array[String] = []
	if not str(threat.get("note", "")).is_empty():
		notes.append(str(threat["note"]) + ".")
	notes.append("Guards cut the risk and gather at half pace.")
	(left.get_node(c + "Notes") as Label).text = "  ".join(notes)
	# Trip facts follow the chosen orders (Long Shift is six times as long, and so on).
	var order: Dictionary = TradeSites.order_for(site, tactic)
	left.get_node(c + "Facts/Duration").value = _duration(int(round(float(site["duration"]) * float(order["duration"]))))
	left.get_node(c + "Facts/Supplies").value = _money(int(round(float(site.get("supplies", 0)) * float(order.get("cost", 1.0)))))
	left.get_node(c + "Facts/Xp").value = "%d xp" % int(round(float(site.get("xp", 0)) * float(order["xp"])))
	(left.get_node(c + "Footer/Back") as Button).pressed.connect(_turn_to.bind("expeditions"))

func _bind_site_plan(right: Control, site: Dictionary) -> void:
	var c := "Margin/Content/"
	var plan := c + "Planning/"
	var site_id: String = str(site["id"])
	var trade: String = str(site["trade"])
	var busy: bool = game.missions.size() >= game.expedition_slots
	var in_field := right.get_node(c + "InField") as Control
	var field_mission: Dictionary = {}
	for mission in game.missions:
		if str(mission.get("site", "")) == site_id:
			field_mission = mission
			in_field.visible = true
			_bind_expedition_row(in_field, mission)
			(in_field.get_node("Row/Info/Top/Name") as Label).text = "Crew at work"
			(in_field.get_node("Row/IconSlot/Icon") as TextureRect).texture = TRADE_ICONS.get(trade)
			break
	var watching: bool = busy and not field_mission.is_empty()
	var ids: Array[String] = _selected_available()
	if watching:
		ids.clear()
		for id in field_mission.get("ids", []):
			ids.append(str(id))
		(right.get_node(plan + "CrewCaption/Label") as Label).text = "Crew at work"
	var best: int = 0
	for i in range(3):
		var slot := right.get_node(plan + "Slots/Slot" + str(i)) as Button
		var bust := slot.get_node("Body/Bust") as TextureRect
		if i < ids.size():
			var merc: Dictionary = game.merc_by_id(ids[i])
			var level: int = TradeSkills.level_of(merc, trade)
			best = maxi(best, level)
			_set_bust(bust, str(merc.get("role", "")))
			(slot.get_node("Body/Name") as Label).text = str(merc.get("name", "?"))
			(slot.get_node("Body/Role") as Label).text = "%s %d" % [TradeSkills.NAMES.get(trade, trade), level]
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
	var needed: int = int(site["level"])
	var best_label := right.get_node(plan + "CrewCaption/Best") as Label
	best_label.text = "Needs %s %d" % [TradeSkills.NAMES.get(trade, trade), needed]
	best_label.theme_type_variation = &"LabelGood" if best >= needed else &"LabelMuted"
	# Roster: every free mercenary can work; their level in this trade is shown.
	var list := right.get_node(plan + "Roster/Items") as VBoxContainer
	var eligible: int = 0
	for merc in game.available_guild_workers():
		eligible += 1
		var id: String = str(merc["id"])
		var role: String = str(merc.get("role", ""))
		var assigned: bool = ids.has(id)
		var health: int = int(merc.get("health", 100))
		var card := ROW_ROSTER_CARD.instantiate() as Button
		list.add_child(card)
		card.toggle_mode = true
		card.button_pressed = assigned
		(card.get_node("Body/RoleIcon") as TextureRect).texture = ROLE_ICONS.get(role, ROLE_ICONS["Miner"])
		(card.get_node("Body/Info/Name") as Label).text = str(merc.get("name", "?"))
		var gear: int = int(MercsV05.equipment_stats(merc).get(trade, 0))
		(card.get_node("Body/Info/Details") as Label).text = "%s  ·  %s %d%s" % [role, TradeSkills.NAMES.get(trade, trade), TradeSkills.level_of(merc, trade), "  ·  tool +%d" % gear if gear > 0 else ""]
		(card.get_node("Body/Health/HealthText") as Label).text = "Health %d%%" % health
		var hp := card.get_node("Body/Health/HealthBar") as ProgressBar
		hp.value = health
		hp.theme_type_variation = &"GreenBar" if health >= 60 else (&"GoldBar" if health >= 25 else &"")
		var tag := card.get_node("Body/Tag") as Label
		if assigned:
			tag.text = "Assigned"
		elif health < 25:
			tag.text = "Too hurt"
			card.disabled = true
		elif ids.size() >= 3:
			tag.text = "Crew full"
			card.disabled = true
		else:
			tag.text = "+ Assign"
		card.pressed.connect(_toggle_crew.bind(not assigned, id))
	(right.get_node(plan + "Roster") as Control).visible = eligible > 0 and not watching
	(right.get_node(plan + "RosterCaption") as Control).visible = eligible > 0 and not watching
	var no_crew := right.get_node(plan + "NoCrew") as Control
	no_crew.visible = eligible == 0 and not watching
	var hire := right.get_node(plan + "Hire") as Button
	hire.visible = no_crew.visible
	hire.pressed.connect(_open_recruitment)
	var orders: String = str(field_mission.get("tactic", tactic)) if watching else tactic
	for pair in [["Orders/Cautious", "Cautious"], ["Orders/Balanced", "Balanced"], ["Orders/DeepPush", "Deep Push"], ["Away/LongShift", "Long Shift"], ["Away/Overnight", "Overnight"], ["Away/FullDay", "Full Day"]]:
		var btn := right.get_node(plan + str(pair[0])) as Button
		btn.set_pressed_no_signal(orders == str(pair[1]))
		if watching:
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			btn.pressed.connect(_set_tactic.bind(str(pair[1])))
	# Forecast: what this crew should bring home and earn.
	var forecast: Dictionary = game.site_forecast(site_id, ids, orders)
	var units: Dictionary = forecast["units"]
	var main_good: String = str((site.get("yields", {}) as Dictionary).keys()[0])
	var haul: float = float(units.get(main_good, 0.0)) * (1.0 - float(forecast["share"]))
	right.get_node(plan + "Forecast/Haul").value = "%d %s" % [int(round(haul)), _resource_name(main_good).to_lower().get_slice(" ", 0)] if not ids.is_empty() else "-"
	var profit_tile := right.get_node(plan + "Forecast/Profit")
	var profit: int = int(forecast["profit"])
	profit_tile.value = ("+" if profit >= 0 else "") + _money(profit) if not ids.is_empty() else "-"
	profit_tile.tone = "good" if profit > 0 and not ids.is_empty() else ("accent" if not ids.is_empty() else "normal")
	profit_tile.tooltip_text = "Haul worth about %s at today's merchant price, minus %s in wages and supplies." % [_money(int(forecast["value"])), _money(int(forecast["cost"]))]
	var risk_tile := right.get_node(plan + "Forecast/Risk")
	var injury: float = float(forecast["injury"]) * 100.0
	var death: float = float(forecast["death"]) * 100.0
	risk_tile.value = "%d%% hurt" % int(round(injury)) if death <= 0.0 else "%.1f%% die" % death
	risk_tile.tone = "accent" if death > 0.0 else "normal"
	risk_tile.tooltip_text = "Per worker: %.0f%% chance of injury, %.1f%% chance of death." % [injury, death]
	# Fund button.
	var fund := right.get_node(c + "Fund") as Button
	var reason := right.get_node(c + "Reason") as Label
	var why: String = ""
	if busy:
		why = "All expedition slots are busy. Wait for a crew to return."
	elif ids.is_empty() and eligible == 0:
		why = "Hire a woodcutter in Personnel to start."
	elif ids.is_empty():
		why = "Choose a crew: click mercenaries in the list above."
	elif not bool(forecast["meets_level"]):
		why = "Needs a mercenary with %s level %d." % [TradeSkills.NAMES.get(trade, trade), needed]
	elif game.gold < int(forecast["cost"]):
		why = "Not enough gold: wages and supplies cost %s." % _money(int(forecast["cost"]))
	fund.text = "Expedition underway" if busy else "Fund expedition  ·  " + _money(int(forecast["cost"]))
	fund.disabled = not why.is_empty()
	fund.pressed.connect(_dispatch_site)
	reason.text = why
	reason.visible = not why.is_empty()
	(right.get_node(c + "Warning") as Control).visible = not busy and int(site["threat"]["danger"]) > 0

func _dispatch_site() -> void:
	var result: String = game.site_dispatch(selected_site, _selected_available(), tactic)
	if result.begins_with("The crew set out"):
		selected_crew.clear()
		harlow_view.selected.clear()
	_action(result)
