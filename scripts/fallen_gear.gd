extends RefCounted
class_name FallenGear
## The death drop pool. When a mercenary dies at a site there is a 40% chance that 1-3
## pieces of their gear stay where they fell. Every item lasts 24 hours.
##
## Each player can only find a small random share of a site's pool (about 1 item in 100),
## and the share reshuffles every 24 hours. The player never sees the rest. Crews have a
## chance per trip to find something from the share, but it is only theirs once the finder
## makes it home; if the finder dies it drops back into the pool for someone else.
##
## Until real players arrive, NPC companies keep dying at the sites and feed the pool. Their
## items are generated deterministically from time and site, so they cost nothing to store.
## Only this company's own drops, claims and reserved finds are saved. Swapping this class
## for a server-backed one later keeps the same interface: share(), size(), drop(), claim().

const LIFETIME := 86400
const RESHUFFLE := 86400
## Share of the pool any one player can find.
const REACH := 0.0125
const DROP_CHANCE := 0.4
const DROP_MIN := 1
const DROP_MAX := 3
const MAX_FINDS := 2
## Chance per find roll, by standing orders.
const FIND_CHANCE := {"Cautious": 0.09, "Balanced": 0.12, "Deep Push": 0.18, "Long Shift": 0.45}
## Chance another player picks up an item from your share before it expires.
const TAKEN_CHANCE := 0.4
## NPC pool items added per hour at each site (dangerous sites see more deaths).
const NPC_RATE := {"mossward_copse": 6.0, "old_oakwood": 14.0, "harlow": 25.0}
## What fallen NPC mercenaries carried, by site. Weights.
const NPC_LOOT := {
	"mossward_copse": {"hand_axe": 30, "leather": 30, "felling_axe": 12, "rusted_sword": 10, "chainmail": 4, "steel_sword": 3, "wardens_axe": 1.2, "knights_blade": 0.3, "gilded_plate": 0.2},
	"old_oakwood": {"felling_axe": 20, "hand_axe": 15, "leather": 15, "rusted_sword": 8, "chainmail": 8, "steel_sword": 6, "wardens_axe": 2.5, "knights_blade": 1.0, "gilded_plate": 0.5},
	"harlow": {"basic_pick": 25, "leather": 15, "reinforced_pick": 12, "rusted_sword": 12, "steel_sword": 8, "chainmail": 8, "dwarven_pick": 1.5, "knights_blade": 1.0, "gilded_plate": 0.7},
}
const COMPANIES := ["Iron Hands", "Grey Lanterns", "Red Wolves", "Ashford Free Company", "Black Pines", "Copper Crowns", "Hollow Oaks", "Brightwater Guild", "Lantern Road Co.", "Salt Kings"]
const NAMES := ["Aldo", "Berin", "Cass", "Dunstan", "Edda", "Fenn", "Garth", "Hilde", "Ivo", "Jory", "Kell", "Lisbet", "Mott", "Nessa", "Orrin", "Pell", "Rook", "Sable", "Tamsin", "Wick"]

## This company's id for share rolls (stable across sessions).
var player: int = 0
## Items this company left behind or lost on the road: {uid, site, key, from, time}.
var drops: Array[Dictionary] = []
## uid -> time claimed (found by a crew, or carried home). Kept until the item would expire.
var claimed: Dictionary = {}
var _next_drop: int = 1

func _init() -> void:
	player = randi()

## 0..1 from a string, the same everywhere for the same input.
static func roll(text: String) -> float:
	# Godot's string hash barely changes for similar strings, so mix it (murmur3 finalizer).
	var h: int = hash(text) & 0xFFFFFFFF
	h ^= h >> 16
	h = (h * 0x85ebca6b) & 0xFFFFFFFF
	h ^= h >> 13
	h = (h * 0xc2b2ae35) & 0xFFFFFFFF
	h ^= h >> 16
	return float(h) / 4294967296.0

## Every item lying at `site` right now, whether or not this company can find it.
func size(site: String, now: int) -> int:
	var count: int = 0
	var first_hour: int = int((now - LIFETIME) / 3600)
	for h in range(first_hour, int(now / 3600) + 1):
		for item in _npc_hour(site, h):
			if _alive(item, now):
				count += 1
	for item in drops:
		if str(item["site"]) == site and _alive(item, now):
			count += 1
	return count

