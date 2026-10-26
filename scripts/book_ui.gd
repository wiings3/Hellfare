extends "res://scripts/book_shell.gd"
## Active book screens: page content and interactions only.
## Every page layout is an editor scene under scenes/journal/pages/; this script
## only binds live game data, connects buttons and instances repeating rows.

const COMPANY_RIGHT := preload("res://scenes/journal/pages/company_right.tscn")
const COMPANY_MAP := preload("res://scenes/journal/pages/company_map.tscn")
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
const WORKSHOP_STORE_LEFT := preload("res://scenes/journal/pages/workshop_store_left.tscn")
const WORKSHOP_STORE_RIGHT := preload("res://scenes/journal/pages/workshop_store_right.tscn")
const WORKSHOP_SHOP_LEFT := preload("res://scenes/journal/pages/workshop_shop_left.tscn")
const WORKSHOP_SHOP_RIGHT := preload("res://scenes/journal/pages/workshop_shop_right.tscn")
const WORKSHOP_TABS := preload("res://scenes/journal/pages/workshop_tabs.tscn")
const WAREHOUSE_LEFT := preload("res://scenes/journal/pages/warehouse_left.tscn")
const WAREHOUSE_RIGHT := preload("res://scenes/journal/pages/warehouse_right.tscn")
const LEDGER_TABS := preload("res://scenes/journal/pages/ledger_tabs.tscn")
const PERSONNEL_WORKSHOP_LEFT := preload("res://scenes/journal/pages/personnel_workshop_left.tscn")
const PERSONNEL_WORKSHOP_RIGHT := preload("res://scenes/journal/pages/personnel_workshop_right.tscn")
const ROW_GEAR_SLOT := preload("res://scenes/journal/rows/gear_slot.tscn")
const ROW_MATERIAL := preload("res://scenes/journal/rows/material_row.tscn")
const ROW_CREW_SLOT := preload("res://scenes/journal/rows/crew_slot.tscn")
const ROW_ROSTER_CARD := preload("res://scenes/journal/rows/roster_card.tscn")
const ROW_MARKET := preload("res://scenes/journal/rows/market_row.tscn")
const ROW_SITE := preload("res://scenes/journal/rows/site_card.tscn")
const ROW_LOCKED := preload("res://scenes/journal/rows/locked_row.tscn")
const ROW_EXPEDITION := preload("res://scenes/journal/rows/expedition_row.tscn")
const ROW_EMPTY_EXPEDITION := preload("res://scenes/journal/rows/empty_expedition.tscn")
const ROW_NEED := preload("res://scenes/journal/rows/need_row.tscn")
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
	"hq": "The Guild",
	"harlow": "The Gatepit",
	"expeditions": "Expeditions",
	"site": "Expedition",
	"dungeon": "Crypt",
	"roster": "Mercenaries",
	"workshop": "Workshop",
	"guildwork": "Warden Work",
	"market": "The Market",
	"hall": "The Gatehouse Tavern",
	"auction": "The Auction House",
	"finance": "The Ledger",
	"ledger": "The Ledger",
	"warehouse": "The Ledger",
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
	title_label.text = str(PAGE_TITLES.get(page, "The Guild"))
	_set_ambience()
	if page == "harlow":
		page = "site"
		selected_site = "harlow"
	if page == "standing":
		page = "hq"  # The Standing tab is retired: worth and the warehouse live in the Treasury.
	if page == "contracts":
		page = "expeditions"  # Regional contracts are retired; old links open the board.
		title_label.text = str(PAGE_TITLES["expeditions"])
	if page == "site":
		title_label.text = str(TradeSites.by_id(selected_site).get("name", "Expedition"))
	if page == "dungeon":
		title_label.text = str(Dungeons.by_id(selected_dungeon).get("name", "Crypt"))
	if page != "workshop":
		workshop_focus = ""  # The lookup card's narrowing lasts only while you're in the Workshop.
	match page:
		"hq": _draw_company()
		"harlow": _draw_site()  # Old links to the retired Harlow page open its planner.
		"expeditions": _draw_board()
		"site": _draw_site()
		"dungeon": _draw_dungeon()
		"roster": _draw_people()
		"workshop": _draw_workshop_chapter()
		"guildwork": _draw_guild_jobs()
		"market": _draw_exchange()
		"auction": _draw_auction()
		"hall": _draw_hall()
		"finance": _draw_ledger()
		"ledger": _draw_ledger()
		"warehouse": _draw_ledger()
		_: _draw_company()

## Gold at the last header update: a change right after a click jingles.
var _heard_gold: int = -1

func _update_header() -> void:
	if _heard_gold >= 0 and game.gold != _heard_gold and Sound.pressed_within(1500) and not Sound.alerted_within(1500):
		var delta: int = game.gold - _heard_gold
		Sound.play("coin_spend" if delta < 0 else ("coin_big" if delta >= 1000 else "coin_earn"))
	_heard_gold = game.gold
	money_label.text = _money(game.gold)
	worth_label.text = "Worth  " + _money(game.wealth())
	missions_label.text = "%d / %d" % [game.missions.size(), game.expedition_slots]

func _live_tick() -> void:
	_update_header()
	_update_event_card()
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

## The hall's hearth always; the Maw under it, louder while a crew is in a crypt; the crypt's
## own drips and wind on a run's page.
func _set_ambience() -> void:
	var below: bool = false
	var on_run: bool = false
	for m in game.missions:
		if str(m.get("region", "")) == "dungeon":
			below = true
			on_run = on_run or (page == "dungeon" and str(m.get("dungeon", "")) == selected_dungeon)
	var levels: Dictionary = {"amb_hall": 0.5 if on_run else 1.0, "amb_maw": 1.0 if below else 0.6}
	if on_run:
		levels["amb_below"] = 1.0
	Sound.ambience(levels)

func _resource_name(key: String) -> String:
	return str(MoneyMercsState.RESOURCE_NAMES.get(key, key.capitalize()))

func _mission_name(mission: Dictionary) -> String:
	var region: String = str(mission.get("region", ""))
	match region:
		"harlow": return "The Gatepit"
		"site": return str(TradeSites.by_id(str(mission.get("site", ""))).get("name", "Expedition"))
		"dungeon": return str(Dungeons.by_id(str(mission.get("dungeon", ""))).get("name", "Crypt"))
		"guild_work": return "Warden work"
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
	if str(mission.get("region", "")) == "dungeon":
		var stage: String = str(mission.get("stage", ""))
		detail += "  ·  " + ("waiting for orders" if stage == "await" else ("walking out" if stage == "out" else "floor %d" % (int(mission.get("floor_i", 0)) + 1)))
	elif mission.has("tactic"):
		detail += "  ·  " + str(mission["tactic"])
	(row.get_node("Row/Info/Crew") as Label).text = detail
	var trade: String = str(mission.get("trade", "mining" if str(mission.get("region", "")) == "harlow" else ""))
	(row.get_node("Row/IconSlot/Icon") as TextureRect).texture = ICON_GUILD if str(mission.get("region", "")) == "guild_work" else TRADE_ICONS.get("dungeon" if str(mission.get("region", "")) == "dungeon" else trade, ICON_FIELD)
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
	_draw_region_map()
	_bind_today(_mount_page(COMPANY_RIGHT, right_leaf))

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
				text += "\n%s is carrying a %s found on the dead." % [who, str(game.item_definition(str(find.get("key", ""))).get("name", "find"))]
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
		btn.text = str(site["name"]).trim_prefix("The ") + ("  ·  %s %d" % [TradeSkills.NAMES.get(trade, trade), int(site["level"])] if locked else "")
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
	# Crypts on the map open their planner.
	for crypt in Dungeons.DUNGEONS:
		if not left.has_node(sites + str(crypt)):
			continue
		var d: Dictionary = Dungeons.DUNGEONS[crypt]
		var keep := left.get_node(sites + str(crypt)) as Button
		var below: int = 0
		for mission in game.missions:
			if RegionMap.road_for(mission) == str(crypt):
				below += 1
		keep.tooltip_text = "%s\n%s" % [str(d["name"]), "A crew is inside." if below > 0 else "A crypt: fighters with gear score %d+." % int(d["min_kit"])]
		keep.pressed.connect(_open_dungeon.bind(str(crypt)))
	_bind_fallen(left)
	var town := left.get_node(sites + "town") as Button
	town.tooltip_text = "Last Lantern, home of the guild.\n%d resting above." % game.free_crew()
	town.pressed.connect(_turn_to.bind("warehouse"))
	var status := left.get_node("Margin/Content/Status") as Label
	var update := func() -> void:
		if game.missions.is_empty():
			status.text = "No crews out. Click a site on the map to send one." if game.free_crew() > 0 else "Nobody out."
			return
		var next: int = -1
		var name: String = ""
		for mission in game.missions:
			var left_s: int = int(mission.get("finish", _now())) - _now()
			if next < 0 or left_s < next:
				next = left_s
				name = _mission_name(mission)
		status.text = "%s out  ·  %s back in %s" % [_plural(game.missions.size(), "crew"), name, _duration(maxi(0, next))]
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
	(card.get_node(body + "Title") as Label).text = "Left below at " + site_name
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

## How long a returned crew's report stays on the Company page.
const REPORT_FRESH := 1800

## The Company's right page: crews in the field, then only what needs the player.
func _bind_today(right: Control) -> void:
	var c := "Margin/Content/"
	var list := right.get_node(c + "Expeditions") as VBoxContainer
	for mission in game.missions:
		var row := ROW_EXPEDITION.instantiate() as Control
		list.add_child(row)
		_bind_expedition_row(row, mission)
	var open: int = game.expedition_slots - game.missions.size()
	if open > 0:
		var empty := ROW_EMPTY_EXPEDITION.instantiate() as Control
		list.add_child(empty)
		(empty.get_node("Row/Text/Title") as Label).text = "%s free" % _plural(open, "slot")
		(empty.get_node("Row/Text/Hint") as Label).text = "Nobody is out." if game.missions.is_empty() else "Room for another crew."
		(empty.get_node("Row/Plan") as Button).pressed.connect(_turn_to.bind("expeditions"))
	var needs := right.get_node(c + "Needs") as VBoxContainer
	for need in _needs():
		var row := ROW_NEED.instantiate() as Control
		needs.add_child(row)
		(row.get_node("Row/IconSlot/Icon") as TextureRect).texture = need["icon"]
		(row.get_node("Row/Info/Name") as Label).text = str(need["title"])
		(row.get_node("Row/Info/Details") as Label).text = str(need["details"])
		var value := row.get_node("Row/Value") as Label
		value.visible = need.has("value")
		if need.has("value"):
			value.text = str(need["value"])
			value.theme_type_variation = &"LabelGood" if not str(need["value"]).begins_with("-") else &"LabelAccent"
		var action := row.get_node("Row/Action") as Button
		action.text = str(need["action"])
		action.pressed.connect(need["call"])
		if need.has("disabled"):
			action.disabled = bool(need["disabled"])
			action.tooltip_text = str(need.get("why", ""))
	(right.get_node(c + "AllClear") as Control).visible = needs.get_child_count() == 0
	right.get_node(c + "Tiles/Reputation").value = Mercs.tier_name(game.rep_tier())
	right.get_node(c + "Tiles/Reputation").tooltip_text = "%s reputation. Better applicants join a better-known guild." % _thousands(game.reputation)
	var stocked: int = 0
	for key in MoneyMercsState.RESOURCE_ORDER:
		stocked += int(game.resources.get(str(key), 0))
	var warehouse := right.get_node(c + "Tiles/Warehouse")
	warehouse.value = "Empty" if stocked == 0 else "%s goods" % _thousands(stocked)
	warehouse.tooltip_text = "Worth %s to the merchants today. Click to open the warehouse." % _money(game.goods_value())
	warehouse.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	warehouse.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_turn_to("warehouse"))

## What needs the player now, most pressing first (at most five).
func _needs() -> Array:
	var out: Array = []
	if game.crew.is_empty():
		out.append({"icon": ROLE_ICONS["Woodcutter"], "title": "Hire your first Hellfarer",
			"details": "A woodcutter at Cinderwood pays from the first trip", "action": "Recruit", "call": _open_recruitment})
	# Crews waiting at a crypt's stairs for orders.
	for m in game.dungeon_checkins():
		var dname: String = str(Dungeons.by_id(str(m["dungeon"])).get("name", "The crypt"))
		out.append({"icon": TRADE_ICONS.get("dungeon"), "title": "%s: crew waiting for orders" % dname,
			"details": "Floor %d cleared  ·  carrying %s  ·  orders in %s" % [int(m["floor_i"]) + 1, _money(game.dungeon_carry_value(m.get("carry", {}))), _duration(maxi(0, int(m["await_until"]) - _now()))],
			"action": "Decide", "call": _open_dungeon.bind(str(m["dungeon"]))})
	# Auction House news since it was last looked at.
	var fresh_sold: int = 0
	var fresh_gold: int = 0
	for e in game.auction.log:
		if _now() - int(e["t"]) > REPORT_FRESH or int(e["t"]) <= ah_seen:
			break
		if str(e["kind"]) == "sold":
			fresh_sold += 1
			fresh_gold += int(e["gold"])
	if fresh_sold > 0:
		out.append({"icon": SIGN_COIN, "title": "Auction House: %s sold" % _plural(fresh_sold, "sale"),
			"details": "+%s while you were away" % _money(fresh_gold), "action": "See", "call": func() -> void:
				auction_tab = "yours"
				_turn_to("auction")})
	# Crews just back.
	var now: int = _now()
	for i in range(mini(2, game.reports.size())):
		var report: Dictionary = game.reports[i]
		if now - int(report.get("time", 0)) > REPORT_FRESH:
			break
		var casualties: Array = report.get("casualties", [])
		var profit: int = _report_value(report) - int(report.get("cost", 0))
		var loot: Dictionary = report.get("loot", {})
		var brought: Array[String] = []
		for key in loot:
			brought.append("%d %s" % [int(loot[key]), _resource_name(str(key))])
		var details: String = ", ".join(brought.slice(0, 2)) if not brought.is_empty() else "Nothing brought home"
		details += "  ·  " + ("lost " + ", ".join(casualties) if not casualties.is_empty() else "no losses")
		var index: int = i
		out.append({"icon": TRADE_ICONS.get(str(TradeSites.by_id(str(report.get("site", ""))).get("trade", report.get("trade", ""))), ICON_FIELD), "title": "Back from %s" % str(report.get("region", "the field")),
			"details": details, "value": ("+" if profit >= 0 else "") + _money(profit), "action": "Report",
			"call": func() -> void:
				selected_report_index = index
				_turn_to("ledger")})
	# The hurt.
	var hurt: Array = []
	for merc in game.crew:
		if game.is_available(merc) and int(merc.get("health", 100)) < 60:
			hurt.append(merc)
	if hurt.size() == 1:
		var merc: Dictionary = hurt[0]
		var cost: int = MoneyMercsState.treat_cost(merc)
		out.append({"icon": _item_icon("healing_draught"), "title": "%s is hurt" % str(merc["name"]),
			"details": "%d%% health  ·  rested in %s" % [int(merc.get("health", 100)), _duration(MoneyMercsState.rest_eta(merc))],
			"action": "Treat %s" % _money(cost), "call": _heal.bind(str(merc["id"])), "disabled": game.gold < cost, "why": "Not enough gold."})
	elif hurt.size() > 1:
		out.append({"icon": _item_icon("healing_draught"), "title": "%d Hellfarers are hurt" % hurt.size(),
			"details": "They rest back to health for free, or a healer treats them now", "action": "Roster", "call": _turn_to.bind("roster")})
	# Gear about to wear out (a quarter left or less).
	var worn: Array = []
	for item in game.needs_repair():
		var most: int = Gear.max_durability(item)
		if most > 0 and Gear.durability(item) * 4 <= most:
			worn.append(item)
	if worn.size() == 1:
		var item: Dictionary = worn[0]
		var cost: int = game.repair_gold(game.repair_cost(item))
		out.append({"icon": _gear_icon(str(item["key"])), "title": "%s is nearly worn out" % str(Catalog.item(str(item["key"])).get("name", "Gear")),
			"details": "%d / %d  ·  works at half pace once broken" % [Gear.durability(item), Gear.max_durability(item)],
			"action": "Repair %s" % _money(cost) if cost > 0 else "Repair", "call": func() -> void: _act(func() -> String: return game.repair(str(item["uid"])), "repair"), "disabled": game.gold < cost, "why": "Not enough gold."})
	elif worn.size() > 1:
		out.append({"icon": _gear_icon(str(worn[0]["key"])), "title": "%d pieces of gear nearly worn out" % worn.size(),
			"details": "Broken gear works at half pace", "action": "Armory", "call": _outfit.bind(selected_merc)})
	# Idle hands with room to send them.
	var idle: int = 0
	for merc in game.crew:
		if game.is_available(merc) and int(merc.get("health", 100)) >= 25:
			idle += 1
	if idle > 0 and game.missions.size() < game.expedition_slots:
		out.append({"icon": ROLE_ICONS["Guard"], "title": "%s idle" % _plural(idle, "Hellfarer"),
			"details": "Idle hands draw %s a day, and drink" % _money(game.idle_upkeep_total()), "action": "Send out", "call": _turn_to.bind("expeditions")})
	var next_charter: String = game.next_charter()
	if next_charter != "" and game.charter_block().is_empty():
		var charter: Dictionary = Catalog.data()["upgrades"][next_charter]
		out.append({"icon": ICON_FIELD, "title": "%s is within reach" % str(charter["name"]), "details": str(charter["effect"]),
			"action": "Sign  ·  %s" % _money(game.upgrade_gold(next_charter)), "call": func() -> void: _act(func() -> String: return game.build_upgrade(next_charter), "sign_charter")})
	if game.can_accept_guild_work():
		out.append({"icon": ICON_GUILD, "title": "The Wardens offer safe work", "details": "Small, risk-free jobs for guilds on hard times",
			"action": "Warden work", "call": _turn_to.bind("guildwork")})
	return out.slice(0, 5)

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
	"head": "helmet", "hands": "gloves", "feet": "boots",
	"light/head": "cap_leather", "light/hands": "gloves_leather", "light/feet": "boots_leather", "light/body": "armor_leather", "medium/body": "armor_iron", "heavy/body": "armor_iron",
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
		return ["Out", &"LabelAccent"]
	if int(merc.get("health", 100)) < 25:
		return ["Resting, too hurt to work", &"LabelAccent"]
	if int(merc.get("health", 100)) < 100:
		return ["Resting  ·  full in " + _duration(MoneyMercsState.rest_eta(merc)), &"LabelAccent"]
	return ["Ready", &"LabelGood"]

