extends SceneTree
## The first hour: a new guild opens on the prologue, then walks hire -> send -> crypt -> sell ->
## gear -> done; steps move on by themselves, Skip ends it, Replay runs it as a tour on a guild
## that's already going. In the book: the prologue shows first, skipping it leads to choosing a
## hero, and the pointer follows each next click — into the crawl screen and back out.
## In-memory guild only (no save file).
var failures: int = 0

func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error("Tutorial check failed: " + what)

func _initialize() -> void:
	call_deferred("_run")

func _settle(ui) -> void:
	await create_timer(0.7).timeout  # the page turn
	ui._update_tutorial()
	await process_frame

## True if the pointer is showing just left of the control tagged `tag`, level with it.
func _points_at(ui, pointer: Control, tag: String) -> bool:
	var target: Control = ui._tut_find(tag)
	if target == null or not pointer.visible:
		return false
	var at: Vector2 = pointer.get_meta("at", Vector2(-999, -999))
	var r: Rect2 = target.get_global_rect()
	var mid: float = at.y + pointer.size.y * pointer.get_global_transform().get_scale().y / 2.0
	return absf(mid - r.get_center().y) < 3.0 and at.x < r.position.x and at.x > r.position.x - 80.0

## Play a led run to the end of the current floor by the automatic rules, then take it out.
func _play_out_led(g) -> void:
	var guard: int = 0
	while not g.lead_run().is_empty() and str(g.lead_run()["stage"]) == "led" and guard < 400:
		guard += 1
		var st: Dictionary = g.lead_fight()
		var c: Array = Crawl.ai_choice(st, Crawl.turn_of(st))
		g.lead_act(str(c[0]), int(c[1]))
	if not g.lead_run().is_empty():
		g.lead_choose(false)

