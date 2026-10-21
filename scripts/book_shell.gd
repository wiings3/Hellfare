extends "res://scripts/ledger_ui.gd"
## Active Guildmaster journal: book shell, art, shared drawing primitives and tabs.
## Rebuild around the licensed BookUI sprites already supplied in assets/BookUI.
## No flattened interface image: each page remains live and interactive.

const SOURCE := "res://assets/BookUI/Pocket Inventory Series #7 Gems of Status v1.1/Sprites/"
const DESK := preload("res://assets/BookUI/Pocket Inventory Series #7 Gems of Status v1.1/Sprites/Book Desk/1.png")
const OPEN_BOOK := preload("res://assets/BookUI/Pocket Inventory Series #7 Gems of Status v1.1/Sprites/Inventory Book/Side Tabs/Tabs/Without icons/1.png")
# The pack supplies one open-book image per physical tab, with that tab
# extended as an arrow. These are the actual selected/hover art states.
const SELECTED_TAB_BOOKS := [
	preload("res://assets/BookUI/Pocket Inventory Series #7 Gems of Status v1.1/Sprites/Inventory Book/Side Tabs/Tabs/Without icons/2.png"),
	preload("res://assets/BookUI/Pocket Inventory Series #7 Gems of Status v1.1/Sprites/Inventory Book/Side Tabs/Tabs/Without icons/3.png"),
	preload("res://assets/BookUI/Pocket Inventory Series #7 Gems of Status v1.1/Sprites/Inventory Book/Side Tabs/Tabs/Without icons/4.png"),
	preload("res://assets/BookUI/Pocket Inventory Series #7 Gems of Status v1.1/Sprites/Inventory Book/Side Tabs/Tabs/Without icons/5.png"),
	preload("res://assets/BookUI/Pocket Inventory Series #7 Gems of Status v1.1/Sprites/Inventory Book/Side Tabs/Tabs/Without icons/6.png"),
	preload("res://assets/BookUI/Pocket Inventory Series #7 Gems of Status v1.1/Sprites/Inventory Book/Side Tabs/Tabs/Without icons/7.png")
]
const PHYSICAL_TAB_PAGES := ["hq", "harlow", "roster", "market", "finance", "ledger"]
const BUTTON_NORMAL := preload("res://assets/BookUI/Pocket Inventory Series #7 Gems of Status v1.1/Sprites/Content/5 Buttons/5.png")
const BUTTON_HOVER := preload("res://assets/BookUI/Pocket Inventory Series #7 Gems of Status v1.1/Sprites/Content/5 Buttons/6.png")
const PALETTE_SHADER := preload("res://assets/ui/book_burgundy.gdshader")
const BOOK_REGION := Rect2(80, 200, 710, 465)
# The flip animation is a full-book sprite WITHOUT tabs. Repaint this narrow
# tab-and-edge strip above it so tabs never duck behind the turning parchment.
# 51 source pixels cover both the resting tabs and their extended arrow tips.
const TAB_STRIP_REGION := Rect2(80, 200, 51, 465)
const INK := Color("#45362d")
const INK_SOFT := Color("#624d43")
const INK_LIGHT := Color("#7b6152")
const BLUE := Color("#762c37")
const BLUE_LIGHT := Color("#984251")
const OXBLOOD := Color("#8d3339")
const PALE := Color("#efe2cf")
const SHADE := Color("#805349", 0.13)

var stage: Control
var left_leaf: Control
var right_leaf: Control
var flip_art: TextureRect
var book_art: TextureRect
var tab_overlay: TextureRect
var tab_book_textures: Array[Texture2D] = []
var tab_strip_textures: Array[Texture2D] = []
var title_label: Label
var subheading: Label
var right_heading: Label
var money_label: Label
var worth_label: Label
var missions_label: Label
var notification: Label
var body_font: SystemFont
var heading_font: SystemFont
var current_flip: int = 0
var clear_notice_at: int = 0
var selected_market_item: String = "copper"
var selected_report_index: int = 0
var view_count: int = 0
var tab_host: Control
var palette_material: ShaderMaterial