func _set_bust(rect: TextureRect, role: String) -> void:
	rect.texture = BUSTS.get(role, BUSTS["Scout"])

# --- Item lookup ----------------------------------------------------------------
# Click any item icon in the book: what it is, where it comes from and what it's for.

func _lookup_card() -> Control:
	return stage.get_node_or_null("ItemLookup") as Control if is_instance_valid(stage) else null

## Make an icon open the lookup card for an item or good when clicked.
func _lookup_on(node: Control, key: String) -> void:
	if node == null or key.is_empty():
		return
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.tooltip_text = (node.tooltip_text + "\n" if not node.tooltip_text.is_empty() else "") + "Click for details"
	node.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			_open_lookup(key))

## Where an item or good comes from, in words.
func _sources_text(key: String) -> String:
	var parts: Array[String] = []
	for site in TradeSites.SITES:
		for part in ["yields", "side"]:
			var y: Dictionary = site.get(part, {})
			if y.has(key):
				parts.append("%s (%d–%d)" % [str(site["name"]), int(y[key][0]), int(y[key][1])])
		for r in ["rare", "rare2"]:
			if str((site.get(r, {}) as Dictionary).get("good", "")) == key:
				parts.append("%s (rare)" % str(site["name"]))
	for id in Dungeons.DUNGEONS:
		var dg: Dictionary = Dungeons.DUNGEONS[id]
		for fl in dg["floors"]:
			if (fl.get("loot", {}) as Dictionary).has(key) or str((fl.get("rare", {}) as Dictionary).get("good", "")) == key:
				parts.append("%s, %s" % [str(dg["name"]), str(fl["name"])])
	var d: Dictionary = Catalog.item(key)
	if d.get("recipe") is Dictionary and not (d["recipe"] as Dictionary).is_empty():
		parts.append("crafted from " + _cost_line(d["recipe"]))
	if MercsV05.shop_keys().has(key):
		parts.append("the quartermaster's shop")
	if bool(d.get("found_only", false)):
		parts.append("found on the dead below and in the crypts")
	if parts.is_empty() and not Catalog.material(key).is_empty():
		parts.append_array(_source_names(key))
	return ", ".join(parts) if not parts.is_empty() else "Nowhere you can reach yet."

## What an item or good is used for, in words.
func _uses_text(key: String) -> String:
	var parts: Array[String] = []
	var d: Dictionary = Catalog.item(key)
	if Gear.consumable(key):
		parts.append(Gear.summary(key).get_slice("·", 1).strip_edges() + " (packed in the %s slot)" % Gear.slot_of(key))
	elif Gear.equippable(key):
		parts.append("worn in the %s slot: %s" % [str(Gear.SLOT_NAMES.get(Gear.slot_of(key), "")).to_lower(), Gear.summary(key)])
	var recipes: Array[String] = []
	for item_key in Catalog.items():
		var recipe: Variant = Catalog.item(str(item_key)).get("recipe", {})
		if recipe is Dictionary and (recipe as Dictionary).has(key):
			recipes.append(str(Catalog.item(str(item_key))["name"]))
	if not recipes.is_empty():
		recipes.sort()
		var more: int = recipes.size() - 8
		parts.append("crafting " + ", ".join(recipes.slice(0, 8)) + (" and %d more" % more if more > 0 else ""))
	for id in Catalog.data().get("upgrades", {}):
		if (Catalog.data()["upgrades"][id]["cost"] as Dictionary).has(key):
			parts.append("building the " + str(Catalog.data()["upgrades"][id]["name"]))
	if parts.is_empty():
		parts.append("selling: merchants and traders buy it")
	return "; ".join(parts) + "."

func _open_lookup(key: String) -> void:
	var card := _lookup_card()
	if card == null:
		return
	var b := "Card/Margin/Body/"
	var good: bool = MoneyMercsState.RESOURCE_ORDER.has(key)
	var d: Dictionary = Catalog.item(key)
	(card.get_node(b + "Head/Slot")).icon = _item_icon(key) if good else _gear_icon(key)
	(card.get_node(b + "Head/Id/Name") as Label).text = _resource_name(key) if good else str(d.get("name", key))
	var kind: String
	if good:
		kind = {"raw": "Raw good", "crafted": "Crafted good", "food": "Food"}.get(str(MoneyMercsState.RESOURCE_KIND.get(key, "raw")), "Good")
	else:
		kind = "Tier %d  ·  %s" % [int(d.get("tier", 1)), str(Gear.SLOT_NAMES.get(Gear.slot_of(key), "item"))]
	(card.get_node(b + "Head/Id/Kind") as Label).text = kind
	(card.get_node(b + "Desc") as Label).text = str(MoneyMercsState.RESOURCE_DESC.get(key, d.get("note", "")))
	var held: int = int(game.resources.get(key, 0))
	if not good:
		held = 0
		for item in game.equipment_inventory:
			held += 1 if str(item.get("key", "")) == key else 0
		for merc in game.crew:
			for item in Gear.worn(merc):
				held += 1 if str(item.get("key", "")) == key else 0
	(card.get_node(b + "Rows/Held") as Label).text = str(held) if held > 0 else "None"
	(card.get_node(b + "Rows/Pays") as Label).text = _money(game.sell_price(key)) if good else "~" + _money(int(Catalog.value_of(key) * 0.65))
	var sells: String = "Not sold"
	if good and game.merchants_sell(key):
		sells = _money(game.buy_price(key))
	elif MercsV05.shop_keys().has(key):
		sells = _money(int(game.item_definition(key).get("cost", 0)))
	(card.get_node(b + "Rows/Sells") as Label).text = sells
	var from: String = _sources_text(key)
	(card.get_node(b + "From") as Label).text = from.left(1).to_upper() + from.substr(1)
	var uses: String = _uses_text(key)
	(card.get_node(b + "Uses") as Label).text = uses.left(1).to_upper() + uses.substr(1)
	var trade := card.get_node(b + "Actions/Trade") as Button
	trade.visible = good
	_reconnect(trade, func() -> void:
		_close_lookup()
		_open_market(key))
	# Recipe(s): straight to what the card was talking about.
	var craft := card.get_node(b + "Actions/Craft") as Button
	var makes: bool = d.get("recipe") is Dictionary and not (d["recipe"] as Dictionary).is_empty()
	var users: Array = []
	for item_key in Catalog.items():
		var recipe: Variant = Catalog.item(str(item_key)).get("recipe", {})
		if recipe is Dictionary and (recipe as Dictionary).has(key):
			users.append(str(item_key))
	var for_sale: Array = game.blueprint_shop()
	var target_tab: String = ""
	var focus: String = ""
	if makes:
		focus = "item:" + key
		if game.knows(key):
			target_tab = "craft"
			focus = ""
		elif for_sale.has(key):
			target_tab = "shop"
		craft.text = "Recipe  >"
	elif not users.is_empty():
		focus = "uses:" + key
		if users.any(func(k): return game.knows(str(k))):
			target_tab = "craft"
		elif users.any(func(k): return for_sale.has(str(k))):
			target_tab = "shop"
		craft.text = "Recipes  >"
	craft.visible = target_tab != ""
	craft.tooltip_text = "Open the Workshop's %s at %s." % ["Craft tab" if target_tab == "craft" else "Shop", _focus_text_for(focus) if focus != "" else "this recipe"]
	_reconnect(craft, func() -> void:
		_close_lookup()
		workshop_focus = focus
		workshop_tab = target_tab
		if makes and game.knows(key):
			selected_recipe = key
		if page == "workshop":
			_refresh()
		else:
			_turn_to("workshop"))
	_reconnect(card.get_node(b + "Head/Close") as Button, _close_lookup)
	var dim := card.get_node("Dim") as Control
	if not dim.gui_input.is_connected(_on_lookup_dim):
		dim.gui_input.connect(_on_lookup_dim)
	card.visible = true

