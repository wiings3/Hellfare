extends RefCounted
class_name Crawl
## The crypt fight, turn by turn: "Light and Loadout". One engine for everything: the fight the
## player leads on the crawl screen, the automatic runs that go on while they're away, and the
## forecasts. So a stat does the same thing whoever is choosing.
##
## Three things make a fight:
##   Loadout  a hero's moves come from their gear. The weapon gives a plain attack and a special
##            (a sword's Riposte, a mace's Crush, a greatsword's Cleave...), a shield turns Guard
##            into Block or Parry, the potion slot gives a drink, and the class adds its skill.
##            New weapons and classes add moves: see MOVES and CLASS_SKILLS.
##   Light    the party's lantern. It burns a point every round, and specials and skills spend
##            it too. Lamp oil (fish oil, packed from the warehouse) refills it. In the dark the
##            monsters' next moves can't be seen, they hit harder, and more crawl out.
##   Intents  every monster shows what it will do next (attack, a heavy blow, a raised shield,
##            web, fire...), following its kind's pattern (PATTERNS). A stun cancels it.
##
## A fight is a plain Dictionary (saved with the run, so a led crawl survives the game closing):
##   party  fighter dictionaries (Heroes.fighter) plus turn state
##   foes   the floor's monsters, with their intents
##   queue  who acts next this round: ["h", i] or ["f", i]
##   light, light_max, oil   the lantern
##   log    everything that happened, as events (see _ev)
##   result "" while fighting, then "cleared", "fled" or "wiped"
##
## Each round every living fighter gains its speed in "acc" and acts once per whole point, so a
## fast dagger acts more often than a greatsword. Turns go fastest first.

## Damage reduction from armour: hits are scaled by K / (K + armour).
const ARMOUR_K := 50.0
## A guarding hero takes this share of a blow by class (Heroes.CLASSES "guard_take").
const GUARD_TAKE_DEFAULT := 0.5
## A shield's Block takes this much off the class's guard on top.
const BLOCK_TAKE := 0.6
## A heavy blow (the "heavy" intent) hits this much harder.
const HEAVY_MULT := 2.0
## A fight that hasn't ended by now ends with the heroes backing out.
const MAX_ROUNDS_AUTO := 30
const MAX_ROUNDS_LED := 40
## Below this share of health an automatic hero drinks a potion if it has one.
const POTION_AT := 0.35

## The lantern: what it holds without a lantern, and what lanterns add by tier.
const LIGHT_BASE := 24
const LANTERN_LIGHT := {1: 4, 2: 5, 3: 7, 4: 8, 5: 10}
## A flask of lamp oil (one fish oil) brings back this much light.
const OIL_LIGHT := 8
## How much oil a run packs per hero from the warehouse.
const OIL_PER_HERO := 2
## In the dark: monsters hit this much harder, and each round this is the chance that one more
## crawls out (at most DARK_SPAWNS a fight).
const DARK_DAMAGE := 1.3
const DARK_SPAWN := 0.3
const DARK_SPAWNS := 2

## Weapon families and their two moves: the plain attack (free) and the special (costs light).
## mult: damage; crit: crit chance multiplier; then what the special does.
const MOVES := {
	"sword": {"strike": {"name": "Strike", "mult": 1.0}, "special": {"name": "Riposte", "cost": 1, "kind": "riposte",
		"text": "Guard, and strike back at the first monster that hits you before your next turn."}},
	"dagger": {"strike": {"name": "Stab", "mult": 0.9, "crit": 1.3}, "special": {"name": "Open a Vein", "cost": 1, "kind": "bleed", "mult": 0.6,
		"text": "A shallow cut that bleeds for three rounds."}},
	"war_axe": {"strike": {"name": "Chop", "mult": 1.05}, "special": {"name": "Sunder", "cost": 1, "kind": "sunder", "mult": 0.9,
		"text": "Splits their armour: it counts for half for the rest of the fight."}},
	"mace": {"strike": {"name": "Bludgeon", "mult": 1.0}, "special": {"name": "Crush", "cost": 1, "kind": "crush", "mult": 0.8,
		"text": "A blow to the head: likely to stun, which cancels what they were about to do."}},
	"spear": {"strike": {"name": "Thrust", "mult": 1.0, "pen": 0.15}, "special": {"name": "Sweep", "cost": 1, "kind": "sweep", "mult": 0.7,
		"text": "Hits two monsters."}},
	"greatsword": {"strike": {"name": "Hew", "mult": 1.0}, "special": {"name": "Cleave", "cost": 1, "kind": "cleave", "mult": 0.65,
		"text": "Hits every monster."}},
	"bow": {"strike": {"name": "Shoot", "mult": 0.95}, "special": {"name": "Aimed Shot", "cost": 1, "kind": "aimed", "mult": 1.7,
		"text": "A careful shot that ignores a raised shield."}},
	"crossbow": {"strike": {"name": "Loose", "mult": 1.0}, "special": {"name": "Pinning Bolt", "cost": 1, "kind": "pin", "mult": 0.8,
		"text": "Pins them: they lose their next turn half the time."}},
	"fists": {"strike": {"name": "Punch", "mult": 1.0}},
}
## Class skills (cost light; one per class for now).
const CLASS_SKILLS := {
	"knight": {"name": "Shield Bash", "cost": 2, "kind": "bash", "mult": 0.6,
		"text": "Stuns the monster: it loses its next turn, and whatever it was about to do."},
	"rogue": {"name": "Backstab", "cost": 2, "kind": "backstab", "mult": 1.1,
		"text": "Hits a busy monster (shield up, winding up, stunned or webbing) for far more, with twice the chance to crit."},
}
const BACKSTAB_BUSY_MULT := 2.6

