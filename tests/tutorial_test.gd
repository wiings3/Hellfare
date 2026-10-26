extends SceneTree
## The first-launch tutorial: a new guild walks welcome -> hire -> send -> wait -> sell -> done,
## steps move on by themselves, Skip ends it, and the card and pointer show in the book.
## In-memory guild only (no save file).
var failures: int = 0

func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error("Tutorial check failed: " + what)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	MoneyMercsState.persist = false
	var now: int = 1_900_000_000
	GameClock.fixed = now
	var g := MoneyMercsState.new()
	g.reset_company()
	check(str(g.tutorial["step"]) == "welcome", "a new guild starts on the welcome")
	check(not Tutorial.advance(g), "the welcome waits for its button")
	Tutorial.press(g)
	check(str(g.tutorial["step"]) == "hire", "then hiring")
	check(Tutorial.numbered("hire") == "Step 1 of 4", "steps are numbered (%s)" % Tutorial.numbered("hire"))
	var cutter: String = ""
	for c in g.recruitment_board():
		if Mercs.best_trade(c) == "logging" and cutter == "":
			cutter = str(c["id"])
	g.hire(cutter)
	check(Tutorial.advance(g) and str(g.tutorial["step"]) == "send", "hiring moves on to sending")
	var ids: Array[String] = [cutter]
	check(g.site_dispatch("mossward_copse", ids, "Balanced").begins_with("The crew set out"), "sent to Cinderwood")
	Tutorial.advance(g)
	check(str(g.tutorial["step"]) == "wait", "sending moves on to waiting")
	g.complete_due(now + 3600)
	Tutorial.advance(g)
	check(str(g.tutorial["step"]) == "sell", "a crew back moves on to selling")
	check(int(g.resources.get("timber", 0)) > 0, "there is ashwood to sell")
	check(not Tutorial.advance(g), "selling waits for a sale")
	g.trade("timber", false, 1)
	Tutorial.advance(g)
	check(str(g.tutorial["step"]) == "next", "a sale moves on to the closing note")
	Tutorial.press(g)
	check(str(g.tutorial["step"]) == "done" and not Tutorial.active(g), "Done ends it")
	# Doing things before reading: steps already done are skipped.
	var h := MoneyMercsState.new()
	h.reset_company()
	for c in h.recruitment_board():
		h.hire(str(c["id"]))
		break
	Tutorial.advance(h)
	check(str(h.tutorial["step"]) == "send", "hiring before reading skips ahead (%s)" % str(h.tutorial["step"]))
	Tutorial.skip(h)
	check(not Tutorial.active(h) and bool(h.tutorial.get("skipped", false)), "Skip ends the tutorial")
	# Replay on a running guild (g has people, reports, a sale): a tour, nothing reset.
	var crew_before: int = g.crew.size()
	var gold_before: int = g.gold
	Tutorial.replay(g)
	check(str(g.tutorial["step"]) == "welcome" and Tutorial.replaying(g), "replay starts at the welcome")
	check(not Tutorial.advance(g), "replay doesn't skip ahead on what the guild already has")
	Tutorial.press(g)
	check(str(g.tutorial["step"]) == "hire" and not Tutorial.advance(g), "replay waits on hiring even with people on the books")
	Tutorial.press(g)
	check(str(g.tutorial["step"]) == "send", "Next moves the tour on without hiring")
	g.gold += 500
	g.site_dispatch("mossward_copse", ids, "Balanced")
	Tutorial.advance(g)
	check(str(g.tutorial["step"]) == "wait", "a new crew sent moves the tour on")
	g.complete_due(now + 7200)
	Tutorial.advance(g)
	check(str(g.tutorial["step"]) == "sell", "a new report moves the tour on")
	check(g.crew.size() == crew_before and g.gold >= gold_before, "the tour changed nothing in the guild by itself")
	Tutorial.skip(g)
	# In the book: the card shows the step and the pointer points at the bookmark.
	var ui: Control = load("res://scenes/journal/widgets/main.tscn").instantiate()
	root.add_child(ui)
	await process_frame
	ui.game.reset_company()
	ui._refresh()
	await process_frame
	await process_frame
	var card: Control = ui.stage.get_node("TutorialCard")
	var body := "Card/Margin/Body/"
	check(card.visible and (card.get_node(body + "Title") as Label).text == "Welcome to Last Lantern", "the welcome shows on a new guild")
	check(not (card.get_node("Pointer") as Control).visible, "the welcome points at nothing")
	(card.get_node(body + "Next") as Button).pressed.emit()
	await process_frame
	check((card.get_node(body + "Title") as Label).text == "Hire a Hellfarer", "Show me moves to hiring")
	var pointer := card.get_node("Pointer") as Control
	var label := ui.stage.get_node("ChapterLabels/Label2") as Control
	check(pointer.visible and absf(pointer.position.y + pointer.size.y / 2.0 - (label.position.y + label.get_parent().position.y + label.size.y / 2.0)) < 3.0,
		"the pointer sits beside the Mercenaries bookmark")
	ui._turn_to("roster")
	await create_timer(0.3).timeout
	ui._update_tutorial()
	check(not pointer.visible, "the pointer hides once that page is open")
	(card.get_node(body + "Head/Skip") as Button).pressed.emit()
	await process_frame
	check(not card.visible, "Skip hides the card")
	# Settings > Replay tutorial brings it back as a tour, with Next on every step.
	var pm = ui.find_child("PauseMenu", true, false)
	(pm.get_node("Cover/Plate/Margin/Content/Settings/ReplayTutorial") as Button).pressed.emit()
	await create_timer(0.4).timeout
	ui._update_tutorial()
	check(card.visible and Tutorial.replaying(ui.game), "Replay tutorial starts the tour")
	(card.get_node(body + "Next") as Button).pressed.emit()
	await process_frame
	check((card.get_node(body + "Next") as Button).visible and (card.get_node(body + "Next") as Button).text == "Next  >", "a tour step has Next")
	check((card.get_node(body + "Head/Skip") as Button).text == "End tour", "the tour can be ended")
	await create_timer(0.6).timeout  # let the page turn finish
	ui.queue_free()
	await create_timer(0.1).timeout
	GameClock.fixed = -1
	if failures > 0:
		push_error("%d tutorial checks failed." % failures)
		quit(1)
		return
	print("Tutorial checks passed.")
	quit(0)
