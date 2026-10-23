extends RefCounted
class_name HallView
## The Trade Hall's pages and windows, bound to TradeHall data. Layout lives in editor
## scenes: pages/hall_left.tscn (chat and message box), pages/hall_right.tscn (inventory
## and conversations), widgets/pm_window.tscn, widgets/trade_window.tscn and the
## NamePopup menu in journal_shell.tscn. This script only fills them in and reacts.
##
## Controls, as in Dark and Darker's first trade chat:
## - Shift+click an item in the inventory (or a link in chat) to link it in your message.
## - Enter or Send posts; a short cooldown stops spam.
## - Click or right-click a name for Message / Block.
## - Hover any item link for its card. During a trade, click inventory items to put them in.

const ROW_CHAT_LINE := preload("res://scenes/journal/rows/chat_line.tscn")
const ROW_SLOT := preload("res://scenes/journal/rows/inventory_slot.tscn")
const ROW_TAB := preload("res://scenes/journal/rows/chat_tab.tscn")
const ROW_TRADE := preload("res://scenes/journal/rows/trade_row.tscn")
const HALL_LEFT := preload("res://scenes/journal/pages/hall_left.tscn")
const HALL_RIGHT := preload("res://scenes/journal/pages/hall_right.tscn")
const ICON_CHAT := preload("res://assets/ui/tab_icons/exchange.png")
const WHISPER := Color("#7d4a6e")
const RARITY := {
	"copper": "Common", "iron": "Common", "timber": "Common", "herbs": "Common",
	"silver": "Uncommon", "crystal": "Rare", "relic": "Very rare", "sovereign": "Legendary",
}

var ui: Control
var composer: LineEdit
var composer_preview: RichTextLabel
var send_button: Button
var composer_text: String = ""
var composer_links: Array = []
var pm_links: Array = []
## Where shift-clicked links go: "chat" or "pm" (whichever box was used last).
var link_target: String = "chat"
var pm_trader: String = ""
var popup_trader: String = ""
var hovered_meta: String = ""
var shown_id: int = 0
var _pm_seen: String = ""
var _trade_seen: String = ""
var _wired: bool = false

func _init(owner: Control) -> void:
	ui = owner

func _game() -> MoneyMercsState:
	return ui.game

func _now() -> int:
	return GameClock.now()

func _pm_window() -> PanelContainer:
	return ui.stage.get_node("PMWindow") as PanelContainer

func _trade_window() -> PanelContainer:
	return ui.stage.get_node("TradeWindow") as PanelContainer

func _popup() -> PopupMenu:
	return ui.stage.get_node("NamePopup") as PopupMenu

## Connect the shell's windows once.
func _wire() -> void:
	if _wired:
		return
	_wired = true
	var pm := _pm_window()
	var b := "Margin/Body/"
	(pm.get_node(b + "TitleBar/Close") as Button).pressed.connect(func() -> void: pm.visible = false)
	(pm.get_node(b + "TitleBar/Trade") as Button).pressed.connect(func() -> void: request_trade(pm_trader))
	var input := pm.get_node(b + "Row/Input") as LineEdit
	input.text_submitted.connect(func(_t: String) -> void: send_pm())
	input.text_changed.connect(func(t: String) -> void: _on_typed(input, pm_links, pm.get_node(b + "Preview") as RichTextLabel, t))
	input.focus_entered.connect(func() -> void: link_target = "pm")
	input.gui_input.connect(_escape_releases.bind(input))
	(pm.get_node(b + "Row/Send") as Button).pressed.connect(send_pm)
	var preview := pm.get_node(b + "Preview") as RichTextLabel
	_wire_links(preview)
	var trade := _trade_window()
	var tb := "Margin/Body/"
	(trade.get_node(tb + "Actions/Lock") as Button).pressed.connect(func() -> void:
		var s: TradeSession = _game().hall.session
		if s != null and s.my_locked:
			_game().trade_unlock()
		else:
			_game().trade_lock()
		_after_trade_edit())
	(trade.get_node(tb + "Actions/Accept") as Button).pressed.connect(func() -> void:
		if not _game().trade_accept():
			ui.notification_text("Both sides must be locked first.")
		_draw_trade(true))
	(trade.get_node(tb + "Actions/Cancel") as Button).pressed.connect(func() -> void:
		_game().trade_cancel()
		_draw_trade(true))
	var gold := trade.get_node(tb + "Mine/Body/Gold/Amount") as LineEdit
	gold.text_submitted.connect(func(t: String) -> void: _set_trade_gold(t))
	gold.focus_exited.connect(func() -> void: _set_trade_gold(gold.text))
	gold.gui_input.connect(_escape_releases.bind(gold))
	(trade.get_node(tb + "Mine/Body/Gold/Less") as Button).pressed.connect(func() -> void: _bump_trade_gold(-10))
	(trade.get_node(tb + "Mine/Body/Gold/More") as Button).pressed.connect(func() -> void: _bump_trade_gold(10))
	_popup().id_pressed.connect(_on_popup)

