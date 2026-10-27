class_name Mercs
extends RefCounted
## Mercenaries without archetypes. Nobody is hired as a Woodcutter, Miner or Guard any more:
## what a mercenary does today is set by the tool in their hands, how well they do it by their
## trade skills, and their traits (rolled at hiring, kept for life) make each one different.
## Reputation decides who applies, and contracts can be bought from and sold to other guilds.

const V05 = preload("res://scripts/v05_rules.gd")

## Trades a recruit can be good at today. Fighting is for heroes (heroes.gd), so nobody
## applies as a guard any more.
const RECRUIT_TRADES := ["logging", "mining", "foraging", "fishing", "hunting", "farming"]
## Always on the board: a green hand for each of these, plus one for a rotating newer trade.
const ENTRY_TRADES := ["logging", "mining", "hunting"]
const ROTATING_TRADES := ["foraging", "fishing", "farming"]
const JOB_NAMES := {"logging": "Woodcutter", "mining": "Miner", "combat": "Guard", "foraging": "Forager",
	"fishing": "Angler", "hunting": "Hunter", "farming": "Farmhand", "": "Labourer"}
## Basic tool a new recruit brings for their best trade.
const STARTER_TOOL := {"logging": "hand_axe", "mining": "basic_pick", "combat": "rusted_sword",
	"foraging": "copper_sickle", "fishing": "birch_rod", "hunting": "birch_shortbow", "farming": "iron_hoe"}

const RARITY_ORDER := ["common", "uncommon", "rare", "legendary"]
const TRAITS := {
	"frugal": {"name": "Frugal", "rarity": "common", "text": "Wage 20% lower.", "value": 30},
	"greedy": {"name": "Greedy", "rarity": "common", "text": "Keeps 5% more of the haul.", "value": -30},
	"tough": {"name": "Tough", "rarity": "common", "text": "Injuries are 30% lighter.", "value": 40},
	"reckless": {"name": "Reckless", "rarity": "common", "text": "Guards as if 5 Combat levels higher, but 30% more likely to be hurt.", "value": 0},
	"coward": {"name": "Coward", "rarity": "common", "text": "Half as likely to die, but brings back 10% less.", "value": 0},
	"woodsman": {"name": "Ashcutter", "rarity": "uncommon", "text": "Logging experience +25%.", "value": 120},
	"steady_hands": {"name": "Steady hands", "rarity": "uncommon", "text": "Mining experience +25%.", "value": 120},
	"brawler": {"name": "Brawler", "rarity": "uncommon", "text": "Combat experience +25%.", "value": 120},
	"quick_healer": {"name": "Quick healer", "rarity": "uncommon", "text": "Rests back to health twice as fast.", "value": 100},
	"herbalist": {"name": "Herbalist", "rarity": "uncommon", "text": "Foraging experience +25%.", "value": 120},
	"patient": {"name": "Patient", "rarity": "uncommon", "text": "Fishing experience +25%.", "value": 120},
	"tracker": {"name": "Tracker", "rarity": "uncommon", "text": "Hunting experience +25%.", "value": 120},
	"green_thumb": {"name": "Green thumb", "rarity": "uncommon", "text": "Farming experience +25%.", "value": 120},
	"strong_back": {"name": "Strong back", "rarity": "rare", "text": "Brings back 10% more from work sites.", "value": 450},
	"keen_eye": {"name": "Keen eye", "rarity": "rare", "text": "The crew is 50% more likely to make rare finds and find what the dead left below.", "value": 450},
	"lucky": {"name": "Lucky", "rarity": "rare", "text": "Survives one killing blow in three.", "value": 500},
	"prodigy": {"name": "Prodigy", "rarity": "legendary", "text": "All experience +50%.", "value": 2500},
	"born_leader": {"name": "Born leader", "rarity": "legendary", "text": "The whole crew brings back 10% more.", "value": 2500},
	"ironhide": {"name": "Ironhide", "rarity": "legendary", "text": "Half as likely to die.", "value": 2500},
}
const XP_TRAITS := {"woodsman": "logging", "steady_hands": "mining", "brawler": "combat", "herbalist": "foraging",
	"patient": "fishing", "tracker": "hunting", "green_thumb": "farming"}

