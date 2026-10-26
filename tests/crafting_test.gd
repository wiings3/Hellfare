extends SceneTree
## Crafting core: blueprints, recipes, rarity rolls, ten-slot gear, wear and repairs, food and
## potions, kit rating, and older saves (in-memory company, no save file).
var failures: int = 0

func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error("Crafting check failed: " + what)

func _initialize() -> void:
	MoneyMercsState.persist = false
	var now: int = 1_900_000_000
	GameClock.fixed = now
	var g := MoneyMercsState.new()
	g.reset_company()
	g.gold = 100000

	# Blueprints: the quartermaster sells tier 1-2 only; intermediates are known to everyone.
	for key in g.blueprint_shop():
		check(int(Catalog.item(key)["tier"]) <= 2, "quartermaster blueprint is tier 1-2: " + str(key))
	check(not g.blueprint_shop().has("silversteel_pick"), "tier-3 blueprints aren't sold")
	check(g.knows("steel_ingot") and not g.knows("iron_war_axe"), "ingots known, gear needs a blueprint")
	for key in ["leather", "leather_cap", "leather_gloves", "leather_boots"]:
		check(g.knows(key), "a new company can craft %s" % key)
		check(not g.blueprint_shop().has(key), "%s isn't sold as a blueprint" % key)
	check(g.craft("iron_war_axe").contains("blueprint"), "can't craft without the blueprint")
	var gold0: int = g.gold
	check(g.buy_blueprint("iron_war_axe").begins_with("Bought"), "buy a blueprint")
	check(g.gold == gold0 - int(Catalog.item("iron_war_axe")["blueprint_price"]) and g.knows("iron_war_axe"), "paid, and known")
	check(g.buy_blueprint("silversteel_pick").contains("dungeons"), "can't buy tier-3 blueprints")

	# Recipes use the warehouse.
	check(g.craft("steel_ingot").begins_with("Not enough"), "missing materials refused")
	g.resources["iron"] = 2
	g.resources["coal"] = 1
	check(g.craft("steel_ingot") == "Crafted Steel Ingot.", "smelt steel")
	check(int(g.resources["iron"]) == 0 and int(g.resources["coal"]) == 0 and int(g.resources["steel_ingot"]) == 1, "materials used, ingot stored")

	# Crafted gear rolls rarity at the catalog's odds, with stats from its family's pool.
	var counts: Dictionary = {}
	var pool: Array = Catalog.item("iron_war_axe")["rolls"]
	for i in range(1000):
		g.resources["iron"] = 2
		g.resources["timber"] = 2
		g.craft("iron_war_axe")
		var item: Dictionary = g.equipment_inventory.back()
		var r: String = str(item["rarity"])
		counts[r] = int(counts.get(r, 0)) + 1
		check((item["rolls"] as Dictionary).size() == int(Gear.rarity_def(r)["affixes"]), "%s has %d rolls" % [r, (item["rolls"] as Dictionary).size()])
		for stat in item["rolls"]:
			check(pool.has(stat), "rolls come from the axe's pool (%s)" % stat)
			var a: Dictionary = Catalog.data()["affixes"][stat]
			check(int(item["rolls"][stat]) >= int(a["low"]) and int(item["rolls"][stat]) <= int(a["high"]), "tier-1 roll within range")
		check(Gear.durability(item) == Gear.max_durability(item) and Gear.max_durability(item) >= 30, "crafted at full durability")
	check(int(counts.get("common", 0)) > 520 and int(counts.get("common", 0)) < 680, "about 60%% common (%d)" % int(counts.get("common", 0)))
	check(int(counts.get("fine", 0)) > 220 and int(counts.get("fine", 0)) < 340, "about 28%% fine (%d)" % int(counts.get("fine", 0)))
	check(int(counts.get("masterwork", 0)) > 3 and int(counts.get("masterwork", 0)) < 45, "about 2%% masterwork (%d)" % int(counts.get("masterwork", 0)))
	var fine: Dictionary = {}
	for item in g.equipment_inventory:
		if str(item["rarity"]) == "superior":
			fine = item
			break
	check(Gear.value(fine) > int(Catalog.item("iron_war_axe")["value"]), "finer rolls are worth more")
	g.equipment_inventory.clear()

	# Ten slots. Tools set the job; a weapon makes a guard; two-handers take both hands.
	var miner: String = ""
	for c in g.recruitment_board():
		if Mercs.best_trade(c) == "mining" and miner == "":
			if g.hire(str(c["id"])).contains("joined"):
				miner = str(c["id"])
	var m: Dictionary = g.merc_by_id(miner)
	check((m["equipment"] as Dictionary).size() == 10 and Gear.job(m) == "mining", "ten slots, pickaxe in hand")
	g.equipment_inventory.append(g.make_item("steel_kite_shield", "common"))
	check(g.equip_item(miner, str(g.equipment_inventory.back()["uid"])).contains("equipped"), "shield in the off hand")
	g.equipment_inventory.append(g.make_item("iron_greatsword", "common"))
	check(g.equip_item(miner, str(g.equipment_inventory.back()["uid"])).contains("equipped"), "a greatsword")
	check(Gear.job(m) == "combat" and Gear.in_slot(m, "off_hand").is_empty(), "two hands: the shield goes back to the storeroom")
	check(Mercs.guard_level(m) == Mercs.level(m, "combat") + 2, "a tier-1 weapon guards two levels higher")
	var shield_uid: String = ""
	for item in g.equipment_inventory:
		if str(item["key"]) == "steel_kite_shield":
			shield_uid = str(item["uid"])
	check(g.equip_item(miner, shield_uid).contains("both hands"), "no shield with a two-hander")
	for item in g.equipment_inventory.duplicate():
		if str(item["key"]) == "basic_pick":
			g.equip_item(miner, str(item["uid"]))
	check(Gear.job(m) == "mining", "back to the pickaxe")
	g.equip_item(miner, shield_uid)

	# Armour lowers injury and death; kit rating adds up tier x slot weight.
	var bare: float = Gear.injury_mult(m)
	for key in ["steel_helm", "steel_cuirass", "steel_gauntlets", "steel_greaves"]:
		g.equipment_inventory.append(g.make_item(key, "common"))
		g.equip_item(miner, str(g.equipment_inventory.back()["uid"]))
	check(Gear.armour(m) > 40 and Gear.injury_mult(m) < bare * 0.8 and Gear.death_mult(m) < 0.75, "plate protects (%.0f armour)" % Gear.armour(m))
	check(Gear.kit_rating(m) == 1 * 4 + 2 * 2 + 2 * (1 + 3 + 1 + 1), "kit rating (%d)" % Gear.kit_rating(m))

	# Every trip wears gear; long orders three times as much; worn-out tools work at half effect.
	var pick: Dictionary = Gear.in_slot(m, "main_hand")
	var ids: Array[String] = [miner]
	var before: int = Gear.durability(pick)
	check(g.site_dispatch("harlow", ids, "Balanced").begins_with("The crew set out"), "a trip")
	g.missions[0]["death"] = 0.0
	g.complete_due(now + 3600)
	check(Gear.durability(Gear.in_slot(m, "main_hand")) == before - 1, "a trip wears 1")
	check(Gear.durability(Gear.in_slot(m, "body")) == Gear.max_durability(Gear.in_slot(m, "body")) - 1, "armour wears too")
	g.gold = 100000
	check(g.site_dispatch("harlow", ids, "Overnight").begins_with("The crew set out"), "a long trip")
	g.missions[0]["death"] = 0.0
	g.complete_due(now + 20 * 3600)
	check(Gear.durability(Gear.in_slot(m, "main_hand")) == before - 4, "a long trip wears 3")
	m["health"] = 100
	var fresh: float = Gear.tool_power(m, "mining")
	Gear.in_slot(m, "main_hand")["dur"] = 0
	check(Gear.worn_out(Gear.in_slot(m, "main_hand")) and is_equal_approx(Gear.tool_power(m, "mining"), fresh * 0.5), "worn out: half effect")

	# Repairs: part of the recipe plus a handle of the tier's timber; missing goods are bought.
	var cost: Dictionary = g.repair_cost(Gear.in_slot(m, "main_hand"))
	check(cost.has("timber") and not cost.has("gold"), "a tier-1 pickaxe is mended with birch (%s)" % str(cost))
	var big: Dictionary = g.make_item("reinforced_pick", "common")
	big["dur"] = 0
	check(g.repair_cost(big).has("iron") and g.repair_cost(big).has("oak"), "a tier-2 pickaxe takes iron and oak (%s)" % str(g.repair_cost(big)))
	g.resources["timber"] = 0
	g.resources["iron"] = 0
	var gold1: int = g.gold
	check(g.repair(str(Gear.in_slot(m, "main_hand")["uid"])).begins_with("Repaired"), "repair")
	check(Gear.durability(Gear.in_slot(m, "main_hand")) == Gear.max_durability(Gear.in_slot(m, "main_hand")) and g.gold < gold1, "full again, materials bought")
	check(g.repair(str(Gear.in_slot(m, "main_hand")["uid"])).contains("doesn't need"), "nothing to repair")
	var found: Dictionary = g.make_item("knights_blade")
	found["dur"] = 50
	check(str(found["rarity"]) == "found" and g.repair_cost(found).has("gold") and g.repair_cost(found).size() == 1, "found-only pieces are repaired for gold")
	var oak_cost: Dictionary = g.make_item("steel_buckler", "common")
	oak_cost["dur"] = 0
	check(g.repair_cost(oak_cost).has("oak"), "tier-2 gear is repaired with oak")

	# Potions and food. A healing draught is drunk when hurt; food is eaten on the way.
	g.resources["healing_draught"] = 1
	check(g.equip_supply(miner, "healing_draught").contains("packed"), "pack a draught")
	check(int(g.resources["healing_draught"]) == 0, "taken from the warehouse")
	m["health"] = 100
	check(g.site_dispatch("harlow", ids, "Balanced").begins_with("The crew set out"), "a trip with a draught")
	g.missions[0]["death"] = 0.0
	g.missions[0]["injury"] = 100.0  # certain, even through plate
	g.complete_due(now + 40 * 3600)
	check(Gear.in_slot(m, "potion").is_empty() and int(m["health"]) >= 90, "hurt, then healed by the draught (%d)" % int(m["health"]))
	m["health"] = 100
	var plain: float = float(g.site_forecast("harlow", ids, "Balanced")["units"]["copper"])
	m["equipment"]["food"] = {"key": "grilled_perch"}
	var fed: float = float(g.site_forecast("harlow", ids, "Balanced")["units"]["copper"])
	check(fed > plain * 1.04, "food buffs the haul (%.2f vs %.2f)" % [fed, plain])
	check(g.site_dispatch("harlow", ids, "Balanced").begins_with("The crew set out"), "a fed trip")
	check(Gear.in_slot(m, "food").is_empty() and is_equal_approx(float(g.missions[0]["buffs"][miner]["yield"]), 5.0), "food eaten at the start, its buff carried")
	g.missions[0]["death"] = 0.0
	g.complete_due(now + 60 * 3600)

	# The quartermaster still sells the starter gear (common), nothing else.
	check(g.buy_equipment("hand_axe").begins_with("Purchased") and str(g.equipment_inventory.back()["rarity"]) == "common", "shop gear is common")
	check(g.buy_equipment("iron_war_axe").contains("crafted"), "other gear must be crafted")

	# Sites yield what the catalog says.
	check(TradeSites.by_id("old_oakwood")["yields"].has("oak"), "the Oakwood yields oak")

	# Older saves: "tool" and "armor" become main hand and body; items gain rarity and durability.
	var old: Dictionary = {"id": "o", "equipment": {"tool": {"uid": "x", "key": "felling_axe"}, "armor": {"uid": "y", "key": "chainmail"}}}
	Gear.ensure(old)
	check(str(Gear.in_slot(old, "main_hand")["key"]) == "felling_axe" and str(Gear.in_slot(old, "body")["key"]) == "chainmail", "old slots migrate")
	check(not (old["equipment"] as Dictionary).has("tool") and str(Gear.in_slot(old, "body")["rarity"]) == "common" and Gear.durability(Gear.in_slot(old, "body")) == 40, "old items become common at full durability")

	GameClock.fixed = -1
	if failures > 0:
		push_error("%d crafting checks failed." % failures)
		quit(1)
		return
	print("Crafting, gear, wear, repairs and supplies passed.")
	quit(0)
