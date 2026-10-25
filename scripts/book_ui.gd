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
const PERSONNEL_TABS := preload("res://scenes/journal/pages/personnel_tabs.tscn")
const PERSONNEL_EMPLOYEES_LEFT := preload("res://scenes/journal/pages/personnel_employed_left.tscn")
const PERSONNEL_EMPLOYEES_RIGHT := preload("res://scenes/journal/pages/personnel_employed_right.tscn")
const PERSONNEL_RECRUITS_LEFT := preload("res://scenes/journal/pages/personnel_recruits_left.tscn")
const PERSONNEL_RECRUITS_RIGHT := preload("res://scenes/journal/pages/personnel_recruits_right.tscn")
const PERSONNEL_ARMORY_LEFT := preload("res://scenes/journal/pages/personnel_armory_left.tscn")
const PERSONNEL_ARMORY_RIGHT := preload("res://scenes/journal/pages/personnel_armory_right.tscn")
const PERSONNEL_WORKSHOP_LEFT := preload("res://scenes/journal/pages/personnel_workshop_left.tscn")
const PERSONNEL_WORKSHOP_RIGHT := preload("res://scenes/journal/pages/personnel_workshop_right.tscn")
const ROW_GEAR_SLOT := preload("res://scenes/journal/rows/gear_slot.tscn")
const ROW_MATERIAL := preload("res://scenes/journal/rows/material_row.tscn")
const ROW_CREW_SLOT := preload("res://scenes/journal/rows/crew_slot.tscn")
const ROW_ROSTER_CARD := preload("res://scenes/journal/rows/roster_card.tscn")
const ROW_SITE := preload("res://scenes/journal/rows/site_card.tscn")
const ROW_LOCKED := preload("res://scenes/journal/rows/locked_row.tscn")
const ROW_EXPEDITION := preload("res://scenes/journal/rows/expedition_row.tscn")
const ROW_EMPTY_EXPEDITION := preload("res://scenes/journal/rows/empty_expedition.tscn")
## Shelves shown on the company page (two rows of nine).
const WAREHOUSE_SLOTS := 18
const ITEM_SLOT := preload("res://scenes/journal/widgets/item_slot.tscn")

const BUSTS := {
	"Labourer": preload("res://assets/ui/portraits/scout_bust.png"),
	"Woodcutter": preload("res://assets/ui/portraits/miner_bust.png"),
	"Miner": preload("res://assets/ui/portraits/miner_bust.png"),
	"Guard": preload("res://assets/ui/portraits/guard_bust.png"),
	"Scout": preload("res://assets/ui/portraits/scout_bust.png"),
	"Forager": preload("res://assets/ui/portraits/scout_bust.png"),
	"Angler": preload("res://assets/ui/portraits/scout_bust.png"),
	"Hunter": preload("res://assets/ui/portraits/scout_bust.png"),
	"Farmhand": preload("res://assets/ui/portraits/miner_bust.png"),
}
const ROLE_ICONS := {
	"Labourer": preload("res://assets/ui/icons/herbs.png"),
	"Miner": preload("res://assets/ui/icons/pickaxe.png"),
	"Guard": preload("res://assets/ui/icons/helmet.png"),
	"Woodcutter": preload("res://assets/ui/icons/axe.png"),
	"Scout": preload("res://assets/ui/icons/herbs.png"),
	"Forager": preload("res://assets/ui/icons/item_sickle.png"),
	"Angler": preload("res://assets/ui/icons/item_rod.png"),
	"Hunter": preload("res://assets/ui/icons/item_bow.png"),
	"Farmhand": preload("res://assets/ui/icons/item_hoe.png"),
}
## Trade skill rows, in the order pages list them.
const SKILL_ORDER := ["logging", "mining", "foraging", "fishing", "hunting", "farming", "combat"]
const TRADE_ICONS := {
	"logging": preload("res://assets/ui/icons/axe.png"),
	"mining": preload("res://assets/ui/icons/pickaxe.png"),
	"foraging": preload("res://assets/ui/icons/herbs.png"),
	"fishing": preload("res://assets/ui/icons/item_rod.png"),
	"hunting": preload("res://assets/ui/icons/item_bow.png"),
	"farming": preload("res://assets/ui/icons/item_hoe.png"),
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
	if page == "contracts":
		page = "expeditions"  # Regional contracts are retired; old links open the board.
		title_label.text = str(PAGE_TITLES["expeditions"])
	if page == "site":
		title_label.text = str(TradeSites.by_id(selected_site).get("name", "Expedition"))
	match page:
		"hq": _draw_company()
		"standing": _draw_company()
		"harlow": _draw_site()  # Old links to the retired Harlow page open its planner.
		"expeditions": _draw_board()
		"site": _draw_site()
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
	# Regions of the newer trades: one label each, opening the best site the company can work.
	for trade in ["foraging", "fishing", "hunting", "farming"]:
		if not left.has_node(sites + trade):
			continue
		var region := left.get_node(sites + trade) as Button
		var best: int = int(_best_in(trade)["level"])
		var open_sites: Array[String] = []
		var target: String = ""
		for site in TradeSites.for_trade(trade):
			var ready: bool = best >= int(site["level"]) and game.has_upgrade(str(site.get("needs", "")))
			open_sites.append("%s%s" % [str(site["name"]), "" if ready else "  (%s %d%s)" % [TradeSkills.NAMES[trade], int(site["level"]), ", needs building" if not game.has_upgrade(str(site.get("needs", ""))) else ""]])
			if ready:
				target = str(site["id"])
		var out: int = 0
		for mission in game.missions:
			if RegionMap.road_for(mission) == trade:
				out += 1
		region.tooltip_text = "%s
%s%s" % [TradeSkills.NAMES[trade], "
".join(open_sites), ("
%d crew working here." % out) if out > 0 else ""]
		if target == "":
			target = str(TradeSites.for_trade(trade)[0]["id"])
		region.pressed.connect(_open_site.bind(target))
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
	left.get_node(c + "Stats/Reputation").value = _standing_short()
	var debt := left.get_node(c + "Stats/Debt")
	debt.value = "None" if game.relief_debt <= 0 else _money(game.relief_debt)
	debt.tone = "accent" if game.relief_debt > 0 else "normal"
	var pieces: int = game.equipment_inventory.size()
	for merc in game.crew:
		pieces += (merc.get("equipment", {}) as Dictionary).size()
	left.get_node(c + "Stats/Gear").value = _plural(pieces, "piece")
	# Warehouse: the goods held, most valuable stack first, over two rows of slots.
	var grid := left.get_node(c + "Goods") as GridContainer
	var held: Array = []
	for key in MoneyMercsState.RESOURCE_ORDER:
		if int(game.resources.get(str(key), 0)) > 0:
			held.append(str(key))
	held.sort_custom(func(a, b): return int(game.resources[a]) * game.sell_price(a) > int(game.resources[b]) * game.sell_price(b))
	var shown: int = WAREHOUSE_SLOTS - 1 if held.size() > WAREHOUSE_SLOTS else held.size()
	for i in range(WAREHOUSE_SLOTS):
		var slot := ITEM_SLOT.instantiate()
		grid.add_child(slot)
		if i < shown:
			var key: String = held[i]
			var amount: int = int(game.resources[key])
			slot.name = key
			slot.icon = _item_icon(key)
			slot.count = amount
			slot.tooltip_text = "%s: %d stored\nSells for %d G each" % [_resource_name(key), amount, game.sell_price(key)]
		elif i == shown and held.size() > shown:
			slot.name = "More"
			slot.count = held.size() - shown
			slot.tooltip_text = "%d more goods in the warehouse. The Exchange lists them all." % (held.size() - shown)
			slot.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _turn_to("market"))
		else:
			slot.dim = true
			slot.tooltip_text = "Empty shelf"
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
	"main_hand": preload("res://assets/ui/icons/empty_main_hand.png"),
	"off_hand": preload("res://assets/ui/icons/empty_off_hand.png"),
	"head": preload("res://assets/ui/icons/empty_helmet.png"),
	"body": preload("res://assets/ui/icons/empty_armor.png"),
	"hands": preload("res://assets/ui/icons/empty_glove.png"),
	"feet": preload("res://assets/ui/icons/empty_boots.png"),
	"trinket": preload("res://assets/ui/icons/empty_trinket.png"),
	"back": preload("res://assets/ui/icons/empty_back.png"),
	"food": preload("res://assets/ui/icons/empty_food.png"),
	"potion": preload("res://assets/ui/icons/empty_potion.png"),
}
## Icons by kind for pieces without their own picture.
const KIND_ICONS := {
	"dagger": "item_dagger", "sword": "sword_steel", "war_axe": "item_war_axe", "mace": "item_mace", "spear": "item_spear",
	"greatsword": "item_greatsword", "bow": "item_bow", "crossbow": "item_crossbow",
	"buckler": "item_shield", "kite_shield": "item_shield", "tower_shield": "item_shield", "lantern": "item_lantern",
	"trinket": "item_ring", "pack": "item_pack", "felling_axe_kind": "axe_felling", "pickaxe": "pickaxe",
	"sickle": "item_sickle", "fishing_rod": "item_rod", "hoe": "item_hoe", "food": "item_bowl", "potion": "healing_draught",
	"head": "helmet", "hands": "gloves", "feet": "boots", "light/body": "armor_leather", "medium/body": "armor_iron", "heavy/body": "armor_iron",
}
const CONTRACT_NOTES := {
	"Balanced": "A standard wage and a modest share of each haul.",
	"Guaranteed Wage": "A higher wage, but a smaller share of the haul.",
	"Profit Share": "A low wage in exchange for a bigger cut of the haul.",
}

