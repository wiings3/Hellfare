extends SceneTree
## Catalog integrity: no dead ends, sane prices, balanced weapon families, every tier covered,
## and in step with the live game.
var failures: int = 0

func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error("Catalog check failed: " + what)

func tier_of(id: String) -> int:
	if Catalog.materials().has(id):
		return int(Catalog.materials()[id]["tier"])
	return int(Catalog.items().get(id, {}).get("tier", 0))

func _initialize() -> void:
	var mats: Dictionary = Catalog.materials()
	var items: Dictionary = Catalog.items()
	var sources: Dictionary = Catalog.sources()
	var rules: Dictionary = Catalog.rules()
	var affixes: Dictionary = Catalog.data()["affixes"]
	var buffs: Dictionary = Catalog.data()["buffs"]
	var upgrades: Dictionary = Catalog.data()["upgrades"]
	check(mats.size() >= 50 and items.size() >= 180, "catalog loaded (%d materials, %d items)" % [mats.size(), items.size()])

	# Sources: every expedition yields something; locked ones name a real upgrade.
	var yields: Dictionary = {}
	for id in mats:
		for s in mats[id]["sources"]:
			yields[s] = true
	for s in sources:
		var kind: String = str(sources[s]["kind"])
		if kind in ["site", "farm", "dungeon"]:
			check(yields.has(s), "expedition yields a material: " + s)
		if sources[s].has("needs"):
			check(upgrades.has(sources[s]["needs"]), "%s is unlocked by a real upgrade" % s)
			check(s in upgrades[sources[s]["needs"]]["unlocks"], "%s's upgrade unlocks it" % s)

	# Materials: a real source and a use (in a recipe or an upgrade).
	var used: Dictionary = {}
	for key in items:
		var r: Variant = items[key].get("recipe")
		if r is Dictionary:
			for part in r:
				used[part] = true
	for u in upgrades:
		for part in upgrades[u]["cost"]:
			check(mats.has(part) or items.has(part), "upgrade %s costs a known material (%s)" % [u, part])
			used[part] = true
	for id in mats:
		var m: Dictionary = mats[id]
		check(not (m["sources"] as Array).is_empty(), "material has a source: " + id)
		for s in m["sources"]:
			check(sources.has(s), "%s comes from a known source (%s)" % [id, s])
		check(bool(m["sell_only"]) or used.has(id), "material has a use: " + id)
		check(float(m["value"]) > 0 and int(m["tier"]) >= 1 and int(m["tier"]) <= 5, "material value and tier: " + id)

	# Items: obtainable, priced 1.1-2.2x their materials, no higher-tier inputs, valid rolls and buffs.
	var cover: Dictionary = {}
	var rolled: Dictionary = {}
	for id in items:
		var it: Dictionary = items[id]
		var tier: int = int(it["tier"])
		for roll in it.get("rolls", []):
			check(affixes.has(roll), "%s rolls a known stat (%s)" % [id, roll])
			rolled[roll] = true
		for roll in it.get("fixed_rolls", {}):
			check(affixes.has(roll), "%s has a known fixed roll (%s)" % [id, roll])
		for b in it.get("buffs", {}):
			check(buffs.has(b), "%s gives a known buff (%s)" % [id, b])
		if str(it["category"]) in ["food", "potion"]:
			check(not (it.get("buffs", {}) as Dictionary).is_empty(), "food and potions do something: " + id)
		if bool(it.get("found_only", false)):
			check(it.get("recipe") == null and (it["blueprint"] as Array).is_empty(), "found-only can't be crafted: " + id)
			check(int(it["value"]) >= 800, "found-only is a jackpot: " + id)
			continue
		var recipe: Dictionary = it["recipe"]
		check(not recipe.is_empty(), "item has a recipe: " + id)
		for part in recipe:
			check(mats.has(part) or (items.has(part) and str(items[part]["category"]) == "material"), "%s uses a known part (%s)" % [id, part])
			if mats.has(part) and bool(mats[part]["sell_only"]):
				continue
			check(tier_of(str(part)) <= maxi(tier, 1), "%s needs nothing above tier %d (%s)" % [id, tier, part])
		var ratio: float = float(it["value"]) / Catalog.recipe_cost(recipe)
		check(ratio >= 1.1 and ratio <= 2.2, "%s is worth %.2fx its materials" % [id, ratio])
		var bps: Array = it["blueprint"]
		check(not bps.is_empty(), "item has a blueprint source: " + id)
		for bp in bps:
			check(sources.has(bp), "%s blueprint source known (%s)" % [id, bp])
			if not sources.has(bp):
				continue
			var kind: String = str(sources[bp]["kind"])
			if kind == "shop":
				check(tier <= 2, "quartermaster only sells tier 1-2 blueprints: " + id)
			elif kind == "dungeon":
				check(int(sources[bp]["tier"]) + 2 == tier, "%s blueprint drops in the tier-%d dungeon" % [id, tier - 2])
			elif kind in ["site", "farm"]:
				check(int(sources[bp]["tier"]) == tier, "%s blueprint found at a tier-%d expedition" % [id, tier])
		if it.get("durability") != null:
			check(int(it["durability"]) > 0, "gear wears: " + id)
		var weight: float = float(rules["slot_weight"].get(str(it["slot"]), 0)) * (1.5 if int(it.get("hands", 1)) == 2 else 1.0)
		if str(it["category"]) != "lantern":  # lanterns hold the off hand but give no protection
			check(int(it.get("kit", 0)) == int(round(tier * weight)), "kit rating is tier x slot weight: " + id)
		cover["%s/%s/%d" % [it["category"], it["kind"], tier]] = true
	for roll in affixes:
		check(rolled.has(roll), "stat roll is used by something: " + roll)

	# Coverage: every tier has every weapon family, shield and armour piece.
	for tier in range(1, 6):
		for fam in ["dagger", "sword", "war_axe", "mace", "spear", "greatsword", "bow", "crossbow"]:
			check(cover.has("weapon/%s/%d" % [fam, tier]), "tier %d has a %s" % [tier, fam])
		for sh in ["buckler", "kite_shield", "tower_shield"]:
			check(cover.has("shield/%s/%d" % [sh, tier]), "tier %d has a %s" % [tier, sh])
		for w in ["light", "medium", "heavy"]:
			for p in ["head", "body", "hands", "feet"]:
				check(cover.has("armour/%s/%s/%d" % [w, p, tier]), "tier %d has %s %s armour" % [tier, w, p])
	# Every trade has a tool for every tier it has expeditions (hunters use weapons).
	var tool_kind := {"logging": "felling_axe_kind", "mining": "pickaxe", "foraging": "sickle", "fishing": "fishing_rod", "farming": "hoe"}
	for s in sources:
		var trade: String = str(sources[s]["trade"])
		if tool_kind.has(trade):
			check(cover.has("tool/%s/%d" % [tool_kind[trade], int(sources[s]["tier"])]), "a tier-%d %s tool exists for %s" % [int(sources[s]["tier"]), trade, s])
		if trade == "hunting":
			check(cover.has("weapon/bow/%d" % int(sources[s]["tier"])), "a tier-%d bow exists for %s" % [int(sources[s]["tier"]), s])

	# Weapon balance: damage per second (with crits) near the sword's; two-handers a bit above.
	var sword_dps: Dictionary = {}
	for id in items:
		var it: Dictionary = items[id]
		if str(it["category"]) == "weapon" and str(it["kind"]) == "sword" and not bool(it.get("found_only", false)):
			sword_dps[int(it["tier"])] = Catalog.expected_dps(it["stats"])
	for id in items:
		var it: Dictionary = items[id]
		if str(it["category"]) != "weapon" or bool(it.get("found_only", false)):
			continue
		var ratio: float = Catalog.expected_dps(it["stats"]) / float(sword_dps[int(it["tier"])])
		if int(it.get("hands", 1)) == 2:
			check(ratio >= 1.05 and ratio <= 1.35, "%s two-hander damage is %.2fx a sword's" % [id, ratio])
		else:
			check(ratio >= 0.85 and ratio <= 1.15, "%s damage is %.2fx a sword's" % [id, ratio])
	# Daggers crit most; maces and greatswords swing slowest of the melee weapons.
	var dagger: Dictionary = items["iron_dagger"]["stats"]
	for id in ["rusted_sword", "iron_war_axe", "iron_mace", "iron_spear", "iron_greatsword"]:
		check(float(dagger["crit_chance"]) > float(items[id]["stats"]["crit_chance"]), "daggers crit more than " + id)
		check(float(dagger["attack_speed"]) > float(items[id]["stats"]["attack_speed"]), "daggers are faster than " + id)
	# Armour: heavy > medium > light for the same piece and tier; light dodges, heavy slows.
	for tier in range(1, 6):
		for p in ["head", "body", "hands", "feet"]:
			var by_weight: Dictionary = {}
			for id in items:
				var it: Dictionary = items[id]
				if str(it["category"]) == "armour" and int(it["tier"]) == tier and str(it["kind"]).ends_with("/" + p) and not bool(it.get("found_only", false)):
					by_weight[str(it.get("weight", ""))] = it["stats"]
			check(int(by_weight["heavy"]["armour"]) > int(by_weight["medium"]["armour"]) and int(by_weight["medium"]["armour"]) > int(by_weight["light"]["armour"]), "tier %d %s armour: heavy > medium > light" % [tier, p])
			check(float(by_weight["light"].get("dodge", 0)) > 0 and float(by_weight["heavy"].get("attack_speed", 0)) < 0, "tier %d %s: light dodges, heavy slows" % [tier, p])
	# Within a kind, the main stat rises with tier.
	var main: Dictionary = {}
	for id in items:
		var it: Dictionary = items[id]
		if bool(it.get("found_only", false)) or not it.has("stats"):
			continue
		var stat: String = "damage" if str(it["category"]) == "weapon" else ("armour" if str(it["category"]) in ["armour", "shield"] else "")
		if str(it["category"]) == "tool":
			stat = str(it["trade"])
		if stat == "":
			continue
		var k: String = str(it["kind"])
		main[k] = main.get(k, {})
		main[k][int(it["tier"])] = maxi(int(main[k].get(int(it["tier"]), 0)), int(it["stats"][stat]))
	for k in main:
		var tiers: Array = main[k].keys()
		tiers.sort()
		for i in range(1, tiers.size()):
			check(int(main[k][tiers[i]]) > int(main[k][tiers[i - 1]]), "%s gets stronger at tier %d" % [k, tiers[i]])
	# Found-only pieces beat crafted tier 4 and trail crafted tier 5.
	for id in items:
		var it: Dictionary = items[id]
		if not bool(it.get("found_only", false)) or str(it["category"]) != "weapon":
			continue
		check(int(it["stats"]["damage"]) > int(main[str(it["kind"])][4]) and int(it["stats"]["damage"]) < int(main[str(it["kind"])][5]), "found %s sits between tier 4 and 5" % id)

	# Dungeon minimums: a full kit of the dungeon's own tier gets in.
	var mins: Dictionary = rules["dungeon_min_kit"]
	var full: int = 0
	for s in rules["slot_weight"]:
		full += int(rules["slot_weight"][s])
	for d in mins:
		check(int(mins[d]) <= int(d) * full, "a full tier-%s kit enters the tier-%s dungeon" % [d, d])
	check(Catalog.kit_rating(["hand_axe", "leather"]) == 7, "kit rating adds up (%d)" % Catalog.kit_rating(["hand_axe", "leather"]))
	check(Catalog.kit_rating(["iron_greatsword"]) == 6, "two-handers count both hands")

	# In step with the live game: the quartermaster's stock exists at its old prices, and
	# every warehouse good is a catalog material or craftable good with the same name and price.
	var old_prices := {"hand_axe": 26, "felling_axe": 98, "basic_pick": 28, "reinforced_pick": 105, "rusted_sword": 30, "leather": 38}
	for key in MercsV05.SHOP:
		check(items.has(key) and not bool(items[key].get("found_only", false)) and int(items[key]["tier"]) == 1 or old_prices.has(key), "shop sells tier-1 starter gear: " + key)
	for key in old_prices:
		check(MercsV05.SHOP.has(key) and int(items.get(key, {}).get("value", 0)) == int(old_prices[key]), "shop price unchanged: " + key)
	for trade in ["foraging", "fishing", "hunting", "farming"]:
		check(MercsV05.SHOP.has(str(Mercs.STARTER_TOOL[trade])), "the quartermaster stocks a starter tool for " + trade)
	for key in ["dwarven_pick", "wardens_axe", "knights_blade", "gilded_plate"]:
		check(bool(items.get(key, {}).get("found_only", false)), "still found-only: " + key)
	for good in MoneyMercsState.RESOURCE_ORDER:
		var d: Dictionary = mats.get(good, items.get(good, {}))
		check(not d.is_empty(), "warehouse good in catalog: " + good)
		check(int(d.get("value", -1)) == int(MoneyMercsState.BASE_PRICE[good]), "base price matches the catalog: " + good)
		check(str(d.get("name", "")) == str(MoneyMercsState.RESOURCE_NAMES[good]), "name matches the catalog: " + good)
	# Every material a live site yields is a warehouse good.
	for site in TradeSites.SITES:
		for k in ["yields", "side"]:
			for good in site.get(k, {}):
				check(MoneyMercsState.RESOURCE_ORDER.has(good), "%s's %s can be stored" % [site["id"], good])
		for k in ["rare", "rare2"]:
			if site.has(k):
				check(MoneyMercsState.RESOURCE_ORDER.has(str(site[k]["good"])), "%s's rare find can be stored" % site["id"])
				check(mats.has(str(site[k]["good"])) and (mats[str(site[k]["good"])]["sources"] as Array).has(str(site["id"])), "catalog lists %s as a source of %s" % [site["id"], site[k]["good"]])
		for good in site.get("yields", {}):
			check(mats.has(good) and (mats[good]["sources"] as Array).has(str(site["id"])), "catalog lists %s as a source of %s" % [site["id"], good])
	for s in sources:
		if sources[s]["kind"] == "site" and sources[s]["status"] == "live":
			check(not TradeSites.by_id(s).is_empty(), "live site exists in the game: " + s)
	if failures > 0:
		push_error("%d catalog checks failed." % failures)
		quit(1)
		return
	print("Catalog passed: %d materials, %d items." % [mats.size(), items.size()])
	quit(0)
