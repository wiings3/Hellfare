extends RefCounted
## Shared company state, including saves, hiring, gear, trading and expedition slots.
## The public MoneyMercsState subclass supplies Harlow-specific simulation.

const V05 = preload("res://scripts/v05_rules.gd")

const SAVE_PATH := "user://money_mercs_save.json"
const RESOURCE_ORDER := ["copper", "iron", "timber", "herbs", "silver", "crystal", "relic", "sovereign"]
const RESOURCE_NAMES := {
	"copper": "Copper Ore", "iron": "Iron Ore", "timber": "Timber", "herbs": "Moonleaf", "silver": "Silver", 
	"crystal": "Azure Crystal", "relic": "Ancient Relic", "sovereign": "Sovereign Orb"
}
const RESOURCE_DESC := {
	"copper": "A reliable metal harvested from Harlow Mines.",
	"iron": "Basic tools, repairs, and early equipment.",
	"timber": "A staple material for trade and construction.",
	"herbs": "Medicinal plants gathered on safer routes.",
	"silver": "Used in advanced equipment and valuable to merchants.",
	"crystal": "A scarce material for elite gear.",
	"relic": "Recovered from forgotten sites. Used by master craftsmen.",
	"sovereign": "The rarest currency. Required for a mythical-tier equipment upgrade."
}
const BASE_PRICE := {"copper": 20, "iron": 17, "timber": 6, "herbs": 5, "silver": 28, "crystal": 75, "relic": 550, "sovereign": 12500}

const RECRUITS := [
	{"id": "garrick", "name": "Garrick", "role": "Miner", "title": "The Quarry Hand", "skill": 11, "hire": 70, "wage": 9, "share": 0.09},
	{"id": "mara", "name": "Mara", "role": "Scout", "title": "The Trailwatcher", "skill": 14, "hire": 110, "wage": 13, "share": 0.10},
	{"id": "oswin", "name": "Oswin", "role": "Guard", "title": "The Oathbreaker", "skill": 17, "hire": 185, "wage": 19, "share": 0.12},
	{"id": "ilya", "name": "Ilya", "role": "Scout", "title": "The Ashwalker", "skill": 21, "hire": 390, "wage": 30, "share": 0.15},
	{"id": "bram", "name": "Bram", "role": "Miner", "title": "The Deep Delver", "skill": 25, "hire": 650, "wage": 42, "share": 0.16},
	{"id": "serah", "name": "Serah", "role": "Guard", "title": "The Iron Vanguard", "skill": 34, "hire": 1350, "wage": 67, "share": 0.18}
]
const REGIONS := [
	{"id": "lowlands", "name": "The Mossward Lowlands", "tagline": "Short supply runs through old logging roads.", "focus": "Guard", "threat": 21, "time": 75, "supplies": 12, "rep": 0,
	"loot": {"iron": [3, 8], "timber": [4, 10], "herbs": [2, 6]}, "bonus": "silver", "bonus_odds": 0.17, "relic_odds": 0.0, "sovereign_odds": 0.0},
	{"id": "ironworks", "name": "The Hollowstone Ironworks", "tagline": "Abandoned shafts with unusually rich veins.", "focus": "Miner", "threat": 39, "time": 240, "supplies": 28, "rep": 12,
	"loot": {"iron": [9, 19], "timber": [2, 5], "silver": [1, 4]}, "bonus": "crystal", "bonus_odds": 0.12, "relic_odds": 0.005, "sovereign_odds": 0.0},
	{"id": "ashen", "name": "The Ashen Reliquary", "tagline": "Buried shrines. Few crews return unscathed.", "focus": "Scout", "threat": 66, "time": 720, "supplies": 65, "rep": 36,
	"loot": {"silver": [4, 10], "crystal": [1, 3], "iron": [3, 9]}, "bonus": "relic", "bonus_odds": 0.12, "relic_odds": 0.05, "sovereign_odds": 0.002}
]
const TACTICS := ["Cautious", "Balanced", "Deep Push"]
const CONTRACTS := ["Balanced", "Guaranteed Wage", "Profit Share"]

var equipment_inventory: Array[Dictionary] = []
var next_item_id: int = 1
var relief_debt: int = 0
var relief_count: int = 0
var retired_ids: Array[String] = []
var harlow: Dictionary = {}
var gold: int = 350
var reputation: int = 0
var expedition_slots: int = 1
var resources: Dictionary = {}
var crew: Array[Dictionary] = []
var missions: Array[Dictionary] = []
var reports: Array[Dictionary] = []
var next_mission_id: int = 1
var last_notice: String = ""
## False while the economy simulator runs: nothing is read from or written to the save.
static var persist: bool = true

