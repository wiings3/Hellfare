extends SceneTree
## Balance simulator for logging sites. Resets the company, so it refuses to run without MM_ALLOW_RESET=1.
## Run: MM_ALLOW_RESET=1 godot --headless --path . --script res://tools/balance_logging.gd
func _initialize() -> void:
	if OS.get_environment("MM_ALLOW_RESET") != "1":
		push_error("Set MM_ALLOW_RESET=1: this resets the local save.")
		quit(1)
		return
	var g := MoneyMercsState.new()
	for site_id in ["mossward_copse", "old_oakwood"]:
		for crew_kind in ["1 woodcutter", "2 woodcutters", "2 woodcutters + guard"]:
			for tactic in ["Cautious", "Balanced", "Deep Push"]:
				var profit := 0.0
				var deaths := 0
				var injuries := 0
				var runs := 300
				var forecast: Dictionary = {}
				var levels := 0
				for r in range(runs):
					g.reset_company()
					g.gold = 5000
					var lvl: int = 1 if site_id == "mossward_copse" else 8
					var ids: Array[String] = []
					var n_wc: int = 1 if crew_kind == "1 woodcutter" else 2
					for i in range(n_wc):
						var m := {"id": "wc%d" % i, "name": "WC%d" % i, "role": "Woodcutter", "skill": 12, "wage": 8, "share": 0.08, "health": 100, "mission_id": "", "contract": "Balanced", "equipment": {"tool": {}, "armor": {}}}
						m["skills"] = {"logging": TradeSkills.xp_for_level(lvl), "mining": 0, "foraging": 0, "combat": 0}
						g.crew.append(m)
						ids.append("wc%d" % i)
					if crew_kind.contains("guard"):
						var gd := {"id": "gd", "name": "Guard", "role": "Guard", "skill": 14, "wage": 9, "share": 0.09, "health": 100, "mission_id": "", "contract": "Balanced", "equipment": {"tool": {}, "armor": {}}}
						gd["skills"] = {"logging": 0, "mining": 0, "foraging": 0, "combat": TradeSkills.xp_for_level(4)}
						g.crew.append(gd)
						ids.append("gd")
					forecast = g.site_forecast(site_id, ids, tactic)
					var res: String = g.site_dispatch(site_id, ids, tactic)
					if not res.begins_with("The crew"):
						print(site_id, " ", res)
						break
					g.missions[0]["seed"] = r * 7 + 3
					g.complete_due(int(Time.get_unix_time_from_system()) + 1000)
					var rep: Dictionary = g.reports[0]
					profit += float(int(rep["value"]) - int(rep["cost"]))
					deaths += (rep["casualties"] as Array).size()
					injuries += (rep["injured"] as Array).size()
				print("%-15s %-22s %-9s forecast %+4d (cost %3d, %.0fs)  actual avg %+6.1f  deaths/100 %.1f  injuries/100 %.1f" % [site_id, crew_kind, tactic, int(forecast["profit"]), int(forecast["cost"]), float(forecast["duration"]), profit / runs, 100.0 * deaths / runs, 100.0 * injuries / runs])
	print("xp to L2 %d L5 %d L8 %d L10 %d L15 %d" % [TradeSkills.xp_for_level(2), TradeSkills.xp_for_level(5), TradeSkills.xp_for_level(8), TradeSkills.xp_for_level(10), TradeSkills.xp_for_level(15)])
	print("timber ref %d npc buys %d sells %d; sell 100 -> %d each" % [g.price("timber"), g.sell_price("timber"), g.buy_price("timber"), g.sell_price("timber", 100)])
	quit()
