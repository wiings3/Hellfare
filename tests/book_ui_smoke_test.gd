extends SceneTree
## End-to-end BookUI navigation and retained state, isolated to CI profiles.
func _initialize() -> void:
	if OS.get_environment("CI") != "true":
		push_error("BookUI tests must only run in CI.")
		quit(1)
		return
	call_deferred("_verify")

func _verify() -> void:
	var view: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(view)
	assert(view.get_script().resource_path == "res://scripts/book_ui.gd")
	view.game.reset_company()
	view._nav_to("hq")
	assert(view.left_leaf.size.x >= 500)
	assert(view.right_leaf.size.x >= 470)
	assert(view.tab_host.get_child_count() == 7)
	# Six actual page tabs must be the buttons, not a row of text labels.
	for i in range(6):
		var tab: Button = view.tab_host.get_node("ChapterTab" + str(i))
		assert(tab.name == "ChapterTab" + str(i))
		assert(tab.text.is_empty())
		assert(tab.tooltip_text.length() > 5)
		assert(tab.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND)
	var personnel_tab: Button = view.tab_host.get_node("ChapterTab2")
	personnel_tab.pressed.emit()
	assert(view.page == "roster")
	assert(view.money_label.text.contains("350"))
	for chapter in ["harlow", "expeditions", "roster", "market", "finance", "ledger", "guildwork"]:
		view._nav_to(chapter)
		assert(view.page == chapter)
		assert(view.left_leaf.get_child_count() > 0)
		assert(view.right_leaf.get_child_count() > 0)
	assert(view.right_heading.text == "WORK ASSIGNMENTS")
	view._nav_to("roster")
	view._set_roster_tab("recruits")
	assert(view.roster_tab == "recruits")
	view._hire("garrick")
	assert(view.game.crew.size() == 1)
	view._outfit("garrick")
	assert(view.roster_tab == "armory")
	assert(view.selected_merc == "garrick")
	view._nav_to("market")
	view._choose_commodity("iron")
	assert(view.selected_market_item == "iron")
	view._nav_to("hq")
	view._turn_to("harlow")
	assert(view.page == "harlow")
	assert(view.flip_art.visible)
	await create_timer(0.5).timeout
	assert(not view.flip_art.visible)
	view.game.reset_company()
	print("BookUI page navigation, equipment desk, merchant selection, and page-turn assets passed.")
	quit(0)
