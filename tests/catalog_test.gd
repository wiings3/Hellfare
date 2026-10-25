extends SceneTree
## Catalog integrity: no dead ends, sane prices, every tier covered, and in step with the live game.
var failures: int = 0

func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error("Catalog check failed: " + what)

func _initialize() -> void:
	var mats: Dictionary = Catalog.materials()
	var items: Dictionary = Catalog.items()
	var sources: Dictionary = Catalog.sources()
	check(mats.size() >= 15 and items.size() >= 30, "catalog loaded (%d materials, %d items)" % [mats.size(), items.size()])
	var rules: Dictionary = Catalog.rules()
	var markup_low: float = 1.1
	var markup_high: float = 2.2
	# Every material comes from somewhere real and goes somewhere.
	for id in mats:
		var m: Dictionary = mats[id]
		check(not (m["sources"] as Array).is_empty(), "material has a source: " + id)
		for s in m["sources"]:
			check(sources.has(s), "%s comes from a known source (%s)" % [id, s])
		check(bool(m["sell_only"]) or not Catalog.used_in(id).is_empty(), "material has a crafting use: " + id)
		check(float(m["value"]) > 0 and int(m["tier"]) >= 1 and int(m["tier"]) <= 5, "material value and tier: " + id)
	# Every item can be obtained, and crafting it pays but doesn't print money.
	var cover: Dictionary = {}
	for id in items:
		var it: Dictionary = items[id]
		var found: bool = bool(it.get("found_only", false))
		if found:
			check(it.get("recipe") == null and (it["blueprint"] as Array).is_empty(), "found-only can't be crafted: " + id)
			continue
		var recipe: Dictionary = it["recipe"]
		check(not recipe.is_empty(), "item has a recipe: " + id)
		for part in recipe:
			check(mats.has(part) or (items.has(part) and items[part]["kind"] == "intermediate"), "%s uses a known part (%s)" % [id, part])
			check(part != id, "recipe isn't circular: " + id)
		var ratio: float = float(it["value"]) / Catalog.recipe_cost(recipe)
		check(ratio >= markup_low and ratio <= markup_high, "%s is worth %.2fx its materials" % [id, ratio])
		var bps: Array = it["blueprint"]
		check(not bps.is_empty(), "item has a blueprint source: " + id)
		var tier: int = int(it["tier"])
		for bp in bps:
			check(sources.has(bp), "%s blueprint source known (%s)" % [id, bp])
			if str(bp) == "quartermaster":
				check(tier <= 2, "quartermaster only sells tier 1-2 blueprints: " + id)
			elif sources.has(bp) and sources[bp]["kind"] == "dungeon":
				check(int(sources[bp]["tier"]) + 2 == tier, "%s blueprint drops in the tier-%d dungeon" % [id, tier - 2])
		# No recipe needs materials above its own tier.
		for part in recipe:
			if mats.has(part) and not bool(mats[part]["sell_only"]):
				check(int(mats[part]["tier"]) <= maxi(tier, 1), "%s needs nothing above tier %d (%s)" % [id, tier, part])
		if str(it["slot"]) != "none":
			check(int(it["kit"]) == tier * int(rules["kit_per_tier"]), "kit rating follows tier: " + id)
			check(int(it["durability"]) > 0, "gear wears: " + id)
			cover["%s/%d" % [it["kind"], tier]] = true
	# Every tier has an axe, a pickaxe, a sword and armour.
	for tier in range(1, 6):
		for kind in ["axe", "pickaxe", "sword", "armour"]:
			check(cover.has("%s/%d" % [kind, tier]), "tier %d has a %s" % [tier, kind])
	# Better gear is always better: within a kind, the stat rises with tier.
	var best: Dictionary = {}
	for id in items:
		var it: Dictionary = items[id]
		if str(it["slot"]) == "none" or bool(it.get("found_only", false)):
			continue
		var stat: int = int((it["stats"] as Dictionary).values()[0])
		var key: String = str(it["kind"])
		best[key] = best.get(key, {})
		best[key][int(it["tier"])] = maxi(int(best[key].get(int(it["tier"]), 0)), stat)
	for kind in best:
		var tiers: Array = best[kind].keys()
		tiers.sort()
		for i in range(1, tiers.size()):
			check(int(best[kind][tiers[i]]) > int(best[kind][tiers[i - 1]]), "%s gets stronger at tier %d" % [kind, tiers[i]])
	# Dungeon minimums can be met with gear from the tier below.
	var mins: Dictionary = rules["dungeon_min_kit"]
	for d in mins:
		check(int(mins[d]) <= (int(d) + 1) * 10 * 2, "tier-%s dungeon is enterable with a tool and armour of tier %d" % [d, int(d) + 1])
	# In step with the live game: every equippable item and every good keeps its id.
	for key in MercsV05.ITEMS:
		var live: Dictionary = MercsV05.ITEMS[key]
		check(items.has(key), "live item in catalog: " + key)
		if items.has(key):
			check(str(items[key]["slot"]) == str(live["slot"]), "slot unchanged: " + key)
			check(str(items[key]["name"]) == str(live["name"]), "name unchanged: " + key)
			check(int(items[key]["value"]) == int(live["cost"]), "price unchanged: " + key)
			check(bool(items[key].get("found_only", false)) == bool(live.get("found", false)), "found-only unchanged: " + key)
	for good in MoneyMercsState.RESOURCE_ORDER:
		check(mats.has(good), "live good in catalog: " + good)
		if mats.has(good):
			check(int(mats[good]["value"]) == int(MoneyMercsState.BASE_PRICE[good]), "base price unchanged: " + good)
			check(str(mats[good]["name"]) == str(MoneyMercsState.RESOURCE_NAMES[good]) or good in ["timber", "copper", "iron"], "name unchanged: " + good)
	# Live sources are real sites.
	for s in sources:
		if sources[s]["kind"] == "site" and sources[s]["status"] == "live":
			check(not TradeSites.by_id(s).is_empty(), "live site exists in the game: " + s)
	check(Catalog.kit_rating(["hand_axe", "leather"]) == 20, "kit rating adds up")
	check(Catalog.kit_rating(["hand_axe", "leather"], ["leather"]) == 15, "worn gear counts half")
	if failures > 0:
		push_error("%d catalog checks failed." % failures)
		quit(1)
		return
	print("Catalog passed: %d materials, %d items." % [mats.size(), items.size()])
	quit(0)