# --- Clock --------------------------------------------------------------------

func clock() -> void:
	_wire()
	var events: Array = _game().hall_tick()
	for event in events:
		var trader: String = str(event.get("trader", ""))
		match str(event["type"]):
			"pm":
				if not _pm_window().visible:
					open_pm(trader, false)
				elif pm_trader != trader:
					ui.notification_text("%s messaged you." % trader)
			"trade_request":
				ui.notification_text("%s sent a trade request." % trader)
			"trade_done", "trade_failed":
				ui.notification_text(str(event.get("message", "")))
				if ui.page in ["hall", "market", "hq", "finance", "roster"]:
					ui._refresh()
				else:
					ui._update_header()
	_draw_pm(false)
	_draw_trade(false)
	if send_button != null and is_instance_valid(send_button):
		_update_send()

# --- Pages --------------------------------------------------------------------

func draw() -> void:
	_wire()
	var left: Control = ui._mount_page(HALL_LEFT, ui.left_leaf)
	var right: Control = ui._mount_page(HALL_RIGHT, ui.right_leaf)
	var c := "Margin/Content/"
	(left.get_node(c + "Summary/Online") as Label).text = "%d traders online" % TradeHall.TRADERS.size()
	(left.get_node(c + "Summary/Fees") as Label).text = "Trade tax %d%%" % int(round(TradeHall.TAX * 100.0))
	# The chat so far, then new lines as they arrive.
	var scroll := left.get_node(c + "Chat/Scroll") as ScrollContainer
	var lines := left.get_node(c + "Chat/Scroll/Lines") as VBoxContainer
	shown_id = 0
	for m in _game().hall.feed:
		_add_feed_line(lines, m)
	_scroll_to_end(scroll)
	var follow := func() -> void:
		var added: bool = false
		for m in _game().hall.feed:
			if int(m["id"]) > shown_id:
				_add_feed_line(lines, m)
				added = true
		if not added:
			return
		while lines.get_child_count() > TradeHall.FEED_LIMIT:
			var old := lines.get_child(0)
			lines.remove_child(old)
			old.queue_free()
		var bar := scroll.get_v_scroll_bar()
		if scroll.scroll_vertical >= int(bar.max_value - bar.page) - 30:
			_scroll_to_end(scroll)
	ui.live_updaters.append(follow)
	# The message box keeps what was being typed across page redraws.
	composer = left.get_node(c + "Composer/Row/Input") as LineEdit
	composer_preview = left.get_node(c + "Composer/Preview") as RichTextLabel
	send_button = left.get_node(c + "Composer/Row/Send") as Button
	composer.max_length = TradeHall.SAY_MAX
	composer.text = composer_text
	composer.caret_column = composer_text.length()
	composer.text_submitted.connect(func(_t: String) -> void: send_chat())
	composer.text_changed.connect(func(t: String) -> void:
		composer_text = t
		_on_typed(composer, composer_links, composer_preview, t))
	composer.focus_entered.connect(func() -> void: link_target = "chat")
	composer.gui_input.connect(_escape_releases.bind(composer))
	send_button.pressed.connect(send_chat)
	_wire_links(composer_preview)
	_render_preview(composer_preview, composer_text, composer_links)
	_update_send()
	_draw_inventory(right)
	ui._mount_exchange_tabs()

func focus_composer() -> bool:
	if composer == null or not is_instance_valid(composer) or composer.has_focus():
		return false
	composer.grab_focus()
	composer.caret_column = composer.text.length()
	return true

