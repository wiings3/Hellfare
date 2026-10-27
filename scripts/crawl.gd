extends RefCounted
class_name Crawl
## The crypt fight, turn by turn. One engine for everything: the fight the player leads on the
## crawl screen, the automatic runs that go on while they're away, and the forecasts. So a stat
## does the same thing whoever is choosing.
##
## A fight is a plain Dictionary (it is saved with the run, so a led crawl survives the game
## closing):
##   party  fighter dictionaries (Heroes.fighter or Dungeons.fighter) plus turn state
##   foes   the floor's monsters
##   queue  who acts next this round: ["h", i] or ["f", i]
##   log    everything that happened, as events (see _ev)
##   result "" while fighting, then "cleared", "fled" or "wiped"
##
## Each round every living fighter gains its speed in "acc" and acts once per whole point, so a
## fast dagger acts more often than a greatsword. Turns go fastest first.

## Damage reduction from armour: hits are scaled by K / (K + armour).
const ARMOUR_K := 50.0
## A guarding hero takes this share of a blow by class (Heroes.CLASSES "guard_take").
const GUARD_TAKE_DEFAULT := 0.5
## Turns before a class skill can be used again.
const SKILL_COOLDOWN := 3
const BASH_MULT := 0.6
const BACKSTAB_MULT := 1.5
## A boss winds up every third action, then hits this much harder.
const HEAVY_EVERY := 3
const HEAVY_MULT := 2.0
## A fight that hasn't ended by now ends with the heroes backing out.
const MAX_ROUNDS_AUTO := 30
const MAX_ROUNDS_LED := 40
## Below this share of health an automatic hero drinks a potion if it has one.
const POTION_AT := 0.35

# --- Starting ----------------------------------------------------------------------------

## A new fight between `party` (fighter dictionaries, used in place) and a floor's monsters.
static func start(party: Array, floor: Dictionary, seed_value: int, led: bool = false) -> Dictionary:
	var foes: Array = []
	var n: int = int(floor.get("count", 1))
	var foe_name: String = str(floor.get("foe", "Monster"))
	var single: String = str(floor.get("one", _singular(foe_name)))
	for i in range(n):
		foes.append({
			"name": foe_name if n == 1 else "%s %d" % [single, i + 1], "kind": str(floor.get("kind", "")),
			"hp": float(floor["hp"]), "max_hp": float(floor["hp"]), "damage": float(floor["damage"]),
			"speed": float(floor["speed"]), "armour": float(floor.get("armour", 0.0)), "boss": bool(floor.get("boss", false)),
			"acc": 0.0, "stun": 0, "acts": 0, "winding": false,
		})
	for f in party:
		f["acc"] = 0.0
		f["cd"] = 0
		f["guard"] = false
		f["stun"] = 0
		if not f.has("max_hp"):
			f["max_hp"] = 100.0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var st: Dictionary = {"party": party, "foes": foes, "queue": [], "round": 0, "result": "", "led": led,
		"auto_potion": not led, "seed": seed_value, "rng_state": str(rng.state), "log": [], "stats": {}, "floor": str(floor.get("name", ""))}
	for i in range(party.size()):
		st["stats"][str(i)] = {"hits": 0, "crits": 0, "dealt": 0.0, "best": 0.0, "taken": 0.0, "turned": 0.0, "dodged": 0, "blocked": 0, "kills": 0}
	# A first strike: one free action before the fight starts.
	for f in party:
		if not bool(f.get("porter", false)) and rng.randf() < float(f.get("first", 0.0)):
			f["acc"] = 1.0
	st["rng_state"] = str(rng.state)
	_advance(st)
	return st

static func _singular(plural: String) -> String:
	return plural.substr(0, plural.length() - 1) if plural.ends_with("s") else plural

static func _rng(st: Dictionary) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(st["seed"])
	rng.state = str(st["rng_state"]).to_int()
	return rng

# --- Whose turn ------------------------------------------------------------------------

static func done(st: Dictionary) -> bool:
	return str(st["result"]) != ""

## The party member whose turn it is (index), or -1 when the fight is over.
static func turn_of(st: Dictionary) -> int:
	if done(st) or (st["queue"] as Array).is_empty():
		return -1
	var q: Array = st["queue"][0]
	return int(q[1]) if str(q[0]) == "h" else -1

static func alive(list: Array) -> Array:
	return list.filter(func(x): return float(x["hp"]) > 0.0)

