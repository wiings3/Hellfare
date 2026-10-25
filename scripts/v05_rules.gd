extends RefCounted
class_name MercsV05

# Data-only item catalogue: each entry represents a real inventory object.
# The legacy "gear" tier is read as a temporary bonus for older saves.
const ITEMS := {
	"basic_pick": {"name": "Iron Pickaxe", "slot": "tool", "role": "Miner", "cost": 28, "mining": 1, "guard": 0, "protection": 0},
	"reinforced_pick": {"name": "Reinforced Pickaxe", "slot": "tool", "role": "Miner", "cost": 105, "mining": 2, "guard": 0, "protection": 0},
	"rusted_sword": {"name": "Rusted Sword", "slot": "tool", "role": "Guard", "cost": 30, "mining": 0, "guard": 1, "protection": 0},
	"steel_sword": {"name": "Steel Sword", "slot": "tool", "role": "Guard", "cost": 125, "mining": 0, "guard": 3, "protection": 0},
	"hand_axe": {"name": "Hand Axe", "slot": "tool", "role": "Woodcutter", "cost": 26, "mining": 0, "guard": 0, "protection": 0, "logging": 1},
	"felling_axe": {"name": "Felling Axe", "slot": "tool", "role": "Woodcutter", "cost": 98, "mining": 0, "guard": 0, "protection": 0, "logging": 2},
	"leather": {"name": "Leather Armor", "slot": "armor", "role": "Any", "cost": 38, "mining": 0, "guard": 0, "protection": 1},
	"chainmail": {"name": "Chainmail", "slot": "armor", "role": "Any", "cost": 138, "mining": 0, "guard": 0, "protection": 3},
	# Found only on the fallen: never sold by the quartermaster. "cost" is their worth.
	"dwarven_pick": {"name": "Dwarven Pickaxe", "slot": "tool", "role": "Miner", "cost": 900, "mining": 4, "guard": 0, "protection": 0, "found": true},
	"wardens_axe": {"name": "Warden's Axe", "slot": "tool", "role": "Woodcutter", "cost": 800, "mining": 0, "guard": 0, "protection": 0, "logging": 4, "found": true},
	"knights_blade": {"name": "Knight's Blade", "slot": "tool", "role": "Guard", "cost": 1100, "mining": 0, "guard": 5, "protection": 0, "found": true},
	"gilded_plate": {"name": "Gilded Plate", "slot": "armor", "role": "Any", "cost": 1500, "mining": 0, "guard": 0, "protection": 5, "found": true}
}

const FIRST_NAMES := [
	"Edric", "Nessa", "Tobin", "Cora", "Lukas", "Yara", "Fenna", "Rurik",
	"Daria", "Merrin", "Alric", "Bryn", "Hale", "Perrin", "Vera", "Otto",
	"Anja", "Torren", "Celia", "Bastian"
]
const LAST_NAMES := [
	"Blackstone", "Moor", "Fell", "Ash", "Holt", "Voss", "Wick",
	"Vale", "Fallow", "Dunn", "Marsh", "Rook"
]

# The recruit board lives in mercs.gd (Mercs.generate_board): applicants depend on reputation.

static func equipment_stats(merc: Dictionary) -> Dictionary:
	var mining := 0
	var guard := 0
	var protection := 0
	var logging := 0
	var equipment: Dictionary = merc.get("equipment", {})
	for slot in ["tool", "armor"]:
		var item: Dictionary = equipment.get(slot, {})
		var key: String = str(item.get("key", ""))
		if not ITEMS.has(key):
			continue
		var definition: Dictionary = ITEMS[key]
		mining += int(definition.get("mining", 0))
		guard += int(definition.get("guard", 0))
		protection += int(definition.get("protection", 0))
		logging += int(definition.get("logging", 0))
	# Legacy tier still has value, without creating a phantom physical item.
	var legacy: int = int(merc.get("gear", 0))
	return {"mining": mining, "guard": guard, "protection": protection + legacy, "logging": logging}

