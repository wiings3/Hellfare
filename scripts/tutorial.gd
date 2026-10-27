extends RefCounted
class_name Tutorial
## The first hour, as a guided tour. It opens with the prologue (scripts/ui/prologue.gd: the
## Lantern Company, the Ember Gate, Aldren's betrayal, choosing your first hero), then walks the
## new guild through its first loop: hire a woodcutter, send them out, lead your hero into the
## Fallen Keep while they work, sell the haul, and arm the hero for the floors that stopped them.
##
## Each step either moves on by itself when the player has done it ("done", checked against
## the guild) or waits for its button. Progress lives in the guild's save (state.tutorial); the
## card is scenes/journal/widgets/tutorial_card.tscn, and book_ui.gd points at the next click.

const STEPS := [
	{"id": "prologue", "title": "", "text": "", "point": ""},
	{"id": "hire", "title": "Hire a woodcutter",
	 "text": "A guild runs on gold, and gold comes up from the Maw. Hire a woodcutter: the ones holding an axe. They're paid for each trip.",
	 "point": "roster"},
	{"id": "send", "title": "Send them down",
	 "text": "Send your woodcutter to Cinderwood, just inside the Maw. A trip takes about a minute and a half, and crews keep working while the game is closed.",
	 "point": "expeditions"},
	{"id": "crypt", "title": "Lead your hero into the Fallen Keep",
	 "text": "While the crew works, take your hero down. The Fallen Keep is a crypt just past the Maw: clear the Cellars, then take what you carry out. Crews and heroes go out at the same time.",
	 "point": "expeditions"},
	{"id": "sell", "title": "Sell the haul",
	 "text": "Everything the guild owns is in the Warehouse (Workshop, third tab). Sell some ashwood to the merchants, or keep it to craft with.",
	 "button": "Keep it for now", "point": "market"},
	{"id": "gear", "title": "Arm your hero",
	 "text": "A rusty blade won't get through the Webbed Halls. The quartermaster in the Workshop sells blueprints: a helm, a shield, a better blade. Iron comes from the Gatepit (hire a miner), hides from the Hollow Fields (a hunter). Make a piece and put it on your hero.",
	 "button": "Later", "point": "workshop"},
	{"id": "next", "title": "Your guild is running",
	 "text": "Clear the Webbed Halls and their stairs stay open: the Bone Knight waits above them. Beat him and the deeper sites open to your crews. Heroes eat a ration a floor, so keep a fisher or hunter working. Long orders keep crews working overnight. More heroes and more crews come with gold and reputation. Somewhere below, Aldren is waiting. Esc opens Settings.",
	 "button": "Done", "point": ""},
]
## The bookmark each page lives under (index in the book's chapter tabs).
const BOOKMARKS := {"hq": 0, "expeditions": 1, "roster": 2, "workshop": 3, "market": 4, "ledger": 5}

static func step_index(id: String) -> int:
	for i in range(STEPS.size()):
		if str(STEPS[i]["id"]) == id:
			return i
	return -1

static func current(state) -> Dictionary:
	var i: int = step_index(str(state.tutorial.get("step", "done")))
	return STEPS[i] if i >= 0 else {}

static func active(state) -> bool:
	return not current(state).is_empty()

## Steps the player has numbered (the prologue and the closing note aren't counted).
static func numbered(id: String) -> String:
	var i: int = step_index(id)
	if i <= 0 or i >= STEPS.size() - 1:
		return ""
	return "Step %d of %d" % [i, STEPS.size() - 2]

## Move on when the player has done what the step asks. Returns true if the step changed.
## Steps already done are skipped (someone who hires and sends a crew before reading is fine).
## The prologue only ends from the prologue screen (press()).
static func advance(state) -> bool:
	var moved: bool = false
	for _guard in range(STEPS.size()):
		var step: Dictionary = current(state)
		if step.is_empty() or str(step["id"]) == "prologue" or not _done(state, str(step["id"])):
			break
		_go_next(state)
		moved = true
	return moved

## The step's button (or the prologue ending): on to the next one.
static func press(state) -> void:
	_go_next(state)

static func skip(state) -> void:
	state.tutorial = {"step": "done", "skipped": true}

## Replay from Settings, on a guild that's already running: a guided tour from the prologue.
## Each step waits for something new (a new hire, a new crew sent, a new crypt report, a sale,
## better gear on a hero) or for its Next button, so nothing has to be undone.
static func replay(state) -> void:
	state.tutorial = _baseline(state, "prologue", true)

static func replaying(state) -> bool:
	return bool(state.tutorial.get("replay", false))

## What the guild looks like as a step begins, to tell later what the player did.
static func _baseline(state, step: String, is_replay: bool) -> Dictionary:
	return {"step": step, "timber": int(state.resources.get("timber", 0)), "gold": state.gold, "replay": is_replay,
		"crew": state.crew.size(), "mission_id": int(state.next_mission_id),
		"reports": state.reports.size(), "crypts": _crypt_reports(state), "kit": _best_hero_kit(state),
		"report_t": int(state.reports[0].get("time", 0)) if not state.reports.is_empty() else 0}

static func _crypt_reports(state) -> int:
	var n: int = 0
	for r in state.reports:
		if str(r.get("dungeon", "")) != "":
			n += 1
	return n

static func _best_hero_kit(state) -> int:
	var best: int = 0
	for h in state.heroes:
		best = maxi(best, Gear.kit_rating(h))
	return best

static func _go_next(state) -> void:
	var i: int = step_index(str(state.tutorial.get("step", "done")))
	if i < 0 or i + 1 >= STEPS.size():
		state.tutorial = {"step": "done"}
		return
	state.tutorial = _baseline(state, str(STEPS[i + 1]["id"]), replaying(state))

static func _crews_sent(state) -> bool:
	for m in state.missions:
		if not bool(m.get("heroes", false)):
			return true
	for r in state.reports:
		if str(r.get("dungeon", "")) == "":
			return true
	return false

static func _done(state, id: String) -> bool:
	var t: Dictionary = state.tutorial
	if replaying(state):
		match id:
			"hire":
				return state.crew.size() > int(t.get("crew", 0))
			"send":
				for m in state.missions:
					if not bool(m.get("heroes", false)) and int(str(m.get("id", "job_0")).trim_prefix("job_")) >= int(t.get("mission_id", 0)):
						return true
				return false
			"crypt":
				return _crypt_reports(state) > int(t.get("crypts", 0))
			"sell":
				return int(state.resources.get("timber", 0)) < int(t.get("timber", 0)) and state.gold > int(t.get("gold", 0))
			"gear":
				return _best_hero_kit(state) > int(t.get("kit", 0))
		return false
	match id:
		"hire":
			return not state.crew.is_empty()
		"send":
			return _crews_sent(state)
		"crypt":
			return _crypt_reports(state) > 0
		"sell":
			# Some of the haul sold: less ashwood than when the step began, and more gold.
			return int(state.resources.get("timber", 0)) < int(t.get("timber", 0)) and state.gold > int(t.get("gold", 0))
		"gear":
			return _best_hero_kit(state) > int(t.get("kit", 0))
	return false
