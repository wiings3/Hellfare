extends RefCounted
class_name DungeonEvents
## Things that happen to a crew in a dungeon, about every twenty seconds: a chest with blood
## around it, a wounded mercenary, a side passage. Each event has hidden states (the chest is
## trapped or it isn't), two or three choices, and outcomes by state. Someone in the crew with
## the right trait or skill reads the state and says so (a hint). The player has EVENT_WAIT
## seconds to choose; otherwise the crew decides by its standing order (play it safe / take
## chances), using a hint when it has one. So runs still finish on their own when nobody watches.
##
## Outcome effects (all optional; coin and wounds are scaled by COIN_SCALE and HURT_SCALE):
##   coin [a, b] · goods {good: [a, b]} · gear tier (a piece like those lying in the dungeon)
##   hurt [a, b] (one member) · hurt_all [a, b] · heal n (everyone) · lose f (share of the haul)
##   buff {damage: %, armour: n} for the next fight · weaken % off the next foes' health
##   ally (a stranger fights with the crew in the next fight) · xp n Combat XP each
##   blueprint chance of a blueprint from this dungeon · text, where {who} is the one affected

## Events come thick and fast (a dozen a floor), so each one's coin and wounds are scaled
## here to keep a whole run in balance (tuned with tools/econ_sim.gd).
const COIN_SCALE := 0.4
const HURT_SCALE := 0.6

const GAP := [15, 25]
const EVENT_WAIT := 15
## Gaps between events on the walk out.
const WALK_GAP := [18, 28]

