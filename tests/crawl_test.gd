extends SceneTree
## Heroes and the crypt crawl: the turn engine (turns, actions, guard, class skills, speed), that
## led and automatic fights follow the same rules, a led run from start to report, a led run
## surviving a save mid-fight, handing a led run back to its orders, hero slots and hiring, and
## old guilds getting their first hero. In-memory guilds only (no save file).
var failures: int = 0

func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error("Crawl check failed: " + what)

func _initialize() -> void:
	call_deferred("_run")

func hero(g: MoneyMercsState, hero_class: String, keys: Array) -> Dictionary:
	var h: Dictionary = Heroes.make("hero_x%d" % g.heroes.size(), "Test %s" % hero_class, hero_class)
	for k in keys:
		h["equipment"][Gear.slot_of(k)] = g.make_item(k, "common")
	return h

func _run() -> void:
	MoneyMercsState.persist = false
	var now: int = 1_900_000_000
	GameClock.fixed = now
	var g := MoneyMercsState.new()
	g.reset_company()
	var keep: Dictionary = Dungeons.by_id("calder_keep")
	var cellars: Dictionary = keep["floors"][0]
	var boss: Dictionary = keep["floors"][2]

	# --- Classes ---------------------------------------------------------------------
	var k: Dictionary = Heroes.fighter(hero(g, "knight", ["rusted_sword", "leather"]))
	var r: Dictionary = Heroes.fighter(hero(g, "rogue", ["rusted_sword", "leather"]))
	check(float(k["max_hp"]) > float(r["max_hp"]), "knights have more health")
	check(float(k["armour"]) > float(r["armour"]), "the same armour counts for more on a knight")
	check(float(r["crit"]) > float(k["crit"]) and float(r["dodge"]) > float(k["dodge"]), "the same gear gives a rogue more crit and dodge")
	var bare: Dictionary = Heroes.fighter(Heroes.make("b", "Bare", "knight"))
	check(not bool(bare["porter"]) and float(bare["damage"]) > 0.0, "a hero with no weapon fights with fists")
	check(Heroes.hero_only("rusted_sword") and Heroes.hero_only("leather") and Heroes.hero_only("iron_kite_shield"), "weapons, armour and shields are for heroes")
	check(not Heroes.hero_only("birch_shortbow") and not Heroes.hero_only("hand_axe"), "hunting bows and tools are for anyone")

	# --- The engine ------------------------------------------------------------------
	var st: Dictionary = Crawl.start([Heroes.fighter(hero(g, "knight", ["rusted_sword"]))], cellars, 7, true)
	check(Crawl.turn_of(st) == 0 or Crawl.done(st), "a led fight waits for the hero's choice")
	var ids: Array = []
	for a in Crawl.actions(st, 0):
		ids.append(str(a["id"]))
	check(ids == ["strike", "skill", "guard", "potion", "retreat"], "the hero's actions (%s)" % str(ids))
	var foe_hp: float = 0.0
	for f in st["foes"]:
		foe_hp += float(f["hp"])
	var ev: Array = Crawl.act(st, "strike", 0)
	var after: float = 0.0
	for f in st["foes"]:
		after += float(f["hp"])
	check(after < foe_hp, "a strike hurts a foe")
	check(ev.any(func(e): return str(e["kind"]) in ["hit", "crit"] and float(e["amount"]) > 0.0), "the hit's number is in the events")
	check(ev.any(func(e): return str(e["text"]) != ""), "every event has words for the log")
	# Same choices, same fight: a led fight played by the automatic rules ends exactly like an
	# automatic one.
	var a1: Dictionary = Crawl.start([Heroes.fighter(hero(g, "rogue", ["iron_dagger"]))], cellars, 99, true)
	var a2: Dictionary = Crawl.start([Heroes.fighter(hero(g, "rogue", ["iron_dagger"]))], cellars, 99, true)
	Crawl.run_auto(a1)
	var guard: int = 0
	while not Crawl.done(a2) and guard < 500:
		guard += 1
		var c: Array = Crawl.ai_choice(a2, Crawl.turn_of(a2))
		Crawl.act(a2, str(c[0]), int(c[1]))
	check(str(a1["result"]) == str(a2["result"]) and int(a1["round"]) == int(a2["round"]) and is_equal_approx(float(a1["party"][0]["hp"]), float(a2["party"][0]["hp"])),
		"led and automatic fights follow the same rules")
	# A fight survives being saved: JSON round trip in the middle, then the same ending.
	var s1: Dictionary = Crawl.start([Heroes.fighter(hero(g, "knight", ["rusted_sword"]))], cellars, 1234, true)
	var s2: Dictionary = Crawl.start([Heroes.fighter(hero(g, "knight", ["rusted_sword"]))], cellars, 1234, true)
	Crawl.act(s1, "strike")
	Crawl.act(s2, "strike")
	s2 = JSON.parse_string(JSON.stringify(s2))
	while not Crawl.done(s1):
		Crawl.act(s1, "strike")
	guard = 0
	while not Crawl.done(s2) and guard < 500:
		guard += 1
		Crawl.act(s2, "strike")
	check(str(s1["result"]) == str(s2["result"]) and int(s1["round"]) == int(s2["round"]), "a fight saved mid-way plays on the same")
	# Guard: against the Bone Knight's heavy blow, a guarding knight takes much less per blow.
	var took: Array = []
	for guarding in [false, true]:
		var total: float = 0.0
		var blows: int = 0
		for seed_value in range(40):
			var b: Dictionary = Crawl.start([Heroes.fighter(hero(g, "knight", ["steel_sword", "chainmail"]))], boss, seed_value, true)
			var safety: int = 0
			while not Crawl.done(b) and safety < 200:
				safety += 1
				var winding: bool = (b["foes"] as Array).any(func(f): return bool(f["winding"]))
				var log_n: int = (b["log"] as Array).size()
				Crawl.act(b, "guard" if (winding and guarding) else "strike")
				for e in (b["log"] as Array).slice(log_n):
					if str(e["kind"]) == "heavy":
						total += float(e["amount"])
						blows += 1
		took.append(total / maxf(1.0, float(blows)))
	check(float(took[1]) < float(took[0]) * 0.6, "guarding against the heavy blow takes most of it off (%.1f vs %.1f a blow)" % [float(took[1]), float(took[0])])
	# Skills: a bash stuns; a backstab crits more often than a strike.
	var bash: Dictionary = Crawl.start([Heroes.fighter(hero(g, "knight", ["rusted_sword"]))], keep["floors"][1], 5, true)
	var bev: Array = Crawl.act(bash, "skill", 0)
	check(bev.any(func(e): return str(e["kind"]) == "stun") or float(bash["foes"][0]["hp"]) <= 0.0, "Shield Bash stuns")
	check(int(bash["party"][0]["cd"]) == Crawl.SKILL_COOLDOWN, "a skill then needs time")
	var crits := [0, 0]
	for seed_value in range(300):
		for m in [0, 1]:
			var t: Dictionary = Crawl.start([Heroes.fighter(hero(g, "rogue", ["iron_dagger"]))], boss, seed_value, true)
			var e2: Array = Crawl.act(t, "skill" if m == 1 else "strike", 0)
			if e2.any(func(e): return str(e["kind"]) == "crit"):
				crits[m] += 1
	check(int(crits[1]) > int(crits[0]) * 1.5, "Backstab crits far more often (%d vs %d)" % [int(crits[1]), int(crits[0])])
	# Speed: a dagger acts more often than a greatsword.
	var fast: Dictionary = Crawl.start([Heroes.fighter(hero(g, "rogue", ["iron_dagger"]))], boss, 3)
	var slow: Dictionary = Crawl.start([Heroes.fighter(hero(g, "knight", ["iron_greatsword"]))], boss, 3)
	Crawl.run_auto(fast)
	Crawl.run_auto(slow)
	var hits_fast: float = float(fast["stats"]["0"]["hits"]) / maxf(1.0, float(fast["round"]))
	var hits_slow: float = float(slow["stats"]["0"]["hits"]) / maxf(1.0, float(slow["round"]))
	check(hits_fast > hits_slow * 1.5, "a dagger strikes more often than a greatsword (%.2f vs %.2f a round)" % [hits_fast, hits_slow])
	check(Crawl.recap(slow).size() >= 2, "the report gets a recap of the fight")

	# --- Hero slots and hiring ---------------------------------------------------------
	check(g.heroes.is_empty() and g.hero_slots == 1, "a new guild has one hero slot")
	check(g.found_hero("knight", "Brannoc").contains("joins"), "the first hero is founded free")
	check(str(Gear.in_slot(g.heroes[0], "main_hand").get("key", "")) == "rusted_sword", "a knight starts with a sword")
	check(g.hire_hero(str(g.hero_board()[1]["id"])).contains("slot"), "a second hero needs a second slot")
	g.gold = 5000
	check(g.buy_hero_slot().contains("2 heroes") and g.hero_slots == 2, "hero slots are bought")
	var rogue_cand: Dictionary = g.hero_board()[1]
	check(g.hire_hero(str(rogue_cand["id"])).contains("Rogue"), "a rogue hired from the board")
	check(str(Gear.in_slot(g.heroes[1], "main_hand").get("key", "")) == "iron_dagger", "a rogue starts with a dagger")
	g.gold = 1000
	var worker_id: String = ""
	for c in g.recruitment_board():
		if g.hire(str(c["id"])).contains("joined"):
			worker_id = str(c["id"])
			break
	check(worker_id != "", "a worker hired")
	g.buy_equipment("leather")
	var leather_uid: String = str(g.equipment_inventory.back()["uid"])
	check(g.equip_item(worker_id, leather_uid).contains("Only heroes"), "workers can't wear armour")
	check(g.equip_item(str(g.heroes[0]["id"]), leather_uid).contains("equipped"), "heroes can")

	# --- A led run, start to finish ----------------------------------------------------
	var hero_id: String = str(g.heroes[0]["id"])
	var one: Array[String] = [hero_id]
	var site_ids: Array[String] = [worker_id]
	var site: String = ""
	for s in TradeSites.SITES:
		if int(s["level"]) <= 1 and str(s.get("needs", "")) == "" and str(s["trade"]) == Mercs.best_trade(g.merc_by_id(worker_id)):
			site = str(s["id"])
	if site != "":
		check(g.site_dispatch(site, site_ids, "Balanced").begins_with("The crew set out"), "a crew goes out")
	check(g.dungeon_dispatch("calder_keep", one, 3, "half", "safe", true).begins_with("The crew went"), "a hero goes in while a crew is out")
	var m: Dictionary = g.lead_run()
	check(not m.is_empty() and str(m["stage"]) == "led", "the run waits for the player")
	check(g.complete_due(now + 99999) >= 0 and not g.lead_run().is_empty(), "time passing doesn't play a led run")
	var fight: Dictionary = g.lead_fight()
	check(not fight.is_empty() and Crawl.turn_of(fight) == 0, "the first floor's fight is the player's")
	guard = 0
	while str(m.get("stage", "")) == "led" and guard < 300:
		guard += 1
		var c: Array = Crawl.ai_choice(g.lead_fight(), Crawl.turn_of(g.lead_fight()))
		g.lead_act(str(c[0]), int(c[1]))
	check(str(m["log"][0]["result"]) == "cleared", "the hero clears the Cellars (%s)" % str(m["log"][0]["result"]))
	check(str(m["stage"]) == "led_between" and bool(m["log"][0]["led"]), "then waits at the stairs")
	check(int(m["carry"].get("coin", 0)) > 0, "carrying the Cellars' coin")
	var reports: int = g.reports.size()
	check(g.lead_choose(false).contains("back up"), "taking it out")
	check(g.lead_run().is_empty() and g.reports.size() == reports + 1, "the run settles at once")
	check(str(g.reports[0].get("dungeon", "")) == "calder_keep" and int(g.reports[0]["cash"]) > 0, "the report pays out")
	check(int(g.heroes[0]["health"]) < 100 and str(g.heroes[0]["mission_id"]) == "", "the hero is home, hurt")
	var worn_body: Dictionary = Gear.in_slot(g.heroes[0], "body")
	check(Gear.durability(worn_body) < Gear.max_durability(worn_body), "a crypt run wears the hero's armour")
	check(g.crypt_starts("calder_keep") == 2, "clearing the Cellars makes their stairs known")
	check(m["log"][0].get("first_clear", false), "the first clear is marked")
	var hp_after: int = int(g.heroes[0]["health"])
	g.complete_due(now + 99999 + 600)
	check(int(g.heroes[0]["health"]) > hp_after, "heroes recover between runs")

	# --- Starting at known stairs --------------------------------------------------------
	g.heroes[0]["health"] = 100
	GameClock.fixed = now + 150000
	check(g.dungeon_dispatch("calder_keep", one, 2, "half", "safe", true, 1).begins_with("The crew went"), "a run can start at known stairs")
	check(int(g.lead_run()["floor_i"]) == 1 and (g.lead_fight()["foes"] as Array).size() == 2, "it starts in the Webbed Halls")
	g.lead_release()
	g.complete_due(now + 199000)
	check(g.dungeon_dispatch("calder_keep", one, 3, "half", "safe", false, 2).begins_with("The crew went") or g.crypt_starts("calder_keep") < 3, "the boss's stairs only once the halls are cleared")
	for mm in g.missions.duplicate():
		if bool(mm.get("heroes", false)):
			g.complete_due(int(mm["finish"]) + 99999)

	# --- Handing a led run back to its orders ------------------------------------------
	# The Webbed Halls run above was left to the hero, who can die there: start again if so.
	if g.merc_by_id(one[0]).is_empty():
		if g.heroes.is_empty():
			g.found_hero("knight", "Second Knight")
		one = [str(g.heroes[0]["id"])]
	g.merc_by_id(one[0])["health"] = 100
	GameClock.fixed = now + 200000
	var again: String = g.dungeon_dispatch("calder_keep", one, 1, "half", "safe", true)
	check(again.begins_with("The crew went"), "led again (%s)" % again)
	g.lead_fight()
	g.lead_act("strike")
	check(g.lead_release().contains("orders"), "let them handle it")
	var auto_run: Dictionary = {}
	for mm in g.missions:
		if bool(mm.get("heroes", false)):
			auto_run = mm
	check(not auto_run.is_empty() and not bool(auto_run["led"]) and (auto_run["log"] as Array).size() == 1, "the fight was played out by the rules")
	g.complete_due(now + 300000)
	check(g.hero_runs_out() == 0, "and the run finished on its own")

	# --- Old guilds get a hero --------------------------------------------------------
	var old := MoneyMercsState.new()
	old.reset_company()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in range(2):
		var p: Dictionary = Mercs.make_person(rng, "old_%d" % i, "combat" if i == 0 else "mining", 4, 0, true)
		p["equipment"] = Gear.empty_equipment()
		p["mission_id"] = ""
		p["health"] = 100
		old.crew.append(p)
	old.crew[0]["equipment"]["main_hand"] = old.make_item("steel_dagger", "common")
	old.crew[0]["equipment"]["body"] = old.make_item("leather", "common")
	old.crew[1]["equipment"]["body"] = old.make_item("chainmail", "common")
	old._migrate_to_heroes()
	check(old.heroes.size() == 1 and Heroes.cls(old.heroes[0]) == "rogue", "the best-armed fighter becomes a rogue hero (dagger)")
	check(str(Gear.in_slot(old.heroes[0], "body").get("key", "")) == "leather", "the hero keeps their kit")
	check(old.crew.size() == 1 and Gear.in_slot(old.crew[0], "body").is_empty(), "armour on workers goes to the warehouse")
	check(old.equipment_inventory.any(func(it): return str(it["key"]) == "chainmail"), "and is still the guild's")

	GameClock.fixed = -1
	if failures > 0:
		push_error("%d crawl checks failed." % failures)
		quit(1)
		return
	print("Crawl checks passed.")
	quit(0)
