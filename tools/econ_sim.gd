extends SceneTree
## Economy simulator. Plays the real game rules (MoneyMercsState, TradeHall, sites,
## regional contracts, merchants) with scripted player strategies, fast-forwarding
## the clock (GameClock.fixed). Nothing is read from or written to the save file.
##
## Usage (from the project root):
##   godot --headless -s tools/econ_sim.gd -- hours=150 seeds=4 out=/tmp/sim.json [only=logging]
##
## Strategies:
##   logging        woodcutters only, sell everything to the merchants
##   logging_hall   woodcutters, sell through Trade Hall posts and messages, merchants as fallback
##   miner          miners at Harlow Mines, then Deepdelve from Mining 8; Trade Hall
##   contracts      the older regional contracts, climbing to the best region reputation allows
##   lowlands       the older regional contracts, staying on Mossward Lowlands
##   hall_trader    no crew: buy cheap posts and resell in the Trade Hall
##   casual         logging on Long Shift; the player only checks in for a minute every 30 minutes
##   minimal        the least the game needs: one woodcutter at the Copse, merchants only, nothing else
##   everything     one slot mining, the rest logging, Trade Hall, and wears gear found among the
##                  fallen when it's an upgrade
##   evening        "everything" for two hours a day; Full Day trips sent out before logging off
##   idle           checks in for a minute three times a day; Overnight logging
##   forager, angler, hunter, farmer
##                  one of the newer trades only, every site it can reach, merchants only;
##                  the farmer builds the farm buildings once it can spare three times their cost
## Every strategy except minimal expands expedition slots and buys tools when it can afford them.
## Hours are hours since the company started (crews keep working while the game is closed).
## While the player is away the clock jumps ahead to the next return or check-in.

const STEP := 10
const SAMPLE := 900
const MILESTONES := [1000, 10000, 100000, 1000000, 10000000]
const CHECKPOINTS := [10, 100, 1000, 3000, 12000]
const ALL := ["minimal", "logging", "logging_hall", "miner", "everything", "hall_trader", "contracts", "casual", "evening", "idle", "forager", "angler", "hunter", "farmer"]
## The newer trades' strategies: trade, job name and the shop tool.
const NEW_TRADES := {"forager": ["foraging", "Forager", "copper_sickle"], "angler": ["fishing", "Angler", "birch_rod"],
	"hunter": ["hunting", "Hunter", "birch_shortbow"], "farmer": ["farming", "Farmhand", "iron_hoe"]}

var hours: float = 150.0
var seeds: int = 4
var out_path: String = ""
var only: String = ""
## First seed index, so seeds can be split across processes.
var first: int = 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		var kv: PackedStringArray = arg.split("=")
		if kv.size() != 2:
			continue
		match kv[0]:
			"hours": hours = float(kv[1])
			"seeds": seeds = int(kv[1])
			"out": out_path = kv[1]
			"only": only = kv[1]
			"first": first = int(kv[1])
	MoneyMercsState.persist = false
	var results: Array = []
	var strategies: Array = ["logging", "logging_hall", "miner", "everything", "casual"]
	if only != "":
		strategies = ALL + ["lowlands"]
	for strategy in strategies:
		if only != "" and not only.split(",").has(strategy):
			continue
		for s in range(first, first + seeds):
			var started: int = Time.get_ticks_msec()
			var r: Dictionary = run(strategy, 1000 + s * 17)
			r["runtime_ms"] = Time.get_ticks_msec() - started
			results.append(r)
			print("%-13s seed %d  worth %8d  1k %6s  10k %6s  100k %6s  deaths %d  finds %d (%d G, %d rare, first rare %s)  (%d ms)" % [strategy, s, int(r["final_worth"]),
				_h(r["milestones"].get("1000", -1)), _h(r["milestones"].get("10000", -1)), _h(r["milestones"].get("100000", -1)),
				int(r["deaths"]), int(r.get("finds", 0)), int(r.get("find_value", 0)), int(r.get("rare_finds", 0)), _h(r.get("first_rare_h", -1)), int(r["runtime_ms"])])
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		f.store_string(JSON.stringify(results))
		f.close()
	GameClock.fixed = -1
	quit()

func _h(v: Variant) -> String:
	return "-" if float(v) < 0.0 else "%.1fh" % float(v)

# --- One run ----------------------------------------------------------------------

var g: MoneyMercsState
var t: int = 0
var t0: int = 0
var rec: Dictionary = {}
var strategy: String = ""
var counters: Dictionary = {}
var dispatched: Dictionary = {}
var sample_every: int = SAMPLE
var next_checkpoint: int = 0