func _on_lookup_dim(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		_close_lookup()

func _close_lookup() -> void:
	var card := _lookup_card()
	if card != null:
		card.visible = false

## Replace a button's pressed handlers (the lookup card is reused).
func _reconnect(button: Button, action: Callable) -> void:
	for conn in button.pressed.get_connections():
		button.pressed.disconnect(conn["callable"])
	button.pressed.connect(action)

# --- Personnel ----------------------------------------------------------------

func _draw_people() -> void:
	match roster_tab:
		"recruits": _draw_recruitment()
		_: _draw_employees()
	var tabs := _mount_page(PERSONNEL_TABS, left_leaf)
	for tab in [["EmployeesTab", "employed"], ["RecruitmentTab", "recruits"]]:
		var btn := tabs.get_node("Tabs/" + str(tab[0])) as Button
		btn.set_pressed_no_signal(roster_tab == str(tab[1]) or (str(tab[1]) == "employed" and roster_tab != "recruits"))
		btn.pressed.connect(_set_roster_tab.bind(str(tab[1])))
	(tabs.get_node("Tabs/EmployeesTab") as Button).text = "Roster  ·  %d" % game.crew.size()
	(tabs.get_node("Tabs/RecruitmentTab") as Button).text = "Recruit  ·  %d" % game.recruitment_board().size()

func _focus_person(id: String) -> void:
	selected_merc = id
	_refresh()

## Does this mercenary pass the roster filter (all, ready, out, hurt)?
func _roster_shows(merc: Dictionary) -> bool:
	match roster_filter:
		"ready": return game.is_available(merc) and int(merc.get("health", 100)) >= 60
		"out": return not game.is_available(merc)
		"hurt": return int(merc.get("health", 100)) < 60
	return true

func _draw_employees() -> void:
	var left := _mount_page(PERSONNEL_EMPLOYEES_LEFT, left_leaf)
	var right := _mount_page(PERSONNEL_EMPLOYEES_RIGHT, right_leaf)
	var c := "Margin/Content/"
	if (selected_merc.is_empty() or game.merc_by_id(selected_merc).is_empty()) and not game.crew.is_empty():
		selected_merc = str(game.crew[0]["id"])
	for pair in [["All", "all"], ["Ready", "ready"], ["Out", "out"], ["Hurt", "hurt"]]:
		var tab := left.get_node(c + "Filter/" + str(pair[0])) as Button
		tab.set_pressed_no_signal(roster_filter == str(pair[1]))
		tab.pressed.connect(func() -> void:
			roster_filter = str(pair[1])
			_refresh())
	var list := left.get_node(c + "List/Items") as VBoxContainer
	var payroll: int = 0
	for merc in game.crew:
		payroll += int(game.terms(merc)["wage"])
		if not _roster_shows(merc):
			continue
		var id: String = str(merc["id"])
		var role: String = Mercs.role_of(merc)
		var health: int = int(merc.get("health", 100))
		var state: String = "Ready"
		var tone: StringName = &"LabelGood"
		if not game.is_available(merc):
			var back: int = 0
			for mission in game.missions:
				if (mission.get("ids", []) as Array).has(id):
					back = maxi(0, int(mission.get("finish", _now())) - _now())
			state = "Out  ·  %s" % _duration(back)
			tone = &"LabelMuted"
		elif health < 60:
			state = "Hurt  ·  %d%%" % health
			tone = &"LabelAccent"
		var card := _list_card(list, ROLE_ICONS.get(role, ROLE_ICONS["Miner"]), str(merc["name"]), Mercs.title(merc), "", state,
			id == selected_merc, _focus_person.bind(id))
		(card.get_node("Body/Side/Value/Text") as Label).theme_type_variation = tone
		card.tooltip_text = "Traits: %s\nHealth %d%%" % [Mercs.trait_names(merc), health]
	var empty: bool = game.crew.is_empty()
	(left.get_node(c + "Summary/Count") as Label).text = "%d hired  ·  %d ready" % [game.crew.size(), game.free_crew()]
	var payroll_label := left.get_node(c + "Summary/Payroll") as Label
	payroll_label.text = "Payroll %s  ·  idle %s/day" % [_money(payroll), _money(game.idle_upkeep_total())]
	payroll_label.tooltip_text = "Payroll: what one trip with every Hellfarer would cost in wages.\nIdle: Hellfarers above still draw half their wage each day."
	(left.get_node(c + "List") as Control).visible = not empty
	(left.get_node(c + "Filter") as Control).visible = not empty
	(left.get_node(c + "Empty") as Control).visible = empty
	var recruit := left.get_node(c + "Recruit") as Button
	recruit.visible = empty
	recruit.pressed.connect(_set_roster_tab.bind("recruits"))
	# Dossier.
	var merc: Dictionary = game.merc_by_id(selected_merc)
	var none: bool = merc.is_empty()
	for child in (right.get_node("Margin/Content") as Control).get_children():
		(child as CanvasItem).visible = child.name == "Empty" if none else child.name != "Empty"
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
	var state_label := right.get_node(c + "Head/Id/Status/State") as Label
	state_label.text = "·  " + str(status[0])
	state_label.theme_type_variation = status[1]
	for pair in [["Overview", "overview"], ["Gear", "gear"]]:
		var tab := right.get_node(c + "View/" + str(pair[0])) as Button
		tab.set_pressed_no_signal(dossier_view == str(pair[1]))
		tab.pressed.connect(func() -> void:
			dossier_view = str(pair[1])
			_refresh())
	(right.get_node(c + "Overview") as Control).visible = dossier_view != "gear"
	(right.get_node(c + "Gear") as Control).visible = dossier_view == "gear"
	if dossier_view == "gear":
		_bind_gear_view(right, merc)
	else:
		_bind_overview(right, merc)

func _bind_overview(right: Control, merc: Dictionary) -> void:
	var o := "Margin/Content/Overview/"
	var terms: Dictionary = game.terms(merc)
	right.get_node(o + "Stats/Skill").value = _money(Mercs.value(merc))
	var wage_tile := right.get_node(o + "Stats/Wage")
	wage_tile.value = _money(int(terms["wage"]))
	wage_tile.tooltip_text = "Paid for each trip. Above, they draw half of it each day (%s/day)." % _money(int(round(game.idle_upkeep(merc))))
	right.get_node(o + "Stats/Share").value = "%d%%" % int(round(float(terms["cut"]) * 100.0))
	right.get_node(o + "Stats/Kit").value = str(Gear.kit_rating(merc))
	var health: int = int(merc.get("health", 100))
	var bar := right.get_node(o + "Health/Bar") as ProgressBar
	bar.value = health
	bar.theme_type_variation = &"GreenBar" if health >= 60 else (&"GoldBar" if health >= 25 else &"")
	(right.get_node(o + "Health/Value") as Label).text = "%d%%" % health
	var heal := right.get_node(o + "Health/Heal") as Button
	heal.visible = health < 100
	if heal.visible:
		var cost: int = MoneyMercsState.treat_cost(merc)
		heal.text = "Treat  ·  %d G" % cost
		heal.disabled = game.gold < cost or not game.is_available(merc)
		heal.tooltip_text = "Resting above heals %d health an hour for free: back to full in %s.\nTreat now to send them down sooner." % [MoneyMercsState.REST_PER_HOUR, _duration(MoneyMercsState.rest_eta(merc))]
		heal.pressed.connect(_heal.bind(selected_merc))
	for trade in SKILL_ORDER:
		var base := o + "Skills/" + str(TradeSkills.NAMES[trade]) + "/"
		(right.get_node(base + "Top/Level") as Label).text = str(TradeSkills.level_of(merc, trade))
		(right.get_node(base + "Bar") as ProgressBar).value = TradeSkills.progress(merc, trade) * 100.0
		if Mercs.job(merc) == trade:
			(right.get_node(base + "Top/Name") as Label).theme_type_variation = &"LabelGood"
	var traits := right.get_node(o + "Traits/List") as Label
	traits.text = Mercs.trait_names(merc) if not (merc.get("traits", []) as Array).is_empty() else "None"
	traits.tooltip_text = Mercs.trait_lines(merc)
	var contract: String = str(merc.get("contract", "Balanced"))
	var contract_name := right.get_node(o + "Contract/Text/Name") as Label
	contract_name.text = contract
	contract_name.tooltip_text = str(CONTRACT_NOTES.get(contract, ""))
	var change := right.get_node(o + "Contract/Change") as Button
	change.disabled = not game.is_available(merc)
	change.pressed.connect(_terms.bind(selected_merc))
	var sell := right.get_node(o + "Contract/Sell") as Button
	var offer: int = game.contract_offer(merc)
	var settling: int = game.settling_left(merc)
	sell.text = ("Confirm  ·  %s" % _money(offer)) if confirm_sell == selected_merc else "Sell contract"
	sell.disabled = not game.is_available(merc) or settling > 0
	sell.tooltip_text = "Settling in: can be sold in %s." % _duration(settling) if settling > 0 else \
		"Another guild buys their contract for %s (half their value), with the gear they wear.\nHellfarers talk: each sale costs a little reputation." % _money(offer)
	sell.pressed.connect(_sell_contract.bind(selected_merc))

## The Gear view: ten slots, the chosen slot's piece, and what in the storeroom fits it.
func _bind_gear_view(right: Control, owner: Dictionary) -> void:
	var g := "Margin/Content/Gear/"
	Gear.ensure(owner)
	var available: bool = game.is_available(owner)
	if not Gear.SLOTS.has(selected_slot):
		selected_slot = "main_hand"
	var grid := right.get_node(g + "Slots") as GridContainer
	for slot in Gear.SLOTS:
		grid.add_child(_gear_slot_button(slot, Gear.in_slot(owner, slot), slot == selected_slot, _choose_slot.bind(slot)))
	var picked: Dictionary = Gear.in_slot(owner, selected_slot)
	var base := g + "Picked/Row/"
	(right.get_node(base + "Info/Name") as Label).text = "%s: %s" % [Gear.SLOT_NAMES[selected_slot], _equipment_name(picked) if not picked.is_empty() else "empty"]
	var detail := right.get_node(base + "Info/Detail") as Label
	if picked.is_empty():
		detail.text = SLOT_HINTS.get(selected_slot, "")
	elif Gear.CONSUMABLE_SLOTS.has(selected_slot):
		detail.text = Gear.summary(str(picked["key"])).get_slice("·", 1).strip_edges()
	else:
		var extra: String = Gear.rolls_text(picked)
		detail.text = ("%d/%d" % [Gear.durability(picked), Gear.max_durability(picked)] if Gear.max_durability(picked) > 0 else "") + ("  ·  " + extra if extra != "" else "")
	detail.tooltip_text = Gear.describe(picked)
	detail.mouse_filter = Control.MOUSE_FILTER_PASS
	var remove := right.get_node(base + "Remove") as Button
	remove.visible = not picked.is_empty()
	remove.disabled = not available
	remove.pressed.connect(_unequip.bind(selected_merc, selected_slot))
	var repair := right.get_node(base + "Repair") as Button
	var cost: Dictionary = {} if picked.is_empty() or Gear.CONSUMABLE_SLOTS.has(selected_slot) else game.repair_cost(picked)
	repair.visible = not cost.is_empty()
	if repair.visible:
		var spend: int = game.repair_gold(cost)
		repair.text = "Repair" + ("  ·  %s" % _money(spend) if spend > 0 else "")
		repair.disabled = not available or game.gold < spend
		repair.tooltip_text = "Uses %s. Anything not in the warehouse is bought from the merchants." % _cost_line(cost)
		repair.pressed.connect(_repair.bind(str(picked["uid"])))
	var bonus := right.get_node(g + "Foot/Bonus") as Label
	var job: String = Gear.job(owner)
	var bits: Array[String] = ["Gear score %d" % Gear.kit_rating(owner), "Armour %d" % int(Gear.armour(owner))]
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
	var all := right.get_node(g + "Foot/RepairAll") as Button
	all.visible = damaged > 1
	all.disabled = not available
	all.pressed.connect(_repair_all.bind(selected_merc))
	# What in the storeroom fits the chosen slot.
	var fits := right.get_node(g + "Fits/Items") as VBoxContainer
	if Gear.CONSUMABLE_SLOTS.has(selected_slot):
		for key in MoneyMercsState.RESOURCE_ORDER:
			if not Gear.consumable(str(key)) or Gear.slot_of(str(key)) != selected_slot or int(game.resources.get(key, 0)) <= 0:
				continue
			var card := ROW_ITEM_CARD.instantiate()
			fits.add_child(card)
			(card.get_node("Row/IconSlot/Icon") as TextureRect).texture = _item_icon(str(key))
			(card.get_node("Row/Info/Name") as Label).text = "%s  ×%d" % [_resource_name(str(key)), int(game.resources[key])]
			(card.get_node("Row/Info/Details") as Label).text = Gear.summary(str(key))
			var pack := card.get_node("Row/Primary") as Button
			pack.text = "Pack"
			pack.disabled = not available
			pack.pressed.connect(_supply.bind(selected_merc, str(key)))
	else:
		for item in game.equipment_inventory:
			var key: String = str(item.get("key", ""))
			var slot_of: String = Gear.slot_of(key)
			if slot_of != selected_slot:
				continue
			var card := ROW_ITEM_CARD.instantiate()
			fits.add_child(card)
			(card.get_node("Row/IconSlot/Icon") as TextureRect).texture = _gear_icon(key)
			(card.get_node("Row/Info/Name") as Label).text = Gear.full_name(item)
			var wear: String = ("  ·  %d/%d" % [Gear.durability(item), Gear.max_durability(item)]) if Gear.max_durability(item) > 0 else ""
			(card.get_node("Row/Info/Details") as Label).text = Gear.summary(key) + wear
			card.tooltip_text = Gear.describe(item) + ("\nGear score +%d" % int(Catalog.item(key).get("kit", 0)) if int(Catalog.item(key).get("kit", 0)) > 0 else "")
			_lookup_on(card.get_node("Row/IconSlot") as Control, key)
			var equip := card.get_node("Row/Primary") as Button
			equip.text = "Equip"
			equip.disabled = not available
			equip.tooltip_text = "Equip on %s. The tool in their hands sets their job." % str(owner.get("name", "")) if available else "They're out."
			equip.pressed.connect(_equip.bind(selected_merc, str(item.get("uid", ""))))
	(right.get_node(g + "Fits") as Control).visible = fits.get_child_count() > 0
	(right.get_node(g + "FitsEmpty") as Control).visible = fits.get_child_count() == 0
	(right.get_node(g + "Workshop") as Button).pressed.connect(func() -> void:
		workshop_tab = "store"
		_turn_to("workshop"))

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

## Does an applicant pass the Recruit filter (all, logging, mining, guards, other)?
func _recruit_shows(candidate: Dictionary) -> bool:
	var best: String = Mercs.best_trade(candidate)
	match recruit_filter:
		"logging", "mining": return best == recruit_filter
		"guards": return best == "combat"
		"other": return not best in ["logging", "mining", "combat"]
	return true

func _draw_recruitment() -> void:
	var left := _mount_page(PERSONNEL_RECRUITS_LEFT, left_leaf)
	var right := _mount_page(PERSONNEL_RECRUITS_RIGHT, right_leaf)
	var c := "Margin/Content/"
	for name in ["All", "Logging", "Mining", "Guards", "Other"]:
		var tab := left.get_node(c + "Filter/" + name) as Button
		tab.set_pressed_no_signal(recruit_filter == name.to_lower())
		tab.pressed.connect(func() -> void:
			recruit_filter = name.to_lower()
			_refresh())
	var board: Array[Dictionary] = []
	for candidate in game.recruitment_board():
		if _recruit_shows(candidate):
			board.append(candidate)
	board.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["hire"]) < int(b["hire"]))
	var applicants: Array = board.filter(func(p): return str(p.get("kind", "")) != "contract")
	var contracts: Array = board.filter(func(p): return str(p.get("kind", "")) == "contract")
	var chosen: Dictionary = {}
	for candidate in board:
		if str(candidate["id"]) == selected_candidate:
			chosen = candidate
	if chosen.is_empty() and not board.is_empty():
		chosen = board[0]
		selected_candidate = str(chosen["id"])
	var list := left.get_node(c + "List/Items") as VBoxContainer
	for group in [["Applicants", applicants], ["From other guilds", contracts]]:
		if (group[1] as Array).is_empty():
			continue
		var heading := Label.new()
		heading.text = str(group[0])
		heading.theme_type_variation = &"LabelCaption"
		list.add_child(heading)
		for candidate in group[1]:
			var role: String = Mercs.role_of(candidate)
			var fee: int = int(candidate["hire"])
			var card := _list_card(list, ROLE_ICONS.get(role, ROLE_ICONS["Miner"]), str(candidate["name"]),
				_candidate_line(candidate).replace("  ·  contract", ""), "", _money(fee), str(candidate["id"]) == selected_candidate, _choose_candidate.bind(str(candidate["id"])))
			card.tooltip_text = Mercs.trait_lines(candidate)
			if game.gold < fee:
				(card.get_node("Body/Side/Value/Text") as Label).theme_type_variation = &"LabelMuted"
	var tier: int = game.rep_tier()
	var standing := left.get_node(c + "Summary/Standing") as Label
	standing.text = "%s  ·  up to level %d" % [Mercs.tier_name(tier), int(Mercs.TIERS[tier]["cap"])]
	var next: int = Mercs.rep_to_next(game.reputation)
	standing.tooltip_text = "Reputation %s.%s\nBetter Hellfarers apply to more reputable guilds." % [_thousands(game.reputation),
		("  %s at %s." % [Mercs.tier_name(tier + 1), _thousands(int(Mercs.TIERS[tier + 1]["rep"]))]) if next > 0 else ""]
	var refresh := left.get_node(c + "Summary/Refresh") as Label
	var tick := func() -> void:
		refresh.text = "New faces in " + _duration(1800 - _now() % 1800)
	tick.call()
	live_updaters.append(tick)
	(left.get_node(c + "List") as Control).visible = not board.is_empty()
	(left.get_node(c + "Empty") as Control).visible = board.is_empty()
	var none: bool = chosen.is_empty()
	for child in (right.get_node("Margin/Content") as Control).get_children():
		(child as CanvasItem).visible = child.name == "Empty" if none else child.name != "Empty"
	if none:
		return
	var role: String = Mercs.role_of(chosen)
	var contract: bool = str(chosen.get("kind", "")) == "contract"
	_set_bust(right.get_node(c + "Head/Portrait/Bust") as TextureRect, role)
	(right.get_node(c + "Head/Id/Name") as Label).text = str(chosen["name"])
	(right.get_node(c + "Head/Id/Title") as Label).text = ("Contract from %s" % str(chosen.get("from", "a guild"))) if contract else Mercs.title(chosen)
	(right.get_node(c + "Head/Id/Status/RoleIcon") as TextureRect).texture = ROLE_ICONS.get(role, ROLE_ICONS["Miner"])
	var kit: String = str(game.item_definition(str(chosen.get("kit", ""))).get("name", ""))
	(right.get_node(c + "Head/Id/Status/Role") as Label).text = ("Brings their own %s" % kit.to_lower()) if kit != "" else role
	right.get_node(c + "Stats/Skill").value = _money(Mercs.value(chosen, false) + int(game.item_definition(str(chosen.get("kit", ""))).get("cost", 0)))
	var fee_tile := right.get_node(c + "Stats/Fee")
	fee_tile.caption = "Price + fee" if contract else "Signing fee"
	fee_tile.value = _money(int(chosen["hire"]))
	right.get_node(c + "Stats/Wage").value = _money(int(game.terms(chosen)["wage"]))
	right.get_node(c + "Stats/Share").value = "%d%%" % int(round(float(game.terms(chosen)["cut"]) * 100.0))
	var best: String = Mercs.best_trade(chosen)
	for trade in SKILL_ORDER:
		var base := c + "Skills/" + str(TradeSkills.NAMES[trade]) + "/"
		(right.get_node(base + "Top/Level") as Label).text = str(Mercs.level(chosen, trade))
		(right.get_node(base + "Bar") as ProgressBar).value = TradeSkills.progress(chosen, trade) * 100.0
		if trade == best:
			(right.get_node(base + "Top/Name") as Label).theme_type_variation = &"LabelGood"
	var lines: Array[String] = []
	for t in chosen.get("traits", []):
		var d: Dictionary = Mercs.TRAITS.get(str(t), {})
		lines.append("%s: %s" % [str(d.get("name", t)), str(d.get("text", ""))])
	if contract:
		lines.append("Price includes a 10% transfer fee. They settle in for 3 days before they can be sold on.")
	(right.get_node(c + "Traits") as Label).text = "\n".join(lines) if not lines.is_empty() else "None"
	var fee: int = int(chosen["hire"])
	var hire := right.get_node(c + "Hire") as Button
	hire.text = "%s %s  ·  %s" % ["Buy" if contract else "Hire", str(chosen["name"]).get_slice(" ", 0), _money(fee)]
	hire.disabled = game.gold < fee
	hire.pressed.connect(_hire.bind(str(chosen["id"])))
	var reason := right.get_node(c + "Reason") as Label
	reason.text = "Not enough gold: %s." % _money(fee) if game.gold < fee else ""
	reason.visible = not reason.text.is_empty()

## The Workshop chapter: Craft (what can I make?), Shop (what can I buy?), Storeroom (what do I have?).
func _draw_workshop_chapter() -> void:
	match workshop_tab:
		"shop": _draw_workshop_shop()
		"store": _draw_workshop_store()
		_: _draw_workshop()
	var tabs := _mount_page(WORKSHOP_TABS, left_leaf)
	for tab in [["CraftTab", "craft"], ["ShopTab", "shop"], ["StoreTab", "store"]]:
		var btn := tabs.get_node("Tabs/" + str(tab[0])) as Button
		btn.set_pressed_no_signal(workshop_tab == str(tab[1]) or (str(tab[1]) == "craft" and not workshop_tab in ["shop", "store"]))
		btn.pressed.connect(_set_workshop_tab.bind(str(tab[1])))
	var spare: int = game.equipment_inventory.size()
	(tabs.get_node("Tabs/StoreTab") as Button).text = "Storeroom  ·  %d" % spare if spare > 0 else "Storeroom"

func _set_workshop_tab(tab: String) -> void:
	workshop_tab = tab
	if tab == "store":
		workshop_focus = ""
	_refresh()

## Does a recipe pass the Workshop's focus from the lookup card?
func _focus_shows(key: String) -> bool:
	if workshop_focus.begins_with("uses:"):
		var recipe: Variant = Catalog.item(key).get("recipe", {})
		return recipe is Dictionary and (recipe as Dictionary).has(workshop_focus.substr(5))
	if workshop_focus.begins_with("item:"):
		return key == workshop_focus.substr(5)
	return true

func _focus_text_for(focus: String) -> String:
	var saved: String = workshop_focus
	workshop_focus = focus
	var text: String = _focus_text().to_lower()
	workshop_focus = saved
	return text

func _focus_text() -> String:
	if workshop_focus.begins_with("uses:"):
		var good: String = workshop_focus.substr(5)
		return "Recipes using " + (_resource_name(good) if MoneyMercsState.RESOURCE_ORDER.has(good) else str(Catalog.item(good).get("name", good)))
	if workshop_focus.begins_with("item:"):
		return "Blueprint: " + str(Catalog.item(workshop_focus.substr(5)).get("name", ""))
	return ""

