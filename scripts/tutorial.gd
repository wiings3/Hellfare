extends RefCounted
class_name Tutorial
## The first-launch tutorial: a few steps through the game's first loop (hire, send down, wait,
## sell). Each step names the bookmark to open ("point"), and either moves on by itself when the
## player has done it ("done", checked against the guild) or waits for its button. Progress lives
## in the guild's save (state.tutorial); the card is scenes/journal/widgets/tutorial_card.tscn.

const STEPS := [
	{"id": "welcome", "title": "Welcome to Last Lantern",
	 "text": "You run a guild of Hellfarers: people who go down through the Maw for pay. You hire them, send them down, and sell what they bring back up. The first trip takes about five minutes.",
	 "button": "Show me", "point": ""},
	{"id": "hire", "title": "Hire a Hellfarer",
	 "text": "Open Mercenaries, then Recruit, and hire a woodcutter: the ones holding an axe. They're paid for each trip they make.",
	 "point": "roster"},
	{"id": "send", "title": "Send them down",
	 "text": "Open Expeditions, choose Logging, then Cinderwood. Click your woodcutter to add them to the crew, then press Send them down.",
	 "point": "expeditions"},
	{"id": "wait", "title": "Wait for them to come back up",
	 "text": "A trip to Cinderwood takes five minutes, and crews keep working while the game is closed. Watch them on the Guild page; a bell rings when they're back.",
	 "point": "hq"},
	{"id": "sell", "title": "Sell the haul",
	 "text": "The ashwood they brought up is in the Warehouse (Workshop, third tab), with everything else the guild owns. Open Market and sell some to the merchants, or keep it to craft with later.",
	 "button": "Keep it for now", "point": "market"},
	{"id": "next", "title": "Your guild is running",
	 "text": "From here: hire more hands, gear them up in the Workshop, and sign a Warden's charter in the Ledger for a second crew. When your fighters reach gear score 8, try the Fallen Keep. Esc opens Settings.",
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

## Steps the player has numbered (the welcome and the closing note aren't counted).
static func numbered(id: String) -> String:
	var i: int = step_index(id)
	if i <= 0 or i >= STEPS.size() - 1:
		return ""
	return "Step %d of %d" % [i, STEPS.size() - 2]

## Move on when the player has done what the step asks. Returns true if the step changed.
## Steps already done are skipped (someone who hires and sends a crew before reading is fine).
static func advance(state) -> bool:
	var moved: bool = false
	for _guard in range(STEPS.size()):
		var step: Dictionary = current(state)
		if step.is_empty() or not _done(state, str(step["id"])):
			break
		_go_next(state)
		moved = true
	return moved

## The step's button (or Skip on the last step): on to the next one.
static func press(state) -> void:
	_go_next(state)

static func skip(state) -> void:
	state.tutorial = {"step": "done", "skipped": true}

## Replay from Settings, on a guild that's already running: a guided tour. Each step waits for
## something new (a new hire, a new crew sent, a new report, a sale) or for its Next button,
## so nothing has to be undone and nothing in the guild changes.
static func replay(state) -> void:
	state.tutorial = _baseline(state, "welcome", true)

static func replaying(state) -> bool:
	return bool(state.tutorial.get("replay", false))

## What the guild looks like as a step begins, to tell later what the player did.
static func _baseline(state, step: String, is_replay: bool) -> Dictionary:
	return {"step": step, "timber": int(state.resources.get("timber", 0)), "gold": state.gold, "replay": is_replay,
		"crew": state.crew.size(), "mission_id": int(state.next_mission_id),
		"reports": state.reports.size(),
		"report_t": int(state.reports[0].get("time", 0)) if not state.reports.is_empty() else 0}

static func _go_next(state) -> void:
	var i: int = step_index(str(state.tutorial.get("step", "done")))
	if i < 0 or i + 1 >= STEPS.size():
		state.tutorial = {"step": "done"}
		return
	state.tutorial = _baseline(state, str(STEPS[i + 1]["id"]), replaying(state))

static func _done(state, id: String) -> bool:
	if replaying(state):
		var t: Dictionary = state.tutorial
		match id:
			"hire":
				return state.crew.size() > int(t.get("crew", 0))
			"send":
				return int(state.next_mission_id) > int(t.get("mission_id", 0))
			"wait":
				return state.reports.size() > int(t.get("reports", 0)) or (not state.reports.is_empty() and int(state.reports[0].get("time", 0)) > int(t.get("report_t", 0)))
			"sell":
				return int(state.resources.get("timber", 0)) < int(t.get("timber", 0)) and state.gold > int(t.get("gold", 0))
		return false
	match id:
		"welcome":
			return not state.crew.is_empty()
		"hire":
			return not state.crew.is_empty()
		"send":
			return not state.missions.is_empty() or not state.reports.is_empty()
		"wait":
			return not state.reports.is_empty() and state.missions.is_empty()
		"sell":
			# Some of the haul sold: less ashwood than when the step began, and more gold.
			return int(state.resources.get("timber", 0)) < int(state.tutorial.get("timber", 0)) and state.gold > int(state.tutorial.get("gold", 0))
	return false
