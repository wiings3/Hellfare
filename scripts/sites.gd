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
##   needs        optional: a company upgrade that must be built first (farm buildings)
##   tier         the site's tier; blueprints of that tier can turn up there
## Harlow Mines (the Gatepit) was the first mining expedition (the MVP). It is now an ordinary tier-1
## site; its old scouting and rotating-deposit rules in game_state.gd only finish trips
## and saves made before the change.

const LEVEL_YIELD_BONUS := 0.03
const GUARD_PROTECTION := 0.25
const MAX_GUARD_PROTECTION := 0.6
## Guards are retired (fighting is for heroes): every crew now meets a site's threat with this
## much taken off its injury and death chances — about what a sensibly guarded crew had.
const BASE_PROTECTION := 0.4

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
		"id": "mossward_copse", "name": "Cinderwood", "trade": "logging", "tier": 1, "level": 1,
		"tagline": "Dead trees just past the Maw that still burn inside. The ash never stops falling.",
		"duration": 90, "supplies": 2,
		"yields": {"timber": [3, 5]},
		"rare": {"good": "amber", "chance": 0.05, "count": 1, "note": "a lump of cinder amber in a burnt-out stump"},
		"threat": {"name": "Falling embers", "danger": 0, "note": "Nothing down here hunts this close to the Maw"},
		"injury": 0.04, "death": 0.0, "xp": 30,
		"art": "res://assets/ui/art/forest_copse.png",
	},
	{
		"id": "old_oakwood", "name": "Weepingwood", "trade": "logging", "tier": 2, "level": 8,
		"tagline": "Black trees that weep sap like blood. Weepwood for better handles, and hounds.",
		"duration": 240, "supplies": 20,
		"yields": {"oak": [3, 4]},
		"side": {"herbs": [0, 2]},
		"rare": {"good": "relic", "chance": 0.015, "count": 1, "note": "a saint's relic in a hollow trunk"},
		"rare2": {"good": "wolf_pelt", "chance": 0.25, "count": 1, "note": "a hound pelt from a pack that came too close"},
		"threat": {"name": "Hound packs", "danger": 2, "note": "They hunt the edges of the clearings, and not for food"},
		"injury": 0.032, "death": 0.0024, "xp": 55,
		"art": "res://assets/ui/art/forest_oakwood.png",
	},
	{
		"id": "harlow", "name": "The Gatepit", "trade": "mining", "tier": 1, "level": 1,
		"tagline": "Old copper workings just inside the Maw. Hard work, little danger.",
		"duration": 90, "supplies": 4,
		"yields": {"copper": [0, 2]},
		"side": {"coal": [0, 1], "iron": [0, 1]},
		"threat": {"name": "Loose rock", "danger": 0, "note": "Rockfalls in the old shafts bruise more than they kill"},
		"injury": 0.06, "death": 0.0, "xp": 30, "tool": 0.5,
		"art": "res://assets/ui/art/harlow_site.png",
	},
	{
		"id": "deepdelve", "name": "The Sulphur Deeps", "trade": "mining", "tier": 2, "level": 8,
		"tagline": "Yellow-lit galleries under the Fens. Iron and silver, and things that crawl.",
		"duration": 240, "supplies": 22,
		"yields": {"iron": [1, 2], "copper": [0, 1]},
		"side": {"silver": [0, 1], "spider_silk": [0, 1]},
		"rare": {"good": "crystal", "chance": 0.04, "count": 1, "note": "a knot of soulglass in a collapsed gallery"},
		"rare2": {"good": "garnet", "chance": 0.06, "count": 1, "note": "a seam of bloodgarnets in the gallery wall"},
		"threat": {"name": "Cave crawlers", "danger": 2, "note": "They nest in the warm galleries"},
		"injury": 0.036, "death": 0.0028, "xp": 55, "tool": 0.5,
		"art": "res://assets/ui/art/mine_deepdelve.png",
	},
	{
		"id": "mossward_meadows", "name": "Ashmeadow", "trade": "foraging", "tier": 1, "level": 1,
		"tagline": "Grey meadows in the lee of the Maw. Ashleaf and cinderberries for the picking.",
		"duration": 90, "supplies": 2,
		"yields": {"herbs": [2, 4], "berries": [1, 3]},
		"threat": {"name": "Ash flies and thorns", "danger": 0, "note": "Nothing worse than stings"},
		"injury": 0.03, "death": 0.0, "xp": 30, "tool": 0.5,
		"art": "res://assets/ui/art/site_mossward_meadows.png",
	},
	{
		"id": "fenmire", "name": "The Bloodfen", "trade": "foraging", "tier": 2, "level": 8,
		"tagline": "A red marsh of bloodcaps and gravecaps. Mind the bog adders.",
		"duration": 240, "supplies": 20,
		"yields": {"bloodcap": [1, 2], "mushrooms": [1, 2]},
		"side": {"herbs": [0, 2]},
		"threat": {"name": "Bog adders", "danger": 2, "note": "They lie still in the warm reeds"},
		"injury": 0.032, "death": 0.002, "xp": 55, "tool": 0.5,
		"art": "res://assets/ui/art/site_fenmire.png",
	},
	{
		"id": "sunreach", "name": "Ember Slopes", "trade": "foraging", "tier": 3, "level": 18,
		"tagline": "Burning slopes where nightshade and emberbloom grow between the vents.",
		"duration": 420, "supplies": 50,
		"yields": {"nightshade": [1, 3], "sunpetal": [1, 3]},
		"threat": {"name": "Vents and rockfalls", "danger": 2, "note": "The slopes shift when the fires do"},
		"injury": 0.0467, "death": 0.0047, "xp": 80, "tool": 0.5,
		"art": "res://assets/ui/art/site_sunreach.png",
	},
	{
		"id": "frostvale", "name": "Lament's Edge", "trade": "foraging", "tier": 4, "level": 30,
		"tagline": "The rim of the frozen layer, where lament lilies flower in ice that holds the screaming.",
		"duration": 600, "supplies": 110,
		"yields": {"frostbloom": [2, 4]},
		"side": {"bloodcap": [0, 2]},
		"threat": {"name": "Frost hounds", "danger": 3, "note": "They hunt the ice in packs"},
		"injury": 0.06, "death": 0.0075, "xp": 110, "tool": 0.5,
		"art": "res://assets/ui/art/site_frostvale.png",
	},
	{
		"id": "millbrook_pond", "name": "The Cinder Pool", "trade": "fishing", "tier": 1, "level": 1,
		"tagline": "A warm grey pool just past the Maw. Ash perch for the pan, and quiet.",
		"duration": 90, "supplies": 2,
		"yields": {"perch": [3, 5]},
		"threat": {"name": "Nothing but ash flies", "danger": 0, "note": "The safest work below"},
		"injury": 0.02, "death": 0.0, "xp": 30, "tool": 0.5,
		"art": "res://assets/ui/art/site_millbrook_pond.png",
	},
	{
		"id": "silverrun", "name": "The Styx Shallows", "trade": "fishing", "tier": 2, "level": 8,
		"tagline": "The shallow end of a black river, full of styx trout and bone eels.",
		"duration": 240, "supplies": 20,
		"yields": {"trout": [2, 3]},
		"side": {"eel": [0, 2]},
		"threat": {"name": "Strong currents", "danger": 1, "note": "The river pulls at anyone who wades too far"},
		"injury": 0.02, "death": 0.0012, "xp": 55, "tool": 0.5,
		"art": "res://assets/ui/art/site_silverrun.png",
	},
	{
		"id": "glasswater", "name": "The Lake of Glass", "trade": "fishing", "tier": 3, "level": 18,
		"tagline": "A lake so still it looks like glass. Great pike below, and tear pearls in the shallows.",
		"duration": 420, "supplies": 50,
		"yields": {"pike": [2, 4]},
		"rare": {"good": "pearl", "chance": 0.08, "count": 1, "note": "a tear pearl in a lakebed mussel"},
		"threat": {"name": "Boiling squalls", "danger": 1, "note": "The lake boils without warning"},
		"injury": 0.028, "death": 0.0023, "xp": 80, "tool": 0.5,
		"art": "res://assets/ui/art/site_glasswater.png",
	},
	{
		"id": "greywater_coast", "name": "The Shore of Tears", "trade": "fishing", "tier": 4, "level": 30,
		"tagline": "A cold shore that weeps salt: weeping cod, shore crab and storms.",
		"duration": 600, "supplies": 110,
		"yields": {"cod": [2, 4]},
		"side": {"crab": [0, 2]},
		"rare": {"good": "pearl", "chance": 0.1, "count": 1, "note": "a tear pearl in an oyster bed"},
		"threat": {"name": "Storms and ice", "danger": 2, "note": "The shore takes a crew now and then"},
		"injury": 0.045, "death": 0.006, "xp": 110, "tool": 0.5,
		"art": "res://assets/ui/art/site_greywater_coast.png",
	},
	{
		"id": "drowned_deep", "name": "The Drowned Deep", "trade": "fishing", "tier": 5, "level": 45,
		"tagline": "Black water at the bottom of everything. Abyssal eels and voidpearls, for the brave.",
		"duration": 900, "supplies": 250,
		"yields": {"abyssal_eel": [2, 4]},
		"rare": {"good": "voidpearl", "chance": 0.05, "count": 1, "note": "a voidpearl from something's belly"},
		"threat": {"name": "Things in the deep", "danger": 3, "note": "Not everything down there is a fish"},
		"injury": 0.06, "death": 0.01, "xp": 150, "tool": 0.5,
		"art": "res://assets/ui/art/site_drowned_deep.png",
	},
	{
		"id": "hollow_fields", "name": "Hollow Fields", "trade": "hunting", "tier": 1, "level": 1,
		"tagline": "Grey fields of thin grass, thick with ashhares and carrion birds. A bow helps.",
		"duration": 90, "supplies": 3,
		"yields": {"game_meat": [1, 3], "rabbit_hide": [1, 2]},
		"side": {"feathers": [0, 2], "bone": [0, 1]},
		"threat": {"name": "Nothing that bites back", "danger": 0, "note": "Ashhares rarely fight"},
		"injury": 0.05, "death": 0.0, "xp": 30, "tool": 0.5,
		"art": "res://assets/ui/art/site_hollow_fields.png",
	},
	{
		"id": "greyfang_hills", "name": "Houndfang Hills", "trade": "hunting", "tier": 2, "level": 8,
		"tagline": "Red hills where hellboar root and hounds follow the herds.",
		"duration": 240, "supplies": 22,
		"yields": {"boar_meat": [1, 2], "wolf_pelt": [0, 2]},
		"side": {"fang": [0, 1], "bone": [0, 1]},
		"threat": {"name": "Hounds and hellboar", "danger": 2, "note": "A cornered hellboar is as dangerous as a hound"},
		"injury": 0.04, "death": 0.0032, "xp": 55, "tool": 0.5,
		"art": "res://assets/ui/art/site_greyfang_hills.png",
	},
	{
		"id": "elkmoor", "name": "Gorehorn Moor", "trade": "hunting", "tier": 3, "level": 18,
		"tagline": "A burning moor where gorehorns run. Their horns fetch a price.",
		"duration": 420, "supplies": 50,
		"yields": {"venison": [1, 3], "elk_hide": [1, 2]},
		"rare": {"good": "antler", "chance": 0.25, "count": 1, "note": "a fine pair of gorehorns"},
		"threat": {"name": "Charging gorehorns", "danger": 2, "note": "A gorehorn in rut fears nothing"},
		"injury": 0.056, "death": 0.0056, "xp": 80, "tool": 0.5,
		"art": "res://assets/ui/art/site_elkmoor.png",
	},
	{
		"id": "bleakridge", "name": "Bleakridge", "trade": "hunting", "tier": 4, "level": 30,
		"tagline": "A frozen ridge where the pitbears den.",
		"duration": 600, "supplies": 110,
		"yields": {"bear_meat": [1, 2], "direbear_pelt": [1, 2]},
		"threat": {"name": "Pitbears", "danger": 4, "note": "Twice the size of any bear above"},
		"injury": 0.075, "death": 0.01, "xp": 110, "tool": 0.5,
		"art": "res://assets/ui/art/site_bleakridge.png",
	},
	{
		"id": "home_fields", "name": "Home Fields", "trade": "farming", "tier": 1, "level": 1,
		"tagline": "The guild's own fields behind the hall in Last Lantern: wheat, cabbage and flax.",
		"duration": 90, "supplies": 2,
		"yields": {"wheat": [2, 4], "cabbage": [1, 2], "flax": [1, 3]},
		"threat": {"name": "Crows", "danger": 0, "note": "Nothing here will hurt anyone"},
		"injury": 0.01, "death": 0.0, "xp": 30, "tool": 0.5,
		"art": "res://assets/ui/art/site_home_fields.png",
	},
	{
		"id": "tilled_acres", "name": "Tilled Acres", "trade": "farming", "tier": 2, "level": 8,
		"tagline": "Freshly broken ground for barley and potatoes. Needs the field plots first.",
		"duration": 240, "supplies": 15,
		"yields": {"barley": [2, 4], "potato": [2, 4]},
		"needs": "field_plots",
		"threat": {"name": "Hard labour", "danger": 0, "note": "Backs ache, nobody dies"},
		"injury": 0.012, "death": 0, "xp": 55, "tool": 0.5,
		"art": "res://assets/ui/art/site_tilled_acres.png",
	},
	{
		"id": "beehives", "name": "Beehives", "trade": "farming", "tier": 2, "level": 8,
		"tagline": "The guild's apiary: honey for cakes, ale and tea. Needs the apiary first.",
		"duration": 240, "supplies": 15,
		"yields": {"honey": [2, 3]},
		"needs": "apiary",
		"threat": {"name": "Angry bees", "danger": 1, "note": "Smoke them first"},
		"injury": 0.016, "death": 0, "xp": 55, "tool": 0.5,
		"art": "res://assets/ui/art/site_beehives.png",
	},
	{
		"id": "glasshouse", "name": "Glasshouse", "trade": "farming", "tier": 3, "level": 18,
		"tagline": "A warm glasshouse for emberpeppers, which grow nowhere else. Needs building first.",
		"duration": 420, "supplies": 40,
		"yields": {"emberpepper": [3, 4]},
		"needs": "glasshouse_build",
		"threat": {"name": "Scalding steam", "danger": 0, "note": "Mind the stove"},
		"injury": 0.014, "death": 0, "xp": 80, "tool": 0.5,
		"art": "res://assets/ui/art/site_glasshouse.png",
	},
]