func _bind_focus(page_root: Control) -> void:
	var focus := page_root.get_node("Margin/Content/Focus") as Control
	focus.visible = not workshop_focus.is_empty()
	(focus.get_node("Text") as Label).text = _focus_text()
	(focus.get_node("Clear") as Button).pressed.connect(func() -> void:
		workshop_focus = ""
		_refresh())

## How many of a known recipe the warehouse can make right now.
func _craftable_count(key: String) -> int:
	if not game.craft_missing(key).is_empty():
		return 0
	var recipe: Variant = Catalog.item(key).get("recipe", {})
	var most: int = 99
	if recipe is Dictionary:
		for part in recipe:
			most = mini(most, int(game.resources.get(str(part), 0)) / maxi(1, int(recipe[part])))
	return most

## Which Workshop filter a catalog item belongs to.
func _craft_group(key: String) -> String:
	var d: Dictionary = Catalog.item(key)
	var slot: String = str(d.get("slot", "none"))
	var kind: String = str(d.get("kind", ""))
	if slot in ["food", "potion"]:
		return "supplies"
	if slot == "none":
		return "materials"
	if slot == "main_hand":
		return "tools" if kind in ["felling_axe_kind", "pickaxe", "sickle", "fishing_rod", "hoe"] else "weapons"
	return "armour"

## A row with the item's icon, name, a line of detail and up to two buttons.
func _item_row(list: VBoxContainer, icon: Texture2D, title: String, details: String, key: String = "") -> Control:
	var card := ROW_ITEM_CARD.instantiate()
	list.add_child(card)
	_lookup_on(card.get_node("Row/IconSlot") as Control, key)
	(card.get_node("Row/IconSlot/Icon") as TextureRect).texture = icon
	(card.get_node("Row/Info/Name") as Label).text = title
	(card.get_node("Row/Info/Details") as Label).text = details
	(card.get_node("Row/Primary") as Button).visible = false
	return card

func _row_button(card: Control, which: String, text: String, action: Callable, disabled: bool = false, tip: String = "") -> void:
	var b := card.get_node("Row/" + which) as Button
	b.visible = true
	b.text = text
	b.disabled = disabled
	b.tooltip_text = tip
	b.pressed.connect(action)

func _draw_workshop_shop() -> void:
	var left := _mount_page(WORKSHOP_SHOP_LEFT, left_leaf)
	var right := _mount_page(WORKSHOP_SHOP_RIGHT, right_leaf)
	var c := "Margin/Content/"
	var gear := left.get_node(c + "Gear/Items") as VBoxContainer
	for key in MercsV05.shop_keys():
		var definition: Dictionary = game.item_definition(str(key))
		var card := _item_row(gear, _gear_icon(str(key)), str(definition["name"]), Gear.summary(str(key)), str(key))
		var cost: int = int(definition["cost"])
		_row_button(card, "Primary", "Buy  ·  %s" % _money(cost), _buy_equipment.bind(str(key)), game.gold < cost,
			"A common one for the storeroom. Crafted pieces can roll better.")
	for name in ["All", "Tools", "Weapons", "Armour", "Supplies", "Materials"]:
		var tab := right.get_node(c + "Filter/" + name) as Button
		tab.set_pressed_no_signal(craft_filter == name.to_lower())
		tab.pressed.connect(func() -> void:
			craft_filter = name.to_lower()
			_refresh())
	var prints := right.get_node(c + "Blueprints/Items") as VBoxContainer
	_bind_focus(right)
	(right.get_node(c + "Filter") as Control).visible = workshop_focus.is_empty()
	for key in game.blueprint_shop():
		if not _focus_shows(key):
			continue
		if workshop_focus.is_empty() and craft_filter != "all" and _craft_group(key) != craft_filter:
			continue
		var d: Dictionary = Catalog.item(key)
		var price: int = int(d.get("blueprint_price", 40))
		var card := _item_row(prints, _recipe_icon(key), str(d["name"]), Gear.summary(key) if game.makeable(key) else "Needs goods from sites you can't reach yet", key)
		card.tooltip_text = "Recipe: %s" % _cost_line(d.get("recipe", {}) if d.get("recipe") is Dictionary else {})
		_row_button(card, "Primary", "Learn  ·  %s" % _money(price), _buy_blueprint.bind(key), game.gold < price)
	var empty_note := right.get_node(c + "Empty")
	empty_note.visible = prints.get_child_count() == 0
	if craft_filter != "all" and not game.blueprint_shop().is_empty():
		empty_note.text = "No blueprints of this kind for sale. Try All."
	(right.get_node(c + "Blueprints") as Control).visible = prints.get_child_count() > 0

func _draw_workshop_store() -> void:
	var left := _mount_page(WORKSHOP_STORE_LEFT, left_leaf)
	var right := _mount_page(WORKSHOP_STORE_RIGHT, right_leaf)
	var c := "Margin/Content/"
	# Spare gear: repair or sell. Equipping happens on a mercenary's Gear page.
	var store := left.get_node(c + "Store/Items") as VBoxContainer
	for item in game.equipment_inventory:
		var key: String = str(item.get("key", ""))
		var wear: String = ("  ·  %d/%d" % [Gear.durability(item), Gear.max_durability(item)]) if Gear.max_durability(item) > 0 else ""
		var card := _item_row(store, _gear_icon(key), Gear.full_name(item), Gear.summary(key) + wear, key)
		card.tooltip_text = Gear.describe(item)
		var value: int = game.resale_value(item)
		_row_button(card, "Primary", "Sell  ·  %s" % _money(value), _sell_equipment.bind(str(item.get("uid", ""))), false,
			"Sell for %s (65%% of its worth, less if worn)." % _money(value))
		var cost: Dictionary = game.repair_cost(item)
		if not cost.is_empty():
			_row_button(card, "Secondary", "Repair", _repair.bind(str(item.get("uid", ""))), game.gold < game.repair_gold(cost), "Uses %s." % _cost_line(cost))
	(left.get_node(c + "Store") as Control).visible = store.get_child_count() > 0
	(left.get_node(c + "StoreEmpty") as Control).visible = store.get_child_count() == 0
	# Food and potions.
	var supplies := right.get_node(c + "Supplies/Items") as VBoxContainer
	for key in MoneyMercsState.RESOURCE_ORDER:
		if not Gear.consumable(str(key)) or int(game.resources.get(key, 0)) <= 0:
			continue
		_item_row(supplies, _item_icon(str(key)), "%s  ×%d" % [_resource_name(str(key)), int(game.resources[key])], Gear.summary(str(key)), str(key))
	(right.get_node(c + "Supplies") as Control).visible = supplies.get_child_count() > 0
	(right.get_node(c + "SuppliesEmpty") as Control).visible = supplies.get_child_count() == 0

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
	for name in ["All", "Tools", "Weapons", "Armour", "Supplies", "Materials"]:
		var tab := left.get_node(c + "Filter/" + name) as Button
		tab.set_pressed_no_signal(craft_filter == name.to_lower())
		tab.pressed.connect(func() -> void:
			craft_filter = name.to_lower()
			_refresh())
	var known: Array = []
	for key in Catalog.items():
		if game.knows(str(key)) and _focus_shows(str(key)) and (not workshop_focus.is_empty() or craft_filter == "all" or _craft_group(str(key)) == craft_filter):
			known.append(str(key))
	known.sort_custom(func(a, b): return int(Catalog.item(a)["tier"]) * 100000 + int(Catalog.item(a)["value"]) < int(Catalog.item(b)["tier"]) * 100000 + int(Catalog.item(b)["value"]))
	var ready: Array = known.filter(func(k): return game.craft_missing(k).is_empty())
	var short: Array = known.filter(func(k): return not game.craft_missing(k).is_empty())
	if selected_recipe == "" or not Catalog.items().has(selected_recipe) or not game.knows(selected_recipe):
		selected_recipe = str(ready[0]) if not ready.is_empty() else (str(short[0]) if not short.is_empty() else "")
	var list := left.get_node(c + "Known/Items") as VBoxContainer
	for group in [["Ready to craft", ready], ["Missing materials", short]]:
		if (group[1] as Array).is_empty():
			continue
		var heading := Label.new()
		heading.text = str(group[0])
		heading.theme_type_variation = &"LabelCaption"
		list.add_child(heading)
		for key in group[1]:
			var missing: Dictionary = game.craft_missing(key)
			var can: int = _craftable_count(key)
			var line: String = Gear.summary(key) if missing.is_empty() else ("Missing " + _cost_line(missing) if game.makeable(key) else "Needs goods from sites not open yet")
			var card := _list_card(list, _recipe_icon(key), str(Catalog.item(key)["name"]), line, "", "×%d" % can if can > 0 else "",
				key == selected_recipe, _choose_recipe.bind(key))
			card.custom_minimum_size.y = 30
			if can > 0:
				(card.get_node("Body/Side/Value/Text") as Label).theme_type_variation = &"LabelGood"
			else:
				(card.get_node("Body/Info/Details") as Label).theme_type_variation = &"LabelMuted"
	(left.get_node(c + "Summary") as Label).text = "%d ready to craft  ·  %d short of materials" % [ready.size(), short.size()]
	(left.get_node(c + "Known") as Control).visible = not known.is_empty()
	(left.get_node(c + "KnownEmpty") as Control).visible = known.is_empty()
	_bind_focus(left)
	(left.get_node(c + "Filter") as Control).visible = workshop_focus.is_empty()
	var for_sale: int = game.blueprint_shop().filter(func(k): return _focus_shows(str(k))).size()
	var link := left.get_node(c + "ShopLink") as Button
	link.text = "%s for sale in the Shop  >" % _plural(for_sale, "blueprint")
	link.visible = for_sale > 0
	link.pressed.connect(_set_workshop_tab.bind("shop"))
	# The recipe.
	var none: bool = selected_recipe == ""
	for child in (right.get_node("Margin/Content") as Control).get_children():
		(child as CanvasItem).visible = (child.name == "Empty" or child.name == "Header") if none else child.name != "Empty"
	if none:
		return
	var d: Dictionary = Catalog.item(selected_recipe)
	var head_slot := right.get_node(c + "Head/Slot")
	head_slot.icon = _recipe_icon(selected_recipe)
	_lookup_on(head_slot, selected_recipe)
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
		_lookup_on(row.get_node("Icon") as Control, str(part))
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
	# Held is the default, so selling is one click away; with nothing held, everything shows.
	var chosen_filter: String = market_filter
	if market_filter == "held" and not MoneyMercsState.RESOURCE_ORDER.any(func(k): return int(game.resources.get(str(k), 0)) > 0):
		market_filter = "all"
	for kind in ["All", "Held", "Raw", "Crafted", "Food"]:
		var tab := left.get_node(c + "Filter/" + kind) as Button
		tab.set_pressed_no_signal(market_filter == kind.to_lower())
		tab.pressed.connect(func() -> void:
			market_filter = kind.to_lower()
			_refresh())
	var held_total: int = 0
	for id in MoneyMercsState.RESOURCE_ORDER:
		var key: String = str(id)
		var stored: int = int(game.resources.get(key, 0))
		held_total += stored * game.sell_price(key)
		if not _market_shows(key, stored):
			continue
		var row := ROW_MARKET.instantiate() as Button
		list.add_child(row)
		(row.get_node("Body/Icon") as TextureRect).texture = _item_icon(key)
		(row.get_node("Body/Name") as Label).text = _resource_name(key)
		var held := row.get_node("Body/Held") as Label
		held.text = str(stored) if stored > 0 else "-"
		held.theme_type_variation = &"" if stored > 0 else &"LabelMuted"
		(row.get_node("Body/Price/Pays") as Label).text = _money(game.sell_price(key))
		var trend := row.get_node("Body/Price/Trend") as TextureRect
		var base: int = int(MoneyMercsState.BASE_PRICE.get(key, 1))
		var now_price: int = game.price(key)
		trend.texture = null if now_price == base else (TREND_UP if now_price > base else TREND_DOWN)
		row.tooltip_text = "%s\nUsual price %d G, today %d G." % [str(MoneyMercsState.RESOURCE_DESC.get(key, "")), base, now_price]
		row.set_pressed_no_signal(key == selected_market_item)
		row.pressed.connect(_choose_commodity.bind(key))
	(left.get_node(c + "Summary/Hint") as Label).text = "Held goods worth %s" % _money(held_total)
	market_filter = chosen_filter
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
	_lookup_on(right.get_node(c + "Head/Slot") as Control, key)
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
		buy.tooltip_text = "-%s (%s each)" % [_money(game.buy_price(key, n) * n), _money(game.buy_price(key, n))] if buyable else ("Merchants never sell these. Find them below." if key in ["relic", "sovereign"] else "Merchants don't stock food or potions: cook or brew them, or buy from players.")
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
		note.text = "Merchants pay about 75% of fair value at once. The Auction House pays more, if you can wait for a buyer."
	_mount_exchange_tabs()

func _mount_exchange_tabs() -> void:
	var tabs := _mount_page(EXCHANGE_TABS, left_leaf)
	for tab in [["MerchantsTab", "market"], ["AuctionTab", "auction"], ["HallTab", "hall"]]:
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

## The Ledger chapter: Accounts (the treasury) and Reports (the chronicle of expeditions).
func _draw_ledger() -> void:
	match page:
		"finance": _draw_accounts()
		"warehouse": _draw_warehouse()
		_: _draw_history()
	var tabs := _mount_page(LEDGER_TABS, left_leaf)
	for tab in [["AccountsTab", "finance"], ["ReportsTab", "ledger"], ["WarehouseTab", "warehouse"]]:
		var btn := tabs.get_node("Tabs/" + str(tab[0])) as Button
		btn.set_pressed_no_signal(page == str(tab[1]))
		btn.pressed.connect(_nav_to.bind(str(tab[1])))

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
	# Expedition capacity: charters open more slots.
	left.get_node(c + "Slots/Text/Pips").value = game.expedition_slots
	(left.get_node(c + "Slots/Text/Caption") as Label).text = "Expedition slots  ·  %d of %d" % [game.expedition_slots, MoneyMercsState.MAX_SLOTS]
	var expand := left.get_node(c + "Slots/Expand") as Button
	var note := left.get_node(c + "SlotsNote") as Label
	var next: String = game.next_charter()
	if next == "":
		expand.text = "All slots open"
		expand.disabled = true
		note.text = "Your guild holds every Warden's charter."
	else:
		var charter: Dictionary = Catalog.data()["upgrades"][next]
		var block: String = game.charter_block()
		expand.text = "Sign  ·  %s" % _money(game.upgrade_gold(next))
		expand.disabled = not block.is_empty()
		expand.tooltip_text = "%s: %s.\nCosts %s and %s; materials you lack are bought from the merchants." % [str(charter["name"]), str(charter["effect"]).to_lower(), _money(int(charter.get("gold", 0))), _cost_line(charter["cost"])]
		expand.pressed.connect(func() -> void: _act(func() -> String: return game.build_upgrade(next), "sign_charter"))
		note.text = "Next: %s  ·  %s + %s%s" % [str(charter["name"]), _money(int(charter.get("gold", 0))), _cost_line(charter["cost"]),
			("  ·  " + block) if game.reputation < int(charter.get("rep", 0)) else ""]
		note.theme_type_variation = &"LabelAccent" if game.reputation < int(charter.get("rep", 0)) else &"LabelCaption"
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
	# Profit by trade, from the reports the company still keeps.
	var by_trade: Dictionary = {}
	var trips: Dictionary = {}
	for report in game.reports:
		var trade: String = str(TradeSites.by_id(str(report.get("site", ""))).get("trade", "mining" if str(report.get("region", "")).begins_with("Harlow") else "other"))
		by_trade[trade] = int(by_trade.get(trade, 0)) + _report_value(report) - int(report.get("cost", 0))
		trips[trade] = int(trips.get(trade, 0)) + 1
	var trades := right.get_node(c + "Trades/Items") as VBoxContainer
	var order: Array = by_trade.keys()
	order.sort_custom(func(a, b): return int(by_trade[a]) > int(by_trade[b]))
	for trade in order:
		var net: int = int(by_trade[trade])
		var card := _list_card(trades, TRADE_ICONS.get(trade, ICON_FIELD), str(TradeSkills.NAMES.get(trade, "Other work")), _plural(int(trips[trade]), "trip"),
			"", ("+" if net >= 0 else "") + _money(net), false, func() -> void: pass)
		card.toggle_mode = false
		card.mouse_default_cursor_shape = Control.CURSOR_ARROW
		(card.get_node("Body/Side/Value/Text") as Label).theme_type_variation = &"LabelGood" if net >= 0 else &"LabelAccent"
	(right.get_node(c + "Trades") as Control).visible = not order.is_empty()
	(right.get_node(c + "TradesEmpty") as Control).visible = order.is_empty()

