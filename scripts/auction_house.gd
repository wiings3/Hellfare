extends RefCounted
class_name AuctionHouse
## The Auction House: post goods or gear at a price for a while and get paid as it sells, or
## post a buy order and get the goods as sellers turn up. Until real players arrive, NPC
## companies keep listings and buy orders of their own and buy and sell against yours.
##
## NPC listings and orders are generated from the item and a three-hour window, so they cost
## nothing to store; only what this company bought from them is saved. Sales and fills of the
## company's own listings and orders are worked out in ten-minute steps from a seed, so the
## result is the same whether the game was open or closed.
##
## Refs are a good's key ("timber") or "gear:<item key>".

const DURATIONS := {"12h": 43200, "1d": 86400, "2d": 172800}
const DURATION_NAMES := {"12h": "12 hours", "1d": "1 day", "2d": "2 days"}
## Paid when posting a listing (share of its asking total, not refunded), and taken from each sale.
const LISTING_FEE := 0.01
const CUT := 0.05
const MAX_LISTINGS := 10
const MAX_ORDERS := 10
const STEP := 600
const EPOCH := 10800
const LOG_LIMIT := 40
const RARITY_MULT := {"common": 1.0, "fine": 1.2, "superior": 1.5, "masterwork": 2.2}

var listings: Array = []
var orders: Array = []
## uid of an NPC listing or order -> units already taken by this company.
var taken: Dictionary = {}
var log: Array = []
var next_id: int = 1

# --- Demand -----------------------------------------------------------------------

## Units per hour that change hands at a fair price.
static func base_rate(ref: String, fair: float) -> float:
	if ref.begins_with("gear:"):
		return clampf(40.0 / maxf(1.0, fair), 0.04, 0.5)
	return clampf(350.0 / maxf(0.5, fair), 0.6, 50.0)

## How much faster or slower a listing sells at `ratio` of the fair price.
static func sell_mult(ratio: float) -> float:
	if ratio <= 1.0:
		return minf(2.5, 1.0 + 3.0 * (1.0 - ratio))
	return exp(-5.0 * (ratio - 1.0))

## How much faster or slower a buy order fills at `ratio` of the fair price.
static func fill_mult(ratio: float) -> float:
	if ratio >= 1.0:
		return minf(3.0, 1.0 + 2.0 * (ratio - 1.0))
	return exp(-6.0 * (1.0 - ratio))

## Units per hour a listing sells: demand, its price against fair value, and whether it's the
## cheapest on offer (buyers take the cheapest first).
static func sell_rate(ref: String, price: float, fair: float, cheapest: float) -> float:
	var r: float = base_rate(ref, fair) * sell_mult(price / maxf(0.5, fair))
	if cheapest > 0.0:
		r *= 1.25 if price <= cheapest else 0.7
	return r

static func fill_rate(ref: String, price: float, fair: float) -> float:
	return base_rate(ref, fair) * fill_mult(price / maxf(0.5, fair))

## Expected hours to sell `qty` at `rate`, and the chance it all goes within `seconds`.
static func estimate(qty: int, rate: float, seconds: int) -> Dictionary:
	var hours: float = float(qty) / maxf(0.0001, rate)
	var expected: float = rate * float(seconds) / 3600.0
	var share: float = clampf(expected / float(maxi(1, qty)), 0.0, 1.0)
	if qty == 1:
		share = 1.0 - exp(-expected)
	return {"hours": hours, "share": share}

# --- NPC listings and orders --------------------------------------------------------

