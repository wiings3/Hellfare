class_name Catalog
extends RefCounted
## The item catalog: every material, piece of gear, consumable and intermediate, read from
## data/catalog.json (written by tools/catalog_gen.py). Read-only at runtime.
##
## Today the live game still prices and equips gear from MercsV05.ITEMS and goods from
## CompanyStateBase; tests/catalog_test.gd keeps those in step with this catalog. Crafting,
## wear and kit rating read from here when they are built.

const PATH := "res://data/catalog.json"
static var _data: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty():
		var text: String = FileAccess.get_file_as_string(PATH)
		var parsed: Variant = JSON.parse_string(text)
		if parsed is Dictionary:
			_data = parsed
		else:
			push_error("Catalog: could not read " + PATH)
	return _data

static func materials() -> Dictionary:
	return data().get("materials", {})

static func items() -> Dictionary:
	return data().get("items", {})

static func sources() -> Dictionary:
	return data().get("sources", {})

static func rules() -> Dictionary:
	return data().get("rules", {})

static func material(id: String) -> Dictionary:
	return materials().get(id, {})

static func item(id: String) -> Dictionary:
	return items().get(id, {})

## Value of one unit of a material or item.
static func value_of(id: String) -> float:
	if materials().has(id):
		return float(materials()[id]["value"])
	return float(items().get(id, {}).get("value", 0))

## Market value of everything a recipe consumes.
static func recipe_cost(recipe: Dictionary) -> float:
	var total: float = 0.0
	for part in recipe:
		total += value_of(str(part)) * float(recipe[part])
	return total

## Kit rating of a set of equipped item ids (worn-out pieces count half). Each piece's "kit"
## is its tier times its slot weight; trinkets, packs, lanterns and food add nothing.
static func kit_rating(keys: Array, worn: Array = []) -> int:
	var total: float = 0.0
	for key in keys:
		var kit: float = float(item(str(key)).get("kit", 0))
		total += kit * (float(rules().get("worn_effect", 0.5)) if worn.has(key) else 1.0)
	return int(total)

## Items in a category ("weapon", "armour", "shield", "tool", "food", "potion", "trinket", "pack", "lantern", "material").
static func in_category(category: String) -> Array:
	var out: Array = []
	for key in items():
		if str(items()[key].get("category", "")) == category:
			out.append(key)
	return out

## Expected damage per second of a weapon's base stats, counting critical hits.
static func expected_dps(stats: Dictionary) -> float:
	var crit: float = float(stats.get("crit_chance", 0.0))
	return float(stats.get("damage", 0)) * float(stats.get("attack_speed", 1.0)) * (1.0 + crit * (float(stats.get("crit_damage", 1.0)) - 1.0))

## Items whose recipe uses this material or intermediate.
static func used_in(id: String) -> Array:
	var out: Array = []
	for key in items():
		var recipe: Variant = items()[key].get("recipe")
		if recipe is Dictionary and recipe.has(id):
			out.append(key)
	return out