## The Ledger's Warehouse tab: every good held and its worth; a click opens it in the Market.
func _draw_warehouse() -> void:
	var left := _mount_page(WAREHOUSE_LEFT, left_leaf)
	var right := _mount_page(WAREHOUSE_RIGHT, right_leaf)
	var c := "Margin/Content/"
	var list := left.get_node(c + "List/Items") as VBoxContainer
	var kinds: Dictionary = {"raw": 0, "crafted": 0, "food": 0}
	var held: Array = []
	for id in MoneyMercsState.RESOURCE_ORDER:
		if int(game.resources.get(str(id), 0)) > 0:
			held.append(str(id))
	held.sort_custom(func(a, b): return int(game.resources[a]) * game.sell_price(a) > int(game.resources[b]) * game.sell_price(b))
	for key in held:
		var quantity: int = int(game.resources[key])
		var worth: int = quantity * game.sell_price(key)
		var kind: String = str(MoneyMercsState.RESOURCE_KIND.get(key, "raw"))
		kinds[kind] = int(kinds.get(kind, 0)) + worth
		var row := ROW_MARKET.instantiate() as Button
		list.add_child(row)
		row.toggle_mode = false
		(row.get_node("Body/Icon") as TextureRect).texture = _item_icon(key)
		(row.get_node("Body/Name") as Label).text = _resource_name(key)
		(row.get_node("Body/Held") as Label).text = str(quantity)
		(row.get_node("Body/Price/Pays") as Label).text = _money(worth)
		row.tooltip_text = "%s\n%s each today. Click for details and to trade it." % [str(MoneyMercsState.RESOURCE_DESC.get(key, "")), _money(game.sell_price(key))]
		row.pressed.connect(_open_lookup.bind(key))
	(left.get_node(c + "List") as Control).visible = not held.is_empty()
	(left.get_node(c + "Empty") as Control).visible = held.is_empty()
	right.get_node(c + "Total").value = _money(game.goods_value())
	right.get_node(c + "Kinds/Raw").value = _money(int(kinds["raw"]))
	right.get_node(c + "Kinds/Crafted").value = _money(int(kinds["crafted"]))
	right.get_node(c + "Kinds/Food").value = _money(int(kinds["food"]))
	var market := right.get_node(c + "Market") as Button
	market.pressed.connect(func() -> void:
		market_filter = "held"
		_turn_to("market"))

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
		var why: String = "Not available: " + ("every expedition slot is busy." if not slot_free else "the Wardens only help guilds with under 120 G cash and under 250 G in cash, goods and spare gear.")
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
		_lookup_on(slot, str(key))
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
		# 1-6 open the chapters, in bookmark order.
		var index: int = int(event.keycode) - int(KEY_1)
		if index >= 0 and index < PHYSICAL_TAB_PAGES.size():
			_turn_to(str(PHYSICAL_TAB_PAGES[index]))

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
		if trade == "dungeon":
			var delving: int = game.missions.filter(func(m): return str(m.get("region", "")) == "dungeon").size()
			var waiting: int = game.dungeon_checkins().size()
			var fit: int = game.crew.filter(func(m): return Gear.kit_rating(m) >= 8).size()
			var dcard := _list_card(trades, TRADE_ICONS.get("dungeon"), str(entry["name"]), "%s with gear score 8+" % _plural(fit, "fighter") if fit > 0 else "Needs fighters with gear score 8",
				"Waiting" if waiting > 0 else ("%d in" % delving if delving > 0 else ""), "%d of %d open" % [Dungeons.DUNGEONS.size(), Dungeons.DUNGEONS.size() + Dungeons.PLANNED.size()],
				selected_trade == trade, _select_trade.bind(trade))
			if delving > 0:
				(dcard.get_node("Body/Side/Caption") as Label).theme_type_variation = &"LabelAccent" if waiting > 0 else &"LabelGood"
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
	if selected_trade == "dungeon":
		_draw_dungeon_list(right)
		return
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
			row.tooltip_text = "%s\nNeeds a Hellfarer with %s level %d (your best: %d)." % [str(site.get("tagline", "")), TradeSkills.NAMES.get(selected_trade, selected_trade), int(site["level"]), level]
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

## The board's right page for dungeons: the open ones as cards, the planned ones locked.
func _draw_dungeon_list(right: Control) -> void:
	var c := "Margin/Content/"
	right.get_node(c + "Header").text = "Crypts"
	var open_list := right.get_node(c + "Open") as VBoxContainer
	var locked_list := right.get_node(c + "Locked") as VBoxContainer
	for id in Dungeons.DUNGEONS:
		var d: Dictionary = Dungeons.DUNGEONS[id]
		var card := ROW_SITE.instantiate() as Button
		open_list.add_child(card)
		card.pressed.connect(_open_dungeon.bind(str(id)))
		card.tooltip_text = str(d.get("tagline", ""))
		var floors: Array = d["floors"]
		(card.get_node("Body/Top/Info/Name") as Label).text = str(d["name"])
		(card.get_node("Body/Top/Info/Details") as Label).text = "Layer %d  ·  %d floors, the last a boss  ·  gear score %d+" % [int(d.get("layer", d["tier"])), floors.size(), int(d["min_kit"])]
		(card.get_node("Body/Facts") as Label).text = "%s  ·  supplies %s" % [", ".join(floors.map(func(f): return str(f["foe"]))), _money(int(d["supplies"]))]
		var value := card.get_node("Body/Top/Value") as Label
		var run: Dictionary = _run_in(str(id))
		if not run.is_empty():
			value.text = "Waiting" if str(run.get("stage", "")) == "await" else "Crew in"
			value.theme_type_variation = &"LabelAccent"
		else:
			value.text = ""
	for d in Dungeons.PLANNED:
		var row := ROW_LOCKED.instantiate() as Button
		locked_list.add_child(row)
		(row.get_node("Body/Name") as Label).text = str(d["name"])
		(row.get_node("Body/Need") as Label).text = "Gear score %d  ·  soon" % int(d["min_kit"])
		row.tooltip_text = "%s opens in a later update: deeper floors, tier-%d gear and %s." % [str(d["name"]), 2 if int(d["min_kit"]) < 30 else 3, str(d.get("note", ""))]
		row.disabled = true
	(right.get_node(c + "LockedCaption") as Label).text = "Coming later"
	(right.get_node(c + "LockedCaption") as Control).visible = true
	(right.get_node(c + "Hint") as Label).text = "Fights floor by floor. Only what gets out counts."

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
	var skill_need: String = "%s %d+" % [TradeSkills.NAMES.get(trade, trade), int(site["level"])]
	# Farms are above; every other site sits in the layer of hell that matches its tier.
	(right.get_node(c + "Site/Badge/Text") as Label).text = skill_need if trade == "farming" else "Layer %d  ·  %s" % [int(site.get("tier", 1)), skill_need]
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
		_lookup_on(slot, str(good))
	for key in ["rare", "rare2"]:
		var rare: Dictionary = site.get(key, {})
		if rare.is_empty():
			continue
		var slot := ITEM_SLOT.instantiate()
		slots.add_child(slot)
		slot.icon = _item_icon(str(rare["good"]))
		slot.theme_type_variation = &"GoldPanel"
		slot.tooltip_text = "Rare find: %s, about %.1f%% of trips. Worth %s to a merchant." % [str(rare.get("note", "")), float(rare["chance"]) * 100.0, _money(game.sell_price(str(rare["good"])))]
		_lookup_on(slot, str(rare["good"]))
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
		no_crew.text = "No Hellfarers are free. Hire one in Mercenaries."
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
		fund.pressed.connect(func() -> void: _act(func() -> String: return game.build_upgrade(needs), "craft"))
		reason.text = why if not why.is_empty() else "%s must be built before any crew can work here." % str(building["name"])
		reason.visible = true
		return
	if busy:
		why = "All expedition slots are busy. Wait for a crew to return."
	elif ids.is_empty() and free.is_empty():
		why = "Hire a Hellfarer in Mercenaries to start."
	elif ids.is_empty():
		why = "Choose a crew from the list on the left."
	elif not bool(forecast["meets_level"]):
		why = "Needs a Hellfarer with %s level %d." % [TradeSkills.NAMES.get(trade, trade), needed]
	elif game.gold < int(forecast["cost"]):
		why = "Not enough gold: wages and supplies cost %s." % _money(int(forecast["cost"]))
	fund.text = "Crew is out" if busy else "%s  ·  %s" % ["Send them out" if trade == "farming" else "Send them down", _money(int(forecast["cost"]))]
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
		Sound.play("send_down")
	if result.begins_with("The crew set out"):
		selected_crew.clear()
		harlow_view.selected.clear()
	_action(result)

# --- Dungeons -------------------------------------------------------------------------

const DUNGEON_LEFT := preload("res://scenes/journal/pages/dungeon_left.tscn")
const DUNGEON_RIGHT := preload("res://scenes/journal/pages/dungeon_right.tscn")
const RUN_LEFT := preload("res://scenes/journal/pages/run_left.tscn")
const RUN_RIGHT := preload("res://scenes/journal/pages/run_right.tscn")
const SIGN_ALERT := preload("res://assets/ui/kit/sign_alert.png")
const SIGN_EMPTY := preload("res://assets/ui/kit/sign_empty.png")
const SIGN_COIN := preload("res://assets/ui/kit/sign_coin.png")

## The run under way in a dungeon, if any (one waiting for orders first).
func _run_in(dungeon_id: String) -> Dictionary:
	var found: Dictionary = {}
	for m in game.missions:
		if str(m.get("region", "")) == "dungeon" and str(m.get("dungeon", "")) == dungeon_id:
			if str(m.get("stage", "")) == "await":
				return m
			if found.is_empty():
				found = m
	return found

func _open_dungeon(id: String) -> void:
	if selected_dungeon != id or page != "dungeon":
		selected_crew.clear()
	selected_dungeon = id
	dungeon_planning = false
	if page == "dungeon":
		_refresh()
	else:
		_turn_to("dungeon")

## True while the player plans another crew for a dungeon that already has one inside.
var dungeon_planning: bool = false

func _draw_dungeon() -> void:
	var d: Dictionary = Dungeons.by_id(selected_dungeon)
	if d.is_empty():
		selected_dungeon = "calder_keep"
		d = Dungeons.by_id(selected_dungeon)
	selected_trade = "dungeon"
	var run: Dictionary = _run_in(selected_dungeon)
	if not run.is_empty() and not dungeon_planning:
		_draw_run(d, run)
	else:
		_draw_dungeon_planner(d)

func _fighter_line(f: Dictionary) -> String:
	if bool(f["porter"]):
		return "porter  ·  armour %d" % int(f["armour"])
	var bits: Array[String] = ["%d dmg" % int(round(float(f["damage"])))]
	if absf(float(f["speed"]) - 1.0) > 0.05:
		bits.append("%.1fx speed" % float(f["speed"]))
	elif float(f["crit"]) >= 0.01:
		bits.append("%d%% crit" % int(round(float(f["crit"]) * 100.0)))
	bits.append("armour %d" % int(f["armour"]))
	return "  ·  ".join(bits)

func _draw_dungeon_planner(d: Dictionary) -> void:
	var left := _mount_page(DUNGEON_LEFT, left_leaf)
	var right := _mount_page(DUNGEON_RIGHT, right_leaf)
	var c := "Margin/Content/"
	var id: String = str(d["id"])
	var min_kit: int = int(d["min_kit"])
	var most: int = int(d.get("crew", 3))
	var ids: Array[String] = _selected_available()
	# Left: who can go.
	for pair in [["Fighters", "fighters"], ["Porters", "porters"], ["All", "all"]]:
		var tab := left.get_node(c + "Filter/" + str(pair[0])) as Button
		tab.set_pressed_no_signal(dungeon_filter == str(pair[1]))
		tab.pressed.connect(_set_dungeon_filter.bind(str(pair[1])))
	(left.get_node(c + "Caption") as Label).text = "Up to %d. Each needs gear score %d. Porters carry more out but die easily." % [most, min_kit]
	(left.get_node(c + "Footer/Back") as Button).pressed.connect(_back_to_dungeons)
	var free: Array = game.available_guild_workers()
	var shown: Array = []
	for merc in free:
		var fights: bool = Gear.job(merc) == "combat"
		var keep: bool = ids.has(str(merc["id"]))
		match dungeon_filter:
			"fighters": keep = keep or fights
			"porters": keep = keep or not fights
			_: keep = true
		if keep:
			shown.append(merc)
	shown.sort_custom(func(a, b):
		var aa: bool = ids.has(str(a["id"]))
		var bb: bool = ids.has(str(b["id"]))
		if aa != bb:
			return aa
		return Gear.kit_rating(a) * 100 + TradeSkills.level_of(a, "combat") > Gear.kit_rating(b) * 100 + TradeSkills.level_of(b, "combat"))
	var list := left.get_node(c + "Roster/Items") as VBoxContainer
	for merc in shown:
		var mid: String = str(merc["id"])
		var assigned: bool = ids.has(mid)
		var health: int = int(merc.get("health", 100))
		var f: Dictionary = Dungeons.fighter(merc)
		var kit: int = Gear.kit_rating(merc)
		var card := ROW_ROSTER_CARD.instantiate() as Button
		list.add_child(card)
		card.toggle_mode = true
		card.button_pressed = assigned
		(card.get_node("Body/RoleIcon") as TextureRect).texture = ROLE_ICONS.get(Mercs.role_of(merc), ROLE_ICONS["Guard"])
		(card.get_node("Body/Info/Name") as Label).text = str(merc.get("name", "?"))
		var weapon: String = str(Catalog.item(str(Gear.in_slot(merc, "main_hand").get("key", ""))).get("name", "no weapon"))
		(card.get_node("Body/Info/Details") as Label).text = "Combat %d  ·  gear %d  ·  %s" % [TradeSkills.level_of(merc, "combat"), kit, "%d dmg" % int(round(float(f["damage"]))) if not bool(f["porter"]) else "porter"]
		card.tooltip_text = "%s\n%s: %s\nTraits: %s" % [Mercs.title(merc), weapon if not bool(f["porter"]) else "No weapon, comes as a porter", _fighter_line(f), Mercs.trait_names(merc)]
		(card.get_node("Body/Health/HealthText") as Label).text = "%d%%" % health
		var hp := card.get_node("Body/Health/HealthBar") as ProgressBar
		hp.value = health
		hp.theme_type_variation = &"GreenBar" if health >= 60 else (&"GoldBar" if health >= 25 else &"")
		var tag := card.get_node("Body/Tag") as Label
		var why: String = game.dungeon_fit(id, merc)
		if assigned:
			tag.text = "In crew"
		elif why != "":
			tag.text = why
			card.disabled = true
			if why.begins_with("Gear score"):
				card.tooltip_text += "\nNeeds better gear: gear score %d of %d. Outfit them in Mercenaries → Gear." % [kit, min_kit]
		elif ids.size() >= most:
			tag.text = "Crew full"
			card.disabled = true
		else:
			tag.text = "+ Add"
		card.pressed.connect(_toggle_crew.bind(not assigned, mid))
	var no_crew := left.get_node(c + "NoCrew") as Control
	no_crew.visible = list.get_child_count() == 0
	if not free.is_empty() and no_crew.visible:
		no_crew.text = "Nobody free with a weapon. Try Everyone, or arm someone in Mercenaries." if dungeon_filter == "fighters" else "Nobody free fits. Try Everyone."
	# Right: the keep, its floors and the orders.
	(right.get_node(c + "Site/Art") as TextureRect).texture = load(str(d.get("art", ""))) as Texture2D
	(right.get_node(c + "Site") as Control).tooltip_text = str(d.get("tagline", ""))
	(right.get_node(c + "Site/Badge/Text") as Label).text = "Layer %d  ·  gear score %d+" % [int(d.get("layer", d["tier"])), min_kit]
	var plan: Dictionary = game.dungeon_forecast(id, ids, dungeon_depth, dungeon_turn_back)
	var floors: Array = d["floors"]
	for i in range(3):
		var box := right.get_node(c + "Floors/F%d" % i) as Control
		box.visible = i < floors.size()
		if i >= floors.size():
			continue
		var fl: Dictionary = floors[i]
		var boss: bool = bool(fl.get("boss", false))
		(box.get_node("Body/When") as Label).text = "Floor %d  ·  %s" % [i + 1, "boss" if boss else "~%dm" % int(Dungeons.FLOOR_TIME / 60)]
		(box.get_node("Body/Name") as Label).text = str(fl["name"])
		(box.get_node("Body/Foe") as Label).text = "%s%s" % ["%d " % int(fl["count"]) if int(fl["count"]) > 1 else "", str(fl["foe"]).to_lower() if int(fl["count"]) > 1 else ("one, armoured" if boss else str(fl["foe"]))]
		var loot: Array[String] = ["%d-%d coin" % [int(fl["coin"][0]), int(fl["coin"][1])]]
		for good in fl.get("loot", {}):
			loot.append(_resource_name(str(good)).to_lower())
		box.tooltip_text = "%s: %s\nHealth %d, hits for %d, armour %d.\nCarries %s.%s" % [str(fl["name"]), str(fl["foe"]), int(fl["hp"]), int(fl["damage"]), int(fl["armour"]), ", ".join(loot),
			"\nA chance at a tier-3 blueprint and a saint's relic." if boss else ""]
		var odds := box.get_node("Body/Odds") as Label
		if ids.is_empty():
			odds.text = "-"
			odds.theme_type_variation = &"LabelMuted"
		else:
			var p: float = float(plan["odds"][i]) if i < (plan["odds"] as Array).size() else 0.0
			odds.text = "%d%%" % int(round(p * 100.0))
			odds.theme_type_variation = &"LabelGood" if p >= 0.85 else (&"" if p >= 0.5 else &"LabelAccent")
		box.modulate = Color(1, 1, 1, 1.0 if i < dungeon_depth else 0.55)
	var names: Array[String] = []
	for mid in ids:
		names.append(str(game.merc_by_id(mid).get("name", "?")))
	var crew_label := right.get_node(c + "Crew") as Label
	if names.is_empty():
		crew_label.text = "No fighters chosen yet. Pick up to %d on the left." % most
		crew_label.theme_type_variation = &"LabelMuted"
	else:
		crew_label.text = "Crew %d of %d: %s" % [names.size(), most, ", ".join(names)]
		crew_label.theme_type_variation = &"LabelGood"
	for i in range(3):
		var btn := right.get_node(c + "Depth/D%d" % (i + 1)) as Button
		btn.visible = i < floors.size()
		btn.set_pressed_no_signal(dungeon_depth == i + 1)
		btn.pressed.connect(_set_dungeon_depth.bind(i + 1))
	for pair in [["Half", "half"], ["Death", "death"], ["Never", "never"]]:
		var btn := right.get_node(c + "Back/" + str(pair[0])) as Button
		btn.set_pressed_no_signal(dungeon_turn_back == str(pair[1]))
		btn.pressed.connect(_set_dungeon_turn_back.bind(str(pair[1])))
	for pair in [["Safe", "safe"], ["Bold", "bold"]]:
		var btn := right.get_node(c + "Risk/" + str(pair[0])) as Button
		btn.set_pressed_no_signal(dungeon_risk == str(pair[1]))
		btn.pressed.connect(func() -> void:
			dungeon_risk = str(pair[1])
			_refresh())
	var empty: bool = ids.is_empty()
	right.get_node(c + "Forecast/Haul").value = "~" + _money(int(plan["haul"])) if not empty else "-"
	var death_tile := right.get_node(c + "Forecast/Death")
	death_tile.value = "%d%%" % int(round(float(plan["death"]) * 100.0)) if not empty else "-"
	death_tile.tone = "accent" if not empty and float(plan["death"]) >= 0.1 else "normal"
	right.get_node(c + "Forecast/Time").value = "~%dm" % int(round(float(plan["duration"]) / 60.0))
	right.get_node(c + "Forecast/Haul").tooltip_text = "Average carried out under these orders, after the crew's share. Wages and supplies cost %s." % _money(int(plan["cost"]))
	var enter := right.get_node(c + "Enter") as Button
	var reason := right.get_node(c + "Reason") as Label
	var why: String = ""
	if game.missions.size() >= game.expedition_slots:
		why = "All expedition slots are busy. Wait for a crew to return."
	elif empty:
		why = "Choose fighters from the list on the left."
	elif str(plan["blocked"]) != "":
		why = str(plan["blocked"])
	elif game.gold < int(plan["cost"]):
		why = "Not enough gold: wages and supplies cost %s." % _money(int(plan["cost"]))
	enter.text = "Enter %s  ·  %s" % [str(d["name"]), _money(int(plan["cost"]) if not empty else int(d["supplies"]))]
	enter.disabled = why != ""
	enter.pressed.connect(_enter_dungeon)
	reason.text = why
	reason.visible = why != ""