func run(name: String, seed_value: int) -> Dictionary:
	strategy = name
	seed(seed_value)
	t0 = 1_900_000_000 + seed_value * 3613
	t = t0
	GameClock.fixed = t
	g = MoneyMercsState.new()
	g.reset_company()
	g.hall.rng.seed = seed_value
	counters = {"pm_counters": {}, "last_post": 0, "held_since": {}}
	dispatched = {}
	rec = {
		"strategy": name, "seed": seed_value, "hours": hours, "samples": [], "milestones": {},
		"income": {}, "trips": {}, "deaths": 0, "hires": 0, "hire_spend": 0, "gear_spend": 0,
		"merchant_sales": 0, "merchant_units": 0, "hall_sales": 0, "hall_units": 0, "hall_buys": 0,
		"hall_trades": 0, "tax_paid": 0, "slots": [], "levels": [], "treat_spend": 0, "repair_spend": 0, "repairs": 0, "wages": 0,
		"active_s": 0, "checkpoints": {}, "no_recruit": 0, "finds": 0, "find_value": 0, "rare_finds": 0,
		"slot_busy_s": 0, "slot_s": 0, "costs": 0,
	}
	next_checkpoint = 0
	sample_every = maxi(SAMPLE, int(hours * 3600.0 / 4000.0))
	var end: int = t0 + int(hours * 3600.0)
	var next_sample: int = t0
	while t <= end:
		GameClock.fixed = t
		_settle()
		var active: bool = _active()
		if active:
			_policy()
		if t >= next_sample:
			_sample()
			next_sample += sample_every
		var step: int = STEP
		if not active:
			# Away from the keyboard: jump to the next return, check-in or sample.
			var wake: int = mini(_next_active(), next_sample)
			for m in g.missions:
				wake = mini(wake, int(m["finish"]))
			step = clampi(wake - t, STEP, 6 * 3600)
		else:
			rec["active_s"] = int(rec["active_s"]) + STEP
		rec["slot_busy_s"] = int(rec["slot_busy_s"]) + g.missions.size() * step
		rec["slot_s"] = int(rec["slot_s"]) + g.expedition_slots * step
		t += step
	_checkpoint(int(hours))
	rec["final_worth"] = g.wealth()
	rec["final_gold"] = g.gold
	rec["crew"] = g.crew.size()
	rec["slots_final"] = g.expedition_slots
	return rec

func _elapsed_h() -> float:
	return float(t - t0) / 3600.0

## Is the player at the keyboard? Casual players check in for a minute every 30 minutes,
## evening players play two hours a day, idle players look in three times a day.
func _active() -> bool:
	var e: int = t - t0
	match strategy:
		"casual": return e % 1800 < 60
		"evening": return e % 86400 < 7200
		"idle": return e % 28800 < 60
	return true

## When the player next sits down (only asked while they are away).
func _next_active() -> int:
	var e: int = t - t0
	var period: int = 1800
	match strategy:
		"evening": period = 86400
		"idle": period = 28800
		"casual": period = 1800
		_: return t + STEP
	return t0 + (int(e / period) + 1) * period

## Evening players send everyone on Long Shift in the last 15 minutes before logging off.
func _leaving() -> bool:
	return strategy == "evening" and (t - t0) % 86400 >= 7200 - 900

func _sample() -> void:
	var w: int = g.wealth()
	var best_level: int = 0
	for merc in g.crew:
		best_level = maxi(best_level, TradeSkills.level_of(merc, _trade()))
	(rec["samples"] as Array).append({"h": snappedf(_elapsed_h(), 0.01), "worth": w, "gold": g.gold, "crew": g.crew.size(), "slots": g.expedition_slots, "level": best_level})
	for m in MILESTONES:
		if w >= m and not (rec["milestones"] as Dictionary).has(str(m)):
			rec["milestones"][str(m)] = snappedf(_elapsed_h(), 0.01)
	while next_checkpoint < CHECKPOINTS.size() and _elapsed_h() >= float(CHECKPOINTS[next_checkpoint]):
		_checkpoint(int(CHECKPOINTS[next_checkpoint]))
		next_checkpoint += 1

