extends RefCounted
class_name Heroes
## Heroes: the guild's champions. They are the only ones who wear weapons and armour, and they
## are who goes into the crypts — led by the player (the crawl, scripts/crawl.gd) or alone under
## standing orders. A hero is stored like a mercenary (skills, traits, equipment, health), with
## "hero": true and a "class", in the company's `heroes` list; hero slots are separate from
## expedition slots, so a crew and a hero can be out at the same time.

## What each class adds to the fighter numbers, how much it gets from guarding, how often
## monsters go for it, and its skill.
const CLASSES := {
	"knight": {
		"name": "Knight", "hp": 30.0, "armour_mult": 1.25, "block": 0.10, "parry": 0.0, "crit": 0.0,
		"crit_damage": 0.0, "dodge": 0.0, "speed": 0.0, "guard_take": 0.3, "aggro": 1.6,
		"skill": "bash", "skill_name": "Shield Bash",
		"skill_text": "A lighter blow that stuns the foe for a turn.",
		"blurb": "Holds the line. More health, armour and block count for more, and Guard turns most of a blow.",
		"wants": "armour, block, health",
	},
	"rogue": {
		"name": "Rogue", "hp": -10.0, "armour_mult": 1.0, "block": 0.0, "parry": 0.0, "crit": 0.08,
		"crit_damage": 0.3, "dodge": 0.08, "speed": 0.12, "guard_take": 0.55, "aggro": 0.8,
		"skill": "backstab", "skill_name": "Backstab",
		"skill_text": "A heavy blow with twice the chance to crit.",
		"blurb": "Strikes fast and hard. Crit, dodge and armour piercing count for more; monsters go for knights first.",
		"wants": "crit, crit damage, dodge, armour piercing",
	},
}
const CLASS_ORDER := ["knight", "rogue"]
## A hero's first weapon.
const STARTER := {"knight": "rusted_sword", "rogue": "iron_dagger"}
## Bare-handed, a hero still fights (badly).
const FISTS := {"damage": 4.0, "speed": 1.0, "crit": 0.03, "crit_damage": 1.5}
## Upkeep: a hero's wage for each crypt run, by Combat level.
const WAGE_BASE := 6
const WAGE_PER_LEVEL := 1
## Hiring a hero from the board, and what a new hero slot costs (the Nth slot).
const HIRE_COST := 90
const SLOT_COSTS := [0, 1800, 6000, 15000]
const MAX_SLOTS := 4

static func is_hero(merc: Dictionary) -> bool:
	return bool(merc.get("hero", false))

static func cls(merc: Dictionary) -> String:
	var c: String = str(merc.get("class", "knight"))
	return c if CLASSES.has(c) else "knight"

static func class_def(merc: Dictionary) -> Dictionary:
	return CLASSES[cls(merc)]

static func class_name_of(merc: Dictionary) -> String:
	return str(class_def(merc)["name"])

## Categories only heroes may wear. Weapons that hunt (bows, spears, crossbows) are also a
## hunter's tool, so workers may hold those.
static func hero_only(key: String) -> bool:
	match Gear.category(key):
		"armour", "shield":
			return true
		"weapon":
			return float((Gear.def(key).get("stats", {}) as Dictionary).get("hunt", 0)) <= 0.0
	return false

## A new hero record.
static func make(id: String, name: String, hero_class: String) -> Dictionary:
	var h: Dictionary = {
		"id": id, "name": name, "hero": true, "class": hero_class if CLASSES.has(hero_class) else "knight",
		"skills": {}, "traits": [], "equipment": Gear.empty_equipment(), "health": 100, "mission_id": "",
		"wage": WAGE_BASE, "share": 0.0, "contract": "Balanced", "xp": 0, "gear": 0,
	}
	TradeSkills.ensure(h)
	return h

static func wage(hero: Dictionary) -> int:
	return WAGE_BASE + WAGE_PER_LEVEL * (TradeSkills.level_of(hero, "combat") - 1)

static func max_hp(hero: Dictionary) -> float:
	return 100.0 + float(class_def(hero)["hp"]) + Gear.rolled(hero, "health")

## A hero's fighting numbers: the mercenary fighter numbers (dungeons.gd) shaped by class.
static func fighter(hero: Dictionary) -> Dictionary:
	var f: Dictionary = Dungeons.fighter(hero)
	var c: Dictionary = class_def(hero)
	if bool(f["porter"]):
		# No weapon: fists.
		var level: int = TradeSkills.level_of(hero, "combat")
		f["porter"] = false
		f["damage"] = float(FISTS["damage"]) * (1.0 + Dungeons.LEVEL_DAMAGE * float(level - 1))
		f["speed"] = float(FISTS["speed"])
		f["crit"] = float(FISTS["crit"])
		f["crit_damage"] = float(FISTS["crit_damage"])
	var top: float = max_hp(hero)
	f["max_hp"] = top
	f["hp"] = minf(top, float(int(hero.get("health", 100))) / 100.0 * top)
	f["armour"] = float(f["armour"]) * float(c["armour_mult"])
	f["block"] = minf(0.5, float(f["block"]) + float(c["block"]))
	f["parry"] = minf(0.35, float(f["parry"]) + float(c["parry"]))
	f["dodge"] = minf(0.45, float(f["dodge"]) + float(c["dodge"]))
	f["crit"] = minf(0.75, float(f["crit"]) + float(c["crit"]))
	f["crit_damage"] = float(f["crit_damage"]) + float(c["crit_damage"])
	f["speed"] = float(f["speed"]) + float(c["speed"])
	var weapon: Dictionary = Gear.in_slot(hero, "main_hand")
	var ws: Dictionary = Gear.def(str(weapon.get("key", ""))).get("stats", {})
	f["stun"] = float(ws.get("stun", 0.0)) + Gear.rolled(hero, "stun") / 100.0
	f["cls"] = cls(hero)
	f["hero"] = true
	return f

## Health (0-100, as stored on the record) from a fighter's hit points.
static func health_from(hero: Dictionary, hp: float) -> int:
	return clampi(int(round(hp / max_hp(hero) * 100.0)), 0, 100)