func _draw_inventory(right: Control) -> void:
	var c := "Margin/Content/"
	var game := _game()
	var s: TradeSession = game.hall.session
	var trading: bool = s != null and s.is_open()
	var grid := right.get_node(c + "Goods") as GridContainer
	for key in MoneyMercsState.RESOURCE_ORDER:
		var good: String = str(key)
		var count: int = int(game.resources.get(good, 0))
		var slot := _slot(grid, ui._item_icon(good), str(count) if count > 0 else "", good, "")
		slot.modulate.a = 1.0 if count > 0 else 0.5
		slot.set_pressed_no_signal(trading and s.mine_goods.has(good))
	var gear_grid := right.get_node(c + "GearScroll/Gear") as GridContainer
	for item in game.equipment_inventory:
		var key: String = str(item.get("key", ""))
		var uid: String = str(item.get("uid", ""))
		var slot := _slot(gear_grid, ui._gear_icon(key), "", "gear:" + key, uid)
		slot.set_pressed_no_signal(trading and s.mine_gear.has(uid))
	(right.get_node(c + "GearEmpty") as Control).visible = game.equipment_inventory.is_empty()
	(right.get_node(c + "GearScroll") as Control).visible = not game.equipment_inventory.is_empty()
	# Conversations, newest first.
	var list := right.get_node(c + "Messages/Items") as VBoxContainer
	var names: Array = _conversations()
	for trader in names:
		var lines: Array = game.hall.conversation(trader)
		var last: Dictionary = lines.back() if not lines.is_empty() else {}
		var preview: String = str(last.get("text", ""))
		if str(last.get("from", "")) == "you":
			preview = "You: " + preview
		var unread: int = int(game.hall.unread.get(trader, 0))
		var kind: String = str(TradeHall.KINDS.get(game.hall.trader_kind(trader), {}).get("label", ""))
		ui._list_card(list, ICON_CHAT, trader, preview, kind, "%d new" % unread if unread > 0 else "",
			_pm_window().visible and pm_trader == trader, open_pm.bind(trader, true))
	(right.get_node(c + "MessagesEmpty") as Control).visible = names.is_empty()
	(right.get_node(c + "Messages") as Control).visible = not names.is_empty()
	var blocked: Array = game.hall.blocked
	(right.get_node(c + "Blocked") as Control).visible = not blocked.is_empty()
	(right.get_node(c + "Blocked/Text") as Label).text = "Blocked: " + ", ".join(blocked)
	var unblock := right.get_node(c + "Blocked/Unblock") as Button
	unblock.pressed.connect(func() -> void:
		for name in blocked.duplicate():
			game.hall_block(str(name), false)
		ui._refresh())

func _conversations() -> Array:
	var names: Array = []
	for trader in _game().hall.pms:
		if not (_game().hall.pms[trader] as Array).is_empty():
			names.append(trader)
	names.sort_custom(func(a: String, b: String) -> bool:
		return int((_game().hall.pms[a] as Array).back()["t"]) > int((_game().hall.pms[b] as Array).back()["t"]))
	return names

## One inventory slot: hover for the card, shift+click to link, click to trade.
func _slot(grid: Control, icon: Texture2D, count: String, ref: String, uid: String) -> Button:
	var slot := ROW_SLOT.instantiate() as Button
	grid.add_child(slot)
	(slot.get_node("Icon") as TextureRect).texture = icon
	(slot.get_node("Count") as Label).text = count
	slot.mouse_entered.connect(show_card.bind(ref))
	slot.mouse_exited.connect(hide_card)
	slot.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
			return
		slot.accept_event()
		if click.shift_pressed:
			link_item(ref, uid)
		else:
			_toggle_in_trade(ref, uid))
	return slot

# --- Chat ----------------------------------------------------------------------

func _add_feed_line(lines: VBoxContainer, m: Dictionary) -> void:
	shown_id = maxi(shown_id, int(m["id"]))
	if _game().hall.is_blocked(str(m["from"])):
		return
	_add_line(lines, _feed_bbcode(m))

func _add_line(lines: Container, bbcode: String) -> void:
	var line := ROW_CHAT_LINE.instantiate() as RichTextLabel
	line.text = bbcode
	_wire_links(line)
	lines.add_child(line)

func _wire_links(line: RichTextLabel) -> void:
	line.meta_hover_started.connect(_on_hover)
	line.meta_hover_ended.connect(_on_unhover)
	line.meta_clicked.connect(_on_meta_click)
	line.gui_input.connect(_on_line_input)

func _scroll_to_end(scroll: ScrollContainer) -> void:
	await ui.get_tree().process_frame
	if is_instance_valid(scroll):
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

func _hex(color: Color) -> String:
	return "#" + color.to_html(false)

func _clock(t: int) -> String:
	var bias: int = int(Time.get_time_zone_from_system().get("bias", 0))
	var d: Dictionary = Time.get_time_dict_from_unix_time(t + bias * 60)
	return "%02d:%02d" % [int(d["hour"]), int(d["minute"])]

## Escape BBCode in typed text so a player's brackets show as written.
func _escape(text: String) -> String:
	return text.replace("[", "\u0001").replace("]", "[rb]").replace("\u0001", "[lb]")