var selected_candidate: String = ""

func _gear_icon(key: String) -> Texture2D:
	if ITEM_ICONS.has(key):
		return _item_icon(str(ITEM_ICONS[key]))
	var kind: String = str(Catalog.item(key).get("kind", ""))
	if KIND_ICONS.has(kind):
		return _item_icon(str(KIND_ICONS[kind]))
	return _item_icon(str(KIND_ICONS.get(kind.get_slice("/", 1), "book")))

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
		return ["Resting, too hurt to work", &"LabelAccent"]
	if int(merc.get("health", 100)) < 100:
		return ["Resting  ·  full in " + _duration(MoneyMercsState.rest_eta(merc)), &"LabelAccent"]
	return ["Ready", &"LabelGood"]

func _set_bust(rect: TextureRect, role: String) -> void:
	rect.texture = BUSTS.get(role, BUSTS["Scout"])

# --- Personnel ----------------------------------------------------------------

func _draw_people() -> void:
	match roster_tab:
		"recruits": _draw_recruitment()
		"armory": _draw_armory_page()
		"workshop": _draw_workshop()
		_: _draw_employees()
	var tabs := _mount_page(PERSONNEL_TABS, left_leaf)
	for tab in [["EmployeesTab", "employed"], ["RecruitmentTab", "recruits"], ["ArmoryTab", "armory"], ["WorkshopTab", "workshop"]]:
		var btn := tabs.get_node("Tabs/" + str(tab[0])) as Button
		btn.set_pressed_no_signal(roster_tab == str(tab[1]) or (str(tab[1]) == "employed" and roster_tab not in ["recruits", "armory", "workshop"]))
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
		var role: String = Mercs.role_of(merc)
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
		card.tooltip_text = "%s\nTraits: %s\nHealth %d%%  ·  Gear %d/2" % [Mercs.title(merc), Mercs.trait_names(merc), health, _equipped_count(merc)]
		card.set_pressed_no_signal(id == selected_merc)
		card.pressed.connect(_focus_person.bind(id))
	var empty: bool = game.crew.is_empty()
	(left.get_node(c + "Summary/Count") as Label).text = "%s  ·  %d ready" % ["%d hired" % game.crew.size(), game.free_crew()]
	var payroll_label := left.get_node(c + "Summary/Payroll") as Label
	payroll_label.text = "Payroll %s  ·  idle %s/day" % [_money(payroll), _money(game.idle_upkeep_total())]
	payroll_label.tooltip_text = "Payroll: what one trip with every mercenary would cost in wages.\nIdle: mercenaries in town still draw half their wage each day."
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
	var role: String = Mercs.role_of(merc)
	_set_bust(right.get_node(c + "Head/Portrait/Bust") as TextureRect, role)
	(right.get_node(c + "Head/Id/Name") as Label).text = str(merc.get("name", ""))
	var origin: String = ""
	if merc.has("background"):
		origin = "  ·  formerly a %s" % str(merc["background"]).to_lower()
	elif merc.has("from"):
		origin = "  ·  from %s" % str(merc["from"])
	(right.get_node(c + "Head/Id/Title") as Label).text = Mercs.title(merc) + origin
	(right.get_node(c + "Head/Id/Status/RoleIcon") as TextureRect).texture = ROLE_ICONS.get(role, ROLE_ICONS["Miner"])
	(right.get_node(c + "Head/Id/Status/Role") as Label).text = role
	var status: Array = _merc_status(merc)
	var state := right.get_node(c + "Head/Id/Status/State") as Label
	state.text = "·  " + str(status[0])
	state.theme_type_variation = status[1]
	var terms: Dictionary = game.terms(merc)
	right.get_node(c + "Stats/Skill").value = _money(Mercs.value(merc))
	var job: String = Mercs.job(merc)
	var exp_tile := right.get_node(c + "Stats/Experience")
	exp_tile.value = "No tool" if job == "" else "%s %d" % [TradeSkills.NAMES.get(job, job), TradeSkills.level_of(merc, job)]
	var wage_tile := right.get_node(c + "Stats/Wage")
	wage_tile.value = _money(int(terms["wage"]))
	wage_tile.tooltip_text = "Paid for each trip. In town they draw half of it each day (%s/day)." % _money(int(round(game.idle_upkeep(merc))))
	right.get_node(c + "Stats/Share").value = "%d%%" % int(round(float(terms["cut"]) * 100.0))
	var health: int = int(merc.get("health", 100))
	var bar := right.get_node(c + "Health/Bar") as ProgressBar
	bar.value = health
	bar.theme_type_variation = &"GreenBar" if health >= 60 else (&"GoldBar" if health >= 25 else &"")
	(right.get_node(c + "Health/Value") as Label).text = "%d%%" % health
	var heal := right.get_node(c + "Health/Heal") as Button
	heal.visible = health < 100
	if heal.visible:
		var cost: int = MoneyMercsState.treat_cost(merc)
		heal.text = "Treat  ·  %d G" % cost
		heal.disabled = game.gold < cost or not game.is_available(merc)
		heal.tooltip_text = "Resting in town heals %d health an hour for free: back to full in %s.\nTreat now to send them out sooner." % [MoneyMercsState.REST_PER_HOUR, _duration(MoneyMercsState.rest_eta(merc))]
		heal.pressed.connect(_heal.bind(selected_merc))
	for trade in SKILL_ORDER:
		var base := c + "Skills/" + str(TradeSkills.NAMES[trade]) + "/"
		(right.get_node(base + "Level") as Label).text = "%s %d" % [TradeSkills.NAMES[trade], TradeSkills.level_of(merc, trade)]
		(right.get_node(base + "Bar") as ProgressBar).value = TradeSkills.progress(merc, trade) * 100.0
	var traits := right.get_node(c + "Traits/List") as Label
	traits.text = Mercs.trait_names(merc) if not (merc.get("traits", []) as Array).is_empty() else "None"
	traits.tooltip_text = Mercs.trait_lines(merc)
	Gear.ensure(merc)
	var gear_grid := right.get_node(c + "Gear") as GridContainer
	for slot in Gear.SLOTS:
		var slot_button := _gear_slot_button(slot, Gear.in_slot(merc, slot), false, _outfit_slot.bind(selected_merc, slot))
		slot_button.custom_minimum_size = Vector2(24, 26)
		gear_grid.add_child(slot_button)
	(right.get_node(c + "GearHead/Kit") as Label).text = "Kit %d  ·  Armour %d" % [Gear.kit_rating(merc), int(Gear.armour(merc))]
	var contract: String = str(merc.get("contract", "Balanced"))
	(right.get_node(c + "Contract/Body/Top/Text/Name") as Label).text = contract
	(right.get_node(c + "Contract/Body/Explain") as Label).text = str(CONTRACT_NOTES.get(contract, ""))
	var change := right.get_node(c + "Contract/Body/Top/Change") as Button
	change.disabled = not game.is_available(merc)
	change.pressed.connect(_terms.bind(selected_merc))
	(right.get_node(c + "Actions/Armory") as Button).pressed.connect(_outfit.bind(selected_merc))
	var sell := right.get_node(c + "Actions/Sell") as Button
	var offer: int = game.contract_offer(merc)
	var settling: int = game.settling_left(merc)
	sell.text = ("Confirm  ·  %s" % _money(offer)) if confirm_sell == selected_merc else "Sell contract"
	sell.disabled = not game.is_available(merc) or settling > 0
	sell.tooltip_text = "Settling in: can be sold in %s." % _duration(settling) if settling > 0 else \
		"Another guild buys their contract for %s (half their value), with the gear they wear.\nMercenaries talk: each sale costs a little reputation." % _money(offer)
	sell.pressed.connect(_sell_contract.bind(selected_merc))

