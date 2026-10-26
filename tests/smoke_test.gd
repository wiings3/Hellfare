extends SceneTree

func _initialize() -> void:
	# Running this test outside CI is intentionally blocked: the test resets a save.
	if OS.get_environment("CI") != "true":
		push_error("Smoke tests are CI-only to protect the player's local save.")
		quit(1)
		return
	var game := MoneyMercsState.new()
	game.reset_company()
	assert(game.gold == 350)
	assert(game.crew.is_empty())
	assert(game.hire("garrick").contains("joined"))
	assert(game.gold == 280)
	var selection: Array[String] = ["garrick"]
	var response := game.dispatch("lowlands", selection, "Balanced")
	assert(response.begins_with("Expedition funded"), response)
	assert(game.missions.size() == 1)
	assert(game.free_crew() == 0)
	assert(game.complete_due(int(Time.get_unix_time_from_system()) + 3600) == 1)
	assert(game.missions.is_empty())
	assert(game.reports.size() == 1)
	assert(game.free_crew() == 1)
	assert(game.reputation > 0)
	game.save_game()
	var reloaded := MoneyMercsState.new()
	assert(reloaded.reports.size() == 1)
	assert(reloaded.crew.size() == 1)
	# Files from the game's Money Mercs days carry over to the Hellfare folder, once, never overwriting.
	var probe := "user://carry_over_probe.txt"
	var old_dir: String = OS.get_user_data_dir().get_base_dir().path_join(GameSettings.OLD_NAME)
	DirAccess.make_dir_recursive_absolute(old_dir)
	var old_file := FileAccess.open(old_dir.path_join("carry_over_probe.txt"), FileAccess.WRITE)
	old_file.store_string("from before")
	old_file.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(probe))
	GameSettings.carry_over(probe)
	assert(FileAccess.get_file_as_string(probe) == "from before")
	var newer := FileAccess.open(probe, FileAccess.WRITE)
	newer.store_string("newer")
	newer.close()
	GameSettings.carry_over(probe)
	assert(FileAccess.get_file_as_string(probe) == "newer")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(probe))
	DirAccess.remove_absolute(old_dir.path_join("carry_over_probe.txt"))
	print("Hellfare smoke test passed.")
	quit(0)
