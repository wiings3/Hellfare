extends RefCounted
class_name TradeHall
## The Trade Hall: a trade chat in the style of Dark and Darker's first trade channel.
## Traders post item links with prices ("WTS [Timber]x40 6g each"). This is the NPC
## prototype agreed in the design doc; the same data can later come from a server.
##
## Stage 1 (this file):
## - NPC traders of six kinds post WTS / WTB lines priced around each good's fair value.
## - The player posts listings from the warehouse. Goods are held in escrow, a small post
##   fee is paid up front and a 3% tax is taken from each sale.
## - NPC buyers take player listings. A fairly priced listing sells in minutes; one priced
##   at the merchants' resale price never sells, because buyers can get it there instead.
## - Fair value = the market's reference price x its saturation factor, so flooding the
##   merchants also cools the Hall, and Hall sales saturate the merchants in turn.
##
## Stage 2 (whispers): any trader's post can be negotiated in a whisper (see Haggle), and
## buyers whisper the company with offers on listings priced on the high side. Posts
## track how much is left; a post traded out shows as sold. Whispers are not saved.
## Stage 3 adds the trade window.

const TAX := 0.03
const POST_FEE := 2
const MAX_LISTINGS := 5
const LISTING_SECONDS := 12 * 3600
const FEED_LIMIT := 60
const POST_GAP_MIN := 5
const POST_GAP_MAX := 16
const FILL_STEP := 60
const FILL_RATE := 0.15
const MAX_CATCHUP := 24 * 3600
## Above this multiple of fair value nobody buys: the merchants sell for about that.
const NO_SALE_RATIO := 1.30
## Listings priced above this multiple of fair value draw whispered offers.
const OFFER_ABOVE := 1.04
const OFFER_RATE := 0.03
const MAX_OPEN_OFFERS := 2

const KINDS := {
	"hawker": {"label": "Hawker", "note": "Posts often at fair prices."},
	"quartermaster": {"label": "Quartermaster", "note": "Buys in bulk and pays a little under value."},
	"collector": {"label": "Collector", "note": "Pays a premium for rare goods."},
	"flipper": {"label": "Flipper", "note": "Buys cheap to sell dear."},
	"bargain": {"label": "Bargain seller", "note": "Undercuts the market to sell fast."},
	"haggler": {"label": "Haggler", "note": "Always open to offers."},
}

const TRADERS := [
	{"name": "Bram_Tollard", "kind": "hawker"},
	{"name": "Wren", "kind": "hawker"},
	{"name": "OldMossy", "kind": "hawker"},
	{"name": "Hesk", "kind": "quartermaster"},
	{"name": "Garrison_QM", "kind": "quartermaster"},
	{"name": "LadyVess", "kind": "collector"},
	{"name": "Corvin_Ashe", "kind": "collector"},
	{"name": "Quickcoin", "kind": "flipper"},
	{"name": "Sly_Pell", "kind": "flipper"},
	{"name": "Dunny", "kind": "bargain"},
	{"name": "Fenna_Low", "kind": "bargain"},
	{"name": "Marrow", "kind": "haggler"},
	{"name": "Tobbin", "kind": "haggler"},
	{"name": "Ilse_Rook", "kind": "hawker"},
]

## How often each good comes up in the chat.
const GOOD_WEIGHT := {
	"copper": 4.0, "iron": 4.0, "timber": 5.0, "herbs": 4.0,
	"silver": 2.0, "crystal": 1.0, "relic": 0.3, "sovereign": 0.05,
}
## Typical post size per good, [low, high].
const GOOD_QTY := {
	"copper": [10, 50], "iron": [10, 50], "timber": [10, 80], "herbs": [10, 60],
	"silver": [3, 20], "crystal": [1, 6], "relic": [1, 2], "sovereign": [1, 1],
}
const RARE := ["silver", "crystal", "relic", "sovereign"]

## [side, low ratio, high ratio, weight] per kind. Ratios are of fair value.
const KIND_POSTS := {
	"hawker": [["wts", 0.95, 1.12, 4.0], ["wtb", 0.82, 0.95, 1.0]],
	"quartermaster": [["wtb", 0.80, 0.92, 1.0]],
	"collector": [["wtb", 1.05, 1.25, 1.0]],
	"flipper": [["wtb", 0.70, 0.84, 3.0], ["wts", 1.08, 1.22, 2.0]],
	"bargain": [["wts", 0.84, 0.94, 1.0]],
	"haggler": [["wts", 0.98, 1.15, 1.0], ["wtb", 0.82, 0.95, 1.0]],
}

