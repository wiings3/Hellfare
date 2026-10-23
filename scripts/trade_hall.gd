extends RefCounted
class_name TradeHall
## The Trade Hall: a typed trade chat in the style of Dark and Darker's first trade
## channel. This is the NPC prototype agreed in the design doc. Real players replace the
## NPC traders later; the chat, messages and trade window stay the same.
##
## - NPC traders post WTS / WTB lines priced around each good's fair value. Their posts
##   sell out after a while, whether or not the player ever answers.
## - The player types their own posts, with item links shift-clicked in from the inventory.
##   A short cooldown stops spam. NPCs read the posts (see ChatParse) and may message the
##   player if the price interests them, or may not.
## - Right-click a name to message or block. Private messages are free text; NPCs read
##   prices, quantities and yes / no, haggle (see Haggle), sometimes never reply, and send
##   a trade request once a price is agreed.
## - The trade window (TradeSession) is where goods and gold actually change hands, with a
##   3% tax on gold received.
## - Fair value = the market's reference price x its saturation factor, so the Hall and
##   the merchants stay linked. Gear is valued at 85% of its quartermaster price.
## Conversations and trades are not saved; the chat, the block list and your posts are.

const TAX := 0.03
const FEED_LIMIT := 80
const POST_GAP_MIN := 5
const POST_GAP_MAX := 16
const SAY_COOLDOWN := 8
const SAY_REPEAT := 60
const SAY_MAX := 120
const PM_MAX := 160
const PM_HISTORY := 40
const MAX_NPC_OPENERS := 3
const GEAR_POST_CHANCE := 0.12
const GEAR_FAIR := 0.85

const KINDS := {
	"hawker": {"label": "Hawker", "note": "Posts often at fair prices."},
	"quartermaster": {"label": "Quartermaster", "note": "Buys in bulk and pays a little under value."},
	"collector": {"label": "Collector", "note": "Pays a premium for rare goods."},
	"flipper": {"label": "Flipper", "note": "Buys cheap to sell dear."},
	"bargain": {"label": "Bargain seller", "note": "Undercuts the market to sell fast."},
	"haggler": {"label": "Haggler", "note": "Always open to offers."},
}
const BUYER_KINDS := ["hawker", "quartermaster", "collector", "flipper", "haggler"]
const SELLER_KINDS := ["hawker", "bargain", "flipper", "haggler"]

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
var next_id: int = 1
var next_post_at: int = 0
var rng := RandomNumberGenerator.new()
## Display name for an item ref ("timber", "gear:steel_sword"); set by the company.
var item_name: Callable = func(ref: String) -> String: return ref
var blocked: Array[String] = []
## trader -> Array of {"from": "you" | trader | "system", "text", "links", "t"}
var pms: Dictionary = {}
var unread: Dictionary = {}
## trader -> Haggle: what is being negotiated with them.
var deals: Dictionary = {}
## Things NPCs will do shortly: {"at", "type", "trader", ...}
var pending: Array = []
var session: TradeSession = null
var last_say_at: int = -1000000
var last_say_text: String = ""
## Goods left in listings by older saves; the company returns them to the warehouse.
var legacy_listings: Array = []

func _init(market_model: MarketModel = null, good_keys: Array = []) -> void:
	market = market_model
	goods = good_keys
	rng.randomize()

# --- Saving -------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"feed": feed, "next_id": next_id, "blocked": blocked}

func load_dict(data: Dictionary) -> void:
	reset()
	next_id = maxi(1, int(data.get("next_id", 1)))
	for m in data.get("feed", []):
		if typeof(m) == TYPE_DICTIONARY:
			var clean: Dictionary = _clean_message(m)
			if not clean.is_empty():
				feed.append(clean)
	for name in data.get("blocked", []):
		blocked.append(str(name))
	# Saves from the listing prototype: the company returns these goods to the warehouse.
	for l in data.get("listings", []):
		if typeof(l) == TYPE_DICTIONARY and goods.has(str(l.get("good", ""))) and int(l.get("left", 0)) > 0:
			legacy_listings.append({"good": str(l["good"]), "left": int(l["left"])})