## Everything worth comparing at 10, 100 and 1000 hours.
func _checkpoint(h: int) -> void:
	var best: int = 0
	var levels: Array = []
	for merc in g.crew:
		var lv: int = TradeSkills.level_of(merc, _trade())
		best = maxi(best, lv)
		levels.append(lv)
	var gear: int = 0
	for merc in g.crew:
		gear += Gear.worn(merc).size()
	rec["checkpoints"][str(h)] = {
		"worth": g.wealth(), "gold": g.gold, "goods": g.goods_value(), "crew": g.crew.size(), "slots": g.expedition_slots,
		"best_level": best, "levels": levels, "gear_worn": gear, "deaths": int(rec["deaths"]),
		"income": (rec["income"] as Dictionary).duplicate(), "trips": (rec["trips"] as Dictionary).duplicate(),
		"merchant_sales": int(rec["merchant_sales"]), "hall_sales": int(rec["hall_sales"]), "hall_buys": int(rec["hall_buys"]),
		"tax_paid": int(rec["tax_paid"]), "hire_spend": int(rec["hire_spend"]), "gear_spend": int(rec["gear_spend"]),
		"treat_spend": int(rec["treat_spend"]), "repair_spend": int(rec["repair_spend"]), "repairs": int(rec["repairs"]), "finds": int(rec["finds"]), "find_value": int(rec["find_value"]),
		"rare_finds": int(rec["rare_finds"]), "guild_jobs": int(rec.get("guild_jobs", 0)), "no_recruit": int(rec["no_recruit"]),
		"active_h": snappedf(float(rec["active_s"]) / 3600.0, 0.1),
		"utilization": snappedf(float(rec["slot_busy_s"]) / maxf(1.0, float(rec["slot_s"])), 0.001),
		"relief": g.relief_count, "reputation": g.reputation, "board": g.recruitment_board().size(),
	}

func _trade() -> String:
	if NEW_TRADES.has(strategy):
		return str(NEW_TRADES[strategy][0])
	match strategy:
		"contracts", "miner": return "mining"
	return "logging"

func _add(key: String, amount: float) -> void:
	rec["income"][key] = float(rec["income"].get(key, 0.0)) + amount

# --- Settling expeditions and trades ----------------------------------------------

## Finish due expeditions and book what each one earned (haul at merchant value - costs).
func _settle() -> void:
	var before_reports: int = g.reports.size()
	var crew_before: int = g.crew.size()
	var done: int = g.complete_due(t)
	if done > 0:
		for i in range(mini(done, g.reports.size())):
			var r: Dictionary = g.reports[i]
			var key: String = str(r.get("site", r.get("region", "?")))
			var net: float
			if r.has("value"):
				net = float(r["value"]) - float(r.get("cost", 0))
			else:
				var goods: float = 0.0
				for good in r.get("loot", {}):
					goods += float(r["loot"][good]) * float(g.sell_price(str(good)))
				net = float(r.get("cash", 0)) - float(r.get("commission", 0)) + goods - float(r.get("cost", 0))
			_add(key, net)
			rec["trips"][key] = int(rec["trips"].get(key, 0)) + 1
			rec["deaths"] = int(rec["deaths"]) + (r.get("casualties", []) as Array).size()
			for k in r.get("found_gear", []):
				rec["finds"] = int(rec.get("finds", 0)) + 1
				rec["find_value"] = int(rec.get("find_value", 0)) + int(Catalog.value_of(str(k)) * 0.65)
				if bool(Catalog.item(str(k)).get("found_only", false)):
					rec["rare_finds"] = int(rec.get("rare_finds", 0)) + 1
					if not rec.has("first_rare_h"):
						rec["first_rare_h"] = snappedf(_elapsed_h(), 0.01)
	if strategy in ["logging_hall", "hall_trader", "everything", "evening", "miner"] or g.hall.session != null:
		var events: Array = g.hall_tick(t)
		for e in events:
			if str(e["type"]) == "trade_done":
				rec["hall_trades"] = int(rec["hall_trades"]) + 1

# --- Policies ---------------------------------------------------------------------

func _policy() -> void:
	_sell_spare_gear()
	_treat()
	_repair()
	match strategy:
		"logging", "casual": _logging(false)
		"logging_hall": _logging(true)
		"contracts": _contracts(false)
		"lowlands": _contracts(true)
		"hall_trader": _hall_trader()
		"everything": _everything()
		"miner": _miner()
		"minimal": _minimal()
		"idle": _logging(false)
		"evening": _logging(true) if _leaving() else _everything()
		"forager", "angler", "hunter", "farmer": _new_trade()
	if strategy != "minimal":
		_expand()
	_guild_fallback()

## A company too poor to send anyone out takes guild work (and records it).
func _guild_fallback() -> void:
	# Only when nothing could be sent out this turn.
	if strategy == "hall_trader" or not g.missions.is_empty() or not g.can_accept_guild_work():
		return
	var worker: String = ""
	for merc in g.crew:
		if g.is_available(merc):
			worker = str(merc["id"])
			break
	if g.start_guild_work(worker).begins_with("Guild") or worker != "":
		rec["guild_jobs"] = int(rec.get("guild_jobs", 0)) + 1
		if not rec.has("stuck_at"):
			rec["stuck_at"] = snappedf(_elapsed_h(), 0.01)

