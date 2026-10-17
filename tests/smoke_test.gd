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
	print("Money Mercs smoke test passed.")
	quit(0)