func _run() -> void:
	MoneyMercsState.persist = false
	var now: int = 1_900_000_000
	GameClock.fixed = now
	var g := MoneyMercsState.new()
	g.reset_company()
	check(str(g.tutorial["step"]) == "prologue", "a new guild starts on the prologue")
	check(not Tutorial.advance(g), "the prologue only ends from its own screen")
	g.found_hero("knight", "Test Knight")
	Tutorial.press(g)
	check(str(g.tutorial["step"]) == "hire", "then hiring")
	check(Tutorial.numbered("hire") == "Step 1 of 5", "steps are numbered (%s)" % Tutorial.numbered("hire"))
	var cutter: String = ""
	for c in g.recruitment_board():
		if Mercs.best_trade(c) == "logging" and cutter == "":
			cutter = str(c["id"])
	g.hire(cutter)
	check(Tutorial.advance(g) and str(g.tutorial["step"]) == "send", "hiring moves on to sending")
	var ids: Array[String] = [cutter]
	check(g.site_dispatch("mossward_copse", ids, "Balanced").begins_with("The crew set out"), "sent to Cinderwood")
	Tutorial.advance(g)
	check(str(g.tutorial["step"]) == "crypt", "sending moves on to the crypt")
	var hero: Array[String] = [str(g.heroes[0]["id"])]
	check(g.dungeon_dispatch("calder_keep", hero, 1, "half", "safe", true).begins_with("The crew went"), "the hero goes in while the crew works")
	check(not Tutorial.advance(g), "the crypt step waits for the run")
	_play_out_led(g)
	Tutorial.advance(g)
	check(str(g.tutorial["step"]) == "sell", "a crypt run moves on to selling (%s)" % str(g.tutorial["step"]))
	g.complete_due(now + 3600)
	check(int(g.resources.get("timber", 0)) > 0, "the crew brought ashwood")
	Tutorial.advance(g)
	check(str(g.tutorial["step"]) == "sell", "selling waits for a sale (the step began before the crew was back)")
	g.tutorial = Tutorial._baseline(g, "sell", false)
	g.trade("timber", false, 1)
	Tutorial.advance(g)
	check(str(g.tutorial["step"]) == "gear", "a sale moves on to arming the hero")
	g.equipment_inventory.append(g.make_item("iron_helm", "common"))
	g.equip_item(str(g.heroes[0]["id"]), str(g.equipment_inventory.back()["uid"]))
	Tutorial.advance(g)
	check(str(g.tutorial["step"]) == "next", "better gear on the hero moves on to the closing note")
	Tutorial.press(g)
	check(str(g.tutorial["step"]) == "done" and not Tutorial.active(g), "Done ends it")
	# Doing things before reading: steps already done are skipped.
	var h := MoneyMercsState.new()
	h.reset_company()
	for c in h.recruitment_board():
		h.hire(str(c["id"]))
		break
	Tutorial.press(h)
	Tutorial.advance(h)
	check(str(h.tutorial["step"]) == "send", "hiring before reading skips ahead (%s)" % str(h.tutorial["step"]))
	Tutorial.skip(h)
	check(not Tutorial.active(h) and bool(h.tutorial.get("skipped", false)), "Skip ends the tutorial")
	# Replay on a running guild: a tour from the prologue, nothing reset.
	var crew_before: int = g.crew.size()
	var gold_before: int = g.gold
	Tutorial.replay(g)
	check(str(g.tutorial["step"]) == "prologue" and Tutorial.replaying(g), "replay starts at the prologue")
	Tutorial.press(g)
	check(str(g.tutorial["step"]) == "hire" and not Tutorial.advance(g), "replay waits on hiring even with people on the books")
	Tutorial.press(g)
	Tutorial.press(g)
	check(str(g.tutorial["step"]) == "crypt", "Next moves the tour on")
	g.heroes[0]["health"] = 100
	GameClock.fixed = now + 7200
	g.dungeon_dispatch("calder_keep", hero, 1, "half", "safe", true)
	_play_out_led(g)
	Tutorial.advance(g)
	check(str(g.tutorial["step"]) == "sell", "a new crypt report moves the tour on")
	check(g.crew.size() == crew_before and g.gold >= gold_before - 50, "the tour changed nothing in the guild by itself")
	Tutorial.skip(g)

	# --- In the book ---------------------------------------------------------------------
	GameClock.fixed = now
	var ui: Control = load("res://scenes/journal/widgets/main.tscn").instantiate()
	root.add_child(ui)
	await process_frame
	ui.game.reset_company()
	ui._refresh()
	await process_frame
	await process_frame
	var card: Control = ui.stage.get_node("TutorialCard")
	var prologue: Control = ui.stage.get_node("PrologueView")
	var body := "Card/Margin/Body/"
	check(prologue.visible and not card.visible, "a new guild opens on the prologue")
	check((prologue.get_node("Card/Margin/Body/Title") as Label).text == "The Lantern Company", "the prologue's first card")
	(prologue.get_node("Card/Margin/Body/Buttons/Skip") as Button).pressed.emit()
	await process_frame
	check((prologue.get_node("Choice") as Control).visible, "skipping goes to choosing the first hero")
	(prologue.get_node("Choice/Options/Rogue/Margin/Body/Choose") as Button).pressed.emit()
	await create_timer(0.9).timeout
	check(not prologue.visible and ui.game.heroes.size() == 1 and Heroes.cls(ui.game.heroes[0]) == "rogue", "the chosen hero leads the new guild")
	await _settle(ui)
	check(card.visible and (card.get_node(body + "Title") as Label).text == "Hire a woodcutter", "then the tour begins")
	var pointer := card.get_node("Pointer") as Control
	var do_text := card.get_node(body + "Do/Text") as Label
	var label := ui.stage.get_node("ChapterLabels/Label2") as Control
	check(pointer.visible and absf(pointer.position.y + pointer.size.y / 2.0 - (label.position.y + label.get_parent().position.y + label.size.y / 2.0)) < 3.0,
		"the pointer sits beside the Mercenaries bookmark")
	# It keeps pointing at the next click, through hiring and sending.
	ui._turn_to("roster")
	await _settle(ui)
	check(_points_at(ui, pointer, "tab:recruits"), "on Mercenaries it points at the Recruit tab (%s)" % do_text.text)
	ui._set_roster_tab("recruits")
	var other := ""
	var wood := ""
	for c in ui.game.recruitment_board():
		if Mercs.role_of(c) != "Woodcutter" and other == "":
			other = str(c["id"])
		if Mercs.role_of(c) == "Woodcutter" and wood == "" and int(c["hire"]) <= ui.game.gold:
			wood = str(c["id"])
	ui._choose_candidate(other)
	await _settle(ui)
	check(_points_at(ui, pointer, "recruit:Woodcutter"), "with someone else chosen it points at a woodcutter (%s)" % do_text.text)
	ui._choose_candidate(wood)
	await _settle(ui)
	check(_points_at(ui, pointer, "hire") and do_text.text.begins_with("Press Hire"), "with a woodcutter chosen it points at Hire (%s)" % do_text.text)
	ui._hire(wood)
	await _settle(ui)
	check((card.get_node(body + "Title") as Label).text == "Send them down", "hiring moves the card on")
	ui._turn_to("expeditions")
	await _settle(ui)
	check(_points_at(ui, pointer, "site:mossward_copse"), "on the board it points at Cinderwood (%s)" % do_text.text)
	ui._open_site("mossward_copse")
	await _settle(ui)
	check(_points_at(ui, pointer, "crew_free"), "at Cinderwood it points at the woodcutter (%s)" % do_text.text)
	ui._toggle_crew(true, wood)
	await _settle(ui)
	check(_points_at(ui, pointer, "fund"), "with a crew picked it points at Send them down (%s)" % do_text.text)
	ui._dispatch_site()
	await _settle(ui)
	# The crypt: Expeditions, Crypts, the Fallen Keep, the hero, Lead them in, the crawl.
	check((card.get_node(body + "Title") as Label).text.begins_with("Lead your hero"), "sending moves on to the crypt")
	ui._turn_to("expeditions")
	await _settle(ui)
	check(_points_at(ui, pointer, "trade:dungeon"), "it points at Crypts (%s)" % do_text.text)
	ui._select_trade("dungeon")
	await _settle(ui)
	check(_points_at(ui, pointer, "crypt:calder_keep"), "then the Fallen Keep (%s)" % do_text.text)
	ui._open_dungeon("calder_keep")
	await _settle(ui)
	check(_points_at(ui, pointer, "hero_pick"), "then the hero (%s)" % do_text.text)
	ui._toggle_crew(true, str(ui.game.heroes[0]["id"]))
	await _settle(ui)
	check(_points_at(ui, pointer, "lead"), "then Lead them in (%s)" % do_text.text)
	ui._enter_dungeon(true)
	await _settle(ui)
	check(ui._crawl_view().visible and _points_at(ui, pointer, "crawl:strike"), "in the crawl it points at Strike (%s)" % do_text.text)
	(card.get_node(body + "Head/Skip") as Button).pressed.emit()
	await process_frame
	check(not card.visible, "Skip hides the card")
	ui._crawl_view().close()
	await process_frame
	# Arming the hero: learn, craft, then equip, one click at a time.
	var gm = ui.game
	gm.tutorial = Tutorial._baseline(gm, "gear", false)
	gm.gold = 500
	gm.resources["iron"] = 4
	gm.resources["rabbit_hide"] = 2
	ui._turn_to("workshop")
	await _settle(ui)
	check(card.visible and (card.get_node(body + "Title") as Label).text == "Arm your hero", "the gear step shows")
	ui._set_workshop_tab("shop")
	await _settle(ui)
	var learn_key: String = ""
	for k in gm.blueprint_shop():
		if _points_at(ui, pointer, "learn:" + str(k)):
			learn_key = str(k)
	check(learn_key != "", "in the Shop it points at a blueprint to learn (%s)" % do_text.text)
	if learn_key != "":
		ui._buy_blueprint(learn_key)
		await _settle(ui)
		ui._set_workshop_tab("craft")
		await _settle(ui)
		check(_points_at(ui, pointer, "recipe:" + learn_key) or _points_at(ui, pointer, "craft:" + learn_key), "then at the recipe (%s)" % do_text.text)
		ui._choose_recipe(learn_key)
		await _settle(ui)
		check(_points_at(ui, pointer, "craft:" + learn_key), "then at Craft (%s)" % do_text.text)
		ui._craft(learn_key)
		await _settle(ui)
		check(do_text.text.contains("Mercenaries"), "then off to put it on (%s)" % do_text.text)
		ui._turn_to("roster")
		ui._set_roster_tab("heroes")
		ui.selected_merc = str(gm.heroes[0]["id"])
		ui.dossier_view = "gear"
		ui.selected_slot = Gear.slot_of(learn_key)
		ui._refresh()
		await _settle(ui)
		check(_points_at(ui, pointer, "equip:" + learn_key), "and at Equip (%s)" % do_text.text)
	Tutorial.skip(gm)
	# The guild was named on the choice screen; Settings can rename it.
	var pm = ui.find_child("PauseMenu", true, false)
	check(ui.game.guild_name.length() >= 2 and (pm.get_node("Cover/Plate/Margin/Content/Settings/Guild/Name") as LineEdit).text == ui.game.guild_name,
		"the guild has the name from the choice screen, and Settings shows it (%s)" % ui.game.guild_name)
	(pm.get_node("Cover/Plate/Margin/Content/Settings/Guild/Name") as LineEdit).text = "Soot Covenant"
	(pm.get_node("Cover/Plate/Margin/Content/Settings/Guild/Rename") as Button).pressed.emit()
	await process_frame
	check(ui.game.guild_name == "Soot Covenant", "Rename in Settings renames the guild")
	# Credits (the art license asks for them in the game), the version, and Send feedback only
	# when there is somewhere to send it.
	var credits := pm.get_node("Cover/Plate/Margin/Content/Credits") as Control
	(pm.get_node("Cover/Plate/Margin/Content/Main/CreditsButton") as Button).pressed.emit()
	var credit_text: String = (credits.get_node("Scroll/Text") as Label).text
	check(credits.visible and "Aleksandr Makarov" in credit_text and "Firepious" in credit_text and "Kenney" in credit_text,
		"Credits opens and names the artists")
	(credits.get_node("Back") as Button).pressed.emit()
	check(not credits.visible and (pm.get_node("Cover/Plate/Margin/Content/Main") as Control).visible, "and Back returns to the menu")
	check((pm.get_node("Cover/Plate/Margin/Content/Version") as Label).text.begins_with("v0."), "the menu shows the version")
	check((pm.get_node("Cover/Plate/Margin/Content/Main/Feedback") as Control).visible == (pm.feedback_url() != ""),
		"Send feedback shows only when the project has an address for it")
	# Settings > Replay tutorial brings it back as a tour: the prologue first, nothing founded.
	(pm.get_node("Cover/Plate/Margin/Content/Settings/ReplayTutorial") as Button).pressed.emit()
	await create_timer(0.4).timeout
	ui._update_tutorial()
	check(prologue.visible and Tutorial.replaying(ui.game), "Replay tutorial starts with the prologue")
	(prologue.get_node("Card/Margin/Body/Buttons/Skip") as Button).hide()
	(prologue.get_node("Card/Margin/Body/Buttons/Next") as Button).pressed.emit()
	await create_timer(1.2).timeout
	check(ui._crawl_view().visible, "the prologue fight opens on the crawl screen")
	await create_timer(0.6).timeout
	# Settings > Start a new guild asks twice, then everything starts over at the prologue.
	prologue._skip()
	await create_timer(0.8).timeout
	var new_btn := pm.get_node("Cover/Plate/Margin/Content/Settings/NewGuild") as Button
	new_btn.pressed.emit()
	check(ui.game.guild_name != "" and new_btn.text.begins_with("Sure"), "the first press only asks")
	new_btn.pressed.emit()
	await create_timer(0.5).timeout
	check(ui.game.guild_name == "" and ui.game.heroes.is_empty() and ui.game.rations_held() == 6, "the second starts a new guild (%s)" % ui.game.guild_name)
	check(str(ui.game.tutorial.get("step", "")) == "prologue" and prologue.visible, "and opens on the prologue")
	ui.queue_free()
	await create_timer(0.1).timeout
	GameClock.fixed = -1
	if failures > 0:
		push_error("%d tutorial checks failed." % failures)
		quit(1)
		return
	print("Tutorial checks passed.")
	quit(0)