static func alive_idx(list: Array) -> Array:
	var out: Array = []
	for i in range(list.size()):
		if float(list[i]["hp"]) > 0.0:
			out.append(i)
	return out

## Run monsters' turns (and new rounds) until a hero has to choose or the fight ends.
static func _advance(st: Dictionary) -> void:
	var rng := _rng(st)
	var guard: int = 0
	while not done(st) and guard < 2000:
		guard += 1
		if _check_end(st):
			break
		var q: Array = st["queue"]
		if q.is_empty():
			if int(st["round"]) >= (MAX_ROUNDS_LED if bool(st["led"]) else MAX_ROUNDS_AUTO):
				st["result"] = "fled"
				_ev(st, "end", "", "", 0.0, "The fight drags on. The heroes back out.")
				break
			_new_round(st, rng)
			continue
		var who: Array = q[0]
		var side: String = str(who[0])
		var i: int = int(who[1])
		var actor: Dictionary = (st["party"] if side == "h" else st["foes"])[i]
		if float(actor["hp"]) <= 0.0:
			q.pop_front()
			continue
		if side == "h":
			if bool(actor.get("porter", false)):
				q.pop_front()
				continue
			# A hero's turn: guard ends, cooldowns tick, and someone has to choose.
			actor["guard"] = false
			break
		q.pop_front()
		_foe_turn(st, i, rng)
	st["rng_state"] = str(rng.state)

static func _new_round(st: Dictionary, rng: RandomNumberGenerator) -> void:
	st["round"] = int(st["round"]) + 1
	var entries: Array = []
	for side in ["h", "f"]:
		var list: Array = st["party"] if side == "h" else st["foes"]
		for i in range(list.size()):
			var a: Dictionary = list[i]
			if float(a["hp"]) <= 0.0:
				continue
			if int(a.get("stun", 0)) > 0:
				a["stun"] = int(a["stun"]) - 1
				_ev(st, "stunned", side + str(i), "", 0.0, "%s is stunned and loses the turn." % str(a["name"]))
				continue
			a["acc"] = float(a["acc"]) + float(a["speed"])
			var k: int = 0
			while float(a["acc"]) >= 1.0:
				a["acc"] = float(a["acc"]) - 1.0
				entries.append({"who": [side, i], "order": float(k) * 10.0 - float(a["speed"]) - rng.randf() * 0.3})
				k += 1
	entries.sort_custom(func(a, b): return float(a["order"]) < float(b["order"]))
	var q: Array = []
	for e in entries:
		q.append(e["who"])
	st["queue"] = q
	_ev(st, "round", "", "", float(st["round"]), "Round %d." % int(st["round"]))

static func _check_end(st: Dictionary) -> bool:
	if alive(st["foes"]).is_empty():
		st["result"] = "cleared"
		_ev(st, "end", "", "", 0.0, "Cleared.")
		return true
	if alive(st["party"]).is_empty():
		st["result"] = "wiped"
		_ev(st, "end", "", "", 0.0, "Nobody is left standing.")
		return true
	return false

# --- The heroes ----------------------------------------------------------------------

## What a hero can do now: [{"id", "label", "ok", "why"}].
static func actions(st: Dictionary, hero_i: int) -> Array:
	var h: Dictionary = st["party"][hero_i]
	var c: Dictionary = Heroes.CLASSES.get(str(h.get("cls", "")), {})
	var out: Array = [{"id": "strike", "label": "Strike", "ok": true, "why": ""}]
	if not c.is_empty():
		var cd: int = int(h.get("cd", 0))
		out.append({"id": "skill", "label": str(c["skill_name"]), "ok": cd <= 0, "why": "Ready in %d" % cd if cd > 0 else ""})
	out.append({"id": "guard", "label": "Guard", "ok": true, "why": ""})
	out.append({"id": "potion", "label": "Potion", "ok": int(h.get("heal", 0)) > 0 and float(h["hp"]) < float(h["max_hp"]),
		"why": "None packed" if int(h.get("heal", 0)) <= 0 else ("Unhurt" if float(h["hp"]) >= float(h["max_hp"]) else "")})
	out.append({"id": "retreat", "label": "Retreat", "ok": true, "why": ""})
	return out

