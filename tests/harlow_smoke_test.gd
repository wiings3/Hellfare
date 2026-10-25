extends SceneTree
## Harlow Mines as an ordinary tier-1 mining site, plus the trips and saves made under its
## old MVP rules (scouting, rotating deposits). Only resets the CI-only save.
func _initialize() -> void:
	if OS.get_environment("CI") != "true":
		push_error("CI only")
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	var view: Control = load("res://scenes/journal/widgets/main.tscn").instantiate()
	root.add_child(view)
	view.game.reset_company()
	var site: Dictionary = TradeSites.by_id("harlow")
	assert(str(site["trade"]) == "mining" and int(site["tier"]) == 1 and not site.has("special"))
	assert(TradeSites.by_id("greyvein_quarry")["id"] == "harlow")  # old saves
	# Old links to the Harlow page open its ordinary planner.
	view._nav_to("harlow")
	assert(view.page == "site" and view.selected_site == "harlow")
	assert(view.right_leaf.get_child(0).scene_file_path.ends_with("/site_right.tscn"))
	# A new miner can work it with any orders, Overnight included.
	var miner: String = ""
	for c in view.game.recruitment_board():
		if Mercs.best_trade(c) == "mining":
			miner = str(c["id"])
			break
	view.game.gold = 900
	assert(view.game.hire(miner).contains("joined"))
	view._refresh()
	view._toggle_crew(true, miner)
	assert(view.selected_crew.size() == 1)
	var ids: Array[String] = [miner]
	assert(bool(view.game.site_forecast("harlow", ids, "Overnight")["meets_level"]))
	view._dispatch_site()
	assert(view.game.missions.size() == 1)
	assert(str(view.game.missions[0]["region"]) == "site" and str(view.game.missions[0]["site"]) == "harlow")
	assert(view.game.complete_due(int(Time.get_unix_time_from_system()) + 1000) == 1)
	assert(str(view.game.reports[0]["site"]) == "harlow")
	assert(TradeSkills.xp_of(view.game.merc_by_id(miner), "mining") > 0)
	# A trip sent under the old rules still settles, and its state survives a save.
	view.game.harlow_send_scout()
	view.game.harlow["scout_finish"] = int(Time.get_unix_time_from_system()) - 1
	view.game.harlow_sync()
	var crew: Array[String] = [miner]
	assert(view.game.harlow_dispatch(crew, "Balanced").begins_with("Harlow expedition funded"))
	assert(str(view.game.missions[0]["region"]) == "harlow")
	view._nav_to("hq")
	assert(view.game.complete_due(int(Time.get_unix_time_from_system()) + 2000) == 1)
	assert(view.game.reports[0].has("extracted"))
	view.game.save_game()
	var restored := MoneyMercsState.new()
	assert(restored.harlow.has("rotation"))
	assert(restored.reports.size() == 2)
	view.game.reset_company()
	print("Harlow Mines site and legacy trip settlement passed.")
	quit(0)