## Reputation tiers. "rep" is the reputation needed; "cap" the best skill level an applicant
## can have; "rare" and "legendary" the odds per applicant of such a trait. Simulated full-time
## play reaches them after about 10, 50, 200 and 600 hours (tools/econ_sim.gd).
const TIERS := [
	{"name": "Unknown", "rep": 0, "cap": 5, "rare": 0.0, "legendary": 0.0},
	{"name": "Known", "rep": 500, "cap": 10, "rare": 0.05, "legendary": 0.0},
	{"name": "Trusted", "rep": 5000, "cap": 20, "rare": 0.125, "legendary": 0.0025},
	{"name": "Renowned", "rep": 25000, "cap": 30, "rare": 0.2, "legendary": 0.0067},
	{"name": "Legendary", "rep": 75000, "cap": 40, "rare": 0.25, "legendary": 0.0167},
]
## Reputation earned per gold of goods a crew delivers (merchant value).
const REP_PER_GOLD := 0.05

## Contracts: NPC guilds pay half the shown value; buyers pay a 10% transfer fee on top;
## a transferred mercenary settles in for 3 days before they can be sold again; every sale
## costs the seller a little reputation.
const NPC_BUY := 0.5
const NPC_ASK := 1.15
const TRANSFER_FEE := 0.10
const SETTLE_SECONDS := 3 * 86400
const SALE_REP_LOSS := 0.02
const SALE_REP_MIN := 5
const CONTRACT_EPOCH := 14400
const GUILDS := ["the Red Wolves", "the Iron Hands", "the Grey Lanterns", "the Black Pines", "the Copper Crowns", "the Salt Kings"]

# --- Reputation ------------------------------------------------------------------

static func tier_for(rep: int) -> int:
	var tier: int = 0
	for i in range(TIERS.size()):
		if rep >= int(TIERS[i]["rep"]):
			tier = i
	return tier

static func tier_name(tier: int) -> String:
	return str(TIERS[clampi(tier, 0, TIERS.size() - 1)]["name"])

## Reputation still needed for the next tier (0 at the top).
static func rep_to_next(rep: int) -> int:
	var tier: int = tier_for(rep)
	if tier >= TIERS.size() - 1:
		return 0
	return int(TIERS[tier + 1]["rep"]) - rep

# --- Skills, jobs and titles -------------------------------------------------------

static func level(merc: Dictionary, trade: String) -> int:
	return TradeSkills.level_of(merc, trade)

## The trade a mercenary is best at (ties go to logging, then mining, then combat).
static func best_trade(merc: Dictionary) -> String:
	var best: String = "logging"
	for trade in TradeSkills.TRADES:
		if level(merc, trade) > level(merc, best):
			best = trade
	return best

static func best_level(merc: Dictionary) -> int:
	return level(merc, best_trade(merc))

## The trade the tool in their hands is for: "logging", "mining", "combat" or "" (none).
static func job(merc: Dictionary) -> String:
	return Gear.job(merc)

## The job as people would describe it: a bow or spear in the hands of someone better at
## hunting than fighting makes a hunter, not a guard. Applicants (no gear yet) go by their
## best trade.
static func shown_job(merc: Dictionary) -> String:
	var j: String = job(merc)
	if j == "" and not merc.has("equipment"):
		return best_trade(merc)
	if j == "combat" and Gear.hunts(merc) and level(merc, "hunting") > level(merc, "combat"):
		return "hunting"
	return j

## What they're doing today, as a job name ("Miner").
static func role_of(merc: Dictionary) -> String:
	return str(JOB_NAMES.get(shown_job(merc), "Labourer"))

## An earned title: rank from their skill in today's job, e.g. "Veteran Miner · Mining 31".
static func title(merc: Dictionary) -> String:
	var j: String = shown_job(merc)
	if j == "":
		var best: String = best_trade(merc)
		return "No tool · best at %s %d" % [TradeSkills.NAMES[best], level(merc, best)]
	var lv: int = level(merc, j)
	var rank: String = ""
	if lv >= 40:
		rank = "Master "
	elif lv >= 30:
		rank = "Veteran "
	elif lv >= 20:
		rank = "Seasoned "
	elif lv <= 3:
		rank = "Green "
	return "%s%s · %s %d" % [rank, JOB_NAMES[j], TradeSkills.NAMES[j], lv]

# --- Traits ------------------------------------------------------------------------

static func has_trait(merc: Dictionary, id: String) -> bool:
	return (merc.get("traits", []) as Array).has(id)

static func crew_has(crew: Array, id: String) -> bool:
	for merc in crew:
		if has_trait(merc, id):
			return true
	return false

static func trait_names(merc: Dictionary) -> String:
	var names: Array[String] = []
	for t in merc.get("traits", []):
		names.append(str(TRAITS.get(str(t), {}).get("name", t)))
	return ", ".join(names)

