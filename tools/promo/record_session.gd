extends SceneTree
## Records the promo footage in one run (see tools/promo/make_short.py); prints MARK lines
## (seconds into the video). In-memory guild only: never touches a save file.
var ui: Control
var g
var ff := 0.0   # game seconds added per frame (fast-forward)
var marks := []
func _initialize() -> void:
	call_deferred("_go")
func mark(name: String) -> void:
	var t: float = float(Engine.get_frames_drawn()) / 30.0
	print("MARK %s %.2f" % [name, t])
func _process(_delta: float) -> bool:
	if ff > 0.0:
		GameClock.fixed += int(ff)
	return false
func hold(s: float) -> void:
	await create_timer(s).timeout
func kit(id: String, keys: Array, combat: int) -> void:
	var m: Dictionary = g.merc_by_id(id)
	m["skills"]["combat"] = TradeSkills.xp_for_level(combat)
	for k in keys:
		m["equipment"][Gear.slot_of(k)] = g.make_item(k, "common")
func _go() -> void:
	MoneyMercsState.persist = false
	GameClock.fixed = 1_900_000_000
	ui = load("res://scenes/journal/widgets/main.tscn").instantiate()
	root.add_child(ui)
	await hold(0.3)
	g = ui.game
	g.reset_company()
	g.tutorial = {"step": "done"}
	g.gold = 4200
	g.expedition_slots = 6
	ui._refresh()
	await hold(0.8)
	# 1. Recruiting
	ui._turn_to("roster")
	await hold(0.9)
	ui._set_roster_tab("recruits")
	await hold(0.6)
	mark("recruit")
	var cutter := ""
	for c in g.recruitment_board():
		if Mercs.role_of(c) == "Woodcutter" and cutter == "":
			cutter = str(c["id"])
	ui._choose_candidate(cutter)
	await hold(1.6)
	ui._hire(cutter)
	await hold(1.4)
	mark("recruit_end")
	# Hire the rest of the board quietly (more crews for the map), kit three fighters.
	var others: Array[String] = []
	for c in g.recruitment_board():
		var cid: String = str(c["id"])
		print("hire: ", g.hire(cid))
		if not g.merc_by_id(cid).is_empty() and cid != cutter:
			others.append(cid)
	var fighters: Array[String] = []
	for id in others:
		if fighters.size() < 3 and Mercs.best_trade(g.merc_by_id(id)) == "combat":
			fighters.append(id)
	for id in others:
		if fighters.size() < 3 and not fighters.has(id):
			fighters.append(id)
	kit(fighters[0], ["steel_sword", "chainmail", "iron_helm"], 9)
	kit(fighters[1], ["steel_sword", "chainmail"], 8)
	kit(fighters[2], ["iron_dagger", "leather", "leather_cap", "leather_boots"], 7)
	# 2. Sending a crew down
	ui._open_site("mossward_copse")
	await hold(1.0)
	mark("send")
	await hold(0.6)
	ui._toggle_crew(true, cutter)
	await hold(1.2)
	ui._dispatch_site()
	await hold(1.0)
	mark("send_end")
	# More crews to other sites, and the crypt crew.
	var spare: Array = []
	for id in others:
		if not fighters.has(id):
			spare.append(id)
	var sites := ["harlow", "mossward_meadows", "millbrook_pond", "hollow_fields"]
	for i in range(mini(spare.size(), sites.size())):
		var one: Array[String] = [str(spare[i])]
		g.site_dispatch(sites[i], one, "Balanced")
	print(g.dungeon_dispatch("calder_keep", fighters, 3, "half", "bold"))
	# 4. A crypt event
	var dm: Dictionary = {}
	for m in g.missions:
		if str(m.get("region", "")) == "dungeon":
			dm = m
	var evs: Array = dm.get("ev", [])
	if not evs.is_empty():
		var t0: int = GameClock.fixed
		GameClock.fixed = int(evs[0]["t"]) + 1
		ui._open_dungeon("calder_keep")
		await hold(0.8)
		ui._update_event_card()
		mark("event")
		await hold(3.5)
		ui._answer_event(str(dm["id"]), 0, 0)
		await hold(2.5)
		mark("event_end")
		GameClock.fixed = t0 + 40
	ui._turn_to("hq")
	await hold(0.8)
	# 3. Crews walking down the map, fast
	mark("walk")
	ff = 1.7
	await hold(6.0)
	mark("walk_end")
	ff = 60.0
	await hold(1.2)
	ff = 0.0
	await hold(0.5)
	mark("reports")
	await hold(2.5)
	mark("reports_end")
	print("GOLD ", g.gold, " REPORTS ", g.reports.size())
	quit(0)
