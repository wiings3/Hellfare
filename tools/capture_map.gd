extends SceneTree
## Records the Company map with crews out, as numbered PNG frames (for previews and GIFs).
## Never touches the save file.
## xvfb-run -a -s "-screen 0 1440x900x24" godot --path . --rendering-method gl_compatibility \
##     --resolution 1440x900 --script res://tools/capture_map.gd -- out=/tmp/map frames=90 step=4
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	MoneyMercsState.persist = false
	var args := {"out": "/tmp/map", "frames": "1", "step": "4", "page": "hq"}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	DirAccess.make_dir_recursive_absolute(str(args["out"]))
	var now: int = int(Time.get_unix_time_from_system())
	GameClock.fixed = now
	var ui: Control = load("res://scenes/journal/widgets/main.tscn").instantiate()
	root.add_child(ui)
	var game = ui.game
	game.reset_company()
	game.gold = 5000
	game.expedition_slots = 3
	var cutters: Array[String] = []
	var miners: Array[String] = []
	for candidate in game.recruitment_board():
		var id: String = str(candidate["id"])
		var role: String = str(candidate.get("role", ""))
		if (role == "Woodcutter" and cutters.size() < 3) or (role == "Miner" and miners.size() < 3) or role == "Guard":
			game.hire(id)
			if game.merc_by_id(id).is_empty():
				continue
			if role == "Woodcutter":
				cutters.append(id)
			elif role == "Miner":
				miners.append(id)
	game.harlow_send_scout()
	game.harlow["scout_finish"] = now - 1
	game.harlow_sync()
	# Real expeditions, shifted so they are at different points of their trips.
	print(game.site_dispatch("mossward_copse", cutters.slice(0, 2), "Balanced"))
	print(game.harlow_dispatch(miners, "Balanced"))
	var shifts := [-0.35, -0.02]
	for i in range(mini(shifts.size(), game.missions.size())):
		var m: Dictionary = game.missions[i]
		var span: int = int(m["finish"]) - int(m["started"])
		var shift: int = int(float(span) * float(shifts[i]))
		m["started"] = int(m["started"]) + shift
		m["finish"] = int(m["finish"]) + shift
	ui._nav_to("standing")
	ui._nav_to("hq")
	ui._nav_to(str(args["page"]))
	for f in range(int(args["frames"])):
		for k in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		var shot: Image = root.get_texture().get_image()
		shot.save_png("%s/f%03d.png" % [args["out"], f])
		GameClock.fixed += int(args["step"])
	print("captured %s frames" % args["frames"])
	quit(0)