## Monster patterns: what each kind does, in turn (from a random point in the cycle).
## attack, heavy (a big blow at one hero), shield (raise a shield until its next turn),
## web (the hero loses their next turn, unless they're braced), fire (hits every hero), summon
## (calls a skeleton, when the monster is alone).
const PATTERNS := {
	"skeleton": ["attack", "attack", "shield"],
	"spider": ["attack", "web", "attack"],
	"death_knight": ["attack", "heavy", "attack", "attack", "summon"],
	"imp": ["attack", "fire"],
	"devil": ["attack", "heavy", "fire"],
}
const INTENT_TEXT := {"attack": "Attack", "heavy": "Heavy blow", "shield": "Shield up", "web": "Web", "fire": "Fire", "summon": "Summon"}
## How much a raised shield adds to armour, and fire's share of a monster's blow on each hero.
const SHIELD_ARMOUR := 30.0
const FIRE_MULT := 0.6
const SUMMONED := {"name": "Risen skeleton", "kind": "skeleton", "hp": 14.0, "damage": 6.0, "speed": 1.0, "armour": 0.0}

# --- Starting ----------------------------------------------------------------------------

## A new fight between `party` (fighter dictionaries, used in place) and a floor's monsters.
## The floor may carry the run's lantern ("light", "oil"); otherwise it starts full.
static func start(party: Array, floor: Dictionary, seed_value: int, led: bool = false) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var foes: Array = []
	# A floor is one kind of monster (count of them), or a mixed band ("foes": [defs]).
	var defs: Array = floor.get("foes", []).duplicate()
	if defs.is_empty():
		var n: int = int(floor.get("count", 1))
		var foe_name: String = str(floor.get("foe", "Monster"))
		var single: String = str(floor.get("one", _singular(foe_name)))
		for i in range(n):
			var one: Dictionary = floor.duplicate()
			one["name"] = foe_name if n == 1 else "%s %d" % [single, i + 1]
			defs.append(one)
	for fd in defs:
		foes.append(_new_foe(fd, str(floor.get("kind", "")), rng))
	for f in party:
		f["acc"] = 0.0
		f["guard"] = ""
		f["stun"] = 0
		if not f.has("max_hp"):
			f["max_hp"] = 100.0
	var top: int = light_max(party)
	var st: Dictionary = {"party": party, "foes": foes, "queue": [], "round": 0, "result": "", "led": led,
		"auto_potion": not led, "seed": seed_value, "rng_state": "", "log": [], "stats": {}, "floor": str(floor.get("name", "")),
		"light": clampi(int(floor.get("light", top)), 0, top), "light_max": top, "oil": int(floor.get("oil", 0)),
		"spawned": 0, "base": {"name": str(floor.get("one", floor.get("foe", "Monster"))), "kind": str(floor.get("kind", "")),
			"hp": float(floor.get("hp", 10.0)), "damage": float(floor.get("damage", 5.0)), "speed": float(floor.get("speed", 1.0)), "armour": float(floor.get("armour", 0.0))}}
	for i in range(party.size()):
		st["stats"][str(i)] = {"hits": 0, "crits": 0, "dealt": 0.0, "best": 0.0, "taken": 0.0, "turned": 0.0, "dodged": 0, "blocked": 0, "kills": 0}
	# A first strike: one free action before the fight starts.
	for f in party:
		if not bool(f.get("porter", false)) and rng.randf() < float(f.get("first", 0.0)):
			f["acc"] = 1.0
	for i in range(foes.size()):
		_next_intent(st, i, rng)
	st["rng_state"] = str(rng.state)
	_advance(st)
	return st