func _set_dungeon_filter(filter: String) -> void:
	dungeon_filter = filter
	_refresh()

func _set_dungeon_depth(depth: int) -> void:
	dungeon_depth = depth
	_refresh()

func _set_dungeon_turn_back(order: String) -> void:
	dungeon_turn_back = order
	_refresh()

func _back_to_dungeons() -> void:
	selected_trade = "dungeon"
	_turn_to("expeditions")

func _enter_dungeon() -> void:
	var result: String = game.dungeon_dispatch(selected_dungeon, _selected_available(), dungeon_depth, dungeon_turn_back, dungeon_risk)
	if result.begins_with("The crew went"):
		Sound.play("send_down")
	if result.begins_with("The crew went"):
		selected_crew.clear()
		harlow_view.selected.clear()
		dungeon_planning = false
	_action(result)

func _dungeon_answer(mission_id: String, push: bool) -> void:
	Sound.play("choice_bold" if push else "retreat")
	_action(game.dungeon_choose(mission_id, push))

func _plan_another() -> void:
	dungeon_planning = true
	selected_crew.clear()
	_refresh()

## Goods as item slots (coin first), each opening its lookup card.
func _carry_slots(row: HBoxContainer, goods: Dictionary, faded: bool = false) -> void:
	var keys: Array = goods.keys()
	keys.sort_custom(func(a, b): return str(a) == "coin" or (str(b) != "coin" and str(a) < str(b)))
	for good in keys:
		if int(goods[good]) <= 0:
			continue
		var slot := ITEM_SLOT.instantiate()
		row.add_child(slot)
		slot.icon = SIGN_COIN if str(good) == "coin" else _item_icon(str(good))
		slot.count = int(goods[good])
		slot.tooltip_text = "%d coin" % int(goods[good]) if str(good) == "coin" else "%d %s" % [int(goods[good]), _resource_name(str(good))]
		if faded:
			slot.modulate = Color(1, 1, 1, 0.5)
		if str(good) != "coin":
			_lookup_on(slot, str(good))

func logs_so_far(m: Dictionary) -> Array:
	return (m.get("log", []) as Array).filter(func(e): return str(e["result"]) == "cleared")

func _draw_run(d: Dictionary, m: Dictionary) -> void:
	var left := _mount_page(RUN_LEFT, left_leaf)
	var right := _mount_page(RUN_RIGHT, right_leaf)
	var c := "Margin/Content/"
	var floors: Array = d["floors"]
	var stage: String = str(m.get("stage", "floor"))
	var dead: Array = m.get("dead", [])
	# Left: the crew's health and what they carry.
	var crew_box := left.get_node(c + "Crew") as VBoxContainer
	for id in m.get("ids", []):
		var merc: Dictionary = game.merc_by_id(str(id))
		if merc.is_empty():
			continue
		var card := ROW_ROSTER_CARD.instantiate() as Button
		crew_box.add_child(card)
		card.mouse_default_cursor_shape = Control.CURSOR_ARROW
		card.focus_mode = Control.FOCUS_NONE
		var f: Dictionary = Dungeons.fighter(merc)
		var top: float = maxf(1.0, float(f.get("max_hp", 100.0)))
		var hp_now: float = float((m.get("hp", {}) as Dictionary).get(str(id), top))
		var pct: int = int(round(clampf(hp_now / top, 0.0, 1.0) * 100.0))
		(card.get_node("Body/RoleIcon") as TextureRect).texture = ROLE_ICONS.get(Mercs.role_of(merc), ROLE_ICONS["Guard"])
		(card.get_node("Body/Info/Name") as Label).text = str(merc.get("name", "?"))
		(card.get_node("Body/Info/Details") as Label).text = "Did not come back up" if dead.has(str(id)) else ("porter  ·  armour %d" % int(f["armour"]) if bool(f["porter"]) else "%d dmg  ·  armour %d" % [int(round(float(f["damage"]))), int(f["armour"])])
		card.tooltip_text = _fighter_line(f)
		(card.get_node("Body/Health/HealthText") as Label).text = "%d%%" % pct
		var bar := card.get_node("Body/Health/HealthBar") as ProgressBar
		bar.value = pct
		bar.theme_type_variation = &"GreenBar" if pct >= 50 else (&"GoldBar" if pct > 0 else &"")
		(card.get_node("Body/Tag") as Label).text = "Dead" if dead.has(str(id)) else ("Potion used" if (m.get("drank", []) as Array).has(str(id)) else "")
		if dead.has(str(id)):
			card.modulate = Color(1, 1, 1, 0.55)
	var carry: Dictionary = m.get("carry", {})
	var worth: int = game.dungeon_carry_value(carry)
	(left.get_node(c + "CarryCaption") as Label).text = "Carrying  ·  worth ~%s if it gets out" % _money(worth) if worth > 0 else "Carrying"
	_carry_slots(left.get_node(c + "Carry") as HBoxContainer, carry)
	(left.get_node(c + "NoCarry") as Control).visible = carry.is_empty()
	var finds: Array[String] = []
	for find in m.get("finds", []):
		finds.append(str(game.item_definition(str(find.get("key", ""))).get("name", "something")))
	var found := left.get_node(c + "Found") as Label
	found.text = "Found on the dead: %s. It's yours if its carrier gets back up." % ", ".join(finds) if not finds.is_empty() else ""
	found.visible = not finds.is_empty() and not logs_so_far(m).is_empty()
	# The last few things that happened, newest first.
	var happened: Array = m.get("ev_log", [])
	var ev_box := left.get_node(c + "Events") as VBoxContainer
	for k in range(happened.size() - 1, maxi(-1, happened.size() - 4), -1):
		var e: Dictionary = happened[k]
		var line := Label.new()
		line.text = "%s%s: %s" % ["(crew) " if bool(e["auto"]) else "", str(e["choice"]), str(e["text"])]
		line.theme_type_variation = &"LabelCaption"
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(200, 0)
		ev_box.add_child(line)
	(left.get_node(c + "EventsCaption") as Control).visible = not happened.is_empty()
	var dropped: Dictionary = m.get("dropped", {})
	(left.get_node(c + "DroppedCaption") as Label).text = "Left in %s" % str(d["name"])
	(left.get_node(c + "DroppedCaption") as Control).visible = not dropped.is_empty()
	_carry_slots(left.get_node(c + "Dropped") as HBoxContainer, dropped, true)
	var walk := left.get_node(c + "Walk") as Label
	(left.get_node(c + "Footer/Back") as Button).pressed.connect(_back_to_dungeons)
	# Right: the floors so far, and the check-in.
	var logs: Array = m.get("log", [])
	var odds: Array = []
	if stage != "out":
		var fighters: Array = game._run_crew(m)
		odds = Dungeons.forecast(fighters, d, floors.size(), "never", func(g): return 1, 80)["odds"] if not fighters.is_empty() else []
	for i in range(3):
		var row := right.get_node(c + "Track/F%d" % i) as Control
		row.visible = i < floors.size()
		if i >= floors.size():
			continue
		var fl: Dictionary = floors[i]
		var dot := row.get_node("Dot") as TextureRect
		var note := row.get_node("Text/Note") as Label
		(row.get_node("Text/Name") as Label).text = "Floor %d  ·  %s" % [i + 1, str(fl["name"])]
		var entry: Dictionary = {}
		for e in logs:
			if int(e["floor"]) == i:
				entry = e
		if not entry.is_empty():
			var ok: bool = str(entry["result"]) == "cleared"
			dot.texture = SIGN_CHECK if ok else SIGN_CROSS
			note.text = " ".join(entry.get("lines", []))
			note.theme_type_variation = &"LabelCaption" if ok else &"LabelAccent"
		elif i == int(m.get("floor_i", 0)) and stage == "floor":
			dot.texture = SIGN_ALERT
			var end: int = int(m["floor_end"])
			var update := func() -> void:
				note.text = "Fighting %s now  ·  %s left." % [str(fl["foe"]).to_lower(), _duration(maxi(0, end - _now()))]
			update.call()
			live_updaters.append(update)
		else:
			dot.texture = SIGN_EMPTY
			note.text = "Ahead." if stage != "out" else "Not reached."
			if stage != "out" and i < odds.size():
				note.text = "Ahead. Chance to win from here: %d%%." % int(round(float(odds[i]) * 100.0))
			row.modulate = Color(1, 1, 1, 0.7)
	var prompt := right.get_node(c + "Prompt") as Control
	if stage == "await":
		prompt.visible = true
		var i: int = int(m["floor_i"])
		var hurt: Array[String] = []
		for f in game._run_crew(m):
			if float(f["hp"]) < 50.0:
				hurt.append("%s is down to %d%%" % [str(f["name"]), int(f["hp"])])
		var title := prompt.get_node("Body/Title") as Label
		title.text = "Floor %d cleared.%s" % [i + 1, (" " + ", ".join(hurt) + ".") if not hurt.is_empty() else " Everyone is standing."]
		var floors_n: int = floors.size()
		var orders_go: bool = Dungeons.keep_going(game._run_crew(m), i + 1, int(m["depth"]), str(m["turn_back"]), not dead.is_empty(), floors_n)
		var next_name: String = str(floors[i + 1]["name"])
		(prompt.get_node("Body/Text") as Label).text = "Your orders say %s. Push on to %s, or take %s out?" % [
			"go on" if orders_go else "head out", next_name, _money(worth)]
		var push := prompt.get_node("Body/Buttons/Push") as Button
		var out := prompt.get_node("Body/Buttons/Out") as Button
		push.text = "Push on" + ("  (orders)" if orders_go else "")
		out.text = "Take it out" + ("" if orders_go else "  (orders)")
		push.pressed.connect(_dungeon_answer.bind(str(m["id"]), true))
		out.pressed.connect(_dungeon_answer.bind(str(m["id"]), false))
		var timer := prompt.get_node("Body/Timer") as Label
		var until: int = int(m["await_until"])
		var tick := func() -> void:
			timer.text = "No answer in %s and the crew follows its orders." % _duration(maxi(0, until - _now()))
		tick.call()
		live_updaters.append(tick)
		walk.text = "Walking out from here takes about %s." % _duration((i + 1) * Dungeons.WALK_TIME)
	elif stage == "out":
		var fin: int = int(m["finish"])
		var tick := func() -> void:
			walk.text = "Walking out  ·  back in %s." % _duration(maxi(0, fin - _now()))
		tick.call()
		live_updaters.append(tick)
	else:
		var fin2: int = int(m["finish"])
		var tick := func() -> void:
			walk.text = "Orders: as deep as %s, turn back %s. Back in about %s." % ["the boss" if int(m["depth"]) >= floors.size() else "floor %d" % int(m["depth"]),
				str(Dungeons.TURN_BACK.get(str(m["turn_back"]), "")).to_lower().replace("anyone below half", "when anyone is below half").replace("someone dies", "if someone dies").replace("never", "never"), _duration(maxi(0, fin2 - _now()))]
		tick.call()
		live_updaters.append(tick)
	var note_label := right.get_node(c + "Note") as Label
	if game.missions.size() < game.expedition_slots:
		note_label.text = "Away from the game? The crew follows its orders. A free slot can send another crew."
	var plan_btn := Button.new()
	plan_btn.text = "Plan another crew  >"
	plan_btn.theme_type_variation = &"TextButton"
	plan_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	plan_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	plan_btn.visible = game.missions.size() < game.expedition_slots
	plan_btn.pressed.connect(_plan_another)
	right.get_node(c).add_child(plan_btn)

# --- Auction House ----------------------------------------------------------------------

const AUCTION_BROWSE_LEFT := preload("res://scenes/journal/pages/auction_browse_left.tscn")
const AUCTION_BROWSE_RIGHT := preload("res://scenes/journal/pages/auction_browse_right.tscn")
const AUCTION_SELL_LEFT := preload("res://scenes/journal/pages/auction_sell_left.tscn")
const AUCTION_SELL_RIGHT := preload("res://scenes/journal/pages/auction_sell_right.tscn")
const AUCTION_YOURS_LEFT := preload("res://scenes/journal/pages/auction_yours_left.tscn")
const AUCTION_YOURS_RIGHT := preload("res://scenes/journal/pages/auction_yours_right.tscn")
const AH_TIMES := [["H12", "12h"], ["D1", "1d"], ["D2", "2d"]]