func reset() -> void:
	feed.clear()
	next_id = 1
	next_post_at = 0
	blocked.clear()
	pms.clear()
	unread.clear()
	deals.clear()
	pending.clear()
	session = null
	last_say_at = -1000000
	last_say_text = ""
	legacy_listings.clear()

func _clean_message(m: Dictionary) -> Dictionary:
	var side: String = str(m.get("side", ""))
	if not side in ["wts", "wtb", "say", "system"]:
		return {}
	var links: Array = []
	for l in m.get("links", []):
		if typeof(l) == TYPE_DICTIONARY:
			links.append({"ref": str(l.get("ref", "")), "name": str(l.get("name", "")), "uid": str(l.get("uid", ""))})
	return {
		"id": int(m.get("id", 0)), "t": int(m.get("t", 0)), "from": str(m.get("from", "")),
		"kind": str(m.get("kind", "")), "side": side, "good": str(m.get("good", "")),
		"qty": int(m.get("qty", 0)), "price": int(m.get("price", 0)), "offer": bool(m.get("offer", false)),
		"left": int(m.get("left", m.get("qty", 0))), "until": int(m.get("until", 0)),
		"text": str(m.get("text", "")), "links": links,
	}

# --- Prices -------------------------------------------------------------------

## What traders think an item is worth right now. Goods follow the market; gear is
## valued at 85% of the quartermaster's price.
func fair(ref: String, now: int = -1) -> float:
	if ref.begins_with("gear:"):
		return float(MercsV05.ITEMS.get(ref.substr(5), {}).get("cost", 10)) * GEAR_FAIR
	return float(market.reference_price(ref, now)) * market.saturation_factor(ref, 0.0, now)

## Kept for the goods pages.
func fair_value(good: String, now: int = -1) -> float:
	return fair(good, now)

## The best open ask (lowest WTS) and bid (highest WTB) in the chat, -1 when none.
func quotes(good: String) -> Dictionary:
	var ask: int = -1
	var bid: int = -1
	for m in feed:
		if str(m["good"]) != good or int(m.get("left", 0)) <= 0:
			continue
		if str(m["side"]) == "wts" and (ask < 0 or int(m["price"]) < ask):
			ask = int(m["price"])
		elif str(m["side"]) == "wtb" and int(m["price"]) > bid:
			bid = int(m["price"])
	return {"ask": ask, "bid": bid}

func name_of(ref: String) -> String:
	return str(item_name.call(ref))

# --- Chat ----------------------------------------------------------------------

## Seconds until the company may post again (0 = now).
func say_wait(now: int) -> int:
	return maxi(0, last_say_at + SAY_COOLDOWN - now)

## Post a message to the trade chat. `links` = [{"ref", "name", "uid"}] for each [Name]
## token in the text. Returns "" on success, or why it was refused.
func say(text: String, links: Array, now: int) -> String:
	var clean: String = text.strip_edges()
	if clean == "":
		return "Type a message first."
	if clean.length() > SAY_MAX:
		return "Keep it under %d characters." % SAY_MAX
	if say_wait(now) > 0:
		return "Slow down. You can post again in %ds." % say_wait(now)
	if clean.to_lower() == last_say_text.to_lower() and now - last_say_at < SAY_REPEAT:
		return "You just posted that. Give it a minute."
	var kept: Array = []
	for l in links:
		if clean.find("[%s]" % str(l["name"])) >= 0:
			kept.append(l)
	last_say_at = now
	last_say_text = clean
	_post({"t": now, "from": "You", "kind": "you", "side": "say", "text": clean, "links": kept})
	_react_to_say(clean, kept, now)
	return ""