## Gear the quartermaster sells (everything except found-only pieces).
static func shop_keys() -> Array:
	var keys: Array = []
	for key in ITEMS:
		if not bool(ITEMS[key].get("found", false)):
			keys.append(key)
	return keys

static func item_name(item: Dictionary) -> String:
	return str(ITEMS.get(str(item.get("key", "")), {}).get("name", "Unknown item"))

## Anyone can hold any tool or weapon: the tool sets the job. Only unknown items are refused.
static func validate_role(key: String, _merc: Dictionary = {}) -> bool:
	return ITEMS.has(key)

static func assess_party(mercs: Array[Dictionary], approach: String, danger: int, supplies: int) -> Dictionary:
	var miners := 0
	var guards := 0
	var capacity := 0
	var guard_points := 0
	var protection := 0
	var average_skill := 0
	var wages := supplies
	var gear_value := 0
	var deaths: Dictionary = {}
	for merc in mercs:
		average_skill += int(merc.get("skill", 10)) + int(merc.get("xp", 0)) / 4
		var stats: Dictionary = equipment_stats(merc)
		var role: String = Mercs.role_of(merc)
		if role == "Miner":
			miners += 1
			capacity += 6 + int(stats["mining"])
		elif role == "Guard":
			guards += 1
			guard_points += 1 + int(stats["guard"])
		protection += int(stats["protection"])
		for slot in ["tool", "armor"]:
			var equipped: Dictionary = (merc.get("equipment", {}) as Dictionary).get(slot, {})
			var id: String = str(equipped.get("key", ""))
			if ITEMS.has(id):
				gear_value += int(ITEMS[id]["cost"])
		gear_value += int(merc.get("gear", 0)) * 60
		# Use the same staged casualty odds that the resolver will roll.
		var risk: float = 0.10 + danger * 0.065 - guard_points * 0.028
		# Recalculated below once every party member is known.
		deaths[str(merc["id"])] = risk
	if not mercs.is_empty():
		average_skill = int(average_skill / mercs.size())
	var protection_score: float = float(guards) * 0.16 + float(guard_points) * 0.055
	var preparation: float = (float(average_skill) - 12.0) * 0.006 + float(protection) * 0.012
	var success: float = 0.64 - 0.085 * float(danger) + protection_score + preparation
	if approach == "Cautious":
		success += 0.10
	elif approach == "Deep Push":
		success -= 0.13
	success = clampf(success, 0.10, 0.96)
	var general_risk: float = 0.02 + float(danger) * 0.035 - protection_score * 0.20
	for merc in mercs:
		var defense: Dictionary = equipment_stats(merc)
		var difference: float = float(int(merc.get("skill", 10)) - 12) * 0.003
		var personal_risk: float = general_risk - float(defense["protection"]) * 0.026 - difference
		if approach == "Cautious":
			personal_risk *= 0.60
		elif approach == "Deep Push":
			personal_risk *= 1.35
		if Mercs.job(merc) == "combat":
			personal_risk *= 1.12
		personal_risk *= Mercs.death_mult(merc)
		deaths[str(merc["id"])] = clampf(personal_risk, 0.003, 0.45)
	for merc in mercs:
		var base_wage: int = int(merc.get("wage", 9))
		var cut: float = float(merc.get("share", 0.09))
		match str(merc.get("contract", "Balanced")):
			"Guaranteed Wage":
				base_wage = int(ceil(float(base_wage) * 1.8))
			"Profit Share":
				base_wage = maxi(1, int(round(float(base_wage) * 0.45)))
		wages += base_wage
	var duration := 360 if approach == "Cautious" else (250 if approach == "Deep Push" else 300)
	return {
		"miners": miners, "guards": guards, "capacity": capacity,
		"success": success, "death": deaths, "wage": wages,
		"duration": duration, "gear_value": gear_value,
		"protection": guard_points
	}
