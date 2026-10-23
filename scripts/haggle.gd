extends RefCounted
class_name Haggle
## One private-message negotiation with an NPC trader about one item (a good or a piece
## of gear). Offers are for a whole lot ("40 for 185g?"), so cheap goods can be haggled.
## Status: "open" while talking, "agreed" once a price is settled (the trade window then
## completes it), "done" after the trade, "gone" when they walked away.
##
## Every trader has a hidden walk-away price per unit (their "reservation") and limited
## patience.
## - When they sell, they will not go below the reservation; when they buy, not above it.
## - Each counter moves part of the way from their current price towards the reservation.
##   Once they reach it, they say it is their last price.
## - A lowball offer (25% or more past the reservation) costs two patience instead of one.
##   When patience runs out they walk away.
## How far each kind will move, and how patient it is, comes from KINDS below.

## flex: share of the posted price they will give up. step: share of the remaining gap
## they concede per counter. patience: offers they will hear before walking away.
const KINDS := {
	"hawker": {"flex": 0.06, "step": 0.5, "patience": 3},
	"bargain": {"flex": 0.03, "step": 0.5, "patience": 2},
	"flipper": {"flex": 0.05, "step": 0.4, "patience": 3},
	"haggler": {"flex": 0.16, "step": 0.35, "patience": 5},
	"quartermaster": {"flex": 0.06, "step": 0.5, "patience": 3},
	"collector": {"flex": 0.10, "step": 0.45, "patience": 4},
}
const INSULT := 0.25

## Lines per moment, by kind ("any" is the fallback). {total} is gold for the lot, {each}
## the unit price, {qty} the quantity, and {item} becomes a hoverable item link.
const LINES := {
	"greet_sell": {
		"hawker": ["Still got them. {qty} at {each}g each, fair and square.", "They're yours at {each}g each."],
		"bargain": ["Priced to go. {each}g each, no fuss."],
		"flipper": ["{each}g each. Bought them cheap, not selling them cheap."],
		"haggler": ["A customer! {each}g each, but go on, make me an offer.", "{each}g each. Everything's negotiable."],
		"any": ["Selling at {each}g each. How many do you want?"],
	},
	"greet_buy": {
		"quartermaster": ["The garrison needs it. {each}g each, up to {qty}."],
		"collector": ["I pay well for quality. {each}g each."],
		"flipper": ["{each}g each. Take it or leave it."],
		"haggler": ["I'll pay {each}g each. We can talk."],
		"any": ["Buying at {each}g each. How many have you got?"],
	},
	"counter": {
		"haggler": ["Ha! You wound me. {total}g, and that's generous.", "Let's meet in the middle. {total}g?", "I like you. {total}g for {qty}."],
		"collector": ["Quality costs. I could do {total}g."],
		"flipper": ["Margins are thin. {total}g."],
		"any": ["Can't do that. {total}g for {qty}?", "Meet me at {total}g?", "How about {total}g for the lot?"],
	},
	"final": {
		"haggler": ["{total}g. Any further and I'm robbing myself."],
		"any": ["{total}g is my last price.", "{total}g for {qty}. That's my best."],
	},
	"accept": {
		"haggler": ["Done! You drive a hard bargain."],
		"any": ["Deal.", "Done. Pleasure doing business.", "Fair enough. Deal."],
	},
	"insult": {
		"haggler": ["Now you're just being rude. {total}g."],
		"any": ["Is that a joke? {total}g.", "Don't waste my time. {total}g."],
	},
	"leave": {
		"any": ["Forget it. Good luck.", "I'll find someone else.", "We're done here."],
	},
	"gone": {
		"any": ["Sorry, sold it already.", "Gone, sorry. Someone beat you to it."],
	},
	"quote": {
		"haggler": ["{each}g each, {total}g for {qty}. Make me an offer."],
		"any": ["{total}g for {qty}.", "{each}g each. {total}g for {qty}."],
	},
	"quote_one": {
		"any": ["{total}g for it.", "{total}g, it's a good one."],
	},
	"interested_sell": {
		"quartermaster": ["Saw your {item}. I'll give {total}g for {qty}."],
		"collector": ["Your {item} caught my eye. {total}g for {qty}?"],
		"flipper": ["{total}g for {qty} of your {item}, right now?"],
		"any": ["Still got the {item}? {total}g for {qty}?", "Interested in your {item}. {total}g for {qty}?"],
	},
	"take_yours": {
		"any": ["I'll take {qty} {item} at your price. {total}g, deal?", "Your {item}, {qty} for {total}g like you posted? I'm in."],
	},
	"how_much": {
		"any": ["How much for the {item}?", "Price on the {item}?", "What do you want for the {item}?"],
	},
	"interested_buy": {
		"bargain": ["Got {qty} {item}, {total}g and they're yours."],
		"any": ["I have {qty} {item}. {total}g?", "Saw your post. {qty} {item} for {total}g?"],
	},
	"trade_request": {
		"any": ["Sending you a trade request.", "Sending the trade now.", "Trade incoming."],
	},
	"short": {
		"any": ["That's short. We said {qty} for {total}g.", "Not what we agreed: {qty} for {total}g."],
	},
	"trade_done": {
		"any": ["Pleasure doing business.", "Good trade. Safe travels.", "Thanks!"],
	},
	"trade_cancel": {
		"any": ["Changed your mind? Say \"trade\" if you want it.", "No trade then?"],
	},
	"what": {
		"any": ["What are you after?", "Hm? What do you need?"],
	},
	"decline_ok": {
		"any": ["No worries.", "Alright, another time.", "Fair enough."],
	},
	"no_more": {
		"any": ["I said we're done.", "Not interested anymore."],
	},
}