func block(trader: String) -> void:
	if not blocked.has(trader):
		blocked.append(trader)
	deals.erase(trader)
	if session != null and session.trader == trader:
		session.status = "cancelled"
		session = null

func unblock(trader: String) -> void:
	blocked.erase(trader)

func is_blocked(trader: String) -> bool:
	return blocked.has(trader)

func trader_kind(name: String) -> String:
	for trader in TRADERS:
		if str(trader["name"]) == name:
			return str(trader["kind"])
	return "hawker"

func is_trader(name: String) -> bool:
	for trader in TRADERS:
		if str(trader["name"]) == name:
			return true
	return false

func message_by_id(id: int) -> Dictionary:
	for m in feed:
		if int(m["id"]) == id:
			return m
	return {}

## The trader's newest post that is still up, optionally for one item.
func latest_post_by(trader: String, ref: String = "") -> Dictionary:
	for i in range(feed.size() - 1, -1, -1):
		var m: Dictionary = feed[i]
		if str(m["from"]) == trader and str(m["side"]) in ["wts", "wtb"] and (ref == "" or str(m["good"]) == ref):
			return m
	return {}

# --- Private messages ------------------------------------------------------------

func conversation(trader: String) -> Array:
	if not pms.has(trader):
		pms[trader] = []
	return pms[trader]

func is_typing(trader: String, now: int) -> bool:
	for p in pending:
		if str(p["trader"]) == trader and str(p["type"]) == "pm":
			return int(p["at"]) - now <= 4
	return false

## The company messages a trader. NPCs read it and may answer after a pause, or not.
func pm(trader: String, text: String, links: Array, now: int) -> String:
	var clean: String = text.strip_edges()
	if clean == "":
		return "Type a message first."
	if clean.length() > PM_MAX:
		return "Keep it under %d characters." % PM_MAX
	if is_blocked(trader):
		return "You blocked %s. Unblock them to message." % trader
	var kept: Array = []
	for l in links:
		if clean.find("[%s]" % str(l["name"])) >= 0:
			kept.append(l)
	_pm_line(trader, "you", clean, kept, now)
	_npc_read(trader, clean, kept, now)
	return ""

func _pm_line(trader: String, from: String, text: String, links: Array, now: int) -> void:
	var lines: Array = conversation(trader)
	lines.append({"from": from, "text": text, "links": links, "t": now})
	while lines.size() > PM_HISTORY:
		lines.pop_front()
	if not from in ["you", "system"]:
		unread[trader] = int(unread.get(trader, 0)) + 1

## Schedule an NPC line (and optional follow-up) after a typing pause.
func _npc_say(trader: String, text: String, h: Haggle, now: int, delay_min: float = 2.0, delay_max: float = 6.0, then_trade: bool = false) -> void:
	var at: int = now + int(round(rng.randf_range(delay_min, delay_max)))
	var links: Array = []
	if h != null and text.find("[%s]" % h.item_name) >= 0:
		links.append({"ref": h.good, "name": h.item_name, "uid": ""})
	pending.append({"at": at, "type": "pm", "trader": trader, "text": text, "links": links})
	if then_trade:
		pending.append({"at": at + rng.randi_range(2, 4), "type": "trade_request", "trader": trader})

func _new_deal(trader: String, ref: String, they_sell: bool, qty: int, price_each: int, now: int) -> Haggle:
	var h := Haggle.make(trader, trader_kind(trader), ref, they_sell, maxi(1, qty), maxi(1, price_each), fair(ref, now), rng)
	h.item_name = name_of(ref)
	deals[trader] = h
	return h