## The items at `site` this company could find right now, best first.
func share(site: String, now: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var first_hour: int = int((now - LIFETIME) / 3600)
	for h in range(first_hour, int(now / 3600) + 1):
		for item in _npc_hour(site, h):
			if _mine(item, now):
				out.append(item)
	for item in drops:
		if str(item["site"]) == site and _mine(item, now):
			out.append(item)
	out.sort_custom(func(a, b): return int(MercsV05.ITEMS.get(a["key"], {}).get("cost", 0)) > int(MercsV05.ITEMS.get(b["key"], {}).get("cost", 0)))
	return out

## Roll a trip's finds from the share. Found items are claimed at once (the crew has them),
## but only become the company's if the finder makes it home.
func roll_finds(site: String, orders: String, now: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var pool: Array[Dictionary] = share(site, now)
	var chance: float = float(FIND_CHANCE.get(orders, FIND_CHANCE["Balanced"]))
	for i in range(MAX_FINDS):
		if pool.is_empty() or rng.randf() >= chance:
			break
		var item: Dictionary = pool.pop_at(rng.randi_range(0, pool.size() - 1))
		claim(str(item["uid"]), now)
		found.append(item)
	return found

func claim(uid: String, now: int) -> void:
	claimed[uid] = now

## A mercenary died at `site` carrying `keys`: 40% chance that 1-3 of them stay behind.
## Returns the keys left in the pool.
func drop_from_death(site: String, keys: Array, who: String, now: int, rng: RandomNumberGenerator) -> Array[String]:
	var left: Array[String] = []
	if keys.is_empty() or rng.randf() >= DROP_CHANCE:
		return left
	var pieces: Array = keys.duplicate()
	var count: int = mini(rng.randi_range(DROP_MIN, DROP_MAX), pieces.size())
	for i in range(count):
		var key: String = str(pieces.pop_at(rng.randi_range(0, pieces.size() - 1)))
		drop(site, key, who, now)
		left.append(key)
	return left

## Put one item into a site's pool (a death, or a find lost on the way home).
func drop(site: String, key: String, who: String, now: int) -> void:
	drops.append({"uid": "own:%d:%d:%d" % [player, now, _next_drop], "site": site, "key": key, "from": who, "time": now})
	_next_drop += 1

## Forget expired items and claims.
func prune(now: int) -> void:
	var kept: Array[Dictionary] = []
	for item in drops:
		if now - int(item["time"]) < LIFETIME:
			kept.append(item)
	drops = kept
	for uid in claimed.keys():
		if now - int(claimed[uid]) > LIFETIME * 2:
			claimed.erase(uid)

func _alive(item: Dictionary, now: int) -> bool:
	var t: int = int(item["time"])
	return t <= now and now - t < LIFETIME and not claimed.has(str(item["uid"]))

## Alive, in this company's share for today, and not yet picked up by someone else.
func _mine(item: Dictionary, now: int) -> bool:
	if not _alive(item, now):
		return false
	var uid: String = str(item["uid"])
	if roll("%d|%s|%d" % [player, uid, int(now / RESHUFFLE)]) >= REACH:
		return false
	if roll("taken|" + uid) < TAKEN_CHANCE:
		var taken_at: int = int(item["time"]) + int(roll("when|" + uid) * float(LIFETIME))
		if now >= taken_at:
			return false
	return true

## The NPC items that fell at `site` during hour `h`. Same result on every call.
func _npc_hour(site: String, h: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rate: float = float(NPC_RATE.get(site, 0.0))
	if rate <= 0.0:
		return out
	var base: String = "%s|%d" % [site, h]
	var count: int = int(rate) + (1 if roll(base + "|n") < rate - floorf(rate) else 0)
	var table: Dictionary = NPC_LOOT.get(site, {})
	var total: float = 0.0
	for key in table:
		total += float(table[key])
	for i in range(count):
		var tag: String = "%s|%d" % [base, i]
		var pick: float = roll(tag + "|k") * total
		var key: String = ""
		for k in table:
			pick -= float(table[k])
			key = str(k)
			if pick <= 0.0:
				break
		var who: String = "%s of the %s" % [NAMES[int(roll(tag + "|w") * NAMES.size()) % NAMES.size()], COMPANIES[int(roll(tag + "|c") * COMPANIES.size()) % COMPANIES.size()]]
		out.append({"uid": "npc:" + tag, "site": site, "key": key, "from": who, "time": h * 3600 + int(roll(tag + "|t") * 3599.0)})
	return out

func to_dict() -> Dictionary:
	return {"player": player, "drops": drops, "claimed": claimed, "next": _next_drop}

func load_dict(data: Dictionary) -> void:
	if data.is_empty():
		return
	player = int(data.get("player", player))
	_next_drop = int(data.get("next", 1))
	drops.clear()
	for item in data.get("drops", []):
		if typeof(item) == TYPE_DICTIONARY and MercsV05.ITEMS.has(str(item.get("key", ""))):
			drops.append(item)
	claimed = (data.get("claimed", {}) as Dictionary).duplicate()
