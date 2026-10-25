class_name Gear
extends RefCounted
## Equipment made of catalog items (data/catalog.json). A mercenary has ten slots; every piece
## rolls a rarity and 0-3 extra stats when it's made, wears down with use, and works at half
## effect once worn out until it's repaired. Food and potions sit in their own slots and are
## used up on trips.
##
## An item instance: {"uid", "key", "rarity", "rolls": {stat: value}, "dur"}. Rolls are in the
## units their text shows (percent for most, flat for armour and health).

const SLOTS := ["main_hand", "off_hand", "head", "body", "hands", "feet", "trinket", "back", "food", "potion"]
const SLOT_NAMES := {"main_hand": "Main hand", "off_hand": "Off hand", "head": "Head", "body": "Body", "hands": "Hands",
	"feet": "Feet", "trinket": "Trinket", "back": "Back", "food": "Food", "potion": "Potion"}
const CONSUMABLE_SLOTS := ["food", "potion"]
## Older saves' two slots.
const LEGACY_SLOTS := {"tool": "main_hand", "armor": "body"}
## Durability a trip uses: 1, or 3 for the long orders; a dungeon run uses 4.
const WEAR_TRIP := 1
const WEAR_LONG := 3
const LONG_ORDERS := ["Long Shift", "Overnight", "Full Day"]
## Each tier's timber, used for every handle and every repair.
const HANDLE := {1: "timber", 2: "oak", 3: "yew", 4: "ironwood", 5: "ghostwood"}
## Share of a piece's recipe a full repair costs.
const REPAIR_SHARE := 0.35
## Categories whose numeric stats are percentages (the rest are fractions or flat values).
const PERCENT_CATEGORIES := ["trinket", "pack", "lantern"]

# --- Definitions ---------------------------------------------------------------------

static func def(key: String) -> Dictionary:
	return Catalog.item(key)

static func exists(key: String) -> bool:
	return Catalog.items().has(key)

static func slot_of(key: String) -> String:
	return str(def(key).get("slot", "none"))

static func category(key: String) -> String:
	return str(def(key).get("category", ""))

## Things a mercenary wears or carries in a slot (not materials).
static func equippable(key: String) -> bool:
	return SLOTS.has(slot_of(key))

static func consumable(key: String) -> bool:
	return CONSUMABLE_SLOTS.has(slot_of(key))

static func rarity_def(id: String) -> Dictionary:
	for r in Catalog.data().get("rarity", []):
		if str(r["id"]) == id:
			return r
	return {"id": "common", "name": "Common", "affixes": 0, "value_mult": 1.0}

static func item_name(item: Dictionary) -> String:
	var key: String = str(item.get("key", ""))
	return str(def(key).get("name", "Unknown item"))

## "Fine Steel Sword", or the plain name for common and found pieces.
static func full_name(item: Dictionary) -> String:
	var r: String = str(item.get("rarity", "common"))
	if r == "common" or r == "found" or not exists(str(item.get("key", ""))):
		return item_name(item)
	return "%s %s" % [str(rarity_def(r)["name"]), item_name(item)]

static func empty_equipment() -> Dictionary:
	var out: Dictionary = {}
	for slot in SLOTS:
		out[slot] = {}
	return out

## Bring a mercenary's equipment up to the ten slots (older saves had "tool" and "armor").
static func ensure(merc: Dictionary) -> void:
	var worn: Dictionary = merc.get("equipment", {})
	for old in LEGACY_SLOTS:
		if worn.has(old):
			var item: Dictionary = worn[old]
			if not item.is_empty() and (worn.get(LEGACY_SLOTS[old], {}) as Dictionary).is_empty():
				worn[LEGACY_SLOTS[old]] = item
			worn.erase(old)
	for slot in SLOTS:
		if not worn.has(slot):
			worn[slot] = {}
	merc["equipment"] = worn
	for slot in SLOTS:
		ensure_item(worn[slot])

## Older items had no rarity, rolls or durability: they become common and fully repaired.
static func ensure_item(item: Dictionary) -> void:
	if item.is_empty():
		return
	if not item.has("rarity"):
		item["rarity"] = "found" if bool(def(str(item.get("key", ""))).get("found_only", false)) else "common"
	if not item.has("rolls"):
		item["rolls"] = (def(str(item.get("key", ""))).get("fixed_rolls", {}) as Dictionary).duplicate()
	if not item.has("dur") and max_durability(item) > 0:
		item["dur"] = max_durability(item)