static func _new_foe(fd: Dictionary, floor_kind: String, rng: RandomNumberGenerator) -> Dictionary:
	var kind: String = str(fd.get("kind", floor_kind))
	var pattern: Array = PATTERNS.get(kind, ["attack"])
	return {
		"name": str(fd.get("name", "Monster")), "kind": kind,
		"hp": float(fd["hp"]), "max_hp": float(fd["hp"]), "damage": float(fd["damage"]),
		"speed": float(fd["speed"]), "armour": float(fd.get("armour", 0.0)), "boss": bool(fd.get("boss", false)),
		"acc": 0.0, "stun": 0, "acts": 0, "step": rng.randi_range(0, pattern.size() - 1),
		"intent": "attack", "intent_target": -1, "shield_up": false, "bleed": 0, "bleed_dmg": 0.0, "sundered": false,
	}

static func _singular(plural: String) -> String:
	return plural.substr(0, plural.length() - 1) if plural.ends_with("s") else plural

static func _rng(st: Dictionary) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(st["seed"])
	rng.state = str(st["rng_state"]).to_int()
	return rng

## The party's lantern: the base light plus the best lantern any of them carries.
static func light_max(party: Array) -> int:
	var best: int = 0
	for p in party:
		best = maxi(best, int(LANTERN_LIGHT.get(int(p.get("lantern", 0)), 0)))
	return LIGHT_BASE + best

static func dark(st: Dictionary) -> bool:
	return int(st.get("light", 1)) <= 0

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
			# A hero's turn: their guard drops, and someone has to choose.
			actor["guard"] = ""
			break
		q.pop_front()
		_foe_turn(st, i, rng)
	st["rng_state"] = str(rng.state)

static func _new_round(st: Dictionary, rng: RandomNumberGenerator) -> void:
	st["round"] = int(st["round"]) + 1
	# The lantern burns down; in the dark, things crawl out.
	var was_dark: bool = dark(st)
	st["light"] = maxi(0, int(st["light"]) - 1)
	if dark(st) and not was_dark:
		_ev(st, "dark", "", "", 0.0, "The lantern gutters out. In the dark you can't see what they'll do, and they hit harder.")
	elif int(st["light"]) == 3:
		_ev(st, "dim", "", "", 3.0, "The lantern is burning low.")
	if dark(st) and int(st["spawned"]) < DARK_SPAWNS and rng.randf() < DARK_SPAWN:
		_spawn(st, st["base"], "Something from the dark", rng)
	# Bleeding monsters lose blood.
	for i in range(st["foes"].size()):
		var f: Dictionary = st["foes"][i]
		if float(f["hp"]) > 0.0 and int(f["bleed"]) > 0:
			f["bleed"] = int(f["bleed"]) - 1
			var b: float = maxf(1.0, round(float(f["bleed_dmg"])))
			f["hp"] = float(f["hp"]) - b
			_ev(st, "bleed", "", "f%d" % i, b, "%s bleeds for %d." % [str(f["name"]), int(b)])
			if float(f["hp"]) <= 0.0:
				f["hp"] = 0.0
				_ev(st, "kill", "", "f%d" % i, 0.0, "%s bleeds out." % str(f["name"]))
	var entries: Array = []
	for side in ["h", "f"]:
		var list: Array = st["party"] if side == "h" else st["foes"]
		for i in range(list.size()):
			var a: Dictionary = list[i]
			if float(a["hp"]) <= 0.0:
				continue
			if int(a.get("stun", 0)) > 0:
				a["stun"] = int(a["stun"]) - 1
				if side == "f":
					# A stun cancels what it was about to do.
					var lost: String = str(a["intent"])
					a["shield_up"] = false
					_next_intent(st, i, rng)
					_ev(st, "stunned", side + str(i), "", 0.0, "%s is stunned and loses the turn%s." % [str(a["name"]), (" (and its %s)" % INTENT_TEXT.get(lost, lost).to_lower()) if lost != "attack" else ""])
				else:
					_ev(st, "stunned", side + str(i), "", 0.0, "%s is held fast and loses the turn." % str(a["name"]))
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

static func _spawn(st: Dictionary, base: Dictionary, name: String, rng: RandomNumberGenerator) -> void:
	var fd: Dictionary = base.duplicate()
	fd["name"] = name
	fd["hp"] = maxf(4.0, float(base["hp"]) * 0.6)
	fd["boss"] = false
	st["foes"].append(_new_foe(fd, str(base.get("kind", "")), rng))
	st["spawned"] = int(st["spawned"]) + 1
	_next_intent(st, st["foes"].size() - 1, rng)
	_ev(st, "spawn", "", "f%d" % (st["foes"].size() - 1), 0.0, "%s crawls out of the dark." % name if name.begins_with("Something") else "%s joins the fight." % name)

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

