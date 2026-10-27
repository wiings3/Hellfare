extends SceneTree
## Balance check for the crypt crawl: how one hero of each class does on each floor of a
## crypt with a few kits, under the automatic rules. Run headless:
##   godot --headless --path . --script res://tools/crawl_sim.gd
const TRIALS := 400
var g: MoneyMercsState

func _initialize() -> void:
	MoneyMercsState.persist = false
	g = MoneyMercsState.new()
	g.reset_company()
	var kits := {
		"starter": {"knight": ["rusted_sword"], "rogue": ["iron_dagger"]},
		"t1": {"knight": ["iron_war_axe", "iron_kite_shield", "iron_helm"], "rogue": ["iron_dagger", "leather", "leather_cap"]},
		"t1_full": {"knight": ["iron_mace", "iron_kite_shield", "iron_helm", "leather", "leather_boots"], "rogue": ["iron_dagger", "leather", "leather_cap", "leather_boots"]},
		"t2": {"knight": ["steel_sword", "chainmail", "iron_helm", "iron_kite_shield"], "rogue": ["steel_dagger", "leather", "leather_cap", "leather_boots"]},
	}
	var d: Dictionary = Dungeons.by_id("calder_keep")
	for kit in kits:
		for c in ["knight", "rogue"]:
			for lvl in [1, 4]:
				var line := "%-8s %-7s L%d" % [kit, c, lvl]
				for fi in range((d["floors"] as Array).size()):
					var wins := 0
					var hp_left := 0.0
					var rounds := 0
					var rng := RandomNumberGenerator.new()
					rng.seed = 99
					for t in range(TRIALS):
						var h: Dictionary = Heroes.make("h", "Hero", c)
						h["skills"]["combat"] = TradeSkills.xp_for_level(lvl)
						for k in kits[kit][c]:
							if Gear.exists(k):
								h["equipment"][Gear.slot_of(k)] = g.make_item(k, "common")
						var f: Dictionary = Heroes.fighter(h)
						var r: Dictionary = Dungeons.fight([f], d["floors"][fi], rng)
						rounds += int(r["rounds"])
						if str(r["result"]) == "cleared":
							wins += 1
							hp_left += float(f["hp"]) / float(f["max_hp"])
					line += "  F%d %3d%% (hp %3d%%, %4.1f rds)" % [fi + 1, int(100.0 * wins / TRIALS), int(100.0 * hp_left / maxf(1, wins)), float(rounds) / TRIALS]
				# The whole run in one go: health carries from floor to floor.
				var full := 0
				var rng2 := RandomNumberGenerator.new()
				rng2.seed = 7
				for t in range(TRIALS):
					var h2: Dictionary = Heroes.make("h", "Hero", c)
					h2["skills"]["combat"] = TradeSkills.xp_for_level(lvl)
					for k in kits[kit][c]:
						if Gear.exists(k):
							h2["equipment"][Gear.slot_of(k)] = g.make_item(k, "common")
					var run: Dictionary = Dungeons.simulate([Heroes.fighter(h2)], d, 3, "never", rng2)
					if int(run["cleared"]) >= 3:
						full += 1
				line += "  RUN %3d%%" % int(100.0 * full / TRIALS)
				# From the boss's own stairs (known once the halls are cleared), fresh.
				var boss := 0
				for t in range(TRIALS):
					var h3: Dictionary = Heroes.make("h", "Hero", c)
					h3["skills"]["combat"] = TradeSkills.xp_for_level(lvl)
					for k in kits[kit][c]:
						if Gear.exists(k):
							h3["equipment"][Gear.slot_of(k)] = g.make_item(k, "common")
					var run3: Dictionary = Dungeons.simulate([Heroes.fighter(h3)], d, 3, "never", rng2, 2)
					if int(run3["cleared"]) >= 3:
						boss += 1
				line += "  AT BOSS %3d%%" % int(100.0 * boss / TRIALS)
				print(line)
	quit(0)