var market: MarketModel
var goods: Array = []
var feed: Array = []
var listings: Array = []
var next_id: int = 1
var next_post_at: int = 0
var last_fill_at: int = 0
var rng := RandomNumberGenerator.new()
## trader name -> Haggle, the open whispers. Not saved: a reload ends conversations.
var whispers: Dictionary = {}

func _init(market_model: MarketModel = null, good_keys: Array = []) -> void:
	market = market_model
	goods = good_keys
	rng.randomize()

# --- Saving -------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"feed": feed, "listings": listings, "next_id": next_id, "last_fill_at": last_fill_at}

func load_dict(data: Dictionary) -> void:
	reset()
	next_id = maxi(1, int(data.get("next_id", 1)))
	last_fill_at = int(data.get("last_fill_at", 0))
	for m in data.get("feed", []):
		if typeof(m) == TYPE_DICTIONARY:
			feed.append(_clean_message(m))
	for l in data.get("listings", []):
		if typeof(l) == TYPE_DICTIONARY and goods.has(str(l.get("good", ""))) and int(l.get("left", 0)) > 0:
			listings.append({
				"id": int(l.get("id", 0)), "good": str(l["good"]), "qty": int(l.get("qty", 0)),
				"left": int(l["left"]), "price": maxi(1, int(l.get("price", 1))),
				"posted": int(l.get("posted", 0)), "expires": int(l.get("expires", 0)),
			})

func reset() -> void:
	feed.clear()
	listings.clear()
	next_id = 1
	next_post_at = 0
	last_fill_at = 0
	whispers.clear()

func _clean_message(m: Dictionary) -> Dictionary:
	return {
		"id": int(m.get("id", 0)), "t": int(m.get("t", 0)), "from": str(m.get("from", "")),
		"kind": str(m.get("kind", "")), "side": str(m.get("side", "")), "good": str(m.get("good", "")),
		"qty": int(m.get("qty", 0)), "price": int(m.get("price", 0)), "offer": bool(m.get("offer", false)),
		"left": int(m.get("left", m.get("qty", 0))), "text": str(m.get("text", "")), "total": int(m.get("total", 0)),
	}

# --- Prices -------------------------------------------------------------------

## A good's fair value right now: what traders in the Hall think it is worth.
func fair_value(good: String, now: int = -1) -> float:
	return float(market.reference_price(good, now)) * market.saturation_factor(good, 0.0, now)

## The best recent ask (lowest WTS) and bid (highest WTB) in the chat, -1 when none.
func quotes(good: String) -> Dictionary:
	var ask: int = -1
	var bid: int = -1
	for m in feed:
		if str(m["good"]) != good or str(m["from"]) == "You" or int(m.get("left", 0)) <= 0:
			continue
		if str(m["side"]) == "wts" and (ask < 0 or int(m["price"]) < ask):
			ask = int(m["price"])
		elif str(m["side"]) == "wtb" and int(m["price"]) > bid:
			bid = int(m["price"])
	return {"ask": ask, "bid": bid}

## Chance per minute that a buyer takes some of a listing at `price`.
func fill_chance(good: String, price: int, now: int = -1) -> float:
	var ratio: float = float(price) / maxf(0.5, fair_value(good, now))
	var appeal: float = clampf((NO_SALE_RATIO - ratio) / 0.45, 0.0, 1.5)
	var depth: float = float(MarketModel.DEPTH.get(good, 50.0))
	return FILL_RATE * appeal * clampf(depth / 60.0, 0.15, 1.0)

## A rough "sells in about" estimate in seconds, or -1 when it will not sell.
func expected_wait(good: String, price: int, now: int = -1) -> int:
	var chance: float = fill_chance(good, price, now)
	if chance <= 0.0:
		return -1
	return int(round(float(FILL_STEP) / chance))

func listed_units(good: String = "") -> int:
	var total: int = 0
	for l in listings:
		if good == "" or str(l["good"]) == good:
			total += int(l["left"])
	return total

# --- Player listings ----------------------------------------------------------

func can_post() -> bool:
	return listings.size() < MAX_LISTINGS

## Adds a listing (the company has already taken the goods and the fee).
func add_listing(good: String, qty: int, price: int, now: int) -> Dictionary:
	var listing := {
		"id": next_id, "good": good, "qty": qty, "left": qty, "price": price,
		"posted": now, "expires": now + LISTING_SECONDS,
	}
	next_id += 1
	listings.append(listing)
	_post({"t": now, "from": "You", "kind": "you", "side": "wts", "good": good, "qty": qty, "price": price})
	return listing

## Removes a listing and returns it, so the company can take back what is left.
func remove_listing(id: int) -> Dictionary:
	for i in range(listings.size()):
		if int(listings[i]["id"]) == id:
			var listing: Dictionary = listings[i]
			listings.remove_at(i)
			return listing
	return {}

