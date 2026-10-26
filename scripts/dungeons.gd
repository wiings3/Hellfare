extends RefCounted
class_name Dungeons
## Dungeons: a run goes down floor by floor, each floor a fight, and only what reaches the
## exit counts. Fights resolve here, round by round, from what the crew carries and wears:
## weapon damage, attack speed, crit and armour piercing against the monsters; armour,
## dodge, parry and block against their blows. Whoever holds a weapon fights; anyone without
## one comes as a porter (carries more out, doesn't fight, dies easily).
##
## Calder Keep is tier 1: monsters only, three floors, the third a boss.

## How long a floor takes, and the walk back out through each floor already cleared. A full run
## (three floors, two check-ins, the walk out) takes 20 minutes.
const FLOOR_TIME := 240
const WALK_TIME := 80
## The check-in between floors: how long the crew waits for the player before following orders.
const CHECKIN := 120
## A fight that hasn't ended after this many rounds ends with the crew backing out.
const MAX_ROUNDS := 14
## Damage reduction from armour: hits are scaled by ARMOUR_K / (ARMOUR_K + armour).
const ARMOUR_K := 50.0
## Health the crew gets back binding wounds on the stairs between floors.
const PATCH_UP := 10.0
## Each Combat level adds this much to a fighter's damage.
const LEVEL_DAMAGE := 0.05
## Orders for turning back, and the health at which each makes a crew back out of a fight.
const TURN_BACK := {"half": "Anyone below half", "death": "Someone dies", "never": "Never"}
const RETREAT_AT := {"half": 15.0, "death": 0.0, "never": 0.0}

const DUNGEONS := {
	"calder_keep": {
		"id": "calder_keep", "name": "The Fallen Keep", "tier": 1, "layer": 1, "min_kit": 8, "supplies": 30, "crew": 3,
		"tagline": "A keep the Maw swallowed when it opened. Rats in the cellars, spiders in the halls, and something in armour on the top floor, still on guard.",
		"art": "res://assets/ui/art/dungeon_calder_keep.png",
		"floors": [
			{"name": "The Cellars", "foe": "Giant rats", "count": 5, "hp": 18, "damage": 10, "speed": 1.2, "armour": 2,
			 "coin": [22, 41], "loot": {"bone": [1, 3]}},
			{"name": "Webbed Halls", "foe": "Cave spiders", "count": 3, "hp": 50, "damage": 16, "speed": 1.1, "armour": 10,
			 "coin": [43, 77], "loot": {"spider_silk": [1, 3], "bone": [0, 2]}},
			{"name": "The Bone Knight", "foe": "The Bone Knight", "count": 1, "hp": 340, "damage": 18, "speed": 0.9, "armour": 32, "boss": true,
			 "coin": [156, 252], "loot": {"bone": [3, 5]}, "rare": {"good": "relic", "chance": 0.08}, "blueprint": 0.2},
		],
	},
}
## Crypts designed but not open yet, for the board.
const PLANNED := [
	{"id": "sunken_abbey", "name": "The Drowned Abbey", "min_kit": 24, "note": "rival crews"},
	{"id": "wyrms_hollow", "name": "The Throne Below", "min_kit": 36, "note": "rival crews"},
]

static func by_id(id: String) -> Dictionary:
	return DUNGEONS.get(id, {})