## An item link: hover for the card, shift+click to link it yourself.
func _item_link(ref: String, qty: int = -1, uid: String = "") -> String:
	var name: String = _game().item_ref_name(ref)
	var shown: String = "[lb]%s[rb]" % name + ("x%d" % qty if qty > 1 else "")
	return "[url=item|%s|%s][color=%s]%s[/color][/url]" % [ref, uid, _hex(ui.OXBLOOD), shown]

## A trader's name: click or right-click for Message / Block.
func _name_link(name: String, color: Color) -> String:
	return "[url=who|%s][color=%s]%s[/color][/url]" % [name, _hex(color), name]

## Typed text with its [Item] tokens turned into live links.
func _rich_text(text: String, links: Array) -> String:
	var out: String = _escape(text)
	for l in links:
		var token: String = _escape("[%s]" % str(l["name"]))
		var at: int = out.find(token)
		if at >= 0:
			out = out.substr(0, at) + _item_link(str(l["ref"]), -1, str(l.get("uid", ""))) + out.substr(at + token.length())
	return out

func _feed_bbcode(m: Dictionary) -> String:
	var head: String = "[color=%s]%s[/color]  " % [_hex(ui.INK_FAINT), _clock(int(m["t"]))]
	var who: String = str(m["from"])
	match str(m["side"]):
		"say":
			return head + "[color=%s]You:[/color] %s" % [_hex(ui.OXBLOOD), _rich_text(str(m["text"]), m.get("links", []))]
		"system":
			return head + "[color=%s]%s[/color]" % [_hex(ui.INK_SOFT), _escape(str(m["text"]))]
	var ref: String = str(m["good"])
	var gear: bool = ref.begins_with("gear:")
	var link: String = _item_link(ref, int(m["qty"]))
	var price: String = ("%dg" % int(m["price"])) if gear else ("%dg each" % int(m["price"]))
	var body: String
	if str(m["side"]) == "wtb":
		body = "WTB %s paying %s" % [link, price]
	else:
		body = "WTS %s %s%s" % [link, price, " or offer" if bool(m.get("offer", false)) else ""]
	if int(m.get("left", 1)) <= 0:
		var faint: String = _hex(ui.INK_FAINT)
		return head + "[color=%s][s]%s: %s[/s]  sold[/color]" % [faint, who, body.replace(_hex(ui.OXBLOOD), faint)]
	return head + _name_link(who, ui.INK_SOFT) + "[color=%s]:[/color] %s" % [_hex(ui.INK_SOFT), body]

func _on_hover(meta: Variant) -> void:
	hovered_meta = str(meta)
	var parts: PackedStringArray = hovered_meta.split("|")
	if parts[0] == "item" and parts.size() > 1:
		show_card(parts[1])

func _on_unhover(_meta: Variant) -> void:
	hovered_meta = ""
	hide_card()

func _on_meta_click(meta: Variant) -> void:
	var parts: PackedStringArray = str(meta).split("|")
	if parts[0] == "who" and parts.size() > 1:
		_open_popup(parts[1])
	elif parts[0] == "item" and parts.size() > 1 and Input.is_key_pressed(KEY_SHIFT):
		link_item(parts[1], parts[2] if parts.size() > 2 else "")

## Right-click a name for the Message / Block menu.
func _on_line_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_RIGHT:
		return
	var parts: PackedStringArray = hovered_meta.split("|")
	if parts[0] == "who" and parts.size() > 1:
		_open_popup(parts[1])

func _open_popup(trader: String) -> void:
	if trader == "You" or not _game().hall.is_trader(trader):
		return
	hide_card()
	popup_trader = trader
	var popup := _popup()
	popup.set_item_text(2, "Unblock" if _game().hall.is_blocked(trader) else "Block")
	var at: Vector2 = ui.get_viewport().get_mouse_position()
	popup.popup(Rect2i(Vector2i(at) + Vector2i(4, 4), Vector2i.ZERO))

func _on_popup(id: int) -> void:
	var trader: String = popup_trader
	if id == 0:
		open_pm(trader, true)
	elif id == 2:
		request_trade(trader)
	elif id == 1:
		if _game().hall.is_blocked(trader):
			_game().hall_block(trader, false)
			ui.notification_text("Unblocked %s." % trader)
		else:
			_game().hall_block(trader)
			if pm_trader == trader:
				_pm_window().visible = false
			ui.notification_text("Blocked %s. You won't see their posts or messages." % trader)
		if ui.page == "hall":
			ui._refresh()

## What the message box does as the player types: links whose [Name] was deleted go.
func _on_typed(input: LineEdit, links: Array, preview: RichTextLabel, text: String) -> void:
	for l in links.duplicate():
		if text.find("[%s]" % str(l["name"])) < 0:
			links.erase(l)
	_render_preview(preview, text, links)

