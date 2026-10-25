extends RefCounted
class_name TradeSites
## Data-driven expedition sites. Adding a forest, quarry or dungeon is a new entry here,
## not new code: the forecast, dispatch and resolution in game_state.gd read these fields.
##
## Fields:
##   trade        which skill the work uses and trains
##   level        the crew's best level in that trade must reach this
##   duration     seconds under Balanced orders
##   supplies     gold paid up front on top of wages
##   yields       good -> [low, high] units per worker before skill and tools
##   side         optional extra goods, good -> [low, high] per worker
##   rare         optional jackpot, {"good", "chance" per expedition, "count", "note"}
##   rare2        optional second jackpot, same shape
##   threat       {"name", "danger" 0-4, "note"}
##   injury/death base chance per worker under Balanced orders
##   xp           trade experience per worker
##   tool         optional: how much of a tool's bonus counts per trip (default 1)
## Harlow Mines was the first mining expedition (the MVP). It is now an ordinary tier-1
## site; its old scouting and rotating-deposit rules in game_state.gd only finish trips
## and saves made before the change.

const LEVEL_YIELD_BONUS := 0.03
const GUARD_PROTECTION := 0.25
const MAX_GUARD_PROTECTION := 0.6

## yield, risk, duration and xp multiply the site's numbers; cost multiplies wages and
## supplies. Long Shift is one long trip for players who check in now and then: six times
## as long, 80% of the hourly haul, four times the wages and supplies.
## Orders with "hours" last that long at every site, for players who look in once or twice
## a day: their numbers are per Balanced trip that fits in the time (see order_for).
const ORDERS := {
	"Cautious": {"yield": 0.85, "risk": 0.5, "duration": 1.1, "xp": 0.9, "cost": 1.0},
	"Balanced": {"yield": 1.0, "risk": 1.0, "duration": 1.0, "xp": 1.0, "cost": 1.0},
	"Deep Push": {"yield": 1.25, "risk": 1.6, "duration": 1.0, "xp": 1.15, "cost": 1.0},
	"Long Shift": {"yield": 4.8, "risk": 3.0, "duration": 6.0, "xp": 4.8, "cost": 4.0},
	"Overnight": {"hours": 8, "yield": 0.5, "risk": 0.2, "xp": 0.5, "cost": 0.25},
	"Full Day": {"hours": 20, "yield": 0.55, "risk": 0.15, "xp": 0.42, "cost": 0.2},
}
## A long trip can't make injury or death certain.
const MAX_INJURY := 0.6
const MAX_DEATH := 0.35