# --- The clock ----------------------------------------------------------------

## Advance the Hall to `now`. Returns events for the company to settle:
## {"type": "sale", "good", "qty", "price", "gross", "tax", "buyer", "t"} and
## {"type": "expired", "good", "qty", "t"}. New chat lines go straight into `feed`.
func tick(now: int) -> Array:
	var events: Array = []
	if last_fill_at <= 0:
		last_fill_at = now
	last_fill_at = maxi(last_fill_at, now - MAX_CATCHUP)
	while last_fill_at + FILL_STEP <= now:
		last_fill_at += FILL_STEP
		events.append_array(_fill_step(last_fill_at))
	_npc_posts(now)
	return events

func _fill_step(t: int) -> Array:
	var events: Array = []
	for listing in listings.duplicate():
		if int(listing["expires"]) <= t:
			events.append({"type": "expired", "good": listing["good"], "qty": int(listing["left"]), "t": t})
			remove_listing(int(listing["id"]))
			continue
		if _maybe_offer(listing, t):
			events.append({"type": "whisper", "trader": _last_offer_from, "good": listing["good"], "t": t})
			continue
		if rng.randf() >= fill_chance(str(listing["good"]), int(listing["price"]), t):
			continue
		var good: String = str(listing["good"])
		var depth: float = float(MarketModel.DEPTH.get(good, 50.0))
		var take: int = mini(int(listing["left"]), rng.randi_range(int(ceil(depth / 15.0)), int(ceil(depth / 4.0))))
		var gross: int = take * int(listing["price"])
		var tax: int = maxi(1, int(round(float(gross) * TAX)))
		var buyer: Dictionary = _pick_buyer(good)
		listing["left"] = int(listing["left"]) - take
		if int(listing["left"]) <= 0:
			remove_listing(int(listing["id"]))
		_post({"t": t, "from": str(buyer["name"]), "kind": str(buyer["kind"]), "side": "bought",
			"good": good, "qty": take, "price": int(listing["price"])})
		events.append({"type": "sale", "good": good, "qty": take, "price": int(listing["price"]),
			"gross": gross, "tax": tax, "buyer": str(buyer["name"]), "t": t})
	return events

func _pick_buyer(good: String) -> Dictionary:
	var pool: Array = []
	for trader in TRADERS:
		var kind: String = str(trader["kind"])
		if kind == "bargain":
			continue
		if kind == "collector" and not RARE.has(good):
			continue
		pool.append(trader)
	return pool[rng.randi_range(0, pool.size() - 1)]

func _npc_posts(now: int) -> void:
	# After a long absence only the last few minutes of chatter are shown.
	if next_post_at < now - 300:
		next_post_at = now - 300
	while next_post_at <= now:
		_post(_npc_message(next_post_at))
		next_post_at += rng.randi_range(POST_GAP_MIN, POST_GAP_MAX)

func _npc_message(t: int) -> Dictionary:
	var trader: Dictionary = TRADERS[rng.randi_range(0, TRADERS.size() - 1)]
	var kind: String = str(trader["kind"])
	var option: Array = _weighted(KIND_POSTS[kind])
	var side: String = str(option[0])
	var good: String = _pick_good(kind == "collector")
	var span: Array = GOOD_QTY.get(good, [1, 10])
	var qty: int = rng.randi_range(int(span[0]), int(span[1]))
	if kind == "quartermaster":
		qty *= 2
	if qty >= 10:
		qty = maxi(5, int(round(float(qty) / 5.0)) * 5)
	var ratio: float = rng.randf_range(float(option[1]), float(option[2]))
	var price: int = maxi(1, int(round(fair_value(good, t) * ratio)))
	return {"t": t, "from": str(trader["name"]), "kind": kind, "side": side, "good": good,
		"qty": qty, "price": price, "offer": kind == "haggler", "left": qty}

func _pick_good(rare_only: bool) -> String:
	var total: float = 0.0
	for good in goods:
		if rare_only and not RARE.has(good):
			continue
		total += float(GOOD_WEIGHT.get(good, 1.0))
	var roll: float = rng.randf() * total
	for good in goods:
		if rare_only and not RARE.has(good):
			continue
		roll -= float(GOOD_WEIGHT.get(good, 1.0))
		if roll <= 0.0:
			return str(good)
	return str(goods[0])

func _weighted(options: Array) -> Array:
	var total: float = 0.0
	for o in options:
		total += float(o[3])
	var roll: float = rng.randf() * total
	for o in options:
		roll -= float(o[3])
		if roll <= 0.0:
			return o
	return options[0]

