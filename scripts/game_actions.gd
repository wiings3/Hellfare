extends Control
## Small bridge from UI actions to game systems; no layout or page rendering.
## Kept intentionally simple for a small Godot project.

var game: MoneyMercsState
var page: String = "hq"
var roster_tab: String = "employed"
var selected_crew: Array[String] = []
var tactic: String = "Balanced"
var selected_region: String = "lowlands"
var selected_item: String = "copper"
var selected_merc: String = ""
var selected_report: int = 0
var _reset_confirm: bool = false

var header_gold: Label
var header_wealth: Label
var header_jobs: Label
var notice: Label
var harlow_view: HarlowController

class HarlowController:
	extends RefCounted
	var owner: Control
	var selected: Array[String] = []
	var stance: String = "Balanced"
	func _init(parent: Control) -> void:
		owner = parent
	func _dispatch() -> void:
		owner._dispatch_harlow()

# These virtual hooks are provided by the book shell and page script.
func _build_shell() -> void:
	pass

func _refresh() -> void:
	pass

# Money Mercs is entirely mouse-driven. Always restore the OS pointer on
# launch and when returning from another window (including the Godot editor).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameSettings.load_settings()
	GameSettings.apply()
	game = MoneyMercsState.new()
	game.harlow_sync()
	var returned: int = game.complete_due()
	harlow_view = HarlowController.new(self)
	selected_crew = harlow_view.selected
	_build_shell()
	_refresh()
	if returned > 0:
		_notify("%d expedition(s) returned while you were away. Their reports await." % returned)
	else:
		_notify("Guild office open. All company records are saved automatically.")
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_clock)
	add_child(timer)

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _nav_to(destination: String) -> void:
	page = destination
	_refresh()

func _notify(message: String) -> void:
	notice.text = message

## Called every second when nothing structural changed; pages update timers in place.
func _live_tick() -> void:
	pass

func _action(result: String) -> void:
	_refresh()
	_notify(result)

func _money(amount: int) -> String:
	var s: String = str(absi(amount))
	var result := ""
	for i in range(s.length()):
		if i > 0 and (s.length() - i) % 3 == 0:
			result += ","
		result += s[i]
	return ("-" if amount < 0 else "") + result + " G"

func _duration(seconds: int) -> String:
	if seconds >= 3600:
		return "%dh %02dm" % [int(seconds / 3600), int(seconds / 60) % 60]
	if seconds >= 60:
		return "%dm %02ds" % [int(seconds / 60), seconds % 60]
	return "%ds" % maxi(0, seconds)

func _selected_available() -> Array[String]:
	var clean: Array[String] = []
	for id in selected_crew:
		var merc: Dictionary = game.merc_by_id(id)
		if not merc.is_empty() and game.is_available(merc):
			clean.append(id)
	return clean

func _toggle_crew(on: bool, id: String) -> void:
	if on and not selected_crew.has(id):
		selected_crew.append(id)
	if not on:
		selected_crew.erase(id)
	harlow_view.selected = selected_crew.duplicate()
	_refresh()

func _set_tactic(new_tactic: String) -> void:
	tactic = new_tactic
	if MoneyMercsState.TACTICS.has(new_tactic):
		harlow_view.stance = new_tactic
	_refresh()

func _scout() -> void:
	_action(game.harlow_send_scout())

func _train_scout() -> void:
	_action(game.harlow_upgrade_scout())

func _dispatch_harlow() -> void:
	var result: String = game.harlow_dispatch(_selected_available(), tactic)
	if result.begins_with("Harlow expedition funded"):
		selected_crew.clear()
		harlow_view.selected.clear()
	_action(result)

func _open_recruitment() -> void:
	roster_tab = "recruits"
	_nav_to("roster")

func _guild_work(worker_id: String) -> void:
	_action(game.start_guild_work(worker_id))

func _set_roster_tab(tab: String) -> void:
	# The Armory and Workshop tabs moved: the Armory is a mercenary's Gear page, the Workshop its own chapter.
	if tab == "armory":
		roster_tab = "employed"
		set("dossier_view", "gear")
	elif tab == "workshop":
		set("workshop_tab", "craft")
		_nav_to("workshop")
		return
	else:
		roster_tab = tab
	_refresh()