const EVENTS := [
	# --- Anywhere ------------------------------------------------------------------------
	{"id": "bloody_chest", "phase": "floor", "text": "A chest stands against the wall. There's blood around it, and it's still wet.",
	 "states": {"trapped": 4, "clean": 6}, "hint_by": ["keen_eye"],
	 "hint": {"trapped": "{who} spots a hair-thin wire across the lock.", "clean": "{who} looks it over: no wires, no needles. The blood is a rat's."},
	 "choices": [
		{"label": "Open it", "tag": "bold", "out": {
			"trapped": [{"w": 3, "hurt": [14, 26], "coin": [10, 24], "text": "A needle springs from the lock. {who} takes it in the hand. Inside: some coin."},
						{"w": 1, "hurt": [26, 40], "text": "Blades snap shut on {who}'s arm. The chest is empty."}],
			"clean": [{"w": 3, "coin": [14, 30], "text": "Coin, and nobody hurt."}, {"w": 1, "gear": 1, "coin": [6, 12], "text": "Coin and a piece of gear wrapped in oilcloth."}]}},
		{"label": "Check for traps first", "tag": "safe", "out": {
			"trapped": [{"w": 3, "coin": [8, 18], "text": "{who} finds the wire and cuts it. Some coin inside."}, {"w": 1, "hurt": [8, 14], "coin": [8, 18], "text": "{who} nearly has it when the needle fires. A scratch, and some coin."}],
			"clean": [{"w": 1, "coin": [10, 22], "text": "No trap after all. Coin inside."}]}},
		{"label": "Leave it", "tag": "", "out": {"any": [{"w": 1, "text": "The crew walks past."}]}}],
	 "best": {"trapped": 1, "clean": 0}},
	{"id": "wounded_merc", "phase": "floor", "text": "A wounded mercenary sits against a pillar, breathing hard. His sword is better than anything your crew carries.",
	 "states": {"honest": 5, "bait": 3}, "hint_by": ["keen_eye", "combat:12"],
	 "hint": {"honest": "{who} sees the wound is real. He's no threat.", "bait": "{who} notices his friends' footprints in the dust. It's bait."},
	 "choices": [
		{"label": "Help him", "tag": "safe", "out": {
			"honest": [{"w": 3, "ally": true, "text": "He's grateful. He'll fight beside you on this floor."}, {"w": 1, "coin": [20, 40], "text": "He presses a purse into {who}'s hand before he limps for the exit."}],
			"bait": [{"w": 2, "hurt_all": [6, 14], "text": "His friends come out of the dark. The crew fights them off, bruised."}, {"w": 1, "lose": 0.2, "text": "While you bind his leg, his friends lift part of the haul."}]}},
		{"label": "Take his sword", "tag": "bold", "out": {
			"honest": [{"w": 2, "gear": 1, "text": "He's too weak to stop you. {who} takes the sword."}, {"w": 1, "hurt": [10, 22], "gear": 1, "text": "He fights for it. {who} gets cut, but the sword is yours."}],
			"bait": [{"w": 2, "hurt": [18, 30], "text": "It was bait. {who} is cut before the crew drives them off."}, {"w": 1, "gear": 1, "hurt": [12, 20], "text": "His friends come at you; you take the sword anyway."}]}},
		{"label": "Walk on", "tag": "", "out": {"any": [{"w": 1, "text": "You leave him be."}]}}],
	 "best": {"honest": 0, "bait": 2}},
	{"id": "side_passage", "phase": "floor", "text": "A side passage, and a draught of fresh air from it.",
	 "states": {"shortcut": 5, "nest": 3}, "hint_by": ["tracker", "hunting:10"],
	 "hint": {"shortcut": "{who} reads the tracks: people came this way, nothing else.", "nest": "{who} smells it before you see it: something nests down there."},
	 "choices": [
		{"label": "Take it", "tag": "bold", "out": {
			"shortcut": [{"w": 1, "weaken": 25, "text": "It comes out behind the monsters. They won't see you coming."}],
			"nest": [{"w": 2, "hurt": [12, 24], "goods": {"bone": [1, 3]}, "text": "A nest. {who} is bitten getting through."}, {"w": 1, "hurt_all": [6, 12], "text": "The passage is full of them. Everyone's bitten."}]}},
		{"label": "Stay on the main way", "tag": "safe", "out": {"any": [{"w": 1, "text": "The crew keeps to the main way."}]}}],
	 "best": {"shortcut": 0, "nest": 1}},
	{"id": "old_campfire", "phase": "floor", "text": "The ashes of a campfire, still warm, and a pack left beside it.",
	 "states": {"left": 6, "owners": 3},
	 "choices": [
		{"label": "Search the pack", "tag": "bold", "out": {
			"left": [{"w": 3, "coin": [10, 24], "text": "Some coin and a stale loaf."}, {"w": 1, "goods": {"healing_draught": [1, 1]}, "text": "A healing draught, still corked."}],
			"owners": [{"w": 1, "hurt": [10, 20], "coin": [6, 14], "text": "Its owners come back. {who} takes a club to the head before they run."}]}},
		{"label": "Rest by the fire", "tag": "safe", "out": {"any": [{"w": 1, "heal": 10, "text": "The crew warms up and binds its cuts."}]}}]},
	{"id": "scratched_map", "phase": "floor", "text": "Someone scratched a map on the wall. An X marks a loose stone nearby.",
	 "states": {"real": 5, "old": 5},
	 "choices": [
		{"label": "Dig for it", "tag": "bold", "out": {
			"real": [{"w": 2, "coin": [20, 45], "text": "Behind the stone: a stash of coin."}, {"w": 1, "gear": 1, "text": "Behind the stone: a piece of gear, wrapped tight."}],
			"old": [{"w": 1, "text": "Somebody got here first."}, {"w": 1, "hurt": [6, 12], "text": "The stone was holding up the wall. {who} gets out of the way, mostly."}]}},
		{"label": "Keep moving", "tag": "safe", "out": {"any": [{"w": 1, "text": "No time for treasure maps."}]}}]},
	{"id": "strange_brew", "phase": "floor", "text": "A shelf of dusty bottles. One still glows faintly.",
	 "states": {"tonic": 5, "poison": 4}, "hint_by": ["herbalist", "foraging:10"],
	 "hint": {"tonic": "{who} sniffs it: herbs and honey. It's a tonic.", "poison": "{who} sniffs it and pulls a face: nightshade."},
	 "choices": [
		{"label": "Drink it", "tag": "bold", "out": {
			"tonic": [{"w": 1, "heal": 20, "buff": {"damage": 10}, "text": "Warmth runs through the crew. They feel stronger."}],
			"poison": [{"w": 1, "hurt_all": [8, 16], "text": "Nightshade. Everyone is sick."}]}},
		{"label": "Sell the bottles later", "tag": "safe", "out": {"any": [{"w": 1, "coin": [6, 14], "text": "The crew pockets the bottles to sell."}]}}],
	 "best": {"tonic": 0, "poison": 1}},
	{"id": "fallen_adventurer", "phase": "floor", "text": "A dead adventurer, not long dead. Their kit is still on them.",
	 "states": {"quiet": 6, "watched": 3}, "hint_by": ["combat:15", "keen_eye"],
	 "hint": {"quiet": "{who} checks the shadows. Whatever killed them is gone.", "watched": "{who} sees eyes in the dark. What killed them is still here."},
	 "choices": [
		{"label": "Strip the body", "tag": "bold", "out": {
			"quiet": [{"w": 2, "gear": 1, "text": "Their armour fits {who} near enough to carry out."}, {"w": 1, "coin": [12, 28], "text": "A purse and a few trinkets."}],
			"watched": [{"w": 1, "hurt": [16, 30], "gear": 1, "text": "It comes back for them. {who} is mauled, but you get the gear."}]}},
		{"label": "Say a word and move on", "tag": "safe", "out": {"any": [{"w": 1, "xp": 5, "text": "The crew remembers why it's careful."}]}}],
	 "best": {"quiet": 0, "watched": 1}},
	{"id": "cracked_floor", "phase": "floor", "text": "The floor ahead is cracked through. Something glints at the bottom of the crack.",
	 "states": {"holds": 5, "gives": 4},
	 "choices": [
		{"label": "Climb down for it", "tag": "bold", "out": {
			"holds": [{"w": 1, "coin": [16, 34], "goods": {"crystal": [0, 1]}, "text": "{who} climbs down and back with a fistful of coin."}],
			"gives": [{"w": 1, "hurt": [18, 32], "text": "The ledge gives way. {who} falls hard."}]}},
		{"label": "Go round", "tag": "safe", "out": {"any": [{"w": 1, "text": "The crew goes the long way round."}]}}]},
	{"id": "sleeping_foes", "phase": "floor", "text": "The monsters ahead are asleep.",
	 "states": {"deep": 6, "light": 4}, "hint_by": ["tracker", "hunting:8"],
	 "hint": {"deep": "{who} creeps close: deep asleep.", "light": "{who} sees an ear twitch. They're barely sleeping."},
	 "choices": [
		{"label": "Strike while they sleep", "tag": "bold", "out": {
			"deep": [{"w": 1, "weaken": 40, "text": "The first blows land before they wake."}],
			"light": [{"w": 1, "hurt": [10, 20], "weaken": 10, "text": "They wake as you close. {who} is caught off guard."}]}},
		{"label": "Rest a moment first", "tag": "safe", "out": {"any": [{"w": 1, "heal": 8, "text": "The crew catches its breath before the fight."}]}}],
	 "best": {"deep": 0, "light": 1}},
	{"id": "gambler", "phase": "floor", "text": "A cheerful stranger offers a game of dice. Stakes: 20 coin.",
	 "states": {"fair": 5, "cheat": 5}, "hint_by": ["lucky", "keen_eye"],
	 "hint": {"fair": "{who} watches a few throws. The dice look honest.", "cheat": "{who} sees the dice land six too often."},
	 "choices": [
		{"label": "Play", "tag": "bold", "out": {
			"fair": [{"w": 1, "coin": [40, 40], "text": "{who} wins the throw: 20 coin."}, {"w": 1, "coin": [-40, -40], "text": "{who} loses the throw: 20 coin."}],
			"cheat": [{"w": 3, "coin": [-40, -40], "text": "Loaded dice. 20 coin gone."}, {"w": 1, "coin": [80, 80], "text": "{who} catches him cheating and takes his purse."}]}},
		{"label": "Decline", "tag": "safe", "out": {"any": [{"w": 1, "text": "He shrugs and shuffles off into the dark."}]}}],
	 "best": {"fair": 0, "cheat": 1}},
	{"id": "shrine", "phase": "floor", "text": "A little shrine with an offering bowl. Coins glint in it.",
	 "states": {"blessed": 5, "cursed": 3},
	 "choices": [
		{"label": "Take the coins", "tag": "bold", "out": {
			"blessed": [{"w": 1, "coin": [14, 30], "text": "Nothing happens. The coins are yours."}],
			"cursed": [{"w": 1, "coin": [14, 30], "buff": {"damage": -15}, "text": "The air turns cold. The crew's hands feel heavy for the next fight."}]}},
		{"label": "Leave an offering (5 coin)", "tag": "safe", "out": {
			"blessed": [{"w": 1, "coin": [-10, -10], "buff": {"armour": 8}, "text": "The crew feels watched over."}],
			"cursed": [{"w": 1, "coin": [-10, -10], "text": "Nothing happens."}]}}]},
	{"id": "lost_porter", "phase": "floor", "text": "A frightened porter from another company begs to be taken to the exit.",
	 "states": {"real": 7, "thief": 3},
	 "choices": [
		{"label": "Take him along", "tag": "safe", "out": {
			"real": [{"w": 2, "coin": [15, 30], "text": "He pays what he has when you reach the stairs."}, {"w": 1, "goods": {"spider_silk": [1, 2]}, "text": "He gives you what he was carrying."}],
			"thief": [{"w": 1, "lose": 0.15, "text": "He slips away at the stairs, with part of the haul."}]}},
		{"label": "Send him off", "tag": "bold", "out": {"any": [{"w": 1, "text": "He runs off into the dark."}]}}]},
	# --- Calder Keep -----------------------------------------------------------------------
	{"id": "rat_hole", "phase": "floor", "where": ["calder_keep"], "floors": [0], "text": "A hole gnawed into the wall. Something shiny is lodged inside, and the rats are nearby.",
	 "states": {"empty": 5, "nest": 5},
	 "choices": [
		{"label": "Reach in", "tag": "bold", "out": {
			"empty": [{"w": 1, "coin": [8, 18], "text": "{who} pulls out a handful of coin."}],
			"nest": [{"w": 1, "hurt": [8, 16], "coin": [8, 18], "text": "Bitten, but {who} keeps hold of the coin."}]}},
		{"label": "Poke it with a sword", "tag": "safe", "out": {"any": [{"w": 2, "coin": [4, 10], "text": "A few coins rattle out."}, {"w": 1, "goods": {"bone": [1, 2]}, "text": "Only bones."}]}}]},
	{"id": "flooded_cellar", "phase": "floor", "where": ["calder_keep"], "floors": [0], "text": "Part of the cellar is flooded. Barrels float in the black water.",
	 "states": {"wine": 5, "eels": 4},
	 "choices": [
		{"label": "Wade in for the barrels", "tag": "bold", "out": {
			"wine": [{"w": 1, "coin": [16, 32], "text": "Good wine. A merchant will pay for this."}],
			"eels": [{"w": 1, "hurt": [10, 22], "text": "Eels. {who} gets out fast, and bleeding."}]}},
		{"label": "Skirt the water", "tag": "safe", "out": {"any": [{"w": 1, "text": "The crew keeps its feet dry."}]}}]},
	{"id": "web_cocoon", "phase": "floor", "where": ["calder_keep"], "floors": [1], "text": "A cocoon hangs in the webs. Something inside it moves.",
	 "states": {"alive": 4, "spider": 5}, "hint_by": ["hunting:8", "keen_eye"],
	 "hint": {"alive": "{who} hears a muffled voice inside.", "spider": "{who} sees eight legs pressed against the silk."},
	 "choices": [
		{"label": "Cut it open", "tag": "bold", "out": {
			"alive": [{"w": 1, "ally": true, "coin": [10, 20], "text": "A trapped explorer tumbles out. He'll fight with you, gladly."}],
			"spider": [{"w": 1, "hurt": [14, 26], "goods": {"spider_silk": [1, 2]}, "text": "A spider bursts out at {who}."}]}},
		{"label": "Burn the webs", "tag": "safe", "out": {"any": [{"w": 1, "goods": {"spider_silk": [1, 2]}, "weaken": 10, "text": "The webs go up. The spiders come out singed."}]}}],
	 "best": {"alive": 0, "spider": 1}},
	{"id": "silk_harvest", "phase": "floor", "where": ["calder_keep"], "floors": [1], "text": "Thick sheets of silk, unguarded for the moment.",
	 "states": {"quiet": 6, "watched": 4},
	 "choices": [
		{"label": "Harvest it", "tag": "bold", "out": {
			"quiet": [{"w": 1, "goods": {"spider_silk": [2, 4]}, "text": "The crew bundles up good silk."}],
			"watched": [{"w": 1, "goods": {"spider_silk": [1, 2]}, "hurt": [12, 22], "text": "A spider drops onto {who}."}]}},
		{"label": "Take a little", "tag": "safe", "out": {"any": [{"w": 1, "goods": {"spider_silk": [1, 1]}, "text": "A strip of silk, quietly."}]}}]},
	{"id": "knights_squire", "phase": "floor", "where": ["calder_keep"], "floors": [2], "text": "A squire's ghost kneels by the stairs. \"My master is tired,\" it whispers. \"Let him rest.\"",
	 "states": {"kind": 5, "warning": 5},
	 "choices": [
		{"label": "Ask how to beat him", "tag": "safe", "out": {
			"kind": [{"w": 1, "weaken": 20, "text": "\"His left side,\" it says. \"The old wound.\""}],
			"warning": [{"w": 1, "buff": {"armour": 10}, "text": "\"Raise your shields when the bell tolls.\" The crew listens."}]}},
		{"label": "Ignore it", "tag": "bold", "out": {"any": [{"w": 1, "text": "The ghost fades."}]}}]},
	{"id": "armoury_rack", "phase": "floor", "where": ["calder_keep"], "floors": [2], "text": "An old weapon rack. Most of it is rust, but not all.",
	 "states": {"sound": 5, "rotten": 5},
	 "choices": [
		{"label": "Take the best of it", "tag": "bold", "out": {
			"sound": [{"w": 1, "gear": 1, "text": "One blade is still sound. {who} takes it."}],
			"rotten": [{"w": 1, "hurt": [6, 14], "text": "The rack collapses on {who}."}]}},
		{"label": "Sharpen your own blades on it", "tag": "safe", "out": {"any": [{"w": 1, "buff": {"damage": 10}, "text": "A whetstone on the rack. Edges are keener for the next fight."}]}}]},
	# --- The walk out ----------------------------------------------------------------------
	{"id": "collapse", "phase": "walk", "text": "The passage behind you rumbles. Stones start to fall.",
	 "states": {"small": 6, "big": 3},
	 "choices": [
		{"label": "Run for it", "tag": "bold", "out": {
			"small": [{"w": 1, "text": "Everyone gets through."}],
			"big": [{"w": 1, "hurt": [14, 28], "text": "{who} is caught by a falling stone."}]}},
		{"label": "Drop the heavy goods and run", "tag": "safe", "out": {"any": [{"w": 1, "lose": 0.1, "text": "Lighter, faster: everyone gets through."}]}}]},
	{"id": "regroup", "phase": "walk", "text": "Monsters you drove off earlier are regrouping behind you.",
	 "states": {"few": 6, "many": 3},
	 "choices": [
		{"label": "Turn and fight", "tag": "bold", "out": {
			"few": [{"w": 1, "coin": [10, 22], "xp": 10, "text": "The crew turns on them. They scatter, dropping coin."}],
			"many": [{"w": 1, "hurt_all": [8, 16], "text": "There are more than you thought. The crew fights clear, hurt."}]}},
		{"label": "Hurry out", "tag": "safe", "out": {"any": [{"w": 3, "text": "The crew outpaces them."}, {"w": 1, "hurt": [6, 12], "text": "They catch {who} at the back."}]}}]},
	{"id": "toll_men", "phase": "walk", "text": "Three men block the stairs out. \"Toll,\" says one. \"A tenth of what you carry.\"",
	 "states": {"bluff": 5, "real": 5}, "hint_by": ["combat:15"],
	 "hint": {"bluff": "{who} sizes them up: farmhands with clubs.", "real": "{who} knows a killer's stance. These men are dangerous."},
	 "choices": [
		{"label": "Pay the toll", "tag": "safe", "out": {"any": [{"w": 1, "lose": 0.1, "text": "You pay. They step aside."}]}},
		{"label": "Push through", "tag": "bold", "out": {
			"bluff": [{"w": 1, "coin": [10, 20], "text": "They run. One drops his purse."}],
			"real": [{"w": 1, "hurt_all": [10, 20], "lose": 0.1, "text": "They fight like killers. You get out, poorer and bleeding."}]}}],
	 "best": {"bluff": 1, "real": 0}},
	{"id": "dropped_purse", "phase": "walk", "text": "A purse lies in the middle of the passage, as if waiting for you.",
	 "states": {"lost": 6, "trap": 4},
	 "choices": [
		{"label": "Pick it up", "tag": "bold", "out": {
			"lost": [{"w": 1, "coin": [12, 28], "text": "Someone's loss is your gain."}],
			"trap": [{"w": 1, "hurt": [12, 24], "text": "A snare drops. {who} is caught."}]}},
		{"label": "Kick it first", "tag": "safe", "out": {
			"lost": [{"w": 1, "coin": [12, 28], "text": "Nothing happens. Coin inside."}],
			"trap": [{"w": 1, "text": "The snare drops on nothing. The purse is empty."}]}}]},
]