## A hero's weapon family ("sword", "dagger"... or "fists").
static func family(h: Dictionary) -> String:
	var w: String = str(h.get("weapon", ""))
	return w if MOVES.has(w) else "fists"

## What a hero can do now: [{"id", "label", "ok", "why", "cost", "text"}]. Ids: strike, special,
## skill, guard, potion, oil, retreat.
static func actions(st: Dictionary, hero_i: int) -> Array:
	var h: Dictionary = st["party"][hero_i]
	var moves: Dictionary = MOVES[family(h)]
	var light: int = int(st.get("light", 0))
	var out: Array = [{"id": "strike", "label": str(moves["strike"]["name"]), "ok": true, "why": "", "cost": 0,
		"text": "Your weapon's plain attack. Costs no light."}]
	if moves.has("special"):
		var sp: Dictionary = moves["special"]
		out.append({"id": "special", "label": str(sp["name"]), "ok": light >= int(sp["cost"]), "why": "" if light >= int(sp["cost"]) else "No light",
			"cost": int(sp["cost"]), "text": str(sp["text"])})
	var sk: Dictionary = CLASS_SKILLS.get(str(h.get("cls", "")), {})
	if not sk.is_empty():
		out.append({"id": "skill", "label": str(sk["name"]), "ok": light >= int(sk["cost"]), "why": "" if light >= int(sk["cost"]) else "No light",
			"cost": int(sk["cost"]), "text": str(sk["text"])})
	var g: Array = _guard_kind(h)
	out.append({"id": "guard", "label": str(g[0]), "ok": true, "why": "", "cost": 0, "text": str(g[1])})
	out.append({"id": "potion", "label": "Drink", "ok": int(h.get("heal", 0)) > 0 and float(h["hp"]) < float(h["max_hp"]), "cost": 0,
		"why": "None packed" if int(h.get("heal", 0)) <= 0 else ("Unhurt" if float(h["hp"]) >= float(h["max_hp"]) else ""),
		"text": "Drink your healing draught: +%d." % int(h.get("heal", 0))})
	out.append({"id": "oil", "label": "Trim the Lantern", "ok": int(st.get("oil", 0)) > 0 and light < int(st.get("light_max", LIGHT_BASE)), "cost": 0,
		"why": "No oil" if int(st.get("oil", 0)) <= 0 else ("Full" if light >= int(st.get("light_max", LIGHT_BASE)) else ""),
		"text": "Pour in a flask of lamp oil: +%d light. %d left." % [OIL_LIGHT, int(st.get("oil", 0))]})
	out.append({"id": "retreat", "label": "Retreat", "ok": true, "why": "", "cost": 0, "text": "Back out of this floor with what you carry."})
	return out

## What Guard is for this hero: [label, text]. A kite or tower shield makes it Block, a
## buckler makes it Parry.
static func _guard_kind(h: Dictionary) -> Array:
	match str(h.get("shield", "")):
		"kite_shield", "tower_shield":
			return ["Block", "Behind the shield: take far less from the next blows, heavy ones too."]
		"buckler":
			return ["Parry", "Ready to turn a blow aside: take less, and half the time turn it away and strike back."]
	return ["Guard", "Brace: take less from the next blows until your turn comes again."]

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
	var living: Array = alive_idx(st["foes"])
	if target < 0 or not living.has(target):
		target = _weakest(st["foes"])
	var moves: Dictionary = MOVES[family(h)]
	match action:
		"special":
			var sp: Dictionary = moves.get("special", {})
			if sp.is_empty() or int(st["light"]) < int(sp["cost"]):
				_attack(st, hero_i, target, rng, moves["strike"], "")
			else:
				st["light"] = int(st["light"]) - int(sp["cost"])
				_special(st, hero_i, target, rng, sp)
		"skill":
			var sk: Dictionary = CLASS_SKILLS.get(str(h.get("cls", "")), {})
			if sk.is_empty() or int(st["light"]) < int(sk["cost"]):
				_attack(st, hero_i, target, rng, moves["strike"], "")
			else:
				st["light"] = int(st["light"]) - int(sk["cost"])
				_special(st, hero_i, target, rng, sk)
		"guard":
			var g: Array = _guard_kind(h)
			h["guard"] = str(g[0]).to_lower()
			_ev(st, "guard", "h%d" % hero_i, "", 0.0, "%s %s." % [str(h["name"]), {"block": "raises the shield", "parry": "readies the buckler"}.get(str(h["guard"]), "braces")])
		"potion":
			if int(h.get("heal", 0)) > 0:
				_drink(st, hero_i)
			else:
				_attack(st, hero_i, target, rng, moves["strike"], "")
		"oil":
			if int(st.get("oil", 0)) > 0:
				st["oil"] = int(st["oil"]) - 1
				var before: int = int(st["light"])
				st["light"] = mini(int(st["light_max"]), before + OIL_LIGHT)
				_ev(st, "oil", "h%d" % hero_i, "", float(int(st["light"]) - before), "%s trims the lantern. The light comes back." % str(h["name"]))
			else:
				_attack(st, hero_i, target, rng, moves["strike"], "")
		"retreat":
			st["result"] = "fled"
			_ev(st, "end", "h%d" % hero_i, "", 0.0, "%s calls the retreat." % str(h["name"]))
		_:
			_attack(st, hero_i, target, rng, moves["strike"], "")
	st["rng_state"] = str(rng.state)
	_advance(st)
	return (st["log"] as Array).slice(start_n)

