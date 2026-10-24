extends SceneTree
## Gear of the fallen: drop odds, private shares, reshuffles, expiry, finds and the trip home.
## Uses an in-memory company (never touches the save file).
var failures: int = 0

func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error("Fallen gear check failed: " + what)

func _initialize() -> void:
	MoneyMercsState.persist = false
	var now: int = 1_800_000_000
	GameClock.fixed = now
	# Shares are private, a small slice of the pool, and reshuffle each day.
	var a := FallenGear.new()
	var b := FallenGear.new()
	a.player = 11
	b.player = 22
	var pool: int = a.size("harlow", now)
	check(pool > 400 and pool < 800, "Harlow pool holds hundreds of items (%d)" % pool)
	var share_a: Array = _uids(a.share("harlow", now))
	var share_b: Array = _uids(b.share("harlow", now))
	check(share_a.size() > 0 and share_a.size() < 20, "share is a handful (%d)" % share_a.size())
	check(share_a != share_b, "two players see different shares")
	var tomorrow: Array = _uids(a.share("harlow", now + FallenGear.RESHUFFLE))
	check(tomorrow != share_a, "share reshuffles after a day")
	# Averaged over many players: about 1.25% of a pool, minus what others took.
	var seen: int = 0
	for p in range(300):
		var f := FallenGear.new()
		f.player = 1000 + p
		seen += f.share("harlow", now).size()
	var avg: float = float(seen) / 300.0
	check(avg > 3.5 and avg < 8.0, "average Harlow share about six (%.1f)" % avg)
	# Deaths: 40% leave 1-3 pieces.
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var dropped: int = 0
	var pieces: int = 0
	for i in range(2000):
		var f := FallenGear.new()
		var left: Array[String] = f.drop_from_death("old_oakwood", ["steel_sword", "chainmail", "hand_axe"], "Tester", now, rng)
		if not left.is_empty():
			dropped += 1
			pieces += left.size()
			check(left.size() >= 1 and left.size() <= 3, "1-3 pieces per drop")
	check(dropped > 700 and dropped < 900, "about 40% of deaths drop gear (%d of 2000)" % dropped)
	check(float(pieces) / float(dropped) > 1.6, "drops average about two pieces")
	# Own drops expire after 24 hours.
	var own := FallenGear.new()
	own.drop("mossward_copse", "felling_axe", "Brann", now)
	check(own.size("mossward_copse", now + 10) == own.size("mossward_copse", now + 10), "size is stable")
	var with_drop: int = own.drops.size()
	own.prune(now + FallenGear.LIFETIME + 1)
	check(own.drops.size() == with_drop - 1, "own drop expires after a day")
	# Finds claim items: they leave the share at once.
	var finder := FallenGear.new()
	finder.player = 11
	var found: Array[Dictionary] = []
	for attempt in range(40):
		var r := RandomNumberGenerator.new()
		r.seed = attempt
		found = finder.roll_finds("harlow", "Deep Push", now, r)
		if not found.is_empty():
			break
	check(not found.is_empty(), "Deep Push finds something eventually")
	check(found.size() <= FallenGear.MAX_FINDS, "at most two finds")
	if not found.is_empty():
		check(not _uids(finder.share("harlow", now)).has(str(found[0]["uid"])), "a found item leaves the share")
	# The trip home: a living finder brings it to the storeroom, a dead finder drops it.
	var g := MoneyMercsState.new()
	g.reset_company()
	var key: String = "knights_blade"
	var events: Array = []
	var names: Array = []
	var trip := {"finish": now, "finds": [{"uid": "x1", "key": key, "from": "Aldo of the Red Wolves", "finder": "m1"}]}
	var value: int = g._settle_finds(trip, "harlow", [], events, names)
	check(g.equipment_inventory.size() == 1 and str(g.equipment_inventory[0]["key"]) == key, "living finder brings it home")
	check(value == int(1100 * 0.65), "find value counted in the report")
	check(str(events[0]).contains("Knight's Blade"), "report names the find")
	var lost_trip := {"finish": now, "finds": [{"uid": "x2", "key": key, "from": "", "finder": "m1"}]}
	var drops_before: int = g.fallen.drops.size()
	g._settle_finds(lost_trip, "harlow", ["m1"], events, names)
	check(g.equipment_inventory.size() == 1, "dead finder brings nothing home")
	check(g.fallen.drops.size() == drops_before + 1 and str(g.fallen.drops.back()["key"]) == key, "lost find goes back to the pool")
	# Found-only gear is never sold.
	check(not MercsV05.shop_keys().has("knights_blade"), "rare gear not in the shop")
	g.gold = 99999
	check(g.buy_equipment("gilded_plate").contains("can't be bought"), "rare gear can't be bought")
	# Save round trip.
	var copy := FallenGear.new()
	copy.load_dict(JSON.parse_string(JSON.stringify(g.fallen.to_dict())))
	check(copy.player == g.fallen.player and copy.drops.size() == g.fallen.drops.size(), "pool survives save and load")
	GameClock.fixed = -1
	if failures > 0:
		push_error("%d fallen gear checks failed." % failures)
		quit(1)
		return
	print("Fallen gear pool, shares, finds and the trip home passed.")
	quit(0)

func _uids(items: Array) -> Array:
	var out: Array = []
	for item in items:
		out.append(str(item["uid"]))
	return out