## A mercenary's fighting numbers. Porters (no weapon) don't attack.
static func fighter(merc: Dictionary) -> Dictionary:
	var weapon: Dictionary = Gear.in_slot(merc, "main_hand")
	var wd: Dictionary = Gear.def(str(weapon.get("key", "")))
	var fights: bool = Gear.job(merc) == "combat"
	var stats: Dictionary = wd.get("stats", {}) if fights else {}
	var eff: float = Gear.effect(weapon) if fights else 1.0
	var level: int = TradeSkills.level_of(merc, "combat")
	return {
		"id": str(merc.get("id", "")), "name": str(merc.get("name", "")), "porter": not fights,
		"hp": float(int(merc.get("health", 100))) + Gear.rolled(merc, "health"),
		"max_hp": 100.0 + Gear.rolled(merc, "health"),
		"damage": float(stats.get("damage", 0)) * eff * (1.0 + LEVEL_DAMAGE * float(level - 1)) * (1.0 + Gear.rolled(merc, "damage") / 100.0),
		"speed": maxf(0.3, float(stats.get("attack_speed", 1.0)) * (1.0 + Gear.rolled(merc, "attack_speed") / 100.0) + Gear.base(merc, "attack_speed", ["armour"])),
		"crit": float(stats.get("crit_chance", 0.0)) + Gear.rolled(merc, "crit_chance") / 100.0,
		"crit_damage": maxf(1.0, float(stats.get("crit_damage", 1.5)) + Gear.rolled(merc, "crit_damage") / 100.0),
		"pen": clampf(float(stats.get("armour_pen", 0.0)) + Gear.rolled(merc, "armour_pen") / 100.0, 0.0, 0.8),
		"first": float(stats.get("first_strike", 0.0)) + Gear.rolled(merc, "first_strike") / 100.0,
		"armour": Gear.armour(merc),
		"dodge": minf(0.4, Gear.base(merc, "dodge") + Gear.rolled(merc, "dodge") / 100.0),
		"parry": minf(0.3, Gear.base(merc, "parry") + Gear.rolled(merc, "parry") / 100.0),
		"block": minf(0.4, Gear.base(merc, "block") + Gear.rolled(merc, "block") / 100.0),
		"lucky": Mercs.has_trait(merc, "lucky"), "heal": int(Gear.buffs(merc, "potion").get("heal", 0)),
	}

## One floor's fight. `crew` is an array of fighter() dictionaries whose "hp" is changed in
## place. Returns {"result": "cleared" | "fled" | "wiped", "dead": [ids], "lines": [text],
## "potions": [ids that drank one], "lucky": [ids saved by luck]}.
static func fight(crew: Array, floor: Dictionary, rng: RandomNumberGenerator, retreat_below: float = 0.0) -> Dictionary:
	var foes: Array = []
	for i in range(int(floor["count"])):
		foes.append({"hp": float(floor["hp"]), "acc": 0.0})
	var dead: Array[String] = []
	var drank: Array[String] = []
	var saved: Array[String] = []
	var crits: Dictionary = {}
	var hits_taken: Dictionary = {}
	var rounds: int = 0
	for c in crew:
		c["acc"] = 0.0
		# A first strike: one free blow before the fight starts.
		if not bool(c["porter"]) and rng.randf() < float(c["first"]):
			c["acc"] = 1.0
	var result: String = "fled"
	while rounds < MAX_ROUNDS:
		rounds += 1
		# The crew strikes.
		for c in crew:
			if float(c["hp"]) <= 0.0 or bool(c["porter"]):
				continue
			c["acc"] = float(c["acc"]) + float(c["speed"])
			while float(c["acc"]) >= 1.0:
				c["acc"] = float(c["acc"]) - 1.0
				var alive: Array = foes.filter(func(f): return float(f["hp"]) > 0.0)
				if alive.is_empty():
					break
				var target: Dictionary = alive[0]
				var hit: float = float(c["damage"]) * rng.randf_range(0.85, 1.15)
				if rng.randf() < float(c["crit"]):
					hit *= float(c["crit_damage"])
					crits[c["name"]] = int(crits.get(c["name"], 0)) + 1
				hit *= ARMOUR_K / (ARMOUR_K + float(floor["armour"]) * (1.0 - float(c["pen"])))
				target["hp"] = float(target["hp"]) - hit
		if foes.all(func(f): return float(f["hp"]) <= 0.0):
			result = "cleared"
			break
		# The monsters strike back.
		for f in foes:
			if float(f["hp"]) <= 0.0:
				continue
			f["acc"] = float(f["acc"]) + float(floor["speed"])
			while float(f["acc"]) >= 1.0:
				f["acc"] = float(f["acc"]) - 1.0
				var targets: Array = crew.filter(func(c): return float(c["hp"]) > 0.0)
				if targets.is_empty():
					break
				var victim: Dictionary = _pick_target(targets, rng)
				if rng.randf() < float(victim["dodge"]) or rng.randf() < float(victim["parry"]):
					continue
				var blow: float = float(floor["damage"]) * rng.randf_range(0.8, 1.2)
				if rng.randf() < float(victim["block"]):
					blow *= 0.5
				blow *= ARMOUR_K / (ARMOUR_K + float(victim["armour"]))
				if bool(victim["porter"]):
					blow *= 1.3
				victim["hp"] = float(victim["hp"]) - blow
				hits_taken[victim["name"]] = int(hits_taken.get(victim["name"], 0)) + 1
				# A healing draught is drunk when badly hurt.
				if float(victim["hp"]) > 0.0 and float(victim["hp"]) < 35.0 and int(victim["heal"]) > 0:
					victim["hp"] = float(victim["hp"]) + float(victim["heal"])
					victim["heal"] = 0
					drank.append(str(victim["id"]))
				if float(victim["hp"]) <= 0.0:
					if bool(victim["lucky"]) and rng.randf() < 1.0 / 3.0:
						victim["hp"] = 5.0
						victim["lucky"] = false
						saved.append(str(victim["id"]))
					else:
						dead.append(str(victim["id"]))
		if crew.all(func(c): return float(c["hp"]) <= 0.0):
			result = "wiped"
			break
		# A crew under orders to mind its health backs out of a fight it's losing.
		if retreat_below > 0.0 and crew.any(func(c): return float(c["hp"]) > 0.0 and float(c["hp"]) < retreat_below):
			result = "fled"
			break
	return {"result": result, "dead": dead, "potions": drank, "lucky": saved, "rounds": rounds,
		"lines": _story(floor, result, rounds, crew, dead, crits, hits_taken)}