static func _weakest(foes: Array) -> int:
	var best: int = -1
	for i in alive_idx(foes):
		if best < 0 or float(foes[i]["hp"]) < float(foes[best]["hp"]):
			best = i
	return best

## A monster too busy to defend itself (for Backstab).
static func busy(f: Dictionary) -> bool:
	return bool(f["shield_up"]) or int(f["stun"]) > 0 or str(f["intent"]) in ["heavy", "web", "summon"]

## A weapon's special or a class skill.
static func _special(st: Dictionary, hero_i: int, target: int, rng: RandomNumberGenerator, mv: Dictionary) -> void:
	var h: Dictionary = st["party"][hero_i]
	match str(mv["kind"]):
		"riposte":
			h["guard"] = "riposte"
			_ev(st, "guard", "h%d" % hero_i, "", 0.0, "%s takes a fencer's guard." % str(h["name"]), "riposte")
		"bleed":
			if _attack(st, hero_i, target, rng, mv, "bleed") > 0.0 and float(st["foes"][target]["hp"]) > 0.0:
				var f: Dictionary = st["foes"][target]
				f["bleed"] = 3
				f["bleed_dmg"] = float(h["damage"]) * 0.45
				_ev(st, "bleeding", "h%d" % hero_i, "f%d" % target, 0.0, "%s is bleeding." % str(f["name"]))
		"sunder":
			_attack(st, hero_i, target, rng, mv, "sunder")
			var f: Dictionary = st["foes"][target]
			if float(f["hp"]) > 0.0 and not bool(f["sundered"]):
				f["sundered"] = true
				_ev(st, "sundered", "h%d" % hero_i, "f%d" % target, 0.0, "%s's armour splits." % str(f["name"]))
		"crush":
			_attack(st, hero_i, target, rng, mv, "crush", 0.6)
		"pin":
			_attack(st, hero_i, target, rng, mv, "pin", 0.5)
		"sweep":
			var hit: Array = [target]
			for i in alive_idx(st["foes"]):
				if hit.size() < 2 and i != target:
					hit.append(i)
			for i in hit:
				_attack(st, hero_i, int(i), rng, mv, "sweep")
		"cleave":
			for i in alive_idx(st["foes"]):
				_attack(st, hero_i, int(i), rng, mv, "cleave")
		"aimed":
			_attack(st, hero_i, target, rng, mv, "aimed")
		"bash":
			_attack(st, hero_i, target, rng, mv, "bash", 1.0)
		"backstab":
			var f: Dictionary = st["foes"][target]
			var m: Dictionary = mv.duplicate()
			if busy(f):
				m["mult"] = BACKSTAB_BUSY_MULT
			m["crit"] = 2.0
			_attack(st, hero_i, target, rng, m, "backstab")
		_:
			_attack(st, hero_i, target, rng, mv, "")