## A live preview with hoverable links appears above the box once an item is linked.
func _render_preview(preview: RichTextLabel, text: String, links: Array) -> void:
	if preview == null or not is_instance_valid(preview):
		return
	preview.visible = not links.is_empty()
	if not links.is_empty():
		preview.text = "[color=%s]Preview:[/color] %s" % [_hex(ui.INK_FAINT), _rich_text(text, links)]

func _escape_releases(event: InputEvent, input: LineEdit) -> void:
	if event.is_action_pressed("ui_cancel"):
		input.release_focus()
		input.accept_event()

## Put [Item] into the message being written (the chat box, or the open message).
func link_item(ref: String, uid: String = "") -> void:
	var name: String = _game().item_ref_name(ref)
	var to_pm: bool = link_target == "pm" and _pm_window().visible and pm_trader != ""
	var input: LineEdit = (_pm_window().get_node("Margin/Body/Row/Input") as LineEdit) if to_pm else composer
	if input == null or not is_instance_valid(input):
		return
	var links: Array = pm_links if to_pm else composer_links
	var token: String = "[%s]" % name
	var text: String = input.text
	var spacer: String = "" if text == "" or text.ends_with(" ") else " "
	if (text + spacer + token + " ").length() > input.max_length:
		ui.notification_text("That message is full.")
		return
	input.text = text + spacer + token + " "
	links.append({"ref": ref, "name": name, "uid": uid})
	input.grab_focus()
	input.caret_column = input.text.length()
	if to_pm:
		_render_preview(_pm_window().get_node("Margin/Body/Preview") as RichTextLabel, input.text, links)
	else:
		composer_text = input.text
		_render_preview(composer_preview, input.text, links)

func send_chat() -> void:
	if composer == null or not is_instance_valid(composer):
		return
	var problem: String = _game().hall_say(composer.text, composer_links)
	if problem != "":
		ui.notification_text(problem)
		return
	composer_text = ""
	composer_links.clear()
	composer.text = ""
	_render_preview(composer_preview, "", composer_links)
	_update_send()
	composer.grab_focus()

func _update_send() -> void:
	var wait: int = _game().hall.say_wait(_now())
	send_button.disabled = wait > 0
	send_button.text = "Send" if wait <= 0 else "%ds" % wait

# --- Item cards -------------------------------------------------------------------

func hide_card() -> void:
	ui._hide_link_card()

## Fill the floating item card for a good or a piece of gear, beside the mouse.
func show_card(ref: String) -> void:
	var card: PanelContainer = ui._link_card()
	if card == null:
		return
	var game := _game()
	var b := "Margin/Body/"
	var r := b + "Rows/"
	var gear: bool = ref.begins_with("gear:")
	var key: String = ref.substr(5) if gear else ref
	if gear:
		var item: Dictionary = game.item_definition(key)
		if item.is_empty():
			return
		(card.get_node(b + "Head/Slot/Icon") as TextureRect).texture = ui._gear_icon(key)
		(card.get_node(b + "Head/Id/Rarity") as Label).text = "%s  ·  %s" % [str(item.get("slot", "")).capitalize(), str(item.get("role", "Anyone"))]
		var bonus: Array[String] = []
		for stat in ["mining", "logging", "guard", "protection"]:
			if int(item.get(stat, 0)) > 0:
				bonus.append("+%d %s" % [int(item[stat]), stat])
		(card.get_node(b + "Desc") as Label).text = ", ".join(bonus) if not bonus.is_empty() else "Company gear."
		(card.get_node(r + "MerchantBuys") as Label).text = ui._money(maxi(1, int(floor(float(item.get("cost", 0)) * 0.65))))
		(card.get_node(r + "MerchantSells") as Label).text = ui._money(int(item.get("cost", 0)))
		var owned: int = 0
		for owned_item in game.equipment_inventory:
			if str(owned_item.get("key", "")) == key:
				owned += 1
		(card.get_node(r + "Owned") as Label).text = str(owned)
		(card.get_node(r + "OwnedCaption") as Label).text = "In your storeroom"
	else:
		if not MoneyMercsState.BASE_PRICE.has(key):
			return
		(card.get_node(b + "Head/Slot/Icon") as TextureRect).texture = ui._item_icon(key)
		(card.get_node(b + "Head/Id/Rarity") as Label).text = str(RARITY.get(key, "Common"))
		(card.get_node(b + "Desc") as Label).text = str(MoneyMercsState.RESOURCE_DESC.get(key, ""))
		var buyable: bool = key != "relic" and key != "sovereign"
		(card.get_node(r + "MerchantBuys") as Label).text = ui._money(game.sell_price(key))
		(card.get_node(r + "MerchantSells") as Label).text = ui._money(game.buy_price(key)) if buyable else "Never"
		(card.get_node(r + "Owned") as Label).text = str(int(game.resources.get(key, 0)))
		(card.get_node(r + "OwnedCaption") as Label).text = "In your warehouse"
	(card.get_node(b + "Head/Id/Name") as Label).text = game.item_ref_name(ref)
	(card.get_node(r + "Fair") as Label).text = ui._money(int(round(game.hall.fair(ref))))
	var quotes: Dictionary = game.hall.quotes(ref)
	(card.get_node(r + "HallAsk") as Label).text = ui._money(int(quotes["ask"])) if int(quotes["ask"]) > 0 else "-"
	(card.get_node(r + "HallBid") as Label).text = ui._money(int(quotes["bid"])) if int(quotes["bid"]) > 0 else "-"
	(card.get_node(b + "Hint") as Label).text = "Shift+click to link it in a message."
	card.reset_size()
	card.visible = true
	var at: Vector2 = ui.stage.get_local_mouse_position() + Vector2(12, 10)
	var size: Vector2 = card.get_combined_minimum_size()
	at.x = minf(at.x, ui.STAGE_SIZE.x - size.x - 4.0)
	if at.y + size.y > ui.STAGE_SIZE.y - 4.0:
		at.y = at.y - size.y - 20.0
	card.position = at.floor()

