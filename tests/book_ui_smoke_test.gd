extends SceneTree
## End-to-end BookUI navigation, layout structure and Harlow/Company bindings.
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
	var company_left: Control = view.left_leaf.get_child(0)
	var company_right: Control = view.right_leaf.get_child(0)
	check(company_left.scene_file_path == "res://scenes/journal/pages/company_left.tscn", "company left scene")
	check(company_right.scene_file_path == "res://scenes/journal/pages/company_right.tscn", "company right scene")
	check(view.money_label.text.contains("350"), "purse shows starting gold")
	check((company_left.get_node("Margin/Content/Hero/Worth/WorthValue") as Label).text.contains("350"), "worth shown")
	check(company_left.get_node("Margin/Content/Goods").get_child_count() == MoneyMercsState.RESOURCE_ORDER.size(), "warehouse slot per resource")
	check((company_left.get_node("Margin/Content/AdviceAction") as Button).visible, "advice offers a next step")
	check((company_right.get_node("Margin/Content/EmptyReport") as Control).visible, "empty report note")
	check(company_right.get_node("Margin/Content/Expeditions").get_child_count() == view.game.expedition_slots, "one row per expedition slot")
	# Hover previews another tab, then restores.
	view._preview_tab(4)
	check(view.book_art.texture.resource_path.ends_with("/6.png"), "hover preview sheet")
	view._restore_tab_art()
	check(view.book_art.texture.resource_path.ends_with("/2.png"), "restored sheet")
	(view.tab_host.get_node("ChapterTab2") as Button).pressed.emit()
	check(view.page == "roster", "personnel tab navigates")
	check(view.book_art.texture.resource_path.ends_with("/4.png"), "personnel tab art")
	# Every chapter mounts its scenes.
	var scene_by_chapter := {
		"harlow": ["harlow_left", "harlow_right"],
		"expeditions": ["board_left", "board_right"],
		"contracts": ["regions_left", "regions_right"],
		"site": ["site_left", "site_right"],
		"roster": ["personnel_employed_left", "personnel_employed_right"],
		"market": ["exchange_left", "exchange_right"],
		"finance": ["finance_left", "finance_right"],
		"ledger": ["chronicle_left", "chronicle_right"],
		"guildwork": ["guildwork_left", "guildwork_right"]
	}
	for chapter in scene_by_chapter:
		view._nav_to(chapter)
		var paths: Array = scene_by_chapter[chapter]
		check(view.left_leaf.get_child(0).scene_file_path.ends_with("/pages/" + str(paths[0]) + ".tscn"), chapter + " left")
		check(view.right_leaf.get_child(0).scene_file_path.ends_with("/pages/" + str(paths[1]) + ".tscn"), chapter + " right")
		check(view.book_art.texture.resource_path.ends_with("/" + str(view._active_tab_index() + 2) + ".png"), chapter + " tab art")
		check(not view.title_label.text.is_empty(), chapter + " title")
	# Personnel and armory flows.
	view._nav_to("roster")
	view._set_roster_tab("recruits")
	check(view.left_leaf.get_child(0).scene_file_path.ends_with("/personnel_recruits_left.tscn"), "recruit page")
	view._hire("garrick")
	view._hire("oswin")
	check(view.game.crew.size() == 2, "hired two")
	view._outfit("garrick")
	check(view.roster_tab == "armory", "armory tab")
	check(view.right_leaf.get_child(0).get_node("Margin/Content/Shop/Items").get_child_count() == MercsV05.ITEMS.size(), "armory catalog")
	view._nav_to("roster")
	view._set_roster_tab("employed")
	var roster_grid: GridContainer = view.left_leaf.get_child(0).get_node("Margin/Content/List/Items")
	check(roster_grid.get_child_count() == view.game.crew.size(), "portrait card per mercenary")
	check((view.right_leaf.get_child(0).get_node("Margin/Content/Head/Id/Name") as Label).text == str(view.game.crew[0]["name"]), "dossier shows selection")
	view._nav_to("finance")
	check((view.left_leaf.get_child(0).get_node("Margin/Content/Ledger/Rows/Total/Value") as Label).text == view._money(view.game.wealth()), "finance worth matches")
	view._nav_to("ledger")
	check((view.left_leaf.get_child(0).get_node("Margin/Content/Empty") as Control).visible == view.game.reports.is_empty(), "chronicle empty state")
	view._nav_to("contracts")
	check(view.left_leaf.get_child(0).get_node("Margin/Content/List/Items").get_child_count() == MoneyMercsState.REGIONS.size() + 1, "contract cards")
	# Logging: the board lists the copse; the site planner forecasts a profit for a woodcutter.
	view._nav_to("expeditions")
	check(view.left_leaf.get_child(0).scene_file_path.ends_with("/board_left.tscn"), "expedition board")
	var cutter: Dictionary = {}
	for candidate in view.game.recruitment_board():
		if str(candidate["role"]) == "Woodcutter":
			cutter = candidate
			break
	check(not cutter.is_empty(), "a woodcutter is always on the board")
	view.game.gold = 900
	view._hire(str(cutter["id"]))
	check(TradeSkills.level_of(view.game.merc_by_id(str(cutter["id"])), "logging") >= 1, "new woodcutter has logging skill")
	view.selected_site = "mossward_copse"
	view._nav_to("site")
	view._toggle_crew(true, str(cutter["id"]))
	var sr: Control = view.right_leaf.get_child(0)
	check(not (sr.get_node("Margin/Content/Fund") as Button).disabled, "copse can be funded with a woodcutter")
	check(int(view.game.site_forecast("mossward_copse", view._selected_available(), "Balanced")["profit"]) > 0, "copse forecast is profitable")
	view._dispatch_site()
	check(view.game.missions.size() == 1 and str(view.game.missions[0].get("site", "")) == "mossward_copse", "copse expedition dispatched")
	view.game.complete_due(int(Time.get_unix_time_from_system()) + 10000)
	check(int(view.game.resources.get("timber", 0)) > 0, "timber delivered")
	check(int(view.game.reports[0].get("value", 0)) > 0, "report records haul value")
	var before_price: int = view.game.sell_price("timber")
	view.game.trade("timber", false, int(view.game.resources["timber"]))
	check(view.game.sell_price("timber") <= before_price, "selling saturates the merchants")
	view._nav_to("market")
	check(view.left_leaf.get_child(0).get_node("Margin/Content/List/Items").get_child_count() == MoneyMercsState.RESOURCE_ORDER.size(), "market rows")
	view._choose_commodity("iron")
	check((view.right_leaf.get_child(0).get_node("Margin/Content/Head/Id/Name") as Label).text == "Iron Ore", "trade desk follows selection")
	# Harlow: unsurveyed, crew selection, fund state.
	view._nav_to("hq")
	view._turn_to("harlow")
	check(view.page == "harlow", "turned to harlow")
	check(view.flip_art.visible, "page flip playing")
	var hl: Control = view.left_leaf.get_child(0)
	var hr: Control = view.right_leaf.get_child(0)
	check((hl.get_node("Margin/Content/Site/Veil") as Control).visible, "unsurveyed veil")
	check((hl.get_node("Margin/Content/Scout/Row/Info/SendScout") as Button).visible, "send scout offered")
	var roster: VBoxContainer = hr.get_node("Margin/Content/Planning/Roster/Items")
	check(roster.get_child_count() == 2, "two roster cards")
	check(roster.get_child(0).scene_file_path.ends_with("/rows/roster_card.tscn"), "roster card scene")
	check((hr.get_node("Margin/Content/Fund") as Button).disabled, "fund disabled with no crew")
	check((hr.get_node("Margin/Content/Reason") as Label).visible, "reason shown when disabled")
	(roster.get_child(0) as Button).pressed.emit()
	check(view.selected_crew.size() == 1, "card click assigns")
	hr = view.right_leaf.get_child(0)
	check((hr.get_node("Margin/Content/Planning/Slots/Slot0/Body/Name") as Label).text != "Empty", "slot shows assigned merc")
	check(not (hr.get_node("Margin/Content/Fund") as Button).disabled, "fund enabled with a miner")
	# Orders toggle.
	(hr.get_node("Margin/Content/Planning/Orders/Cautious") as Button).pressed.emit()
	check(view.tactic == "Cautious", "orders toggle")
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
	# Every item the quartermaster sells must have an icon in the slots and lists.
	for item_key in MercsV05.ITEMS.keys():
		check(view._gear_icon(str(item_key)) != null, "icon for item " + str(item_key))
	view.game.reset_company()
	if failures > 0:
		push_error("%d BookUI checks failed." % failures)
		quit(1)
		return
	print("BookUI page navigation, equipment desk, merchant selection, and page-turn assets passed.")
	quit(0)