## One blow from a hero. Returns the damage done.
static func _attack(st: Dictionary, hero_i: int, target: int, rng: RandomNumberGenerator, mv: Dictionary, kind: String, stun_chance: float = -1.0) -> float:
	if target < 0 or float(st["foes"][target]["hp"]) <= 0.0:
		return 0.0
	var h: Dictionary = st["party"][hero_i]
	var f: Dictionary = st["foes"][target]
	var s: Dictionary = st["stats"][str(hero_i)]
	var hit: float = float(h["damage"]) * float(mv.get("mult", 1.0)) * rng.randf_range(0.85, 1.15)
	var crit: bool = rng.randf() < minf(0.9, float(h["crit"]) * float(mv.get("crit", 1.0)))
	if crit:
		hit *= float(h["crit_damage"])
	var armour: float = float(f["armour"]) * (0.5 if bool(f["sundered"]) else 1.0)
	if bool(f["shield_up"]) and kind != "aimed":
		armour += SHIELD_ARMOUR
	hit *= ARMOUR_K / (ARMOUR_K + armour * (1.0 - clampf(float(h.get("pen", 0.0)) + float(mv.get("pen", 0.0)), 0.0, 0.9)))
	hit = maxf(1.0, round(hit))
	f["hp"] = float(f["hp"]) - hit
	s["hits"] = int(s["hits"]) + 1
	s["dealt"] = float(s["dealt"]) + hit
	s["best"] = maxf(float(s["best"]), hit)
	if crit:
		s["crits"] = int(s["crits"]) + 1
	var verb: String = {"bash": "shield-bashes", "backstab": "backstabs", "crush": "crushes", "cleave": "cleaves", "sweep": "sweeps",
		"aimed": "puts an aimed shot into", "pin": "pins", "sunder": "hacks at", "bleed": "cuts", "counter": "strikes back at"}.get(kind, "hits")
	_ev(st, "crit" if crit else "hit", "h%d" % hero_i, "f%d" % target, hit,
		"%s %s %s for %d%s." % [str(h["name"]), verb, str(f["name"]), int(hit), " — a critical blow" if crit else ""], kind)
	var chance: float = stun_chance if stun_chance >= 0.0 else float(h.get("stun", 0.0))
	if bool(f["boss"]) and kind != "bash":
		chance *= 0.5
	if float(f["hp"]) > 0.0 and chance > 0.0 and rng.randf() < chance:
		f["stun"] = 1
		_ev(st, "stun", "h%d" % hero_i, "f%d" % target, 0.0, "%s is stunned: its %s is lost." % [str(f["name"]), INTENT_TEXT.get(str(f["intent"]), "turn").to_lower()])
	if float(f["hp"]) <= 0.0:
		f["hp"] = 0.0
		s["kills"] = int(s["kills"]) + 1
		_ev(st, "kill", "h%d" % hero_i, "f%d" % target, 0.0, "%s falls." % str(f["name"]))
	return hit

static func _drink(st: Dictionary, hero_i: int) -> void:
	var h: Dictionary = st["party"][hero_i]
	var before: float = float(h["hp"])
	h["hp"] = minf(float(h["max_hp"]), before + float(h["heal"]))
	h["heal"] = 0
	h["drank"] = true
	_ev(st, "potion", "h%d" % hero_i, "h%d" % hero_i, float(h["hp"]) - before, "%s drinks a healing draught: +%d." % [str(h["name"]), int(float(h["hp"]) - before)])

# --- The monsters ----------------------------------------------------------------------

## Pick what monster `foe_i` does next (and at whom), from its kind's pattern.
static func _next_intent(st: Dictionary, foe_i: int, rng: RandomNumberGenerator) -> void:
	var f: Dictionary = st["foes"][foe_i]
	var pattern: Array = PATTERNS.get(str(f["kind"]), ["attack"])
	var intent: String = str(pattern[int(f["step"]) % pattern.size()])
	f["step"] = int(f["step"]) + 1
	if intent == "summon" and alive(st["foes"]).size() >= 2:
		intent = "attack"
	f["intent"] = intent
	f["intent_target"] = -1
	if intent in ["attack", "heavy", "web"]:
		var targets: Array = alive_idx(st["party"])
		if not targets.is_empty():
			f["intent_target"] = _pick_target(st["party"], targets, rng)

## What a monster will do next, as shown on its card ("?" in the dark).
static func intent_text(st: Dictionary, foe_i: int) -> String:
	var f: Dictionary = st["foes"][foe_i]
	if float(f["hp"]) <= 0.0:
		return ""
	if dark(st):
		return "?"
	var intent: String = str(f["intent"])
	var who: String = ""
	var ti: int = int(f["intent_target"])
	if ti >= 0 and ti < (st["party"] as Array).size():
		who = " at " + str(st["party"][ti]["name"]).get_slice(" ", 0)
	match intent:
		"attack":
			return "Attack %d%s" % [int(round(float(f["damage"]))), who]
		"heavy":
			return "Heavy blow %d%s" % [int(round(float(f["damage"]) * HEAVY_MULT)), who]
		"fire":
			return "Fire %d on everyone" % int(round(float(f["damage"]) * FIRE_MULT))
		"web":
			return "Web%s" % who
	return str(INTENT_TEXT.get(intent, intent))