## NPC listings per ref, for the current three-hour window (cleared after buying).
var _ah_cache: Dictionary = {}
var _ah_cache_epoch: int = -1

func _ah_listings(ref: String) -> Array:
	var epoch: int = int(_now() / AuctionHouse.EPOCH)
	if epoch != _ah_cache_epoch:
		_ah_cache.clear()
		_ah_cache_epoch = epoch
	if not _ah_cache.has(ref):
		_ah_cache[ref] = game.ah_listings_for(ref)
	return _ah_cache[ref]

func _ah_icon(ref: String) -> Texture2D:
	return _gear_icon(ref.substr(5)) if ref.begins_with("gear:") else _item_icon(ref)

func _ah_key(ref: String) -> String:
	return ref.substr(5) if ref.begins_with("gear:") else ref

## Browse's filter group for a ref.
func _ah_group(ref: String) -> String:
	var d: Dictionary = Catalog.item(_ah_key(ref))
	var cat: String = str(d.get("category", ""))
	if not ref.begins_with("gear:"):
		return "food" if cat in ["food", "potion"] else "goods"
	match cat:
		"weapon": return "arms"
		"tool", "lantern": return "tools"
	return "armour"

func _ah_all_refs() -> Array:
	var out: Array = []
	for key in MoneyMercsState.RESOURCE_ORDER:
		out.append(str(key))
	for key in Catalog.items():
		if Gear.equippable(str(key)) and not Gear.consumable(str(key)):
			out.append("gear:" + str(key))
	return out

func _ends_in(t: int) -> String:
	var left: int = maxi(0, t - _now())
	if left >= 86400:
		return "%dd %dh" % [left / 86400, (left % 86400) / 3600]
	if left >= 3600:
		return "%dh" % (left / 3600)
	return "%dm" % maxi(1, left / 60)

func _draw_auction() -> void:
	match auction_tab:
		"sell": _draw_ah_sell()
		"yours": _draw_ah_yours()
		_: _draw_ah_browse()
	_mount_exchange_tabs()

func _bind_ah_sub(left: Control) -> void:
	var c := "Margin/Content/"
	for pair in [["Browse", "browse"], ["Sell", "sell"], ["Yours", "yours"]]:
		var b := left.get_node(c + "Sub/" + str(pair[0])) as Button
		b.set_pressed_no_signal(auction_tab == str(pair[1]))
		b.pressed.connect(func() -> void:
			auction_tab = str(pair[1])
			_refresh())
	var mine: int = game.auction.listings.size() + game.auction.orders.size()
	(left.get_node(c + "Sub/Yours") as Button).text = "Yours  ·  %d" % mine if mine > 0 else "Yours"

func _ah_action(result: String) -> void:
	_ah_cache.clear()
	_action(result)

## A number box with − and + buttons; `apply` gets the new value (at least 1).
func _ah_stepper(row: Control, value: int, step: int, apply: Callable, live: Callable = Callable()) -> void:
	var box := row.get_node("Value") as LineEdit
	box.text = str(value)
	var set_to := func(v: int) -> void:
		apply.call(maxi(1, v))
		_refresh()
	(row.get_node("Minus") as Button).pressed.connect(func() -> void: set_to.call(value - step))
	(row.get_node("Plus") as Button).pressed.connect(func() -> void: set_to.call(value + step))
	box.text_submitted.connect(func(t: String) -> void: set_to.call(int(t) if t.is_valid_int() else value))
	box.focus_exited.connect(func() -> void:
		if box.text.is_valid_int() and int(box.text) != value:
			set_to.call(int(box.text)))
	if live.is_valid():
		box.text_changed.connect(func(t: String) -> void:
			if t.is_valid_int() and int(t) > 0:
				live.call(int(t)))

func _ah_times(row: Control, current: String, apply: Callable) -> void:
	for pair in AH_TIMES:
		var b := row.get_node(str(pair[0])) as Button
		b.set_pressed_no_signal(current == str(pair[1]))
		b.pressed.connect(func() -> void:
			apply.call(str(pair[1]))
			_refresh())

# Browse ------------------------------------------------------------------------------

func _draw_ah_browse() -> void:
	var left := _mount_page(AUCTION_BROWSE_LEFT, left_leaf)
	var right := _mount_page(AUCTION_BROWSE_RIGHT, right_leaf)
	var c := "Margin/Content/"
	_bind_ah_sub(left)
	var search := left.get_node(c + "Search") as LineEdit
	search.text = ah_search
	search.text_submitted.connect(func(t: String) -> void:
		ah_search = t
		_refresh())
	search.text_changed.connect(func(t: String) -> void:
		if t == "" and ah_search != "":
			ah_search = ""
			_refresh())
	for pair in [["All", "all"], ["Goods", "goods"], ["Arms", "arms"], ["Armour", "armour"], ["Tools", "tools"], ["Food", "food"]]:
		var b := left.get_node(c + "Filter/" + str(pair[0])) as Button
		b.set_pressed_no_signal(ah_filter == str(pair[1]))
		b.pressed.connect(func() -> void:
			ah_filter = str(pair[1])
			_refresh())
	var list := left.get_node(c + "List/Items") as VBoxContainer
	var refs: Array = _hall().search_refs(ah_search, 60) if ah_search.strip_edges().length() >= 2 else _ah_all_refs()
	var shown: int = 0
	for ref in refs:
		var r: String = str(ref)
		if ah_filter != "all" and _ah_group(r) != ah_filter:
			continue
		var npc: Array = _ah_listings(r)
		var searching: bool = ah_search.strip_edges().length() >= 2
		if npc.is_empty() and not searching and r != ah_item:
			continue
		var count: int = 0
		for l in npc:
			count += int(l["left"])
		var detail: String = ""
		var held: int = game.ah_held(r)
		if npc.is_empty():
			detail = "Nobody selling"
		elif held > 0:
			detail = "You hold %d" % held
		elif r.begins_with("gear:"):
			detail = "Tier %d" % int(Catalog.item(_ah_key(r)).get("tier", 1))
		var card := _list_card(list, _ah_icon(r), game.item_ref_name(r), detail, "%d listed" % count if count > 0 else "",
			_money(int(npc[0]["price"])) if not npc.is_empty() else "-", ah_item == r, func() -> void:
				ah_item = r
				_refresh())
		if npc.is_empty():
			card.modulate = Color(1, 1, 1, 0.65)
		shown += 1
		if shown >= 60:
			break
	(left.get_node(c + "Empty") as Control).visible = shown == 0
	_bind_ah_item(right)

func _bind_ah_item(right: Control) -> void:
	var c := "Margin/Content/"
	var empty: bool = ah_item == ""
	for n in ["Head", "SaleHeader", "BuyQty", "Listings", "NoListings", "OrderHeader", "OrderQty", "OrderPrice", "OrderTime", "OrderNote", "Place"]:
		(right.get_node(c + n) as Control).visible = not empty
	(right.get_node(c + "Empty") as Control).visible = empty
	if empty:
		return
	var ref: String = ah_item
	var gear: bool = ref.begins_with("gear:")
	var key: String = _ah_key(ref)
	var fair: float = game.ah_fair(ref)
	(right.get_node(c + "Head/Slot/Icon") as TextureRect).texture = _ah_icon(ref)
	_lookup_on(right.get_node(c + "Head/Slot") as Control, key)
	(right.get_node(c + "Head/Id/Name") as Label).text = game.item_ref_name(ref)
	var d: Dictionary = Catalog.item(key)
	var desc: String
	if gear:
		desc = "%s%s  ·  usually ~%s" % [Gear.summary(key), ("  ·  gear score +%d" % int(d.get("kit", 0))) if int(d.get("kit", 0)) > 0 else "", _money(int(round(fair)))]
	else:
		desc = "Usually ~%s  ·  merchants charge %s  ·  you hold %d" % [_money(int(round(fair))), _money(game.buy_price(ref)), game.ah_held(ref)]
	(right.get_node(c + "Head/Id/Desc") as Label).text = desc
	# Listings, cheapest first.
	(right.get_node(c + "BuyQty") as Control).visible = not gear
	for pair in [["One", "one"], ["Ten", "ten"], ["All", "all"]]:
		var b := right.get_node(c + "BuyQty/" + str(pair[0])) as Button
		b.set_pressed_no_signal(ah_buy_qty == str(pair[1]))
		b.pressed.connect(func() -> void:
			ah_buy_qty = str(pair[1])
			_refresh())
	var want: int = {"one": 1, "ten": 10}.get(ah_buy_qty, 1000000)
	var list := right.get_node(c + "Listings/Items") as VBoxContainer
	var npc: Array = _ah_listings(ref)
	for l in npc:
		var card: Control
		if gear:
			var item: Dictionary = l["item"]
			var rolls: String = Gear.rolls_text(item)
			card = _item_row(list, _gear_icon(key), "%s  ·  %s" % [str(l["seller"]), str(item.get("rarity", "common")).capitalize()], "%s%sends in %s" % [rolls, "  ·  " if rolls != "" else "", _ends_in(int(l["ends"]))], key)
			card.tooltip_text = Gear.describe(item)
			_row_button(card, "Primary", "Buy  ·  %s" % _money(int(l["price"])), _ah_buy.bind(str(l["uid"]), 1), game.gold < int(l["price"]), "Not enough gold." if game.gold < int(l["price"]) else "")
		else:
			var n: int = mini(want, int(l["left"]))
			card = _item_row(list, _item_icon(ref), "%s  ·  %s each" % [str(l["seller"]), _money(int(l["price"]))], "%d for sale  ·  ends in %s" % [int(l["left"]), _ends_in(int(l["ends"]))], ref)
			_row_button(card, "Primary", "Buy %d  ·  %s" % [n, _money(n * int(l["price"]))], _ah_buy.bind(str(l["uid"]), n), game.gold < int(l["price"]), "Not enough gold." if game.gold < int(l["price"]) else "Buys as many as you can afford, up to %d." % n)
	for mine in game.auction.listings:
		if str(mine["ref"]) == ref:
			var card := _item_row(list, _ah_icon(ref), "You  ·  %s each" % _money(int(mine["price"])), "%d left  ·  ends in %s" % [int(mine["left"]), _ends_in(int(mine["ends"]))], key)
			_row_button(card, "Primary", "Cancel", func() -> void: _ah_action(game.ah_cancel_listing(int(mine["id"]))))
	(right.get_node(c + "NoListings") as Control).visible = list.get_child_count() == 0
	# A buy order (its numbers start fresh for each item).
	if ah_order_for != ref:
		ah_order_for = ref
		ah_order_price = 0
		ah_order_qty = 0
	if ah_order_price <= 0:
		ah_order_price = maxi(1, int(round(fair * 0.9)))
	if ah_order_qty <= 0:
		ah_order_qty = 1 if gear else 10
	(right.get_node(c + "OrderHeader") as Control).set("text", "Want One Cheaper?" if not npc.is_empty() else "Buy Order")
	_ah_stepper(right.get_node(c + "OrderQty"), ah_order_qty, 1 if gear else 5, func(v: int) -> void: ah_order_qty = mini(v, 5) if gear else v)
	_ah_stepper(right.get_node(c + "OrderPrice"), ah_order_price, maxi(1, int(round(fair * 0.05))), func(v: int) -> void: ah_order_price = v)
	_ah_times(right.get_node(c + "OrderTime"), ah_order_time, func(t: String) -> void: ah_order_time = t)
	var rate: float = AuctionHouse.fill_rate(ref, float(ah_order_price), fair)
	var est: Dictionary = AuctionHouse.estimate(ah_order_qty, rate, int(AuctionHouse.DURATIONS[ah_order_time]))
	(right.get_node(c + "OrderNote") as Label).text = "The %s is held until sellers fill it, or you cancel. At %s each, %s." % [
		_money(ah_order_qty * ah_order_price), _money(ah_order_price),
		"it should fill in about %s" % _duration(int(float(est["hours"]) * 3600.0)) if float(est["share"]) >= 0.95 else "about %d%% should fill before it ends" % int(float(est["share"]) * 100.0)]
	var place := right.get_node(c + "Place") as Button
	place.text = "Place buy order  ·  %s" % _money(ah_order_qty * ah_order_price)
	place.disabled = game.gold < ah_order_qty * ah_order_price or game.auction.orders.size() >= AuctionHouse.MAX_ORDERS
	place.tooltip_text = "Not enough gold." if game.gold < ah_order_qty * ah_order_price else ""
	place.pressed.connect(func() -> void:
		var n: int = game.auction.orders.size()
		var said: String = game.ah_order(ref, ah_order_qty, ah_order_price, ah_order_time)
		if game.auction.orders.size() > n:
			Sound.play("list_item")
		_ah_action(said))

var ah_order_for: String = ""

func _ah_buy(uid: String, qty: int) -> void:
	_ah_action(game.ah_buy(uid, qty))

# Sell --------------------------------------------------------------------------------

func _draw_ah_sell() -> void:
	var left := _mount_page(AUCTION_SELL_LEFT, left_leaf)
	var right := _mount_page(AUCTION_SELL_RIGHT, right_leaf)
	var c := "Margin/Content/"
	_bind_ah_sub(left)
	for pair in [["All", "all"], ["Goods", "goods"], ["Gear", "gear"]]:
		var b := left.get_node(c + "Filter/" + str(pair[0])) as Button
		b.set_pressed_no_signal(ah_sell_filter == str(pair[1]))
		b.pressed.connect(func() -> void:
			ah_sell_filter = str(pair[1])
			_refresh())
	var list := left.get_node(c + "List/Items") as VBoxContainer
	var choices: Array = []
	if ah_sell_filter != "gear":
		for key in MoneyMercsState.RESOURCE_ORDER:
			if int(game.resources.get(str(key), 0)) > 0:
				choices.append({"pick": str(key), "ref": str(key), "count": int(game.resources[str(key)]), "name": _resource_name(str(key))})
	if ah_sell_filter != "goods":
		for item in game.equipment_inventory:
			choices.append({"pick": "uid:" + str(item["uid"]), "ref": "gear:" + str(item["key"]), "count": 1, "name": Gear.full_name(item), "item": item})
	if ah_sell_item == "" or not choices.any(func(ch): return str(ch["pick"]) == ah_sell_item):
		ah_sell_item = str(choices[0]["pick"]) if not choices.is_empty() else ""
	for ch in choices:
		var ref: String = str(ch["ref"])
		var npc: Array = _ah_listings(ref)
		var orders: Array = game.ah_orders_for(ref)
		var detail: String = "%d buy order%s waiting" % [orders.size(), "" if orders.size() == 1 else "s"] if not orders.is_empty() else ("Spare gear" if ch.has("item") else "")
		var pick: String = str(ch["pick"])
		_list_card(list, _ah_icon(ref), str(ch["name"]), detail, str(ch["count"]) if not ch.has("item") else "",
			_money(int(npc[0]["price"])) if not npc.is_empty() else "-", ah_sell_item == pick, func() -> void:
				ah_sell_item = pick
				ah_qty = 0
				ah_price = 0
				_refresh())
	(left.get_node(c + "Empty") as Control).visible = choices.is_empty()
	var chosen: Dictionary = {}
	for ch in choices:
		if str(ch["pick"]) == ah_sell_item:
			chosen = ch
	_bind_ah_sell(right, chosen)