var trader: String = ""
var kind: String = "hawker"
var good: String = ""
## True when the trader is selling to the company (a WTS post).
var they_sell: bool = true
var post_id: int = -1
var listing_id: int = -1
var qty_max: int = 0
## The price per unit in the original post or offer.
var posted: int = 0
## The trader's current price per unit, and the most they will give.
var ask: float = 0.0
var reservation: float = 0.0
var patience: int = 3
var status: String = "open"
var rng: RandomNumberGenerator
## Settled terms once both sides agree.
var agreed_qty: int = 0
var agreed_total: int = 0
## Display name of the item, used in lines as [Name].
var item_name: String = ""

static func make(trader_name: String, trader_kind: String, good_key: String, selling: bool, quantity: int, price: int, fair: float, random: RandomNumberGenerator) -> Haggle:
	var h := Haggle.new()
	h.trader = trader_name
	h.kind = trader_kind if KINDS.has(trader_kind) else "hawker"
	h.good = good_key
	h.they_sell = selling
	h.qty_max = quantity
	h.ask = float(price)
	h.posted = price
	h.rng = random
	var k: Dictionary = KINDS[h.kind]
	h.patience = int(k["patience"])
	var flex: float = float(k["flex"])
	if selling:
		h.reservation = minf(float(price), maxf(float(price) * (1.0 - flex), fair * 0.8))
	else:
		h.reservation = maxf(float(price), minf(float(price) * (1.0 + flex), fair * 1.3))
	return h

func is_open() -> bool:
	return status == "open"

func is_agreed() -> bool:
	return status == "agreed"

func _agree(qty: int, total: int) -> void:
	status = "agreed"
	agreed_qty = qty
	agreed_total = total

## Their current price for `qty` units, in whole gold (rounded in their favour).
func quote(qty: int) -> int:
	return _total(ask, qty)

## Their limit for `qty` units: the least they would sell for, or the most they would pay.
func limit(qty: int) -> int:
	return _total(reservation, qty)

func _total(unit: float, qty: int) -> int:
	var raw: float = unit * float(qty)
	return maxi(1, int(ceil(raw - 0.001)) if they_sell else int(floor(raw + 0.001)))

## The player offers `total` gold for `qty`. Returns {"result": accept|counter|final|leave,
## "total", "line"}. "accept" means the deal stands at the player's total.
func offer(qty: int, total: int) -> Dictionary:
	if not is_open():
		return {"result": "leave", "total": quote(qty), "line": say("leave", qty)}
	var acceptable: bool = total >= limit(qty) if they_sell else total <= limit(qty)
	if acceptable:
		_agree(qty, total)
		return {"result": "accept", "total": total, "line": say("accept", qty, total)}
	var unit: float = float(total) / float(maxi(qty, 1))
	var insulting: bool = unit < reservation * (1.0 - INSULT) if they_sell else unit > reservation / (1.0 - INSULT)
	patience -= 2 if insulting else 1
	if patience <= 0:
		status = "gone"
		return {"result": "leave", "total": quote(qty), "line": say("leave", qty)}
	ask += (reservation - ask) * float(KINDS[kind]["step"])
	if absf(ask - reservation) * float(qty) < 1.0:
		ask = reservation
	var final: bool = is_equal_approx(ask, reservation)
	var moment: String = "insult" if insulting else ("final" if final else "counter")
	return {"result": "final" if final else "counter", "total": quote(qty), "line": say(moment, qty)}

## The player takes the trader's current price for `qty`.
func take(qty: int) -> Dictionary:
	if not is_open():
		return {"result": "leave", "total": quote(qty), "line": say("leave", qty)}
	_agree(qty, quote(qty))
	return {"result": "accept", "total": quote(qty), "line": say("accept", qty)}

func walk_away() -> void:
	status = "gone"

## A line of dialogue for a moment, in this trader's voice.
func say(moment: String, qty: int = -1, total: int = -1) -> String:
	var n: int = qty if qty > 0 else qty_max
	var table: Dictionary = LINES.get(moment, {})
	var options: Array = table.get(kind, table.get("any", [""]))
	var line: String = str(options[rng.randi_range(0, options.size() - 1)]) if rng != null else str(options[0])
	var each: String = str(int(round(ask))) if is_equal_approx(ask, round(ask)) else "%.1f" % ask
	var named: String = "[%s]" % item_name if item_name != "" else "it"
	return line.replace("{total}", str(total if total >= 0 else quote(n))).replace("{qty}", str(n)).replace("{each}", each).replace("{item}", named)
