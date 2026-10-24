extends SceneTree
## Long orders, the mining sites and guild contractors (in-memory company, no save file).
var failures: int = 0

func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error("Viability check failed: " + what)

func _initialize() -> void:
	MoneyMercsState.persist = false
	var now: int = 1_900_000_000
	GameClock.fixed = now
	# Long orders last the same at every site.
	for site_id in ["mossward_copse", "old_oakwood", "greyvein_quarry", "deepdelve"]:
		var site: Dictionary = TradeSites.by_id(site_id)
		check(not site.is_empty(), "site exists: " + site_id)
		var night: Dictionary = TradeSites.order_for(site, "Overnight")
		var day: Dictionary = TradeSites.order_for(site, "Full Day")
		check(is_equal_approx(float(site["duration"]) * float(night["duration"]), 8.0 * 3600.0), "Overnight lasts 8 hours at " + site_id)
		check(is_equal_approx(float(site["duration"]) * float(day["duration"]), 20.0 * 3600.0), "Full Day lasts 20 hours at " + site_id)
		check(float(night["yield"]) / float(night["duration"]) < float(TradeSites.orders("Long Shift")["yield"]) / 6.0, "Overnight pays less per hour than Long Shift")
	# A new company can afford an Overnight trip with one woodcutter, and it pays.
	var g := MoneyMercsState.new()
	g.reset_company()
	var cutter: String = ""
	var miner: String = ""
	for c in g.recruitment_board():
		if str(c["role"]) == "Woodcutter" and cutter == "":
			cutter = str(c["id"])
		if str(c["role"]) == "Miner" and miner == "":
			miner = str(c["id"])
	g.hire(cutter)
	var ids: Array[String] = [cutter]
	var plan: Dictionary = g.site_forecast("mossward_copse", ids, "Overnight")
	check(int(plan["cost"]) <= g.gold, "Overnight affordable after one hire (%d G, have %d)" % [int(plan["cost"]), g.gold])
	check(int(plan["profit"]) > 0, "Overnight at the Copse is profitable")
	check(int(plan["duration"]) == 8 * 3600, "forecast shows eight hours")
	var oak: Dictionary = g.site_forecast("old_oakwood", ids, "Full Day")
	check(float(oak["injury"]) <= TradeSites.MAX_INJURY and float(oak["death"]) <= TradeSites.MAX_DEATH, "long trips cap injury and death")
	check(g.site_dispatch("mossward_copse", ids, "Overnight").begins_with("The crew set out"), "Overnight dispatch")
	check(int(g.missions[0]["finish"]) - int(g.missions[0]["started"]) == 8 * 3600, "mission lasts eight hours")
	g.complete_due(now + 8 * 3600 + 1)
	check(int(g.resources.get("timber", 0)) > 30, "an Overnight haul is a real haul (%d timber)" % int(g.resources.get("timber", 0)))
	# Mining sites: the quarry takes a new miner, Deepdelve needs Mining 8.
	g.gold = 2000
	g.hire(miner)
	var mids: Array[String] = [miner]
	check(bool(g.site_forecast("greyvein_quarry", mids, "Balanced")["meets_level"]), "a new miner can work the quarry")
	check(not bool(g.site_forecast("deepdelve", mids, "Balanced")["meets_level"]), "Deepdelve needs Mining 8")
	check(g.site_dispatch("greyvein_quarry", mids, "Balanced").begins_with("The crew set out"), "quarry dispatch")
	g.complete_due(now + 9 * 3600)
	check(int(g.resources.get("copper", 0)) >= 0 and g.reports[0].get("site", "") == "greyvein_quarry", "quarry trip reported")
	check(TradeSkills.xp_of(g.merc_by_id(miner), "mining") > 0, "quarry trains mining")
	# Guild contractors post big orders above fair value, and filling one leaves NPC demand alone.
	var hall: TradeHall = g.hall
	hall.rng.seed = 4
	var contract: Dictionary = {}
	for i in range(4000):
		var m: Dictionary = hall._npc_message(now)
		if str(m["kind"]) == "contractor":
			contract = m
			break
	check(not contract.is_empty(), "contractors post")
	if not contract.is_empty():
		check(str(contract["side"]) == "wtb", "contractors buy")
		check(float(contract["price"]) >= hall.fair(str(contract["good"]), now) * 1.05, "contract pays above fair value")
		check(int(contract["until"]) - now >= 1800, "contract stays up at least half an hour")
	GameClock.fixed = -1
	if failures > 0:
		push_error("%d viability checks failed." % failures)
		quit(1)
		return
	print("Long orders, mining sites and guild contractors passed.")
	quit(0)