func _choose_candidate(id: String) -> void:
	selected_candidate = id
	_refresh()

func _standing_short() -> String:
	return "%s · %s" % [Mercs.tier_name(game.rep_tier()), _thousands(game.reputation)]

func _thousands(n: int) -> String:
	var t: String = str(absi(n))
	var out: String = ""
	while t.length() > 3:
		out = "," + t.substr(t.length() - 3) + out
		t = t.substr(0, t.length() - 3)
	return ("-" if n < 0 else "") + t + out

func _candidate_line(candidate: Dictionary) -> String:
	var best: String = Mercs.best_trade(candidate)
	var parts: Array[String] = ["%s %d" % [TradeSkills.NAMES[best], Mercs.level(candidate, best)]]
	var traits: String = Mercs.trait_names(candidate)
	if traits != "":
		parts.append(traits)
	if str(candidate.get("kind", "")) == "contract":
		parts.append("contract")
	return "  ·  ".join(parts)

func _draw_recruitment() -> void:
	var left := _mount_page(PERSONNEL_RECRUITS_LEFT, left_leaf)
	var right := _mount_page(PERSONNEL_RECRUITS_RIGHT, right_leaf)
	var c := "Margin/Content/"
	var board: Array[Dictionary] = game.recruitment_board()
	# Applicants first, cheapest first; then contracts other guilds are selling.
	board.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ka: int = 1 if str(a.get("kind", "")) == "contract" else 0
		var kb: int = 1 if str(b.get("kind", "")) == "contract" else 0
		return ka < kb if ka != kb else int(a["hire"]) < int(b["hire"]))
	var chosen: Dictionary = {}
	for candidate in board:
		if str(candidate["id"]) == selected_candidate:
			chosen = candidate
	if chosen.is_empty() and not board.is_empty():
		chosen = board[0]
		selected_candidate = str(chosen["id"])
	var list := left.get_node(c + "List/Items") as VBoxContainer
	for candidate in board:
		var role: String = Mercs.role_of(candidate)
		var fee: int = int(candidate["hire"])
		var contract: bool = str(candidate.get("kind", "")) == "contract"
		var card := _list_card(list, ROLE_ICONS.get(role, ROLE_ICONS["Miner"]), str(candidate["name"]),
			_candidate_line(candidate), "Price" if contract else "Fee", _money(fee), str(candidate["id"]) == selected_candidate, _choose_candidate.bind(str(candidate["id"])))
		card.tooltip_text = Mercs.trait_lines(candidate)
		if game.gold < fee:
			(card.get_node("Body/Side/Value/Text") as Label).theme_type_variation = &"LabelMuted"
	(left.get_node(c + "Summary/Count") as Label).text = "%d waiting" % board.size()
	var tier: int = game.rep_tier()
	var standing := left.get_node(c + "Standing") as Label
	var next: int = Mercs.rep_to_next(game.reputation)
	standing.text = "Reputation %s: %s. Applicants up to level %d.%s" % [_thousands(game.reputation), Mercs.tier_name(tier), int(Mercs.TIERS[tier]["cap"]),
		("  %s at %s." % [Mercs.tier_name(tier + 1), _thousands(int(Mercs.TIERS[tier + 1]["rep"]))]) if next > 0 else ""]
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
	var role: String = Mercs.role_of(chosen)
	var contract: bool = str(chosen.get("kind", "")) == "contract"
	_set_bust(right.get_node(c + "Head/Portrait/Bust") as TextureRect, role)
	(right.get_node(c + "Head/Id/Name") as Label).text = str(chosen["name"])
	(right.get_node(c + "Head/Id/Title") as Label).text = ("Contract from %s" % str(chosen.get("from", "a guild"))) if contract else Mercs.title(chosen)
	(right.get_node(c + "Head/Id/Status/RoleIcon") as TextureRect).texture = ROLE_ICONS.get(role, ROLE_ICONS["Miner"])
	var kit: String = str(game.item_definition(str(chosen.get("kit", ""))).get("name", ""))
	(right.get_node(c + "Head/Id/Status/Role") as Label).text = ("Brings their own %s" % kit) if kit != "" else role
	right.get_node(c + "Stats/Skill").value = _money(Mercs.value(chosen, false) + int(game.item_definition(str(chosen.get("kit", ""))).get("cost", 0)))
	var fee_tile := right.get_node(c + "Stats/Fee")
	fee_tile.caption = "Price + fee" if contract else "Signing fee"
	fee_tile.value = _money(int(chosen["hire"]))
	right.get_node(c + "Stats/Wage").value = _money(int(game.terms(chosen)["wage"]))
	right.get_node(c + "Stats/Share").value = "%d%%" % int(round(float(game.terms(chosen)["cut"]) * 100.0))
	for trade in SKILL_ORDER:
		var base := c + "Skills/" + str(TradeSkills.NAMES[trade]) + "/"
		(right.get_node(base + "Level") as Label).text = "%s %d" % [TradeSkills.NAMES[trade], Mercs.level(chosen, trade)]
		(right.get_node(base + "Bar") as ProgressBar).value = TradeSkills.progress(chosen, trade) * 100.0
	var note := right.get_node(c + "RoleNote")
	var lines: Array[String] = []
	for t in chosen.get("traits", []):
		var d: Dictionary = Mercs.TRAITS.get(str(t), {})
		lines.append("%s (%s): %s" % [str(d.get("name", t)), str(d.get("rarity", "")), str(d.get("text", ""))])
	if contract:
		lines.append("Includes a 10% transfer fee. They settle in for 3 days before they can be sold on.")
	note.text = "\n".join(lines) if not lines.is_empty() else "No traits."
	var fee: int = int(chosen["hire"])
	var hire := right.get_node(c + "Hire") as Button
	hire.text = "%s %s  ·  %s" % ["Buy" if contract else "Hire", str(chosen["name"]).get_slice(" ", 0), _money(fee)]
	hire.disabled = game.gold < fee
	hire.pressed.connect(_hire.bind(str(chosen["id"])))
	var reason := right.get_node(c + "Reason") as Label
	reason.text = "Not enough gold: %s." % _money(fee) if game.gold < fee else ""
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
		var role: String = Mercs.role_of(merc)
		var away: bool = not game.is_available(merc)
		var card := _list_card(picker, ROLE_ICONS.get(role, ROLE_ICONS["Miner"]), str(merc["name"]),
			Mercs.title(merc) + ("  ·  in the field" if away else ""), "Kit", str(Gear.kit_rating(merc)), id == selected_merc, _choose_worker.bind(id))
		card.custom_minimum_size.y = 30
	(left.get_node(c + "Crew") as Control).custom_minimum_size.y = mini(game.crew.size(), 3) * 33
	var none: bool = owner.is_empty()
	(left.get_node(c + "Empty") as Control).visible = game.crew.is_empty()
	for path in ["Caption", "Crew", "LoadoutHeader", "Loadout", "Tip"]:
		(left.get_node(c + path) as Control).visible = not game.crew.is_empty()
	if not none:
		Gear.ensure(owner)
		var available: bool = game.is_available(owner)
		(left.get_node(c + "Loadout/Body/Who") as Label).text = "%s  ·  %s" % [str(owner["name"]), Mercs.title(owner)]
		var grid := left.get_node(c + "Loadout/Body/Slots") as GridContainer
		if not Gear.SLOTS.has(selected_slot):
			selected_slot = "main_hand"
		for slot in Gear.SLOTS:
			var item: Dictionary = Gear.in_slot(owner, slot)
			grid.add_child(_gear_slot_button(slot, item, slot == selected_slot, _choose_slot.bind(slot)))
		var picked: Dictionary = Gear.in_slot(owner, selected_slot)
		var base := c + "Loadout/Body/Picked/"
		(left.get_node(base + "Info/Name") as Label).text = "%s: %s" % [Gear.SLOT_NAMES[selected_slot], _equipment_name(picked) if not picked.is_empty() else "empty"]
		var detail := left.get_node(base + "Info/Detail") as Label
		if picked.is_empty():
			detail.text = SLOT_HINTS.get(selected_slot, "")
		elif Gear.CONSUMABLE_SLOTS.has(selected_slot):
			detail.text = Gear.summary(str(picked["key"])).get_slice("·", 1).strip_edges()
		else:
			var extra: String = Gear.rolls_text(picked)
			detail.text = ("%d/%d" % [Gear.durability(picked), Gear.max_durability(picked)] if Gear.max_durability(picked) > 0 else "") + ("  ·  " + extra if extra != "" else "")
		detail.tooltip_text = Gear.describe(picked)
		detail.mouse_filter = Control.MOUSE_FILTER_PASS
		var remove := left.get_node(base + "Remove") as Button
		remove.visible = not picked.is_empty()
		remove.disabled = not available
		remove.pressed.connect(_unequip.bind(selected_merc, selected_slot))
		var repair := left.get_node(base + "Repair") as Button
		var cost: Dictionary = {} if picked.is_empty() or Gear.CONSUMABLE_SLOTS.has(selected_slot) else game.repair_cost(picked)
		repair.visible = not cost.is_empty()
		if repair.visible:
			var spend: int = game.repair_gold(cost)
			repair.text = "Repair" + ("  ·  %s" % _money(spend) if spend > 0 else "")
			repair.disabled = not available or game.gold < spend
			repair.tooltip_text = "Uses %s. Anything not in the warehouse is bought from the merchants." % _cost_line(cost)
			repair.pressed.connect(_repair.bind(str(picked["uid"])))
		var bonus := left.get_node(c + "Loadout/Body/Foot/Bonus") as Label
		var job: String = Gear.job(owner)
		var bits: Array[String] = ["Kit %d" % Gear.kit_rating(owner), "Armour %d" % int(Gear.armour(owner))]
		if job != "" and job != "combat":
			bits.append("%s +%d" % [TradeSkills.NAMES[job], int(Gear.tool_power(owner, job))])
		elif job == "combat":
			bits.append("Guards +%d" % Gear.weapon_levels(owner))
		var haul: float = Gear.haul_mult(owner) - 1.0
		if haul > 0.001:
			bits.append("Haul +%d%%" % int(round(haul * 100.0)))
		bonus.text = "  ·  ".join(bits)
		bonus.tooltip_text = "Armour and dodge lower the chance of injury and death. The tool sets the job; a weapon makes them a guard.\nInjury chance x%.2f, death chance x%.2f compared with no gear." % [Gear.injury_mult(owner), Gear.death_mult(owner)]
		var damaged: int = 0
		for item in Gear.worn(owner):
			if not game.repair_cost(item).is_empty():
				damaged += 1
		var all := left.get_node(c + "Loadout/Body/Foot/RepairAll") as Button
		all.visible = damaged > 1
		all.disabled = not available
		all.pressed.connect(_repair_all.bind(selected_merc))
	# Storeroom: loose gear (equip, repair, sell) and food and potions (pack).
	var store := right.get_node(c + "Store/Items") as VBoxContainer
	var stored: int = 0
	for item in game.equipment_inventory:
		var key: String = str(item.get("key", ""))
		var card := ROW_ITEM_CARD.instantiate()
		store.add_child(card)
		stored += 1
		(card.get_node("Row/IconSlot/Icon") as TextureRect).texture = _gear_icon(key)
		(card.get_node("Row/Info/Name") as Label).text = Gear.full_name(item)
		var wear: String = ("  ·  %d/%d" % [Gear.durability(item), Gear.max_durability(item)]) if Gear.max_durability(item) > 0 else ""
		(card.get_node("Row/Info/Details") as Label).text = Gear.summary(key) + wear
		card.tooltip_text = Gear.describe(item)
		var fits: bool = not none and game.is_available(owner)
		var equip := card.get_node("Row/Primary") as Button
		equip.text = "Equip"
		equip.disabled = not fits
		equip.tooltip_text = "Equip on %s. The tool in their hands sets their job." % str(owner.get("name", "")) if fits else "Choose a mercenary who isn't in the field."
		equip.pressed.connect(_equip.bind(selected_merc, str(item.get("uid", ""))))
		var sell := card.get_node("Row/Secondary") as Button
		sell.visible = true
		var value: int = game.resale_value(item)
		sell.text = "Sell %d" % value
		sell.tooltip_text = "Sell for %s (65%% of its worth, less if worn)." % _money(value)
		sell.pressed.connect(_sell_equipment.bind(str(item.get("uid", ""))))
		var cost: Dictionary = game.repair_cost(item)
		var fix := card.get_node("Row/Tertiary") as Button
		fix.visible = not cost.is_empty()
		if fix.visible:
			fix.text = "Repair"
			fix.disabled = game.gold < game.repair_gold(cost)
			fix.tooltip_text = "Uses %s." % _cost_line(cost)
			fix.pressed.connect(_repair.bind(str(item.get("uid", ""))))
	for key in MoneyMercsState.RESOURCE_ORDER:
		if not Gear.consumable(str(key)) or int(game.resources.get(key, 0)) <= 0:
			continue
		var card := ROW_ITEM_CARD.instantiate()
		store.add_child(card)
		stored += 1
		(card.get_node("Row/IconSlot/Icon") as TextureRect).texture = _item_icon(str(key))
		(card.get_node("Row/Info/Name") as Label).text = "%s  ×%d" % [_resource_name(str(key)), int(game.resources[key])]
		(card.get_node("Row/Info/Details") as Label).text = Gear.summary(str(key))
		var pack := card.get_node("Row/Primary") as Button
		pack.text = "Pack"
		pack.disabled = none or not game.is_available(owner)
		pack.tooltip_text = "Put one in %s's %s slot." % [str(owner.get("name", "")), Gear.slot_of(str(key))]
		pack.pressed.connect(_supply.bind(selected_merc, str(key)))
	(right.get_node(c + "Store") as Control).visible = stored > 0
	(right.get_node(c + "StoreEmpty") as Control).visible = stored == 0
	# Quartermaster: the starter gear, ready-made (everything else is crafted in the Workshop).
	var shop := right.get_node(c + "Shop/Items") as VBoxContainer
	for key in MercsV05.shop_keys():
		var definition: Dictionary = game.item_definition(str(key))
		var card := ROW_ITEM_CARD.instantiate()
		shop.add_child(card)
		(card.get_node("Row/IconSlot/Icon") as TextureRect).texture = _gear_icon(str(key))
		(card.get_node("Row/Info/Name") as Label).text = str(definition["name"])
		(card.get_node("Row/Info/Details") as Label).text = Gear.summary(str(key))
		var buy := card.get_node("Row/Primary") as Button
		buy.text = _money(int(definition["cost"]))
		buy.disabled = game.gold < int(definition["cost"])
		buy.tooltip_text = "Buy a common one for the storeroom. Crafted pieces can roll better."
		buy.pressed.connect(_buy_equipment.bind(str(key)))