static func trait_lines(merc: Dictionary) -> String:
	var lines: Array[String] = []
	for t in merc.get("traits", []):
		var d: Dictionary = TRAITS.get(str(t), {})
		lines.append("%s (%s): %s" % [str(d.get("name", t)), str(d.get("rarity", "")), str(d.get("text", ""))])
	return "\n".join(lines)

## Experience multiplier from traits for one trade.
static func xp_mult(merc: Dictionary, trade: String) -> float:
	var mult: float = 1.0
	for t in XP_TRAITS:
		if XP_TRAITS[t] == trade and has_trait(merc, t):
			mult *= 1.25
	if has_trait(merc, "prodigy"):
		mult *= 1.5
	return mult

## Personal haul multiplier at work sites.
static func haul_mult(merc: Dictionary) -> float:
	var mult: float = 1.0
	if has_trait(merc, "strong_back"):
		mult *= 1.1
	if has_trait(merc, "coward"):
		mult *= 0.9
	return mult

static func death_mult(merc: Dictionary) -> float:
	var mult: float = 1.0
	if has_trait(merc, "coward"):
		mult *= 0.5
	if has_trait(merc, "ironhide"):
		mult *= 0.5
	return mult

static func injury_chance_mult(merc: Dictionary) -> float:
	return 1.3 if has_trait(merc, "reckless") else 1.0

static func injury_damage_mult(merc: Dictionary) -> float:
	return 0.7 if has_trait(merc, "tough") else 1.0

static func rest_mult(merc: Dictionary) -> float:
	return 2.0 if has_trait(merc, "quick_healer") else 1.0

## Combat level used when they stand guard.
static func guard_level(merc: Dictionary) -> int:
	return level(merc, "combat") + (5 if has_trait(merc, "reckless") else 0) + Gear.weapon_levels(merc)

static func _pick(rng: RandomNumberGenerator, rarities: Array, exclude: Array) -> String:
	var pool: Array[String] = []
	for t in TRAITS:
		if rarities.has(str(TRAITS[t]["rarity"])) and not exclude.has(t):
			pool.append(t)
	pool.sort()
	return "" if pool.is_empty() else pool[rng.randi_range(0, pool.size() - 1)]

## One or two traits. The first may be rare or legendary at the tier's odds; the rest are
## common or uncommon. Entry-level applicants only get common traits.
static func roll_traits(rng: RandomNumberGenerator, tier: int, entry: bool = false) -> Array:
	var out: Array = []
	var odds: Dictionary = TIERS[clampi(tier, 0, TIERS.size() - 1)]
	var roll: float = rng.randf()
	if not entry and roll < float(odds["legendary"]):
		out.append(_pick(rng, ["legendary"], out))
	elif not entry and roll < float(odds["legendary"]) + float(odds["rare"]):
		out.append(_pick(rng, ["rare"], out))
	else:
		out.append(_pick(rng, ["common"] if entry or rng.randf() < 0.6 else ["uncommon"], out))
	if rng.randf() < 0.35:
		out.append(_pick(rng, ["common"] if entry or rng.randf() < 0.6 else ["uncommon"], out))
	return out

# --- Value and terms -----------------------------------------------------------------

## A rough market value: skills (the best one counts most), traits and the gear they wear.
static func value(merc: Dictionary, with_gear: bool = true) -> int:
	var best: String = best_trade(merc)
	var total: float = 20.0 + 4.0 * pow(float(level(merc, best)), 2.0)
	for trade in TradeSkills.TRADES:
		if trade != best:
			total += 1.5 * pow(float(level(merc, trade)), 2.0)
	for t in merc.get("traits", []):
		total += float(TRAITS.get(str(t), {}).get("value", 0))
	if with_gear:
		for item in Gear.worn(merc):
			total += float(Gear.value(item))
	return maxi(20, int(round(total)))

## The lowest reputation tier a mercenary will serve: the best skill a company of that tier
## could recruit, and a legendary trait at least Respected.
static func min_tier(merc: Dictionary) -> int:
	var lv: int = best_level(merc)
	var tier: int = 0
	for i in range(TIERS.size()):
		if lv > int(TIERS[i]["cap"]):
			tier = i + 1
	for t in merc.get("traits", []):
		if str(TRAITS.get(str(t), {}).get("rarity", "")) == "legendary":
			tier = maxi(tier, 2)
	return clampi(tier, 0, TIERS.size() - 1)

static func base_wage(best: int) -> int:
	return 6 + int(round(float(best) * 0.55))

static func base_share(best: int) -> float:
	return minf(0.18, 0.08 + float(best) * 0.0025)