var market: MarketModel = MarketModel.new(BASE_PRICE)
var hall: TradeHall = TradeHall.new(market, RESOURCE_ORDER)

func _init() -> void:
	for id in RESOURCE_ORDER:
		resources[id] = 0
	hall.item_name = item_ref_name
	load_game()

func load_game() -> void:
	if not persist or not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		last_notice = "Save file unreadable. Started a new company."
		return
	var state: Dictionary = data
	if int(state.get("version", 0)) != 1:
		last_notice = "Save version not recognized. Started a new company."
		return
	gold = int(state.get("gold", 350))
	reputation = int(state.get("reputation", 0))
	expedition_slots = clampi(int(state.get("expedition_slots", 1)), 1, 3)
	next_mission_id = maxi(1, int(state.get("next_mission_id", 1)))
	var saved_resources: Dictionary = state.get("resources", {})
	for id in RESOURCE_ORDER:
		resources[id] = maxi(0, int(saved_resources.get(id, 0)))
	for m in state.get("crew", []):
		if typeof(m) == TYPE_DICTIONARY:
			crew.append(m)
	for m in state.get("missions", []):
		if typeof(m) == TYPE_DICTIONARY:
			missions.append(m)
	for r in state.get("reports", []):
		if typeof(r) == TYPE_DICTIONARY:
			reports.append(r)
	harlow = state.get("harlow", {})
	next_item_id = maxi(1, int(state.get("next_item_id", 1)))
	relief_debt = maxi(0, int(state.get("relief_debt", 0)))
	relief_count = maxi(0, int(state.get("relief_count", 0)))
	for value in state.get("retired_ids", []):
		retired_ids.append(str(value))
	for item in state.get("equipment_inventory", []):
		if typeof(item) == TYPE_DICTIONARY and V05.ITEMS.has(str(item.get("key", ""))):
			equipment_inventory.append(item)
	for merc in crew:
		if not merc.has("equipment"):
			merc["equipment"] = {"tool": {}, "armor": {}}
		TradeSkills.ensure(merc)
	market.load_dict(state.get("market", {}))
	hall.load_dict(state.get("hall", {}))
	# Listings no longer exist: goods left in them go back to the warehouse.
	for listing in hall.legacy_listings:
		resources[str(listing["good"])] = int(resources.get(str(listing["good"]), 0)) + int(listing["left"])
	hall.legacy_listings.clear()
	last_notice = "Company records restored."

func save_game() -> void:
	if not persist:
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		last_notice = "Unable to save company data."
		return
	var data := {
		"version": 1, "gold": gold, "reputation": reputation,
		"expedition_slots": expedition_slots, "next_mission_id": next_mission_id,
		"resources": resources, "crew": crew, "missions": missions, "reports": reports,
		"harlow": harlow, "equipment_inventory": equipment_inventory,
		"next_item_id": next_item_id, "relief_debt": relief_debt,
		"relief_count": relief_count, "retired_ids": retired_ids,
		"market": market.to_dict(), "hall": hall.to_dict()
	}
	file.store_string(JSON.stringify(data, "\t"))

func region_by_id(id: String) -> Dictionary:
	for region in REGIONS:
		if region["id"] == id:
			return region
	return {}

func recruit_by_id(id: String) -> Dictionary:
	for candidate in RECRUITS:
		if candidate["id"] == id:
			return candidate
	return {}

func merc_by_id(id: String) -> Dictionary:
	for merc in crew:
		if merc["id"] == id:
			return merc
	return {}

func is_available(merc: Dictionary) -> bool:
	return str(merc.get("mission_id", "")) == ""

func recruitment_board() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for candidate in RECRUITS:
		if str(candidate["role"]) != "Scout" and merc_by_id(str(candidate["id"])).is_empty() and not _is_retired(candidate):
			result.append(candidate.duplicate(true))
	var epoch: int = int(GameClock.now() / 1800.0)
	for candidate in V05.generate_board(epoch):
		if merc_by_id(str(candidate["id"])).is_empty() and not _is_retired(candidate):
			result.append(candidate)
	return result

func _is_retired(candidate: Dictionary) -> bool:
	if retired_ids.has(str(candidate["id"])):
		return true
	for record in harlow.get("fallen", []):
		if str(record.get("name", "")) == str(candidate["name"]):
			return true
	return false

func _available_candidate(id: String) -> Dictionary:
	for candidate in recruitment_board():
		if str(candidate["id"]) == id:
			return candidate
	return {}