## Broke with nothing out: sell spare gear from the storeroom, as a player would.
func _sell_spare_gear() -> void:
	# Gear found among the fallen: "everything" players wear it if it's an upgrade, the rest sell it.
	for item in g.equipment_inventory.duplicate():
		if not item.has("found_from"):
			continue
		if strategy in ["everything", "evening"] and _equip_upgrade(item):
			continue
		g.sell_equipment(str(item["uid"]))
	if g.gold >= 100 or not g.missions.is_empty():
		return
	for item in g.equipment_inventory.duplicate():
		g.sell_equipment(str(item["uid"]))

## Put a found piece on the mercenary it improves most. Returns true if it was equipped.
func _equip_upgrade(item: Dictionary) -> bool:
	var key: String = str(item["key"])
	var slot: String = Gear.slot_of(key)
	if not Gear.equippable(key) or Gear.consumable(key):
		return false
	# A tool or weapon only goes to someone already doing that job.
	var d: Dictionary = Catalog.item(key)
	var job: String = str(d.get("trade", "")) if str(d.get("category", "")) == "tool" else ("combat" if str(d.get("category", "")) == "weapon" else "")
	for merc in g.crew:
		if not g.is_available(merc) or (slot == "main_hand" and Mercs.job(merc) != job):
			continue
		if int(d.get("hands", 1)) == 2 or (slot == "off_hand" and int(Catalog.item(str(Gear.in_slot(merc, "main_hand").get("key", ""))).get("hands", 1)) == 2):
			continue
		var worn: Dictionary = Gear.in_slot(merc, slot)
		var worn_cost: int = 0 if worn.is_empty() else Gear.value(worn)
		if Gear.value(item) > worn_cost and g.equip_item(str(merc["id"]), str(item["uid"])).contains(" equipped "):
			rec["equipped_finds"] = int(rec.get("equipped_finds", 0)) + 1
			return true
	return false

## Repair anything worn halfway down, if the company can spare the gold.
func _repair() -> void:
	for item in g.needs_repair():
		if Gear.durability(item) * 2 > Gear.max_durability(item):
			continue
		var cost: Dictionary = g.repair_cost(item)
		var gold_before: int = g.gold
		var value_before: int = g.goods_value()
		if g.gold < g.repair_gold(cost) + 80:
			continue
		if g.repair(str(item["uid"])).begins_with("Repaired"):
			rec["repairs"] = int(rec["repairs"]) + 1
			rec["repair_spend"] = int(rec["repair_spend"]) + (gold_before - g.gold) + maxi(0, value_before - g.goods_value())

func _treat() -> void:
	for merc in g.crew:
		if g.is_available(merc) and int(merc.get("health", 100)) < 60:
			var cost: int = MoneyMercsState.treat_cost(merc)
			if g.gold > cost + 60:
				g.treat(str(merc["id"]))
				rec["treat_spend"] = int(rec["treat_spend"]) + cost

## Sign the next expedition charter once it's allowed and affordable with a little to spare.
func _expand() -> void:
	if g.next_charter() == "" or strategy == "hall_trader":
		return
	if g.charter_block().is_empty() and g.gold >= g.expansion_cost() + 250:
		if g.expand_operations().contains("signed"):
			(rec["slots"] as Array).append({"h": snappedf(_elapsed_h(), 0.01), "slots": g.expedition_slots})

func _hire(role: String, max_count: int) -> void:
	var have: int = 0
	for merc in g.crew:
		if Mercs.role_of(merc) == role:
			have += 1
	if have >= max_count:
		return
	# The best applicant for the trade the company can comfortably afford (cheapest if none).
	var best: Dictionary = {}
	# Skills train quickly and death is permanent, so skilled recruits rarely pay for themselves
	# (600-hour runs spent ~340k on them for nothing). The bot hires the best it can get for
	# about what a green hand costs.
	var budget: int = 150
	for c in g.recruitment_board():
		if Mercs.role_of(c) != role:
			continue
		if best.is_empty():
			best = c
			continue
		var fits: bool = int(c["hire"]) <= budget
		var best_fits: bool = int(best["hire"]) <= budget
		if fits and (not best_fits or Mercs.best_level(c) > Mercs.best_level(best) or (Mercs.best_level(c) == Mercs.best_level(best) and int(c["hire"]) < int(best["hire"]))):
			best = c
		elif not fits and not best_fits and int(c["hire"]) < int(best["hire"]):
			best = c
	if best.is_empty():
		rec["no_recruit"] = int(rec["no_recruit"]) + 1
		return
	if g.gold < int(best["hire"]) + 40:
		return
	var said: String = g.hire(str(best["id"]))
	if said.ends_with("joined your company.") or said.contains("is yours"):
		rec["hires"] = int(rec["hires"]) + 1
		rec["hire_spend"] = int(rec["hire_spend"]) + int(best["hire"])

