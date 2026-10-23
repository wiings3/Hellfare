extends RefCounted
class_name TradeSession
## One open trade window between the company and an NPC trader.
##
## The NPC puts in their side of the agreed deal. The player puts in their side by hand:
## goods from the warehouse, spare gear and gold.
##
## Two-step confirm, against last-second swaps:
## 1. Each side locks its offer. A locked side cannot be edited until it is unlocked.
## 2. Once both are locked, and after ACCEPT_DELAY seconds, each side may accept.
##    The trade goes through when both have accepted.
## Any change to either side (including unlocking) clears every lock and acceptance.
## The NPC locks only when the player's side covers the deal. The company applies the
## trade (see CompanyStateBase.trade_*).

const ACCEPT_DELAY := 2

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
var my_locked: bool = false
var their_locked: bool = false
var my_accepted: bool = false
var their_accepted: bool = false
## When the second side locked; accepting opens ACCEPT_DELAY seconds later.
var locked_at: int = 0
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
	my_locked = false
	their_locked = false
	my_accepted = false
	their_accepted = false
	locked_at = 0

func both_locked() -> bool:
	return my_locked and their_locked

## Seconds until accepting opens, or -1 while either side is unlocked.
func accept_wait(now: int) -> int:
	if not both_locked():
		return -1
	return maxi(0, locked_at + ACCEPT_DELAY - now)

func both_accepted() -> bool:
	return my_accepted and their_accepted

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