func hire(id: String) -> String:
	if not merc_by_id(id).is_empty():
		return "Already on your payroll."
	var candidate: Dictionary = _available_candidate(id)
	if candidate.is_empty():
		return "Recruit not found."
	if gold < int(candidate["hire"]):
		return "Not enough gold to hire this mercenary."
	var merc: Dictionary = candidate.duplicate(true)
	merc["gear"] = 0
	merc["equipment"] = {"tool": {}, "armor": {}}
	merc["health"] = 100
	merc["xp"] = 0
	merc["contract"] = "Balanced"
	merc["mission_id"] = ""
	merc["skills"] = TradeSkills.starting_skills(str(merc.get("role", "")), int(merc.get("skill", 10)))
	gold -= int(merc["hire"])
	crew.append(merc)
	save_game()
	return "%s has joined your company." % str(merc["name"])

func terms(merc: Dictionary) -> Dictionary:
	var wage: int = int(merc.get("wage", 10))
	var cut: float = float(merc.get("share", 0.10))
	match str(merc.get("contract", "Balanced")):
		"Guaranteed Wage":
			wage = int(ceil(float(wage) * 1.8))
			cut = maxf(0.01, cut - 0.06)
		"Profit Share":
			wage = maxi(1, int(round(float(wage) * 0.45)))
			cut += 0.07
	return {"wage": wage, "cut": cut}

func switch_contract(id: String) -> String:
	var merc := merc_by_id(id)
	if merc.is_empty():
		return "Mercenary not found."
	if not is_available(merc):
		return "Contracts cannot change mid-expedition."
	var idx: int = CONTRACTS.find(str(merc.get("contract", "Balanced")))
	merc["contract"] = CONTRACTS[(idx + 1) % CONTRACTS.size()]
	save_game()
	return "%s now works under %s terms." % [str(merc["name"]), str(merc["contract"])]

func gear_cost(gear_level: int) -> Dictionary:
	match gear_level:
		0: return {"gold": 85, "iron": 8}
		1: return {"gold": 240, "iron": 18, "silver": 3}
		2: return {"gold": 680, "silver": 12, "crystal": 6}
		3: return {"gold": 2200, "crystal": 24, "relic": 2, "sovereign": 1}
	return {}

func cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for key in cost:
		var name: String = "Gold" if key == "gold" else str(RESOURCE_NAMES.get(key, key))
		parts.append("%d %s" % [int(cost[key]), name])
	return ", ".join(parts)

func _can_afford(cost: Dictionary) -> bool:
	for item in cost:
		var owned: int = gold if item == "gold" else int(resources.get(item, 0))
		if owned < int(cost[item]):
			return false
	return true

func _pay(cost: Dictionary) -> void:
	for item in cost:
		if item == "gold":
			gold -= int(cost[item])
		else:
			resources[item] = int(resources.get(item, 0)) - int(cost[item])

func improve_gear(id: String) -> String:
	var merc := merc_by_id(id)
	if merc.is_empty():
		return "Mercenary not found."
	if not is_available(merc):
		return "Cannot refit a mercenary currently in the field."
	var level: int = int(merc.get("gear", 0))
	if level >= 4:
		return "This mercenary has the finest equipment available."
	var cost := gear_cost(level)
	if not _can_afford(cost):
		return "Upgrade needs: " + cost_text(cost)
	_pay(cost)
	merc["gear"] = level + 1
	save_game()
	return "%s now has equipment tier %d." % [str(merc["name"]), level + 1]

func treat(id: String) -> String:
	var merc := merc_by_id(id)
	if merc.is_empty():
		return "Mercenary not found."
	if not is_available(merc):
		return "Mercenary is still in the field."
	if int(merc.get("health", 100)) >= 100:
		return "No treatment required."
	var cost: int = maxi(12, int(ceil(float(100 - int(merc["health"])) * 1.5)))
	if gold < cost:
		return "Treatment requires %d gold." % cost
	gold -= cost
	merc["health"] = 100
	save_game()
	return "%s recovered for %d gold." % [str(merc["name"]), cost]

## Price of the next expedition slot (0 when all three are open).
func expansion_cost() -> int:
	match expedition_slots:
		1: return 1500
		2: return 9000
	return 0

func expand_operations() -> String:
	if expedition_slots >= 3:
		return "Maximum expedition capacity reached."
	var cost: int = expansion_cost()
	if gold < cost:
		return "You need %d gold to expand operations." % cost
	gold -= cost
	expedition_slots += 1
	save_game()
	return "You can now operate %d expeditions at once." % expedition_slots

func merc_power(merc: Dictionary, region: Dictionary) -> int:
	var power: int = int(merc.get("skill", 10)) + int(merc.get("gear", 0)) * 8
	power += int(merc.get("xp", 0)) / 3
	if str(merc.get("role", "")) == str(region.get("focus", "")):
		power += 7
	power = int(round(float(power) * (0.5 + float(merc.get("health", 100)) / 200.0)))
	return power

