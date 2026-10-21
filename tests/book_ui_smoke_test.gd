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
	assert(view.tab_host.get_child_count() == 6)
	assert(view.tab_book_textures.size() == 7)
	assert((view.book_art.texture as AtlasTexture).atlas.resource_path.ends_with("/2.png"))
	# Source-art alignment: first tab begins at (153, 182), every subsequent tab 90 px lower.
	assert(view.tab_host.position == Vector2(151, 182))
	assert(view.title_label.position.x >= view.left_leaf.position.x)
	assert(view.money_label.position.x >= view.right_leaf.position.x)
	assert(view.body_font.font_names[0] == "Palatino Linotype")
	# Six actual page tabs must be the buttons, not a row of text labels.
	for i in range(6):
		var tab: Button = view.tab_host.get_node("ChapterTab" + str(i))
		assert(tab.name == "ChapterTab" + str(i))
		assert(tab.text.is_empty())
		assert(tab.tooltip_text.length() > 5)
		assert(tab.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND)
		assert(tab.position == Vector2(2, float(i) * 90.0))
		assert(tab.size == Vector2(80, 60))
		# The tab never paints its own colored hover, pressed, or focus rectangle.
		for state in ["normal", "hover", "pressed", "focus"]:
			assert(tab.get_theme_stylebox(state) is StyleBoxEmpty)
	# Hover previews the original selected sprite, then restores the active tab.
	view._preview_tab(4)
	assert((view.book_art.texture as AtlasTexture).atlas.resource_path.ends_with("/6.png"))
	view._restore_tab_art()
	assert((view.book_art.texture as AtlasTexture).atlas.resource_path.ends_with("/2.png"))
	var personnel_tab: Button = view.tab_host.get_node("ChapterTab2")
	personnel_tab.pressed.emit()
	assert(view.page == "roster")
	assert((view.book_art.texture as AtlasTexture).atlas.resource_path.ends_with("/4.png"))
	assert(view.money_label.text.contains("350"))
	for chapter in ["harlow", "expeditions", "roster", "market", "finance", "ledger", "guildwork"]:
		view._nav_to(chapter)
		assert(view.page == chapter)
		assert(view.left_leaf.get_child_count() > 0)
		assert(view.right_leaf.get_child_count() > 0)
		assert((view.book_art.texture as AtlasTexture).atlas.resource_path.ends_with(
			"/" + str(view._active_tab_index() + 2) + ".png"))
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