## Buy and fit the best affordable tool for a role.
func _outfit(role: String, keys: Array) -> void:
	for merc in g.crew:
		if Mercs.role_of(merc) != role or not g.is_available(merc):
			continue
		var tool: Dictionary = Gear.in_slot(merc, "main_hand")
		var current: int = keys.find(str(tool.get("key", "")))
		var worn_cost: int = 0 if tool.is_empty() else Gear.value(tool)
		for i in range(keys.size() - 1, current, -1):
			var key: String = str(keys[i])
			var cost: int = int(Catalog.item(key)["value"])
			if cost <= worn_cost:
				break  # Already wears something better (a piece found among the fallen).
			if g.gold >= cost * 3 + 100:
				g.buy_equipment(key)
				rec["gear_spend"] = int(rec["gear_spend"]) + cost
				g.equip_item(str(merc["id"]), str(g.equipment_inventory.back()["uid"]))
				break

func _free(role: String) -> Array[String]:
	var ids: Array[String] = []
	for merc in g.crew:
		if Mercs.role_of(merc) == role and g.is_available(merc) and int(merc.get("health", 100)) >= 25:
			ids.append(str(merc["id"]))
	return ids

func _sell_to_merchants(keep: Array = []) -> void:
	for good in MoneyMercsState.RESOURCE_ORDER:
		var n: int = int(g.resources.get(good, 0))
		if n <= 0 or keep.has(good):
			continue
		var each: int = g.sell_price(str(good), n)
		g.trade(str(good), false, n)
		rec["merchant_sales"] = int(rec["merchant_sales"]) + each * n
		rec["merchant_units"] = int(rec["merchant_units"]) + n

# Logging: each free slot goes to the site and orders with the best forecast profit per
# hour, as the planner shows it. Casual players use Long Shift.
func _logging(use_hall: bool, slots_for_logging: int = -1) -> void:
	_work("logging", "Woodcutter", ["mossward_copse", "old_oakwood"], ["hand_axe", "felling_axe"], use_hall, slots_for_logging)

## Mining sites the same way: Harlow Mines, then Deepdelve from Mining 8.
func _mining(use_hall: bool, slots_for_mining: int = -1) -> void:
	_work("mining", "Miner", ["harlow", "deepdelve"], ["basic_pick", "reinforced_pick"], use_hall, slots_for_mining)

## The orders a player away from the keyboard uses: Long Shift for a half-hour check-in,
## Overnight for three visits a day, Full Day for a once-a-day player logging off.
func _long_orders() -> Array:
	match strategy:
		"casual": return ["Long Shift"]
		"idle": return ["Overnight", "Long Shift"]
		"evening": return ["Full Day", "Overnight", "Long Shift"] if _leaving() else []
	return []

# One trade at its generic sites: each free slot goes to the site and orders with the best
# forecast profit per hour, as the planner shows it.
func _work(trade: String, role: String, sites: Array, tools: Array, use_hall: bool, slots_for_trade: int = -1) -> void:
	var slots: int = g.expedition_slots if slots_for_trade < 0 else slots_for_trade
	_hire(role, 3 * slots)
	_outfit(role, tools)
	var long_list: Array = _long_orders()
	var long_mode: bool = not long_list.is_empty()
	var orders_list: Array = long_list if long_mode else ["Balanced", "Deep Push"]
	while _running_trade(trade) < slots and g.missions.size() < g.expedition_slots:
		var free: Array[String] = _free(role)
		if free.is_empty():
			break
		free.sort_custom(func(a: String, b: String) -> bool: return TradeSkills.xp_of(g.merc_by_id(a), trade) > TradeSkills.xp_of(g.merc_by_id(b), trade))
		var best_site: String = ""
		var best_orders: String = ""
		var best_crew: Array[String] = []
		var best_rate: float = -1000000.0
		# Biggest affordable crew first; long orders fall back to shorter ones when unaffordable.
		for size in range(mini(3, free.size()), 0, -1):
			var crew: Array[String] = []
			for id in free.slice(0, size):
				crew.append(id)
			for site in sites:
				for i in range(orders_list.size() + (1 if long_mode else 0)):
					var orders: String = str(orders_list[i]) if i < orders_list.size() else "Balanced"
					var plan: Dictionary = g.site_forecast(site, crew, orders)
					if not bool(plan["meets_level"]) or g.gold < int(plan["cost"]):
						continue
					# Count an expected death as 150 G (hire, tools and lost levels).
					var rate: float = (float(plan["profit"]) - float(plan["death"]) * crew.size() * 150.0) / float(plan["duration"])
					if long_mode:
						rate -= 1000.0 * float(i)  # The player prefers the order that covers their absence.
					if rate > best_rate:
						best_rate = rate
						best_site = site
						best_orders = orders
						best_crew = crew
			if best_site != "":
				break
		if best_site == "" or not g.site_dispatch(best_site, best_crew, best_orders).begins_with("The crew set out"):
			break
	if use_hall:
		_hall_seller(["timber", "herbs", "copper", "iron", "silver", "crystal"])
	else:
		_sell_to_merchants()