func success_chance(region: Dictionary, ids: Array[String], tactic: String) -> float:
	var power: int = 0
	for id in ids:
		var merc := merc_by_id(id)
		if not merc.is_empty():
			power += merc_power(merc, region)
	var probability: float = 0.60 + float(power - int(region.get("threat", 20))) * 0.013
	if tactic == "Cautious":
		probability += 0.12
	elif tactic == "Deep Push":
		probability -= 0.17
	return clampf(probability, 0.10, 0.96)

func expedition_cost(region: Dictionary, ids: Array[String]) -> int:
	var cost: int = int(region.get("supplies", 0))
	for id in ids:
		var merc := merc_by_id(id)
		if not merc.is_empty():
			cost += int(terms(merc)["wage"])
	return cost

func expedition_seconds(region: Dictionary, tactic: String) -> int:
	var mult: float = 1.15 if tactic == "Cautious" else (0.85 if tactic == "Deep Push" else 1.0)
	return maxi(15, int(round(float(region["time"]) * mult)))

func dispatch(region_id: String, ids: Array[String], tactic: String) -> String:
	var region := region_by_id(region_id)
	if region.is_empty():
		return "Unknown expedition."
	if reputation < int(region["rep"]):
		return "This region requires %d company reputation." % int(region["rep"])
	if missions.size() >= expedition_slots:
		return "All expedition slots are occupied."
	if ids.is_empty() or ids.size() > 3:
		return "Choose one to three available mercenaries."
	var seen: Dictionary = {}
	for id in ids:
		var merc := merc_by_id(id)
		if merc.is_empty() or not is_available(merc) or seen.has(id):
			return "Crew selection includes an unavailable mercenary."
		if int(merc.get("health", 100)) < 25:
			return "%s needs medical treatment before traveling." % str(merc["name"])
		seen[id] = true
	if not TACTICS.has(tactic):
		return "Invalid expedition strategy."
	var cost: int = expedition_cost(region, ids)
	if gold < cost:
		return "Requires %d gold upfront for wages and supplies." % cost
	gold -= cost
	var now: int = GameClock.now()
	var mission_id := "job_%d" % next_mission_id
	next_mission_id += 1
	var party_cut: float = 0.0
	for id in ids:
		var merc := merc_by_id(id)
		merc["mission_id"] = mission_id
		party_cut += float(terms(merc)["cut"])
	var mission: Dictionary = {
		"id": mission_id, "region": region_id, "ids": ids.duplicate(), "tactic": tactic,
		"started": now, "finish": now + expedition_seconds(region, tactic),
		"seed": randi(), "cost": cost, "chance": success_chance(region, ids, tactic),
		"share": minf(party_cut, 0.85)
	}
	missions.append(mission)
	save_game()
	return "Expedition funded! %d gold spent; your crew is in the field." % cost

func complete_due(now: int = -1) -> int:
	if now < 0:
		now = GameClock.now()
	var completed: int = 0
	for i in range(missions.size() - 1, -1, -1):
		var mission: Dictionary = missions[i]
		if int(mission["finish"]) > now:
			continue
		if mission.has("site"):
			_site_finish(mission)
		elif str(mission.get("region", "")) == "harlow":
			_harlow_finish(mission)
		elif str(mission.get("region", "")) == "guild_work":
			_finish_guild_work(mission)
		else:
			_finish(mission)
		missions.remove_at(i)
		completed += 1
	if completed > 0:
		save_game()
	return completed

# Guild-supported recovery work: pays modest guaranteed fees, never kills workers,
# requires no capital, and uses the ordinary expedition timer/save system.
# A clerk can always do basic paperwork even after every mercenary is gone.
const GUILD_WORK_SECONDS := 150
const OFFICE_WORK_SECONDS := 180
const GUILD_WORK_PAY := 18
const OFFICE_WORK_PAY := 9

func available_guild_workers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for merc in crew:
		if is_available(merc):
			result.append(merc)
	return result

func can_accept_guild_work() -> bool:
	# These are loss-recovery assignments, not an unlimited safer alternative
	# to dangerous expeditions or the eventual player economy. Judged on what the
	# company could actually raise (see liquid_worth), so gear worn by the crew
	# never locks a broke company out of help.
	return gold < 120 and liquid_worth() < 250

