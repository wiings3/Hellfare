extends RefCounted
class_name MarketModel
## The town market: reference prices, NPC merchant spread, saturation and price history.
##
## Design (see the "Economy, Trades & the Trade Hall" doc):
## - Each good has a reference price: its base price, nudged by a slow six-hour drift
##   and by occasional demand events.
## - NPC merchants buy from players at about 75% of reference and sell at about 130%.
##   Players trading with each other inside that gap both do better than the NPCs.
## - Selling to NPCs saturates them (their buy price falls); buying from them makes the
##   good scarce (their sell price rises). Saturation fades with an 8-hour half-life and
##   can move a price at most 50%, so steady selling never makes honest work unprofitable
##   (the economy simulator found the old 60% / 12-hour limits bankrupting companies).
## - Every NPC trade is recorded, plus an hourly sample, so item cards can show history.
## Everything here is plain data so it can later run on a server unchanged.

const NPC_BUYS_AT := 0.75
const NPC_SELLS_AT := 1.30
const HALF_LIFE_SECONDS := 28800.0
const SATURATION_PULL := 0.5
const DRIFT_PERIOD := 21600
const EVENT_PERIOD := 43200
const HISTORY_LIMIT := 48
const SAMPLE_INTERVAL := 3600

## How many units it takes to move a merchant's price halfway to its limit.
## Cheap bulk goods have deep markets; rare goods move with a single sale.
const DEPTH := {
	"copper": 60.0, "iron": 60.0, "timber": 100.0, "herbs": 80.0,
	"silver": 25.0, "crystal": 8.0, "relic": 3.0, "sovereign": 1.0,
	"oak": 45.0, "coal": 90.0, "wolf_pelt": 30.0, "spider_silk": 25.0, "amber": 30.0, "garnet": 10.0,
	"steel_ingot": 30.0, "silversteel_ingot": 12.0, "healing_draught": 30.0,
}

## Demand events: one good, a price swing and a line of news. Picked per 12-hour period.
const EVENTS := [
	{"good": "iron", "factor": 1.40, "news": "The garrison is re-arming and buying iron."},
	{"good": "timber", "factor": 1.35, "news": "A fire in the lower town: builders want ashwood."},
	{"good": "timber", "factor": 0.75, "news": "A crew came up with a full haul. Ashwood is cheap."},
	{"good": "copper", "factor": 1.30, "news": "The mint is short of copper."},
	{"good": "herbs", "factor": 1.50, "news": "A fever in the slums: healers pay for ashleaf."},
	{"good": "silver", "factor": 0.80, "news": "A silver caravan flooded the market."},
	{"good": "crystal", "factor": 1.35, "news": "The enchanters' guild is buying soulglass."},
	{"good": "copper", "factor": 0.80, "news": "Too much copper in the warehouses this week."},
]
const EVENT_CHANCE := 0.45

var base_prices: Dictionary = {}
## good -> {"value": float units, "t": unix seconds when value was last set}
var saturation: Dictionary = {}
## good -> Array of {"t": int, "p": int} reference price samples, oldest first
var history: Dictionary = {}

## How many units merchants absorb before prices sag, for goods without a set depth:
## cheap bulk goods move in large lots, dear ones in small.
func auto_depth(good: String) -> float:
	return clampf(600.0 / maxf(1.0, float(base_prices.get(good, 10))), 4.0, 120.0)

func _init(bases: Dictionary = {}) -> void:
	base_prices = bases

# --- Saving -------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"saturation": saturation, "history": history}

func load_dict(data: Dictionary) -> void:
	saturation.clear()
	history.clear()
	var sat: Dictionary = data.get("saturation", {})
	for good in sat:
		var entry: Dictionary = sat[good]
		saturation[str(good)] = {"value": float(entry.get("value", 0.0)), "t": int(entry.get("t", 0))}
	var hist: Dictionary = data.get("history", {})
	for good in hist:
		var samples: Array = []
		for s in hist[good]:
			if typeof(s) == TYPE_DICTIONARY:
				samples.append({"t": int(s.get("t", 0)), "p": int(s.get("p", 0))})
		history[str(good)] = samples

