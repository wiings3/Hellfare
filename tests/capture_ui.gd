extends SceneTree
## Visual QA capture — run only under a virtual display.
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
	instance._nav_to("harlow")
	instance._toggle_crew(true, "garrick")
	instance._toggle_crew(true, "oswin")
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	if img == null or img.is_empty():
		push_error("Could not capture Harlow frame.")
		quit(1)
		return
	var target := "res://docs/ui_harlow_preview.png"
	var error: Error = img.save_png(target)
	if error != OK:
		push_error("Could not save screenshot: %d" % error)
		quit(1)
		return
	print("Captured Harlow UI at %dx%d" % [img.get_width(),img.get_height()])
	quit(0)
