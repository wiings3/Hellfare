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
		"crafted": {"knight": ["steel_sword", "leather"], "rogue": ["steel_dagger", "leather"]},
		"good": {"knight": ["steel_sword", "chainmail", "iron_helm", "iron_kite_shield"], "rogue": ["steel_dagger", "leather", "leather_cap", "leather_boots"]},
	}
	var d: Dictionary = Dungeons.by_id("calder_keep")
	for kit in kits:
		for c in ["knight", "rogue"]:
			var line := "%-8s %-7s" % [kit, c]
			for fi in range((d["floors"] as Array).size()):
				var wins := 0
				var hp_left := 0.0
				var rounds := 0
				var rng := RandomNumberGenerator.new()
				rng.seed = 99
				for t in range(TRIALS):
					var h: Dictionary = Heroes.make("h", "Hero", c)
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
			print(line)
	quit(0)