## How an NPC answers a private message from the company.
func _npc_read(trader: String, text: String, links: Array, now: int) -> void:
	if not is_trader(trader):
		return
	var h: Haggle = deals.get(trader, null)
	var first_contact: bool = h == null or h.status in ["done", "gone"]
	if first_contact:
		h = _deal_from_context(trader, text, links, now)
		if h == null:
			if rng.randf() < 0.6:
				var asker := Haggle.new()
				asker.rng = rng
				_npc_say(trader, asker.say("what"), null, now)
			return
		if h.status == "gone":
			# Their post sold before they read the message: sometimes they say so, often not.
			if rng.randf() < 0.5:
				_npc_say(trader, h.say("gone"), h, now, 5.0, 20.0)
			return
		# Busy traders do not always answer a first message.
		var post: Dictionary = message_by_id(h.post_id)
		var age: int = now - int(post.get("t", now))
		if rng.randf() < 0.1 + clampf(float(age) / 900.0, 0.0, 0.3):
			return
	_npc_answer(h, text, now)

## Work out what a first message is about: an item it links, or the trader's latest post.
func _deal_from_context(trader: String, text: String, links: Array, now: int) -> Haggle:
	var ref: String = str(links[0]["ref"]) if not links.is_empty() else ""
	var post: Dictionary = latest_post_by(trader, ref)
	if post.is_empty() and ref == "":
		post = latest_post_by(trader)
	if not post.is_empty():
		var qty: int = int(post["left"]) if int(post["left"]) > 0 else int(post["qty"])
		var h := _new_deal(trader, str(post["good"]), str(post["side"]) == "wts", qty, int(post["price"]), now)
		h.post_id = int(post["id"])
		if int(post["left"]) <= 0:
			h.status = "gone"
		return h
	if ref == "":
		return null
	# No post for it: they may still buy what the company offers, or sell from stock.
	var kind: String = trader_kind(trader)
	var value: float = fair(ref, now)
	var wanted: int = ChatParse.quantity(text)
	if ref.begins_with("gear:"):
		wanted = 1
	var mine: bool = str(links[0].get("uid", "")) != "" or ChatParse.intent(text) == "sell" or kind in ["quartermaster", "collector"]
	if mine and BUYER_KINDS.has(kind):
		var bid: int = maxi(1, int(round(value * rng.randf_range(0.82, 0.94))))
		var h := _new_deal(trader, ref, false, maxi(1, wanted), bid, now)
		h.reservation = value * rng.randf_range(1.0, 1.1)
		return h
	if SELLER_KINDS.has(kind) and not ref.begins_with("gear:"):
		var ask: int = maxi(1, int(round(value * rng.randf_range(1.0, 1.12))))
		return _new_deal(trader, ref, true, maxi(1, wanted if wanted > 0 else 20), ask, now)
	return null

## Read the company's message inside a negotiation and reply.
func _npc_answer(h: Haggle, text: String, now: int) -> void:
	var trader: String = h.trader
	if h.status == "gone":
		if rng.randf() < 0.5:
			_npc_say(trader, h.say("no_more"), h, now)
		return
	if h.is_agreed():
		if ChatParse.says_no(text):
			h.status = "gone"
			_npc_say(trader, h.say("decline_ok"), h, now)
		elif ChatParse.wants_trade(text) or ChatParse.says_yes(text):
			if session == null or session.trader != trader:
				_npc_say(trader, h.say("trade_request"), h, now, 1.0, 3.0, true)
		else:
			_npc_say(trader, h.say("quote", h.agreed_qty, h.agreed_total), h, now)
		return
	if ChatParse.says_no(text):
		h.walk_away()
		_npc_say(trader, h.say("decline_ok"), h, now)
		return
	var lot: Dictionary = ChatParse.lot(text)
	var qty: int = h.qty_max
	if not lot.is_empty():
		qty = int(lot["qty"])
	elif ChatParse.quantity(text) > 0:
		qty = ChatParse.quantity(text)
	qty = clampi(qty, 1, h.qty_max)
	var figures: Array = ChatParse.money(text)
	# "deal, 40" or "ok 20" means a quantity at their price, not 40 gold. Only figures
	# marked as gold ("40g", "40 each", "1.5k") are read as prices next to a yes.
	if lot.is_empty() and (ChatParse.says_yes(text) or ChatParse.wants_trade(text)):
		var priced: bool = false
		for f in figures:
			priced = priced or bool(f["gold"]) or bool(f["each"])
		if not priced:
			if not figures.is_empty():
				qty = clampi(int(figures[0]["value"]), 1, h.qty_max)
			figures = []
	var reply: Dictionary = {}
	if not lot.is_empty():
		reply = h.offer(qty, int(lot["total"]))
	elif not figures.is_empty():
		reply = h.offer(qty, ChatParse.total_for(figures[0], qty, h.ask))
	elif ChatParse.says_yes(text) or ChatParse.wants_trade(text):
		reply = h.take(qty)
	else:
		_npc_say(trader, h.say("quote_one" if h.good.begins_with("gear:") else "quote", qty), h, now)
		return
	var line: String = str(reply["line"])
	if str(reply["result"]) == "accept":
		_npc_say(trader, line, h, now, 2.0, 5.0)
		_npc_say(trader, h.say("trade_request"), h, now + 3, 1.0, 2.0, true)
	else:
		_npc_say(trader, line, h, now)

