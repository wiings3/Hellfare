extends "res://scripts/company_state_base.gd"
class_name MoneyMercsState
## Harlow mine mechanics and expedition settlement.
## All existing MoneyMercsState methods, state fields and save keys are retained.

# Harlow Mines: separate persistent rotation state, scouting, and role-based work.
# This is the first vertical slice. Existing jobs remain backward compatible.
const HARLOW_ROTATION_SECONDS := 3600
const HARLOW_ENEMIES := [
	{"name": "Sleeping Dire Wolf", "danger": 3, "note": "Territorial predator near the lower shafts"},
	{"name": "Goblin Prospectors", "danger": 2, "note": "A band of armed scavengers"},
	{"name": "Cave Spiders", "danger": 1, "note": "Nest signs around the old supports"},
	{"name": "Ancient Cave Troll", "danger": 4, "note": "Huge tracks vanish into the rock"}
]

func harlow_sync(now: int = -1) -> bool:
	if now < 0:
		now = GameClock.now()
	var rotation: int = int(now / HARLOW_ROTATION_SECONDS)
	var changed := false
	if int(harlow.get("rotation", -1)) != rotation:
		var archives: Dictionary = harlow.get("archives", {})
		var ongoing_scout: int = int(harlow.get("scout_finish", 0))
		if harlow.has("rotation"):
			archives[str(int(harlow["rotation"]))] = (harlow.get("deposits", {}) as Dictionary).duplicate(true)
		var randomizer := RandomNumberGenerator.new()
		randomizer.seed = int(rotation * 15427 + 28483)
		# Hourly rotations with enough ore for a few good trips (the simulator found the
		# old 4-hour, ~10-ore rotations could never pay the wages).
		var ore: Dictionary = {
			"copper": randomizer.randi_range(25, 40),
			"iron": randomizer.randi_range(10, 22),
			"silver": (1 if randomizer.randf() < 0.35 else 0) + (1 if randomizer.randf() < 0.10 else 0)
		}
		if randomizer.randf() < 0.08:
			ore["crystal"] = 1
		var creature: Dictionary = HARLOW_ENEMIES[randomizer.randi_range(0, HARLOW_ENEMIES.size() - 1)]
		var old_scout_level: int = int(harlow.get("scout_level", 1))
		harlow = {
			"rotation": rotation,
			"deposits": ore,
			"original": ore.duplicate(true),
			"enemy": creature.duplicate(true),
			"scout_level": clampi(old_scout_level, 1, 3),
			"scout_finish": ongoing_scout,
			"report": {},
			"fallen": harlow.get("fallen", []),
			"archives": archives
		}
		changed = true
	var finish: int = int(harlow.get("scout_finish", 0))
	if finish > 0 and now >= finish:
		var ores: Dictionary = harlow.get("deposits", {})
		var lead: String = "copper"
		for key in ["copper", "iron", "silver", "crystal"]:
			if int(ores.get(key, 0)) > int(ores.get(lead, 0)):
				lead = key
		var available: int = int(ores.get(lead, 0))
		var scout_level: int = int(harlow.get("scout_level", 1))
		var min_seen: int = maxi(0, available - maxi(0, 3 - scout_level))
		var findings: Dictionary = {"primary": lead, "minimum": min_seen, "creature": str(harlow["enemy"]["name"]), "exact": scout_level == 3}
		if scout_level >= 2:
			findings["all_ore"] = ores.duplicate(true) if scout_level == 3 else {"copper": maxi(0, int(ores.get("copper", 0)) - 1), "iron": maxi(0, int(ores.get("iron", 0)) - 1)}
		if scout_level >= 2:
			findings["threat_note"] = str(harlow["enemy"]["note"])
			findings["danger_band"] = "Severe" if int(harlow["enemy"]["danger"]) >= 3 else "Moderate"
		if scout_level == 3:
			findings["danger"] = int(harlow["enemy"]["danger"])
			findings["all_ore"] = ores.duplicate(true)
		harlow["report"] = findings
		harlow["scout_finish"] = 0
		changed = true
	if changed:
		save_game()
	return changed

func harlow_rotation_remaining(now: int = -1) -> int:
	if now < 0:
		now = GameClock.now()
	return HARLOW_ROTATION_SECONDS - (now % HARLOW_ROTATION_SECONDS)

func harlow_scout_seconds() -> int:
	match int(harlow.get("scout_level", 1)):
		2: return 40
		3: return 25
	return 60

func harlow_send_scout() -> String:
	harlow_sync()
	if int(harlow.get("scout_finish", 0)) > 0:
		return "Your scout is already surveying Harlow Mines."
	if not (harlow.get("report", {}) as Dictionary).is_empty():
		return "Your scout already reported on this rotation."
	harlow["scout_finish"] = GameClock.now() + harlow_scout_seconds()
	save_game()
	return "Scout dispatched. The report will arrive even if you close the game."

func harlow_upgrade_scout() -> String:
	harlow_sync()
	var level: int = int(harlow.get("scout_level", 1))
	if level >= 3:
		return "Your scout has reached maximum proficiency."
	if int(harlow.get("scout_finish", 0)) > 0:
		return "Wait until your scout returns before upgrading."
	var cost: int = 200 if level == 1 else 650
	if gold < cost:
		return "Scout training requires %d gold." % cost
	gold -= cost
	harlow["scout_level"] = level + 1
	save_game()
	return "Scout promoted to level %d. Future surveys will be faster and more detailed." % (level + 1)

func harlow_crew_stats(ids: Array[String], approach: String) -> Dictionary:
	harlow_sync()
	var workers: Array[Dictionary] = []
	for id in ids:
		var merc: Dictionary = merc_by_id(id)
		if not merc.is_empty() and is_available(merc):
			workers.append(merc)
	var threat: int = int((harlow.get("enemy", {}) as Dictionary).get("danger", 2))
	return V05.assess_party(workers, approach, threat, 18)

func _harlow_cost(ids: Array[String]) -> int:
	var total := 18
	for id in ids:
		var merc: Dictionary = merc_by_id(id)
		if not merc.is_empty():
			total += int(terms(merc)["wage"])
	return total

func harlow_dispatch(ids: Array[String], approach: String) -> String:
	harlow_sync()
	if not TACTICS.has(approach):
		return "Unrecognized standing orders."
	if ids.is_empty() or ids.size() > 3:
		return "Choose between one and three workers."
	if missions.size() >= expedition_slots:
		return "No expedition slots are free."
	var seen: Dictionary = {}
	for id in ids:
		var merc := merc_by_id(id)
		if merc.is_empty() or not is_available(merc) or seen.has(id):
			return "A selected mercenary is unavailable."
		if int(merc.get("health", 100)) < 25:
			return "%s is too injured for deployment." % str(merc["name"])
		seen[id] = true
	var stats: Dictionary = harlow_crew_stats(ids, approach)
	if int(stats["miners"]) == 0:
		return "Someone needs a pickaxe to collect ore."
	if gold < int(stats["wage"]):
		return "Insufficient gold for wages and provisions."
	var available: Dictionary = harlow.get("deposits", {})
	var remaining: int = 0
	for ore_id in available:
		remaining += int(available[ore_id])
	if remaining <= 0:
		return "Harlow Mines have been exhausted this rotation."
	gold -= int(stats["wage"])
	var now := GameClock.now()
	var key := "job_%d" % next_mission_id
	next_mission_id += 1
	var share := 0.0
	for id in ids:
		var merc: Dictionary = merc_by_id(id)
		merc["mission_id"] = key
		share += float(terms(merc)["cut"])
	missions.append({
		"id": key, "region": "harlow", "ids": ids.duplicate(),
		"tactic": approach, "cost": int(stats["wage"]), "chance": float(stats["success"]),
		"death": stats["death"], "capacity": int(stats["capacity"]),
		"threat": (harlow.get("enemy", {}) as Dictionary).duplicate(true),
		"equipped": _snapshot_equipment(ids), "v05": true,
		"share": minf(share, 0.85), "seed": randi(),
		"rotation": int(harlow["rotation"]), "snapshot": available.duplicate(true),
		"started": now, "finish": now + int(stats["duration"])
	})
	_roll_fallen(missions.back(), "harlow")
	save_game()
	return "Harlow expedition funded. Your crew is heading underground."