## The hero whose turn it is does `action` on foe `target` (-1: the weakest). Returns the
## events this caused, through the monsters' turns, up to the next hero turn.
static func act(st: Dictionary, action: String, target: int = -1) -> Array:
	var hero_i: int = turn_of(st)
	if hero_i < 0:
		return []
	var start_n: int = (st["log"] as Array).size()
	var rng := _rng(st)
	var h: Dictionary = st["party"][hero_i]
	(st["queue"] as Array).pop_front()
	if int(h.get("cd", 0)) > 0:
		h["cd"] = int(h["cd"]) - 1
	var living: Array = alive_idx(st["foes"])
	if target < 0 or not living.has(target):
		target = _weakest(st["foes"])
	match action:
		"skill":
			var c: String = str(h.get("cls", ""))
			if int(h.get("cd", 0)) > 0 or not Heroes.CLASSES.has(c):
				_strike(st, hero_i, target, rng, 1.0, 1.0, "")
			elif c == "knight":
				_strike(st, hero_i, target, rng, BASH_MULT, 1.0, "bash")
				h["cd"] = SKILL_COOLDOWN
			else:
				_strike(st, hero_i, target, rng, BACKSTAB_MULT, 2.0, "backstab")
				h["cd"] = SKILL_COOLDOWN
		"guard":
			h["guard"] = true
			_ev(st, "guard", "h%d" % hero_i, "", 0.0, "%s raises a guard." % str(h["name"]))
		"potion":
			if int(h.get("heal", 0)) > 0:
				_drink(st, hero_i)
			else:
				_strike(st, hero_i, target, rng, 1.0, 1.0, "")
		"retreat":
			st["result"] = "fled"
			_ev(st, "end", "h%d" % hero_i, "", 0.0, "%s calls the retreat." % str(h["name"]))
		_:
			_strike(st, hero_i, target, rng, 1.0, 1.0, "")
	st["rng_state"] = str(rng.state)
	_advance(st)
	return (st["log"] as Array).slice(start_n)

static func _weakest(foes: Array) -> int:
	var best: int = -1
	for i in alive_idx(foes):
		if best < 0 or float(foes[i]["hp"]) < float(foes[best]["hp"]):
			best = i
	return best

static func _strike(st: Dictionary, hero_i: int, target: int, rng: RandomNumberGenerator, mult: float, crit_mult: float, skill: String) -> void:
	if target < 0:
		return
	var h: Dictionary = st["party"][hero_i]
	var f: Dictionary = st["foes"][target]
	var s: Dictionary = st["stats"][str(hero_i)]
	var hit: float = float(h["damage"]) * mult * rng.randf_range(0.85, 1.15)
	var crit: bool = rng.randf() < minf(0.9, float(h["crit"]) * crit_mult)
	if crit:
		hit *= float(h["crit_damage"])
	hit *= ARMOUR_K / (ARMOUR_K + float(f["armour"]) * (1.0 - float(h.get("pen", 0.0))))
	hit = maxf(1.0, round(hit))
	f["hp"] = float(f["hp"]) - hit
	s["hits"] = int(s["hits"]) + 1
	s["dealt"] = float(s["dealt"]) + hit
	s["best"] = maxf(float(s["best"]), hit)
	if crit:
		s["crits"] = int(s["crits"]) + 1
	var verb: String = {"bash": "shield-bashes", "backstab": "backstabs"}.get(skill, "hits")
	_ev(st, "crit" if crit else "hit", "h%d" % hero_i, "f%d" % target, hit,
		"%s %s %s for %d%s." % [str(h["name"]), verb, str(f["name"]), int(hit), " — a critical blow" if crit else ""], skill)
	var stun_chance: float = 1.0 if skill == "bash" else float(h.get("stun", 0.0))
	if bool(f["boss"]):
		stun_chance *= 0.5
	if float(f["hp"]) > 0.0 and stun_chance > 0.0 and rng.randf() < stun_chance:
		f["stun"] = 1
		f["winding"] = false
		_ev(st, "stun", "h%d" % hero_i, "f%d" % target, 0.0, "%s is stunned." % str(f["name"]))
	if float(f["hp"]) <= 0.0:
		f["hp"] = 0.0
		s["kills"] = int(s["kills"]) + 1
		_ev(st, "kill", "h%d" % hero_i, "f%d" % target, 0.0, "%s falls." % str(f["name"]))

static func _drink(st: Dictionary, hero_i: int) -> void:
	var h: Dictionary = st["party"][hero_i]
	var before: float = float(h["hp"])
	h["hp"] = minf(float(h["max_hp"]), before + float(h["heal"]))
	h["heal"] = 0
	h["drank"] = true
	_ev(st, "potion", "h%d" % hero_i, "h%d" % hero_i, float(h["hp"]) - before, "%s drinks a healing draught: +%d." % [str(h["name"]), int(float(h["hp"]) - before)])

