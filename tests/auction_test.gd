extends SceneTree
## The Auction House: NPC listings and orders, posting, selling over time (open or closed),
## buy orders, fees, expiry and saving (in-memory company, no save file).
var failures: int = 0

func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error("Auction check failed: " + what)

func _initialize() -> void:
	MoneyMercsState.persist = false
	var now: int = 1_900_000_000
	GameClock.fixed = now
	var g := MoneyMercsState.new()
	g.reset_company()
	g.gold = 5000
	# NPC listings: common goods always have sellers, deterministic for the window.
	var timber: Array = g.ah_listings_for("timber")
	check(not timber.is_empty(), "timber is listed")
	check(timber == g.ah_listings_for("timber"), "listings are the same on every call")
	check(int(timber[0]["price"]) <= int(timber.back()["price"]), "cheapest first")
	# Buying from a listing.
	var first: Dictionary = timber[0]
	var gold0: int = g.gold
	check(g.ah_buy(str(first["uid"]), 3).begins_with("Bought 3"), "buy goods from a listing")
	check(int(g.resources["timber"]) == 3 and g.gold == gold0 - 3 * int(first["price"]), "goods arrive and gold is paid")
	var again: Array = g.ah_listings_for("timber")
	var same: Array = again.filter(func(l): return str(l["uid"]) == str(first["uid"]))
	check(same.is_empty() or int(same[0]["left"]) == int(first["left"]) - 3, "bought units leave the listing")
	# Gear listings carry their rolled piece.
	var found_gear: bool = false
	for t in range(12):
		var swords: Array = g.auction.npc_listings("gear:steel_sword", g.ah_fair("gear:steel_sword"), now + t * AuctionHouse.EPOCH)
		if not swords.is_empty():
			found_gear = swords[0].has("item")
			break
	check(found_gear, "steel swords turn up with a rolled piece")
	# Posting: fee paid, goods held, sells over time with the game closed.
	g.resources["timber"] = 240
	var plan: Dictionary = g.ah_forecast("timber", 200, int(round(g.ah_fair("timber"))), "1d")
	check(float(plan["hours"]) > 0.0 and int(plan["fee"]) >= 1 and int(plan["take"]) > 0, "forecast gives time, fee and take")
	var price: int = maxi(1, int(round(g.ah_fair("timber"))))
	gold0 = g.gold
	check(g.ah_post("timber", 200, price, "1d").begins_with("Listed 200"), "post a listing")
	check(int(g.resources["timber"]) == 40 and g.gold < gold0, "goods held, fee paid")
	var worth_listed: int = g.auction_value()
	check(worth_listed > 0, "listed goods still count toward worth")
	var listing: Dictionary = g.auction.listings[0]
	g.complete_due(now + 3600 * 6)
	check(int(listing["left"]) < 200 and g.auction.log.size() > 0, "some sold within six hours (%d left)" % int(listing["left"]))
	# The same result whether ticked often or once.
	var h := MoneyMercsState.new()
	h.reset_company()
	h.gold = 5000
	h.resources["timber"] = 240
	h.ah_post("timber", 200, price, "1d")
	h.auction.listings[0]["seed"] = int(listing["seed"])
	h.auction.listings[0]["started"] = int(listing["started"])
	h.auction.listings[0]["last"] = int(listing["started"])
	for step in range(36):
		h.complete_due(now + 600 * (step + 1))
	check(int(h.auction.listings[0]["left"]) == int(listing["left"]) if not h.auction.listings.is_empty() else int(listing["left"]) == 0 or g.auction.listings.is_empty(), "ticking often or once gives the same sales")
	# An overpriced listing sells slowly and comes back when it ends.
	g.resources["iron"] = 30
	g.ah_post("iron", 30, int(g.ah_fair("iron") * 3.0), "12h")
	var gold6: int = g.gold
	g.complete_due(now + 86400 * 3)
	check(g.auction.listings.is_empty(), "listings end")
	check(int(g.resources["iron"]) > 0, "unsold goods come back")
	check(g.auction.log.any(func(e): return str(e["kind"]) == "expired"), "expiry is logged")
	check(g.gold >= gold6, "sales paid out")
	# Buy orders: gold held, goods arrive, the rest refunded when it ends.
	GameClock.fixed = now + 86400 * 3
	var t3: int = now + 86400 * 3
	gold0 = g.gold
	var silk_price: int = int(round(g.ah_fair("spider_silk") * 1.1))
	check(g.ah_order("spider_silk", 10, silk_price, "1d").begins_with("Buy order up"), "post a buy order")
	check(g.gold == gold0 - 10 * silk_price, "order gold held")
	g.complete_due(t3 + 86400 + 1)
	check(g.auction.orders.is_empty(), "order ended or filled")
	var spent: int = gold0 - g.gold
	check(spent == int(g.resources.get("spider_silk", 0)) * silk_price, "paid only for what arrived (%d G for %d)" % [spent, int(g.resources.get("spider_silk", 0))])
	# Limits and gear listings.
	g.equipment_inventory.append(g.make_item("hand_axe", "common"))
	check(g.ah_post("gear:hand_axe", 1, 40, "12h").begins_with("Listed"), "list a spare piece")
	check(g.equipment_inventory.filter(func(i): return str(i["key"]) == "hand_axe").is_empty(), "the piece leaves the storeroom")
	check(g.ah_cancel_listing(int(g.auction.listings[0]["id"])).begins_with("Took down"), "cancel a listing")
	check(not g.equipment_inventory.filter(func(i): return str(i["key"]) == "hand_axe").is_empty(), "the piece comes back")
	# Save round trip.
	g.resources["timber"] = 50
	g.ah_post("timber", 50, 9, "2d")
	var data: Dictionary = JSON.parse_string(JSON.stringify(g.auction.to_dict()))
	var b := AuctionHouse.new()
	b.load_dict(data)
	check(b.listings.size() == 1 and int(b.listings[0]["left"]) == 50, "listings survive a save")
	GameClock.fixed = -1
	if failures > 0:
		push_error("%d auction checks failed." % failures)
		quit(1)
		return
	print("Auction House checks passed.")
	quit(0)
