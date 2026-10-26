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

# Hellfare is entirely mouse-driven. Always restore the OS pointer on
# launch and when returning from another window (including the Godot editor).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameSettings.load_settings()
	GameSettings.apply()
	Sound.refresh()
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
		_notify("The guild hall is open. Records are saved automatically.")
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

## Floors fought so far across the crypt runs under way (a new one means a fight just ended).
func _floors_logged() -> int:
	var n: int = 0
	for m in game.missions:
		n += (m.get("log", []) as Array).size()
	return n

## One alert for crews coming back: the worst news wins (a lost crew, a death, a haul).
func _play_return_alert(returned: int) -> void:
	var wiped: bool = false
	var died: bool = false
	var boss: bool = false
	for i in range(mini(returned, game.reports.size())):
		var r: Dictionary = game.reports[i]
		wiped = wiped or str(r.get("outcome", "")) == "wiped"
		died = died or not (r.get("casualties", []) as Array).is_empty()
		boss = boss or str(r.get("outcome", "")) == "cleared"
	if wiped:
		Sound.play("crew_wiped")
	elif died:
		Sound.play("death")
	else:
		Sound.play("crew_back")
		if boss:
			Sound.play("boss_down")
	# Smaller news from the same reports, a moment later.
	var extra: String = ""
	for i in range(mini(returned, game.reports.size())):
		var r: Dictionary = game.reports[i]
		for e in r.get("events", []):
			if str(e).contains(" reached "):
				extra = "level_up"
		for f in r.get("found_items", []):
			if str(f).begins_with("Blueprint") and extra == "":
				extra = "blueprint"
		if not (r.get("found_gear", []) as Array).is_empty() and extra == "":
			extra = "find_gear"
	if extra != "":
		get_tree().create_timer(1.2).timeout.connect(func() -> void: Sound.play(extra))

func _hire(id: String) -> void:
	var text: String = game.hire(id)
	if text.contains("joined") or text.contains("is yours"):
		roster_tab = "employed"
		selected_merc = id
		Sound.play("hire")
	_action(text)

## A fingerprint of what the player owns, to tell whether an action did anything.
func _state_mark() -> int:
	return hash(var_to_str([game.gold, game.resources, game.crew, game.missions.size(), game.equipment_inventory,
		game.blueprints, game.upgrades]))

## Run an action and play `sound` if it changed anything.
func _act(call: Callable, sound: String) -> void:
	var before: int = _state_mark()
	var result: String = str(call.call())
	if _state_mark() != before:
		Sound.play(sound)
	_action(result)

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
	_act(func() -> String: return game.equip_item(id, uid), "equip")

func _sell_equipment(uid: String) -> void:
	_action(game.sell_equipment(uid))

func _repair(uid: String) -> void:
	_act(func() -> String: return game.repair(uid), "repair")

func _repair_all(id: String) -> void:
	var said: Array[String] = []
	for item in Gear.worn(game.merc_by_id(id)):
		if not game.repair_cost(item).is_empty():
			said.append(game.repair(str(item["uid"])))
	if not said.is_empty():
		Sound.play("repair")
	_action("\n".join(said) if not said.is_empty() else "Nothing needs repairs.")

func _supply(id: String, key: String) -> void:
	_act(func() -> String: return game.equip_supply(id, key), "equip")

func _craft(key: String) -> void:
	var kind: String = str(Catalog.item(key).get("category", ""))
	_act(func() -> String: return game.craft(key), "cook" if kind in ["food", "potion"] else "craft")

func _buy_blueprint(key: String) -> void:
	_action(game.buy_blueprint(key))

func _unequip(id: String, slot: String) -> void:
	_act(func() -> String: return game.unequip_item(id, slot), "equip")

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
		_action("Reset armed. Press confirm to permanently reset this test guild.")
		return
	game.reset_company()
	selected_crew.clear()
	_reset_confirm = false
	_action("Test guild reset.")

func _select_report(index: int) -> void:
	selected_report = index
	_refresh()

func _loot_text(items: Dictionary) -> String:
	var results: Array[String] = []
	for key in items:
		results.append("%d %s" % [int(items[key]), str(MoneyMercsState.RESOURCE_NAMES.get(key,key))])
	return ", ".join(results) if not results.is_empty() else "No resources returned."

## How many dungeon events have been decided, to redraw a run as the crew decides them.
func _dungeon_calls() -> int:
	var n: int = 0
	for m in game.missions:
		n += (m.get("ev_log", []) as Array).size()
	return n

## What the dungeon runs look like, to notice a floor resolving or a crew reaching the stairs.
func _delving_state() -> String:
	var parts: Array[String] = []
	for m in game.missions:
		if str(m.get("region", "")) == "dungeon":
			parts.append("%s:%s:%d" % [str(m["id"]), str(m.get("stage", "")), int(m.get("floor_i", 0))])
	return ",".join(parts)

func _on_clock() -> void:
	var changed: bool = game.harlow_sync()
	var before: String = _delving_state()
	var waiting: int = game.dungeon_checkins().size()
	var calls: int = _dungeon_calls()
	var last_sale: Dictionary = game.auction.log[0] if not game.auction.log.is_empty() else {}
	var floors_before: int = _floors_logged()
	var returned: int = game.complete_due()
	if not game.auction.log.is_empty() and game.auction.log[0] != last_sale:
		var e: Dictionary = game.auction.log[0]
		Sound.play("sale")
		if str(e["kind"]) == "sold":
			_notify("Auction House: sold %s%s for %s." % ["%d " % int(e["qty"]) if not str(e["ref"]).begins_with("gear:") else "", game.item_ref_name(str(e["ref"])), _money(int(e["gold"]))])
		elif str(e["kind"]) == "bought":
			_notify("Auction House: your order bought %d %s." % [int(e["qty"]), game.item_ref_name(str(e["ref"]))])
		if page in ["auction", "hq"]:
			changed = true
	if _dungeon_calls() != calls and page == "dungeon":
		changed = true
	if _delving_state() != before:
		changed = true
		if game.dungeon_checkins().size() > waiting:
			var m: Dictionary = game.dungeon_checkins().back()
			Sound.play("crew_waiting")
			_notify("%s: floor %d cleared. Your crew is waiting for orders." % [str(Dungeons.by_id(str(m["dungeon"])).get("name", "The crypt")), int(m["floor_i"]) + 1])
	if returned == 0 and _floors_logged() > floors_before and page == "dungeon" and game.dungeon_checkins().size() <= waiting:
		Sound.play("floor_cleared")
	if returned > 0:
		_play_return_alert(returned)
		_refresh()
		_notify("%s back up. Their reports are in the Ledger." % ("A crew is" if returned == 1 else "%d crews are" % returned))
	elif changed:
		_refresh()
	else:
		# Only timers and progress bars move; update them without rebuilding the
		# page so open menus, hover states and scroll positions are preserved.
		_live_tick()