const SLOT_HINTS := {
	"main_hand": "A tool sets the job; a weapon makes a guard.", "off_hand": "A shield, or a lantern for rare finds.",
	"head": "Armour.", "body": "Armour.", "hands": "Armour.", "feet": "Armour.",
	"trinket": "A ring, charm or amulet.", "back": "A pack carries more home.",
	"food": "Eaten on the next trip.", "potion": "Healing draughts are drunk when hurt.",
}

var selected_slot: String = "main_hand"
var selected_recipe: String = ""

func _choose_slot(slot: String) -> void:
	selected_slot = slot
	_refresh()

func _choose_recipe(key: String) -> void:
	selected_recipe = key
	_refresh()

func _cost_line(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for part in cost:
		parts.append(("%d G" % int(cost[part])) if part == "gold" else "%d %s" % [int(cost[part]), _resource_name(str(part))])
	return ", ".join(parts)

## A slot button: the piece's icon (or the slot's empty icon) and its durability.
func _gear_slot_button(slot: String, item: Dictionary, selected: bool, action: Callable) -> Button:
	var b := ROW_GEAR_SLOT.instantiate() as Button
	var s := b.get_node("Slot")
	s.icon = EMPTY_SLOT_ICONS.get(slot) if item.is_empty() else (_item_icon(str(item["key"])) if Gear.CONSUMABLE_SLOTS.has(slot) else _gear_icon(str(item["key"])))
	s.dim = item.is_empty()
	var bar := b.get_node("Wear") as ProgressBar
	var top: int = 0 if item.is_empty() else Gear.max_durability(item)
	bar.visible = top > 0
	if top > 0:
		var frac: float = float(Gear.durability(item)) / float(top)
		bar.value = frac * 100.0
		bar.theme_type_variation = &"GreenBar" if frac >= 0.5 else (&"GoldBar" if frac > 0.0 else &"")
	b.tooltip_text = "%s: %s" % [Gear.SLOT_NAMES[slot], Gear.describe(item) if not item.is_empty() else "empty. " + str(SLOT_HINTS.get(slot, ""))]
	b.set_pressed_no_signal(selected)
	b.pressed.connect(action)
	return b

# --- Personnel: workshop ----------------------------------------------------------

func _draw_workshop() -> void:
	var left := _mount_page(PERSONNEL_WORKSHOP_LEFT, left_leaf)
	var right := _mount_page(PERSONNEL_WORKSHOP_RIGHT, right_leaf)
	var c := "Margin/Content/"
	var known: Array = []
	for key in Catalog.items():
		if game.knows(str(key)):
			known.append(str(key))
	# What can be made right now first, then by tier and value.
	known.sort_custom(func(a, b):
		var ra: int = (0 if game.craft_missing(a).is_empty() else 1) + (0 if game.makeable(a) else 2)
		var rb: int = (0 if game.craft_missing(b).is_empty() else 1) + (0 if game.makeable(b) else 2)
		if ra != rb:
			return ra < rb
		return int(Catalog.item(a)["tier"]) * 100000 + int(Catalog.item(a)["value"]) < int(Catalog.item(b)["tier"]) * 100000 + int(Catalog.item(b)["value"]))
	var shop: Array = game.blueprint_shop()
	if selected_recipe == "" or not Catalog.items().has(selected_recipe):
		selected_recipe = str(known[0]) if not known.is_empty() else (str(shop[0]) if not shop.is_empty() else "")
	var list := left.get_node(c + "Known/Items") as VBoxContainer
	for key in known:
		var missing: Dictionary = game.craft_missing(key)
		var ready: bool = missing.is_empty()
		var line: String = "Ready to craft" if ready else ("Missing " + _cost_line(missing) if game.makeable(key) else "Needs goods from expeditions not open yet")
		var card := _list_card(list, _recipe_icon(key), str(Catalog.item(key)["name"]),
			line, "Worth", _money(int(Catalog.item(key)["value"])),
			key == selected_recipe, _choose_recipe.bind(key))
		card.custom_minimum_size.y = 30
		if not ready:
			(card.get_node("Body/Info/Details") as Label).theme_type_variation = &"LabelMuted"
	(left.get_node(c + "Summary") as Label).text = "%d blueprints known. Anyone can craft with the materials and the blueprint." % known.size()
	(left.get_node(c + "Known") as Control).visible = not known.is_empty()
	(left.get_node(c + "KnownEmpty") as Control).visible = known.is_empty()
	var shelf := left.get_node(c + "Shop/Items") as VBoxContainer
	for key in shop:
		var price: int = int(Catalog.item(key).get("blueprint_price", 40))
		var card := _list_card(shelf, _recipe_icon(key), str(Catalog.item(key)["name"]), Gear.summary(key) if game.makeable(key) else "Not makeable yet  ·  " + Gear.summary(key),
			"Blueprint", _money(price), key == selected_recipe, _choose_recipe.bind(key))
		card.custom_minimum_size.y = 30
		if not game.makeable(key):
			(card.get_node("Body/Info/Details") as Label).theme_type_variation = &"LabelMuted"
		if game.gold < price:
			(card.get_node("Body/Side/Value/Text") as Label).theme_type_variation = &"LabelMuted"
	(left.get_node(c + "ShopHeader") as Control).visible = not shop.is_empty()
	(left.get_node(c + "Shop") as Control).visible = not shop.is_empty()
	# The recipe.
	var none: bool = selected_recipe == ""
	for child in (right.get_node("Margin/Content") as Control).get_children():
		(child as CanvasItem).visible = (child.name == "Empty" or child.name == "Header") if none else child.name != "Empty"
	if none:
		return
	var d: Dictionary = Catalog.item(selected_recipe)
	var head_slot := right.get_node(c + "Head/Slot")
	head_slot.icon = _recipe_icon(selected_recipe)
	(right.get_node(c + "Head/Id/Name") as Label).text = str(d["name"])
	var summary := right.get_node(c + "Head/Id/Summary") as Label
	summary.text = Gear.summary(selected_recipe)
	summary.tooltip_text = summary.text
	summary.mouse_filter = Control.MOUSE_FILTER_PASS
	right.get_node(c + "Stats/Value").value = _money(int(d["value"]))
	var mat_value: int = 0
	var rows := right.get_node(c + "Materials") as VBoxContainer
	var recipe: Dictionary = d.get("recipe", {}) if d.get("recipe") is Dictionary else {}
	for part in recipe:
		var row := ROW_MATERIAL.instantiate()
		rows.add_child(row)
		(row.get_node("Icon") as TextureRect).texture = _item_icon(str(part)) if _item_icon(str(part)) != null else _recipe_icon(str(part))
		(row.get_node("Name") as Label).text = _resource_name(str(part)) if MoneyMercsState.RESOURCE_NAMES.has(part) else str(Catalog.material(str(part)).get("name", part))
		var have: int = int(game.resources.get(str(part), 0))
		var need: int = int(recipe[part])
		var have_label := row.get_node("Have") as Label
		have_label.text = "%d / %d" % [have, need]
		have_label.theme_type_variation = &"LabelGood" if have >= need else &"LabelAccent"
		if not MoneyMercsState.RESOURCE_ORDER.has(part):
			row.tooltip_text = "Not sold anywhere yet: comes from %s." % ", ".join(_source_names(str(part)))
		mat_value += need * (game.price(str(part)) if MoneyMercsState.RESOURCE_ORDER.has(part) else int(Catalog.value_of(str(part))))
	right.get_node(c + "Stats/Cost").value = _money(mat_value)
	var rolls := right.get_node(c + "Rolls")
	if Gear.equippable(selected_recipe) and not Gear.consumable(selected_recipe):
		var names: Array[String] = []
		for r in d.get("rolls", []):
			names.append(str(Catalog.data()["affixes"][r]["name"]))
		rolls.text = "Rolls Common 60%%, Fine 28%% (+1 stat), Superior 10%% (+2), Masterwork 2%% (+3). Can roll: %s." % ", ".join(names)
	else:
		rolls.text = str(d.get("note", "Goes to the warehouse."))
	var knows: bool = game.knows(selected_recipe)
	var craft := right.get_node(c + "Craft") as Button
	var reason := right.get_node(c + "Reason") as Label
	if knows:
		var missing: Dictionary = game.craft_missing(selected_recipe)
		craft.text = "Craft %s" % str(d["name"])
		craft.disabled = not missing.is_empty()
		craft.pressed.connect(_craft.bind(selected_recipe))
		reason.text = "" if missing.is_empty() else "Missing " + _cost_line(missing) + "."
	else:
		var price: int = int(d.get("blueprint_price", 0))
		var sold: bool = (d.get("blueprint", []) as Array).has("quartermaster")
		craft.text = ("Buy blueprint  ·  %s" % _money(price)) if sold else "Blueprint not owned"
		craft.disabled = not sold or game.gold < price
		if sold:
			craft.pressed.connect(_buy_blueprint.bind(selected_recipe))
		reason.text = "" if sold else "Found in " + ", ".join(_source_names_bp(d)) + "."
	reason.visible = not reason.text.is_empty()

func _source_names(material: String) -> Array[String]:
	var out: Array[String] = []
	for src in Catalog.material(material).get("sources", []):
		out.append(str(Catalog.sources().get(src, {}).get("name", src)))
	return out

func _source_names_bp(d: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for src in d.get("blueprint", []):
		out.append(str(Catalog.sources().get(src, {}).get("name", src)))
	return out

## Any catalog thing: its own picture if it has one, else its kind's, else a book.
func _recipe_icon(key: String) -> Texture2D:
	if Catalog.materials().has(key) or MoneyMercsState.RESOURCE_ORDER.has(key) or Gear.consumable(key):
		var own: Texture2D = _item_icon(key)
		if own != null:
			return own
		if Catalog.materials().has(key):
			return _item_icon(str(MATERIAL_GROUP_ICONS.get(str(Catalog.material(key).get("group", "")), "book")))
	return _gear_icon(key)

const MATERIAL_GROUP_ICONS := {"timber": "timber", "sap": "amber", "gem": "crystal", "ore": "iron", "metal": "steel_ingot", "herb": "herbs",
	"fish": "item_bowl", "meat": "item_bowl", "hide": "wolf_pelt", "hunt": "relic", "crop": "herbs", "fibre": "spider_silk", "treasure": "relic"}

# --- Exchange -----------------------------------------------------------------

func _market_shows(key: String, stored: int) -> bool:
	match market_filter:
		"held": return stored > 0
		"raw", "crafted", "food": return str(MoneyMercsState.RESOURCE_KIND.get(key, "raw")) == market_filter
	return true

func _choose_commodity(id: String) -> void:
	selected_market_item = id
	_refresh()

func _draw_exchange() -> void:
	var left := _mount_page(EXCHANGE_LEFT, left_leaf)
	var right := _mount_page(EXCHANGE_RIGHT, right_leaf)
	var c := "Margin/Content/"
	var list := left.get_node(c + "List/Items") as VBoxContainer
	for kind in ["All", "Held", "Raw", "Crafted", "Food"]:
		var tab := left.get_node(c + "Filter/" + kind) as Button
		tab.set_pressed_no_signal(market_filter == kind.to_lower())
		tab.pressed.connect(func() -> void:
			market_filter = kind.to_lower()
			_refresh())
	for id in MoneyMercsState.RESOURCE_ORDER:
		var key: String = str(id)
		var stored: int = int(game.resources.get(key, 0))
		if not _market_shows(key, stored):
			continue
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
	var buyable: bool = game.merchants_sell(key)
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
		buy.tooltip_text = "-%s (%s each)" % [_money(game.buy_price(key, n) * n), _money(game.buy_price(key, n))] if buyable else ("Merchants never sell these. Find them in the field." if key in ["relic", "sovereign"] else "Merchants don't stock food or potions: cook or brew them, or buy from players.")
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
	left.get_node(c + "Costs/Reputation").value = _standing_short()
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
		var role: String = Mercs.role_of(member)
		var card := _list_card(list, ROLE_ICONS.get(role, ROLE_ICONS["Miner"]), str(member.get("name", "Contractor")),
			Mercs.title(member), "", "Assign" if can_take else "", false, _guild_work.bind(str(member["id"])))
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
	if not TradeSites.BOARD.any(func(e): return str(e["trade"]) == selected_trade and bool(e["ready"])):
		selected_trade = "logging"
	# Left: one row per trade, with the best hand, crews out and sites open.
	var trades := left.get_node(c + "Trades") as VBoxContainer
	for entry in TradeSites.BOARD:
		var trade: String = str(entry["trade"])
		if not bool(entry["ready"]):
			continue
		var best: Dictionary = _best_in(trade)
		var merc: Dictionary = best["merc"]
		var sites: Array = TradeSites.for_trade(trade)
		var open: int = 0
		for site in sites:
			if int(best["level"]) >= int(site["level"]):
				open += 1
		var out: int = 0
		for mission in game.missions:
			if str(mission.get("trade", "")) == trade or (trade == "mining" and str(mission.get("region", "")) == "harlow"):
				out += 1
		var who: String = "Nobody trained yet" if merc.is_empty() else "Best: %s  ·  Lv %d" % [str(merc.get("name", "")), int(best["level"])]
		var card := _list_card(trades, TRADE_ICONS.get(trade), str(entry["name"]), who, "%d out" % out if out > 0 else "",
			"%d of %d open" % [open, sites.size()], selected_trade == trade, _select_trade.bind(trade))
		if out > 0:
			(card.get_node("Body/Side/Caption") as Label).theme_type_variation = &"LabelGood"
	var guard: Dictionary = _best_in("combat")
	var guard_card := _list_card(trades, TRADE_ICONS["combat"], "Guarding",
		"Nobody trained yet" if (guard["merc"] as Dictionary).is_empty() else "Best: %s  ·  Combat %d" % [str(guard["merc"].get("name", "")), int(guard["level"])],
		"", "", false, func() -> void: pass)
	guard_card.toggle_mode = false
	guard_card.mouse_default_cursor_shape = Control.CURSOR_ARROW
	guard_card.tooltip_text = "Guards have no sites of their own: add one to any crew."
	# Right: the chosen trade's sites. Open ones as cards, locked ones as a line each.
	right.get_node(c + "Header").text = str(TradeSkills.NAMES.get(selected_trade, selected_trade))
	var open_list := right.get_node(c + "Open") as VBoxContainer
	var locked_list := right.get_node(c + "Locked") as VBoxContainer
	var level: int = int(_best_in(selected_trade)["level"])
	var workers: Array[String] = []
	for merc in game.available_guild_workers():
		if Mercs.job(merc) == selected_trade or (selected_trade == "hunting" and Gear.hunts(merc)):
			workers.append(str(merc["id"]))
	workers.sort_custom(func(a, b): return TradeSkills.xp_of(game.merc_by_id(a), selected_trade) > TradeSkills.xp_of(game.merc_by_id(b), selected_trade))
	for site in TradeSites.for_trade(selected_trade):
		var id: String = str(site["id"])
		if level < int(site["level"]):
			var row := ROW_LOCKED.instantiate() as Button
			locked_list.add_child(row)
			(row.get_node("Body/Name") as Label).text = str(site["name"])
			(row.get_node("Body/Need") as Label).text = "%s %d" % [TradeSkills.NAMES.get(selected_trade, selected_trade), int(site["level"])]
			row.tooltip_text = "%s\nNeeds a mercenary with %s level %d (your best: %d)." % [str(site.get("tagline", "")), TradeSkills.NAMES.get(selected_trade, selected_trade), int(site["level"]), level]
			row.pressed.connect(_open_site.bind(id))
			continue
		var card := ROW_SITE.instantiate() as Button
		open_list.add_child(card)
		card.pressed.connect(_open_site.bind(id))
		card.tooltip_text = str(site.get("tagline", ""))
		var threat: Dictionary = site.get("threat", {})
		var risk: String = "safe" if float(site.get("death", 0.0)) <= 0.0 else "%.1f%% death" % (float(site["death"]) * 100.0)
		(card.get_node("Body/Top/Info/Name") as Label).text = str(site["name"])
		(card.get_node("Body/Top/Info/Details") as Label).text = "%s  ·  %s" % [str(threat.get("name", "")), risk]
		var goods: Array[String] = []
		for good in site.get("yields", {}):
			goods.append(_resource_name(str(good)).to_lower())
		var busy: bool = false
		for mission in game.missions:
			if str(mission.get("site", "")) == id or (id == "harlow" and str(mission.get("region", "")) == "harlow"):
				busy = true
		var facts: String = "Trip %s  ·  brings %s" % [_duration(int(site["duration"])), ", ".join(goods)]
		if not game.has_upgrade(str(site.get("needs", ""))):
			facts = "Needs the %s built first" % str(Catalog.data()["upgrades"][str(site["needs"])]["name"])
		(card.get_node("Body/Facts") as Label).text = facts
		var value := card.get_node("Body/Top/Value") as Label
		if busy:
			value.text = "Crew out"
			value.theme_type_variation = &"LabelAccent"
		elif not workers.is_empty() and game.has_upgrade(str(site.get("needs", ""))):
			var crew: Array[String] = []
			for wid in workers.slice(0, 3):
				crew.append(wid)
			var plan: Dictionary = game.site_forecast(id, crew, "Balanced")
			value.text = ("~ +" if int(plan["profit"]) >= 0 else "~ ") + _money(int(plan["profit"]))
			value.tooltip_text = "Forecast profit for your %d best free %s on Balanced orders." % [crew.size(), Mercs.JOB_NAMES.get(selected_trade, "worker").to_lower() + ("s" if crew.size() != 1 else "")]
			if int(plan["profit"]) < 0:
				value.theme_type_variation = &"LabelAccent"
		else:
			value.text = ""
	(right.get_node(c + "LockedCaption") as Control).visible = locked_list.get_child_count() > 0

func _select_trade(trade: String) -> void:
	selected_trade = trade
	_refresh()

# --- Generic site spread --------------------------------------------------------

func _draw_site() -> void:
	var site: Dictionary = TradeSites.by_id(selected_site)
	if site.is_empty() or site.has("special"):
		selected_site = "mossward_copse"
		site = TradeSites.by_id(selected_site)
	selected_trade = str(site["trade"])
	var left := _mount_page(SITE_LEFT, left_leaf)
	var right := _mount_page(SITE_RIGHT, right_leaf)
	_bind_site_info(right, site)
	_bind_site_crew(left, right, site)

## Right page, top: the site's picture, what it yields, its threat and the trip facts.
func _bind_site_info(right: Control, site: Dictionary) -> void:
	var c := "Margin/Content/"
	var trade: String = str(site["trade"])
	(right.get_node(c + "Site/Art") as TextureRect).texture = load(str(site.get("art", ""))) as Texture2D
	(right.get_node(c + "Site") as Control).tooltip_text = str(site.get("tagline", ""))
	(right.get_node(c + "Site/Badge/Text") as Label).text = "%s %d+" % [TradeSkills.NAMES.get(trade, trade), int(site["level"])]
	var slots := right.get_node(c + "Intel/Yields") as HBoxContainer
	var goods: Dictionary = (site.get("yields", {}) as Dictionary).duplicate()
	goods.merge(site.get("side", {}))
	for good in goods:
		var span: Array = goods[good]
		var slot := ITEM_SLOT.instantiate()
		slots.add_child(slot)
		slot.icon = _item_icon(str(good))
		slot.count = int(span[1])
		slot.tooltip_text = "%s: %d to %d per worker, more with skill and tools.\nMerchants pay %s each today." % [_resource_name(str(good)), int(span[0]), int(span[1]), _money(game.sell_price(str(good)))]
	for key in ["rare", "rare2"]:
		var rare: Dictionary = site.get(key, {})
		if rare.is_empty():
			continue
		var slot := ITEM_SLOT.instantiate()
		slots.add_child(slot)
		slot.icon = _item_icon(str(rare["good"]))
		slot.theme_type_variation = &"GoldPanel"
		slot.tooltip_text = "Rare find: %s, about %.1f%% of trips. Worth %s to a merchant." % [str(rare.get("note", "")), float(rare["chance"]) * 100.0, _money(game.sell_price(str(rare["good"])))]
	var threat: Dictionary = site.get("threat", {})
	var danger: int = int(threat.get("danger", 0))
	var threat_name := right.get_node(c + "Intel/Threat/Name") as Label
	threat_name.text = str(threat.get("name", "None"))
	threat_name.theme_type_variation = &"LabelAccent" if danger > 0 else &"LabelGood"
	threat_name.tooltip_text = str(threat.get("note", ""))
	right.get_node(c + "Intel/Threat/Danger").value = danger
	# Trip facts follow the chosen orders (Long Shift is six times as long, and so on).
	var order: Dictionary = TradeSites.order_for(site, tactic)
	(right.get_node(c + "Facts") as Label).text = "Trip %s  ·  supplies %s  ·  %d xp each" % [
		_duration(int(round(float(site["duration"]) * float(order["duration"])))),
		_money(int(round(float(site.get("supplies", 0)) * float(order.get("cost", 1.0))))),
		int(round(float(site.get("xp", 0)) * float(order["xp"])))]

## The crew's fit for a site, best first: the right tool, then their level in the trade.
func _crew_fit(merc: Dictionary, trade: String) -> int:
	var job: String = Mercs.job(merc)
	var right_tool: bool = job == trade or (trade == "hunting" and Gear.hunts(merc))
	return (100000 if right_tool else 0) + TradeSkills.xp_of(merc, trade) / 10

func _bind_site_crew(left: Control, right: Control, site: Dictionary) -> void:
	var c := "Margin/Content/"
	var site_id: String = str(site["id"])
	var trade: String = str(site["trade"])
	var busy: bool = game.missions.size() >= game.expedition_slots
	var in_field := right.get_node(c + "InField") as Control
	var field_mission: Dictionary = {}
	for mission in game.missions:
		if str(mission.get("site", "")) == site_id or (site_id == "harlow" and str(mission.get("region", "")) == "harlow"):
			field_mission = mission
			in_field.visible = true
			_bind_expedition_row(in_field, mission)
			(in_field.get_node("Row/Info/Top/Name") as Label).text = "Crew at work"
			(in_field.get_node("Row/IconSlot/Icon") as TextureRect).texture = TRADE_ICONS.get(trade)
			break
	var watching: bool = busy and not field_mission.is_empty()
	var ids: Array[String] = _selected_available()
	# Left: the crew picker.
	var job_name: String = str(Mercs.JOB_NAMES.get(trade, "Worker"))
	(left.get_node(c + "Filter/Trade") as Button).text = job_name + "s"
	for pair in [["Trade", "trade"], ["Guards", "guards"], ["All", "all"]]:
		var tab := left.get_node(c + "Filter/" + str(pair[0])) as Button
		tab.set_pressed_no_signal(crew_filter == str(pair[1]))
		tab.pressed.connect(_set_crew_filter.bind(str(pair[1])))
	(left.get_node(c + "Footer/Back") as Button).text = "<  All %s sites" % str(TradeSkills.NAMES.get(trade, trade)).to_lower()
	(left.get_node(c + "Footer/Back") as Button).pressed.connect(_turn_to.bind("expeditions"))
	var free: Array = game.available_guild_workers()
	var shown: Array = []
	for merc in free:
		var id: String = str(merc["id"])
		var job: String = Mercs.job(merc)
		var right_tool: bool = job == trade or (trade == "hunting" and Gear.hunts(merc))
		var keep: bool = ids.has(id)
		match crew_filter:
			"trade": keep = keep or right_tool
			"guards": keep = keep or (job == "combat" and not right_tool)
			_: keep = true
		if keep:
			shown.append(merc)
	shown.sort_custom(func(a, b):
		var aa: bool = ids.has(str(a["id"]))
		var bb: bool = ids.has(str(b["id"]))
		if aa != bb:
			return aa
		if crew_filter == "guards":
			return Mercs.guard_level(a) > Mercs.guard_level(b)
		return _crew_fit(a, trade) > _crew_fit(b, trade))
	var list := left.get_node(c + "Roster/Items") as VBoxContainer
	if watching:
		shown.clear()
		for id in field_mission.get("ids", []):
			var merc: Dictionary = game.merc_by_id(str(id))
			if not merc.is_empty():
				shown.append(merc)
	for merc in shown:
		var id: String = str(merc["id"])
		var role: String = Mercs.role_of(merc)
		var assigned: bool = ids.has(id)
		var health: int = int(merc.get("health", 100))
		var card := ROW_ROSTER_CARD.instantiate() as Button
		list.add_child(card)
		card.toggle_mode = true
		card.button_pressed = assigned
		(card.get_node("Body/RoleIcon") as TextureRect).texture = ROLE_ICONS.get(role, ROLE_ICONS["Miner"])
		(card.get_node("Body/Info/Name") as Label).text = str(merc.get("name", "?"))
		var job: String = Mercs.job(merc)
		var right_tool: bool = job == trade or (trade == "hunting" and Gear.hunts(merc))
		var tool_name: String = str(Gear.in_slot(merc, "main_hand").get("name", ""))
		if tool_name.is_empty():
			tool_name = str(Catalog.item(str(Gear.in_slot(merc, "main_hand").get("key", ""))).get("name", "no tool"))
		var how: String = tool_name.to_lower() if right_tool else ("on guard" if job == "combat" else "half pace")
		(card.get_node("Body/Info/Details") as Label).text = "%s %d  ·  %s" % [TradeSkills.NAMES.get(trade, trade), TradeSkills.level_of(merc, trade), how]
		card.tooltip_text = "%s\nTraits: %s\n%s" % [Mercs.title(merc), Mercs.trait_names(merc),
			"Has the right tool." if right_tool else ("Guards the crew and works at half pace." if job == "combat" else "Works at half pace without the right tool.")]
		(card.get_node("Body/Health/HealthText") as Label).text = "%d%%" % health
		var hp := card.get_node("Body/Health/HealthBar") as ProgressBar
		hp.value = health
		hp.theme_type_variation = &"GreenBar" if health >= 60 else (&"GoldBar" if health >= 25 else &"")
		var tag := card.get_node("Body/Tag") as Label
		if watching:
			tag.text = "At work"
			card.disabled = true
			continue
		if assigned:
			tag.text = "In crew"
		elif health < 25:
			tag.text = "Too hurt"
			card.disabled = true
			card.tooltip_text = "Resting: fit to work in %s, or treat them in Mercenaries." % _duration(int(ceil(float(25 - health) * 3600.0 / (float(MoneyMercsState.REST_PER_HOUR) * Mercs.rest_mult(merc)))))
		elif ids.size() >= 3:
			tag.text = "Crew full"
			card.disabled = true
		else:
			tag.text = "+ Add"
		card.pressed.connect(_toggle_crew.bind(not assigned, id))
	var no_crew := left.get_node(c + "NoCrew") as Control
	no_crew.visible = list.get_child_count() == 0
	if free.is_empty():
		no_crew.text = "No mercenaries are free. Hire one in Mercenaries."
	elif no_crew.visible:
		no_crew.text = "No free %ss. Try Everyone." % job_name.to_lower() if crew_filter == "trade" else "Nobody free to guard. Try Everyone."
	var hire := left.get_node(c + "Hire") as Button
	hire.visible = free.is_empty() and not watching
	hire.pressed.connect(_open_recruitment)
	(left.get_node(c + "Caption") as Control).visible = not watching
	# Right: who's going, orders, forecast and the fund button.
	var names: Array[String] = []
	var best: int = 0
	for id in (field_mission.get("ids", []) if watching else ids):
		var merc: Dictionary = game.merc_by_id(str(id))
		names.append(str(merc.get("name", "?")))
		best = maxi(best, TradeSkills.level_of(merc, trade))
	var needed: int = int(site["level"])
	var crew_label := right.get_node(c + "Crew") as Label
	if names.is_empty():
		crew_label.text = "No crew chosen yet. Needs %s %d." % [TradeSkills.NAMES.get(trade, trade), needed]
		crew_label.theme_type_variation = &"LabelMuted"
	else:
		crew_label.text = "%s: %s" % ["At work" if watching else "Crew %d of 3" % names.size(), ", ".join(names)]
		crew_label.theme_type_variation = &"LabelGood" if best >= needed else &"LabelAccent"
		if best < needed and not watching:
			crew_label.text += "  ·  needs %s %d" % [TradeSkills.NAMES.get(trade, trade), needed]
	var orders: String = str(field_mission.get("tactic", tactic)) if watching else tactic
	for pair in [["Orders/Cautious", "Cautious"], ["Orders/Balanced", "Balanced"], ["Orders/DeepPush", "Deep Push"], ["Away/LongShift", "Long Shift"], ["Away/Overnight", "Overnight"], ["Away/FullDay", "Full Day"]]:
		var btn := right.get_node(c + str(pair[0])) as Button
		btn.set_pressed_no_signal(orders == str(pair[1]))
		if watching:
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			btn.pressed.connect(_set_tactic.bind(str(pair[1])))
	var forecast_ids: Array[String] = []
	for id in (field_mission.get("ids", []) if watching else ids):
		forecast_ids.append(str(id))
	var forecast: Dictionary = game.site_forecast(site_id, forecast_ids, orders)
	var units: Dictionary = forecast["units"]
	var main_good: String = str((site.get("yields", {}) as Dictionary).keys()[0])
	var haul: float = float(units.get(main_good, 0.0)) * (1.0 - float(forecast["share"]))
	var empty: bool = forecast_ids.is_empty()
	right.get_node(c + "Forecast/Haul").value = "%d %s" % [int(round(haul)), _resource_name(main_good).to_lower().get_slice(" ", 0)] if not empty else "-"
	var profit_tile := right.get_node(c + "Forecast/Profit")
	var profit: int = int(forecast["profit"])
	profit_tile.value = ("+" if profit >= 0 else "") + _money(profit) if not empty else "-"
	profit_tile.tone = "good" if profit > 0 and not empty else ("accent" if not empty else "normal")
	profit_tile.tooltip_text = "Haul worth about %s at today's merchant price, minus %s in wages and supplies." % [_money(int(forecast["value"])), _money(int(forecast["cost"]))]
	var risk_tile := right.get_node(c + "Forecast/Risk")
	var injury: float = float(forecast["injury"]) * 100.0
	var death: float = float(forecast["death"]) * 100.0
	risk_tile.value = "%d%% hurt" % int(round(injury)) if death <= 0.0 else "%.1f%% die" % death
	risk_tile.tone = "accent" if death > 0.0 else "normal"
	risk_tile.tooltip_text = "Per worker: %.0f%% chance of injury, %.1f%% chance of death." % [injury, death]
	# Fund button.
	var fund := right.get_node(c + "Fund") as Button
	var reason := right.get_node(c + "Reason") as Label
	var why: String = ""
	var needs: String = str(site.get("needs", ""))
	if not game.has_upgrade(needs):
		# The site opens once its building stands: the button builds it instead.
		var building: Dictionary = Catalog.data()["upgrades"][needs]
		var spend: int = game.upgrade_gold(needs)
		var parts: Array[String] = []
		for part in building["cost"]:
			parts.append("%d %s" % [int(building["cost"][part]), _resource_name(str(part))])
		fund.text = "Build %s  ·  %s" % [str(building["name"]), _money(spend) if spend > 0 else "from stores"]
		fund.tooltip_text = "%s\nCosts %s. Goods come from the warehouse; anything missing is bought from the merchants." % [str(building["effect"]), ", ".join(parts)]
		for part in building["cost"]:
			if int(game.resources.get(str(part), 0)) < int(building["cost"][part]) and not game.merchants_sell(str(part)):
				why = "Bring home %s first: merchants don't sell it." % _resource_name(str(part))
		if why.is_empty() and game.gold < spend:
			why = "Building needs %s for the missing materials." % _money(spend)
		fund.disabled = not why.is_empty()
		fund.pressed.connect(func() -> void: _action(game.build_upgrade(needs)))
		reason.text = why if not why.is_empty() else "%s must be built before any crew can work here." % str(building["name"])
		reason.visible = true
		return
	if busy:
		why = "All expedition slots are busy. Wait for a crew to return."
	elif ids.is_empty() and free.is_empty():
		why = "Hire a mercenary in Mercenaries to start."
	elif ids.is_empty():
		why = "Choose a crew from the list on the left."
	elif not bool(forecast["meets_level"]):
		why = "Needs a mercenary with %s level %d." % [TradeSkills.NAMES.get(trade, trade), needed]
	elif game.gold < int(forecast["cost"]):
		why = "Not enough gold: wages and supplies cost %s." % _money(int(forecast["cost"]))
	fund.text = "Expedition underway" if busy else "Fund expedition  ·  " + _money(int(forecast["cost"]))
	fund.disabled = not why.is_empty()
	fund.pressed.connect(_dispatch_site)
	reason.text = why
	reason.visible = not why.is_empty()

func _set_crew_filter(filter: String) -> void:
	crew_filter = filter
	_refresh()

func _dispatch_site() -> void:
	var result: String = game.site_dispatch(selected_site, _selected_available(), tactic)
	if result.begins_with("The crew set out"):
		selected_crew.clear()
		harlow_view.selected.clear()
	_action(result)
