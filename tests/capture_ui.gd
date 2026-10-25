extends SceneTree
## Visual QA captures — actual 1440x900 Godot rendering under an X virtual display.
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed: PackedScene = load("res://scenes/journal/widgets/main.tscn")
	var instance: Control = packed.instantiate()
	root.add_child(instance)
	instance.game.reset_company()
	instance.game.hire("garrick")
	instance.game.hire("oswin")
	instance._toggle_crew(true, "garrick")
	instance._toggle_crew(true, "oswin")
	var widescreen: bool = OS.get_environment("MM_CAPTURE_WIDE") == "1"
	var destinations: Array = [
		["harlow", "res://docs/ui_harlow_preview.jpg"],
		["roster", "res://docs/ui_mercenaries_preview.jpg"],
		["recruits", "res://docs/ui_recruitment_preview.jpg"],
		["regions", "res://docs/ui_regions_preview.jpg"],
		["guildwork", "res://docs/ui_guildwork_preview.jpg"],
		["finance", "res://docs/ui_finance_preview.jpg"],
		["market", "res://docs/ui_trading_preview.jpg"],
		["hq", "res://docs/ui_office_preview.jpg"],
		["armory", "res://docs/ui_armory_preview.jpg"],
		["ledger", "res://docs/ui_journal_preview.jpg"]
	]
	if widescreen:
		destinations = [
			["hq", "res://docs/ui_office_wide_preview.jpg"],
			["harlow", "res://docs/ui_harlow_wide_preview.jpg"],
			["guildwork", "res://docs/ui_guildwork_wide_preview.jpg"],
			["finance", "res://docs/ui_finance_wide_preview.jpg"],
			["market", "res://docs/ui_trading_wide_preview.jpg"]
		]
	for destination in destinations:
		var name: String = str(destination[0])
		if name == "recruits":
			instance._nav_to("roster")
			instance._set_roster_tab("recruits")
		elif name == "regions":
			instance._nav_to("expeditions")
		elif name == "armory":
			instance.game.gold = 1200
			instance.game.buy_equipment("basic_pick")
			instance.game.buy_equipment("steel_sword")
			instance.game.buy_equipment("leather")
			instance._outfit("garrick")
		elif name == "ledger":
			instance._nav_to("harlow")
			instance._dispatch_site()
			if not instance.game.missions.is_empty():
				instance.game.complete_due(int(Time.get_unix_time_from_system()) + 500)
			instance._nav_to("ledger")
		else:
			instance._nav_to(name)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var screenshot: Image = root.get_texture().get_image()
		if screenshot == null or screenshot.is_empty():
			push_error("Could not capture %s." % str(destination[0]))
			quit(1)
			return
		# Downscale only the regression image; the running game remains 1440x900.
		# Keep the file below GitHub's 1 MiB Contents API read limit.
		if widescreen:
			screenshot.resize(1600, 900, Image.INTERPOLATE_LANCZOS)
		else:
			screenshot.resize(1120, 700, Image.INTERPOLATE_LANCZOS)
		var error: Error = screenshot.save_jpg(str(destination[1]), 0.85)
		if error != OK:
			push_error("Could not save image (%d)." % error)
			quit(1)
			return
		print("Visual QA saved: %s" % str(destination[1]))
	quit(0)
