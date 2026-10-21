extends "res://scripts/company_state_base.gd"
class_name MoneyMercsState
## Harlow mine mechanics and expedition settlement.
## All existing MoneyMercsState methods, state fields and save keys are retained.

# Harlow Mines: separate persistent rotation state, scouting, and role-based work.
# This is the first vertical slice. Existing jobs remain backward compatible.
const HARLOW_ROTATION_SECONDS := 14400
const HARLOW_ENEMIES := [
	{"name": "Sleeping Dire Wolf", "danger": 3, "note": "Territorial predator near the lower shafts"},
	{"name": "Goblin Prospectors", "danger": 2, "note": "A band of armed scavengers"},
	{"name": "Cave Spiders", "danger": 1, "note": "Nest signs around the old supports"},
	{"name": "Ancient Cave Troll", "danger": 4, "note": "Huge tracks vanish into the rock"}
]

func harlow_sync(now: int = -1) -> bool:
	if now < 0:
		now = int(Time.get_unix_time_from_system())
	var rotation: int = int(now / HARLOW_ROTATION_SECONDS)
	var changed := false
	if int(harlow.get("rotation", -1)) != rotation:
		var archives: Dictionary = harlow.get("archives", {})
		var ongoing_scout: int = int(harlow.get("scout_finish", 0))
		if harlow.has("rotation"):
			archives[str(int(harlow["rotation"]))] = (harlow.get("deposits", {}) as Dictionary).duplicate(true)
		var randomizer := RandomNumberGenerator.new()
		randomizer.seed = int(rotation * 15427 + 28483)
		var ore: Dictionary = {
			"copper": randomizer.randi_range(5, 9),
			"iron": randomizer.randi_range(0, 5),
			"silver": 1 if randomizer.randf() < 0.28 else 0
		}
		if randomizer.randf() < 0.06:
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
		now = int(Time.get_unix_time_from_system())
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
	harlow["scout_finish"] = int(Time.get_unix_time_from_system()) + harlow_scout_seconds()
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
		if str(merc.get("role")) != "Miner" and str(merc.get("role")) != "Guard":
			return "Harlow Mines requires miners and guards; guild scouts operate separately."
		if int(merc.get("health", 100)) < 25:
			return "%s is too injured for deployment." % str(merc["name"])
		seen[id] = true
	var stats: Dictionary = harlow_crew_stats(ids, approach)
	if int(stats["miners"]) == 0:
		return "At least one miner is needed to collect ore."
	if gold < int(stats["wage"]):
		return "Insufficient gold for wages and provisions."
	var available: Dictionary = harlow.get("deposits", {})
	var remaining: int = 0
	for ore_id in available:
		remaining += int(available[ore_id])
	if remaining <= 0:
		return "Harlow Mines have been exhausted this rotation."
	gold -= int(stats["wage"])
	var now := int(Time.get_unix_time_from_system())
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
	reputation += 2 if succeeded else 1
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
			retired_ids.append(id)
			var equipped: Dictionary = worker.get("equipment", {})
			for slot in ["tool", "armor"]:
				var item: Dictionary = equipped.get(slot, {})
				if not item.is_empty():
					lost_items.append("%s — %s" % [str(worker["name"]), V05.item_name(item)])
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
			if str(worker.get("role", "")) == "Miner":
				living_miners += 1
				var gear_stats: Dictionary = V05.equipment_stats(worker)
				effective_capacity += 3 + int(gear_stats["mining"])
	if not casualties.is_empty():
		events.append("%s fell. Their personal equipment was lost." % ", ".join(casualties))
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
	var find_value: int = 0
	if success and not survivors.is_empty() and rng.randf() < 0.15:
		var gear_key: String = "reinforced_pick" if rng.randf() < 0.5 else "steel_sword"
		var recovered_item: Dictionary = make_item(gear_key)
		equipment_inventory.append(recovered_item)
		finds.append(V05.item_name(recovered_item))
		find_value = int(item_definition(gear_key)["cost"])
		events.append("An abandoned %s was found in the shafts." % finds[0].to_lower())
	var coins: int = rng.randi_range(5, 15) if not survivors.is_empty() else 0
	var gross: int = coins + find_value
	for ore in loot:
		gross += int(loot[ore]) * price(str(ore))
	# Short-term v0.5 arrangement: percentage of found coins, NOT
	# entire unsold haul. Prevents negative balances on lucky item drops.
	var commission: int = mini(coins, int(ceil(float(coins) * float(mission["share"]))))
	gold += coins - commission
	_apply_relief_payment()
	reputation += 3 if success else 1
	reports.push_front({
		"region": "Harlow Mines", "won": success, "loot": loot,
		"cash": coins, "commission": commission, "cost": int(mission["cost"]),
		"gross": gross, "tactic": orders, "crew": mission["ids"],
		"time": int(mission["finish"]), "casualties": casualties,
		"injured": wounded, "lost_items": lost_items, "found_items": finds,
		"events": events, "partial": not success and not loot.is_empty(),
		"rotation": int(mission["rotation"]), "extracted": loot.duplicate(true)
	})
	if reports.size() > 35:
		reports.resize(35)
