extends SceneTree
## Mercenaries without archetypes: jobs from gear, traits, earned titles, reputation tiers,
## the recruit board and the contract market (in-memory company, no save file).
var failures: int = 0

func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error("Mercs check failed: " + what)

func person(trade: String, lv: int, traits: Array = []) -> Dictionary:
	var skills: Dictionary = {}
	for t in TradeSkills.TRADES:
		skills[t] = TradeSkills.xp_for_level(lv if t == trade else 1)
	return {"id": "p_%s_%d" % [trade, lv], "name": "Test Person", "skills": skills, "traits": traits, "wage": 10, "share": 0.1,
		"health": 100, "mission_id": "", "contract": "Balanced", "equipment": {"tool": {}, "armor": {}}}

func _initialize() -> void:
	MoneyMercsState.persist = false
	var now: int = 1_900_000_000
	GameClock.fixed = now
	var g := MoneyMercsState.new()
	g.reset_company()

	# The board: three green applicants (one per trade) always there; nobody above the tier's cap.
	for tier in range(Mercs.TIERS.size()):
		var cap: int = int(Mercs.TIERS[tier]["cap"])
		var best_seen: int = 0
		for epoch in range(200):
			var board: Array[Dictionary] = Mercs.generate_board(epoch, tier)
			check(board.size() == 7, "seven applicants")
			for i in range(3):
				check(Mercs.best_trade(board[i]) == Mercs.RECRUIT_TRADES[i] and Mercs.best_level(board[i]) <= 3, "green applicant %d at tier %d" % [i, tier])
			for c in board:
				best_seen = maxi(best_seen, Mercs.best_level(c))
				check(Mercs.best_level(c) <= cap, "tier %d applicant within cap" % tier)
				check(int(c["min_tier"]) <= tier, "tier %d applicant will join" % tier)
				check((c["traits"] as Array).size() >= 1 and (c["traits"] as Array).size() <= 2, "one or two traits")
		check(best_seen >= cap - 3, "tier %d board reaches near its cap (%d of %d)" % [tier, best_seen, cap])
	# Legendary traits never show up for an Unknown or Known company.
	for epoch in range(300):
		for c in Mercs.generate_board(epoch, 1):
			for t in c["traits"]:
				check(str(Mercs.TRAITS[t]["rarity"]) != "legendary", "no legendary traits below Respected")

	# Named recruits arrive with reputation: Bram (Mining 18) needs a Respected company.
	var ids: Array = []
	for c in g.recruitment_board():
		ids.append(str(c["id"]))
	check(ids.has("garrick") and ids.has("oswin") and not ids.has("bram"), "named recruits gated by reputation")
	check(g.hire("bram").contains("not found"), "can't sign Bram while Unknown")

	# Hiring: a recruit brings the basic tool for their best trade, and the tool sets the job.
	g.gold = 5000
	check(g.hire("garrick").contains("joined"), "hire Garrick")
	var garrick: Dictionary = g.merc_by_id("garrick")
	check(str(garrick["equipment"]["tool"].get("key", "")) == "basic_pick", "brings a pickaxe")
	check(Mercs.job(garrick) == "mining" and Mercs.role_of(garrick) == "Miner", "the pickaxe makes him a miner")
	check(Mercs.title(garrick) == "Miner · Mining 4", "earned title (%s)" % Mercs.title(garrick))
	check(Mercs.has_trait(garrick, "steady_hands"), "Garrick has steady hands")
	# Anyone can hold any tool: hand him an axe and he's a woodcutter.
	g.buy_equipment("hand_axe")
	check(g.equip_item("garrick", str(g.equipment_inventory.back()["uid"])).contains("equipped"), "a miner can take an axe")
	check(Mercs.job(garrick) == "logging" and Mercs.title(garrick).begins_with("Green Woodcutter"), "the axe makes him a woodcutter (%s)" % Mercs.title(garrick))
	g.unequip_item("garrick", "tool")
	check(Mercs.job(garrick) == "" and Mercs.title(garrick).begins_with("No tool"), "no tool, no job")
	# The right tool works at full pace; without it, half.
	var crew: Array[String] = ["garrick"]
	var bare: float = float(g.site_forecast("harlow", crew, "Balanced")["units"].get("copper", 0.0))
	for item in g.equipment_inventory:
		if str(item["key"]) == "basic_pick":
			g.equip_item("garrick", str(item["uid"]))
			break
	var tooled: float = float(g.site_forecast("harlow", crew, "Balanced")["units"].get("copper", 0.0))
	check(tooled > bare * 1.8, "the right tool doubles the pace (%.2f vs %.2f)" % [tooled, bare])

	# Traits do what they say.
	var plain: Dictionary = person("logging", 10)
	var frugal: Dictionary = person("logging", 10, ["frugal"])
	check(int(g.terms(frugal)["wage"]) == 8 and int(g.terms(plain)["wage"]) == 10, "Frugal: wage -20%")
	check(is_equal_approx(float(g.terms(person("logging", 10, ["greedy"]))["cut"]), 0.15), "Greedy: +5% share")
	plain["health"] = 50
	var healer: Dictionary = person("logging", 10, ["quick_healer"])
	healer["health"] = 50
	check(MoneyMercsState.rest_eta(healer) * 2 == MoneyMercsState.rest_eta(plain), "Quick healer rests twice as fast")
	var woods: Dictionary = person("logging", 1, ["woodsman"])
	var prodigy: Dictionary = person("logging", 1, ["prodigy"])
	var normal: Dictionary = person("logging", 1)
	TradeSkills.grant(woods, "logging", 100)
	TradeSkills.grant(prodigy, "logging", 100)
	TradeSkills.grant(normal, "logging", 100)
	check(TradeSkills.xp_of(woods, "logging") == 125 and TradeSkills.xp_of(prodigy, "logging") == 150 and TradeSkills.xp_of(normal, "logging") == 100, "Woodsman +25%, Prodigy +50% experience")
	check(is_equal_approx(Mercs.death_mult(person("mining", 5, ["coward", "ironhide"])), 0.25), "Coward and Ironhide halve the chance of dying")
	check(Mercs.guard_level(person("combat", 5, ["reckless"])) == 10, "Reckless guards five levels higher")
	var keen_crew: Array = [person("mining", 5, ["keen_eye"])]
	var rare: Dictionary = {"chance": 0.04}
	var order: Dictionary = {"duration": 1.0}
	check(is_equal_approx(g._rare_chance(rare, order, keen_crew), 0.06), "Keen eye: rare finds +50%")
	# Strong back hauls more; a Born leader lifts the whole crew.
	g.gold = 5000
	var cutters: Array[String] = []
	for board_refresh in range(2):
		GameClock.fixed = now + board_refresh * 1800
		for c in g.recruitment_board():
			if Mercs.best_trade(c) == "logging" and cutters.size() < board_refresh + 1:
				if g.hire(str(c["id"])).contains("joined"):
					cutters.append(str(c["id"]))
	GameClock.fixed = now
	check(cutters.size() == 2, "two woodcutters hired")
	var a: Dictionary = g.merc_by_id(cutters[0])
	var before: Dictionary = g.site_forecast("mossward_copse", cutters, "Balanced")
	var saved_traits: Array = (a["traits"] as Array).duplicate()
	a["traits"] = ["born_leader"]
	var led: Dictionary = g.site_forecast("mossward_copse", cutters, "Balanced")
	a["traits"] = saved_traits
	check(float(led["units"]["timber"]) > float(before["units"]["timber"]) * 1.05, "Born leader lifts the crew's haul")

	# Value: more skill and better traits are worth more.
	check(Mercs.value(person("mining", 20)) > Mercs.value(person("mining", 10)) * 3, "value grows with skill")
	check(Mercs.value(person("mining", 10, ["keen_eye"])) > Mercs.value(person("mining", 10)), "rare traits add value")
	check(Mercs.min_tier(person("mining", 18)) == 2 and Mercs.min_tier(person("mining", 3)) == 0, "skilled mercenaries need a reputable company")
	check(Mercs.min_tier(person("mining", 3, ["prodigy"])) == 2, "a legendary trait needs at least Respected")

	# Reputation comes from value delivered, not trip count.
	var rep0: int = g.reputation
	g._earn_reputation(1000)
	check(g.reputation == rep0 + int(1000 * Mercs.REP_PER_GOLD), "reputation from value delivered")
	var free_ids: Array[String] = [cutters[1]]
	check(g.site_dispatch("mossward_copse", free_ids, "Balanced").begins_with("The crew set out"), "a trip")
	var rep1: int = g.reputation
	g.complete_due(now + 3600)
	var delivered: int = int(g.reports[0]["value"])
	check(g.reputation - rep1 == int(round(delivered * Mercs.REP_PER_GOLD)), "a trip earns reputation for its haul (%d for %d G)" % [g.reputation - rep1, delivered])
	check(Mercs.tier_for(0) == 0 and Mercs.tier_for(int(Mercs.TIERS[2]["rep"])) == 2, "tiers by reputation")

	# Selling a contract: half the shown value, a little reputation, and they're gone for good.
	g.reputation = 1000
	var seller: Dictionary = g.merc_by_id(cutters[0])
	var offer: int = g.contract_offer(seller)
	check(offer == int(round(Mercs.value(seller) * 0.5)), "NPC guilds pay half the value")
	var gold0: int = g.gold
	check(g.sell_contract(cutters[0]).begins_with("Sold"), "sell a contract")
	check(g.gold == gold0 + offer and g.reputation == 1000 - 20, "paid, and word gets around (rep %d)" % g.reputation)
	check(g.merc_by_id(cutters[0]).is_empty() and not g._available_candidate(cutters[0]).size() > 0, "sold mercenaries don't come back")
	# Buying one: Known companies see other guilds' contracts; bought mercenaries settle in first.
	g.reputation = int(Mercs.TIERS[1]["rep"])
	var contract: Dictionary = {}
	for e in range(40):
		GameClock.fixed = now + e * Mercs.CONTRACT_EPOCH
		for c in g.recruitment_board():
			if str(c.get("kind", "")) == "contract":
				contract = c
				break
		if not contract.is_empty():
			break
	check(not contract.is_empty(), "other guilds sell contracts to a Known company")
	if not contract.is_empty():
		check(int(contract["hire"]) == int(contract["price"]) + int(round(int(contract["price"]) * Mercs.TRANSFER_FEE)), "10% transfer fee on top")
		check(int(contract["min_tier"]) <= 1, "contracts respect reputation")
		g.gold = 99999
		check(g.hire(str(contract["id"])).contains("is yours"), "buy a contract")
		var bought: Dictionary = g.merc_by_id(str(contract["id"]))
		check(g.settling_left(bought) == Mercs.SETTLE_SECONDS, "settling in for three days")
		check(g.sell_contract(str(contract["id"])).contains("settling in"), "can't flip them straight away")
		GameClock.fixed += Mercs.SETTLE_SECONDS + 1
		check(g.sell_contract(str(contract["id"])).begins_with("Sold"), "can sell once settled")

	# Older saves: archetypes become background, and each mercenary gains one trait.
	var old: Dictionary = {"id": "old", "name": "Old Hand", "role": "Guard", "skill": 14}
	TradeSkills.ensure(old)
	Mercs.migrate(old)
	check(not old.has("role") and str(old["background"]) == "Guard" and (old["traits"] as Array).size() == 1, "migration")
	check(Mercs.level(old, "combat") > 1, "old guards keep their combat skill")

	GameClock.fixed = -1
	if failures > 0:
		push_error("%d mercenary checks failed." % failures)
		quit(1)
		return
	print("Mercenaries, traits, reputation and contracts passed.")
	quit(0)