# --- Private messages ----------------------------------------------------------------

func open_pm(trader: String, focus: bool = true) -> void:
	_wire()
	var hall: TradeHall = _game().hall
	if hall.is_blocked(trader):
		ui.notification_text("You blocked %s. Unblock them to message." % trader)
		return
	if pm_trader != trader:
		pm_links.clear()
		(_pm_window().get_node("Margin/Body/Row/Input") as LineEdit).text = ""
		_render_preview(_pm_window().get_node("Margin/Body/Preview") as RichTextLabel, "", pm_links)
	pm_trader = trader
	hall.conversation(trader)
	_pm_window().visible = true
	_draw_pm(true)
	if focus:
		var input := _pm_window().get_node("Margin/Body/Row/Input") as LineEdit
		input.grab_focus()
		link_target = "pm"
	if ui.page == "hall":
		ui._refresh()

## Send a trade request; the conversation opens so the answer can be read.
func request_trade(trader: String) -> void:
	var problem: String = _game().hall_request_trade(trader)
	if problem != "":
		ui.notification_text(problem)
		return
	if not _pm_window().visible or pm_trader != trader:
		open_pm(trader, false)
	else:
		_draw_pm(true)

func send_pm() -> void:
	var input := _pm_window().get_node("Margin/Body/Row/Input") as LineEdit
	var problem: String = _game().hall_pm(pm_trader, input.text, pm_links)
	if problem != "":
		ui.notification_text(problem)
		return
	input.text = ""
	pm_links.clear()
	_render_preview(_pm_window().get_node("Margin/Body/Preview") as RichTextLabel, "", pm_links)
	_draw_pm(true)
	input.grab_focus()

## Redraw the message window when its conversation or status changed (or when forced).
func _draw_pm(force: bool) -> void:
	var window := _pm_window()
	if not window.visible or pm_trader == "":
		return
	var hall: TradeHall = _game().hall
	var lines: Array = hall.conversation(pm_trader)
	var status: String = _pm_status()
	var seen: String = "%s|%d|%s|%d" % [pm_trader, lines.size(), status, _conversations().size()]
	if not force and seen == _pm_seen:
		return
	_pm_seen = seen
	hall.unread.erase(pm_trader)
	var b := "Margin/Body/"
	(window.get_node(b + "TitleBar/Title") as Label).text = pm_trader
	(window.get_node(b + "TitleBar/Kind") as Label).text = str(TradeHall.KINDS.get(hall.trader_kind(pm_trader), {}).get("label", ""))
	var tabs := window.get_node(b + "Tabs") as HBoxContainer
	ui._clear(tabs)
	var names: Array = _conversations()
	if not names.has(pm_trader):
		names.push_front(pm_trader)
	for name in names.slice(0, 4):
		var tab := ROW_TAB.instantiate() as Button
		tabs.add_child(tab)
		var unread: int = int(hall.unread.get(name, 0))
		tab.text = str(name) + (" (%d)" % unread if unread > 0 else "")
		tab.set_pressed_no_signal(name == pm_trader)
		tab.pressed.connect(open_pm.bind(str(name), true))
	tabs.visible = names.size() > 1
	var log_lines := window.get_node(b + "Log/Scroll/Lines") as VBoxContainer
	ui._clear(log_lines)
	for line in lines:
		var who: String = str(line["from"])
		var head: String = "[color=%s]%s[/color]  " % [_hex(ui.INK_FAINT), _clock(int(line["t"]))]
		if who == "system":
			_add_line(log_lines, head + "[color=%s]%s[/color]" % [_hex(ui.INK_SOFT), _escape(str(line["text"]))])
			continue
		var name_part: String = "[color=%s]You:[/color]" % _hex(ui.OXBLOOD) if who == "you" else "[color=%s]%s:[/color]" % [_hex(WHISPER), who]
		_add_line(log_lines, head + name_part + " " + _rich_text(str(line["text"]), line.get("links", [])))
	if lines.is_empty():
		_add_line(log_lines, "[color=%s]Say hello, or ask about their post.[/color]" % _hex(ui.INK_FAINT))
	_scroll_to_end(window.get_node(b + "Log/Scroll") as ScrollContainer)
	var status_label := window.get_node(b + "Status") as Label
	status_label.text = status
	status_label.visible = status != ""