func reset() -> void:
	saturation.clear()
	history.clear()

# --- Prices -------------------------------------------------------------------

func _now(now: int) -> int:
	return now if now >= 0 else GameClock.now()

## Slow deterministic drift, -12% .. +12%, changing every six hours.
func drift(good: String, now: int = -1) -> float:
	var period: int = int(_now(now) / DRIFT_PERIOD)
	return float(posmod(good.hash() + period * 17, 25) - 12) / 100.0

## The demand event active in this 12-hour period, or an empty dictionary.
func current_event(now: int = -1) -> Dictionary:
	var period: int = int(_now(now) / EVENT_PERIOD)
	var rng := RandomNumberGenerator.new()
	rng.seed = period * 7919 + 104729
	if rng.randf() >= EVENT_CHANCE:
		return {}
	return EVENTS[rng.randi_range(0, EVENTS.size() - 1)]

func event_ends_in(now: int = -1) -> int:
	return EVENT_PERIOD - _now(now) % EVENT_PERIOD

func event_factor(good: String, now: int = -1) -> float:
	var event: Dictionary = current_event(now)
	if not event.is_empty() and str(event["good"]) == good:
		return float(event["factor"])
	return 1.0

## The good's fair value today, before any merchant spread.
func reference_price(good: String, now: int = -1) -> int:
	var base: float = float(base_prices.get(good, 1))
	return maxi(1, int(round(base * (1.0 + drift(good, now)) * event_factor(good, now))))

## Current saturation in units: positive = merchants flooded, negative = scarce.
func saturation_units(good: String, now: int = -1) -> float:
	var entry: Dictionary = saturation.get(good, {})
	if entry.is_empty():
		return 0.0
	var elapsed: float = maxf(0.0, float(_now(now) - int(entry["t"])))
	return float(entry["value"]) * pow(0.5, elapsed / HALF_LIFE_SECONDS)

## Price multiplier from saturation: below 1 when flooded, above 1 when scarce.
func saturation_factor(good: String, extra_units: float = 0.0, now: int = -1) -> float:
	var s: float = saturation_units(good, now) + extra_units
	var depth: float = float(DEPTH.get(good, auto_depth(good)))
	var pull: float = absf(s) / (absf(s) + depth) * SATURATION_PULL
	return 1.0 - pull if s >= 0.0 else 1.0 + pull

## What an NPC merchant pays a player per unit (selling `quantity` lowers it as it goes).
func npc_buy_price(good: String, quantity: int = 1, now: int = -1) -> int:
	var mid: float = float(maxi(quantity, 1)) / 2.0
	return maxi(1, int(floor(float(reference_price(good, now)) * NPC_BUYS_AT * saturation_factor(good, mid, now))))

## What an NPC merchant charges a player per unit (buying `quantity` raises it as it goes).
func npc_sell_price(good: String, quantity: int = 1, now: int = -1) -> int:
	var mid: float = -float(maxi(quantity, 1)) / 2.0
	return maxi(1, int(ceil(float(reference_price(good, now)) * NPC_SELLS_AT * saturation_factor(good, mid, now))))

## A player sold `quantity` to the merchants (positive) or bought from them (negative).
func record_npc_trade(good: String, quantity: int, now: int = -1) -> void:
	var t: int = _now(now)
	saturation[good] = {"value": saturation_units(good, t) + float(quantity), "t": t}
	_sample(good, t, true)

## Hourly price samples so history exists even when nobody trades.
func sample_all(goods: Array, now: int = -1) -> void:
	var t: int = _now(now)
	for good in goods:
		_sample(str(good), t, false)

func _sample(good: String, t: int, force: bool) -> void:
	var samples: Array = history.get(good, [])
	if not force and not samples.is_empty() and t - int(samples.back()["t"]) < SAMPLE_INTERVAL:
		return
	samples.append({"t": t, "p": npc_buy_price(good, 1, t)})
	while samples.size() > HISTORY_LIMIT:
		samples.pop_front()
	history[good] = samples

func price_history(good: String) -> Array:
	return history.get(good, [])
