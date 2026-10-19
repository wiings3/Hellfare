extends SceneTree
## Visual QA captures — actual 1440x900 Godot rendering under an X virtual display.
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var instance: Control = packed.instantiate()
	root.add_child(instance)
	instance.game.reset_company()
	instance.game.hire("garrick")
	instance.game.hire("oswin")
	instance.game.harlow_send_scout()
	instance.game.harlow["scout_finish"] = int(Time.get_unix_time_from_system()) - 1
	instance.game.harlow_sync()
	instance._toggle_crew(true, "garrick")
	instance._toggle_crew(true, "oswin")
	var destinations: Array = [
		["harlow", "res://docs/ui_harlow_preview.png"],
		["roster", "res://docs/ui_mercenaries_preview.png"],
		["market", "res://docs/ui_trading_preview.png"],
		["hq", "res://docs/ui_office_preview.png"],
		["armory", "res://docs/ui_armory_preview.png"],
		["ledger", "res://docs/ui_journal_preview.png"]
	]
	for destination in destinations:
		var name: String = str(destination[0])
		if name == "armory":
			instance.game.gold = 1200
			instance.game.buy_equipment("basic_pick")
			instance.game.buy_equipment("steel_sword")
			instance.game.buy_equipment("leather")
			instance._outfit("garrick")
		elif name == "ledger":
			instance._nav_to("harlow")
			instance._dispatch_harlow()
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
		screenshot.resize(1024, 640, Image.INTERPOLATE_LANCZOS)
		var error: Error = screenshot.save_png(str(destination[1]))
		if error != OK:
			push_error("Could not save image (%d)." % error)
			quit(1)
			return
		print("Visual QA saved: %s" % str(destination[1]))
	quit(0)