## One of the newer trades at every site it can reach. The farmer builds farm buildings.
func _new_trade() -> void:
	var spec: Array = NEW_TRADES[strategy]
	var trade: String = str(spec[0])
	if strategy == "farmer":
		for id in g.upgrade_shop():
			if g.gold >= 3 * g.upgrade_gold(id) + 300 and g.build_upgrade(id).begins_with("Built"):
				rec["gear_spend"] = int(rec["gear_spend"]) + g.upgrade_gold(id)
	var sites: Array = []
	for site in TradeSites.for_trade(trade):
		if g.has_upgrade(str(site.get("needs", ""))):
			sites.append(str(site["id"]))
	_work(trade, str(spec[1]), sites, [str(spec[2])], false)

func _running_trade(trade: String) -> int:
	var n: int = 0
	for m in g.missions:
		if m.has("site") and str(m.get("trade", "")) == trade:
			n += 1
	return n

# Minimal: one woodcutter at Mossward Copse on Balanced orders, everything sold to the
# merchants. No expansion, no tools, no Trade Hall, no other sites.
func _minimal() -> void:
	_hire("Woodcutter", 1)
	if g.missions.is_empty():
		var free: Array[String] = _free("Woodcutter")
		if not free.is_empty():
			var plan: Dictionary = g.site_forecast("mossward_copse", free.slice(0, 1), "Balanced")
			if g.gold >= int(plan["cost"]):
				g.site_dispatch("mossward_copse", free.slice(0, 1), "Balanced")
	_sell_to_merchants()

func _running(kind: String) -> int:
	var n: int = 0
	for m in g.missions:
		if (kind == "site" and m.has("site")) or (kind == "harlow" and str(m.get("region", "")) == "harlow"):
			n += 1
	return n

# Miner: Harlow Mines, then Deepdelve; sales through the Trade Hall.
func _miner() -> void:
	_mining(true)

# Everything: one slot mining (Harlow or the mining sites), the rest logging; Trade Hall.
func _everything() -> void:
	if g.expedition_slots >= 2:
		_mining(true, 1)
		_logging(true, g.expedition_slots - 1)
	else:
		_logging(true)

# Regional contracts: the best region the company's reputation allows, three mercs.
func _contracts(lowlands_only: bool) -> void:
	_hire("Guard", 2 * g.expedition_slots)
	_hire("Miner", g.expedition_slots)
	while g.missions.size() < g.expedition_slots:
		var region: Dictionary = {}
		for r in MoneyMercsState.REGIONS:
			if g.reputation >= int(r["rep"]) and str(r["id"]) != "ashen" and (not lowlands_only or str(r["id"]) == "lowlands"):
				region = r
		var crew: Array[String] = []
		var focus: String = str(region.get("focus", "Guard"))
		for id in _free(focus):
			if crew.size() < 3:
				crew.append(id)
		for role in ["Guard", "Miner"]:
			for id in _free(role):
				if crew.size() < 3 and not crew.has(id):
					crew.append(id)
		if crew.is_empty():
			break
		if not g.dispatch(str(region["id"]), crew, "Balanced").begins_with("Expedition funded"):
			break
	_sell_to_merchants()

# --- Trade Hall play -------------------------------------------------------------------