# --- The monsters ----------------------------------------------------------------------

static func _foe_turn(st: Dictionary, foe_i: int, rng: RandomNumberGenerator) -> void:
	var f: Dictionary = st["foes"][foe_i]
	var targets: Array = alive_idx(st["party"])
	if targets.is_empty():
		return
	f["acts"] = int(f["acts"]) + 1
	var heavy: bool = false
	if bool(f["boss"]):
		if bool(f["winding"]):
			heavy = true
			f["winding"] = false
		elif int(f["acts"]) % HEAVY_EVERY == 0:
			f["winding"] = true
			_ev(st, "wind", "f%d" % foe_i, "", 0.0, "%s draws back for a heavy blow. Guard!" % str(f["name"]))
			return
	var vi: int = _pick_target(st["party"], targets, rng)
	var v: Dictionary = st["party"][vi]
	var s: Dictionary = st["stats"][str(vi)]
	var src: String = "f%d" % foe_i
	var dst: String = "h%d" % vi
	if rng.randf() < float(v.get("dodge", 0.0)):
		s["dodged"] = int(s["dodged"]) + 1
		_ev(st, "dodge", src, dst, 0.0, "%s dodges %s." % [str(v["name"]), str(f["name"])])
		return
	if rng.randf() < float(v.get("parry", 0.0)):
		s["dodged"] = int(s["dodged"]) + 1
		_ev(st, "parry", src, dst, 0.0, "%s parries %s." % [str(v["name"]), str(f["name"])])
		return
	var blow: float = float(f["damage"]) * rng.randf_range(0.8, 1.2) * (HEAVY_MULT if heavy else 1.0)
	var raw: float = blow
	var blocked: bool = rng.randf() < float(v.get("block", 0.0))
	if blocked:
		blow *= 0.5
		s["blocked"] = int(s["blocked"]) + 1
	blow *= ARMOUR_K / (ARMOUR_K + float(v.get("armour", 0.0)))
	if bool(v.get("guard", false)):
		blow *= float(Heroes.CLASSES.get(str(v.get("cls", "")), {}).get("guard_take", GUARD_TAKE_DEFAULT))
	if bool(v.get("porter", false)):
		blow *= 1.3
	blow = maxf(1.0, round(blow))
	s["turned"] = float(s["turned"]) + maxf(0.0, raw - blow)
	s["taken"] = float(s["taken"]) + blow
	v["hp"] = float(v["hp"]) - blow
	var how: String = ""
	if heavy:
		how = " with a heavy blow"
	var tail: String = ""
	if blocked:
		tail = " (blocked)"
	elif bool(v.get("guard", false)):
		tail = " (guarded)"
	_ev(st, "heavy" if heavy else "struck", src, dst, blow, "%s hits %s%s for %d%s." % [str(f["name"]), str(v["name"]), how, int(blow), tail])
	if bool(st["auto_potion"]) and float(v["hp"]) > 0.0 and float(v["hp"]) < float(v["max_hp"]) * POTION_AT and int(v.get("heal", 0)) > 0:
		_drink(st, vi)
	if float(v["hp"]) <= 0.0:
		if bool(v.get("lucky", false)) and rng.randf() < 1.0 / 3.0:
			v["hp"] = 5.0
			v["lucky"] = false
			v["saved"] = true
			_ev(st, "lucky", dst, "", 0.0, "%s should have fallen. Lucky." % str(v["name"]))
		else:
			v["hp"] = 0.0
			_ev(st, "death", dst, src, 0.0, "%s falls." % str(v["name"]))

## Monsters go for whoever draws them: knights most (and more when guarding), rogues least,
## porters at the back less often.
static func _pick_target(party: Array, targets: Array, rng: RandomNumberGenerator) -> int:
	var weights: Array = []
	var total: float = 0.0
	for i in targets:
		var p: Dictionary = party[i]
		var w: float = 0.6 if bool(p.get("porter", false)) else float(Heroes.CLASSES.get(str(p.get("cls", "")), {}).get("aggro", 1.0))
		if bool(p.get("guard", false)) and str(p.get("cls", "")) == "knight":
			w *= 1.5
		weights.append(w)
		total += w
	var roll: float = rng.randf() * total
	for k in range(targets.size()):
		roll -= float(weights[k])
		if roll <= 0.0:
			return int(targets[k])
	return int(targets.back())

# --- Without the player --------------------------------------------------------------

