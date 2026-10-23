extends RefCounted
class_name TradeSession
## One open trade window between the company and an NPC trader.
##
## The NPC puts in their side of the agreed deal. The player puts in their side by hand:
## goods from the warehouse, spare gear and gold. Any change clears both "ready" marks.
## The NPC marks ready only when the player's side covers the deal; the trade goes through
## when both sides are ready. The company applies it (see CompanyStateBase.trade_*).

var trader: String = ""
var deal: Haggle
## good -> quantity, gear uids, gold: what the company puts in.
var mine_goods: Dictionary = {}
var mine_gear: Array = []
var mine_gold: int = 0
## good -> quantity, gear item keys, gold: what the trader puts in.
var their_goods: Dictionary = {}
var their_gear: Array = []
var their_gold: int = 0
var my_ready: bool = false
var their_ready: bool = false
## "open", "done" or "cancelled".
var status: String = "open"

static func open_for(h: Haggle) -> TradeSession:
	var s := TradeSession.new()
	s.trader = h.trader
	s.deal = h
	if h.they_sell:
		if h.good.begins_with("gear:"):
			for i in range(h.agreed_qty):
				s.their_gear.append(h.good.substr(5))
		else:
			s.their_goods[h.good] = h.agreed_qty
	else:
		s.their_gold = h.agreed_total
	return s

func is_open() -> bool:
	return status == "open"

func changed() -> void:
	my_ready = false
	their_ready = false

## Does the company's side cover what was agreed?
func covers_deal(gear_keys: Dictionary) -> bool:
	if deal.they_sell:
		return mine_gold >= deal.agreed_total
	if deal.good.begins_with("gear:"):
		var key: String = deal.good.substr(5)
		var count: int = 0
		for uid in mine_gear:
			if str(gear_keys.get(uid, "")) == key:
				count += 1
		return count >= deal.agreed_qty
	return int(mine_goods.get(deal.good, 0)) >= deal.agreed_qty

func is_empty_mine() -> bool:
	return mine_goods.is_empty() and mine_gear.is_empty() and mine_gold <= 0
