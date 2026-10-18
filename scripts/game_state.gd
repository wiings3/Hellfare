extends RefCounted
class_name MoneyMercsState

const V05 = preload("res://scripts/v05_rules.gd")

const SAVE_PATH := "user://money_mercs_save.json"
const RESOURCE_ORDER := ["copper", "iron", "timber", "herbs", "silver", "crystal", "relic", "sovereign"]
const RESOURCE_NAMES := {
	"copper": "Copper Ore", "iron": "Iron Ore", "timber": "Oldgrowth Timber", "herbs": "Moonleaf", "silver": "Silver", 
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
const BASE_PRICE := {"copper": 12, "iron": 14, "timber": 4, "herbs": 5, "silver": 28, "crystal": 75, "relic": 550, "sovereign": 12500}

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

func _init() -> void:
	for id in RESOURCE_ORDER:
		resources[id] = 0
	load_game()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
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
	for item in state.get("equipment_inventory", []):
		if typeof(item) == TYPE_DICTIONARY and V05.ITEMS.has(str(item.get("key", ""))):
			equipment_inventory.append(item)
	for merc in crew:
		if not merc.has("equipment"):
			merc["equipment"] = {"tool": {}, "armor": {}}
	last_notice = "Company records restored."

func save_game() -> void:
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
		"relief_count": relief_count
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
		if str(candidate["role"]) != "Scout" and merc_by_id(str(candidate["id"])).is_empty():
			result.append(candidate.duplicate(true))
	var epoch: int = int(Time.get_unix_time_from_system() / 1800.0)
	for candidate in V05.generate_board(epoch):
		if merc_by_id(str(candidate["id"])).is_empty():
			result.append(candidate)
	return result

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

func expand_operations() -> String:
	if expedition_slots >= 3:
		return "Maximum expedition capacity reached."
	var cost: int = 900 if expedition_slots == 1 else 4200
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
	var now: int = int(Time.get_unix_time_from_system())
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
		now = int(Time.get_unix_time_from_system())
	var completed: int = 0
	for i in range(missions.size() - 1, -1, -1):
		var mission: Dictionary = missions[i]
		if int(mission["finish"]) > now:
			continue
		if str(mission.get("region", "")) == "harlow":
			_harlow_finish(mission)
		else:
			_finish(mission)
		missions.remove_at(i)
		completed += 1
	if completed > 0:
		save_game()
	return completed

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

func price(item: String) -> int:
	var base: int = int(BASE_PRICE.get(item, 1))
	var market_period: int = int(Time.get_unix_time_from_system() / 21600.0)
	var fluctuation: int = posmod(item.hash() + market_period * 17, 25) - 12
	return maxi(1, int(round(float(base) * (1.0 + float(fluctuation) / 100.0))))

func sell_price(item: String) -> int:
	return maxi(1, int(floor(float(price(item)) * 0.90)))

func buy_price(item: String) -> int:
	return maxi(1, int(ceil(float(price(item)) * 1.12)))

func trade(item: String, buy: bool, quantity: int) -> String:
	if not BASE_PRICE.has(item) or quantity <= 0:
		return "Invalid trade."
	if buy:
		if item == "relic" or item == "sovereign":
			return "Ancient Relics and Sovereign Orbs cannot be bought from NPC merchants."
		var cost: int = buy_price(item) * quantity
		if gold < cost:
			return "You need %d gold for this purchase." % cost
		gold -= cost
		resources[item] = int(resources.get(item, 0)) + quantity
		save_game()
		return "Purchased %d %s for %d gold." % [quantity, str(RESOURCE_NAMES[item]), cost]
	if int(resources.get(item, 0)) < quantity:
		return "You don't have that many resources."
	var revenue: int = sell_price(item) * quantity
	resources[item] = int(resources[item]) - quantity
	gold += revenue
	_apply_relief_payment()
	save_game()
	return "Sold %d %s for %d gold." % [quantity, str(RESOURCE_NAMES[item]), revenue]

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

func wealth() -> int:
	var total: int = gold
	for item in RESOURCE_ORDER:
		total += int(resources.get(item, 0)) * sell_price(item)
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
	for item in RESOURCE_ORDER:
		resources[item] = 0
	save_game()


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
			"scout_finish": 0,
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