func start_guild_work(worker_id: String = "") -> String:
	if not can_accept_guild_work():
		return "Guild relief contracts are reserved for companies below 120 G cash and 250 G total net worth."
	if missions.size() >= expedition_slots:
		return "All operation slots are occupied."
	var worker: Dictionary = {}
	if not worker_id.is_empty():
		worker = merc_by_id(worker_id)
		if worker.is_empty() or not is_available(worker):
			return "This contractor cannot accept a guild work order."
	var office: bool = worker_id.is_empty()
	var now: int = GameClock.now()
	var task_id: String = "job_%d" % next_mission_id
	next_mission_id += 1
	if not office:
		worker["mission_id"] = task_id
	missions.append({
		"id": task_id, "region": "guild_work", "ids": [] if office else [worker_id],
		"worker": worker_id, "office": office, "cost": 0,
		"cash": OFFICE_WORK_PAY if office else GUILD_WORK_PAY,
		"started": now, "finish": now + (OFFICE_WORK_SECONDS if office else GUILD_WORK_SECONDS)
	})
	save_game()
	if office:
		return "Guild paperwork accepted: 9 G after 3 minutes. No danger or fees."
	return "%s assigned a safe guild work order: 18 G after 2m 30s." % str(worker["name"])

func _finish_guild_work(mission: Dictionary) -> void:
	var worker_id: String = str(mission.get("worker", ""))
	var worker_name: String = "The guild office"
	if not worker_id.is_empty():
		var worker: Dictionary = merc_by_id(worker_id)
		if not worker.is_empty():
			worker_name = str(worker.get("name", "Contractor"))
			worker["mission_id"] = ""
			worker["xp"] = int(worker.get("xp", 0)) + 1
	var payout: int = int(mission.get("cash", OFFICE_WORK_PAY))
	gold += payout
	# Debt repayment only touches funds above the existing 120 G safety reserve.
	_apply_relief_payment()
	reports.push_front({
		"region": "Guild Work Order", "won": true, "loot": {},
		"cash": payout, "commission": 0, "cost": 0, "gross": payout,
		"time": int(mission["finish"]), "tactic": "Safe Work",
		"crew": mission.get("ids", []), "events": [
			"%s completed routine contract work for the guild." % worker_name,
			"Guaranteed fee: %d gold. No combat, injuries or equipment exposure." % payout
		], "casualties": [], "injured": [], "lost_items": [], "found_items": []
	})
	if reports.size() > 35:
		reports.resize(35)

func _finish(mission: Dictionary) -> void:
	var region := region_by_id(str(mission["region"]))
	if region.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(mission["seed"])
	var succeeded: bool = rng.randf() <= float(mission["chance"])
	var mult: float = 0.75 if str(mission["tactic"]) == "Cautious" else (1.45 if str(mission["tactic"]) == "Deep Push" else 1.0)
	if not succeeded:
		mult *= 0.25
	var loot: Dictionary = {}
	for item in region["loot"]:
		var limits: Array = region["loot"][item]
		var count: int = int(round(float(rng.randi_range(int(limits[0]), int(limits[1]))) * mult))
		if count > 0:
			loot[item] = count
	if succeeded and rng.randf() <= float(region["bonus_odds"]) * (1.5 if str(mission["tactic"]) == "Deep Push" else 1.0):
		var bonus: String = str(region["bonus"])
		loot[bonus] = int(loot.get(bonus, 0)) + 1
	if succeeded and rng.randf() < float(region["relic_odds"]) * mult:
		loot["relic"] = int(loot.get("relic", 0)) + 1
	if succeeded and rng.randf() < float(region["sovereign_odds"]) * mult:
		loot["sovereign"] = int(loot.get("sovereign", 0)) + 1
	var cash_found: int = rng.randi_range(10, 24) if succeeded else rng.randi_range(0, 5)
	cash_found = int(round(float(cash_found) * mult))
	var gross_value: int = cash_found
	for item in loot:
		resources[item] = int(resources.get(item, 0)) + int(loot[item])
		gross_value += int(loot[item]) * price(item)
	var commission: int = int(ceil(float(gross_value) * float(mission["share"])))
	gold += cash_found - commission
	for id in mission["ids"]:
		var merc := merc_by_id(str(id))
		if merc.is_empty():
			continue
		merc["mission_id"] = ""
		merc["xp"] = int(merc.get("xp", 0)) + (1 if succeeded else 0)
		if not succeeded:
			merc["health"] = maxi(20, int(merc.get("health", 100)) - rng.randi_range(12, 32))
	reputation += 3 if succeeded else 1
	var result: Dictionary = {
		"region": str(region["name"]), "won": succeeded, "loot": loot, "cash": cash_found,
		"commission": commission, "cost": int(mission["cost"]), "gross": gross_value,
		"time": int(mission["finish"]), "tactic": str(mission["tactic"]), "crew": mission["ids"]
	}
	reports.push_front(result)
	if reports.size() > 35:
		reports.resize(35)