## Post goods in the chat, answer buyers who message, and complete trades. Goods nobody
## has bought within 30 minutes go to the merchants.
func _hall_seller(goods: Array, hold_s: int = 1800) -> void:
	var hall: TradeHall = g.hall
	_run_trade()
	_answer_messages()
	_sell_into_bids()
	var links: Array = []
	var parts: Array[String] = []
	for good in goods:
		var n: int = int(g.resources.get(good, 0))
		if n <= 0:
			counters["held_since"].erase(good)
			continue
		if not counters["held_since"].has(good):
			counters["held_since"][good] = t
		var name: String = g.item_ref_name(str(good))
		links.append({"ref": good, "name": name, "uid": ""})
		parts.append("[%s]x%d %dg each" % [name, n, int(round(hall.fair(str(good), t)))])
	if not links.is_empty() and t - int(counters["last_post"]) >= 300 and hall.say_wait(t) == 0:
		if g.hall_say("WTS " + ", ".join(parts), links, t) == "":
			counters["last_post"] = t
	# Anything held for 30 minutes goes to the merchants, except what an agreed deal needs.
	for good in MoneyMercsState.RESOURCE_ORDER:
		var n: int = int(g.resources.get(good, 0))
		if n <= 0:
			continue
		if goods.has(good) and t - int(counters["held_since"].get(good, t)) < hold_s:
			continue
		var spare: int = n - _committed_qty(str(good))
		if spare > 0:
			var each: int = g.sell_price(str(good), spare)
			g.trade(str(good), false, spare)
			rec["merchant_sales"] = int(rec["merchant_sales"]) + each * spare
			rec["merchant_units"] = int(rec["merchant_units"]) + spare
		counters["held_since"].erase(good)

## Answer WTB posts paying at least fair value (guild contractors) with goods in stock.
func _sell_into_bids() -> void:
	var hall: TradeHall = g.hall
	if hall.session != null and hall.session.is_open():
		return
	for m in hall.feed:
		if str(m["side"]) != "wtb" or int(m["left"]) <= 0 or str(m["good"]).begins_with("gear:"):
			continue
		if int(m.get("until", 0)) > 0 and t >= int(m["until"]):
			continue
		var good: String = str(m["good"])
		var have: int = int(g.resources.get(good, 0)) - _committed_qty(good)
		if have <= 0 or float(m["price"]) < hall.fair(good, t) or _busy_with(str(m["from"])):
			continue
		var n: int = mini(have, int(m["left"]))
		var said: String = g.hall_pm(str(m["from"]), "%d for %dg" % [n, n * int(m["price"])], [], t)
		_pm_sent(str(m["from"]))
		if OS.has_environment("SIM_DEBUG"):
			print("%.2fh SELL %s x%d %s @%d -> %s" % [_elapsed_h(), m["from"], n, good, int(m["price"]), said])
		return

## Still talking or trading with this trader (a finished deal doesn't count).
func _busy_with(trader: String) -> bool:
	# A message just sent counts until they've had two minutes to answer.
	if t - int((counters.get("pm_sent", {}) as Dictionary).get(trader, -100000)) < 120:
		return true
	if not g.hall.deals.has(trader):
		return false
	return (g.hall.deals[trader] as Haggle).status in ["open", "agreed"]

func _pm_sent(trader: String) -> void:
	if not counters.has("pm_sent"):
		counters["pm_sent"] = {}
	counters["pm_sent"][trader] = t

## Units promised in agreed deals stay out of merchant sales.
func _committed_qty(good: String) -> int:
	var n: int = 0
	for trader in g.hall.deals:
		var h: Haggle = g.hall.deals[trader]
		if h.good == good and not h.they_sell and h.is_agreed():
			n += h.agreed_qty
	return n

## Reply to traders: accept a fair offer, counter once at fair value, otherwise pass.
func _answer_messages() -> void:
	var hall: TradeHall = g.hall
	for trader in hall.deals.keys():
		var h: Haggle = hall.deals[trader]
		if not h.is_open() or hall.is_typing(trader, t):
			continue
		var lines: Array = hall.conversation(trader)
		if lines.is_empty():
			continue
		# A trader who has gone quiet for five minutes is dropped.
		if str((lines.back() as Dictionary)["from"]) != trader:
			if t - int((lines.back() as Dictionary)["t"]) > 300:
				h.walk_away()
			continue
		var qty: int = h.qty_max if h.they_sell else mini(h.qty_max, int(g.resources.get(h.good, 0)))
		if qty <= 0:
			g.hall_pm(trader, "no thanks", [], t)
			continue
		var fair: float = hall.fair(h.good, t)
		var merchant: float = float(g.sell_price(h.good, qty))
		var asked: int = int((counters["pm_counters"] as Dictionary).get(trader, 0))
		if not h.they_sell:
			if h.ask >= fair * 0.97 or (asked >= 1 and h.ask > merchant * 1.05):
				g.hall_pm(trader, "deal x%d" % qty, [], t)
			elif asked < 1:
				counters["pm_counters"][trader] = asked + 1
				g.hall_pm(trader, "%d for %dg" % [qty, int(ceil(fair * float(qty)))], [], t)
			else:
				g.hall_pm(trader, "no thanks", [], t)

