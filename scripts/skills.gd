extends RefCounted
class_name TradeSkills
## Per-mercenary trade skills, RuneScape-style: experience per trade, levels 1 to 50.
## Stored on each mercenary as merc["skills"] = {"logging": xp, "mining": xp, ...}.

const TRADES := ["logging", "mining", "foraging", "combat"]
const NAMES := {"logging": "Logging", "mining": "Mining", "foraging": "Foraging", "combat": "Combat"}
const MAX_LEVEL := 50
## Which trade an old hiring role specialised in (only used to migrate older saves).
const ROLE_TRADE := {"Woodcutter": "logging", "Miner": "mining", "Forager": "foraging", "Guard": "combat", "Scout": "foraging"}

## Total experience needed to reach a level (level 1 = 0).
static func xp_for_level(level: int) -> int:
	if level <= 1:
		return 0
	return int(round(12.0 * pow(float(level - 1), 1.9)))

static func level_for_xp(xp: int) -> int:
	var level: int = 1
	while level < MAX_LEVEL and xp >= xp_for_level(level + 1):
		level += 1
	return level

static func xp_of(merc: Dictionary, trade: String) -> int:
	return int((merc.get("skills", {}) as Dictionary).get(trade, 0))

static func level_of(merc: Dictionary, trade: String) -> int:
	return level_for_xp(xp_of(merc, trade))

## Progress from the current level to the next, 0.0 to 1.0.
static func progress(merc: Dictionary, trade: String) -> float:
	var xp: int = xp_of(merc, trade)
	var level: int = level_for_xp(xp)
	if level >= MAX_LEVEL:
		return 1.0
	var lo: int = xp_for_level(level)
	var hi: int = xp_for_level(level + 1)
	return clampf(float(xp - lo) / float(maxi(1, hi - lo)), 0.0, 1.0)

## Skills for an older save's archetype mercenary: their old speciality starts above level 1.
static func starting_skills(role: String, skill: int) -> Dictionary:
	var result: Dictionary = {}
	for trade in TRADES:
		result[trade] = 0
	var main: String = str(ROLE_TRADE.get(role, ""))
	if not main.is_empty():
		var level: int = clampi(1 + int(skill / 4), 1, 20)
		result[main] = xp_for_level(level)
	return result

## Add experience (traits such as Woodsman or Prodigy add more); returns levels gained.
static func grant(merc: Dictionary, trade: String, amount: int) -> int:
	var skills: Dictionary = merc.get("skills", {})
	var before: int = level_for_xp(int(skills.get(trade, 0)))
	skills[trade] = int(skills.get(trade, 0)) + maxi(0, int(round(float(amount) * Mercs.xp_mult(merc, trade))))
	merc["skills"] = skills
	return level_for_xp(int(skills[trade])) - before

## Give older saves' mercenaries skills derived from their role, skill and experience.
static func ensure(merc: Dictionary) -> void:
	if merc.has("skills") and typeof(merc["skills"]) == TYPE_DICTIONARY:
		for trade in TRADES:
			if not (merc["skills"] as Dictionary).has(trade):
				merc["skills"][trade] = 0
		return
	var skills: Dictionary = starting_skills(str(merc.get("role", "")), int(merc.get("skill", 10)))
	var main: String = str(ROLE_TRADE.get(str(merc.get("role", "")), ""))
	if not main.is_empty():
		skills[main] = int(skills[main]) + int(merc.get("xp", 0)) * 10
	merc["skills"] = skills