## Fair reference value of a good today (see MarketModel).
func price(item: String) -> int:
	return market.reference_price(item)

## What an NPC merchant pays per unit when the company sells `quantity`.
func sell_price(item: String, quantity: int = 1) -> int:
	return market.npc_buy_price(item, quantity)

## What an NPC merchant charges per unit when the company buys `quantity`.
func buy_price(item: String, quantity: int = 1) -> int:
	return market.npc_sell_price(item, quantity)

## Record hourly price samples; called from the game clock.
func market_tick() -> void:
	market.sample_all(RESOURCE_ORDER)

func trade(item: String, buy: bool, quantity: int) -> String:
	if not BASE_PRICE.has(item) or quantity <= 0:
		return "Invalid trade."
	if buy:
		if item == "relic" or item == "sovereign":
			return "Ancient Relics and Sovereign Orbs cannot be bought from NPC merchants."
		var cost: int = buy_price(item, quantity) * quantity
		if gold < cost:
			return "You need %d gold for this purchase." % cost
		gold -= cost
		resources[item] = int(resources.get(item, 0)) + quantity
		market.record_npc_trade(item, -quantity)
		save_game()
		return "Purchased %d %s for %d gold." % [quantity, str(RESOURCE_NAMES[item]), cost]
	if int(resources.get(item, 0)) < quantity:
		return "You don't have that many resources."
	var revenue: int = sell_price(item, quantity) * quantity
	resources[item] = int(resources[item]) - quantity
	gold += revenue
	market.record_npc_trade(item, quantity)
	_apply_relief_payment()
	save_game()
	return "Sold %d %s for %d gold." % [quantity, str(RESOURCE_NAMES[item]), revenue]

# --- Trade Hall -----------------------------------------------------------------

## Display name for an item ref: a good key, or "gear:<item key>".
func item_ref_name(ref: String) -> String:
	if ref.begins_with("gear:"):
		return str(item_definition(ref.substr(5)).get("name", "Gear"))
	return str(RESOURCE_NAMES.get(ref, ref.capitalize()))

## Spare gear in the storeroom, uid -> item key.
func storeroom_keys() -> Dictionary:
	var keys: Dictionary = {}
	for item in equipment_inventory:
		keys[str(item.get("uid", ""))] = str(item.get("key", ""))
	return keys

func hall_say(text: String, links: Array, now: int = -1) -> String:
	return hall.say(text, links, now if now >= 0 else GameClock.now())

## Send a trader a trade request (they accept once a price is agreed).
func hall_request_trade(trader: String, now: int = -1) -> String:
	return hall.request_trade(trader, now if now >= 0 else GameClock.now())

## Block or unblock a trader; the list is saved.
func hall_block(trader: String, on: bool = true) -> void:
	if on:
		hall.block(trader)
	else:
		hall.unblock(trader)
	save_game()

func hall_pm(trader: String, text: String, links: Array, now: int = -1) -> String:
	return hall.pm(trader, text, links, now if now >= 0 else GameClock.now())

## Advance the Hall. Trades complete here once both sides are ready.
func hall_tick(now: int = -1) -> Array:
	var t: int = now if now >= 0 else GameClock.now()
	var events: Array = hall.tick(t)
	if hall.session != null and hall.session.is_open() and hall.session.both_accepted():
		var trader: String = hall.session.trader
		var result: String = trade_complete(t)
		events.append({"type": "trade_done" if result.begins_with("Traded") else "trade_failed", "trader": trader, "message": result})
	return events

## Put goods from the warehouse into the company's side of the trade (sets the amount).
## Your side can only change while it is unlocked.
func trade_editable() -> bool:
	return hall.session != null and hall.session.is_open() and not hall.session.my_locked

func trade_set_goods(good: String, quantity: int, now: int = -1) -> void:
	var s: TradeSession = hall.session
	if not trade_editable() or not BASE_PRICE.has(good):
		return
	var amount: int = clampi(quantity, 0, int(resources.get(good, 0)))
	if amount <= 0:
		s.mine_goods.erase(good)
	else:
		s.mine_goods[good] = amount
	hall.trade_changed(storeroom_keys(), now if now >= 0 else GameClock.now())

func trade_toggle_gear(uid: String, now: int = -1) -> void:
	var s: TradeSession = hall.session
	if not trade_editable() or not storeroom_keys().has(uid):
		return
	if s.mine_gear.has(uid):
		s.mine_gear.erase(uid)
	else:
		s.mine_gear.append(uid)
	hall.trade_changed(storeroom_keys(), now if now >= 0 else GameClock.now())