func _build_shell() -> void:
	stage = Control.new()
	stage.name = "GuildmastersLogbook"
	stage.size = Vector2(1600, 900)
	stage.mouse_filter = Control.MOUSE_FILTER_PASS
	stage.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(stage)
	body_font = SystemFont.new()
	body_font.font_names = PackedStringArray(["Palatino Linotype", "Book Antiqua", "Constantia", "EB Garamond", "Georgia", "Noto Serif", "DejaVu Serif"])
	heading_font = SystemFont.new()
	heading_font.font_names = PackedStringArray(["Goudy Old Style", "Palatino Linotype", "Book Antiqua", "EB Garamond", "Georgia", "Noto Serif", "DejaVu Serif"])
	palette_material = ShaderMaterial.new()
	palette_material.shader = PALETTE_SHADER
	resized.connect(_fit_layout)
	_fit_layout()

	# Fill transparent pixels around the desk with matching walnut instead
	# of exposing the engine's gray clear color.
	var backing := ColorRect.new()
	backing.color = Color("#443e3a")
	backing.position = Vector2.ZERO
	backing.size = Vector2(1600, 900)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(backing)
	# The desk is a legitimate BookUI illustration, not a generated backdrop.
	# The desk is nine-sliced, not cropped or distorted: corners and screws
	# keep their original proportions; only the plain wood planks expand.
	var desk := NinePatchRect.new()
	desk.texture = DESK
	desk.position = Vector2.ZERO
	desk.size = Vector2(1600, 900)
	desk.patch_margin_left = 110
	desk.patch_margin_right = 110
	desk.patch_margin_top = 96
	desk.patch_margin_bottom = 96
	desk.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	desk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(desk)
	# Cropping transparent margins keeps the book itself large and crisp.
	book_art = _book_image(stage, OPEN_BOOK, 144, 30, 1326, 870)
	# Crop the seven sheets identically once; switching never shifts or
	# repaints the underlying parchment and decorative border.
	tab_book_textures.append(book_art.texture)
	tab_strip_textures.append(_tab_strip_texture(OPEN_BOOK))
	for sheet: Texture2D in SELECTED_TAB_BOOKS:
		var cropped := AtlasTexture.new()
		cropped.atlas = sheet
		cropped.region = BOOK_REGION
		tab_book_textures.append(cropped)
		tab_strip_textures.append(_tab_strip_texture(sheet))
	_text(stage, "MONEY MERCS   /   GUILDMASTER'S JOURNAL", 244, 100, 497, 24, 16, true, INK_SOFT)
	title_label = _text(stage, "Company Records", 241, 141, 500, 42, 28, true)
	subheading = _text(stage, "Every coin and every loss accounted for", 241, 179, 500, 24, 16, false, INK_SOFT)
	_label_rule(stage, 241, 208, 498)
	right_heading = _text(stage, "CURRENT ACCOUNTS", 891, 147, 465, 27, 19, true)
	money_label = _text(stage, "", 894, 178, 201, 29, 17, true, BLUE)
	worth_label = _text(stage, "", 1111, 178, 245, 29, 17, true, BLUE)
	missions_label = _text(stage, "", 1095, 111, 260, 23, 14, false, INK_SOFT)
	_label_rule(stage, 890, 208, 464)
	left_leaf = _region(stage, 235, 212, 520, 520)
	right_leaf = _region(stage, 886, 212, 486, 520)
	
	
	notification = _text(stage, "", 295, 22, 1045, 29, 16, false, PALE)
	notification.visible = false
	# Inherited controller integration: keeps legacy actions and CI navigation.
	header_gold = money_label
	header_wealth = worth_label
	header_jobs = missions_label
	notice = notification
	# Six side tabs supplied with the book art. Labels are legible at 720p.
	# Invisible clickable shapes cover each tab and its extended arrow tip.
	tab_host = _region(stage, 151, 182, 84, 515)
	# Page turns use the pack's own animation frames when clicked.
	flip_art = TextureRect.new()
	flip_art.position = Vector2(144, 30)
	flip_art.size = Vector2(1326, 870)
	flip_art.stretch_mode = TextureRect.STRETCH_SCALE
	flip_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flip_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flip_art.visible = false
	flip_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flip_art.material = palette_material
	stage.add_child(flip_art)
	# A duplicate of *only* the tab strip is drawn above the page-turn sprite.
	# The rest of the book remains underneath the page animation.
	tab_overlay = TextureRect.new()
	tab_overlay.name = "PinnedBookTabs"
	tab_overlay.texture = tab_strip_textures[0]
	tab_overlay.position = Vector2(144, 30)
	tab_overlay.size = Vector2(1326.0 * TAB_STRIP_REGION.size.x / BOOK_REGION.size.x, 870)
	tab_overlay.stretch_mode = TextureRect.STRETCH_SCALE
	tab_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tab_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tab_overlay.material = palette_material
	tab_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(tab_overlay)

