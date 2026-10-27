extends SceneTree
## The crypt event card in the book: it shows a waiting event, and after an answer it shrinks to
## fit the result (it once measured the result before it had wrapped and stood ~400 px tall).
## In-memory guild only (no save file).
var failures: int = 0

func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error("Event card check failed: " + what)

func kit(g, id: String, keys: Array, combat: int) -> void:
	var m: Dictionary = g.merc_by_id(id)
	m["skills"]["combat"] = TradeSkills.xp_for_level(combat)
	for k in keys:
		m["equipment"][Gear.slot_of(k)] = g.make_item(k, "common")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	MoneyMercsState.persist = false
	GameClock.fixed = 1_900_000_000
	var ui: Control = load("res://scenes/journal/widgets/main.tscn").instantiate()
	root.add_child(ui)
	await process_frame
	var g = ui.game
	g.reset_company()
	g.tutorial = {"step": "done"}
	g.gold = 5000
	var ids: Array[String] = []
	g.hero_slots = 2
	for i in range(2):
		var h: Dictionary = Heroes.make("hero_e%d" % i, "Hero %d" % i, "knight")
		g.heroes.append(h)
		ids.append(str(h["id"]))
	kit(g, ids[0], ["steel_sword", "chainmail", "iron_helm"], 9)
	kit(g, ids[1], ["steel_sword", "chainmail"], 8)
	check(g.dungeon_dispatch("calder_keep", ids, 3, "half", "bold").begins_with("The crew went"), "a crew goes into the Fallen Keep")
	var m: Dictionary = g.missions[0]
	GameClock.fixed = int(m["ev"][0]["t"]) + 1
	ui._refresh()
	ui._update_event_card()
	await create_timer(0.3).timeout
	var card := ui.stage.get_node("EventCard") as Control
	var panel := card.get_node("Card") as Control
	check(card.visible, "the event card shows while an event waits")
	var asking: float = panel.size.y
	ui._answer_event(str(m["id"]), 0, 0)
	await process_frame
	await process_frame
	var result := card.get_node("Card/Margin/Body/Result") as Label
	check(result.visible and result.text != "", "the answer's result shows on the card")
	check(panel.size.y <= asking + 20.0, "the card fits the result after answering (%.0f px, was %.0f asking)" % [panel.size.y, asking])
	check(is_equal_approx(panel.offset_top, panel.offset_bottom - panel.size.y), "the card grows up from the corner")
	await create_timer(0.6).timeout
	ui.queue_free()
	await create_timer(0.1).timeout
	GameClock.fixed = -1
	if failures > 0:
		push_error("%d event card checks failed." % failures)
		quit(1)
		return
	print("Event card checks passed.")
	quit(0)
