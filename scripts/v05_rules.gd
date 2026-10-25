extends RefCounted
class_name MercsV05

# Items live in data/catalog.json now (see Catalog and Gear). The quartermaster still sells
# the starter pieces for every trade; everything else is crafted or found.
const SHOP := ["hand_axe", "felling_axe", "basic_pick", "reinforced_pick", "rusted_sword", "steel_sword", "leather", "chainmail",
	"copper_sickle", "birch_rod", "birch_shortbow", "iron_hoe"]

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

## The old four numbers, now read from catalog gear: tool power per trade, a guard's
## weapon tier, and armour (one point of protection per 5 armour).
static func equipment_stats(merc: Dictionary) -> Dictionary:
	var weapon: int = 0
	if Gear.job(merc) == "combat":
		weapon = int(round(float(Gear.weapon_levels(merc)) / 2.0))
	return {"mining": int(Gear.tool_power(merc, "mining")), "logging": int(Gear.tool_power(merc, "logging")),
		"guard": weapon, "protection": int(Gear.armour(merc) / 5.0) + int(merc.get("gear", 0))}

## Gear the quartermaster sells.
static func shop_keys() -> Array:
	return SHOP.duplicate()

static func item_name(item: Dictionary) -> String:
	return Gear.item_name(item)

## Anyone can hold anything that goes in a slot: the tool sets the job.
static func validate_role(key: String, _merc: Dictionary = {}) -> bool:
	return Gear.exists(key) and Gear.equippable(key)

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
		for equipped in Gear.worn(merc):
			gear_value += Gear.value(equipped)
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