const SITES := [
	{
		"id": "mossward_copse", "name": "Mossward Copse", "trade": "logging", "tier": 1, "level": 1,
		"tagline": "Young birch and pine a short walk from town. Safe, honest work.",
		"duration": 300, "supplies": 2,
		"yields": {"timber": [3, 5]},
		"rare": {"good": "amber", "chance": 0.05, "count": 1, "note": "a lump of amber in an old stump"},
		"threat": {"name": "Nothing worse than splinters", "danger": 0, "note": "No predators this close to town"},
		"injury": 0.04, "death": 0.0, "xp": 30,
		"art": "res://assets/ui/art/forest_copse.png",
	},
	{
		"id": "old_oakwood", "name": "Old Oakwood", "trade": "logging", "tier": 2, "level": 8,
		"tagline": "Ancient oaks a day's walk out. Oak for better handles, and wolves.",
		"duration": 600, "supplies": 20,
		"yields": {"oak": [3, 4]},
		"side": {"herbs": [0, 2]},
		"rare": {"good": "relic", "chance": 0.015, "count": 1, "note": "a carved idol in a hollow oak"},
		"rare2": {"good": "wolf_pelt", "chance": 0.25, "count": 1, "note": "a wolf pelt from a pack that came too close"},
		"threat": {"name": "Grey wolf packs", "danger": 2, "note": "They hunt the edges of the clearings"},
		"injury": 0.08, "death": 0.006, "xp": 55,
		"art": "res://assets/ui/art/forest_oakwood.png",
	},
	{
		"id": "harlow", "name": "Harlow Mines", "trade": "mining", "tier": 1, "level": 1,
		"tagline": "Old copper workings in the foothills. Hard work, little danger.",
		"duration": 300, "supplies": 4,
		"yields": {"copper": [0, 2]},
		"side": {"coal": [0, 1], "iron": [0, 1]},
		"threat": {"name": "Loose rock", "danger": 0, "note": "Rockfalls in the old shafts bruise more than they kill"},
		"injury": 0.06, "death": 0.0, "xp": 30, "tool": 0.5,
		"art": "res://assets/ui/art/harlow_site.png",
	},
	{
		"id": "deepdelve", "name": "Deepdelve", "trade": "mining", "tier": 2, "level": 8,
		"tagline": "Old dwarven galleries high in the range. Iron and silver, and things that crawl.",
		"duration": 600, "supplies": 22,
		"yields": {"iron": [1, 2], "copper": [0, 1]},
		"side": {"silver": [0, 1], "spider_silk": [0, 1]},
		"rare": {"good": "crystal", "chance": 0.04, "count": 1, "note": "a geode in a collapsed gallery"},
		"rare2": {"good": "garnet", "chance": 0.06, "count": 1, "note": "a seam of garnets in the gallery wall"},
		"threat": {"name": "Cave crawlers", "danger": 2, "note": "They nest in the old galleries"},
		"injury": 0.09, "death": 0.007, "xp": 55, "tool": 0.5,
		"art": "res://assets/ui/art/mine_deepdelve.png",
	},
]

## Trades shown on the expedition board, in order, with those not built yet.
const BOARD := [
	{"trade": "logging", "name": "Logging", "ready": true},
	{"trade": "mining", "name": "Mining", "ready": true},
	{"trade": "foraging", "name": "Foraging", "ready": false},
	{"trade": "dungeon", "name": "Dungeon delving", "ready": false},
]

## Sites renamed or merged since, mapped to the site that replaced them (old saves).
const ALIASES := {"greyvein_quarry": "harlow"}

static func by_id(id: String) -> Dictionary:
	id = str(ALIASES.get(id, id))
	for site in SITES:
		if str(site["id"]) == id:
			return site
	return {}

static func for_trade(trade: String) -> Array:
	var result: Array = []
	for site in SITES:
		if str(site["trade"]) == trade:
			result.append(site)
	return result

static func has_orders(tactic: String) -> bool:
	return ORDERS.has(tactic)

static func orders(tactic: String) -> Dictionary:
	return ORDERS.get(tactic, ORDERS["Balanced"])

## The multipliers an order applies at one site. Fixed-length orders count how many
## Balanced trips fit in their hours and scale per trip.
static func order_for(site: Dictionary, tactic: String) -> Dictionary:
	var order: Dictionary = orders(tactic).duplicate()
	if order.has("hours"):
		var trips: float = float(order["hours"]) * 3600.0 / maxf(1.0, float(site.get("duration", 300)))
		for key in ["yield", "risk", "xp", "cost"]:
			order[key] = float(order[key]) * trips
		order["duration"] = trips
	return order

## Expected units of one good from one worker (before orders), given their level and tool.
static func worker_yield(span: Array, level: int, tool_bonus: float) -> float:
	var avg: float = (float(span[0]) + float(span[1])) / 2.0
	return avg * (1.0 + LEVEL_YIELD_BONUS * float(level - 1)) + tool_bonus

## Fraction of risk removed by guards and the crew's combat training.
static func protection(guards: int, best_combat: int) -> float:
	return minf(MAX_GUARD_PROTECTION, float(guards) * GUARD_PROTECTION + float(maxi(0, best_combat - 1)) * 0.01)