## Fill the company's side of an open trade, lock, and accept when allowed.
func _run_trade() -> void:
	var s: TradeSession = g.hall.session
	if s == null or not s.is_open():
		counters.erase("trade_since")
		return
	if not counters.has("trade_since"):
		counters["trade_since"] = t
	# A trade that has not gone through in two minutes is cancelled, as a player would.
	if t - int(counters["trade_since"]) > 120:
		var stuck: Haggle = s.deal
		g.trade_cancel(t)
		stuck.walk_away()
		counters.erase("trade_since")
		rec["trades_cancelled"] = int(rec.get("trades_cancelled", 0)) + 1
		return
	if not s.my_locked:
		var h: Haggle = s.deal
		if h.they_sell:
			g.trade_set_gold(h.agreed_total, t)
		else:
			g.trade_set_goods(h.good, h.agreed_qty, t)
		g.trade_lock(t)
	elif s.accept_wait(t) == 0 and not s.my_accepted:
		var gold_before: int = g.gold
		g.trade_accept(t)
		rec["hall_units"] = int(rec["hall_units"]) + s.deal.agreed_qty
		if s.deal.they_sell:
			rec["hall_buys"] = int(rec["hall_buys"]) + s.deal.agreed_total
		else:
			rec["hall_sales"] = int(rec["hall_sales"]) + s.deal.agreed_total
			rec["tax_paid"] = int(rec["tax_paid"]) + int(round(float(s.deal.agreed_total) * TradeHall.TAX))

# Pure trading: buy posts priced well under fair value, sell them on in the Hall.
func _hall_trader() -> void:
	var hall: TradeHall = g.hall
	_run_trade()
	_answer_messages()
	# Buy: message sellers of posts under 88% of fair value, for as much as we can afford.
	var open_buys: int = 0
	for trader in hall.deals:
		var h: Haggle = hall.deals[trader]
		if h.they_sell and h.status in ["open", "agreed"]:
			open_buys += 1
	if open_buys < 2 and (hall.session == null or not hall.session.is_open()):
		# What open buy orders (contractors and other high bids) still want, by good.
		var wanted: Dictionary = {}
		for m in hall.feed:
			if str(m["side"]) == "wtb" and int(m["left"]) > 0 and not str(m["good"]).begins_with("gear:") and t < int(m.get("until", t + 1)):
				var good: String = str(m["good"])
				var best: Dictionary = wanted.get(good, {})
				if best.is_empty() or int(m["price"]) > int(best["price"]):
					wanted[good] = {"price": int(m["price"]), "left": int(m["left"]) - int(g.resources.get(good, 0))}
		for m in hall.feed:
			if str(m["side"]) != "wts" or int(m["left"]) <= 0 or str(m["good"]).begins_with("gear:") or t - int(m["t"]) > 300:
				continue
			var good: String = str(m["good"])
			var fair: float = hall.fair(good, t)
			var price: int = int(m["price"])
			var cap: int = int(m["left"])
			var order: Dictionary = wanted.get(good, {})
			# Buy to fill a standing order at a margin, or a deep bargain to hold.
			var fills: bool = not order.is_empty() and int(order["left"]) > 0 and float(price) <= float(order["price"]) * 0.85
			if not fills:
				continue  # Only buy what a standing order will take at a margin.
			cap = mini(cap, int(order["left"]))
			var n: int = mini(cap, int(float(g.gold - 50) / float(maxi(1, price))))
			if n >= 1 and not _busy_with(str(m["from"])):
				var said: String = g.hall_pm(str(m["from"]), "I'll take x%d for %dg" % [n, n * price], [], t)
				_pm_sent(str(m["from"]))
				if OS.has_environment("SIM_DEBUG"):
					print("%.2fh BUY %s x%d %s @%d fair %.1f fills=%s gold=%d -> %s" % [_elapsed_h(), m["from"], n, good, price, fair, fills, g.gold, said])
				break
	# Accept sellers' replies that hold the price.
	for trader in hall.deals.keys():
		var h: Haggle = hall.deals[trader]
		if h.they_sell and h.is_open() and not hall.is_typing(trader, t):
			var lines: Array = hall.conversation(trader)
			if not lines.is_empty() and str((lines.back() as Dictionary)["from"]) == trader and h.ask <= hall.fair(h.good, t) * 0.9:
				g.hall_pm(trader, "deal", [], t)
	# Sell: into bids at or above fair value, and post what we hold; keep stock up to 8 hours.
	_hall_seller(MoneyMercsState.RESOURCE_ORDER, 8 * 3600)