## Monsters go for fighters; porters at the back are reached less often.
static func _pick_target(targets: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total: float = 0.0
	for t in targets:
		total += 0.6 if bool(t["porter"]) else 1.0
	var roll: float = rng.randf() * total
	for t in targets:
		roll -= 0.6 if bool(t["porter"]) else 1.0
		if roll <= 0.0:
			return t
	return targets.back()

## A short account of a floor's fight, for the report.
static func _story(floor: Dictionary, result: String, rounds: int, crew: Array, dead: Array, crits: Dictionary, hits: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var foe: String = str(floor["foe"])
	match result:
		"cleared":
			lines.append("%s %s in %d rounds." % ["Beat" if bool(floor.get("boss", false)) else "Cleared the", foe if bool(floor.get("boss", false)) else foe.to_lower(), rounds])
		"fled":
			lines.append("%s held. The crew backed out after %d rounds." % [foe, rounds])
		"wiped":
			lines.append("%s killed the whole crew." % foe)
	var best: String = ""
	for who in crits:
		if best == "" or int(crits[who]) > int(crits[best]):
			best = str(who)
	if best != "":
		lines.append("%s landed %s." % [best, "a critical blow" if int(crits[best]) == 1 else "%d critical blows" % int(crits[best])])
	for c in crew:
		if dead.has(str(c["id"])):
			lines.append("%s fell." % str(c["name"]))
		elif int(hits.get(c["name"], 0)) >= 3:
			lines.append("%s took %d hits." % [str(c["name"]), int(hits[c["name"]])])
	return lines

## Between floors the living bind their wounds.
static func patch_up(crew: Array) -> void:
	for c in crew:
		if float(c["hp"]) > 0.0:
			c["hp"] = minf(float(c.get("max_hp", 100.0)), float(c["hp"]) + PATCH_UP)

## Fresh fighter copies for a forecast (each trial changes hp in place).
static func copies(fighters: Array) -> Array:
	var out: Array = []
	for f in fighters:
		out.append((f as Dictionary).duplicate())
	return out

## Monte Carlo forecast for a crew: per-floor chance to clear (going all the way, from the
## health they'd have), and, under the given orders, the chance someone dies, the average
## floors cleared and the average carried haul (coin plus goods at `price`).
static func forecast(fighters: Array, dungeon: Dictionary, depth: int, turn_back: String, price: Callable, trials: int = 120) -> Dictionary:
	var floors: Array = dungeon["floors"]
	var reached: Array = []
	var cleared: Array = []
	for i in range(floors.size()):
		reached.append(0)
		cleared.append(0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for t in range(trials):
		var crew: Array = copies(fighters)
		for i in range(floors.size()):
			if crew.all(func(c): return float(c["hp"]) <= 0.0):
				break
			reached[i] += 1
			var r: Dictionary = fight(crew.filter(func(c): return float(c["hp"]) > 0.0), floors[i], rng)
			if str(r["result"]) != "cleared":
				break
			cleared[i] += 1
			patch_up(crew)
	var odds: Array = []
	for i in range(floors.size()):
		odds.append(float(cleared[i]) / maxf(1.0, float(reached[i])))
	var deaths: int = 0
	var haul: float = 0.0
	var floors_done: float = 0.0
	for t in range(trials):
		var run: Dictionary = simulate(fighters, dungeon, depth, turn_back, rng)
		if not (run["dead"] as Array).is_empty():
			deaths += 1
		floors_done += float(run["cleared"])
		var carried: Dictionary = run["carry"]
		haul += float(carried.get("coin", 0))
		for good in carried:
			if good != "coin":
				haul += float(carried[good]) * float(price.call(str(good)))
	return {"odds": odds, "death": float(deaths) / float(trials), "haul": haul / float(trials), "floors": floors_done / float(trials)}

## One whole run under standing orders, with no player in the loop.
static func simulate(fighters: Array, dungeon: Dictionary, depth: int, turn_back: String, rng: RandomNumberGenerator) -> Dictionary:
	var crew: Array = copies(fighters)
	var carry: Dictionary = {}
	var dead: Array = []
	var done: int = 0
	var floors: Array = dungeon["floors"]
	for i in range(floors.size()):
		var alive: Array = crew.filter(func(c): return float(c["hp"]) > 0.0)
		var r: Dictionary = fight(alive, floors[i], rng, float(RETREAT_AT.get(turn_back, 0.0)))
		dead.append_array(r["dead"])
		if str(r["result"]) == "wiped":
			carry.clear()
			break
		if not (r["dead"] as Array).is_empty():
			drop_half(carry)
		if str(r["result"]) != "cleared":
			break
		done += 1
		patch_up(crew)
		add_loot(carry, floors[i], crew.filter(func(c): return float(c["hp"]) > 0.0), rng)
		if not keep_going(crew, done, depth, turn_back, not dead.is_empty(), floors.size()):
			break
	return {"carry": carry, "dead": dead, "cleared": done}

## Should the crew go down another floor under its orders?
static func keep_going(crew: Array, done: int, depth: int, turn_back: String, someone_died: bool, total: int) -> bool:
	if done >= mini(depth, total):
		return false
	match turn_back:
		"half":
			return not crew.any(func(c): return float(c["hp"]) > 0.0 and float(c["hp"]) < 50.0)
		"death":
			return not someone_died
	return true

## A cleared floor's coin and goods. Porters carry more out.
static func add_loot(carry: Dictionary, floor: Dictionary, alive: Array, rng: RandomNumberGenerator) -> void:
	var porters: int = alive.filter(func(c): return bool(c["porter"])).size()
	var mult: float = 1.0 + 0.5 * float(porters)
	carry["coin"] = int(carry.get("coin", 0)) + int(round(float(rng.randi_range(int(floor["coin"][0]), int(floor["coin"][1]))) * mult))
	for good in floor.get("loot", {}):
		var span: Array = floor["loot"][good]
		var n: int = int(round(float(rng.randi_range(int(span[0]), int(span[1]))) * mult))
		if n > 0:
			carry[good] = int(carry.get(good, 0)) + n
	var rare: Dictionary = floor.get("rare", {})
	if not rare.is_empty() and rng.randf() < float(rare["chance"]):
		carry[str(rare["good"])] = int(carry.get(str(rare["good"]), 0)) + 1

## A death makes the survivors drop half of everything they carry.
static func drop_half(carry: Dictionary) -> Dictionary:
	var dropped: Dictionary = {}
	for good in carry.keys():
		var lost: int = int(carry[good]) / 2 + (int(carry[good]) % 2)
		if lost > 0:
			dropped[good] = lost
			carry[good] = int(carry[good]) - lost
	return dropped