static func by_id(id: String) -> Dictionary:
	for e in EVENTS:
		if str(e["id"]) == id:
			return e
	return {}

## Events that can happen in a dungeon, on a floor ("floor") or on the walk out ("walk").
static func pool(dungeon: String, phase: String, floor_i: int) -> Array:
	var out: Array = []
	for e in EVENTS:
		if str(e.get("phase", "floor")) != phase:
			continue
		if e.has("where") and not (e["where"] as Array).has(dungeon):
			continue
		if e.has("floors") and not (e["floors"] as Array).has(floor_i):
			continue
		out.append(e)
	return out

static func _pick_weighted(table: Dictionary, rng: RandomNumberGenerator) -> String:
	var total: float = 0.0
	for k in table:
		total += float(table[k])
	var roll: float = rng.randf() * total
	for k in table:
		roll -= float(table[k])
		if roll <= 0.0:
			return str(k)
	return str(table.keys().back())

## Who in the crew can read this event's hidden state, if anyone (a mercenary dictionary).
static func reader(e: Dictionary, crew: Array) -> Dictionary:
	for rule in e.get("hint_by", []):
		var r: String = str(rule)
		for merc in crew:
			if r.contains(":"):
				if TradeSkills.level_of(merc, r.get_slice(":", 0)) >= int(r.get_slice(":", 1)):
					return merc
			elif Mercs.has_trait(merc, r):
				return merc
	return {}