func _post(message: Dictionary) -> void:
	message["id"] = next_id
	next_id += 1
	if not message.has("offer"):
		message["offer"] = false
	if not message.has("left"):
		message["left"] = int(message.get("qty", 0))
	if not message.has("text"):
		message["text"] = ""
	feed.append(message)
	while feed.size() > FEED_LIMIT:
		feed.pop_front()

# --- Whispers ------------------------------------------------------------------

var _last_offer_from: String = ""

func message_by_id(id: int) -> Dictionary:
	for m in feed:
		if int(m["id"]) == id:
			return m
	return {}

func trader_kind(name: String) -> String:
	for trader in TRADERS:
		if str(trader["name"]) == name:
			return str(trader["kind"])
	return "hawker"

func whisper_with(trader: String) -> Haggle:
	return whispers.get(trader, null)

## Open (or return) a whisper about a WTS / WTB post in the chat.
func open_whisper(message_id: int, now: int) -> Haggle:
	var m: Dictionary = message_by_id(message_id)
	if m.is_empty() or str(m["from"]) == "You" or not str(m["side"]) in ["wts", "wtb"]:
		return null
	var trader: String = str(m["from"])
	var current: Haggle = whispers.get(trader, null)
	if current != null and current.is_open() and current.post_id == message_id:
		return current
	var h := Haggle.make(trader, str(m["kind"]), str(m["good"]), str(m["side"]) == "wts",
		int(m["left"]), int(m["price"]), fair_value(str(m["good"]), now), rng)
	h.post_id = message_id
	whispers[trader] = h
	var item_line: String = "Hi, about your {item}x%d?" % int(m["qty"])
	whisper_line(h, true, item_line, now)
	if int(m["left"]) <= 0:
		h.status = "gone"
		whisper_line(h, false, h.say("gone"), now)
	else:
		whisper_line(h, false, h.say("greet_sell" if h.they_sell else "greet_buy"), now)
	return h

## Post one whispered line into the chat. `outgoing` = written by the company.
func whisper_line(h: Haggle, outgoing: bool, text: String, now: int, qty: int = -1, total: int = -1) -> void:
	var n: int = qty if qty > 0 else h.qty_max
	_post({"t": now, "from": h.trader, "kind": h.kind, "side": "whisper_out" if outgoing else "whisper_in",
		"good": h.good, "qty": n, "price": int(round(h.ask)), "total": total if total >= 0 else h.quote(n), "text": text, "left": 0})

func end_whisper(trader: String) -> void:
	var h: Haggle = whispers.get(trader, null)
	if h != null and h.is_open():
		h.walk_away()

## Units traded out of a chat post through a whisper.
func take_from_post(post_id: int, qty: int) -> void:
	var m: Dictionary = message_by_id(post_id)
	if not m.is_empty():
		m["left"] = maxi(0, int(m["left"]) - qty)

func open_offer_count() -> int:
	var n: int = 0
	for trader in whispers:
		var h: Haggle = whispers[trader]
		if h.is_open() and h.listing_id >= 0:
			n += 1
	return n

## Buyers whisper offers on listings priced above fair value instead of buying outright.
func _maybe_offer(listing: Dictionary, t: int) -> bool:
	var good: String = str(listing["good"])
	var fair: float = fair_value(good, t)
	if float(listing["price"]) <= fair * OFFER_ABOVE or open_offer_count() >= MAX_OPEN_OFFERS:
		return false
	for trader in whispers:
		var open: Haggle = whispers[trader]
		if open.is_open() and open.listing_id == int(listing["id"]):
			return false
	if rng.randf() >= OFFER_RATE:
		return false
	var buyer: Dictionary = _pick_buyer(good)
	if whispers.has(str(buyer["name"])) and (whispers[str(buyer["name"])] as Haggle).is_open():
		return false
	var depth: float = float(MarketModel.DEPTH.get(good, 50.0))
	var qty: int = mini(int(listing["left"]), rng.randi_range(int(ceil(depth / 10.0)), int(ceil(depth / 3.0))))
	var bid: int = maxi(1, int(round(fair * rng.randf_range(0.94, 1.02))))
	var h := Haggle.make(str(buyer["name"]), str(buyer["kind"]), good, false, qty, bid, fair, rng)
	# Their ceiling per unit sits between fair value and the listing price.
	h.reservation = clampf(fair * rng.randf_range(1.0, 1.12), float(bid), float(listing["price"]))
	h.listing_id = int(listing["id"])
	whispers[h.trader] = h
	whisper_line(h, false, h.say("offer", qty), t, qty)
	_last_offer_from = h.trader
	return true

func listing_by_id(id: int) -> Dictionary:
	for l in listings:
		if int(l["id"]) == id:
			return l
	return {}
