extends SceneTree
## Calder Keep: fights, kit gating, floors over time, check-ins, the death rule and saving
## mid-run (in-memory company, no save file).
var failures: int = 0

func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error("Dungeon check failed: " + what)

func _kit(g: MoneyMercsState, id: String, keys: Array, combat: int) -> void:
	var m: Dictionary = g.merc_by_id(id)
	m["skills"]["combat"] = TradeSkills.xp_for_level(combat)
	for k in keys:
		m["equipment"][Gear.slot_of(k)] = g.make_item(k, "common")

func _crew(g: MoneyMercsState, kits: Array) -> Array[String]:
	var ids: Array[String] = []
	for c in g.recruitment_board():
		if ids.size() >= kits.size():
			break
		if g.hire(str(c["id"])).begins_with("Hired") or g.merc_by_id(str(c["id"])).size() > 0:
			if not g.merc_by_id(str(c["id"])).is_empty() and not ids.has(str(c["id"])):
				ids.append(str(c["id"]))
	for i in range(ids.size()):
		_kit(g, ids[i], kits[i][0], kits[i][1])
	return ids

func _initialize() -> void:
	MoneyMercsState.persist = false
	var now: int = 1_900_000_000
	GameClock.fixed = now
	var d: Dictionary = Dungeons.by_id("calder_keep")
	check(not d.is_empty() and (d["floors"] as Array).size() == 3, "Calder Keep has three floors")
	check(bool(d["floors"][2].get("boss", false)), "the third floor is a boss")
	# Fights are deterministic for a seed.
	var f1 := {"id": "a", "name": "A", "porter": false, "hp": 100.0, "max_hp": 100.0, "damage": 16.0, "speed": 1.0, "crit": 0.06, "crit_damage": 1.5, "pen": 0.0, "first": 0.0, "armour": 17.0, "dodge": 0.0, "parry": 0.0, "block": 0.0, "lucky": false, "heal": 0}
	var r1 := RandomNumberGenerator.new(); r1.seed = 11
	var r2 := RandomNumberGenerator.new(); r2.seed = 11
	var a: Dictionary = Dungeons.fight([f1.duplicate()], d["floors"][0], r1)
	var b: Dictionary = Dungeons.fight([f1.duplicate()], d["floors"][0], r2)
	check(str(a["result"]) == str(b["result"]) and int(a["rounds"]) == int(b["rounds"]), "fights repeat for a seed")
	# Drop half rounds the loss up; nothing is invented.
	var carry := {"coin": 9, "bone": 1}
	var lost: Dictionary = Dungeons.drop_half(carry)
	check(int(carry["coin"]) == 4 and int(lost["coin"]) == 5 and int(carry["bone"]) == 0, "drop half")

	var g := MoneyMercsState.new()
	g.reset_company()
	g.gold = 5000
	g.expedition_slots = 3
	var ids: Array[String] = _crew(g, [[["steel_sword", "chainmail", "iron_helm"], 9], [["iron_dagger", "leather", "leather_cap", "leather_boots"], 7], [["birch_shortbow", "leather", "leather_cap"], 4]])
	check(ids.size() == 3, "three mercenaries hired (%d)" % ids.size())
	# Kit gating.
	var green: Dictionary = g.merc_by_id(ids[2])
	var bow: Dictionary = green["equipment"]["main_hand"]
	green["equipment"]["main_hand"] = {}
	check(g.dungeon_fit("calder_keep", green).begins_with("Gear score"), "low gear score is turned away")
	check(not g.dungeon_dispatch("calder_keep", ids, 2, "half").begins_with("The crew went"), "dispatch refuses low kit")
	green["equipment"]["main_hand"] = bow
	check(g.dungeon_fit("calder_keep", green) == "", "kit 8 gets in (%d)" % Gear.kit_rating(green))
	var plan: Dictionary = g.dungeon_forecast("calder_keep", ids, 2, "half")
	check((plan["odds"] as Array).size() == 3 and float(plan["odds"][0]) > 0.8, "forecast gives floor odds")
	check(int(plan["cost"]) >= 30 and str(plan["blocked"]) == "", "forecast cost includes supplies")
	var gold0: int = g.gold
	var reps: int = g.reports.size()
	check(g.dungeon_dispatch("calder_keep", ids, 2, "half").begins_with("The crew went"), "dispatch")
	check(g.gold == gold0 - int(plan["cost"]), "paid wages and supplies")
	var m: Dictionary = g.missions[0]
	check(str(m["stage"]) == "floor" and int(m["floor_i"]) == 0, "starts on floor 1")
	check(g.complete_due(now + 60) == 0 and str(m["stage"]) == "floor", "nothing happens before the floor is done")
	# Floor 1 resolves; the crew waits at the stairs.
	g.complete_due(now + Dungeons.FLOOR_TIME + 1)
	check((m["log"] as Array).size() == 1, "floor 1 resolved")
	if str(m["log"][0]["result"]) == "cleared":
		check(str(m["stage"]) == "await", "check-in after a cleared floor")
		check(g.dungeon_checkins().size() == 1, "check-in listed")
		check(int(m["carry"].get("coin", 0)) > 0, "carrying coin")
		# Saving mid-run keeps the run.
		var saved: Dictionary = JSON.parse_string(JSON.stringify(m))
		check(str(saved["stage"]) == "await" and (saved["log"] as Array).size() == 1, "run survives a save round trip")
		check(g.dungeon_choose(str(m["id"]), true) == "The crew pushed on.", "push on")
		check(str(m["stage"]) == "floor" and int(m["floor_i"]) == 1, "on floor 2")
		# Nobody answers the next check-in: orders (depth 2) take the crew out.
		g.complete_due(now + 3 * Dungeons.FLOOR_TIME)
		g.complete_due(now + 3 * Dungeons.FLOOR_TIME + Dungeons.CHECKIN + 1)
		check(str(m["stage"]) == "out" or g.missions.is_empty(), "orders take the crew out at depth 2")
	g.complete_due(now + 10 * 3600)
	check(g.missions.is_empty(), "run finished")
	check(g.reports.size() == reps + 1 and g.reports[0].has("floor_log"), "dungeon report written")
	var rep: Dictionary = g.reports[0]
	check(str(rep.get("dungeon", "")) == "calder_keep", "report names the dungeon")
	for id in ids:
		var merc: Dictionary = g.merc_by_id(id)
		if not merc.is_empty():
			check(str(merc.get("mission_id", "")) == "", "survivor is home")
			check(TradeSkills.xp_of(merc, "combat") > TradeSkills.xp_for_level(1), "survivor earned combat xp")
	# A wipe loses everything; the dead are gone and their gear may stay in the keep.
	var w := MoneyMercsState.new()
	w.reset_company()
	w.gold = 5000
	var weak: Array[String] = _crew(w, [[["rusted_sword", "leather", "leather_cap", "leather_boots"], 1]])
	w.merc_by_id(weak[0])["health"] = 100
	var gate: String = w.dungeon_fit("calder_keep", w.merc_by_id(weak[0]))
	if gate == "":
		w.dungeon_dispatch("calder_keep", weak, 3, "never")
		var wm: Dictionary = w.missions[0]
		# Make the run deadly: the crew starts nearly dead.
		wm["hp"][weak[0]] = 1.0
		wm["carry"] = {"coin": 50}
		w.complete_due(now + 10 * 3600)
		check(w.missions.is_empty(), "wiped run finishes")
		check(w.merc_by_id(weak[0]).is_empty(), "the dead leave the roster")
		check(str(w.reports[0]["outcome"]) == "wiped", "report says wiped")
		check(int(w.reports[0]["cash"]) == 0, "a wipe brings nothing out")
		check(int((w.reports[0]["dropped"] as Dictionary).get("coin", 0)) >= 50, "carried coin left in the keep")
		check(w.retired_ids.has(weak[0]), "the dead are retired")
	else:
		check(false, "weak crew should still pass the kit gate for the wipe test (%s)" % gate)
	# Events: scheduled through each floor, waiting for the player, decided by orders when not.
	var e := MoneyMercsState.new()
	e.reset_company()
	e.gold = 5000
	var eids: Array[String] = _crew(e, [[["steel_sword", "chainmail", "iron_helm"], 9], [["steel_sword", "chainmail"], 8]])
	check(e.dungeon_dispatch("calder_keep", eids, 3, "half", "bold").begins_with("The crew went"), "dispatch with bold orders")
	var em: Dictionary = e.missions[0]
	var evs: Array = em["ev"]
	check(evs.size() >= 6, "events through the first floor (%d)" % evs.size())
	var gaps_ok: bool = true
	for k in range(1, evs.size()):
		var gap: int = int(evs[k]["t"]) - int(evs[k - 1]["t"])
		gaps_ok = gaps_ok and gap >= DungeonEvents.GAP[0] and gap <= DungeonEvents.GAP[1]
	check(gaps_ok, "events come every 15-25 seconds")
	var first_t: int = int(evs[0]["t"])
	check(e.dungeon_pending(first_t - 1).is_empty() and e.dungeon_pending(first_t).size() == 1, "an event waits for the player when it happens")
	GameClock.fixed = first_t + 2
	var said: String = e.dungeon_answer(str(em["id"]), 0, 0)
	check(said != "" and bool(evs[0]["done"]) and not bool(evs[0]["auto"]), "the player's choice is applied")
	check(e.dungeon_answer(str(em["id"]), 0, 1).begins_with("Too late"), "an event is decided once")
	e.complete_due(first_t + 200)
	var auto_done: int = 0
	for ev in em["ev"]:
		if bool(ev["done"]) and int(ev["t"]) + DungeonEvents.EVENT_WAIT <= first_t + 200:
			auto_done += 1
	check(auto_done >= 5, "unanswered events are decided by the crew")
	check((em["ev_log"] as Array).size() >= auto_done, "decisions are logged")
	check(DungeonEvents.auto_choice({"id": "bloody_chest", "state": "trapped", "hint": "", "roll": 1}, "bold") == 0, "bold orders open the chest")
	check(DungeonEvents.auto_choice({"id": "bloody_chest", "state": "trapped", "hint": "x", "roll": 1}, "bold") == 1, "a hint makes the crew check for traps")
	# A deadly outcome kills; the last death wipes the run.
	var em_hp: Dictionary = em["hp"]
	for id in eids:
		em_hp[id] = 1.0
	em["lucky"] = {}
	var trap: Dictionary = {"t": GameClock.now(), "id": "cracked_floor", "state": "gives", "hint": "", "reader": "", "done": false, "roll": 5}
	(em["ev"] as Array).append(trap)
	e._apply_event(em, trap, 0, GameClock.now(), false)
	check((em["dead"] as Array).size() == 1, "a fall kills a crew member at 1 health")
	e.complete_due(first_t + 7200)
	check(e.missions.is_empty() and e.reports[0].has("floor_log"), "the run still finishes and reports")
	for ev_def in DungeonEvents.EVENTS:
		for ch in ev_def["choices"]:
			for state in ch["out"]:
				check(state == "any" or (ev_def["states"] as Dictionary).has(state), "%s: outcome state %s exists" % [ev_def["id"], state])
	GameClock.fixed = -1
	if failures > 0:
		push_error("%d dungeon checks failed." % failures)
		quit(1)
		return
	print("Dungeon checks passed.")
	quit(0)