func _hire(id: String) -> void:
	var text: String = game.hire(id)
	if text.contains("joined") or text.contains("is yours"):
		roster_tab = "employed"
		selected_merc = id
	_action(text)

## Selling a contract can't be undone: the first press asks, the second sells.
var confirm_sell: String = ""

func _sell_contract(id: String) -> void:
	if confirm_sell != id:
		confirm_sell = id
		_refresh()
		return
	confirm_sell = ""
	_action(game.sell_contract(id))

func _equipped_count(merc: Dictionary) -> int:
	return Gear.worn(merc).size()

func _equipment_name(item: Dictionary) -> String:
	if item.is_empty():
		return "Empty"
	return Gear.full_name(item)

## Open a mercenary's Gear page (the old Armory).
func _outfit(id: String) -> void:
	selected_merc = id
	roster_tab = "employed"
	set("dossier_view", "gear")
	page = "roster"
	_refresh()

func _outfit_slot(id: String, slot: String) -> void:
	set("selected_slot", slot)
	_outfit(id)

func _choose_worker(id: String) -> void:
	selected_merc = id
	_refresh()

func _buy_equipment(key: String) -> void:
	_action(game.buy_equipment(key))

func _equip(id: String, uid: String) -> void:
	_action(game.equip_item(id, uid))

func _sell_equipment(uid: String) -> void:
	_action(game.sell_equipment(uid))

func _repair(uid: String) -> void:
	_action(game.repair(uid))

func _repair_all(id: String) -> void:
	var said: Array[String] = []
	for item in Gear.worn(game.merc_by_id(id)):
		if not game.repair_cost(item).is_empty():
			said.append(game.repair(str(item["uid"])))
	_action("\n".join(said) if not said.is_empty() else "Nothing needs repairs.")

func _supply(id: String, key: String) -> void:
	_action(game.equip_supply(id, key))

func _craft(key: String) -> void:
	_action(game.craft(key))

func _buy_blueprint(key: String) -> void:
	_action(game.buy_blueprint(key))

func _unequip(id: String, slot: String) -> void:
	_action(game.unequip_item(id, slot))

func _terms(id: String) -> void:
	_action(game.switch_contract(id))

func _upgrade_gear(id: String) -> void:
	_action(game.improve_gear(id))

func _heal(id: String) -> void:
	_action(game.treat(id))

func _trade(item: String, buying: bool, count: int) -> void:
	_action(game.trade(item,buying,count))

func _select_item(item: String) -> void:
	selected_item = item
	_refresh()

func _old_dispatch(id: String) -> void:
	selected_region = id
	var team: Array[String] = []
	for merc in game.crew:
		if game.is_available(merc) and team.size() < 2:
			team.append(str(merc["id"]))
	_action(game.dispatch(id, team, "Balanced"))

func _select_region(id: String) -> void:
	selected_region = id
	_refresh()

func _reset() -> void:
	if not _reset_confirm:
		_reset_confirm = true
		_action("Reset armed. Press confirm to permanently reset this test company.")
		return
	game.reset_company()
	selected_crew.clear()
	_reset_confirm = false
	_action("Test company reset.")

func _select_report(index: int) -> void:
	selected_report = index
	_refresh()

func _loot_text(items: Dictionary) -> String:
	var results: Array[String] = []
	for key in items:
		results.append("%d %s" % [int(items[key]), str(MoneyMercsState.RESOURCE_NAMES.get(key,key))])
	return ", ".join(results) if not results.is_empty() else "No resources returned."

func _on_clock() -> void:
	var changed: bool = game.harlow_sync()
	var returned: int = game.complete_due()
	if returned > 0:
		_refresh()
		_notify("%d field team(s) returned. See The Chronicle for full findings." % returned)
	elif changed:
		_refresh()
	else:
		# Only timers and progress bars move; update them without rebuilding the
		# page so open menus, hover states and scroll positions are preserved.
		_live_tick()

