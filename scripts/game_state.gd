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
	return 1.0 if Mercs.job(merc) == trade else 0.5

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
	var leader: float = 1.1 if Mercs.crew_has(workers, "born_leader") else 1.0
	var saved: float = 0.0
	var quicker: float = 0.0
	var guarded: float = 0.0
	var armoured: float = 0.0
	for merc in workers:
		var level: int = TradeSkills.level_of(merc, trade)
		best_level = maxi(best_level, level)
		best_combat = maxi(best_combat, Mercs.guard_level(merc))
		var guard: bool = Mercs.job(merc) == "combat"
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
		"buffs": fed
	})
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
	var leader: float = 1.1 if Mercs.crew_has(team, "born_leader") else 1.0
	for merc_id in mission.get("ids", []):
		var id: String = str(merc_id)
		var worker: Dictionary = merc_by_id(id)
		if worker.is_empty():
			continue
		var guard: bool = Mercs.job(worker) == "combat"
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