## NPCs skim the company's post and message about the items it links, if interested.
func _react_to_say(text: String, links: Array, now: int) -> void:
	var intent: String = ChatParse.intent(text)
	var buying: bool = intent == "buy"
	var openers: int = 0
	for trader in deals:
		var open: Haggle = deals[trader]
		if open.status in ["open", "agreed"]:
			openers += 1
	for l in links.slice(0, 3):
		var ref: String = str(l["ref"])
		var name: String = str(l["name"])
		var value: float = fair(ref, now)
		var figure: Dictionary = ChatParse.price_after_link(text, name)
		var qty: int = ChatParse.qty_after_link(text, name)
		if qty <= 0:
			qty = 1 if ref.begins_with("gear:") else 20
		var each: float = -1.0
		if not figure.is_empty():
			each = float(figure["value"]) if (bool(figure["each"]) or float(figure["value"]) <= value * 2.5 or qty <= 1) else float(figure["value"]) / float(qty)
		var pool: Array = []
		for trader in TRADERS:
			var name_t: String = str(trader["name"])
			if is_blocked(name_t) or (deals.has(name_t) and (deals[name_t] as Haggle).status in ["open", "agreed"]):
				continue
			var kind: String = str(trader["kind"])
			if (SELLER_KINDS if buying else BUYER_KINDS).has(kind) and (kind != "collector" or RARE.has(ref) or ref.begins_with("gear:")):
				pool.append(trader)
		pool.shuffle()
		for trader in pool.slice(0, 2):
			if openers >= MAX_NPC_OPENERS:
				return
			var interest: float = 0.45
			if each > 0.0:
				var ratio: float = each / maxf(0.5, value)
				interest = clampf((1.25 - ratio) / 0.35, 0.0, 1.0) if not buying else clampf((ratio - 0.8) / 0.3, 0.0, 1.0)
			if rng.randf() >= interest * 0.75:
				continue
			openers += 1
			_npc_opener(str(trader["name"]), ref, buying, qty, each, value, now)

