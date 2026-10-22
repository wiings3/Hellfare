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
	# The game is mouse driven, so startup and focus changes must restore the cursor.
	assert(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	view.notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	assert(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	assert(view.get_script().resource_path == "res://scripts/book_ui.gd")
	# Presentation should inherit the active book shell and the lean action layer,
	# not a whole previous-generation UI implementation.
	var shell_script: Script = view.get_script().get_base_script()
	assert(shell_script.resource_path == "res://scripts/book_shell.gd")
	assert(shell_script.get_base_script().resource_path == "res://scripts/game_actions.gd")
	view.game.reset_company()
	view._nav_to("hq")
	assert(view.left_leaf.size.x >= 500)
	assert(view.right_leaf.size.x >= 470)
	assert(view.tab_host.get_child_count() == 6)
	assert(view.tab_book_textures.size() == 7)
	assert(view.tab_strip_textures.size() == 7)
	assert(view.tab_overlay.get_index() > view.flip_art.get_index())
	assert(view.tab_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(view.tab_overlay.position == Vector2(144, 30))
	assert(is_equal_approx(view.tab_overlay.size.x,
		1326.0 * 51.0 / 710.0))
	assert(view.tab_overlay.size.y == 870)
	# All six icon textures are true 16x16 PNGs above the page-turn art.
	assert(view.tab_icons_layer.get_child_count() == 6)
	assert(view.tab_icons_layer.get_index() > view.tab_overlay.get_index())
	assert(view.tab_icons_layer.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	var icon_names: Array[String] = ["company", "expeditions", "personnel", "exchange", "finances", "chronicle"]
	for i in range(6):
		var icon: TextureRect = view.tab_icons_layer.get_node("TabIcon" + str(i))
		assert(icon.texture.get_size() == Vector2(16, 16))
		assert(icon.texture.resource_path.ends_with("/tab_icons/" + icon_names[i] + ".png"))
		assert(icon.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
		assert(icon.mouse_filter == Control.MOUSE_FILTER_IGNORE)
		assert(icon.position == Vector2(168, 196 + 90 * i))
		assert(icon.size == Vector2(32, 32))
	assert((view.book_art.texture as AtlasTexture).atlas.resource_path.contains("/Without icons/"))
	assert((view.tab_overlay.texture as AtlasTexture).atlas.resource_path.contains("/Without icons/"))
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
	assert((view.tab_overlay.texture as AtlasTexture).atlas.resource_path.ends_with("/6.png"))
	view._restore_tab_art()
	assert((view.book_art.texture as AtlasTexture).atlas.resource_path.ends_with("/2.png"))
	assert((view.tab_overlay.texture as AtlasTexture).atlas.resource_path.ends_with("/2.png"))
	var personnel_tab: Button = view.tab_host.get_node("ChapterTab2")
	personnel_tab.pressed.emit()
	assert(view.page == "roster")
	assert((view.book_art.texture as AtlasTexture).atlas.resource_path.ends_with("/4.png"))
	assert((view.tab_overlay.texture as AtlasTexture).atlas.resource_path.ends_with("/4.png"))
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
	# The icon-free tab strip is a later sibling and stays drawn over flips.

	assert(view.tab_overlay.visible)
	assert(view.tab_overlay.get_index() > view.flip_art.get_index())
	assert(view.tab_icons_layer.visible)
	assert(view.tab_icons_layer.get_index() > view.tab_overlay.get_index())
	assert((view.tab_overlay.texture as AtlasTexture).atlas.resource_path.ends_with("/3.png"))
	await create_timer(0.5).timeout
	assert(not view.flip_art.visible)
	view.game.reset_company()
	print("BookUI page navigation, equipment desk, merchant selection, and page-turn assets passed.")
	quit(0)
