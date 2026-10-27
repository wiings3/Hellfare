extends SceneTree
## Saving is write-then-swap with a backup; a damaged save is restored from the backup and
## kept aside, never overwritten. Uses its own save file, never the player's.
var failures: int = 0

func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error("Save check failed: " + what)

func _initialize() -> void:
	MoneyMercsState.SAVE_PATH = "user://save_test_guild.json"
	MoneyMercsState.persist = true
	_clean()
	var g := MoneyMercsState.new()
	check(g.rations_held() == 6 and g.guild_name == "", "a new guild: six meals, no name yet")
	check(g.set_guild_name("  The   Cinder   Oath ").begins_with("The guild is now") and g.guild_name == "The Cinder Oath", "names are tidied")
	check(not g.set_guild_name("x").begins_with("The guild"), "a name needs two letters")
	g.gold = 1234
	g.save_game()
	check(FileAccess.file_exists(MoneyMercsState.SAVE_PATH) and not FileAccess.file_exists(MoneyMercsState.save_tmp()), "saved, nothing left half-written")
	g.gold = 2222
	g.save_game()
	check(int(MoneyMercsState.read_save(MoneyMercsState.save_bak()).get("gold", 0)) == 1234, "the previous save is kept as a backup")
	var kept: String = g.keep_previous_guild()
	check(kept.begins_with("save_test_guild.json.previous-") and FileAccess.file_exists("user://" + kept), "starting over keeps the old guild as a file (%s)" % kept)
	var again := MoneyMercsState.new()
	check(again.gold == 2222 and again.guild_name == "The Cinder Oath", "loads what was saved, name and all")
	# Damage the save: the backup comes back, the damaged file is kept.
	var f := FileAccess.open(MoneyMercsState.SAVE_PATH, FileAccess.WRITE)
	f.store_string("{\"version\": 1, \"gold\": 22")
	f.close()
	var restored := MoneyMercsState.new()
	check(restored.gold == 1234 and restored.last_notice.contains("backup"), "a damaged save is restored from the backup (%d, %s)" % [restored.gold, restored.last_notice])
	check(_damaged_count() == 1, "and the damaged file is kept aside")
	# Nothing readable at all: a new guild, but the damaged file is still kept.
	_clean()
	f = FileAccess.open(MoneyMercsState.SAVE_PATH, FileAccess.WRITE)
	f.store_string("not a save")
	f.close()
	var fresh := MoneyMercsState.new()
	check(fresh.gold == 350 and fresh.last_notice.contains("damaged") and _damaged_count() == 1, "unreadable with no backup: a new guild, the old file kept")
	_clean()
	MoneyMercsState.persist = false
	if failures > 0:
		push_error("%d save checks failed." % failures)
		quit(1)
		return
	print("Save checks passed.")
	quit(0)

func _damaged_count() -> int:
	var n: int = 0
	var dir := DirAccess.open("user://")
	for name in dir.get_files():
		if name.begins_with("save_test_guild.json.damaged"):
			n += 1
	return n

func _clean() -> void:
	var dir := DirAccess.open("user://")
	for name in dir.get_files():
		if name.begins_with("save_test_guild.json"):
			dir.remove(name)