# --- Making pieces ----------------------------------------------------------------------

static func roll_rarity(rng: RandomNumberGenerator) -> String:
	var roll: float = rng.randf()
	var acc: float = 0.0
	for r in Catalog.data().get("rarity", []):
		acc += float(r["chance"])
		if roll < acc:
			return str(r["id"])
	return "common"

## `count` different stats from the piece's pool, each within its tier's range.
static func roll_affixes(rng: RandomNumberGenerator, key: String, count: int) -> Dictionary:
	var d: Dictionary = def(key)
	var pool: Array = (d.get("rolls", []) as Array).duplicate()
	var scale: float = float(Catalog.rules().get("affix_scale", {}).get(str(clampi(int(d.get("tier", 1)), 1, 5)), 1.0))
	var out: Dictionary = {}
	for i in range(mini(count, pool.size())):
		var stat: String = str(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
		var a: Dictionary = Catalog.data()["affixes"][stat]
		out[stat] = rng.randi_range(int(round(float(a["low"]) * scale)), int(round(float(a["high"]) * scale)))
	return out

## A new piece at full durability. Gear rolls a rarity (or takes the one given); found-only
## pieces come with their fixed rolls; food and potions don't roll.
static func make(key: String, uid: String, rng: RandomNumberGenerator, rarity: String = "") -> Dictionary:
	var d: Dictionary = def(key)
	var item: Dictionary = {"uid": uid, "key": key}
	if bool(d.get("found_only", false)):
		item["rarity"] = "found"
		item["rolls"] = (d.get("fixed_rolls", {}) as Dictionary).duplicate()
	elif consumable(key) or not d.has("rolls"):
		item["rarity"] = "common"
		item["rolls"] = {}
	else:
		item["rarity"] = rarity if rarity != "" else roll_rarity(rng)
		item["rolls"] = roll_affixes(rng, key, int(rarity_def(str(item["rarity"]))["affixes"]))
	if max_durability(item) > 0:
		item["dur"] = max_durability(item)
	return item

# --- Durability and value -----------------------------------------------------------------

static func max_durability(item: Dictionary) -> int:
	var base: Variant = def(str(item.get("key", ""))).get("durability")
	if base == null or consumable(str(item.get("key", ""))):
		return 0
	return int(round(float(base) * (1.0 + float((item.get("rolls", {}) as Dictionary).get("sturdy", 0)) / 100.0)))

static func durability(item: Dictionary) -> int:
	return int(item.get("dur", max_durability(item)))

static func worn_out(item: Dictionary) -> bool:
	return max_durability(item) > 0 and durability(item) <= 0

static func effect(item: Dictionary) -> float:
	return float(Catalog.rules().get("worn_effect", 0.5)) if worn_out(item) else 1.0

## Worth of a piece: its catalog value times its rarity.
static func value(item: Dictionary) -> int:
	var d: Dictionary = def(str(item.get("key", "")))
	return int(round(float(d.get("value", 0)) * float(rarity_def(str(item.get("rarity", "common"))).get("value_mult", 1.0))))

# --- Effects of what a mercenary wears -------------------------------------------------------

static func worn(merc: Dictionary) -> Array:
	var out: Array = []
	var eq: Dictionary = merc.get("equipment", {})
	for slot in SLOTS:
		if CONSUMABLE_SLOTS.has(slot):
			continue
		var item: Dictionary = eq.get(slot, {})
		if not item.is_empty() and exists(str(item.get("key", ""))):
			out.append(item)
	return out

static func in_slot(merc: Dictionary, slot: String) -> Dictionary:
	return (merc.get("equipment", {}) as Dictionary).get(slot, {})

## Sum of a rolled stat over everything worn (worn-out pieces count half).
static func rolled(merc: Dictionary, stat: String) -> float:
	var total: float = 0.0
	for item in worn(merc):
		total += float((item.get("rolls", {}) as Dictionary).get(stat, 0)) * effect(item)
	return total

## Sum of a base stat over worn pieces of the given categories, as a fraction where the
## catalog gives a percentage.
static func base(merc: Dictionary, stat: String, categories: Array = []) -> float:
	var total: float = 0.0
	for item in worn(merc):
		var d: Dictionary = def(str(item["key"]))
		if not categories.is_empty() and not categories.has(str(d.get("category", ""))):
			continue
		var v: float = float((d.get("stats", {}) as Dictionary).get(stat, 0.0))
		if PERCENT_CATEGORIES.has(str(d.get("category", ""))):
			v /= 100.0
		total += v * effect(item)
	return total

## The trade the piece in their main hand is for, "combat" for a weapon, "" for none.
static func job(merc: Dictionary) -> String:
	var item: Dictionary = in_slot(merc, "main_hand")
	var d: Dictionary = def(str(item.get("key", "")))
	match str(d.get("category", "")):
		"tool": return str(d.get("trade", ""))
		"weapon": return "combat"
	return ""

## True if the weapon in hand is good for hunting (bows best, then crossbows and spears).
static func hunts(merc: Dictionary) -> bool:
	if job(merc) != "combat":
		return false
	return float((def(str(in_slot(merc, "main_hand").get("key", ""))).get("stats", {}) as Dictionary).get("hunt", 0)) > 0.0

static func tool_power(merc: Dictionary, trade: String) -> float:
	if trade == "hunting":
		if not hunts(merc):
			return 0.0
		var w: Dictionary = in_slot(merc, "main_hand")
		var wd: Dictionary = def(str(w["key"]))
		var tier: float = 4.5 if bool(wd.get("found_only", false)) else float(wd.get("tier", 1))
		return round(tier * float(wd["stats"]["hunt"]) / 2.0) * effect(w)
	if job(merc) != trade:
		return 0.0
	var item: Dictionary = in_slot(merc, "main_hand")
	return float((def(str(item["key"])).get("stats", {}) as Dictionary).get(trade, 0)) * effect(item)

## A guard's weapon adds two Combat levels per tier.
static func weapon_levels(merc: Dictionary) -> int:
	if job(merc) != "combat":
		return 0
	var item: Dictionary = in_slot(merc, "main_hand")
	var d: Dictionary = def(str(item["key"]))
	var tier: float = 4.5 if bool(d.get("found_only", false)) else float(d.get("tier", 1))
	return int(round(tier * 2.0 * effect(item)))

static func armour(merc: Dictionary) -> float:
	return base(merc, "armour", ["armour", "shield"]) + rolled(merc, "armour")

## Chance of being hurt, relative to an unarmoured mercenary: armour soaks, dodge and warding avoid.
static func injury_mult(merc: Dictionary) -> float:
	var avoid: float = base(merc, "dodge") + rolled(merc, "dodge") / 100.0 + base(merc, "injury_resist") + rolled(merc, "injury_resist") / 100.0
	return 100.0 / (100.0 + armour(merc)) * maxf(0.2, 1.0 - avoid)

static func death_mult(merc: Dictionary) -> float:
	return 100.0 / (100.0 + armour(merc))

## Extra haul: "Bountiful" rolls, trinkets and packs (carrying).
static func haul_mult(merc: Dictionary) -> float:
	return 1.0 + rolled(merc, "yield") / 100.0 + base(merc, "yield", ["trinket"]) + base(merc, "carry", ["pack"]) + rolled(merc, "carry") / 100.0

static func xp_mult(merc: Dictionary) -> float:
	return 1.0 + rolled(merc, "xp") / 100.0 + base(merc, "xp", ["trinket"])

static func rare_mult(merc: Dictionary) -> float:
	return 1.0 + rolled(merc, "rare_find") / 100.0 + base(merc, "rare_find", ["trinket", "lantern"])

## Fraction of trip time saved ("Hasty" rolls).
static func speed(merc: Dictionary) -> float:
	return minf(0.3, rolled(merc, "speed") / 100.0)

static func kit_rating(merc: Dictionary) -> int:
	var keys: Array = []
	var tired: Array = []
	for item in worn(merc):
		keys.append(str(item["key"]))
		if worn_out(item):
			tired.append(str(item["key"]))
	return Catalog.kit_rating(keys, tired)

## Wear every piece a mercenary wears by `amount`. Returns names of pieces that just wore out.
static func wear(merc: Dictionary, amount: int) -> Array[String]:
	var broke: Array[String] = []
	for item in worn(merc):
		if max_durability(item) <= 0:
			continue
		var before: int = durability(item)
		item["dur"] = maxi(0, before - amount)
		if before > 0 and int(item["dur"]) <= 0:
			broke.append(item_name(item))
	return broke

## Buffs of the food or potion in a slot (empty if none).
static func buffs(merc: Dictionary, slot: String) -> Dictionary:
	var item: Dictionary = in_slot(merc, slot)
	return (def(str(item.get("key", ""))).get("buffs", {}) as Dictionary) if not item.is_empty() else {}

# --- Repairs ----------------------------------------------------------------------------

## What it costs to bring a piece back to full: about 35% of its recipe for a full repair
## (less if only part-worn), always at least one timber of its tier. Found-only pieces, and
## parts no market sells, are paid in gold.
static func repair_cost(item: Dictionary, stocked: Array) -> Dictionary:
	var top: int = max_durability(item)
	var missing: int = top - durability(item)
	if top <= 0 or missing <= 0:
		return {}
	var frac: float = float(missing) / float(top)
	var d: Dictionary = def(str(item.get("key", "")))
	var cost: Dictionary = {}
	var recipe: Variant = d.get("recipe")
	if not (recipe is Dictionary):
		cost["gold"] = maxi(1, int(ceil(float(value(item)) * 0.15 * frac)))
		return cost
	for part in recipe:
		var n: int = int(round(float(recipe[part]) * frac * REPAIR_SHARE))
		if n <= 0:
			continue
		if stocked.has(part):
			cost[part] = int(cost.get(part, 0)) + n
		else:
			cost["gold"] = int(cost.get("gold", 0)) + int(ceil(float(n) * Catalog.value_of(str(part)) * 1.25))
	var handle: String = str(HANDLE.get(clampi(int(d.get("tier", 1)), 1, 5), "timber"))
	if stocked.has(handle):
		cost[handle] = maxi(1, int(cost.get(handle, 0)))
	return cost

# --- Text -----------------------------------------------------------------------------------

const STAT_TEXT := {"damage": "dmg", "attack_speed": "speed", "crit_chance": "crit", "armour": "armour", "block": "block",
	"logging": "logging", "mining": "mining", "foraging": "foraging", "fishing": "fishing", "farming": "farming",
	"carry": "carrying", "rare_find": "rare finds", "xp": "experience", "yield": "haul", "crit_damage": "crit damage",
	"injury_resist": "fewer injuries", "health": "health"}

## One line about a catalog item's base stats, for cards.
static func summary(key: String) -> String:
	var d: Dictionary = def(key)
	var parts: Array[String] = []
	match str(d.get("category", "")):
		"tool":
			parts.append("%s +%d" % [str(d.get("trade", "")).capitalize(), int(d["stats"].get(str(d.get("trade", "")), 0))])
		"weapon":
			parts.append("%d dmg" % int(d["stats"].get("damage", 0)))
			parts.append("%.2f× speed" % float(d["stats"].get("attack_speed", 1.0)))
			parts.append("%d%% crit" % int(round(float(d["stats"].get("crit_chance", 0.0)) * 100.0)))
		"armour", "shield":
			parts.append("%d armour" % int(d["stats"].get("armour", 0)))
			if d.has("weight"):
				parts.append(str(d["weight"]))
		"food", "potion":
			for b in d.get("buffs", {}):
				parts.append(str(Catalog.data()["buffs"].get(b, b + " {}")).replace("{:+}", "%+d" % int(d["buffs"][b])).replace("{}", str(int(d["buffs"][b]))))
		_:
			for s in d.get("stats", {}):
				parts.append("+%d%% %s" % [int(d["stats"][s]), str(STAT_TEXT.get(s, s))])
	if parts.is_empty():
		return "T%d  ·  %s" % [int(d.get("tier", 1)), str(d.get("note", "Crafting material"))]
	return "T%d  ·  %s" % [int(d.get("tier", 1)), ", ".join(parts)]

## Rolled stats as text: "+4% haul, +2% rare finds".
static func rolls_text(item: Dictionary) -> String:
	var parts: Array[String] = []
	var rolls: Dictionary = item.get("rolls", {})
	for stat in rolls:
		var a: Dictionary = Catalog.data()["affixes"].get(stat, {})
		parts.append(str(a.get("text", stat + " {}")).replace("{}", str(int(rolls[stat]))))
	return ", ".join(parts)

## Everything about one piece, for tooltips.
static func describe(item: Dictionary) -> String:
	if item.is_empty():
		return ""
	var key: String = str(item.get("key", ""))
	var lines: Array[String] = [full_name(item), summary(key)]
	var r: String = rolls_text(item)
	if r != "":
		lines.append(r)
	if max_durability(item) > 0:
		lines.append("Durability %d/%d%s" % [durability(item), max_durability(item), "  (worn out: half effect until repaired)" if worn_out(item) else ""])
	return "\n".join(lines)