## Schedule a phase's events from `start` to `end` (seconds). Each is
## {"t", "id", "state", "hint", "reader", "done": false}. Deterministic for the seed.
static func schedule(dungeon: String, phase: String, floor_i: int, start: int, end: int, seed_value: int, crew: Array) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var gaps: Array = GAP if phase == "floor" else WALK_GAP
	var out: Array = []
	var options: Array = pool(dungeon, phase, floor_i)
	if options.is_empty():
		return out
	var t: int = start + rng.randi_range(int(gaps[0]), int(gaps[1]))
	var last: String = ""
	while t + EVENT_WAIT < end:
		var e: Dictionary = options[rng.randi_range(0, options.size() - 1)]
		if str(e["id"]) == last and options.size() > 1:
			e = options[(options.find(e) + 1) % options.size()]
		last = str(e["id"])
		var state: String = _pick_weighted(e["states"], rng)
		var who: Dictionary = reader(e, crew)
		var hint: String = ""
		if not who.is_empty() and (e.get("hint", {}) as Dictionary).has(state):
			hint = str(e["hint"][state]).replace("{who}", str(who.get("name", "Someone")))
		out.append({"t": t, "id": str(e["id"]), "state": state, "hint": hint, "reader": str(who.get("id", "")), "done": false, "roll": rng.randi()})
		t += rng.randi_range(int(gaps[0]), int(gaps[1]))
	return out