static func _foe_turn(st: Dictionary, foe_i: int, rng: RandomNumberGenerator) -> void:
	var f: Dictionary = st["foes"][foe_i]
	var targets: Array = alive_idx(st["party"])
	if targets.is_empty():
		return
	f["acts"] = int(f["acts"]) + 1
	f["shield_up"] = false
	var intent: String = str(f["intent"])
	var src: String = "f%d" % foe_i
	match intent:
		"shield":
			f["shield_up"] = true
			_ev(st, "shield", src, "", 0.0, "%s raises its shield." % str(f["name"]))
		"summon":
			_ev(st, "summon", src, "", 0.0, "%s calls the dead to its side." % str(f["name"]))
			_spawn(st, SUMMONED, "Risen skeleton", rng)
		"fire":
			_ev(st, "fire", src, "", 0.0, "%s breathes fire across the party." % str(f["name"]))
			for vi in targets:
				_blow(st, foe_i, int(vi), rng, FIRE_MULT, "fire")
		"web":
			var vi: int = int(f["intent_target"]) if targets.has(int(f["intent_target"])) else _pick_target(st["party"], targets, rng)
			var v: Dictionary = st["party"][vi]
			if str(v.get("guard", "")) != "":
				_ev(st, "web", src, "h%d" % vi, 0.0, "%s spits web, but %s is braced and tears free." % [str(f["name"]), str(v["name"])])
			else:
				v["stun"] = 1
				_ev(st, "web", src, "h%d" % vi, 0.0, "%s webs %s: they lose their next turn." % [str(f["name"]), str(v["name"])])
		_:
			var vi: int = int(f["intent_target"]) if targets.has(int(f["intent_target"])) else _pick_target(st["party"], targets, rng)
			_blow(st, foe_i, vi, rng, HEAVY_MULT if intent == "heavy" else 1.0, intent)
	_next_intent(st, foe_i, rng)

## A monster's blow on hero `vi`.
static func _blow(st: Dictionary, foe_i: int, vi: int, rng: RandomNumberGenerator, mult: float, intent: String) -> void:
	var f: Dictionary = st["foes"][foe_i]
	var v: Dictionary = st["party"][vi]
	var s: Dictionary = st["stats"][str(vi)]
	var src: String = "f%d" % foe_i
	var dst: String = "h%d" % vi
	var heavy: bool = intent == "heavy"
	var guard: String = str(v.get("guard", ""))
	if intent != "fire" and rng.randf() < float(v.get("dodge", 0.0)):
		s["dodged"] = int(s["dodged"]) + 1
		_ev(st, "dodge", src, dst, 0.0, "%s dodges %s." % [str(v["name"]), str(f["name"])])
		return
	var parried: bool = intent != "fire" and (rng.randf() < float(v.get("parry", 0.0)) or (guard == "parry" and rng.randf() < 0.5))
	if parried:
		s["dodged"] = int(s["dodged"]) + 1
		_ev(st, "parry", src, dst, 0.0, "%s turns aside %s's blow." % [str(v["name"]), str(f["name"])])
		if guard == "parry":
			_counter(st, vi, foe_i, rng, 0.6)
		return
	var blow: float = float(f["damage"]) * rng.randf_range(0.8, 1.2) * mult * (DARK_DAMAGE if dark(st) else 1.0)
	var raw: float = blow
	var blocked: bool = rng.randf() < float(v.get("block", 0.0))
	if blocked:
		blow *= 0.5
		s["blocked"] = int(s["blocked"]) + 1
	blow *= ARMOUR_K / (ARMOUR_K + float(v.get("armour", 0.0)))
	if guard != "":
		var take: float = float(Heroes.CLASSES.get(str(v.get("cls", "")), {}).get("guard_take", GUARD_TAKE_DEFAULT))
		if guard == "block":
			take *= BLOCK_TAKE
		blow *= take
	if bool(v.get("porter", false)):
		blow *= 1.3
	blow = maxf(1.0, round(blow))
	s["turned"] = float(s["turned"]) + maxf(0.0, raw - blow)
	s["taken"] = float(s["taken"]) + blow
	v["hp"] = float(v["hp"]) - blow
	var how: String = " with a heavy blow" if heavy else (" with fire" if intent == "fire" else "")
	var tail: String = " (blocked)" if blocked or guard == "block" else (" (guarded)" if guard != "" else "")
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
			return
	if guard == "riposte" and float(f["hp"]) > 0.0:
		# One riposte per guard: the first blow is answered, then it's a plain guard.
		v["guard"] = "guard"
		_counter(st, vi, foe_i, rng, 1.0)

static func _counter(st: Dictionary, hero_i: int, foe_i: int, rng: RandomNumberGenerator, mult: float) -> void:
	if float(st["party"][hero_i]["hp"]) > 0.0:
		_attack(st, hero_i, foe_i, rng, {"mult": mult}, "counter")