func _npc_opener(trader: String, ref: String, player_buys: bool, qty: int, each: float, value: float, now: int) -> void:
	var kind: String = trader_kind(trader)
	var their_qty: int = qty
	if not ref.begins_with("gear:") and not player_buys and kind != "quartermaster":
		their_qty = rng.randi_range(int(ceil(float(qty) / 3.0)), qty)
	var h: Haggle
	var moment: String
	if player_buys:
		var ask: int = maxi(1, int(round(maxf(each, value * rng.randf_range(0.95, 1.08)) if each > 0.0 else value * rng.randf_range(1.0, 1.1))))
		h = _new_deal(trader, ref, true, their_qty, ask, now)
		moment = "interested_buy"
	elif each > 0.0 and each <= value * 0.97:
		h = _new_deal(trader, ref, false, their_qty, int(round(each)), now)
		h.reservation = each
		moment = "take_yours"
	else:
		var bid: int = maxi(1, int(round(value * rng.randf_range(0.86, 0.97))))
		h = _new_deal(trader, ref, false, their_qty, bid, now)
		h.reservation = minf(each if each > 0.0 else value * 1.1, value * rng.randf_range(1.0, 1.12))
		h.reservation = maxf(h.reservation, float(bid))
		moment = "interested_sell" if each > 0.0 else "how_much"
	_npc_say(trader, h.say(moment, their_qty), h, now, 6.0, 40.0)

# --- Trades -----------------------------------------------------------------------

## The company sends a trade request. A trader accepts once a price is agreed; before
## that they ask to settle the price first (or, if they have moved on, ignore it).
func request_trade(trader: String, now: int) -> String:
	if not is_trader(trader):
		return "You can only trade with someone in the Hall."
	if is_blocked(trader):
		return "You blocked %s. Unblock them to trade." % trader
	if session != null and session.is_open():
		return "Finish your trade with %s first." % session.trader
	_pm_line(trader, "system", "You sent a trade request.", [], now)
	var h: Haggle = deals.get(trader, null)
	if h != null and h.is_agreed():
		_npc_say(trader, h.say("trade_request"), h, now, 1.0, 2.0, true)
	elif h != null and h.status == "gone":
		pass
	else:
		var asker := Haggle.new()
		asker.rng = rng
		_npc_say(trader, asker.say("price_first"), h, now, 2.0, 5.0)
	return ""

## The trader's side is put in at once; the company fills its side in the trade window.
func open_trade(trader: String) -> TradeSession:
	var h: Haggle = deals.get(trader, null)
	if h == null or not h.is_agreed():
		return null
	if session != null and session.is_open():
		return null
	session = TradeSession.open_for(h)
	return session

## Any change to the company's side unlocks both sides.
func trade_changed(_gear_keys: Dictionary, _now: int) -> void:
	if session == null or not session.is_open():
		return
	session.changed()

## The company locks its side. The trader locks too if it covers the deal, or says so.
func trade_lock(gear_keys: Dictionary, now: int) -> void:
	if session == null or not session.is_open() or session.my_locked:
		return
	session.my_locked = true
	if session.covers_deal(gear_keys):
		pending.append({"at": now + rng.randi_range(1, 2), "type": "npc_lock", "trader": session.trader})
	else:
		trade_short(now)

## The company accepts. Returns false if both sides are not locked or the pause has not passed.
func trade_accept(now: int) -> bool:
	if session == null or not session.is_open() or session.accept_wait(now) != 0:
		return false
	session.my_accepted = true
	return true

func trade_cancel(now: int) -> void:
	if session == null:
		return
	var h: Haggle = session.deal
	session.status = "cancelled"
	session = null
	if h != null and h.is_agreed():
		_npc_say(h.trader, h.say("trade_cancel"), h, now, 1.0, 3.0)

## The company pressed accept with a side that does not cover the deal.
func trade_short(now: int) -> void:
	if session == null:
		return
	var h: Haggle = session.deal
	_npc_say(h.trader, h.say("short", h.agreed_qty, h.agreed_total), h, now, 1.0, 2.0)

func trade_finished(now: int) -> void:
	if session == null:
		return
	var h: Haggle = session.deal
	session.status = "done"
	session = null
	h.status = "done"
	if h.post_id >= 0:
		var post: Dictionary = message_by_id(h.post_id)
		if not post.is_empty():
			post["left"] = maxi(0, int(post["left"]) - h.agreed_qty)
	_npc_say(h.trader, h.say("trade_done"), h, now, 1.0, 3.0)

# --- The clock ----------------------------------------------------------------

