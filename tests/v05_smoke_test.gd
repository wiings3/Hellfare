extends SceneTree
## V0.5 regression test, isolated to GitHub CI because it replaces user:// data.
func _initialize() -> void:
	if OS.get_environment("CI") != "true":
		push_error("Do not run economic save tests on a real player profile.")
		quit(1)
		return
	call_deferred("_test")

func _test() -> void:
	var g := MoneyMercsState.new()
	# The public state still uses the same API; Harlow mechanics now live in
	# a subclass of the generic company simulation.
	assert(g.get_script().resource_path == "res://scripts/game_state.gd")
	assert(g.get_script().get_base_script().resource_path == "res://scripts/company_state_base.gd")
	g.reset_company()
	assert(g.recruitment_board().size() >= 6)
	var affordable_miner: bool = false
	var affordable_guard: bool = false
	for candidate in g.recruitment_board():
		if str(candidate["role"]) == "Miner" and int(candidate["hire"]) < 90:
			affordable_miner = true
		if str(candidate["role"]) == "Guard" and int(candidate["hire"]) < 90:
			affordable_guard = true
	assert(affordable_miner and affordable_guard)
	g.gold = 1000
	assert(g.hire("garrick").contains("joined"))
	assert(g.hire("oswin").contains("joined"))
	assert(g.buy_equipment("reinforced_pick").contains("Purchased"))
	assert(g.buy_equipment("leather").contains("Purchased"))
	assert(g.equipment_inventory.size() == 2)
	var tool_uid: String = str(g.equipment_inventory[0]["uid"])
	assert(g.equip_item("garrick", tool_uid).contains("equipped"))
	assert(g.equipment_inventory.size() == 1)
	assert(str(g.merc_by_id("garrick")["equipment"]["tool"]["uid"]) == tool_uid)
	assert(g.equip_item("oswin", tool_uid).contains("not found"))
	var armor_uid: String = str(g.equipment_inventory[0]["uid"])
	assert(g.equip_item("garrick", armor_uid).contains("equipped"))
	assert(g.owned_equipment_value() == 143)
	var without: Array[String] = ["garrick"]
	var with_guard: Array[String] = ["garrick", "oswin"]
	var solo: Dictionary = g.harlow_crew_stats(without, "Balanced")
	var protected: Dictionary = g.harlow_crew_stats(with_guard, "Balanced")
	assert(int(solo["capacity"]) == 5)
	assert(float(protected["success"]) > float(solo["success"]))
	assert(float(protected["death"]["garrick"]) < float(solo["death"]["garrick"]))
	g.harlow_send_scout()
	g.harlow["scout_finish"] = int(Time.get_unix_time_from_system()) - 1
	g.harlow_sync()
	assert(not (g.harlow["report"] as Dictionary).is_empty())
	var first_snapshot: Dictionary = (g.harlow["deposits"] as Dictionary).duplicate(true)
	var s: String = g.harlow_dispatch(without, "Balanced")
	assert(s.begins_with("Harlow expedition funded"))
	assert(g.missions.size() == 1)
	g.missions[0]["chance"] = 0.0
	g.missions[0]["death"] = {"garrick": 1.0}
	var finished: int = g.complete_due(int(Time.get_unix_time_from_system()) + 1000)
	assert(finished == 1)
	assert(g.merc_by_id("garrick").is_empty())
	assert(not g.retired_ids.is_empty())
	assert(g._available_candidate("garrick").is_empty())
	assert(not g.hire("garrick").contains("joined"))
	assert(g.owned_equipment_value() == 0)
	assert(g.equipment_inventory.is_empty())
	assert(g.reports[0]["casualties"].size() == 1)
	assert(g.reports[0]["lost_items"].size() == 2)
	assert((g.reports[0]["loot"] as Dictionary).is_empty())
	assert(g.reports[0]["events"].size() > 0)
	# Returning with a partial haul must work, even when the objective fails.
	var next_miner: String = ""
	for candidate in g.recruitment_board():
		if str(candidate["role"]) == "Miner" and g.merc_by_id(str(candidate["id"])).is_empty():
			next_miner = str(candidate["id"])
			break
	assert(not next_miner.is_empty())
	g.gold = 1000
	assert(g.hire(next_miner).contains("joined"))
	var crew: Array[String] = [next_miner, "oswin"]
	assert(g.harlow_dispatch(crew, "Balanced").begins_with("Harlow expedition funded"))
	g.missions[0]["chance"] = 0.0
	g.missions[0]["death"] = {next_miner: 0.0, "oswin": 0.0}
	assert(g.complete_due(int(Time.get_unix_time_from_system()) + 1000) == 1)
	assert(bool(g.reports[0]["partial"]))
	assert(not (g.reports[0]["loot"] as Dictionary).is_empty())
	assert(g.merc_by_id(next_miner).size() > 0)
	assert(g.complete_due(int(Time.get_unix_time_from_system()) + 1000) == 0)
	var remaining: Dictionary = g.harlow["deposits"]
	for ore in first_snapshot:
		assert(int(remaining.get(ore, 0)) >= 0)
		assert(int(remaining.get(ore, 0)) <= int(first_snapshot[ore]))
	g.save_game()
	var restored := MoneyMercsState.new()
	assert(restored.reports.size() == 2)
	assert(restored.retired_ids.has("garrick"))
	assert(restored.next_item_id >= 3)
	assert(restored.merc_by_id(next_miner).size() > 0)
	# Companies can sell owned gear without creating duplicates.
	assert(restored.buy_equipment("rusted_sword").contains("Purchased"))
	var loose: String = str(restored.equipment_inventory[0]["uid"])
	var before: int = restored.gold
	assert(restored.sell_equipment(loose).contains("Sold"))
	assert(restored.gold > before)
	assert(restored.equipment_inventory.is_empty())
	# Guild relief has a debt, not free money.
	restored.gold = 0
	restored.relief_debt = 0
	assert(restored.guild_relief().contains("advanced"))
	assert(restored.gold == 90)
	assert(restored.relief_debt == 110)
	restored.reset_company()
	assert(restored.equipment_inventory.is_empty())
	assert(restored.relief_debt == 0)
	# A scout dispatched before rotation should return with information
	# about the new rotation, rather than vanish into the clock change.
	restored.harlow_sync()
	var old_rotation: int = int(restored.harlow["rotation"])
	assert(restored.harlow_send_scout().begins_with("Scout dispatched"))
	restored.harlow_sync(int(Time.get_unix_time_from_system()) + MoneyMercsState.HARLOW_ROTATION_SECONDS)
	assert(int(restored.harlow["rotation"]) > old_rotation)
	assert(int(restored.harlow["scout_finish"]) == 0)
	assert(not (restored.harlow["report"] as Dictionary).is_empty())
	restored.reset_company()
	# A disastrous first expedition must not strand a solo, broke miner.
	restored.reset_company()
	assert(restored.hire("garrick").contains("joined"))
	assert(restored.hire("oswin").contains("joined"))
	var starter_party: Array[String] = ["garrick", "oswin"]
	assert(restored.harlow_dispatch(starter_party, "Balanced").begins_with("Harlow expedition funded"))
	restored.missions[0]["chance"] = 0.0
	restored.missions[0]["death"] = {"garrick": 0.0, "oswin": 1.0}
	assert(restored.complete_due(int(Time.get_unix_time_from_system()) + 1000) == 1)
	assert(restored.merc_by_id("oswin").is_empty())
	assert(not restored.merc_by_id("garrick").is_empty())
	restored.gold = 0  # Extreme starting setback with no emergency advance.
	var replacement_guard: Dictionary = {}
	for applicant in restored.recruitment_board():
		if str(applicant["role"]) == "Guard" and (replacement_guard.is_empty() or int(applicant["hire"]) < int(replacement_guard["hire"])):
			replacement_guard = applicant
	assert(not replacement_guard.is_empty())
	var saved_xp: int = int(restored.merc_by_id("garrick").get("xp", 0))
	var work_count := 0
	while restored.gold < int(replacement_guard["hire"]) and work_count < 10:
		assert(restored.start_guild_work("garrick").contains("safe guild work order"))
		assert(restored.missions.size() == 1)
		assert(restored.start_guild_work("garrick").contains("slots"))
		var cash_before: int = restored.gold
		assert(restored.complete_due(int(Time.get_unix_time_from_system()) + 1000) == 1)
		assert(restored.gold == cash_before + MoneyMercsState.GUILD_WORK_PAY)
		assert(not restored.merc_by_id("garrick").is_empty())
		assert((restored.reports[0]["casualties"] as Array).is_empty())
		assert(restored.complete_due(int(Time.get_unix_time_from_system()) + 1000) == 0)
		work_count += 1
	assert(restored.gold >= int(replacement_guard["hire"]))
	assert(work_count > 0)
	assert(restored.hire(str(replacement_guard["id"])).contains("joined"))
	assert(restored.crew.size() == 2)
	assert(int(restored.merc_by_id("garrick").get("xp", 0)) > saved_xp)
	# Relief work is a floor for broke companies, never an unlimited gold farm.
	restored.gold = 120
	assert(not restored.can_accept_guild_work())
	assert(restored.start_guild_work("garrick").contains("reserved"))
	restored.gold = 20
	restored.resources["relic"] = 1
	assert(not restored.can_accept_guild_work())
	restored.resources["relic"] = 0
	# Recovery is possible even with no mercenaries, gold or remaining credit.
	restored.reset_company()
	restored.gold = 0
	restored.relief_debt = 440
	assert(restored.start_guild_work().contains("paperwork accepted"))
	restored.save_game()
	var overnight := MoneyMercsState.new()
	assert(overnight.missions.size() == 1)
	assert(overnight.complete_due(int(Time.get_unix_time_from_system()) + 1000) == 1)
	assert(overnight.gold == MoneyMercsState.OFFICE_WORK_PAY)
	assert(overnight.crew.is_empty())
	assert(overnight.start_guild_work().contains("paperwork accepted"))
	assert(overnight.complete_due(int(Time.get_unix_time_from_system()) + 1000) == 1)
	assert(overnight.gold == 2 * MoneyMercsState.OFFICE_WORK_PAY)
	overnight.reset_company()
	# Migration from a v0.4 state (no equipment fields, unchanged version 1).
	var legacy_file := FileAccess.open(MoneyMercsState.SAVE_PATH, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify({
		"version": 1, "gold": 175, "resources": {}, "crew": [
			{"id": "old", "name": "Older Worker", "role": "Miner", "skill": 12,
			 "hire": 50, "wage": 9, "share": 0.1, "mission_id": "", "gear": 2}
		], "missions": [], "reports": [], "harlow": {}
	}))
	legacy_file.close()
	var migrated := MoneyMercsState.new()
	assert(migrated.gold == 175)
	assert(migrated.merc_by_id("old").has("equipment"))
	assert(int(migrated.merc_by_id("old")["gear"]) == 2)
	migrated.reset_company()
	print("V0.5 equipment, permadeath, partial mining, debt, and migration tests passed.")
	quit(0)