func _pm_status() -> String:
	var hall: TradeHall = _game().hall
	if hall.is_typing(pm_trader, _now()):
		return "%s is typing..." % pm_trader
	var h: Haggle = hall.deals.get(pm_trader, null)
	if hall.session != null and hall.session.is_open() and hall.session.trader == pm_trader:
		return "Trade window open."
	if h != null and h.is_agreed():
		var what: String = "%d %s" % [h.agreed_qty, _game().item_ref_name(h.good)] if not h.good.begins_with("gear:") else _game().item_ref_name(h.good)
		return "Agreed: %s for %s. Waiting for their trade request." % [what, ui._money(h.agreed_total)]
	return ""

# --- Trade window -------------------------------------------------------------------

func _toggle_in_trade(ref: String, uid: String) -> void:
	var s: TradeSession = _game().hall.session
	if s == null or not s.is_open():
		show_card(ref)
		return
	if not _game().trade_editable():
		ui.notification_text("Unlock your side to change it.")
		return
	if ref.begins_with("gear:"):
		_game().trade_toggle_gear(uid)
	elif s.mine_goods.has(ref):
		_game().trade_set_goods(ref, 0)
	else:
		var want: int = s.deal.agreed_qty if s.deal.good == ref and not s.deal.they_sell else int(_game().resources.get(ref, 0))
		_game().trade_set_goods(ref, want)
	_draw_trade(true)
	if ui.page == "hall":
		ui._refresh()

func _set_trade_gold(text: String) -> void:
	var s: TradeSession = _game().hall.session
	if s == null or not s.is_open():
		return
	var amount: int = int(text.strip_edges()) if text.strip_edges().is_valid_int() else 0
	if amount != s.mine_gold:
		_game().trade_set_gold(amount)
		_draw_trade(true)

func _bump_trade_gold(delta: int) -> void:
	var s: TradeSession = _game().hall.session
	if s != null and s.is_open():
		_game().trade_set_gold(s.mine_gold + delta)
		_draw_trade(true)

