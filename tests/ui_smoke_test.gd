extends SceneTree
## UI navigation and player interaction smoke coverage.
## Restricted to GitHub Actions to avoid resetting a real player's local save.

func _initialize() -> void:
	if OS.get_environment("CI") != "true":
		push_error("This test intentionally runs in CI only.")
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	assert(scene != null)
	var view: Control = scene.instantiate()
	root.add_child(view)
	assert(view.game != null)
	view.game.reset_company()
	view._nav_to("hq")
	assert(view.header_gold.text.contains("350"))
	view._open_recruitment()
	assert(view.roster_tab == "recruits")
	assert(view.page == "roster")
	view._hire("garrick")
	assert(view.game.crew.size() == 1)
	assert(view.roster_tab == "employed")
	view._nav_to("expeditions")
	view._select_region("lowlands")
	view._toggle_crew(true, "garrick")
	# Defer-based updates from checkbox handlers are allowed to complete.
	await process_frame
	assert(view.selected_crew.has("garrick"))
	view._dispatch()
	assert(view.game.missions.size() == 1)
	assert(view.game.free_crew() == 0)
	view._nav_to("hq")
	view._nav_to("market")
	view._select_item("iron")
	view._nav_to("roster")
	view._nav_to("ledger")
	var outcome: int = view.game.complete_due(int(Time.get_unix_time_from_system()) + 3600)
	assert(outcome == 1)
	view._nav_to("ledger")
	assert(view.game.reports.size() == 1)
	view._select_report(0)
	view._nav_to("expeditions")
	view._nav_to("market")
	view._nav_to("hq")
	view.game.reset_company()
	print("Money Mercs UI navigation and actions passed.")
	quit(0)