func _snapshot_equipment(ids: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	for id in ids:
		var merc: Dictionary = merc_by_id(id)
		if not merc.is_empty():
			result[id] = (merc.get("equipment", {}) as Dictionary).duplicate(true)
	return result

func _harlow_finish(mission: Dictionary) -> void:
	if bool(mission.get("v05", false)):
		_harlow_finish_v05(mission)
	else:
		_harlow_finish_legacy(mission)

func _harlow_finish_legacy(mission: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(mission["seed"])
	var succeeded := rng.randf() < float(mission["chance"])
	var dead_names: Array[String] = []
	var injured_names: Array[String] = []
	var alive: int = 0
	for merc_id in mission["ids"]:
		var merc: Dictionary = merc_by_id(str(merc_id))
		if merc.is_empty():
			continue
		var risk: float = float(mission["death"])
		# Risk shown at dispatch is unconditional; outcomes modulate it.
		var outcome_risk: float = risk * (0.35 if succeeded else 1.7)
		if rng.randf() < outcome_risk:
			dead_names.append(str(merc["name"]))
			var list: Array = harlow.get("fallen", [])
			list.push_front({"name": str(merc["name"]), "gear": int(merc.get("gear", 0)), "xp": int(merc.get("xp", 0)), "region": "Harlow Mines", "time": int(mission["finish"])})
			harlow["fallen"] = list
			crew.erase(merc)
		else:
			alive += 1
			merc["mission_id"] = ""
			merc["xp"] = int(merc.get("xp", 0)) + (2 if succeeded else 1)
			if not succeeded and rng.randf() < 0.70:
				merc["health"] = maxi(20, int(merc.get("health", 100)) - rng.randi_range(12, 35))
				injured_names.append(str(merc["name"]))
	var loot: Dictionary = {}
	var cap: int = int(mission["capacity"]) if succeeded else maxi(0, int(mission["capacity"]) / 3)
	if alive == 0:
		cap = 0
	# A rotated site does not deplete the NEW rotation. Concurrent jobs never clone veins.
	var current_rotation: bool = int(mission["rotation"]) == int(harlow.get("rotation", -1))
	var from: Dictionary = harlow["deposits"] if current_rotation else mission.get("snapshot", {})
	for key in ["copper", "iron", "silver", "crystal"]:
		var extraction: int = mini(cap, int(from.get(key, 0)))
		if extraction <= 0:
			continue
		cap -= extraction
		loot[key] = extraction
		if current_rotation:
			harlow["deposits"][key] = int(harlow["deposits"][key]) - extraction
	var coins: int = rng.randi_range(7, 18) if succeeded and alive > 0 else 0
	var gross: int = coins
	for key in loot:
		resources[key] = int(resources.get(key, 0)) + int(loot[key])
		gross += int(loot[key]) * price(str(key))
	var commission := int(ceil(float(gross) * float(mission["share"])))
	gold += coins - commission
	_earn_reputation(gross, alive == 0)
	reports.push_front({
		"region": "Harlow Mines", "won": succeeded, "loot": loot,
		"cash": coins, "commission": commission, "cost": int(mission["cost"]),
		"gross": gross, "tactic": str(mission["tactic"]), "crew": mission["ids"],
		"time": int(mission["finish"]), "casualties": dead_names,
		"injured": injured_names, "rotation": int(mission["rotation"]),
		"extracted": loot.duplicate(true)
	})
	if reports.size() > 35:
		reports.resize(35)


func _harlow_finish_v05(mission: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(mission["seed"])
	var enemy: Dictionary = mission.get("threat", {"name": "Unknown creature", "danger": 2})
	var orders: String = str(mission["tactic"])
	var events: Array[String] = []
	var casualties: Array[String] = []
	var wounded: Array[String] = []
	var lost_items: Array[String] = []
	var dead_ids: Array[String] = []
	var left_behind: Array[String] = []
	var success: bool = rng.randf() < float(mission["chance"])
	events.append("The crew entered the shafts with %s standing orders." % orders.to_lower())
	events.append("%s was encountered in the tunnels." % str(enemy.get("name", "An unknown threat")))
	var survivors: Array[Dictionary] = []
	var effective_capacity: int = 0
	var living_miners: int = 0
	var risks: Dictionary = mission.get("death", {})
	# Death is resolved per worker. The odds were locked at dispatch time.
	for merc_id in mission["ids"]:
		var id: String = str(merc_id)
		var worker: Dictionary = merc_by_id(id)
		if worker.is_empty():
			continue
		var risk: float = float(risks.get(id, 0.15))
		if rng.randf() < risk:
			casualties.append(str(worker["name"]))
			dead_ids.append(id)
			left_behind.append_array(_drop_on_death("harlow", worker, int(mission["finish"]), rng))
			retired_ids.append(id)
			var equipped: Dictionary = worker.get("equipment", {})
			for item in Gear.worn(worker):
				lost_items.append("%s — %s" % [str(worker["name"]), Gear.full_name(item)])
			var legacy_tier: int = int(worker.get("gear", 0))
			if legacy_tier > 0:
				lost_items.append("%s — tier %d legacy outfitting" % [str(worker["name"]), legacy_tier])
			var memorial: Array = harlow.get("fallen", [])
			memorial.push_front({"name": str(worker["name"]), "equipment": equipped.duplicate(true),
				"gear": legacy_tier, "xp": int(worker.get("xp", 0)),
				"region": "Harlow Mines", "time": int(mission["finish"])})
			harlow["fallen"] = memorial
			crew.erase(worker)
		else:
			survivors.append(worker)
			worker["mission_id"] = ""
			worker["xp"] = int(worker.get("xp", 0)) + (2 if success else 1)
			if rng.randf() < (0.12 if success else 0.48):
				worker["health"] = maxi(20, int(worker.get("health", 100)) - rng.randi_range(8, 31))
				wounded.append(str(worker["name"]))
			if Mercs.job(worker) == "mining":
				living_miners += 1
				var gear_stats: Dictionary = V05.equipment_stats(worker)
				effective_capacity += 6 + int(gear_stats["mining"])
	if not casualties.is_empty():
		events.append("%s fell. Their personal equipment was lost." % ", ".join(casualties))
	if not left_behind.is_empty():
		events.append("Some of their gear stayed in the shafts: %s. Another company may find it." % ", ".join(left_behind))
	if not wounded.is_empty():
		events.append("%s returned injured." % ", ".join(wounded))
	var extractable: int = 0
	if living_miners > 0:
		if success:
			extractable = effective_capacity
			events.append("The crew secured the seam and worked the ore veins.")
		else:
			var fraction: float = rng.randf_range(0.3, 0.68)
			if orders == "Cautious":
				fraction = maxf(fraction, 0.48)
			extractable = maxi(1, int(round(float(effective_capacity) * fraction)))
			events.append("The team retreated after recovering part of the deposit.")
	else:
		events.append("No miner escaped with recoverable ore.")
	var key: String = str(mission["rotation"])
	var current: bool = int(mission["rotation"]) == int(harlow.get("rotation", -1))
	var source: Dictionary = {}
	if current:
		source = harlow.get("deposits", {})
	else:
		var archives: Dictionary = harlow.get("archives", {})
		if not archives.has(key):
			archives[key] = (mission.get("snapshot", {}) as Dictionary).duplicate(true)
			harlow["archives"] = archives
		source = archives[key]
	var loot: Dictionary = {}
	var order: Array[String] = ["copper", "iron", "silver", "crystal"]
	if rng.randf() < 0.3:
		order = ["iron", "copper", "silver", "crystal"]
	for ore in order:
		var count: int = mini(extractable, int(source.get(ore, 0)))
		if count <= 0:
			continue
		loot[ore] = count
		source[ore] = int(source[ore]) - count
		extractable -= count
		if extractable <= 0:
			break
	if current:
		harlow["deposits"] = source
	else:
		harlow["archives"][key] = source
	var gathered: Array[String] = []
	for ore in loot:
		resources[ore] = int(resources.get(ore, 0)) + int(loot[ore])
		gathered.append("%d %s" % [int(loot[ore]), str(RESOURCE_NAMES.get(ore, ore))])
	if not gathered.is_empty():
		events.append("Survivors delivered %s." % ", ".join(gathered))
	var finds: Array[String] = []
	var find_value: int = _settle_finds(mission, "harlow", dead_ids, events, finds)
	var coins: int = rng.randi_range(5, 15) if not survivors.is_empty() else 0
	var gross: int = coins + find_value
	for ore in loot:
		gross += int(loot[ore]) * price(str(ore))
	# Short-term v0.5 arrangement: percentage of found coins, NOT
	# entire unsold haul. Prevents negative balances on lucky item drops.
	var commission: int = mini(coins, int(ceil(float(coins) * float(mission["share"]))))
	var value: int = coins - commission + find_value
	for ore in loot:
		value += int(loot[ore]) * sell_price(str(ore), int(loot[ore]))
	gold += coins - commission
	_apply_relief_payment()
	_earn_reputation(value, survivors.is_empty())
	reports.push_front({
		"region": "Harlow Mines", "won": success, "loot": loot,
		"cash": coins, "commission": commission, "cost": int(mission["cost"]),
		"gross": gross, "tactic": orders, "crew": mission["ids"],
		"time": int(mission["finish"]), "casualties": casualties,
		"injured": wounded, "lost_items": lost_items, "found_items": finds,
		"events": events, "partial": not success and not loot.is_empty(),
		"rotation": int(mission["rotation"]), "extracted": loot.duplicate(true),
		"value": value, "trade": "mining", "site": "harlow",
		"found_gear": mission.get("found_keys", [])
	})
	if reports.size() > 35:
		reports.resize(35)


# --- Generic trade sites (data in sites.gd) -------------------------------------

func _roll_avg(rng: RandomNumberGenerator, span: Array, rolls: int) -> float:
	var total: int = 0
	for i in range(rolls):
		total += rng.randi_range(int(span[0]), int(span[1]))
	return float(total) / float(rolls)

func _tool_bonus(merc: Dictionary, trade: String) -> float:
	return Gear.tool_power(merc, trade)

## Buffs from the food and potion a mercenary is carrying (healing potions are kept for
## when they're hurt). Values are percents, e.g. {"yield": 5, "injury": -10}.
func _trip_buffs(merc: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for slot in ["food", "potion"]:
		var b: Dictionary = Gear.buffs(merc, slot)
		if b.has("heal"):
			continue
		for k in b:
			out[k] = float(out.get(k, 0.0)) + float(b[k])
	return out

## Personal haul multiplier: tool pace, traits, gear and food.
func _haul(merc: Dictionary, trade: String, buffs: Dictionary) -> float:
	return _effort(merc, trade) * Mercs.haul_mult(merc) * Gear.haul_mult(merc) * (1.0 + (float(buffs.get("yield", 0.0)) + float(buffs.get("yield_" + trade, 0.0))) / 100.0)

## The right tool works at full pace; anything else (a weapon, the wrong tool, bare hands)
## at half pace. Whoever holds a weapon stands guard.
func _effort(merc: Dictionary, trade: String) -> float:
	if trade == "hunting":
		return 1.0 if Gear.hunts(merc) else 0.5
	return 1.0 if Mercs.job(merc) == trade else 0.5

## Whoever holds a weapon stands guard, except a hunter on a hunt: their bow is their tool,
## so they work the hunt and don't also shield the crew.
func _stands_guard(merc: Dictionary, trade: String) -> bool:
	return Mercs.job(merc) == "combat" and not (trade == "hunting" and Gear.hunts(merc))

## Bone meal spread on the fields: +15% on a farming trip (one is used per trip).
const BONE_MEAL_BONUS := 1.15

func _fertilised(trade: String) -> bool:
	return trade == "farming" and int(resources.get("bone_meal", 0)) > 0

## Blueprints that can turn up at a site: its tier's tools, food, trinkets and packs not yet
## owned. Chance per trip, more on long trips.
const BLUEPRINT_FIND := 0.02

func site_blueprints(site_id: String) -> Array:
	var out: Array = []
	for key in Catalog.items():
		if (Catalog.items()[key].get("blueprint", []) as Array).has(site_id) and not blueprints.has(key):
			out.append(key)
	out.sort()
	return out

## Rare-find chance for a crew (longer trips find more; a Keen eye finds half again as often).
func _rare_chance(rare: Dictionary, order: Dictionary, workers: Array, buffs: Dictionary = {}) -> float:
	var chance: float = float(rare["chance"]) * maxf(1.0, float(order.get("duration", 1.0)))
	if Mercs.crew_has(workers, "keen_eye"):
		chance *= 1.5
	var best: float = 1.0
	for merc in workers:
		var b: Dictionary = buffs.get(str(merc.get("id", "")), _trip_buffs(merc))
		best = maxf(best, Gear.rare_mult(merc) * (1.0 + float(b.get("rare_find", 0.0)) / 100.0))
	return minf(0.9, chance * best)

func _crew(ids: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in ids:
		var merc: Dictionary = merc_by_id(id)
		if not merc.is_empty() and is_available(merc):
			result.append(merc)
	return result

## Everything the planner shows before committing: haul, value, cost, profit, risk.
func site_forecast(site_id: String, ids: Array[String], approach: String) -> Dictionary:
	var site: Dictionary = TradeSites.by_id(site_id)
	var workers: Array[Dictionary] = _crew(ids)
	var trade: String = str(site.get("trade", "logging"))
	var order: Dictionary = TradeSites.order_for(site, approach)
	var guards: int = 0
	var best_level: int = 0
	var best_combat: int = 1
	var wages: int = 0
	var share: float = 0.0
	var units: Dictionary = {}
	var leader: float = (1.1 if Mercs.crew_has(workers, "born_leader") else 1.0) * (BONE_MEAL_BONUS if _fertilised(trade) else 1.0)
	var saved: float = 0.0
	var quicker: float = 0.0
	var guarded: float = 0.0
	var armoured: float = 0.0
	for merc in workers:
		var level: int = TradeSkills.level_of(merc, trade)
		best_level = maxi(best_level, level)
		best_combat = maxi(best_combat, Mercs.guard_level(merc))
		var guard: bool = _stands_guard(merc, trade)
		if guard:
			guards += 1
		var buffs: Dictionary = _trip_buffs(merc)
		var effort: float = _haul(merc, trade, buffs) * leader
		saved = maxf(saved, Gear.speed(merc))
		quicker = minf(quicker, float(buffs.get("duration", 0.0)) / 100.0)
		guarded += Gear.injury_mult(merc) * (1.0 + float(buffs.get("injury", 0.0)) / 100.0)
		armoured += Gear.death_mult(merc)
		for good in site.get("yields", {}):
			units[good] = float(units.get(good, 0.0)) + TradeSites.worker_yield(site["yields"][good], level, _tool_bonus(merc, trade) * float(site.get("tool", 1.0))) * effort * float(order["yield"])
		for good in site.get("side", {}):
			units[good] = float(units.get(good, 0.0)) + TradeSites.worker_yield(site["side"][good], 1, 0) * float(order["yield"])
		var t: Dictionary = terms(merc)
		wages += int(t["wage"])
		share += float(t["cut"])
	if not workers.is_empty():
		share = share / float(workers.size())
	var value: float = 0.0
	for good in units:
		var kept: float = float(units[good]) * (1.0 - share)
		value += kept * float(sell_price(str(good), int(round(kept))))
	for rare_key in ["rare", "rare2"]:
		var rare: Dictionary = site.get(rare_key, {})
		if not rare.is_empty() and not workers.is_empty():
			value += _rare_chance(rare, order, workers) * float(rare["count"]) * float(sell_price(str(rare["good"])))
	var protect: float = TradeSites.protection(guards, best_combat)
	var injury: float = minf(TradeSites.MAX_INJURY, float(site.get("injury", 0.0)) * float(order["risk"]) * (1.0 - protect))
	var death: float = minf(TradeSites.MAX_DEATH, float(site.get("death", 0.0)) * float(order["risk"]) * (1.0 - protect))
	# What the crew's armour and supplies make of it, on average (each worker's own gear counts).
	var n: float = maxf(1.0, float(workers.size()))
	var cost: int = int(round(float(int(site.get("supplies", 0)) + wages) * float(order.get("cost", 1.0))))
	return {
		"site": site_id, "trade": trade, "workers": workers.size(), "guards": guards,
		"needs": str(site.get("needs", "")) if not has_upgrade(str(site.get("needs", ""))) else "",
		"fertilised": _fertilised(trade),
		"best_level": best_level, "meets_level": best_level >= int(site.get("level", 1)),
		"units": units, "share": share, "value": int(round(value)), "cost": cost,
		"profit": int(round(value)) - cost, "injury": injury, "death": death,
		"injury_seen": injury * (guarded / n if not workers.is_empty() else 1.0), "death_seen": death * (armoured / n if not workers.is_empty() else 1.0),
		"duration": int(round(float(site.get("duration", 60)) * float(order["duration"]) * (1.0 - saved) * (1.0 + quicker))),
		"xp": int(round(float(site.get("xp", 20)) * float(order["xp"]))),
	}

func site_dispatch(site_id: String, ids: Array[String], approach: String) -> String:
	var site: Dictionary = TradeSites.by_id(site_id)
	if site.is_empty() or site.has("special"):
		return "That site is not available."
	if not TradeSites.has_orders(approach):
		return "Unrecognized standing orders."
	if ids.is_empty() or ids.size() > 3:
		return "Choose between one and three workers."
	if missions.size() >= expedition_slots:
		return "No expedition slots are free."
	for id in ids:
		var merc: Dictionary = merc_by_id(id)
		if merc.is_empty() or not is_available(merc):
			return "A selected mercenary is unavailable."
		if int(merc.get("health", 100)) < 25:
			return "%s is too injured for work." % str(merc["name"])
	var plan: Dictionary = site_forecast(site_id, ids, approach)
	if str(plan["needs"]) != "":
		return "Build the %s first." % str(Catalog.data()["upgrades"][str(plan["needs"])]["name"])
	if not bool(plan["meets_level"]):
		return "%s needs a crew member with %s level %d." % [str(site["name"]), TradeSkills.NAMES.get(str(site["trade"]), "trade"), int(site["level"])]
	if gold < int(plan["cost"]):
		return "Insufficient gold for wages and supplies."
	gold -= int(plan["cost"])
	var now := GameClock.now()
	var key := "job_%d" % next_mission_id
	next_mission_id += 1
	var fed: Dictionary = {}
	for id in ids:
		var merc: Dictionary = merc_by_id(id)
		merc["mission_id"] = key
		Gear.ensure(merc)
		fed[id] = _trip_buffs(merc)
		# Food is eaten on the way; potions other than healing ones are drunk at the start.
		merc["equipment"]["food"] = {}
		if not Gear.buffs(merc, "potion").has("heal"):
			merc["equipment"]["potion"] = {}
	missions.append({
		"id": key, "site": site_id, "region": "site", "trade": str(site["trade"]),
		"ids": ids.duplicate(), "tactic": approach, "cost": int(plan["cost"]),
		"share": float(plan["share"]), "injury": float(plan["injury"]), "death": float(plan["death"]),
		"xp": int(plan["xp"]), "seed": randi(), "started": now, "finish": now + int(plan["duration"]),
		"buffs": fed, "fertilised": bool(plan["fertilised"])
	})
	if bool(plan["fertilised"]):
		resources["bone_meal"] = int(resources["bone_meal"]) - 1
	_roll_fallen(missions.back(), site_id)
	save_game()
	return "The crew set out for %s." % str(site["name"])

func _site_finish(mission: Dictionary) -> void:
	var site: Dictionary = TradeSites.by_id(str(mission.get("site", "")))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(mission.get("seed", 1))
	var trade: String = str(mission.get("trade", site.get("trade", "logging")))
	var order: Dictionary = TradeSites.order_for(site, str(mission.get("tactic", "Balanced")))
	var site_name: String = str(site.get("name", "the site"))
	var events: Array[String] = []
	var casualties: Array[String] = []
	var wounded: Array[String] = []
	var lost_items: Array[String] = []
	var finds: Array[String] = []
	var dead_ids: Array[String] = []
	var left_behind: Array[String] = []
	var raw: Dictionary = {}
	var survivors: int = 0
	events.append("The crew set out for %s with %s orders." % [site_name, str(mission.get("tactic", "Balanced")).to_lower()])
	var threat: Dictionary = site.get("threat", {})
	var team: Array = []
	for merc_id in mission.get("ids", []):
		if not merc_by_id(str(merc_id)).is_empty():
			team.append(merc_by_id(str(merc_id)))
	var leader: float = (1.1 if Mercs.crew_has(team, "born_leader") else 1.0) * (BONE_MEAL_BONUS if bool(mission.get("fertilised", false)) else 1.0)
	if bool(mission.get("fertilised", false)):
		events.append("Bone meal went on the fields first.")
	for merc_id in mission.get("ids", []):
		var id: String = str(merc_id)
		var worker: Dictionary = merc_by_id(id)
		if worker.is_empty():
			continue
		var guard: bool = _stands_guard(worker, trade)
		var buffs: Dictionary = (mission.get("buffs", {}) as Dictionary).get(id, {})
		var death_chance: float = float(mission.get("death", 0.0)) * (1.1 if guard else 1.0) * Mercs.death_mult(worker) * Gear.death_mult(worker)
		var dies: bool = rng.randf() < death_chance
		if dies and Mercs.has_trait(worker, "lucky") and rng.randf() < 1.0 / 3.0:
			dies = false
			worker["health"] = 20
			wounded.append(str(worker["name"]))
			events.append("%s should have died, and walked away. Lucky." % str(worker["name"]))
		if dies:
			casualties.append(str(worker["name"]))
			dead_ids.append(id)
			left_behind.append_array(_drop_on_death(str(mission.get("site", "")), worker, int(mission["finish"]), rng))
			retired_ids.append(id)
			var equipped: Dictionary = worker.get("equipment", {})
			for item in Gear.worn(worker):
				lost_items.append("%s — %s" % [str(worker["name"]), Gear.full_name(item)])
			var memorial: Array = harlow.get("fallen", [])
			memorial.push_front({"name": str(worker["name"]), "equipment": equipped.duplicate(true),
				"region": site_name, "time": int(mission["finish"])})
			harlow["fallen"] = memorial
			crew.erase(worker)
			continue
		survivors += 1
		worker["mission_id"] = ""
		var injury_chance: float = float(mission.get("injury", 0.0)) * Mercs.injury_chance_mult(worker) * Gear.injury_mult(worker) * (1.0 + float(buffs.get("injury", 0.0)) / 100.0)
		if rng.randf() < injury_chance and not wounded.has(str(worker["name"])):
			var hurt: int = int(round(float(rng.randi_range(8, 25)) * Mercs.injury_damage_mult(worker)))
			worker["health"] = maxi(20, int(worker.get("health", 100)) - hurt)
			wounded.append(str(worker["name"]))
		# A healing draught is drunk as soon as they're hurt.
		var potion: Dictionary = Gear.buffs(worker, "potion")
		if potion.has("heal") and int(worker.get("health", 100)) < 100:
			worker["health"] = mini(100, int(worker["health"]) + int(potion["heal"]))
			worker["equipment"]["potion"] = {}
			events.append("%s drank a healing draught." % str(worker["name"]))
		var level: int = TradeSkills.level_of(worker, trade)
		var effort: float = _haul(worker, trade, buffs) * leader
		var tool: float = _tool_bonus(worker, trade) * float(site.get("tool", 1.0))
		# Long trips average several rolls, so an eight-hour haul isn't one coin flip.
		var rolls: int = clampi(int(float(order.get("duration", 1.0))), 1, 12)
		for good in site.get("yields", {}):
			var span: Array = site["yields"][good]
			var amount: float = _roll_avg(rng, span, rolls) * (1.0 + TradeSites.LEVEL_YIELD_BONUS * float(level - 1)) + float(tool)
			raw[good] = int(raw.get(good, 0)) + int(round(amount * effort * float(order["yield"])))
		for good in site.get("side", {}):
			var span: Array = site["side"][good]
			raw[good] = int(raw.get(good, 0)) + int(round(_roll_avg(rng, span, rolls) * float(order["yield"])))
		var xp: int = int(round(float(mission.get("xp", 20)) * Gear.xp_mult(worker) * (1.0 + float(buffs.get("xp", 0.0)) / 100.0)))
		var gained: int = TradeSkills.grant(worker, trade, xp)
		# Every trip wears what they wear; long orders three times as much.
		var worn_out: Array[String] = Gear.wear(worker, Gear.WEAR_LONG if Gear.LONG_ORDERS.has(str(mission.get("tactic", ""))) else Gear.WEAR_TRIP)
		if not worn_out.is_empty():
			events.append("%s's %s wore out: half as good until repaired." % [str(worker["name"]), ", ".join(worn_out)])
		if gained > 0:
			events.append("%s reached %s %d." % [str(worker["name"]), TradeSkills.NAMES.get(trade, trade), TradeSkills.level_of(worker, trade)])
		if guard and int(threat.get("danger", 0)) > 0:
			if TradeSkills.grant(worker, "combat", int(xp * 0.6)) > 0:
				events.append("%s reached Combat %d." % [str(worker["name"]), TradeSkills.level_of(worker, "combat")])
	if int(threat.get("danger", 0)) > 0 and (not wounded.is_empty() or not casualties.is_empty()):
		events.append("%s found the crew." % str(threat.get("name", "Trouble")))
	if not casualties.is_empty():
		events.append("%s did not come back. Their gear was lost." % ", ".join(casualties))
	if not left_behind.is_empty():
		events.append("Some of their gear stayed where they fell: %s. Another company may find it." % ", ".join(left_behind))
	if not wounded.is_empty():
		events.append("%s returned injured." % ", ".join(wounded))
	# The crew keeps its agreed share of the haul.
	var loot: Dictionary = {}
	var kept_by_crew: Array[String] = []
	for good in raw:
		var total: int = int(raw[good])
		if total <= 0:
			continue
		var crew_cut: int = int(round(float(total) * float(mission.get("share", 0.0))))
		if crew_cut > 0:
			kept_by_crew.append("%d %s" % [crew_cut, str(RESOURCE_NAMES.get(good, good))])
		loot[good] = total - crew_cut
	for rare_key in ["rare", "rare2"]:
		var rare: Dictionary = site.get(rare_key, {})
		if survivors > 0 and not rare.is_empty() and rng.randf() < _rare_chance(rare, order, team, mission.get("buffs", {})):
			var good: String = str(rare["good"])
			loot[good] = int(loot.get(good, 0)) + int(rare.get("count", 1))
			finds.append(str(RESOURCE_NAMES.get(good, good)))
			events.append("A rare find: %s." % str(rare.get("note", good)))
	var found_bp: Array = site_blueprints(str(mission.get("site", "")))
	if survivors > 0 and not found_bp.is_empty():
		var bp_chance: float = minf(0.5, BLUEPRINT_FIND * maxf(1.0, float(order.get("duration", 1.0))) * (1.5 if Mercs.crew_has(team, "keen_eye") else 1.0))
		if rng.randf() < bp_chance:
			var bp: String = str(found_bp[rng.randi_range(0, found_bp.size() - 1)])
			blueprints.append(bp)
			finds.append("Blueprint: " + str(Catalog.item(bp)["name"]))
			events.append("Found a blueprint: %s. The company can make it now." % str(Catalog.item(bp)["name"]))
	var hauled: Array[String] = []
	var value: int = _settle_finds(mission, str(mission.get("site", "")), dead_ids, events, finds)
	for good in loot:
		if int(loot[good]) <= 0:
			continue
		resources[good] = int(resources.get(good, 0)) + int(loot[good])
		hauled.append("%d %s" % [int(loot[good]), str(RESOURCE_NAMES.get(good, good))])
		value += int(loot[good]) * sell_price(str(good), int(loot[good]))
	if survivors == 0:
		events.append("Nothing was brought back.")
	elif not hauled.is_empty():
		events.append("They brought back %s." % ", ".join(hauled))
	if not kept_by_crew.is_empty():
		events.append("The crew kept their share: %s." % ", ".join(kept_by_crew))
	var success: bool = survivors > 0 and casualties.is_empty()
	_earn_reputation(value, survivors == 0)
	_apply_relief_payment()
	reports.push_front({
		"region": site_name, "site": str(mission.get("site", "")), "trade": trade,
		"won": success, "loot": loot, "cash": 0, "commission": 0, "cost": int(mission.get("cost", 0)),
		"value": value, "tactic": str(mission.get("tactic", "Balanced")), "crew": mission.get("ids", []),
		"time": int(mission["finish"]), "casualties": casualties, "injured": wounded,
		"lost_items": lost_items, "found_items": finds, "events": events,
		"partial": not success and not loot.is_empty(), "found_gear": mission.get("found_keys", [])
	})
	if reports.size() > 35:
		reports.resize(35)


# --- Dungeons (rules and fights in dungeons.gd) -----------------------------------------
#
# A run is a mission with region "dungeon". It goes down floor by floor: each floor's fight is
# resolved when the floor's time is up, then the crew waits briefly at the stairs (a check-in)
# for the player to push on or take it out; with no answer it follows its standing orders.
# Stages: "floor" (fighting floor_i until floor_end), "await" (until await_until), "out"
# (walking out until finish). Health, potions and the carried haul live on the mission, so a
# run survives saving and the game being closed.

## Combat XP for each floor cleared; the boss counts three times.
const DUNGEON_FLOOR_XP := 40
## Health needed to go in.
const DUNGEON_MIN_HEALTH := 40
## Chance each piece a mercenary dies in stays in the dungeon for others to find; the rest is ruined.
const DUNGEON_GEAR_STAYS := 0.7

## Why each picked mercenary can or can't go: {id: reason or ""}.
func dungeon_fit(dungeon_id: String, merc: Dictionary) -> String:
	var d: Dictionary = Dungeons.by_id(dungeon_id)
	if not is_available(merc):
		return "Away"
	if int(merc.get("health", 100)) < DUNGEON_MIN_HEALTH:
		return "Too hurt"
	if Gear.kit_rating(merc) < int(d.get("min_kit", 0)):
		return "Gear score %d of %d" % [Gear.kit_rating(merc), int(d.get("min_kit", 0))]
	return ""

## What the planner shows: per-floor odds, death chance, haul, cost and time under the orders.
func dungeon_forecast(dungeon_id: String, ids: Array[String], depth: int, turn_back: String) -> Dictionary:
	var d: Dictionary = Dungeons.by_id(dungeon_id)
	var fighters: Array = []
	var wages: int = 0
	var share: float = 0.0
	var blocked: String = ""
	for id in ids:
		var merc: Dictionary = merc_by_id(id)
		if merc.is_empty():
			continue
		fighters.append(Dungeons.fighter(merc))
		var t: Dictionary = terms(merc)
		wages += int(t["wage"])
		share += float(t["cut"])
		var why: String = dungeon_fit(dungeon_id, merc)
		if why != "" and blocked == "":
			blocked = "%s: %s" % [str(merc["name"]), why.to_lower()]
	if not fighters.is_empty():
		share /= float(fighters.size())
	var floors: int = (d.get("floors", []) as Array).size()
	depth = clampi(depth, 1, floors)
	var f: Dictionary = {"odds": [], "death": 0.0, "haul": 0.0, "floors": 0.0}
	if not fighters.is_empty():
		f = Dungeons.forecast(fighters, d, depth, turn_back, func(g): return sell_price(str(g)), 120)
	var fights: int = fighters.filter(func(c): return not bool(c["porter"])).size()
	if blocked == "" and fights == 0 and not fighters.is_empty():
		blocked = "Someone has to hold a weapon."
	var time: int = depth * Dungeons.FLOOR_TIME + (depth - 1) * Dungeons.CHECKIN + depth * Dungeons.WALK_TIME
	return {"dungeon": dungeon_id, "odds": f["odds"], "death": f["death"], "haul": int(round(float(f["haul"]) * (1.0 - share))),
		"floors": f["floors"], "cost": int(d.get("supplies", 0)) + wages, "duration": time, "share": share,
		"blocked": blocked, "fighters": fighters, "depth": depth}

func dungeon_dispatch(dungeon_id: String, ids: Array[String], depth: int, turn_back: String, risk: String = "safe") -> String:
	var d: Dictionary = Dungeons.by_id(dungeon_id)
	if d.is_empty():
		return "That dungeon isn't open."
	if not Dungeons.TURN_BACK.has(turn_back):
		return "Unrecognized orders."
	if ids.is_empty() or ids.size() > int(d.get("crew", 3)):
		return "Choose between one and %d mercenaries." % int(d.get("crew", 3))
	if missions.size() >= expedition_slots:
		return "No expedition slots are free."
	for id in ids:
		var merc: Dictionary = merc_by_id(id)
		if merc.is_empty():
			return "A selected mercenary is unavailable."
		var why: String = dungeon_fit(dungeon_id, merc)
		if why != "":
			return "%s can't go: %s." % [str(merc["name"]), why.to_lower()]
	var plan: Dictionary = dungeon_forecast(dungeon_id, ids, depth, turn_back)
	if str(plan["blocked"]) != "":
		return str(plan["blocked"])
	if gold < int(plan["cost"]):
		return "Insufficient gold for wages and supplies."
	gold -= int(plan["cost"])
	var now := GameClock.now()
	var key := "job_%d" % next_mission_id
	next_mission_id += 1
	var hp: Dictionary = {}
	var heal: Dictionary = {}
	var lucky: Dictionary = {}
	for f in plan["fighters"]:
		hp[str(f["id"])] = float(f["hp"])
		heal[str(f["id"])] = int(f["heal"])
		lucky[str(f["id"])] = bool(f["lucky"])
	for id in ids:
		merc_by_id(id)["mission_id"] = key
	var mission: Dictionary = {
		"id": key, "region": "dungeon", "dungeon": dungeon_id, "trade": "combat", "ids": ids.duplicate(),
		"depth": int(plan["depth"]), "turn_back": turn_back, "tactic": "Deep Push", "cost": int(plan["cost"]),
		"share": float(plan["share"]), "seed": randi(), "started": now,
		"stage": "floor", "floor_i": 0, "floor_end": now + Dungeons.FLOOR_TIME, "await_until": 0,
		"hp": hp, "heal": heal, "lucky": lucky, "drank": [], "carry": {}, "dropped": {}, "log": [], "dead": [],
		"overrode": -1, "risk": "bold" if risk == "bold" else "safe", "ev": [], "ev_log": [], "event_gear": [],
		"buff": {}, "weaken": 0, "ally": false, "bonus_xp": 0,
	}
	mission["finish"] = _dungeon_projection(mission)
	_schedule_events(mission, "floor", now, now + Dungeons.FLOOR_TIME)
	missions.append(mission)
	_roll_fallen(mission, dungeon_id)
	save_game()
	return "The crew went down into %s." % str(d["name"])

## When the run ends if the crew follows its orders from here (for timers and the board).
func _dungeon_projection(m: Dictionary) -> int:
	var floors: int = (Dungeons.by_id(str(m["dungeon"])).get("floors", []) as Array).size()
	var depth: int = mini(int(m.get("depth", floors)), floors)
	var i: int = int(m.get("floor_i", 0))
	match str(m.get("stage", "floor")):
		"out":
			return int(m["finish"])
		"await":
			var more: int = maxi(0, depth - (i + 1))
			return int(m["await_until"]) + more * (Dungeons.FLOOR_TIME + Dungeons.CHECKIN) + (i + 1 + more) * Dungeons.WALK_TIME
	var left: int = maxi(0, depth - (i + 1))
	return int(m["floor_end"]) + left * (Dungeons.FLOOR_TIME + Dungeons.CHECKIN) + (i + 1 + left) * Dungeons.WALK_TIME

## Runs waiting for the player at the stairs.
func dungeon_checkins() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for m in missions:
		if str(m.get("region", "")) == "dungeon" and str(m.get("stage", "")) == "await":
			out.append(m)
	return out

func mission_by_id(id: String) -> Dictionary:
	for m in missions:
		if str(m.get("id", "")) == id:
			return m
	return {}

## The crew's fighting numbers as they stand in the run (health and potions from the mission).
func _run_crew(m: Dictionary) -> Array:
	var out: Array = []
	for id in m.get("ids", []):
		var merc: Dictionary = merc_by_id(str(id))
		if merc.is_empty() or (m.get("dead", []) as Array).has(str(id)):
			continue
		var f: Dictionary = Dungeons.fighter(merc)
		f["hp"] = float((m["hp"] as Dictionary).get(str(id), f["hp"]))
		f["heal"] = int((m["heal"] as Dictionary).get(str(id), 0))
		f["lucky"] = bool((m["lucky"] as Dictionary).get(str(id), false))
		out.append(f)
	return out

func _store_run_crew(m: Dictionary, crew_now: Array) -> void:
	for f in crew_now:
		m["hp"][str(f["id"])] = maxf(0.0, float(f["hp"]))
		m["heal"][str(f["id"])] = int(f["heal"])
		m["lucky"][str(f["id"])] = bool(f["lucky"])

## Advance every dungeon run to `now`: resolve floors whose time is up, and follow orders at
## check-ins nobody answered. Returns true if anything changed.
func _dungeon_tick(now: int) -> bool:
	return dungeon_tick(now)

func dungeon_tick(now: int = -1) -> bool:
	if now < 0:
		now = GameClock.now()
	var changed: bool = false
	for m in missions:
		if str(m.get("region", "")) != "dungeon":
			continue
		var guard: int = 0
		while guard < 400:
			guard += 1
			var stage: String = str(m.get("stage", "out"))
			# Events nobody answered: the crew decides by its orders once the wait is up.
			var due: Dictionary = _next_due_event(m, now)
			if not due.is_empty() and (stage != "floor" or int(due["t"]) < int(m["floor_end"])):
				_apply_event(m, due, DungeonEvents.auto_choice(due, str(m.get("risk", "safe"))), int(due["t"]) + DungeonEvents.EVENT_WAIT, true)
				changed = true
				continue
			if stage == "floor" and int(m["floor_end"]) <= now:
				_dungeon_floor(m)
				changed = true
			elif stage == "await" and int(m["await_until"]) <= now:
				var crew_now: Array = _run_crew(m)
				var floors: int = (Dungeons.by_id(str(m["dungeon"]))["floors"] as Array).size()
				var go: bool = Dungeons.keep_going(crew_now, int(m["floor_i"]) + 1, int(m["depth"]), str(m["turn_back"]), not (m["dead"] as Array).is_empty(), floors)
				_dungeon_next(m, go, int(m["await_until"]))
				changed = true
			else:
				break
	return changed

## The player's answer at a check-in: push on to the next floor, or take the haul out.
func dungeon_choose(mission_id: String, push: bool) -> String:
	var m: Dictionary = mission_by_id(mission_id)
	if m.is_empty() or str(m.get("stage", "")) != "await":
		return "That crew isn't waiting for orders."
	var now: int = GameClock.now()
	var crew_now: Array = _run_crew(m)
	var floors: int = (Dungeons.by_id(str(m["dungeon"]))["floors"] as Array).size()
	var orders_say: bool = Dungeons.keep_going(crew_now, int(m["floor_i"]) + 1, int(m["depth"]), str(m["turn_back"]), not (m["dead"] as Array).is_empty(), floors)
	if push and int(m["floor_i"]) + 1 >= floors:
		push = false
	if push != orders_say:
		m["overrode"] = int(m["floor_i"]) + 1
	_dungeon_next(m, push, mini(now, int(m["await_until"])))
	save_game()
	return "The crew pushed on." if push else "The crew is heading out."

func _dungeon_next(m: Dictionary, push: bool, t: int) -> void:
	if push:
		m["floor_i"] = int(m["floor_i"]) + 1
		m["stage"] = "floor"
		m["floor_end"] = t + Dungeons.FLOOR_TIME
		# Pushing past the planned depth makes the new floor the plan.
		m["depth"] = maxi(int(m["depth"]), int(m["floor_i"]) + 1)
		_schedule_events(m, "floor", t, int(m["floor_end"]))
	else:
		_start_walk(m, t)
		return
	m["finish"] = _dungeon_projection(m)

## Head for the exit from `t`, through every floor reached, with things happening on the way.
func _start_walk(m: Dictionary, t: int) -> void:
	m["stage"] = "out"
	m["finish"] = t + (int(m["floor_i"]) + 1) * Dungeons.WALK_TIME
	_schedule_events(m, "walk", t, int(m["finish"]))

## The events for a floor or the walk out, from the run's seed.
func _schedule_events(m: Dictionary, phase: String, start: int, end: int) -> void:
	var crew_now: Array = []
	for id in m.get("ids", []):
		if not (m.get("dead", []) as Array).has(str(id)) and not merc_by_id(str(id)).is_empty():
			crew_now.append(merc_by_id(str(id)))
	var seed_value: int = int(m["seed"]) + 104729 * (int(m.get("floor_i", 0)) + 1) + (7 if phase == "walk" else 0)
	m["ev"] = DungeonEvents.schedule(str(m["dungeon"]), phase, int(m.get("floor_i", 0)), start, end, seed_value, crew_now)
	m["ev_phase"] = phase

## The earliest unanswered event whose wait is over at `now`.
func _next_due_event(m: Dictionary, now: int) -> Dictionary:
	for ev in m.get("ev", []):
		if not bool(ev["done"]) and int(ev["t"]) + DungeonEvents.EVENT_WAIT <= now:
			return ev
	return {}

## Events waiting for the player right now: [{"mission", "index", "event"}].
func dungeon_pending(now: int = -1) -> Array:
	if now < 0:
		now = GameClock.now()
	var out: Array = []
	for m in missions:
		if str(m.get("region", "")) != "dungeon":
			continue
		var evs: Array = m.get("ev", [])
		for i in range(evs.size()):
			var ev: Dictionary = evs[i]
			if not bool(ev["done"]) and int(ev["t"]) <= now and now < int(ev["t"]) + DungeonEvents.EVENT_WAIT:
				out.append({"mission": m, "index": i, "event": ev})
	return out

## The player's choice on an event card.
func dungeon_answer(mission_id: String, index: int, choice: int) -> String:
	var m: Dictionary = mission_by_id(mission_id)
	if m.is_empty():
		return "That crew is gone."
	var evs: Array = m.get("ev", [])
	if index < 0 or index >= evs.size() or bool(evs[index]["done"]):
		return "Too late: the crew already decided."
	var now: int = GameClock.now()
	_apply_event(m, evs[index], choice, maxi(now, int(evs[index]["t"])), false)
	save_game()
	return str(evs[index].get("result", ""))

## What a choice on an event does to the run.
func _apply_event(m: Dictionary, ev: Dictionary, choice: int, t: int, auto: bool) -> void:
	var o: Dictionary = DungeonEvents.outcome(ev, choice)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(ev.get("roll", 1)) ^ 0x51ED27
	var alive: Array = []
	for id in m.get("ids", []):
		if not (m["dead"] as Array).has(str(id)) and not merc_by_id(str(id)).is_empty():
			alive.append(str(id))
	ev["done"] = true
	ev["choice"] = choice
	ev["auto"] = auto
	if alive.is_empty():
		return
	var who_id: String = str(alive[rng.randi_range(0, alive.size() - 1)])
	var who: String = str(merc_by_id(who_id).get("name", "Someone"))
	var carry: Dictionary = m["carry"]
	var notes: Array[String] = []
	if o.has("coin"):
		var n: int = int(round(float(rng.randi_range(int(o["coin"][0]), int(o["coin"][1]))) * DungeonEvents.COIN_SCALE))
		carry["coin"] = maxi(0, int(carry.get("coin", 0)) + n)
	for good in o.get("goods", {}):
		var n: int = rng.randi_range(int(o["goods"][good][0]), int(o["goods"][good][1]))
		if n > 0:
			carry[good] = int(carry.get(good, 0)) + n
	if o.has("gear"):
		var table: Dictionary = {}
		var all: Dictionary = FallenGear.NPC_LOOT.get(str(m["dungeon"]), {})
		for k in all:
			var gd: Dictionary = Catalog.item(str(k))
			if int(gd.get("tier", 1)) <= int(o["gear"]) and not bool(gd.get("found_only", false)):
				table[k] = all[k]
		var total: float = 0.0
		for k in table:
			total += float(table[k])
		var pick: float = rng.randf() * total
		for k in table:
			pick -= float(table[k])
			if pick <= 0.0:
				(m["event_gear"] as Array).append(str(k))
				notes.append("Found: %s." % str(Catalog.item(str(k)).get("name", k)))
				break
	if o.has("heal"):
		for id in alive:
			m["hp"][id] = minf(100.0, float(m["hp"].get(id, 100.0)) + float(o["heal"]))
	if o.has("buff"):
		var buff: Dictionary = m["buff"]
		for k in o["buff"]:
			buff[k] = float(buff.get(k, 0.0)) + float(o["buff"][k])
	if o.has("weaken"):
		m["weaken"] = mini(60, int(m.get("weaken", 0)) + int(o["weaken"]))
	if bool(o.get("ally", false)):
		m["ally"] = true
	if o.has("xp"):
		m["bonus_xp"] = int(m.get("bonus_xp", 0)) + int(o["xp"])
	if o.has("lose"):
		var dropped: Dictionary = m["dropped"]
		for good in carry.keys():
			var lost: int = int(round(float(carry[good]) * float(o["lose"])))
			if lost > 0:
				carry[good] = int(carry[good]) - lost
				dropped[good] = int(dropped.get(good, 0)) + lost
	var hurt: Array = []
	if o.has("hurt"):
		hurt.append([who_id, rng.randi_range(int(o["hurt"][0]), int(o["hurt"][1]))])
	if o.has("hurt_all"):
		for id in alive:
			hurt.append([id, rng.randi_range(int(o["hurt_all"][0]), int(o["hurt_all"][1]))])
	var died: Array[String] = []
	for h in hurt:
		var id: String = str(h[0])
		var merc: Dictionary = merc_by_id(id)
		var dmg: float = float(h[1]) * DungeonEvents.HURT_SCALE * Mercs.injury_damage_mult(merc)
		var hp: float = float(m["hp"].get(id, 100.0)) - dmg
		if hp > 0.0 and hp < 35.0 and int(m["heal"].get(id, 0)) > 0:
			hp += float(m["heal"][id])
			m["heal"][id] = 0
			(m["drank"] as Array).append(id)
		if hp <= 0.0 and bool(m["lucky"].get(id, false)):
			hp = 5.0
			m["lucky"][id] = false
			notes.append("%s should have died. Lucky." % str(merc.get("name", "")))
		m["hp"][id] = maxf(0.0, hp)
		if hp <= 0.0:
			(m["dead"] as Array).append(id)
			died.append(str(merc.get("name", "")))
	var text: String = str(o.get("text", "")).replace("{who}", who)
	if not died.is_empty():
		notes.append("%s died." % ", ".join(died))
		if (m["dead"] as Array).size() >= (m["ids"] as Array).size():
			var dropped: Dictionary = m["dropped"]
			for good in carry:
				dropped[good] = int(dropped.get(good, 0)) + int(carry[good])
			carry.clear()
			(m["event_gear"] as Array).clear()
			notes.append("Nobody is left to carry anything out.")
			for other in m.get("ev", []):
				other["done"] = true
			m["stage"] = "out"
			m["finish"] = t
		else:
			var lost: Dictionary = Dungeons.drop_half(carry)
			var dropped2: Dictionary = m["dropped"]
			for good in lost:
				dropped2[good] = int(dropped2.get(good, 0)) + int(lost[good])
			notes.append("The crew dropped half of what it carried.")
	if not notes.is_empty():
		text += " " + " ".join(notes)
	ev["result"] = text
	var e: Dictionary = DungeonEvents.by_id(str(ev["id"]))
	var label: String = str((e["choices"] as Array)[clampi(choice, 0, (e["choices"] as Array).size() - 1)]["label"])
	(m["ev_log"] as Array).append({"t": t, "floor": int(m.get("floor_i", 0)), "phase": str(m.get("ev_phase", "floor")), "id": str(ev["id"]),
		"choice": label, "auto": auto, "text": text})

## Resolve the fight on the current floor at floor_end.
func _dungeon_floor(m: Dictionary) -> void:
	var d: Dictionary = Dungeons.by_id(str(m["dungeon"]))
	var floors: Array = d["floors"]
	var i: int = int(m["floor_i"])
	var floor: Dictionary = floors[i]
	var t: int = int(m["floor_end"])
	var rng := RandomNumberGenerator.new()
	rng.seed = int(m["seed"]) + 7919 * (i + 1)
	var crew_now: Array = _run_crew(m)
	# What happened on the floor shapes the fight: blessings and curses, sleeping or singed
	# monsters, a stranger fighting beside the crew.
	var buff: Dictionary = m.get("buff", {})
	for c in crew_now:
		c["damage"] = float(c["damage"]) * (1.0 + float(buff.get("damage", 0.0)) / 100.0)
		c["armour"] = float(c["armour"]) + float(buff.get("armour", 0.0))
	var foes: Dictionary = floor.duplicate()
	foes["hp"] = float(floor["hp"]) * (1.0 - float(m.get("weaken", 0)) / 100.0)
	var ally: Dictionary = {}
	if bool(m.get("ally", false)):
		ally = {"id": "ally", "name": "The stranger", "porter": false, "hp": 70.0, "max_hp": 70.0, "damage": 10.0 + 4.0 * float(d.get("tier", 1)),
			"speed": 1.0, "crit": 0.05, "crit_damage": 1.5, "pen": 0.0, "first": 0.0, "armour": 10.0 * float(d.get("tier", 1)), "dodge": 0.0,
			"parry": 0.0, "block": 0.0, "lucky": false, "heal": 0}
		crew_now.append(ally)
	m["buff"] = {}
	m["weaken"] = 0
	m["ally"] = false
	var r: Dictionary = Dungeons.fight(crew_now, foes, rng, float(Dungeons.RETREAT_AT.get(str(m["turn_back"]), 0.0)))
	if not ally.is_empty():
		crew_now.erase(ally)
		(r["dead"] as Array).erase("ally")
		if float(ally["hp"]) > 0.0:
			(r["lines"] as Array).append("The stranger fought with you and walked away.")
	_store_run_crew(m, crew_now)
	for id in r["potions"]:
		(m["drank"] as Array).append(str(id))
	var dead: Array = m["dead"]
	for id in r["dead"]:
		if not dead.has(str(id)):
			dead.append(str(id))
	var entry: Dictionary = {"floor": i, "name": str(floor["name"]), "result": str(r["result"]), "lines": r["lines"], "dead": r["dead"], "time": t}
	var carry: Dictionary = m["carry"]
	var dropped: Dictionary = m["dropped"]
	if str(r["result"]) == "wiped":
		for good in carry:
			dropped[good] = int(dropped.get(good, 0)) + int(carry[good])
		carry.clear()
		entry["lines"].append("Everything they carried stays in the keep.")
	elif not (r["dead"] as Array).is_empty():
		var lost: Dictionary = Dungeons.drop_half(carry)
		for good in lost:
			dropped[good] = int(dropped.get(good, 0)) + int(lost[good])
		if not lost.is_empty():
			entry["lines"].append("The crew dropped half of what it carried to get out.")
	(m["log"] as Array).append(entry)
	if str(r["result"]) == "wiped":
		m["stage"] = "out"
		m["finish"] = t
		m["ev"] = []
		(m["event_gear"] as Array).clear()
		return
	if str(r["result"]) != "cleared":
		_start_walk(m, t)
		return
	var alive: Array = crew_now.filter(func(c): return float(c["hp"]) > 0.0)
	Dungeons.patch_up(alive)
	_store_run_crew(m, alive)
	var before: Dictionary = carry.duplicate()
	Dungeons.add_loot(carry, floor, alive, rng)
	if bool(floor.get("boss", false)):
		var bps: Array = site_blueprints(str(m["dungeon"]))
		if not bps.is_empty() and rng.randf() < float(floor.get("blueprint", 0.0)):
			m["blueprint"] = str(bps[rng.randi_range(0, bps.size() - 1)])
	var gained: Array[String] = []
	for good in carry:
		var n: int = int(carry[good]) - int(before.get(good, 0))
		if n > 0:
			gained.append("%d %s" % [n, "coin" if good == "coin" else str(RESOURCE_NAMES.get(good, good)).to_lower()])
	if not gained.is_empty():
		entry["lines"].append("Picked up %s." % ", ".join(gained))
	if i + 1 >= floors.size():
		_start_walk(m, t)
		return
	m["ev"] = []
	m["stage"] = "await"
	m["await_until"] = t + Dungeons.CHECKIN
	m["finish"] = _dungeon_projection(m)

## Worth of what the crew carries now, at merchant prices.
func dungeon_carry_value(carry: Dictionary) -> int:
	var v: int = int(carry.get("coin", 0))
	for good in carry:
		if good != "coin":
			v += int(carry[good]) * sell_price(str(good), int(carry[good]))
	return v

## The crew is out (or dead): settle the haul, the dead and the report.
func _dungeon_finish(m: Dictionary) -> void:
	var d: Dictionary = Dungeons.by_id(str(m["dungeon"]))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(m["seed"]) ^ 0x2545F491
	var t: int = int(m["finish"])
	var dead_ids: Array = m.get("dead", [])
	var events: Array[String] = []
	var casualties: Array[String] = []
	var lost_items: Array[String] = []
	var fallen_notes: Array = []
	var survivors: Array[Dictionary] = []
	var cleared: int = (m.get("log", []) as Array).filter(func(e): return str(e["result"]) == "cleared").size()
	var boss_down: bool = false
	for e in m.get("log", []):
		if str(e["result"]) == "cleared" and bool((d["floors"][int(e["floor"])] as Dictionary).get("boss", false)):
			boss_down = true
	for id in m.get("ids", []):
		var merc: Dictionary = merc_by_id(str(id))
		if merc.is_empty():
			continue
		if dead_ids.has(str(id)):
			casualties.append(str(merc["name"]))
			var stayed: Array[String] = []
			var ruined: Array[String] = []
			for item in Gear.worn(merc):
				lost_items.append("%s — %s" % [str(merc["name"]), Gear.full_name(item)])
				if rng.randf() < DUNGEON_GEAR_STAYS:
					fallen.drop(str(m["dungeon"]), str(item.get("key", "")), str(merc["name"]), t)
					stayed.append(Gear.full_name(item))
				else:
					ruined.append(Gear.full_name(item))
			var note: String = ""
			if not stayed.is_empty():
				note = "%s stayed in %s for others to find" % [", ".join(stayed), str(d["name"])]
			if not ruined.is_empty():
				note += ("; " if note != "" else "") + "%s %s ruined" % [", ".join(ruined), "was" if ruined.size() == 1 else "were"]
			fallen_notes.append({"name": str(merc["name"]), "level": TradeSkills.level_of(merc, "combat"), "note": note})
			retired_ids.append(str(id))
			var memorial: Array = harlow.get("fallen", [])
			memorial.push_front({"name": str(merc["name"]), "equipment": (merc.get("equipment", {}) as Dictionary).duplicate(true),
				"region": str(d["name"]), "time": t})
			harlow["fallen"] = memorial
			crew.erase(merc)
			continue
		survivors.append(merc)
		merc["mission_id"] = ""
		merc["health"] = clampi(int(round(float((m["hp"] as Dictionary).get(str(id), 100.0)))), 1, 100)
		if (m.get("drank", []) as Array).has(str(id)):
			merc["equipment"]["potion"] = {}
		var xp: int = 0
		for e in m.get("log", []):
			if str(e["result"]) == "cleared":
				xp += DUNGEON_FLOOR_XP * (3 if bool((d["floors"][int(e["floor"])] as Dictionary).get("boss", false)) else 1)
			else:
				xp += DUNGEON_FLOOR_XP / 2
		xp += int(m.get("bonus_xp", 0))
		xp = int(round(float(xp) * Gear.xp_mult(merc)))
		if TradeSkills.grant(merc, "combat", xp) > 0:
			events.append("%s reached Combat %d." % [str(merc["name"]), TradeSkills.level_of(merc, "combat")])
		var worn_out: Array[String] = Gear.wear(merc, 4)
		if not worn_out.is_empty():
			events.append("%s's %s wore out: half as good until repaired." % [str(merc["name"]), ", ".join(worn_out)])
	# What came out, less the survivors' share.
	var carry: Dictionary = m.get("carry", {})
	var loot: Dictionary = {}
	var coin: int = 0
	var share: float = 0.0
	for merc in survivors:
		share += float(terms(merc)["cut"])
	if not survivors.is_empty():
		share /= float(survivors.size())
	for good in carry:
		var n: int = int(carry[good])
		var kept: int = n - int(round(float(n) * share))
		if kept <= 0:
			continue
		if good == "coin":
			coin = kept
		else:
			loot[good] = kept
	var finds: Array[String] = []
	var value: int = 0
	if not survivors.is_empty():
		value = _settle_finds(m, str(m["dungeon"]), dead_ids, events, finds)
	else:
		_settle_finds(m, str(m["dungeon"]), m.get("ids", []), events, finds)
	# Gear picked up along the way comes out with the survivors.
	if not survivors.is_empty():
		for key in m.get("event_gear", []):
			if Gear.exists(str(key)):
				var piece: Dictionary = make_item(str(key))
				equipment_inventory.append(piece)
				finds.append(Gear.full_name(piece))
				value += resale_value(piece)
	if survivors.size() > 0 and str(m.get("blueprint", "")) != "" and not blueprints.has(str(m["blueprint"])):
		var bp: String = str(m["blueprint"])
		blueprints.append(bp)
		finds.append("Blueprint: " + str(Catalog.item(bp)["name"]))
		events.append("Found a blueprint on the top floor: %s. The company can make it now." % str(Catalog.item(bp)["name"]))
	gold += coin
	value += coin
	for good in loot:
		resources[good] = int(resources.get(good, 0)) + int(loot[good])
		value += int(loot[good]) * sell_price(str(good), int(loot[good]))
	_earn_reputation(value, survivors.is_empty())
	_apply_relief_payment()
	# The floor-by-floor account leads the field notes.
	var notes: Array[String] = []
	for e in m.get("log", []):
		notes.append("Floor %d, %s. %s" % [int(e["floor"]) + 1, str(e["name"]), " ".join(e.get("lines", []))])
	var answered: int = 0
	for e in m.get("ev_log", []):
		if not bool(e["auto"]):
			answered += 1
		notes.append("%s: %s. %s" % ["Floor %d" % (int(e["floor"]) + 1) if str(e["phase"]) == "floor" else "On the way out", str(e["choice"]), str(e["text"])])
	if not (m.get("ev_log", []) as Array).is_empty():
		notes.append("You made %d of the crew's %d calls; it made the rest %s." % [answered, (m["ev_log"] as Array).size(), "carefully" if str(m.get("risk", "safe")) == "safe" else "boldly"])
	if int(m.get("overrode", -1)) >= 0:
		notes.append("You overrode the standing orders at floor %d." % int(m["overrode"]))
	var dropped: Dictionary = m.get("dropped", {})
	if not dropped.is_empty():
		var left: Array[String] = []
		for good in dropped:
			left.append("%d %s" % [int(dropped[good]), "coin" if good == "coin" else str(RESOURCE_NAMES.get(good, good)).to_lower()])
		notes.append("Left in %s: %s." % [str(d["name"]), ", ".join(left)])
	for f in fallen_notes:
		if str(f["note"]) != "":
			notes.append("%s fell. %s." % [str(f["name"]), str(f["note"])])
	notes.append_array(events)
	events = notes
	var outcome: String = "wiped" if survivors.is_empty() else ("loss" if not casualties.is_empty() else ("cleared" if boss_down else "out"))
	reports.push_front({
		"region": str(d["name"]), "dungeon": str(m["dungeon"]), "trade": "combat", "won": outcome == "cleared" or (outcome == "out" and cleared > 0),
		"outcome": outcome, "floors_cleared": cleared, "floor_log": m.get("log", []), "loot": loot, "cash": coin,
		"commission": 0, "cost": int(m.get("cost", 0)), "value": value, "tactic": "Dungeon run", "crew": m.get("ids", []),
		"depth": int(m.get("depth", 1)), "turn_back": str(m.get("turn_back", "half")), "overrode": int(m.get("overrode", -1)),
		"time": t, "started": int(m.get("started", t)), "casualties": casualties, "injured": [], "lost_items": lost_items,
		"found_items": finds, "events": events, "dropped": m.get("dropped", {}), "fallen_notes": fallen_notes,
		"partial": false, "found_gear": m.get("found_keys", []),
	})
	if reports.size() > 35:
		reports.resize(35)


# --- Auction House (rules and NPC listings in auction_house.gd) ---------------------------

func ah_fair(ref: String, now: int = -1) -> float:
	return hall.fair(ref, GameClock.now() if now < 0 else now)

func ah_listings_for(ref: String) -> Array:
	var now: int = GameClock.now()
	return auction.npc_listings(ref, ah_fair(ref, now), now)

func ah_orders_for(ref: String) -> Array:
	var now: int = GameClock.now()
	return auction.npc_orders(ref, ah_fair(ref, now), now)

## How many of a ref the company could put up: goods in the warehouse, or spare pieces.
func ah_held(ref: String) -> int:
	if ref.begins_with("gear:"):
		return equipment_inventory.filter(func(i): return "gear:" + str(i.get("key", "")) == ref).size()
	return int(resources.get(ref, 0))

## What the Sell page shows before posting: sale time, the chance it all goes, fee and take.
func ah_forecast(ref: String, qty: int, price: int, duration: String) -> Dictionary:
	var now: int = GameClock.now()
	var fair: float = ah_fair(ref, now)
	var low: int = AuctionHouse.cheapest(auction.npc_listings(ref, fair, now))
	var rate: float = AuctionHouse.sell_rate(ref, float(price), fair, float(low))
	var est: Dictionary = AuctionHouse.estimate(qty, rate, int(AuctionHouse.DURATIONS.get(duration, 86400)))
	var fee: int = maxi(1, int(round(float(qty * price) * AuctionHouse.LISTING_FEE)))
	var take: int = int(round(float(qty * price) * (1.0 - AuctionHouse.CUT))) - fee
	var at_low: Dictionary = AuctionHouse.estimate(qty, AuctionHouse.sell_rate(ref, float(maxi(1, low)), fair, float(low)), 86400) if low > 0 else {}
	return {"fair": fair, "cheapest": low, "hours": est["hours"], "share": est["share"], "fee": fee, "take": take,
		"merchant": sell_price(ref) if not ref.begins_with("gear:") else int(floor(Catalog.value_of(ref.substr(5)) * 0.65)),
		"hours_at_cheapest": float(at_low.get("hours", 0.0))}

func ah_post(ref: String, qty: int, price: int, duration: String, uid: String = "") -> String:
	var a: AuctionHouse = auction
	if a.listings.size() >= AuctionHouse.MAX_LISTINGS:
		return "You have %d listings up already. Cancel one or wait for one to end." % AuctionHouse.MAX_LISTINGS
	if not AuctionHouse.DURATIONS.has(duration):
		return "Choose how long it stays up."
	if price < 1 or qty < 1:
		return "Set a price and how many."
	var gear: bool = ref.begins_with("gear:")
	var item: Dictionary = {}
	if gear:
		qty = 1
		for i in equipment_inventory:
			if "gear:" + str(i.get("key", "")) == ref and (uid == "" or str(i.get("uid", "")) == uid):
				item = i
				break
		if item.is_empty():
			return "That piece isn't in the storeroom."
	elif int(resources.get(ref, 0)) < qty:
		return "You only hold %d." % int(resources.get(ref, 0))
	var fee: int = maxi(1, int(round(float(qty * price) * AuctionHouse.LISTING_FEE)))
	if gold < fee:
		return "The listing fee is %d G." % fee
	gold -= fee
	if gear:
		equipment_inventory.erase(item)
	else:
		resources[ref] = int(resources[ref]) - qty
	var now: int = GameClock.now()
	var listing: Dictionary = {"id": a.next_id, "ref": ref, "qty": qty, "left": qty, "price": price, "started": now,
		"ends": now + int(AuctionHouse.DURATIONS[duration]), "last": now, "earned": 0, "seed": randi(), "fee": fee}
	if gear:
		listing["item"] = item
	a.next_id += 1
	a.listings.append(listing)
	save_game()
	return "Listed %d %s at %d G each for %s." % [qty, item_ref_name(ref), price, AuctionHouse.DURATION_NAMES[duration]]

func _ah_return(l: Dictionary) -> void:
	var left: int = int(l["left"])
	if left <= 0:
		return
	if l.has("item"):
		equipment_inventory.append(l["item"])
	else:
		resources[str(l["ref"])] = int(resources.get(str(l["ref"]), 0)) + left

func ah_cancel_listing(id: int) -> String:
	var l: Dictionary = auction.listing_by_id(id)
	if l.is_empty():
		return "That listing has ended."
	_ah_return(l)
	auction.listings.erase(l)
	save_game()
	return "Took down %s. %d came back." % [item_ref_name(str(l["ref"])), int(l["left"])]

## A new price for what's left; the listing fee is paid again on the new total.
func ah_reprice(id: int, price: int) -> String:
	var l: Dictionary = auction.listing_by_id(id)
	if l.is_empty():
		return "That listing has ended."
	var fee: int = maxi(1, int(round(float(int(l["left"]) * price) * AuctionHouse.LISTING_FEE)))
	if gold < fee:
		return "Repricing costs a %d G fee." % fee
	gold -= fee
	l["price"] = price
	l["fee"] = int(l.get("fee", 0)) + fee
	save_game()
	return "Repriced to %d G (fee %d G)." % [price, fee]

func ah_order(ref: String, qty: int, price: int, duration: String) -> String:
	if auction.orders.size() >= AuctionHouse.MAX_ORDERS:
		return "You have %d buy orders up already." % AuctionHouse.MAX_ORDERS
	if price < 1 or qty < 1 or not AuctionHouse.DURATIONS.has(duration):
		return "Set a price, how many and how long."
	if ref.begins_with("gear:") and qty > 5:
		return "Gear orders are for up to 5 pieces."
	var held: int = qty * price
	if gold < held:
		return "The order holds %d G until it fills." % held
	gold -= held
	var now: int = GameClock.now()
	auction.orders.append({"id": auction.next_id, "ref": ref, "qty": qty, "got": 0, "price": price, "started": now,
		"ends": now + int(AuctionHouse.DURATIONS[duration]), "last": now, "seed": randi()})
	auction.next_id += 1
	save_game()
	return "Buy order up: %d %s at %d G each. %d G held." % [qty, item_ref_name(ref), price, held]

func ah_cancel_order(id: int) -> String:
	var o: Dictionary = auction.order_by_id(id)
	if o.is_empty():
		return "That order has ended."
	var back: int = (int(o["qty"]) - int(o["got"])) * int(o["price"])
	gold += back
	auction.orders.erase(o)
	save_game()
	return "Cancelled the order. %d G came back." % back

## The ref an NPC listing or order belongs to, from its uid.
static func _ah_ref(uid: String) -> String:
	return uid.substr(uid.find(":") + 1).get_slice("|", 0)

## Buy from an NPC listing: goods to the warehouse, gear to the storeroom.
func ah_buy(uid: String, qty: int = 1) -> String:
	var ref: String = _ah_ref(uid)
	var entry: Dictionary = {}
	for l in ah_listings_for(ref):
		if str(l["uid"]) == uid:
			entry = l
	if entry.is_empty():
		return "Someone else bought it first."
	qty = clampi(qty, 1, int(entry["left"]))
	var cost: int = qty * int(entry["price"])
	if gold < cost:
		qty = gold / int(entry["price"])
		if qty < 1:
			return "Not enough gold: %d G each." % int(entry["price"])
		cost = qty * int(entry["price"])
	gold -= cost
	auction.taken[uid] = int(auction.taken.get(uid, 0)) + qty
	var name: String = item_ref_name(ref)
	if entry.has("item"):
		var item: Dictionary = (entry["item"] as Dictionary).duplicate(true)
		item["uid"] = "gear_%d" % next_item_id
		next_item_id += 1
		equipment_inventory.append(item)
		name = Gear.full_name(item)
	else:
		resources[ref] = int(resources.get(ref, 0)) + qty
	auction.add_log(GameClock.now(), "bought", ref, qty, -cost, str(entry["seller"]))
	save_game()
	return "Bought %s%s from %s for %d G." % ["%d " % qty if not entry.has("item") else "", name, str(entry["seller"]), cost]

## Sell straight into an NPC buy order.
func ah_fill(uid: String, qty: int = -1) -> String:
	var ref: String = _ah_ref(uid)
	var entry: Dictionary = {}
	for o in ah_orders_for(ref):
		if str(o["uid"]) == uid:
			entry = o
	if entry.is_empty():
		return "That order is gone."
	var held: int = ah_held(ref)
	qty = mini(held if qty < 0 else qty, int(entry["left"]))
	if qty < 1:
		return "You don't have any to sell."
	if ref.begins_with("gear:"):
		for n in range(qty):
			for i in equipment_inventory:
				if "gear:" + str(i.get("key", "")) == ref:
					equipment_inventory.erase(i)
					break
	else:
		resources[ref] = int(resources[ref]) - qty
		market.record_npc_trade(ref, qty, GameClock.now())
	var paid: int = int(round(float(qty * int(entry["price"])) * (1.0 - AuctionHouse.CUT)))
	gold += paid
	auction.taken[uid] = int(auction.taken.get(uid, 0)) + qty
	auction.add_log(GameClock.now(), "sold", ref, qty, paid, str(entry["buyer"]))
	save_game()
	return "Sold %d %s to %s for %d G." % [qty, item_ref_name(ref), str(entry["buyer"]), paid]

## Work the company's listings and orders forward to `now`. Returns true if anything changed.
func _ah_tick(now: int) -> bool:
	var a: AuctionHouse = auction
	var changed: bool = false
	var lows: Dictionary = {}
	for l in a.listings.duplicate():
		var ref: String = str(l["ref"])
		var end: int = mini(now, int(l["ends"]))
		var sold: int = 0
		var paid: int = 0
		var t: int = int(l["last"])
		while t + AuctionHouse.STEP <= end and int(l["left"]) > 0:
			t += AuctionHouse.STEP
			var key: String = "%s|%d" % [ref, int(t / AuctionHouse.EPOCH)]
			var fair: float = ah_fair(ref, t)
			if not lows.has(key):
				lows[key] = AuctionHouse.cheapest(a.npc_listings(ref, fair, t))
			var rate: float = AuctionHouse.sell_rate(ref, float(l["price"]), fair, float(lows[key]))
			var rng := RandomNumberGenerator.new()
			rng.seed = int(l["seed"]) + t
			var expected: float = rate * float(AuctionHouse.STEP) / 3600.0
			var n: int = int(expected) + (1 if rng.randf() < expected - floorf(expected) else 0)
			n = mini(n, int(l["left"]))
			if n > 0:
				l["left"] = int(l["left"]) - n
				# Goods sold at auction weigh on the market like goods sold to merchants.
				if not ref.begins_with("gear:"):
					market.record_npc_trade(ref, n, t)
				var p: int = int(round(float(n * int(l["price"])) * (1.0 - AuctionHouse.CUT)))
				sold += n
				paid += p
		l["last"] = maxi(int(l["last"]), t)
		if sold > 0:
			gold += paid
			l["earned"] = int(l.get("earned", 0)) + paid
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = int(l["seed"]) ^ t
			a.add_log(t, "sold", ref, sold, paid, AuctionHouse._who(rng2))
			changed = true
		if int(l["left"]) <= 0:
			a.listings.erase(l)
			changed = true
		elif now >= int(l["ends"]):
			_ah_return(l)
			a.add_log(int(l["ends"]), "expired", ref, int(l["left"]), 0, "")
			a.listings.erase(l)
			changed = true
	for o in a.orders.duplicate():
		var ref: String = str(o["ref"])
		var end: int = mini(now, int(o["ends"]))
		var got: int = 0
		var t: int = int(o["last"])
		while t + AuctionHouse.STEP <= end and int(o["got"]) < int(o["qty"]):
			t += AuctionHouse.STEP
			var rate: float = AuctionHouse.fill_rate(ref, float(o["price"]), ah_fair(ref, t))
			var rng := RandomNumberGenerator.new()
			rng.seed = int(o["seed"]) + t
			var expected: float = rate * float(AuctionHouse.STEP) / 3600.0
			var n: int = mini(int(expected) + (1 if rng.randf() < expected - floorf(expected) else 0), int(o["qty"]) - int(o["got"]))
			if n > 0:
				o["got"] = int(o["got"]) + n
				got += n
		o["last"] = maxi(int(o["last"]), t)
		if got > 0:
			if ref.begins_with("gear:"):
				for n in range(got):
					equipment_inventory.append(make_item(ref.substr(5)))
			else:
				resources[ref] = int(resources.get(ref, 0)) + got
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = int(o["seed"]) ^ t
			a.add_log(t, "bought", ref, got, -got * int(o["price"]), AuctionHouse._who(rng2))
			changed = true
		if int(o["got"]) >= int(o["qty"]):
			a.orders.erase(o)
			changed = true
		elif now >= int(o["ends"]):
			var back: int = (int(o["qty"]) - int(o["got"])) * int(o["price"])
			gold += back
			a.add_log(int(o["ends"]), "order_ended", ref, int(o["qty"]) - int(o["got"]), back, "")
			a.orders.erase(o)
			changed = true
	return changed