func _fit_layout() -> void:
	if not is_instance_valid(stage):
		return
	var viewport: Vector2 = get_viewport_rect().size
	var factor: float = minf(viewport.x / 1600.0, viewport.y / 900.0)
	stage.scale = Vector2(factor, factor)
	stage.position = (viewport - Vector2(1600, 900) * factor) * 0.5

func _book_image(parent: Node, full: Texture2D, x: float, y: float, w: float, h: float) -> TextureRect:
	var crop := AtlasTexture.new()
	crop.atlas = full
	crop.region = BOOK_REGION
	var image := TextureRect.new()
	image.texture = crop
	image.position = Vector2(x, y)
	image.size = Vector2(w, h)
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.material = palette_material
	parent.add_child(image)
	return image

func _tab_strip_texture(full: Texture2D) -> AtlasTexture:
	var crop := AtlasTexture.new()
	crop.atlas = full
	crop.region = TAB_STRIP_REGION
	return crop

func _region(parent: Node, x: float, y: float, w: float, h: float) -> Control:
	var box := Control.new()
	box.position = Vector2(x, y)
	box.size = Vector2(w, h)
	box.clip_contents = true
	parent.add_child(box)
	return box

func _text(parent: Node, message: String, x: float, y: float, w: float, h: float,
		size: int = 18, header: bool = false, color: Color = INK,
		wrap_text: bool = false) -> Label:
	var label := Label.new()
	label.position = Vector2(x, y)
	label.size = Vector2(w, h)
	label.text = message
	var font: Font = heading_font if header else body_font
	label.add_theme_font_override("font", font)
	var actual: int = size + 1 if size <= 16 else size
	if wrap_text:
		# A short journal annotation must fit the page vertically, not be clipped mid-sentence.
		while actual > 13 and font.get_multiline_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, w - 14, actual).y > h - 4:
			actual -= 1
	else:
		while actual > 13 and font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, actual).x > w - 12:
			actual -= 1
	label.add_theme_font_size_override("font_size", actual)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap_text else TextServer.AUTOWRAP_OFF
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _label_rule(parent: Node, x: float, y: float, w: float) -> void:
	var line := ColorRect.new()
	line.position = Vector2(x, y)
	line.size = Vector2(w, 2)
	line.color = Color("#997563", 0.45)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)

func _tint(parent: Node, x: float, y: float, w: float, h: float, color: Color = SHADE) -> void:
	var surface := ColorRect.new()
	surface.position = Vector2(x, y)
	surface.size = Vector2(w, h)
	surface.color = color
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(surface)

func _button_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 12
	style.texture_margin_right = 12
	style.texture_margin_top = 9
	style.texture_margin_bottom = 9
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

func _book_button(parent: Node, value: String, x: float, y: float, w: float, h: float,
		action: Callable, enabled: bool = true, secondary: bool = false) -> Button:
	var btn := Button.new()
	btn.text = value
	btn.position = Vector2(x, y)
	btn.size = Vector2(w, h)
	btn.disabled = not enabled
	btn.add_theme_font_override("font", body_font)
	btn.add_theme_font_size_override("font_size", 16 if h >= 38 else 14)
	btn.add_theme_color_override("font_color", PALE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color("#c3a9a0"))
	btn.material = palette_material
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.add_theme_stylebox_override("normal", _button_style(BUTTON_NORMAL))
	btn.add_theme_stylebox_override("hover", _button_style(BUTTON_HOVER))
	btn.add_theme_stylebox_override("pressed", _button_style(BUTTON_HOVER))
	btn.add_theme_stylebox_override("disabled", _button_style(BUTTON_NORMAL))
	btn.add_theme_stylebox_override("focus", _button_style(BUTTON_HOVER))
	if secondary:
		btn.modulate = Color("#b2bec3")
	btn.pressed.connect(action)
	parent.add_child(btn)
	return btn