## What an automatic hero does: drink when badly hurt, guard against a boss's heavy blow,
## use the skill when it's ready, otherwise strike the weakest foe.
static func ai_choice(st: Dictionary, hero_i: int) -> Array:
	var h: Dictionary = st["party"][hero_i]
	var hp_share: float = float(h["hp"]) / maxf(1.0, float(h["max_hp"]))
	if int(h.get("heal", 0)) > 0 and hp_share < POTION_AT:
		return ["potion", -1]
	for i in alive_idx(st["foes"]):
		if bool(st["foes"][i]["winding"]) and hp_share < 0.6:
			if str(h.get("cls", "")) == "knight" and int(h.get("cd", 0)) <= 0:
				return ["skill", i]
			return ["guard", -1]
	if Heroes.CLASSES.has(str(h.get("cls", ""))) and int(h.get("cd", 0)) <= 0:
		var t: int = _weakest(st["foes"])
		if str(h.get("cls", "")) == "knight":
			# Bash the hardest hitter.
			var best: int = -1
			for i in alive_idx(st["foes"]):
				if best < 0 or float(st["foes"][i]["damage"]) > float(st["foes"][best]["damage"]):
					best = i
			t = best
		return ["skill", t]
	return ["strike", -1]

## Play the fight out with every hero choosing by ai_choice. `retreat_below` (hit points)
## makes the party back out when anyone drops under it.
static func run_auto(st: Dictionary, retreat_below: float = 0.0) -> void:
	var guard: int = 0
	while not done(st) and guard < 5000:
		guard += 1
		var i: int = turn_of(st)
		if i < 0:
			break
		if retreat_below > 0.0 and (st["party"] as Array).any(func(p): return float(p["hp"]) > 0.0 and float(p["hp"]) < retreat_below):
			st["result"] = "fled"
			_ev(st, "end", "", "", 0.0, "The heroes back out, as ordered.")
			break
		var c: Array = ai_choice(st, i)
		act(st, str(c[0]), int(c[1]))

# --- Telling it ---------------------------------------------------------------------

static func _ev(st: Dictionary, kind: String, src: String, dst: String, amount: float, text: String, skill: String = "") -> void:
	(st["log"] as Array).append({"kind": kind, "src": src, "dst": dst, "amount": amount, "text": text, "skill": skill})

## A few lines for the report: how it ended, the best blows, what armour turned, who fell.
static func recap(st: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var foes: Array = st["foes"]
	var foe: String = str(foes[0]["name"]) if foes.size() == 1 else str(st.get("floor", "the floor"))
	var boss: bool = foes.size() == 1 and bool(foes[0]["boss"])
	match str(st["result"]):
		"cleared":
			lines.append("%s in %d rounds." % ["Beat " + foe if boss else "Cleared " + foe, int(st["round"])])
		"fled":
			lines.append("Backed out of %s after %d rounds." % [foe, int(st["round"])])
		"wiped":
			lines.append("%s killed everyone." % foe)
	var worst: float = 0.0
	var worst_from: String = ""
	for e in st["log"]:
		if str(e["kind"]) in ["struck", "heavy"] and float(e["amount"]) > worst:
			worst = float(e["amount"])
			worst_from = str(e["src"])
	var party: Array = st["party"]
	for i in range(party.size()):
		var p: Dictionary = party[i]
		var s: Dictionary = st["stats"][str(i)]
		if bool(p.get("porter", false)):
			continue
		var bits: Array[String] = []
		if int(s["hits"]) > 0:
			bits.append("%d hits for %d" % [int(s["hits"]), int(s["dealt"])])
		if int(s["crits"]) > 0:
			bits.append("%d %s" % [int(s["crits"]), "crit" if int(s["crits"]) == 1 else "crits"])
		if float(s["best"]) > 0.0:
			bits.append("best %d" % int(s["best"]))
		if float(s["turned"]) >= 1.0:
			bits.append("armour and guard turned %d" % int(s["turned"]))
		if int(s["dodged"]) > 0:
			bits.append("avoided %d" % int(s["dodged"]))
		if not bits.is_empty():
			lines.append("%s: %s." % [str(p["name"]), ", ".join(bits)])
	if worst > 0.0 and worst_from.begins_with("f"):
		lines.append("Hardest blow taken: %d, from %s." % [int(worst), str(foes[int(worst_from.substr(1))]["name"])])
	for p in party:
		if float(p["hp"]) <= 0.0:
			lines.append("%s fell." % str(p["name"]))
		elif bool(p.get("drank", false)):
			lines.append("%s drank a healing draught." % str(p["name"]))
	return lines