## Trades shown on the expedition board, in order, with those not built yet.
const BOARD := [
	{"trade": "logging", "name": "Logging", "ready": true},
	{"trade": "mining", "name": "Mining", "ready": true},
	{"trade": "foraging", "name": "Foraging", "ready": true},
	{"trade": "fishing", "name": "Fishing", "ready": true},
	{"trade": "hunting", "name": "Hunting", "ready": true},
	{"trade": "farming", "name": "Farming", "ready": true},
	{"trade": "dungeon", "name": "Crypts", "ready": true},
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
		var trips: float = float(order["hours"]) * 3600.0 / maxf(1.0, long_order_trip(site))
		for key in ["yield", "risk", "xp", "cost"]:
			order[key] = float(order[key]) * trips
		# Below tier 1 the per-trip risks were cut with the trip lengths (the same risk per hour
		# of work); a long order still counts its hours at the old pace, so its risk does too.
		if int(site.get("tier", 1)) >= 2:
			order["risk"] = float(order["risk"]) * long_order_trip(site) / maxf(1.0, float(site.get("duration", 300)))
		order["duration"] = trips
	return order

## Trips are short so the player has something coming back every minute or two (tier 1 about a
## minute and a half). Fixed-length orders (Overnight, Full Day) still count trips at the old,
## slower pace, so a guild left alone earns what it did before: being there pays, being away
## doesn't break the economy.
const LONG_ORDER_TRIP := {1: 300, 2: 600, 3: 900, 4: 1200, 5: 1800}

static func long_order_trip(site: Dictionary) -> float:
	return float(LONG_ORDER_TRIP.get(int(site.get("tier", 1)), site.get("duration", 300)))

## How long a trip under these orders (from order_for) lasts, in seconds.
static func trip_seconds(site: Dictionary, order: Dictionary) -> float:
	if order.has("hours"):
		return float(order["hours"]) * 3600.0
	return float(site.get("duration", 60)) * float(order["duration"])

## Expected units of one good from one worker (before orders), given their level and tool.
static func worker_yield(span: Array, level: int, tool_bonus: float) -> float:
	var avg: float = (float(span[0]) + float(span[1])) / 2.0
	return avg * (1.0 + LEVEL_YIELD_BONUS * float(level - 1)) + tool_bonus

## Fraction of risk removed by guards and the crew's combat training.
static func protection(guards: int, best_combat: int) -> float:
	return minf(MAX_GUARD_PROTECTION, float(guards) * GUARD_PROTECTION + float(maxi(0, best_combat - 1)) * 0.01)