func _text_button(parent: Node, value: String, x: float, y: float, w: float, h: float,
		action: Callable, active: bool = false) -> Button:
	var btn := Button.new()
	btn.text = value
	btn.position = Vector2(x, y)
	btn.size = Vector2(w, h)
	btn.flat = true
	btn.add_theme_font_override("font", body_font)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", BLUE if active else INK)
	btn.add_theme_color_override("font_hover_color", BLUE_LIGHT)
	btn.add_theme_color_override("font_pressed_color", BLUE)
	btn.add_theme_color_override("font_disabled_color", Color("#866a5e"))
	var transparent := StyleBoxFlat.new()
	transparent.bg_color = Color.TRANSPARENT
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#762c37", 0.13)
	btn.add_theme_stylebox_override("normal", transparent)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.pressed.connect(action)
	parent.add_child(btn)
	return btn

# An icon is selected by switching the book to the corresponding included
# sprite, not by painting a rectangle on top of its tab.
func _show_tab_art(index: int) -> void:
	if not is_instance_valid(book_art) or tab_book_textures.is_empty():
		return
	var frame: int = index + 1
	if frame < 0 or frame >= tab_book_textures.size():
		frame = 0
	book_art.texture = tab_book_textures[frame]
	if is_instance_valid(tab_overlay):
		tab_overlay.texture = tab_strip_textures[frame]

func _active_tab_index() -> int:
	# These secondary pages belong to the Contracts chapter.
	if page == "expeditions" or page == "guildwork":
		return 1
	return PHYSICAL_TAB_PAGES.find(page)

func _restore_tab_art() -> void:
	_show_tab_art(_active_tab_index())

func _preview_tab(index: int) -> void:
	_show_tab_art(index)

func _render_tabs() -> void:
	# The six REAL pixel-art page tabs are the six navigation controls.
	# No duplicate navigation bars or floating labels on the desk.
	var entries: Array = [
		["hq", "Company records", "Company overview, profit and losses"],
		["harlow", "Contracts", "Scout Harlow Mines and fund field work"],
		["roster", "Personnel", "Hire, equip and manage contractors"],
		["market", "Exchange", "Buy and sell the guild's resources"],
		["finance", "Finances", "Review cash and total company value"],
		["ledger", "Chronicle", "Read expedition reports and casualties"]
	]
	for index in range(entries.size()):
		var entry: Array = entries[index]
		var target: String = str(entry[0])
		# The six tabs in the sprite are spaced 48 source pixels apart, or ~90 stage pixels.
		var y: float = float(index) * 90.0
		var click := Button.new()
		click.name = "ChapterTab" + str(index)
		click.text = ""
		click.tooltip_text = "%s\n%s" % [str(entry[1]), str(entry[2])]
		click.position = Vector2(2, y)
		click.size = Vector2(80, 60)
		click.focus_mode = Control.FOCUS_ALL
		click.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		# Every button state is invisible. The sheet artwork IS the button state.
		# A StyleBoxEmpty also prevents Godot from drawing its usual focus outline.
		var invisible := StyleBoxEmpty.new()
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			click.add_theme_stylebox_override(state, invisible)
		click.mouse_entered.connect(_preview_tab.bind(index))
		click.mouse_exited.connect(_restore_tab_art)
		click.focus_entered.connect(_preview_tab.bind(index))
		click.focus_exited.connect(_restore_tab_art)
		click.pressed.connect(_turn_to.bind(target))
		tab_host.add_child(click)

func _turn_to(destination: String) -> void:
	if page == destination:
		return
	var old: String = page
	_nav_to(destination)
	var direction: String = "Page Flip Right" if _tab_index(destination) >= _tab_index(old) else "Page Flip Left"
	_start_page_flip(direction)

func _tab_index(destination: String) -> int:
	var keys: Array = ["hq", "harlow", "expeditions", "roster", "guildwork", "market", "finance", "ledger"]
	return keys.find(destination)

func _start_page_flip(direction: String) -> void:
	current_flip += 1
	var generation: int = current_flip
	var frames: Array[Texture2D] = []
	for i in range(1, 9):
		var tex: Texture2D = load(SOURCE + "Inventory Book/Page Flip/Style 1/" + direction + "/" + str(i) + ".png")
		if tex != null:
			frames.append(tex)
	if frames.is_empty():
		return
	_animate_turn(generation, frames)

func _animate_turn(generation: int, frames: Array[Texture2D]) -> void:
	for picture in frames:
		if generation != current_flip or not is_instance_valid(flip_art):
			return
		var crop := AtlasTexture.new()
		crop.atlas = picture
		crop.region = BOOK_REGION
		flip_art.texture = crop
		flip_art.visible = true
		await get_tree().create_timer(0.037).timeout
	if generation == current_flip:
		flip_art.visible = false