# --- Applicants ------------------------------------------------------------------------

static func _name(rng: RandomNumberGenerator) -> String:
	return Names.pick(rng)

static func _skills(rng: RandomNumberGenerator, focus: String, best: int) -> Dictionary:
	var skills: Dictionary = {}
	for trade in TradeSkills.TRADES:
		var lv: int = best if trade == focus else 1 + int(pow(rng.randf(), 2.0) * float(best) / 3.0)
		skills[trade] = TradeSkills.xp_for_level(lv if trade == focus else mini(lv, maxi(1, best - 1)))
	return skills

## A new person: skills, traits, terms and the basic tool for their best trade.
static func make_person(rng: RandomNumberGenerator, id: String, focus: String, best: int, tier: int, entry: bool) -> Dictionary:
	var person: Dictionary = {"id": id, "name": _name(rng), "skills": _skills(rng, focus, best),
		"traits": roll_traits(rng, tier, entry), "kit": STARTER_TOOL.get(focus, "")}
	person["skill"] = 8 + best
	person["wage"] = base_wage(best) + rng.randi_range(0, 1 if entry else 2)
	person["share"] = base_share(best)
	person["min_tier"] = min_tier(person)
	return person

## The recruit board for one half-hour epoch, for a company of this tier. Four green hands
## are always there (logging, mining, guarding, and one of the newer trades in turn); four more
## can be as good as the tier allows.
static func generate_board(epoch: int, tier: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(77933 + epoch * 99437 + tier * 7919)
	var cap: int = int(TIERS[clampi(tier, 0, TIERS.size() - 1)]["cap"])
	var board: Array[Dictionary] = []
	for i in range(8):
		var entry: bool = i < 4
		var focus: String
		if i < 3:
			focus = ENTRY_TRADES[i]
		elif i == 3:
			focus = ROTATING_TRADES[posmod(epoch, ROTATING_TRADES.size())]
		else:
			focus = RECRUIT_TRADES[rng.randi_range(0, RECRUIT_TRADES.size() - 1)]
		var floor_level: int = maxi(2, cap / 4)
		var best: int = rng.randi_range(2, 3) if entry else floor_level + int(float(cap - floor_level) * pow(rng.randf(), 1.4))
		var person: Dictionary = make_person(rng, "candidate_%d_%d" % [epoch, i], focus, best, tier, entry)
		var worth: int = value(person, false) + int(Catalog.item(str(person["kit"])).get("value", 0))
		if entry:
			# Green hands sign for their best skill and tool alone, so a new company can always start.
			worth = 20 + 4 * best * best + int(Catalog.item(str(person["kit"])).get("value", 0))
		person["hire"] = maxi(30, int(round(float(worth) * (rng.randf_range(0.85, 1.0) if entry else rng.randf_range(0.85, 1.05)))))
		person["kind"] = "recruit"
		board.append(person)
	return board

## Veterans other guilds are selling, refreshed every four hours. Only companies of tier 1+
## see any; each is priced above their shown value, plus the transfer fee.
static func guild_contracts(epoch: int, tier: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if tier < 1:
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = int(31337 + epoch * 104729 + tier * 613)
	var cap: int = int(TIERS[tier]["cap"])
	for i in range(rng.randi_range(2, 3)):
		var focus: String = RECRUIT_TRADES[rng.randi_range(0, RECRUIT_TRADES.size() - 1)]
		var best: int = rng.randi_range(maxi(2, cap / 2), cap)
		var person: Dictionary = make_person(rng, "contract_%d_%d" % [epoch, i], focus, best, tier, false)
		if int(person["min_tier"]) > tier:
			continue
		person["from"] = GUILDS[rng.randi_range(0, GUILDS.size() - 1)]
		var worth: int = value(person, false) + int(Catalog.item(str(person["kit"])).get("value", 0))
		var price: int = int(round(float(worth) * NPC_ASK))
		person["price"] = price
		person["hire"] = price + int(round(float(price) * TRANSFER_FEE))
		person["kind"] = "contract"
		out.append(person)
	return out

## Older saves: archetype mercenaries keep their skills, their old role becomes background,
## and each gains one common or uncommon trait.
static func migrate(merc: Dictionary) -> void:
	if merc.has("traits"):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(merc.get("id", ""))) & 0x7fffffff
	merc["traits"] = [_pick(rng, ["common", "uncommon"], [])]
	if merc.has("role"):
		merc["background"] = str(merc["role"])
		merc.erase("role")
	merc["min_tier"] = 0