func trade_set_gold(amount: int, now: int = -1) -> void:
	var s: TradeSession = hall.session
	if not trade_editable():
		return
	s.mine_gold = clampi(amount, 0, maxi(0, gold))
	hall.trade_changed(storeroom_keys(), now if now >= 0 else GameClock.now())

## Step 1: lock the company's side. If it falls short of the deal, the trader says so.
func trade_lock(now: int = -1) -> void:
	hall.trade_lock(storeroom_keys(), now if now >= 0 else GameClock.now())

## Unlocking (to change something) clears both sides' locks.
func trade_unlock(now: int = -1) -> void:
	hall.trade_changed(storeroom_keys(), now if now >= 0 else GameClock.now())

## Step 2: accept, once both sides are locked and the pause has passed.
func trade_accept(now: int = -1) -> bool:
	return hall.trade_accept(now if now >= 0 else GameClock.now())

func trade_cancel(now: int = -1) -> void:
	hall.trade_cancel(now if now >= 0 else GameClock.now())

## Swap both sides. Gold the company receives is taxed 3%.
func trade_complete(now: int = -1) -> String:
	var s: TradeSession = hall.session
	if s == null or not s.is_open():
		return "No trade is open."
	var t: int = now if now >= 0 else GameClock.now()
	var keys: Dictionary = storeroom_keys()
	for good in s.mine_goods:
		if int(resources.get(good, 0)) < int(s.mine_goods[good]):
			s.changed()
			return "You no longer have that many %s." % item_ref_name(str(good))
	for uid in s.mine_gear:
		if not keys.has(uid):
			s.changed()
			return "That gear is no longer in the storeroom."
	if gold < s.mine_gold:
		s.changed()
		return "You don't have %d gold." % s.mine_gold
	# The company's side leaves.
	gold -= s.mine_gold
	for good in s.mine_goods:
		resources[good] = int(resources[good]) - int(s.mine_goods[good])
		market.record_npc_trade(str(good), int(s.mine_goods[good]), t)
	for uid in s.mine_gear:
		for i in range(equipment_inventory.size()):
			if str(equipment_inventory[i].get("uid", "")) == uid:
				equipment_inventory.remove_at(i)
				break
	# The trader's side arrives.
	var tax: int = int(round(float(s.their_gold) * TradeHall.TAX)) if s.their_gold > 0 else 0
	gold += s.their_gold - tax
	for good in s.their_goods:
		resources[good] = int(resources.get(good, 0)) + int(s.their_goods[good])
		market.record_npc_trade(str(good), -int(s.their_goods[good]), t)
	for key in s.their_gear:
		equipment_inventory.append(make_item(str(key)))
	var trader: String = s.trader
	var got: Array[String] = []
	for good in s.their_goods:
		got.append("%d %s" % [int(s.their_goods[good]), item_ref_name(str(good))])
	for key in s.their_gear:
		got.append(item_ref_name("gear:" + str(key)))
	if s.their_gold > 0:
		got.append("%d gold (%d tax)" % [s.their_gold - tax, tax])
	hall.trade_finished(t)
	_apply_relief_payment()
	save_game()
	return "Traded with %s. Received %s." % [trader, ", ".join(got) if not got.is_empty() else "nothing"]

func item_definition(key: String) -> Dictionary:
	return V05.ITEMS.get(key, {})

func owned_equipment_value() -> int:
	var amount: int = 0
	for item in equipment_inventory:
		amount += int(item_definition(str(item.get("key", ""))).get("cost", 0))
	for merc in crew:
		var worn: Dictionary = merc.get("equipment", {})
		for slot in ["tool", "armor"]:
			amount += int(item_definition(str((worn.get(slot, {}) as Dictionary).get("key", ""))).get("cost", 0))
	return amount

func make_item(key: String) -> Dictionary:
	var item: Dictionary = {"uid": "gear_%d" % next_item_id, "key": key}
	next_item_id += 1
	return item

func buy_equipment(key: String) -> String:
	var definition: Dictionary = item_definition(key)
	if definition.is_empty():
		return "That equipment does not exist."
	var cost: int = int(definition["cost"])
	if gold < cost:
		return "You need %d gold." % cost
	gold -= cost
	equipment_inventory.append(make_item(key))
	save_game()
	return "Purchased %s for %d gold." % [str(definition["name"]), cost]

func sell_equipment(uid: String) -> String:
	for i in range(equipment_inventory.size()):
		var item: Dictionary = equipment_inventory[i]
		if str(item.get("uid", "")) != uid:
			continue
		var name: String = V05.item_name(item)
		var value: int = maxi(1, int(floor(float(item_definition(str(item["key"]))["cost"]) * 0.65)))
		equipment_inventory.remove_at(i)
		gold += value
		_apply_relief_payment()
		save_game()
		return "Sold %s for %d gold." % [name, value]
	return "Only loose equipment in the armory may be sold."