## Monsters go for whoever draws them: knights most (and more when guarding), rogues least,
## porters at the back less often.
static func _pick_target(party: Array, targets: Array, rng: RandomNumberGenerator) -> int:
	var weights: Array = []
	var total: float = 0.0
	for i in targets:
		var p: Dictionary = party[i]
		var w: float = 0.6 if bool(p.get("porter", false)) else float(Heroes.CLASSES.get(str(p.get("cls", "")), {}).get("aggro", 1.0))
		weights.append(w)
		total += w
	var roll: float = rng.randf() * total
	for k in range(targets.size()):
		roll -= float(weights[k])
		if roll <= 0.0:
			return int(targets[k])
	return int(targets.back())

# --- Without the player --------------------------------------------------------------

## What an automatic hero does, reading the monsters' intents:
## drink when badly hurt; trim the lantern when it's nearly out; bash (knight) whatever is about
## to do something dangerous; guard against a heavy blow aimed at them; backstab (rogue) a busy
## monster; use the weapon's special when it pays and there's light to spare; otherwise the
## plain attack on the weakest monster without its shield up.
static func ai_choice(st: Dictionary, hero_i: int) -> Array:
	var h: Dictionary = st["party"][hero_i]
	var foes: Array = st["foes"]
	var living: Array = alive_idx(foes)
	var light: int = int(st.get("light", 0))
	var hp_share: float = float(h["hp"]) / maxf(1.0, float(h["max_hp"]))
	if int(h.get("heal", 0)) > 0 and hp_share < POTION_AT:
		return ["potion", -1]
	if light <= 2 and int(st.get("oil", 0)) > 0:
		return ["oil", -1]
	var cls: String = str(h.get("cls", ""))
	# Light kept back for the rest of the fight and the floors below.
	var reserve: int = 4
	if cls == "knight" and not dark(st):
		for i in living:
			var it: String = str(foes[i]["intent"])
			if int(foes[i]["stun"]) <= 0 and ((it == "heavy" and light >= 2) or (it in ["fire", "summon"] and light >= 2 + reserve)):
				return ["skill", i]
	if not dark(st):
		for i in living:
			var it: String = str(foes[i]["intent"])
			# A heavy blow aimed at you: brace. A web: knights brace; a rogue would rather
			# backstab the busy spider (below).
			if int(foes[i]["intent_target"]) == hero_i and (it == "heavy" or (it == "web" and (cls != "rogue" or light < 2))):
				return ["guard", -1]
	if cls == "rogue" and light >= 2:
		var best: int = -1
		for i in living:
			if busy(foes[i]) and (best < 0 or float(foes[i]["hp"]) > float(foes[best]["hp"])):
				best = i
		if best >= 0:
			return ["skill", best]
	var open_target: int = -1
	for i in living:
		if not bool(foes[i]["shield_up"]) and (open_target < 0 or float(foes[i]["hp"]) < float(foes[open_target]["hp"])):
			open_target = i
	if open_target < 0:
		open_target = _weakest(foes)
	var sp: Dictionary = MOVES[family(h)].get("special", {})
	if not sp.is_empty() and light >= int(sp["cost"]) + reserve:
		match str(sp["kind"]):
			"cleave", "sweep":
				if living.size() >= 2:
					return ["special", open_target]
			"crush", "pin":
				for i in living:
					if str(foes[i]["intent"]) in ["heavy", "web", "fire", "summon"]:
						return ["special", i]
			"bleed":
				var big: int = -1
				for i in living:
					if int(foes[i]["bleed"]) <= 0 and float(foes[i]["hp"]) > float(h["damage"]) * 2.0 and (big < 0 or float(foes[i]["hp"]) > float(foes[big]["hp"])):
						big = i
				if big >= 0:
					return ["special", big]
			"sunder":
				for i in living:
					if not bool(foes[i]["sundered"]) and float(foes[i]["armour"]) >= 8.0 and float(foes[i]["hp"]) > float(h["damage"]) * 2.0:
						return ["special", i]
			"aimed":
				for i in living:
					if bool(foes[i]["boss"]) or bool(foes[i]["shield_up"]):
						return ["special", i]
			"riposte":
				for i in living:
					if int(foes[i]["intent_target"]) == hero_i and str(foes[i]["intent"]) in ["attack", "heavy"]:
						return ["special", -1]
	return ["strike", open_target]

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
	var boss: bool = foes.size() >= 1 and bool(foes[0]["boss"])
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
	if (st["log"] as Array).any(func(e): return str(e["kind"]) == "dark"):
		lines.append("The lantern went out down there.")
	for p in party:
		if float(p["hp"]) <= 0.0:
			lines.append("%s fell." % str(p["name"]))
		elif bool(p.get("drank", false)):
			lines.append("%s drank a healing draught." % str(p["name"]))
	return lines