## Redraw the trade window when the session changed (or when forced).
func _draw_trade(force: bool) -> void:
	var window := _trade_window()
	var s: TradeSession = _game().hall.session
	if s == null or not s.is_open():
		window.visible = false
		_trade_seen = ""
		return
	var wait: int = s.accept_wait(_now())
	var seen: String = "%s|%s|%s|%d|%s|%s|%s|%s|%d|%s" % [s.trader, str(s.mine_goods), str(s.mine_gear), s.mine_gold,
		str(s.my_locked), str(s.their_locked), str(s.my_accepted), str(s.their_accepted), wait, str(_game().gold)]
	if not force and seen == _trade_seen and window.visible:
		return
	_trade_seen = seen
	window.visible = true
	var game := _game()
	var b := "Margin/Body/"
	(window.get_node(b + "TitleBar/Title") as Label).text = "Trade with %s" % s.trader
	var h: Haggle = s.deal
	var item: String = "%d %s" % [h.agreed_qty, game.item_ref_name(h.good)] if not h.good.begins_with("gear:") else game.item_ref_name(h.good)
	(window.get_node(b + "Deal") as Label).text = ("Agreed: you pay %s for %s." % [ui._money(h.agreed_total), item]) if h.they_sell else ("Agreed: they pay %s for %s. You keep 97%% after tax." % [ui._money(h.agreed_total), item])
	# Your side.
	var mine := window.get_node(b + "Mine/Body/Items") as VBoxContainer
	ui._clear(mine)
	for good in s.mine_goods:
		var row := _trade_row(mine, ui._item_icon(str(good)), game.item_ref_name(str(good)), int(s.mine_goods[good]), true)
		for pair in [["Less10", -10], ["Less1", -1], ["More1", 1], ["More10", 10]]:
			(row.get_node(str(pair[0])) as Button).pressed.connect(func() -> void:
				game.trade_set_goods(str(good), int(s.mine_goods.get(good, 0)) + int(pair[1]))
				_after_trade_edit())
		(row.get_node("Remove") as Button).pressed.connect(func() -> void:
			game.trade_set_goods(str(good), 0)
			_after_trade_edit())
	var keys: Dictionary = game.storeroom_keys()
	for uid in s.mine_gear:
		var key: String = str(keys.get(uid, ""))
		var row := _trade_row(mine, ui._gear_icon(key), game.item_ref_name("gear:" + key), 1, false)
		(row.get_node("Remove") as Button).visible = true
		(row.get_node("Remove") as Button).pressed.connect(func() -> void:
			game.trade_toggle_gear(str(uid))
			_after_trade_edit())
	(window.get_node(b + "Mine/Body/Empty") as Control).visible = s.mine_goods.is_empty() and s.mine_gear.is_empty() and s.mine_gold <= 0
	var gold := window.get_node(b + "Mine/Body/Gold/Amount") as LineEdit
	if not gold.has_focus():
		gold.text = str(s.mine_gold)
	_lock_label(window.get_node(b + "Mine/Body/Head/Ready") as Label, s.my_locked, s.my_accepted)
	# A locked side can't be edited.
	var editable: bool = not s.my_locked
	for row in mine.get_children():
		for button in ["Less10", "Less1", "More1", "More10", "Remove"]:
			(row.get_node(button) as Button).disabled = not editable
	gold.editable = editable
	(window.get_node(b + "Mine/Body/Gold/Less") as Button).disabled = not editable
	(window.get_node(b + "Mine/Body/Gold/More") as Button).disabled = not editable
	# Their side.
	var theirs := window.get_node(b + "Theirs/Body/Items") as VBoxContainer
	ui._clear(theirs)
	for good in s.their_goods:
		_trade_row(theirs, ui._item_icon(str(good)), game.item_ref_name(str(good)), int(s.their_goods[good]), false)
	for key in s.their_gear:
		_trade_row(theirs, ui._gear_icon(str(key)), game.item_ref_name("gear:" + str(key)), 1, false)
	(window.get_node(b + "Theirs/Body/Empty") as Control).visible = s.their_goods.is_empty() and s.their_gear.is_empty() and s.their_gold <= 0
	(window.get_node(b + "Theirs/Body/Head/Title") as Label).text = "%s gives" % s.trader
	(window.get_node(b + "Theirs/Body/Gold/Amount") as Label).text = ui._money(s.their_gold)
	(window.get_node(b + "Theirs/Body/Gold") as Control).visible = s.their_gold > 0
	_lock_label(window.get_node(b + "Theirs/Body/Head/Ready") as Label, s.their_locked, s.their_accepted)
	var lock := window.get_node(b + "Actions/Lock") as Button
	lock.text = "Unlock" if s.my_locked else "Lock offer"
	lock.disabled = s.my_accepted
	var accept := window.get_node(b + "Actions/Accept") as Button
	if s.my_accepted:
		accept.text = "Accepted"
	elif wait > 0:
		accept.text = "Accept (%d)" % wait
	else:
		accept.text = "Accept"
	accept.disabled = s.my_accepted or wait != 0

func _after_trade_edit() -> void:
	_draw_trade(true)
	if ui.page == "hall":
		ui._refresh()

func _trade_row(list: VBoxContainer, icon: Texture2D, name: String, qty: int, editable: bool) -> Control:
	var row := ROW_TRADE.instantiate() as Control
	list.add_child(row)
	(row.get_node("Slot/Icon") as TextureRect).texture = icon
	(row.get_node("Name") as Label).text = name
	(row.get_node("Qty") as Label).text = "x%d" % qty
	for button in ["Less10", "Less1", "More1", "More10", "Remove"]:
		(row.get_node(button) as Control).visible = editable
	return row

func _lock_label(label: Label, locked: bool, accepted: bool) -> void:
	label.text = "Accepted" if accepted else ("Locked" if locked else "Not locked")
	label.theme_type_variation = &"LabelGood" if accepted else (&"LabelAccent" if locked else &"LabelMuted")