func equip_item(merc_id: String, uid: String) -> String:
	var merc: Dictionary = merc_by_id(merc_id)
	if merc.is_empty() or not is_available(merc):
		return "Select an available mercenary."
	var index: int = -1
	for i in range(equipment_inventory.size()):
		if str(equipment_inventory[i].get("uid", "")) == uid:
			index = i
			break
	if index < 0:
		return "Equipment not found in the armory."
	var item: Dictionary = equipment_inventory[index]
	var key: String = str(item.get("key", ""))
	if not V05.validate_role(key, merc):
		return "This item cannot be equipped by that role."
	var slot: String = str(item_definition(key)["slot"])
	var worn: Dictionary = merc.get("equipment", {"tool": {}, "armor": {}})
	var previous: Dictionary = worn.get(slot, {})
	equipment_inventory.remove_at(index)
	if not previous.is_empty():
		equipment_inventory.append(previous)
	worn[slot] = item
	merc["equipment"] = worn
	save_game()
	return "%s equipped %s." % [str(merc["name"]), str(item_definition(key)["name"])]

func unequip_item(merc_id: String, slot: String) -> String:
	var merc: Dictionary = merc_by_id(merc_id)
	if merc.is_empty() or not is_available(merc) or not ["tool", "armor"].has(slot):
		return "Worker unavailable for outfitting."
	var worn: Dictionary = merc.get("equipment", {})
	var item: Dictionary = worn.get(slot, {})
	if item.is_empty():
		return "Nothing equipped in that slot."
	equipment_inventory.append(item)
	worn[slot] = {}
	merc["equipment"] = worn
	save_game()
	return "%s placed %s into the armory." % [str(merc["name"]), V05.item_name(item)]

func guild_relief() -> String:
	if not missions.is_empty() or gold >= 28:
		return "The guild issues advances only when you cannot afford a basic expedition."
	if relief_debt >= 440:
		return "The guild will not extend more credit until you repay some debt."
	if liquid_worth() > 250:
		return "Sell some of your goods or spare gear before requesting guild support."
	gold += 90
	relief_debt += 110
	relief_count += 1
	reputation = maxi(0, reputation - 3)
	save_game()
	return "The guild advanced 90 gold. You owe 110 gold from future trade proceeds."

func _apply_relief_payment() -> void:
	if relief_debt <= 0 or gold <= 120:
		return
	var paid: int = mini(relief_debt, gold - 120)
	gold -= paid
	relief_debt -= paid

## Merchant value of the warehouse.
func goods_value() -> int:
	var total: int = 0
	for item in RESOURCE_ORDER:
		total += int(resources.get(item, 0)) * sell_price(item)
	return total

## What the company could turn into cash today: gold, warehouse goods at merchant
## prices and spare gear in the storeroom, less guild debt. Gear worn by the crew is left
## out, so a company that cannot pay wages always qualifies for guild help.
func liquid_worth() -> int:
	var total: int = gold + goods_value() - relief_debt
	for item in equipment_inventory:
		total += maxi(1, int(floor(float(item_definition(str(item.get("key", ""))).get("cost", 0)) * 0.65)))
	return total

func wealth() -> int:
	var total: int = gold + goods_value()
	for merc in crew:
		total += int(merc.get("gear", 0)) * 60
	total += owned_equipment_value()
	total -= relief_debt
	return total

func free_crew() -> int:
	var available: int = 0
	for merc in crew:
		if is_available(merc):
			available += 1
	return available

func debug_skip(seconds: int) -> String:
	for mission in missions:
		mission["finish"] = int(mission["finish"]) - seconds
	var resolved: int = complete_due()
	save_game()
	return "Simulated %d minutes forward; %d expedition(s) completed." % [int(seconds / 60), resolved]

func reset_company() -> void:
	gold = 350
	reputation = 0
	expedition_slots = 1
	next_mission_id = 1
	crew.clear()
	missions.clear()
	reports.clear()
	harlow.clear()
	equipment_inventory.clear()
	next_item_id = 1
	relief_debt = 0
	relief_count = 0
	retired_ids.clear()
	market.reset()
	hall.reset()
	for item in RESOURCE_ORDER:
		resources[item] = 0
	save_game()


# Called from generic expedition completion; implemented by MoneyMercsState.
func _harlow_finish(_mission: Dictionary) -> void:
	push_error("CompanyStateBase needs a Harlow expedition resolver.")

func _site_finish(_mission: Dictionary) -> void:
	push_error("CompanyStateBase needs a site expedition resolver.")