## Advance the Hall to `now`: NPC chatter, posts selling out, and NPC replies and trade
## requests whose moment has come. Returns {"type": "pm" | "trade_request" | "npc_lock" | "npc_accept",
## "trader"} events for the page to react to.
func tick(now: int) -> Array:
	_npc_posts(now)
	for m in feed:
		if int(m.get("until", 0)) > 0 and now >= int(m["until"]) and int(m["left"]) > 0:
			m["left"] = 0
	var events: Array = []
	var still: Array = []
	for p in pending:
		if int(p["at"]) > now:
			still.append(p)
			continue
		var trader: String = str(p["trader"])
		if is_blocked(trader):
			continue
		match str(p["type"]):
			"pm":
				_pm_line(trader, trader, str(p["text"]), p.get("links", []), int(p["at"]))
				events.append({"type": "pm", "trader": trader})
			"trade_request":
				if open_trade(trader) != null:
					events.append({"type": "trade_request", "trader": trader})
			"npc_lock":
				if session != null and session.is_open() and session.trader == trader and session.my_locked:
					session.their_locked = true
					session.locked_at = int(p["at"])
					still.append({"at": int(p["at"]) + TradeSession.ACCEPT_DELAY + rng.randi_range(0, 1), "type": "npc_accept", "trader": trader})
					events.append({"type": "npc_lock", "trader": trader})
			"npc_accept":
				if session != null and session.is_open() and session.trader == trader and session.accept_wait(int(p["at"])) == 0:
					session.their_accepted = true
					events.append({"type": "npc_accept", "trader": trader})
	pending = still
	return events

func _npc_posts(now: int) -> void:
	# After a long absence only the last few minutes of chatter are shown.
	if next_post_at < now - 300:
		next_post_at = now - 300
	# Never backfill behind the newest line (such as the company's own post).
	if not feed.is_empty() and next_post_at <= int(feed.back()["t"]):
		next_post_at = int(feed.back()["t"]) + rng.randi_range(POST_GAP_MIN, POST_GAP_MAX)
	while next_post_at <= now:
		_post(_npc_message(next_post_at))
		next_post_at += rng.randi_range(POST_GAP_MIN, POST_GAP_MAX)

func _npc_message(t: int) -> Dictionary:
	var trader: Dictionary = TRADERS[rng.randi_range(0, TRADERS.size() - 1)]
	var kind: String = str(trader["kind"])
	var option: Array = _weighted(KIND_POSTS[kind])
	var side: String = str(option[0])
	var good: String
	var qty: int
	if side == "wts" and rng.randf() < GEAR_POST_CHANCE:
		var keys: Array = MercsV05.ITEMS.keys()
		good = "gear:" + str(keys[rng.randi_range(0, keys.size() - 1)])
		qty = 1
	else:
		good = _pick_good(kind == "collector")
		var span: Array = GOOD_QTY.get(good, [1, 10])
		qty = rng.randi_range(int(span[0]), int(span[1]))
		if kind == "quartermaster":
			qty *= 2
		if qty >= 10:
			qty = maxi(5, int(round(float(qty) / 5.0)) * 5)
	var ratio: float = rng.randf_range(float(option[1]), float(option[2]))
	var price: int = maxi(1, int(round(fair(good, t) * ratio)))
	return {"t": t, "from": str(trader["name"]), "kind": kind, "side": side, "good": good,
		"qty": qty, "price": price, "offer": kind == "haggler", "left": qty,
		"until": t + rng.randi_range(180, 1200)}

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
	for key in ["offer", "left", "until", "text", "links", "good", "qty", "price", "kind"]:
		if not message.has(key):
			message[key] = {"offer": false, "left": int(message.get("qty", 0)), "until": 0, "text": "", "links": [], "good": "", "qty": 0, "price": 0, "kind": ""}[key]
	feed.append(message)
	while feed.size() > FEED_LIMIT:
		feed.pop_front()
