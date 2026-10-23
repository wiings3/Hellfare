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
##   threat       {"name", "danger" 0-4, "note"}
##   injury/death base chance per worker under Balanced orders
##   xp           trade experience per worker
## Harlow Mines keeps its own rotating-deposit rules (game_state.gd) and is listed with
## "special": "harlow" so the board can link to it.

const LEVEL_YIELD_BONUS := 0.05
const GUARD_PROTECTION := 0.25
const MAX_GUARD_PROTECTION := 0.6

const ORDERS := {
	"Cautious": {"yield": 0.8, "risk": 0.5, "duration": 1.15, "xp": 0.9},
	"Balanced": {"yield": 1.0, "risk": 1.0, "duration": 1.0, "xp": 1.0},
	"Deep Push": {"yield": 1.3, "risk": 1.6, "duration": 0.9, "xp": 1.2},
}

const SITES := [
	{
		"id": "mossward_copse", "name": "Mossward Copse", "trade": "logging", "tier": 1, "level": 1,
		"tagline": "Young birch and pine a short walk from town. Safe, honest work.",
		"duration": 240, "supplies": 4,
		"yields": {"timber": [4, 6]},
		"threat": {"name": "Nothing worse than splinters", "danger": 0, "note": "No predators this close to town"},
		"injury": 0.03, "death": 0.0, "xp": 30,
		"art": "res://assets/ui/art/forest_copse.png",
	},
	{
		"id": "old_oakwood", "name": "Old Oakwood", "trade": "logging", "tier": 2, "level": 8,
		"tagline": "Ancient oaks a day's walk out. Rich timber, and wolves.",
		"duration": 600, "supplies": 12,
		"yields": {"timber": [7, 10]},
		"side": {"herbs": [0, 2]},
		"rare": {"good": "relic", "chance": 0.015, "count": 1, "note": "a carved idol in a hollow oak"},
		"threat": {"name": "Grey wolf packs", "danger": 2, "note": "They hunt the edges of the clearings"},
		"injury": 0.10, "death": 0.015, "xp": 55,
		"art": "res://assets/ui/art/forest_oakwood.png",
	},
	{
		"id": "harlow", "name": "Harlow Mines", "trade": "mining", "tier": 1, "level": 1,
		"tagline": "A rotating copper and iron mine. Scout before you dig.",
		"special": "harlow", "duration": 80, "supplies": 18,
		"yields": {"copper": [5, 9], "iron": [0, 5]},
		"threat": {"name": "Changes every rotation", "danger": 2, "note": ""},
		"injury": 0.0, "death": 0.0, "xp": 40,
		"art": "res://assets/ui/art/harlow_site.png",
	},
]

## Trades shown on the expedition board, in order, with those not built yet.
const BOARD := [
	{"trade": "logging", "name": "Logging", "ready": true},
	{"trade": "mining", "name": "Mining", "ready": true},
	{"trade": "foraging", "name": "Foraging", "ready": false},
	{"trade": "dungeon", "name": "Dungeon delving", "ready": false},
]

static func by_id(id: String) -> Dictionary:
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

static func orders(tactic: String) -> Dictionary:
	return ORDERS.get(tactic, ORDERS["Balanced"])

## Expected units of one good from one worker (before orders), given their level and tool.
static func worker_yield(span: Array, level: int, tool_bonus: int) -> float:
	var avg: float = (float(span[0]) + float(span[1])) / 2.0
	return avg * (1.0 + LEVEL_YIELD_BONUS * float(level - 1)) + float(tool_bonus)

## Fraction of risk removed by guards and the crew's combat training.
static func protection(guards: int, best_combat: int) -> float:
	return minf(MAX_GUARD_PROTECTION, float(guards) * GUARD_PROTECTION + float(maxi(0, best_combat - 1)) * 0.01)