func _bind_ah_sell(right: Control, ch: Dictionary) -> void:
	var c := "Margin/Content/"
	var empty: bool = ch.is_empty()
	for n in ["Head", "PostHeader", "Qty", "Price", "Marks", "Time", "Forecast", "Advice", "Post", "Reason"]:
		(right.get_node(c + n) as Control).visible = not empty
	(right.get_node(c + "Empty") as Control).visible = empty
	if empty:
		(right.get_node(c + "Order") as Control).visible = false
		return
	var ref: String = str(ch["ref"])
	var gear: bool = ch.has("item")
	var held: int = int(ch["count"])
	var fair: float = game.ah_fair(ref)
	var npc: Array = _ah_listings(ref)
	var low: int = AuctionHouse.cheapest(npc)
	var merchant: int = game.sell_price(ref) if not gear else game.resale_value(ch["item"])
	(right.get_node(c + "Head/Slot/Icon") as TextureRect).texture = _ah_icon(ref)
	_lookup_on(right.get_node(c + "Head/Slot") as Control, _ah_key(ref))
	(right.get_node(c + "Head/Id/Name") as Label).text = str(ch["name"])
	(right.get_node(c + "Head/Id/Desc") as Label).text = ("You hold %d  ·  " % held if not gear else "") + "merchants pay %s now" % _money(merchant)
	# The best NPC buy order, if any: sell into it at once.
	var orders: Array = game.ah_orders_for(ref)
	var order_box := right.get_node(c + "Order") as Control
	order_box.visible = not orders.is_empty()
	if not orders.is_empty():
		var o: Dictionary = orders[0]
		var n: int = mini(held, int(o["left"]))
		var paid: int = int(round(float(n * int(o["price"])) * (1.0 - AuctionHouse.CUT)))
		(order_box.get_node("Row/Text") as Label).text = "%s wants %d at %s each. Sell %d now for %s after the cut." % [str(o["buyer"]), int(o["left"]), _money(int(o["price"])), n, _money(paid)]
		var fill := order_box.get_node("Row/Fill") as Button
		fill.text = "Sell %d" % n
		fill.pressed.connect(func() -> void: _ah_action(game.ah_fill(str(o["uid"]), n)))
	# The listing.
	if ah_qty <= 0 or ah_qty > held:
		ah_qty = held
	if gear:
		ah_qty = 1
	if ah_price <= 0:
		ah_price = maxi(1, low if low > 0 else int(round(fair)))
	(right.get_node(c + "Qty") as Control).visible = not gear
	_ah_stepper(right.get_node(c + "Qty"), ah_qty, maxi(1, held / 10), func(v: int) -> void: ah_qty = mini(v, held))
	(right.get_node(c + "Qty/All") as Button).pressed.connect(func() -> void:
		ah_qty = held
		_refresh())
	var update := func(price: int) -> void:
		_bind_ah_sell_forecast(right, ref, ah_qty, price, low, merchant, gear)
	_ah_stepper(right.get_node(c + "Price"), ah_price, maxi(1, int(round(fair * 0.05))), func(v: int) -> void: ah_price = v, update)
	for pair in [["Merchant", merchant], ["Cheapest", low], ["Usual", int(round(fair))]]:
		var b := right.get_node(c + "Marks/" + str(pair[0])) as Button
		var v: int = int(pair[1])
		b.text = "%s %s" % [str(pair[0]).replace("Merchant", "Merchants"), _money(v) if v > 0 else "-"]
		b.disabled = v <= 0
		b.pressed.connect(func() -> void:
			ah_price = v
			_refresh())
	_ah_times(right.get_node(c + "Time"), ah_time, func(t: String) -> void: ah_time = t)
	update.call(ah_price)
	var post := right.get_node(c + "Post") as Button
	post.pressed.connect(func() -> void:
		var uid: String = str(ch["item"]["uid"]) if gear else ""
		var listed: int = game.auction.listings.size()
		var result: String = game.ah_post(ref, ah_qty, ah_price, ah_time, uid)
		if game.auction.listings.size() > listed:
			Sound.play("list_item")
		if result.begins_with("Listed"):
			ah_qty = 0
		_ah_action(result))
	if game.auction.listings.size() >= AuctionHouse.MAX_LISTINGS:
		post.disabled = true
		(right.get_node(c + "Reason") as Label).text = "You have %d listings up. Cancel one in Yours, or wait for one to end." % AuctionHouse.MAX_LISTINGS

func _bind_ah_sell_forecast(right: Control, ref: String, qty: int, price: int, low: int, merchant: int, gear: bool) -> void:
	var c := "Margin/Content/"
	var plan: Dictionary = game.ah_forecast(ref, qty, price, ah_time)
	var hours: float = float(plan["hours"])
	var sells := right.get_node(c + "Forecast/Sells")
	sells.value = ("~" + _duration(int(hours * 3600.0)).get_slice(" ", 0)) if float(plan["share"]) >= 0.95 else "%d%%" % int(float(plan["share"]) * 100.0)
	sells.caption = "Sells in" if float(plan["share"]) >= 0.95 else "Sells by the end"
	sells.tone = "good" if hours <= 6.0 else ("normal" if float(plan["share"]) >= 0.95 else "accent")
	right.get_node(c + "Forecast/Fee").value = "%s · 5%%" % _money(int(plan["fee"]))
	var take := right.get_node(c + "Forecast/Take")
	take.value = "~" + _money(int(plan["take"]))
	take.tone = "good" if int(plan["take"]) > merchant * qty else "normal"
	var advice: String
	if low <= 0:
		advice = "Nobody else is selling one, so buyers come to you. Usually worth about %s." % _money(int(round(float(plan["fair"]))))
	elif price > low:
		advice = "Above the cheapest listing (%s), so buyers take theirs first. At %s it would go in about %s." % [_money(low), _money(low), _duration(int(float(plan["hours_at_cheapest"]) * 3600.0)).get_slice(" ", 0)]
	else:
		advice = "The cheapest on offer: buyers take yours first."
	if merchant * qty >= int(plan["take"]):
		advice += " Merchants would pay %s right now, no wait." % _money(merchant * qty)
	(right.get_node(c + "Advice") as Label).text = advice
	(right.get_node(c + "Post") as Button).text = "Post %s at %s%s" % ["%d %s" % [qty, game.item_ref_name(ref)] if not gear else game.item_ref_name(ref), _money(price), " each" if not gear else ""]

# Yours -------------------------------------------------------------------------------

## When the Yours tab was last opened: Today stops flagging sales from before then.
var ah_seen: int = 0

func _draw_ah_yours() -> void:
	ah_seen = _now()
	var left := _mount_page(AUCTION_YOURS_LEFT, left_leaf)
	var right := _mount_page(AUCTION_YOURS_RIGHT, right_leaf)
	var c := "Margin/Content/"
	_bind_ah_sub(left)
	var a: AuctionHouse = game.auction
	var listings := left.get_node(c + "Listings/Items") as VBoxContainer
	for l in a.listings:
		var ref: String = str(l["ref"])
		var name: String = Gear.full_name(l["item"]) if l.has("item") else _resource_name(ref)
		var sold: int = int(l["qty"]) - int(l["left"])
		var details: String = "%s%s  ·  %s left" % ["%d/%d sold" % [sold, int(l["qty"])] if not l.has("item") else "Not sold yet",
			"  ·  %s" % _money(int(l.get("earned", 0))) if int(l.get("earned", 0)) > 0 else "", _ends_in(int(l["ends"]))]
		var low: int = AuctionHouse.cheapest(_ah_listings(ref))
		var card := _item_row(listings, _ah_icon(ref), "%s  ·  %s%s" % [name, _money(int(l["price"])), " each" if not l.has("item") else ""], details, _ah_key(ref))
		var id: int = int(l["id"])
		_row_button(card, "Primary", "Cancel", func() -> void: _ah_action(game.ah_cancel_listing(id)), false, "Take it down: what's left comes back.")
		if low > 0 and low < int(l["price"]):
			_row_button(card, "Secondary", "Match %s" % _money(low), func() -> void: _ah_action(game.ah_reprice(id, low)), false, "Reprice to the cheapest listing (pays the 1% fee again).")
	(left.get_node(c + "NoListings") as Control).visible = a.listings.is_empty()
	(left.get_node(c + "Listings") as Control).visible = not a.listings.is_empty()
	var orders := left.get_node(c + "Orders/Items") as VBoxContainer
	for o in a.orders:
		var ref: String = str(o["ref"])
		var held: int = (int(o["qty"]) - int(o["got"])) * int(o["price"])
		var card := _item_row(orders, _ah_icon(ref), "%s  ·  %s each" % [game.item_ref_name(ref), _money(int(o["price"]))],
			"%d of %d bought  ·  %s held  ·  ends in %s" % [int(o["got"]), int(o["qty"]), _money(held), _ends_in(int(o["ends"]))], _ah_key(ref))
		var id: int = int(o["id"])
		_row_button(card, "Primary", "Cancel", func() -> void: _ah_action(game.ah_cancel_order(id)), false, "The held gold comes back.")
	(left.get_node(c + "NoOrders") as Control).visible = a.orders.is_empty()
	(left.get_node(c + "Orders") as Control).visible = not a.orders.is_empty()
	# Right: the last day.
	var sold_g: int = 0
	var bought: int = 0
	var fees: int = 0
	var since: int = _now() - 86400
	for e in a.log:
		if int(e["t"]) < since:
			continue
		match str(e["kind"]):
			"sold":
				sold_g += int(e["gold"])
				fees += int(round(float(int(e["gold"])) / (1.0 - AuctionHouse.CUT) * AuctionHouse.CUT))
			"bought":
				bought += int(e["qty"])
	for l in a.listings:
		if int(l["started"]) >= since:
			fees += int(l.get("fee", 0))
	right.get_node(c + "Totals/Sold").value = "+" + _money(sold_g)
	right.get_node(c + "Totals/Sold").tone = "good" if sold_g > 0 else "normal"
	right.get_node(c + "Totals/Bought").value = _plural(bought, "item")
	right.get_node(c + "Totals/Fees").value = _money(fees)
	var log_list := right.get_node(c + "Log/Items") as VBoxContainer
	for e in a.log:
		var ref: String = str(e["ref"])
		var name: String = game.item_ref_name(ref)
		var title: String
		var value: String = ""
		match str(e["kind"]):
			"sold":
				title = "Sold %d %s" % [int(e["qty"]), name] if not ref.begins_with("gear:") else "Sold %s" % name
				value = "+" + _money(int(e["gold"]))
			"bought":
				title = "Bought %d %s" % [int(e["qty"]), name] if not ref.begins_with("gear:") or int(e["qty"]) > 1 else "Bought %s" % name
				value = _money(int(e["gold"]))
			"expired":
				title = "%s ended unsold" % ("%d %s" % [int(e["qty"]), name] if not ref.begins_with("gear:") else name)
				value = "-"
			"order_ended":
				title = "Order for %s ended" % name
				value = "+" + _money(int(e["gold"]))
		var where: String = {"sold": str(e["who"]), "bought": "%s  ·  %s" % [str(e["who"]), "in the storeroom" if ref.begins_with("gear:") else "in the warehouse"],
			"expired": "Back in the %s" % ("storeroom" if ref.begins_with("gear:") else "warehouse"), "order_ended": "Unspent gold returned"}.get(str(e["kind"]), "")
		var card := _list_card(log_list, _ah_icon(ref), title, "%s  ·  %s" % [where, _ago(int(e["t"]))], "", value, false, func() -> void: pass)
		card.toggle_mode = false
		card.mouse_default_cursor_shape = Control.CURSOR_ARROW
		if value.begins_with("+"):
			(card.get_node("Body/Side/Value/Text") as Label).theme_type_variation = &"LabelGood"
	(right.get_node(c + "NoLog") as Control).visible = a.log.is_empty()


# --- Dungeon event card -------------------------------------------------------------------

## The event on the card ({mission id, index}), and until when an answer's result stays up.
var card_event: Dictionary = {}
var card_result_until: int = 0
## The seconds-left the event card last ticked at (one tick a second near the end).
var card_tick_at: int = -1

func _event_card() -> Control:
	return stage.get_node_or_null("EventCard") as Control if is_instance_valid(stage) else null

## Show the next event waiting for the player, or keep an answer's result up for a moment.
func _update_event_card() -> void:
	var card := _event_card()
	if card == null:
		return
	var b := "Card/Margin/Body/"
	if Time.get_ticks_msec() < card_result_until:
		return
	var pending: Array = game.dungeon_pending()
	if pending.is_empty():
		card.visible = false
		card_event = {}
		return
	var p: Dictionary = pending[0]
	var m: Dictionary = p["mission"]
	var ev: Dictionary = p["event"]
	var e: Dictionary = DungeonEvents.by_id(str(ev["id"]))
	var key: Dictionary = {"mission": str(m["id"]), "index": int(p["index"])}
	var fresh: bool = key != card_event
	card_event = key
	card.visible = true
	var left_s: int = maxi(0, int(ev["t"]) + DungeonEvents.EVENT_WAIT - _now())
	if fresh:
		Sound.play("event_open")
	elif left_s <= 5 and left_s > 0 and left_s != card_tick_at:
		Sound.play("event_tick")
	card_tick_at = left_s
	(card.get_node(b + "Timer") as ProgressBar).value = 100.0 * float(left_s) / float(DungeonEvents.EVENT_WAIT)
	(card.get_node(b + "TimerText") as Label).text = "The crew decides in %ds (%s)." % [left_s, "playing it safe" if str(m.get("risk", "safe")) == "safe" else "taking chances"]
	if not fresh:
		return
	var where: String = "Floor %d" % (int(m.get("floor_i", 0)) + 1) if str(m.get("ev_phase", "floor")) == "floor" else "The way out"
	(card.get_node(b + "Head/Title") as Label).text = "%s  ·  %s" % [str(Dungeons.by_id(str(m["dungeon"])).get("name", "Crypt")), where]
	var open := card.get_node(b + "Head/Open") as Button
	_reconnect(open, func() -> void: _open_dungeon(str(m["dungeon"])))
	(card.get_node(b + "Text") as Label).text = str(e.get("text", ""))
	var hint := card.get_node(b + "Hint") as Label
	hint.text = str(ev.get("hint", ""))
	hint.visible = hint.text != ""
	(card.get_node(b + "Result") as Control).visible = false
	(card.get_node(b + "Timer") as Control).visible = true
	(card.get_node(b + "TimerText") as Control).visible = true
	var choices: Array = e.get("choices", [])
	var lean: int = DungeonEvents.auto_choice(ev, str(m.get("risk", "safe")))
	for i in range(3):
		var btn := card.get_node(b + "Choices/C%d" % i) as Button
		btn.visible = i < choices.size()
		if i >= choices.size():
			continue
		var tag: String = str(choices[i].get("tag", ""))
		btn.text = str(choices[i]["label"]) + ("   (crew's pick)" if i == lean else "")
		btn.tooltip_text = {"bold": "The risky choice.", "safe": "The careful choice."}.get(tag, "")
		_reconnect(btn, _answer_event.bind(str(m["id"]), int(p["index"]), i))
	_fit_event_card(card)

func _answer_event(mission_id: String, index: int, choice: int) -> void:
	var m: Dictionary = game.mission_by_id(mission_id)
	var before: Dictionary = _run_mark(m)
	var ev: Dictionary = (m.get("ev", []) as Array)[index] if index < (m.get("ev", []) as Array).size() else {}
	var tag: String = ""
	if not ev.is_empty():
		var choices: Array = DungeonEvents.by_id(str(ev["id"])).get("choices", [])
		tag = str(choices[choice].get("tag", "")) if choice < choices.size() else ""
	var result: String = game.dungeon_answer(mission_id, index, choice)
	Sound.play("choice_bold" if tag == "bold" else "choice_safe")
	var after: Dictionary = _run_mark(m)
	var outcome: String = ""
	if int(after["dead"]) > int(before["dead"]) or float(after["hp"]) < float(before["hp"]) - 0.5 or int(after["carry"]) < int(before["carry"]):
		outcome = "outcome_bad"
	elif int(after["carry"]) > int(before["carry"]) or int(after["gear"]) > int(before["gear"]) or float(after["hp"]) > float(before["hp"]) + 0.5:
		outcome = "outcome_good"
	if outcome != "":
		get_tree().create_timer(0.35).timeout.connect(func() -> void: Sound.play(outcome))
	var card := _event_card()
	if card == null:
		return
	var b := "Card/Margin/Body/"
	for i in range(3):
		(card.get_node(b + "Choices/C%d" % i) as Control).visible = false
	(card.get_node(b + "Hint") as Control).visible = false
	(card.get_node(b + "Timer") as Control).visible = false
	(card.get_node(b + "TimerText") as Control).visible = false
	var res := card.get_node(b + "Result") as Label
	res.text = result
	res.visible = true
	card_result_until = Time.get_ticks_msec() + 4500
	card_event = {}
	_fit_event_card(card)
	if page == "dungeon":
		_refresh()

## What a crypt run holds right now, to tell whether an event helped or hurt.
func _run_mark(m: Dictionary) -> Dictionary:
	var hp: float = 0.0
	for id in m.get("hp", {}):
		hp += float(m["hp"][id])
	var carry: int = 0
	for good in m.get("carry", {}):
		carry += int(m["carry"][good]) * (1 if good == "coin" else 5)
	return {"hp": hp, "dead": (m.get("dead", []) as Array).size(), "carry": carry, "gear": (m.get("event_gear", []) as Array).size()}

## The card grows upward from the bottom-right corner to fit what's on it.
func _fit_event_card(card: Control) -> void:
	var panel := card.get_node("Card") as Control
	panel.offset_top = panel.offset_bottom - 40.0
	panel.reset_size()
	panel.offset_top = panel.offset_bottom - panel.get_combined_minimum_size().y