## Which choice the crew makes on its own: the best one for what a hint told it, otherwise
## the one its orders lean to ("safe" or "bold"), otherwise the first.
static func auto_choice(ev: Dictionary, risk: String) -> int:
	var e: Dictionary = by_id(str(ev["id"]))
	if str(ev.get("hint", "")) != "" and (e.get("best", {}) as Dictionary).has(str(ev["state"])):
		return int(e["best"][str(ev["state"])])
	var choices: Array = e["choices"]
	for i in range(choices.size()):
		if str(choices[i].get("tag", "")) == risk:
			return i
	return 0

## The outcome of a choice for the event's state (weighted, from the event's own roll).
static func outcome(ev: Dictionary, choice: int) -> Dictionary:
	var e: Dictionary = by_id(str(ev["id"]))
	var choices: Array = e["choices"]
	choice = clampi(choice, 0, choices.size() - 1)
	var outs: Dictionary = choices[choice]["out"]
	var list: Array = outs.get(str(ev["state"]), outs.get("any", []))
	if list.is_empty():
		return {"text": "Nothing happens."}
	var rng := RandomNumberGenerator.new()
	rng.seed = int(ev.get("roll", 1)) + choice * 7919
	var total: float = 0.0
	for o in list:
		total += float(o.get("w", 1))
	var r: float = rng.randf() * total
	for o in list:
		r -= float(o.get("w", 1))
		if r <= 0.0:
			return o
	return list.back()