static func _rng(text: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(text)
	return rng

static func _who(rng: RandomNumberGenerator) -> String:
	return str(FallenGear.COMPANIES[rng.randi_range(0, FallenGear.COMPANIES.size() - 1)])

## How many NPC listings an item has in a window: plenty for common goods, few for costly
## ones, seldom any for high-tier or found-only gear.
static func _listing_count(ref: String, fair: float, rng: RandomNumberGenerator) -> int:
	if ref.begins_with("gear:"):
		var d: Dictionary = Catalog.item(ref.substr(5))
		if bool(d.get("found_only", false)):
			return 1 if rng.randf() < 0.05 else 0
		var tier: int = int(d.get("tier", 1))
		var none: float = [0.0, 0.25, 0.35, 0.55, 0.75, 0.88][clampi(tier, 0, 5)]
		return 0 if rng.randf() < none else rng.randi_range(1, 4 if tier <= 2 else 2)
	if fair >= 200.0 and rng.randf() < 0.5:
		return 0
	return rng.randi_range(1, 5)

## NPC listings for an item now, cheapest first: {uid, seller, qty, left, price, ends, item?}.
func npc_listings(ref: String, fair: float, now: int) -> Array:
	var epoch: int = int(now / EPOCH)
	var out: Array = []
	for e in [epoch - 1, epoch]:
		var rng := _rng("ahl|%s|%d" % [ref, e])
		var n: int = _listing_count(ref, fair, rng)
		for i in range(n):
			var uid: String = "npc:%s|%d|%d" % [ref, e, i]
			var ends: int = (e + 1) * EPOCH + rng.randi_range(1, 16) * 1800
			var entry: Dictionary = {"uid": uid, "seller": _who(rng), "ends": ends}
			if ref.begins_with("gear:"):
				var item: Dictionary = Gear.make(ref.substr(5), uid, rng)
				entry["item"] = item
				entry["qty"] = 1
				entry["price"] = maxi(1, int(round(fair * float(RARITY_MULT.get(str(item.get("rarity", "common")), 1.0)) * rng.randf_range(0.9, 1.35))))
			else:
				entry["qty"] = maxi(1, int(round(rng.randf_range(0.3, 1.0) * clampf(600.0 / maxf(1.0, fair), 1.0, 120.0))))
				entry["price"] = maxi(1, int(round(fair * rng.randf_range(0.88, 1.35))))
			entry["left"] = int(entry["qty"]) - int(taken.get(uid, 0))
			if now < int(entry["ends"]) and int(entry["left"]) > 0 and (e == epoch or rng.randf() < 0.6):
				out.append(entry)
	out.sort_custom(func(a, b): return int(a["price"]) < int(b["price"]))
	return out

## NPC buy orders for an item now, best paying first: {uid, buyer, qty, left, price, ends}.
func npc_orders(ref: String, fair: float, now: int) -> Array:
	var epoch: int = int(now / EPOCH)
	var rng := _rng("aho|%s|%d" % [ref, epoch])
	var out: Array = []
	var n: int = 0 if rng.randf() < 0.45 else rng.randi_range(1, 2)
	for i in range(n):
		var uid: String = "npco:%s|%d|%d" % [ref, epoch, i]
		var qty: int = 1 if ref.begins_with("gear:") else maxi(1, int(round(rng.randf_range(0.4, 1.0) * clampf(400.0 / maxf(1.0, fair), 1.0, 80.0))))
		var entry: Dictionary = {"uid": uid, "buyer": _who(rng), "qty": qty, "price": maxi(1, int(round(fair * rng.randf_range(0.75, 0.95)))),
			"ends": (epoch + 1) * EPOCH}
		entry["left"] = qty - int(taken.get(uid, 0))
		if int(entry["left"]) > 0:
			out.append(entry)
	out.sort_custom(func(a, b): return int(a["price"]) > int(b["price"]))
	return out

static func cheapest(npc: Array) -> int:
	return int(npc[0]["price"]) if not npc.is_empty() else 0

# --- The company's own listings and orders ------------------------------------------

func add_log(t: int, kind: String, ref: String, qty: int, gold: int, who: String) -> void:
	log.push_front({"t": t, "kind": kind, "ref": ref, "qty": qty, "gold": gold, "who": who})
	if log.size() > LOG_LIMIT:
		log.resize(LOG_LIMIT)

func listing_by_id(id: int) -> Dictionary:
	for l in listings:
		if int(l["id"]) == id:
			return l
	return {}

func order_by_id(id: int) -> Dictionary:
	for o in orders:
		if int(o["id"]) == id:
			return o
	return {}

func prune(now: int) -> void:
	var keep: Dictionary = {}
	var epoch: int = int(now / EPOCH)
	for uid in taken:
		var parts: PackedStringArray = str(uid).split("|")
		if parts.size() >= 2 and int(parts[parts.size() - 2]) >= epoch - 2:
			keep[uid] = taken[uid]
	taken = keep

func to_dict() -> Dictionary:
	return {"listings": listings, "orders": orders, "taken": taken, "log": log, "next": next_id}

func load_dict(data: Dictionary) -> void:
	if data.is_empty():
		return
	listings = (data.get("listings", []) as Array).duplicate(true)
	orders = (data.get("orders", []) as Array).duplicate(true)
	taken = (data.get("taken", {}) as Dictionary).duplicate()
	log = (data.get("log", []) as Array).duplicate(true)
	next_id = int(data.get("next", 1))
