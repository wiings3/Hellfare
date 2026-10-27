extends SceneTree
## End-to-end BookUI navigation, layout structure and Company bindings.
## Isolated to CI profiles because it resets the company.
## Uses check() rather than assert() so a failure exits with an error instead of hanging.

var failures: int = 0

func _initialize() -> void:
	if OS.get_environment("CI") != "true":
		push_error("BookUI tests must only run in CI.")
		quit(1)
		return
	call_deferred("_verify")

func check(condition: bool, what: String) -> void:
	if not condition:
		failures += 1
		push_error("BookUI check failed: " + what)

func _verify() -> void:
	var view: Control = load("res://scenes/journal/widgets/main.tscn").instantiate()
	root.add_child(view)
	var journal: Control = view.get_node("GuildmastersLogbook")
	# The fixed journal is an editor scene with a 960x540 stage.
	check(journal == view.stage, "stage node")
	check(journal.size == Vector2(960, 540), "stage is 960x540")
	check(journal.get_node("Book") == view.book_art, "book node")
	check(journal.get_node("LeftLeaf") == view.left_leaf, "left leaf")
	check(journal.get_node("RightLeaf") == view.right_leaf, "right leaf")
	check(view.left_leaf.size == Vector2(285, 371), "left page size matches book art")
	check(view.right_leaf.size == Vector2(285, 371), "right page size matches book art")
	# The book is drawn at exactly one art pixel per stage unit (crisp at 2x).
	check(view.book_art.size == view.book_art.texture.get_size(), "book drawn 1:1")
	check(view.book_art.position == view.book_art.position.round(), "book on whole pixels")
	check(view.book_art.material == null, "no runtime palette shader on the book")
	# Mouse cursor restore.
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "cursor visible")
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	view.notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "cursor restored on focus")
	# Script chain.
	check(view.get_script().resource_path == "res://scripts/book_ui.gd", "page script")
	var shell_script: Script = view.get_script().get_base_script()
	check(shell_script.resource_path == "res://scripts/book_shell.gd", "shell script")
	check(shell_script.get_base_script().resource_path == "res://scripts/game_actions.gd", "action script")
	# Bundled fonts via the project theme, not system fonts.
	var theme: Theme = ThemeDB.get_project_theme()
	check(theme != null, "project theme loaded")
	if theme:
		check(theme.default_font is FontFile, "bundled default font")
		check(str(theme.default_font.resource_path).ends_with("Jersey10-Regular.ttf"), "Jersey 10 body font")
	# Tabs.
	check(view.tab_host.get_child_count() == 6, "six chapter tabs")
	check(view.tab_book_textures.size() == 7, "seven book sheets")
	check(view.tab_overlay.get_index() > view.flip_art.get_index(), "tabs drawn above page flips")
	check(view.tab_icons_layer.get_index() > view.tab_overlay.get_index(), "icons above tab strip")
	for i in range(6):
		var tab: Button = view.tab_host.get_node("ChapterTab" + str(i))
		check(tab.text.is_empty(), "tab %d has no text" % i)
		check(tab.tooltip_text.length() > 5, "tab %d tooltip" % i)
		check(tab.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND, "tab %d cursor" % i)
		for state in ["normal", "hover", "pressed", "focus"]:
			check(tab.get_theme_stylebox(state) is StyleBoxEmpty, "tab %d %s style empty" % [i, state])
		var icon: TextureRect = view.tab_icons_layer.get_node("TabIcon" + str(i))
		check(icon.texture.get_size() == Vector2(24, 24), "tab icon %d is 24x24" % i)
		check(icon.size == Vector2(24, 24), "tab icon %d drawn 1:1" % i)
	# Company overview.
	view.game.reset_company()
	view._nav_to("hq")
	var map_page: Control = view.left_leaf.get_child(0)
	check(map_page.scene_file_path == "res://scenes/journal/pages/company_map.tscn", "company opens on the region map")
	var region_map := map_page.get_node("Margin/Content/Map") as RegionMap
	for site in TradeSites.SITES:
		check(region_map._roads.has(RegionMap.road_for({"region": "site", "site": str(site["id"])})), "a road to " + str(site["id"]))
	check(region_map.get_node("Crews").get_child_count() == 0, "no crews and nobody idle at the start")
	var locked_spot := map_page.get_node("Margin/Content/Map/Sites/old_oakwood") as Button
	check(locked_spot.tooltip_text.contains("Logging level 8") and (locked_spot.get_node("Veil") as Control).visible, "a locked site is veiled and says what it needs")
	var open_spot := map_page.get_node("Margin/Content/Map/Sites/mossward_copse") as Button
	check(not (open_spot.get_node("Veil") as Control).visible and (open_spot.get_node("Name") as Label).text == "Cinderwood", "an open site is named and unveiled")
	for site in TradeSites.SITES:
		check(map_page.has_node("Margin/Content/Map/Sites/" + str(site["id"])), "every site has a place on the map: " + str(site["id"]))
	var grave := map_page.get_node("Margin/Content/Map/Fallen/harlow") as Button
	var share: int = view.game.fallen.share("harlow", view._now()).size()
	check(grave.text == str(share) and grave.visible == (share > 0), "grave marker counts this company's share, and shows only when there is some")
	var fallen_card := map_page.get_node("Margin/Content/Map/FallenCard") as Control
	grave.mouse_entered.emit()
	check(fallen_card.visible and (fallen_card.get_node("Margin/Body/Title") as Label).text.contains("Gatepit"), "hovering a grave opens the fallen gear card")
	grave.mouse_exited.emit()
	check(not fallen_card.visible, "card closes")
	var company_left: Control = view.left_leaf.get_child(0)
	var company_right: Control = view.right_leaf.get_child(0)
	check(company_left.scene_file_path == "res://scenes/journal/pages/company_map.tscn", "company left is the map")
	check(company_right.scene_file_path == "res://scenes/journal/pages/company_right.tscn", "company right scene")
	check(view.money_label.text.contains("350"), "purse shows starting gold")
	check(company_right.get_node("Margin/Content/Expeditions").get_child_count() == 1, "one row for the free slots")
	var needs: VBoxContainer = company_right.get_node("Margin/Content/Needs")
	check(needs.get_child_count() > 0 and (needs.get_child(0).get_node("Row/Info/Name") as Label).text == "Hire your first Hellfarer", "a new company is told to hire")
	view._nav_to("standing")
	check(view.page == "hq", "the retired Standing tab opens the Company page")
	# Hover previews another tab, then restores.
	view._preview_tab(4)
	check(view.book_art.texture.resource_path.ends_with("/6.png"), "hover preview sheet")
	view._restore_tab_art()
	check(view.book_art.texture.resource_path.ends_with("/2.png"), "restored sheet")
	(view.tab_host.get_node("ChapterTab2") as Button).pressed.emit()
	check(view.page == "roster", "mercenaries tab navigates")
	check(view.book_art.texture.resource_path.ends_with("/4.png"), "mercenaries tab art")
	# Every chapter mounts its scenes.
	var scene_by_chapter := {
		"expeditions": ["board_left", "board_right"],
		"site": ["site_left", "site_right"],
		"roster": ["personnel_employed_left", "personnel_employed_right"],
		"workshop": ["personnel_workshop_left", "personnel_workshop_right"],
		"market": ["exchange_left", "exchange_right"],
		"finance": ["finance_left", "finance_right"],
		"ledger": ["chronicle_left", "chronicle_right"],
		"warehouse": ["workshop_store_left", "workshop_store_right"],
		"guildwork": ["guildwork_left", "guildwork_right"]
	}
	for chapter in scene_by_chapter:
		view._nav_to(chapter)
		var paths: Array = scene_by_chapter[chapter]
		check(view.left_leaf.get_child(0).scene_file_path.ends_with("/pages/" + str(paths[0]) + ".tscn"), chapter + " left")
		check(view.right_leaf.get_child(0).scene_file_path.ends_with("/pages/" + str(paths[1]) + ".tscn"), chapter + " right")
		check(view.book_art.texture.resource_path.ends_with("/" + str(view._active_tab_index() + 2) + ".png"), chapter + " tab art")
		check(not view.title_label.text.is_empty(), chapter + " title")
	view.workshop_tab = "craft"
	# Personnel and armory flows.
	view._nav_to("roster")
	view._set_roster_tab("recruits")
	check(view.left_leaf.get_child(0).scene_file_path.ends_with("/personnel_recruits_left.tscn"), "recruit page")
	view._hire("garrick")
	var second: String = ""
	for c in view.game.recruitment_board():
		if Mercs.best_trade(c) != "logging" and second == "" and str(c["id"]) != "garrick":
			second = str(c["id"])
	view._hire(second)
	check(view.game.crew.size() == 2, "hired two")
	view._outfit("garrick")
	check(view.page == "roster" and view.dossier_view == "gear", "outfitting opens the Gear page")
	check((view.right_leaf.get_child(0).get_node("Margin/Content/Gear") as Control).visible, "gear view shown")
	check(view.right_leaf.get_child(0).get_node("Margin/Content/Gear/Slots").get_child_count() == Gear.SLOTS.size(), "a button per gear slot")
	view.workshop_tab = "shop"
	view._nav_to("workshop")
	check(view.left_leaf.get_child(0).scene_file_path.ends_with("/workshop_shop_left.tscn"), "shop page")
	check(view.left_leaf.get_child(0).get_node("Margin/Content/Gear/Items").get_child_count() == MercsV05.shop_keys().size(), "quartermaster catalog")
	view.craft_filter = "all"
	view._refresh()
	check(view.right_leaf.get_child(0).get_node("Margin/Content/Blueprints/Items").get_child_count() == view.game.blueprint_shop().size(), "blueprint shelf")
	check(view._active_tab_index() == 3, "workshop bookmark")
	view._buy_equipment("hand_axe")
	view._nav_to("roster")
	view._set_roster_tab("employed")
	view._focus_person(second)
	view.dossier_view = "gear"
	view.selected_slot = "main_hand"
	view._refresh()
	var fits: VBoxContainer = view.right_leaf.get_child(0).get_node("Margin/Content/Gear/Fits/Items")
	check(fits.get_child_count() >= 1, "the storeroom axe fits the main hand")
	(fits.get_child(fits.get_child_count() - 1).get_node("Row/Primary") as Button).pressed.emit()
	check(str(Gear.in_slot(view.game.merc_by_id(second), "main_hand").get("key", "")) == "hand_axe", "equipped from the Gear page")
	view.dossier_view = "overview"
	view._refresh()
	var roster_list: VBoxContainer = view.left_leaf.get_child(0).get_node("Margin/Content/List/Items")
	check(roster_list.get_child_count() == view.game.crew.size(), "a roster row per mercenary")
	view._focus_person("garrick")
	check((view.right_leaf.get_child(0).get_node("Margin/Content/Head/Id/Name") as Label).text == str(view.game.crew[0]["name"]), "dossier shows selection")
	view._nav_to("finance")
	check((view.left_leaf.get_child(0).get_node("Margin/Content/Ledger/Rows/Total/Value") as Label).text == view._money(view.game.wealth()), "finance worth matches")
	view._nav_to("ledger")
	check((view.left_leaf.get_child(0).get_node("Margin/Content/Empty") as Control).visible == view.game.reports.is_empty(), "chronicle empty state")
	view._nav_to("contracts")
	check(view.page == "expeditions" and view.left_leaf.get_child(0).scene_file_path.ends_with("/board_left.tscn"), "retired contracts open the board")
	# Logging: the board lists the copse; the site planner forecasts a profit for a woodcutter.
	view._nav_to("expeditions")
	check(view.left_leaf.get_child(0).scene_file_path.ends_with("/board_left.tscn"), "expedition board")
	check(view.left_leaf.get_child(0).get_node("Margin/Content/Trades").get_child_count() == 8, "six trades, dungeons and guarding")
	view._select_trade("dungeon")
	check(view.right_leaf.get_child(0).get_node("Margin/Content/Header").text == "Crypts", "crypts heading")
	check(view.right_leaf.get_child(0).get_node("Margin/Content/Open").get_child_count() == Dungeons.DUNGEONS.size(), "a card per open dungeon")
	check(view.right_leaf.get_child(0).get_node("Margin/Content/Locked").get_child_count() == Dungeons.PLANNED.size(), "planned dungeons shown locked")
	view._select_trade("fishing")
	check(view.right_leaf.get_child(0).get_node("Margin/Content/Header").text == "Fishing", "trade heading")
	var site_rows: int = view.right_leaf.get_child(0).get_node("Margin/Content/Open").get_child_count() + view.right_leaf.get_child(0).get_node("Margin/Content/Locked").get_child_count()
	check(site_rows == TradeSites.for_trade("fishing").size(), "a row per fishing site")
	view._select_trade("logging")
	var cutter: Dictionary = {}
	for candidate in view.game.recruitment_board():
		if Mercs.best_trade(candidate) == "logging":
			cutter = candidate
			break
	check(not cutter.is_empty(), "a woodcutter is always on the board")
	view.game.gold = 900
	view._hire(str(cutter["id"]))
	check(TradeSkills.level_of(view.game.merc_by_id(str(cutter["id"])), "logging") >= 1, "new woodcutter has logging skill")
	# A farm site waits on its building; the planner's button builds it.
	view.selected_site = "tilled_acres"
	view._nav_to("site")
	var farm_fund := view.right_leaf.get_child(0).get_node("Margin/Content/Fund") as Button
	check(farm_fund.text.begins_with("Build Field Plots") and not farm_fund.disabled, "planner offers to build the field plots")
	var gold_pre_build: int = view.game.gold
	farm_fund.pressed.emit()
	check(view.game.has_upgrade("field_plots") and view.game.gold < gold_pre_build, "field plots built from the planner")
	view.game.gold = 900
	view.selected_site = "mossward_copse"
	view._nav_to("site")
	view._toggle_crew(true, str(cutter["id"]))
	var sr: Control = view.right_leaf.get_child(0)
	check(not (sr.get_node("Margin/Content/Fund") as Button).disabled, "copse can be funded with a woodcutter")
	# Judge the forecast at an ordinary market moment, not whenever timber's drift is at its low.
	var probe: int = int(Time.get_unix_time_from_system())
	while view.game.market.drift("timber", probe) < 0.0:
		probe += MarketModel.DRIFT_PERIOD
	GameClock.fixed = probe
	check(int(view.game.site_forecast("mossward_copse", view._selected_available(), "Balanced")["profit"]) > 0, "copse forecast is profitable")
	GameClock.fixed = -1
	view._dispatch_site()
	check(view.game.missions.size() == 1 and str(view.game.missions[0].get("site", "")) == "mossward_copse", "copse expedition dispatched")
	view._nav_to("hq")
	var live_map := view.left_leaf.get_child(0).get_node("Margin/Content/Map") as RegionMap
	check(live_map._tokens.size() == 1, "the crew appears on the map")
	var m0: Dictionary = view.game.missions[0]
	check(live_map.place("mossward_copse", 0.0, 0)["pos"].distance_to(RegionMap.TOWN) < 1.0, "crew sets out from town")
	check(live_map.place("mossward_copse", 0.5, 0)["pose"] == "work", "crew works mid-trip")
	check(live_map.place("mossward_copse", 0.95, 0)["pose"] == "carry", "crew carries the haul home")
	check(live_map.describe.call(m0).contains("Cinderwood"), "crew tooltip names the site")
	view.game.complete_due(int(Time.get_unix_time_from_system()) + 10000)
	check(int(view.game.resources.get("timber", 0)) > 0, "timber delivered")
	check(int(view.game.reports[0].get("value", 0)) > 0, "report records haul value")
	var before_price: int = view.game.sell_price("timber")
	view.game.trade("timber", false, int(view.game.resources["timber"]))
	check(view.game.sell_price("timber") <= before_price, "selling saturates the merchants")
	view.market_filter = "all"
	view._nav_to("market")
	check(view.left_leaf.get_child(0).get_node("Margin/Content/List/Items").get_child_count() == MoneyMercsState.RESOURCE_ORDER.size(), "market rows")
	(view.left_leaf.get_child(0).get_node("Margin/Content/Filter/Food") as Button).pressed.emit()
	var food_rows: int = view.left_leaf.get_child(0).get_node("Margin/Content/List/Items").get_child_count()
	check(food_rows > 0 and food_rows < MoneyMercsState.RESOURCE_ORDER.size(), "food filter narrows the market")
	(view.left_leaf.get_child(0).get_node("Margin/Content/Filter/All") as Button).pressed.emit()
	view._choose_commodity("iron")
	check((view.right_leaf.get_child(0).get_node("Margin/Content/Head/Id/Name") as Label).text == "Iron Ore", "trade desk follows selection")
	# Trade Hall: typed chat, cooldown, links, NPC messages, trades with tax, gear, blocking.
	var hall: TradeHall = view.game.hall
	hall.rng.seed = 4242
	view._nav_to("hall")
	check(view.left_leaf.get_child(0).scene_file_path.ends_with("/hall_left.tscn"), "trade hall page")
	check(view._active_tab_index() == 4, "trade hall sits under the Market tab")
	var t0: int = int(Time.get_unix_time_from_system())
	view.game.hall_tick(t0)
	check(not hall.feed.is_empty(), "NPC traders post in the chat")
	view._live_tick()
	check(view.left_leaf.get_child(0).get_node("Margin/Content/Chat/Scroll/Lines").get_child_count() > 0, "chat lines drawn")
	view._show_link_card("timber")
	check(view._link_card().visible, "hovering an item link shows its card")
	view._hide_link_card()
	# Parsing reads prices and quantities the way traders write them.
	check(ChatParse.intent("WTS [Iron Sword] +20% CRIT, 150g") == "sell" and int(ChatParse.money("WTS [Iron Sword] +20% CRIT, 150g")[0]["value"]) == 150, "reads a typed price, not the stat")
	check(ChatParse.qty_after_link("WTS [Timber]x40 6g each", "Timber") == 40 and bool(ChatParse.price_after_link("WTS [Timber]x40 6g each", "Timber")["each"]), "reads quantity and per-unit price")
	check(ChatParse.lot("20 for 110g?") == {"qty": 20, "total": 110}, "reads a lot offer")
	check(ChatParse.says_yes("ok deal") and ChatParse.says_no("no thanks") and not ChatParse.says_yes("no thanks"), "reads yes and no")
	# Shift+click linking puts [Item] into the message box with a live link.
	var hv: HallView = view._hall()
	hv.link_target = "chat"
	hv.link_item("timber")
	check(hv.composer.text.find("[Ashwood]") >= 0 and hv.composer_links.size() == 1, "shift+click links an item into the message")
	# The chat filter: only timber posts, then only people buying it.
	hall._post({"t": t0, "from": "Wren", "kind": "hawker", "side": "wts", "good": "timber", "qty": 20, "price": 6})
	hall._post({"t": t0, "from": "Dunny", "kind": "bargain", "side": "wts", "good": "iron", "qty": 10, "price": 9})
	hall._post({"t": t0, "from": "Hesk", "kind": "quartermaster", "side": "wtb", "good": "timber", "qty": 30, "price": 5})
	hv.add_chat_filter("timber")
	var chat_lines: VBoxContainer = view.left_leaf.get_child(0).get_node("Margin/Content/Chat/Scroll/Lines")
	var shown_text: String = ""
	for line in chat_lines.get_children():
		shown_text += (line as RichTextLabel).text if line is RichTextLabel else ""
	check(shown_text.contains("Wren") and shown_text.contains("Hesk") and not shown_text.contains("Dunny"), "filtering by timber shows only timber posts")
	hv.chat_side = "wtb"
	hv._redraw_feed()
	shown_text = ""
	for line in chat_lines.get_children():
		shown_text += (line as RichTextLabel).text if line is RichTextLabel else ""
	check(shown_text.contains("Hesk") and not shown_text.contains("Wren"), "WTB shows only buyers")
	var filter_box := view.left_leaf.get_child(0).get_node("Margin/Content/Filter/Find") as LineEdit
	filter_box.text_changed.emit("iron ore")
	check((view.left_leaf.get_child(0).get_node("Margin/Content/Suggest") as Control).visible, "typing suggests items to filter by")
	hv.chat_refs.clear()
	hv.chat_side = "all"
	hv.chat_typed = ""
	hv._redraw_feed()
	check(chat_lines.get_child_count() >= 3, "clearing the filter shows everything again")
	# Anything can be linked from the find box, owned or not (for WTB posts).
	check(hv.search_refs("steel sword").has("gear:steel_sword"), "find box finds gear you don't own")
	check(hv.search_refs("spider").has("spider_silk"), "find box finds goods you don't hold")
	var hall_right: Control = view.right_leaf.get_child(0)
	var find_box := hall_right.get_node("Margin/Content/Find") as LineEdit
	find_box.text = "steel sword"
	find_box.text_changed.emit("steel sword")
	var found := hall_right.get_node("Margin/Content/FoundScroll/Found") as GridContainer
	check(found.get_child_count() > 0 and (hall_right.get_node("Margin/Content/FoundScroll") as Control).visible, "find results shown")
	var steel: Button = null
	for slot in found.get_children():
		if str(slot.get_meta("ref")) == "gear:steel_sword":
			steel = slot
	check(steel != null, "steel sword among the results")
	if steel != null:
		steel.pressed.emit()
	check(hv.composer.text.find("[Steel Sword]") >= 0 and hv.composer_links.size() == 2, "clicking a result links it in chat")
	hv.composer_links.resize(1)
	hv.composer.text = hv.composer.text.replace(" [Steel Sword] ", "").replace("[Steel Sword] ", "")
	find_box.text_changed.emit("")
	hv.composer.text = "WTS " + hv.composer.text + "x40 6g each"
	hv.composer_text = hv.composer.text
	view.game.resources["timber"] = 60
	hv.send_chat()
	var mine_post: Dictionary = hall.feed.back()
	check(str(mine_post["side"]) == "say" and (mine_post["links"] as Array).size() == 1, "typed post with its link is in the chat")
	check(view.game.hall_say("again", [], int(Time.get_unix_time_from_system())) != "", "posting has a cooldown")
	var t1: int = t0 + 100
	check(view.game.hall_say("same", [], t1) == "" and view.game.hall_say("same", [], t1 + TradeHall.SAY_COOLDOWN + 1) != "", "repeating a post is refused")
	# An NPC buyer messages about the timber; agreeing leads to a trade request.
	hall.pending.clear()
	hall.deals.clear()
	hall._npc_opener("Hesk", "timber", false, 40, 6.0, hall.fair("timber", t1), t1)
	var t2: int = t1 + 60
	var got_pm: bool = false
	for event in view.game.hall_tick(t2):
		got_pm = got_pm or (str(event["type"]) == "pm" and str(event["trader"]) == "Hesk")
	check(got_pm and not hall.conversation("Hesk").is_empty(), "an NPC messages about the linked item")
	var deal: Haggle = hall.deals["Hesk"]
	check(not deal.they_sell and deal.is_open(), "the NPC is negotiating to buy")
	check(view.game.hall_pm("Hesk", "ok deal", [], t2) == "", "the company replies by message")
	var requested: bool = false
	for event in view.game.hall_tick(t2 + 30):
		requested = requested or str(event["type"]) == "trade_request"
	check(deal.is_agreed() and requested and hall.session != null, "agreeing brings a trade request")
	# Two-step confirm: lock, then accept. The trader only locks a side that covers the deal.
	var gold_before: int = view.game.gold
	view.game.trade_set_goods("timber", deal.agreed_qty - 1, t2 + 30)
	view.game.trade_lock(t2 + 30)
	view.game.hall_tick(t2 + 40)
	check(hall.session != null and hall.session.my_locked and not hall.session.their_locked, "a short side is not locked by the trader")
	view.game.trade_set_goods("timber", deal.agreed_qty, t2 + 40)
	check(int(hall.session.mine_goods["timber"]) == deal.agreed_qty - 1, "a locked side cannot be edited")
	view.game.trade_unlock(t2 + 40)
	check(not hall.session.my_locked, "unlocking")
	view.game.trade_set_goods("timber", deal.agreed_qty, t2 + 40)
	view.game.trade_lock(t2 + 40)
	view.game.hall_tick(t2 + 43)
	check(hall.session.both_locked(), "the trader locks a side that covers the deal")
	check(not view.game.trade_accept(int(hall.session.locked_at)), "accepting waits a moment after both lock")
	view.game.trade_unlock(int(hall.session.locked_at) + 1)
	check(not hall.session.my_locked and not hall.session.their_locked, "any change unlocks both sides")
	view.game.trade_lock(t2 + 50)
	view.game.hall_tick(t2 + 53)
	check(view.game.trade_accept(int(hall.session.locked_at) + TradeSession.ACCEPT_DELAY), "accept once both are locked and the pause has passed")
	var traded: bool = false
	for event in view.game.hall_tick(t2 + 60):
		traded = traded or str(event["type"]) == "trade_done"
	var tax_paid: int = int(round(float(deal.agreed_total) * TradeHall.TAX))
	check(traded and view.game.gold == gold_before + deal.agreed_total - tax_paid, "the trade pays out after the 3% tax")
	check(int(view.game.resources["timber"]) == 60 - deal.agreed_qty, "the goods leave the warehouse")
	# Buying gear from an NPC post: message, agree, pay, receive the item.
	var t3: int = t2 + 200
	hall._post({"t": t3, "from": "Dunny", "kind": "bargain", "side": "wts", "good": "gear:steel_sword", "qty": 1, "price": 100})
	view.game.gold = 1000
	hall.rng.seed = 9
	var replied: bool = false
	var attempts: int = 0
	while not replied and attempts < 6:
		hall.deals.erase("Dunny")
		view.game.hall_pm("Dunny", "I'll take it for 100g", [], t3)
		for event in view.game.hall_tick(t3 + 60):
			replied = replied or str(event["type"]) == "pm"
		attempts += 1
		t3 += 61
	check(replied, "the trader answers a message about their post")
	var sword_deal: Haggle = hall.deals["Dunny"]
	check(sword_deal.they_sell and sword_deal.is_agreed(), "offering their price strikes a deal")
	view.game.hall_tick(t3 + 60)
	check(hall.session != null and hall.session.their_gear.has("steel_sword"), "their side holds the sword")
	var gear_before: int = view.game.equipment_inventory.size()
	view.game.trade_set_gold(sword_deal.agreed_total, t3 + 60)
	view.game.trade_lock(t3 + 60)
	view.game.hall_tick(t3 + 63)
	view.game.trade_accept(t3 + 63 + TradeSession.ACCEPT_DELAY)
	view.game.hall_tick(t3 + 70)
	check(view.game.equipment_inventory.size() == gear_before + 1 and view.game.gold == 1000 - sword_deal.agreed_total, "buying gear by trade")
	# Sending a trade request: refused politely until a price is agreed, accepted after.
	var t4: int = t3 + 200
	hall.deals.erase("Wren")
	check(view.game.hall_request_trade("Wren", t4) == "", "a trade request can be sent")
	view.game.hall_tick(t4 + 10)
	check(hall.session == null or not hall.session.is_open(), "no trade without an agreed price")
	check(str((hall.conversation("Wren").back() as Dictionary)["from"]) == "Wren", "the trader answers the request")
	var agreed := Haggle.make("Wren", "hawker", "copper", true, 5, 20, 20.0, hall.rng)
	agreed.item_name = "Copper Ore"
	agreed.take(5)
	hall.deals["Wren"] = agreed
	view.game.hall_request_trade("Wren", t4 + 20)
	view.game.hall_tick(t4 + 30)
	check(hall.session != null and hall.session.is_open() and hall.session.trader == "Wren", "an agreed trader accepts the request")
	view.game.trade_cancel(t4 + 30)
	# Blocking hides a trader and stops their messages.
	view.game.hall_block("Marrow")
	check(hall.is_blocked("Marrow"), "block works")
	var reloaded := MoneyMercsState.new()
	check(reloaded.hall.is_blocked("Marrow"), "the block list is saved")
	view.game.hall_block("Marrow", false)
	view._nav_to("market")
	# Harlow Mines: the ordinary site planner, crew selection, fund state.
	view._nav_to("hq")
	view._turn_to("harlow")
	check(view.page == "site" and view.selected_site == "harlow", "Harlow opens its site planner")
	check(view.flip_art.visible, "page flip playing")
	var hr: Control = view.right_leaf.get_child(0)
	var hl: Control = view.left_leaf.get_child(0)
	(hl.get_node("Margin/Content/Filter/All") as Button).pressed.emit()
	hl = view.left_leaf.get_child(0)
	check(view.crew_filter == "all", "crew filter: everyone")
	var roster: VBoxContainer = hl.get_node("Margin/Content/Roster/Items")
	check(roster.get_child_count() == view.game.available_guild_workers().size(), "a roster card per free mercenary")
	check(roster.get_child(0).scene_file_path.ends_with("/rows/roster_card.tscn"), "roster card scene")
	check((hr.get_node("Margin/Content/Fund") as Button).disabled, "fund disabled with no crew")
	(roster.get_child(0) as Button).pressed.emit()
	check(view.selected_crew.size() == 1, "card click assigns")
	hr = view.right_leaf.get_child(0)
	check((hr.get_node("Margin/Content/Crew") as Label).text.begins_with("Crew 1 of 3"), "crew line names the crew")
	check(not (hr.get_node("Margin/Content/Fund") as Button).disabled, "fund enabled with a crew")
	(view.left_leaf.get_child(0).get_node("Margin/Content/Filter/Trade") as Button).pressed.emit()
	check(view.crew_filter == "trade", "crew filter: workers")
	# Orders toggle, including the long orders.
	hr = view.right_leaf.get_child(0)
	(hr.get_node("Margin/Content/Orders/Cautious") as Button).pressed.emit()
	check(view.tactic == "Cautious", "orders toggle")
	hr = view.right_leaf.get_child(0)
	(hr.get_node("Margin/Content/Away/Overnight") as Button).pressed.emit()
	check(view.tactic == "Overnight", "Overnight toggle")
	# Live tick updates without rebuilding the page.
	var before: Control = view.left_leaf.get_child(0)
	view._live_tick()
	check(view.left_leaf.get_child(0) == before, "live tick keeps the page")
	# Tab strip stays above the flip; flip finishes.
	check(view.tab_overlay.visible and view.tab_icons_layer.visible, "tabs visible during flip")
	await create_timer(0.6).timeout
	check(not view.flip_art.visible, "page flip finished")
	# Escape closes the journal onto its back cover with the pause menu.
	var pause_menu: Control = journal.get_node("PauseMenu")
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	Input.parse_input_event(escape)
	await create_timer(1.0).timeout
	check(pause_menu.visible and pause_menu.is_open(), "escape opens pause menu")
	check(paused, "game paused behind the menu")
	check(not view.book_art.visible and not view.left_leaf.visible and not view.tab_host.visible, "book hidden while closed")
	check(pause_menu.get_node("Cover/Plate").visible, "bookplate shown on the cover")
	pause_menu._show_settings(true)
	check(pause_menu.settings_view.visible and not pause_menu.main_view.visible, "settings view")
	Input.parse_input_event(escape)
	await create_timer(0.1).timeout
	check(pause_menu.main_view.visible and pause_menu.is_open(), "escape leaves settings first")
	Input.parse_input_event(escape)
	await create_timer(1.0).timeout
	check(not pause_menu.visible and not pause_menu.is_open(), "escape resumes")
	check(not paused, "game unpaused")
	check(view.book_art.visible and view.left_leaf.visible and view.tab_host.visible, "book restored")
	check(not view.flip_art.visible, "page flip stays hidden after resume")
	# Every catalog item and every warehouse good has an icon in the slots and lists.
	for item_key in Catalog.items().keys():
		check(view._recipe_icon(str(item_key)) != null, "icon for item " + str(item_key))
	for good in MoneyMercsState.RESOURCE_ORDER:
		check(view._item_icon(str(good)) != null, "icon for good " + str(good))
	for slot in Gear.SLOTS:
		check(view.EMPTY_SLOT_ICONS.get(slot) != null, "empty icon for " + slot)
	# The Workshop: buy a blueprint, gather materials, craft, and find it in the storeroom.
	view.game.reset_company()
	view.game.gold = 1000
	view.workshop_tab = "craft"
	view._nav_to("workshop")
	check(view.left_leaf.get_child(0).scene_file_path.ends_with("/personnel_workshop_left.tscn"), "workshop page")
	view._buy_blueprint("iron_war_axe")
	check(view.game.knows("iron_war_axe"), "blueprint bought from the workshop")
	view.game.resources["iron"] = 2
	view.game.resources["timber"] = 2
	view.selected_recipe = "iron_war_axe"
	view.craft_filter = "weapons"
	view._refresh()
	check(view.left_leaf.get_child(0).get_node("Margin/Content/Known/Items").get_child_count() == 2, "weapons filter: a heading and the axe")
	view.craft_filter = "all"
	view._refresh()
	var craft_button: Button = view.right_leaf.get_child(0).get_node("Margin/Content/Craft")
	check(not craft_button.disabled, "craft button ready")
	craft_button.pressed.emit()
	check(view.game.equipment_inventory.size() == 1 and str(view.game.equipment_inventory[0]["key"]) == "iron_war_axe", "crafted into the Warehouse")
	# The Warehouse (Workshop): everything owned, searchable, with details and actions.
	view._turn_to("warehouse")
	await create_timer(0.3).timeout
	check(view.page == "workshop" and view.workshop_tab == "store", "the old warehouse link opens the Workshop's Warehouse")
	check(view.book_art.texture.resource_path.ends_with("/%d.png" % (view.PHYSICAL_TAB_PAGES.find("workshop") + 2)), "the Workshop bookmark is open")
	view.game.resources["timber"] = 42
	view.store_find = ""
	view.store_filter = "all"
	view._refresh()
	var wl: Control = view.left_leaf.get_child(0)
	var wr: Control = view.right_leaf.get_child(0)
	var names: Array[String] = []
	for row in wl.get_node("Margin/Content/List/Items").get_children():
		if row.has_node("Body/Info/Name"):
			names.append((row.get_node("Body/Info/Name") as Label).text)
	check(names.any(func(n): return n.contains("War Axe")), "the Warehouse lists the crafted axe (%s)" % str(names))
	check(names.has("Ashwood  ×42"), "the Warehouse lists goods with their count")
	check(view.game.crew.is_empty() or names.size() > 2, "worn gear is listed too")
	check((wl.get_node("Margin/Content/Summary") as Label).text.contains("42 goods") or (wl.get_node("Margin/Content/Summary") as Label).text.contains("goods"), "a summary of everything")
	var find: LineEdit = wl.get_node("Margin/Content/Find")
	find.text = "ashw"
	find.text_changed.emit("ashw")
	var after: Array[String] = []
	for row in wl.get_node("Margin/Content/List/Items").get_children():
		if row.has_node("Body/Info/Name"):
			after.append((row.get_node("Body/Info/Name") as Label).text)
	check(after == ["Ashwood  ×42"], "search narrows the list (%s)" % str(after))
	check((wr.get_node("Margin/Content/Head/Id/Name") as Label).text == "Ashwood", "the found good is chosen on the right")
	check((wr.get_node("Margin/Content/Actions/Primary") as Button).text.begins_with("Sell in the Market"), "goods can be sold from here")
	check((wr.get_node("Margin/Content/Where") as Label).text.contains("Cinderwood"), "it says where the good comes from")
	find.text_changed.emit("no such thing")
	check((wl.get_node("Margin/Content/Empty") as Control).visible and (wr.get_node("Margin/Content/Empty") as Control).visible, "nothing found is said plainly")
	view.store_find = ""
	view.store_filter = "weapons"
	view._refresh()
	wr = view.right_leaf.get_child(0)
	check((wr.get_node("Margin/Content/Head/Id/Name") as Label).text.contains("War Axe"), "the Arms filter picks the axe")
	check((wr.get_node("Margin/Content/Actions/Secondary") as Button).text.begins_with("Sell"), "spare gear can be sold from here")
	view.store_filter = "all"
	view.game.reset_company()
	if failures > 0:
		push_error("%d BookUI checks failed." % failures)
		quit(1)
		return
	# Item lookup: any item opens a card saying where it comes from and what it's for.
	view._open_lookup("perch")
	var lookup: Control = view._lookup_card()
	check(lookup.visible, "lookup card opens")
	check((lookup.get_node("Card/Margin/Body/From") as Label).text.contains("The Cinder Pool"), "perch comes from the Cinder Pool")
	check((lookup.get_node("Card/Margin/Body/Uses") as Label).text.contains("Grilled Ash Perch"), "perch is used for grilled perch")
	(lookup.get_node("Card/Margin/Body/Actions/Trade") as Button).pressed.emit()
	check(not lookup.visible and view.page == "market" and view.selected_market_item == "perch", "Trade opens it in the Market")
	await create_timer(0.6).timeout  # let the page turn finish
	# Recipes on an ingredient: the Workshop narrowed to recipes that use it.
	view._open_lookup("iron")
	var recipes_button := lookup.get_node("Card/Margin/Body/Actions/Craft") as Button
	check(recipes_button.visible and recipes_button.text.begins_with("Recipes"), "iron offers its recipes")
	recipes_button.pressed.emit()
	await create_timer(0.6).timeout
	check(view.page == "workshop" and view.workshop_focus == "uses:iron", "Recipes narrows the Workshop to iron")
	var listed: VBoxContainer = view.right_leaf.get_child(0).get_node("Margin/Content/Blueprints/Items") if view.workshop_tab == "shop" else view.left_leaf.get_child(0).get_node("Margin/Content/Known/Items")
	check(listed.get_child_count() > 0, "some recipes use iron")
	check((view.left_leaf.get_child(0).get_node("Margin/Content/Focus") as Control).visible or (view.right_leaf.get_child(0).get_node("Margin/Content/Focus") as Control).visible, "the focus line says what's shown")
	# Recipe on an unknown craftable item: the Shop, showing just that blueprint.
	view._open_lookup("iron_war_axe")
	(lookup.get_node("Card/Margin/Body/Actions/Craft") as Button).pressed.emit()
	check(view.workshop_tab == "shop" and view.right_leaf.get_child(0).get_node("Margin/Content/Blueprints/Items").get_child_count() == 1, "Recipe shows just that blueprint")
	view._nav_to("hq")
	check(view.workshop_focus == "", "leaving the Workshop clears the focus")
	view._open_lookup("hand_axe")
	check((lookup.get_node("Card/Margin/Body/From") as Label).text.contains("quartermaster"), "the hand axe is sold by the quartermaster")
	view._close_lookup()
	check(not lookup.visible, "lookup card closes")
	# Expedition charters: signed in order from the Ledger, the third needs Respected reputation.
	view.game.reset_company()
	view.game.gold = 20000
	view._nav_to("finance")
	var sign := view.left_leaf.get_child(0).get_node("Margin/Content/Slots/Expand") as Button
	check(not sign.disabled, "first charter can be signed")
	sign.pressed.emit()
	check(view.game.expedition_slots == 2 and view.game.upgrades.has("charter_1"), "charter I opens a second slot")
	check(view.game.charter_block().begins_with("Needs Known"), "charter II waits on reputation")
	check((view.left_leaf.get_child(0).get_node("Margin/Content/Slots/Expand") as Button).disabled, "sign button waits too")
	view.game.reputation = 500
	check(view.game.build_upgrade("charter_3").begins_with("Charters are signed in order"), "charters go in order")
	check(view.game.expand_operations().contains("signed") and view.game.expedition_slots == 3, "charter II opens a third slot")
	# The Auction House: browse and buy, post a listing, see it under Yours.
	view.game.reset_company()
	view.game.gold = 3000
	view.game.resources["timber"] = 100
	view._nav_to("auction")
	check(view.page == "auction" and view._active_tab_index() == 4, "auction house sits under the Market tab")
	view.auction_tab = "browse"
	view.ah_item = "timber"
	view._refresh()
	var ah_right: Control = view.right_leaf.get_child(0)
	check(ah_right.scene_file_path.ends_with("/auction_browse_right.tscn"), "browse spread")
	var ah_rows := ah_right.get_node("Margin/Content/Listings/Items") as VBoxContainer
	check(ah_rows.get_child_count() > 0, "timber listings shown")
	var timber_before: int = int(view.game.resources["timber"])
	(ah_rows.get_child(0).get_node("Row/Primary") as Button).pressed.emit()
	check(int(view.game.resources["timber"]) > timber_before, "buying from a listing adds timber")
	view.auction_tab = "sell"
	view.ah_sell_item = "timber"
	view._refresh()
	var post := view.right_leaf.get_child(0).get_node("Margin/Content/Post") as Button
	check(post.text.begins_with("Post"), "sell spread offers to post")
	post.pressed.emit()
	check(view.game.auction.listings.size() == 1, "posting from the Sell tab lists it")
	view.auction_tab = "yours"
	view._refresh()
	check(view.left_leaf.get_child(0).get_node("Margin/Content/Listings/Items").get_child_count() == 1, "the listing shows under Yours")
	view.game.reset_company()
	# Calder Keep: the planner gates on kit, enters, and the run waits at the stairs for orders.
	view.game.reset_company()
	view.game.gold = 5000
	var fighter: Dictionary = view.game.recruitment_board()[0]
	view._hire(str(fighter["id"]))
	var fm: Dictionary = view.game.merc_by_id(str(fighter["id"]))
	view._open_dungeon("calder_keep")
	check(view.page == "dungeon" and view.left_leaf.get_child(0).scene_file_path.ends_with("/dungeon_left.tscn"), "dungeon planner opens")
	view._set_dungeon_filter("all")
	var dcard := view.left_leaf.get_child(0).get_node("Margin/Content/Roster/Items").get_child(0) as Button
	check(dcard.disabled and (dcard.get_node("Body/Tag") as Label).text.begins_with("Gear score"), "unarmed recruit is turned away on gear score")
	for k in ["steel_sword", "chainmail", "iron_helm", "leather_boots"]:
		fm["equipment"][Gear.slot_of(k)] = view.game.make_item(k, "common")
	view._refresh()
	view._toggle_crew(true, str(fighter["id"]))
	var enter := view.right_leaf.get_child(0).get_node("Margin/Content/Enter") as Button
	check(not enter.disabled, "an armed crew can enter (%s)" % (view.right_leaf.get_child(0).get_node("Margin/Content/Reason") as Label).text)
	check((view.right_leaf.get_child(0).get_node("Margin/Content/Floors/F0/Body/Odds") as Label).text.ends_with("%"), "floor odds shown")
	enter.pressed.emit()
	check(view.game.missions.size() == 1 and str(view.game.missions[0]["region"]) == "dungeon", "crew entered the keep")
	check(view.left_leaf.get_child(0).scene_file_path.ends_with("/run_left.tscn"), "the run spread shows the crew inside")
	var run: Dictionary = view.game.missions[0]
	view.game.complete_due(int(run["floor_end"]) + 1)
	view._refresh()
	if str(run["stage"]) == "await":
		var prompt := view.right_leaf.get_child(0).get_node("Margin/Content/Prompt") as Control
		check(prompt.visible, "check-in prompt shows")
		check(view._needs().any(func(n): return str(n["title"]).contains("waiting")), "Today lists the check-in")
		(prompt.get_node("Body/Buttons/Out") as Button).pressed.emit()
		check(str(run["stage"]) == "out", "taking it out sends the crew home")
	view.game.complete_due(int(run["finish"]) + 1)
	check(view.game.missions.is_empty() and str(view.game.reports[0].get("dungeon", "")) == "calder_keep", "run reported")
	view._refresh()
	await create_timer(0.8).timeout
	view.game.reset_company()
	if failures > 0:
		push_error("%d BookUI checks failed." % failures)
		quit(1)
		return
	print("BookUI page navigation, equipment desk, merchant selection, and page-turn assets passed.")
	quit(0)
