extends "res://scripts/game_actions.gd"
## Active Guildmaster journal: book shell, art, shared drawing primitives and tabs.
## Rebuild around the licensed BookUI sprites already supplied in assets/BookUI.
## No flattened interface image: each page remains live and interactive.

const JOURNAL_LABEL := preload("res://scenes/journal/widgets/journal_label.tscn")
const JOURNAL_RULE := preload("res://scenes/journal/widgets/journal_rule.tscn")
const JOURNAL_TINT := preload("res://scenes/journal/widgets/journal_tint.tscn")
const JOURNAL_BUTTON := preload("res://scenes/journal/widgets/journal_button.tscn")
const JOURNAL_TEXT_BUTTON := preload("res://scenes/journal/widgets/journal_text_button.tscn")

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
# Six hand-pixeled native 24x24 icons. No AI-image downsampling or smearing.
# Expeditions uses a compass for logging, foraging, dungeon runs, etc.
const CHAPTER_TAB_ICONS := [
	preload("res://assets/ui/tab_icons/company.png"),
	preload("res://assets/ui/tab_icons/expeditions.png"),
	preload("res://assets/ui/tab_icons/personnel.png"),
	preload("res://assets/ui/tab_icons/exchange.png"),
	preload("res://assets/ui/tab_icons/finances.png"),
	preload("res://assets/ui/tab_icons/chronicle.png")
]
# Center on the rectangular body of each tab, NOT its extended arrow tip.
# Measured against the BookUI sprite and the in-game tab screenshot.
const TAB_ICON_FIRST_CENTER := Vector2(179, 209)
const TAB_ICON_STEP_Y := 90.0
const TAB_ICON_DRAW_SIZE := Vector2(40, 40)
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
var tab_icons_layer: Control
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

# The entire fixed journal layout now lives in an editable PackedScene:
# res://scenes/journal/journal_shell.tscn. The script only binds live data
# and wires actions to the pre-existing editor nodes.
func _build_shell() -> void:
	stage = get_node("GuildmastersLogbook") as Control
	book_art = stage.get_node("Book") as TextureRect
	title_label = stage.get_node("Title") as Label
	subheading = stage.get_node("Subtitle") as Label
	right_heading = stage.get_node("RightHeading") as Label
	money_label = stage.get_node("Gold") as Label
	worth_label = stage.get_node("Worth") as Label
	missions_label = stage.get_node("Jobs") as Label
	notification = stage.get_node("Notice") as Label
	left_leaf = stage.get_node("LeftLeaf") as Control
	right_leaf = stage.get_node("RightLeaf") as Control
	tab_host = stage.get_node("ChapterTabHost") as Control
	flip_art = stage.get_node("PageFlip") as TextureRect
	tab_overlay = stage.get_node("PinnedBookTabs") as TextureRect
	tab_icons_layer = stage.get_node("ChapterIcons") as Control
	palette_material = book_art.material as ShaderMaterial
	body_font = subheading.get_theme_font("font") as SystemFont
	heading_font = title_label.get_theme_font("font") as SystemFont
	header_gold = money_label
	header_wealth = worth_label
	header_jobs = missions_label
	notice = notification
	tab_book_textures.clear()
	tab_strip_textures.clear()
	tab_book_textures.append(book_art.texture)
	tab_strip_textures.append(tab_overlay.texture)
	for sheet: Texture2D in SELECTED_TAB_BOOKS:
		var cropped := AtlasTexture.new()
		cropped.atlas = sheet
		cropped.region = BOOK_REGION
		tab_book_textures.append(cropped)
		tab_strip_textures.append(_tab_strip_texture(sheet))
	_render_tabs()
	resized.connect(_fit_layout)
	_fit_layout()

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
	var label := JOURNAL_LABEL.instantiate() as Label
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
	var line := JOURNAL_RULE.instantiate() as ColorRect
	line.position = Vector2(x, y)
	line.size = Vector2(w, 2)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)

func _tint(parent: Node, x: float, y: float, w: float, h: float, color: Color = SHADE) -> void:
	var surface := JOURNAL_TINT.instantiate() as ColorRect
	surface.position = Vector2(x, y)
	surface.size = Vector2(w, h)
	surface.color = color
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(surface)

func _book_button(parent: Node, value: String, x: float, y: float, w: float, h: float,
		action: Callable, enabled: bool = true, secondary: bool = false) -> Button:
	var btn := JOURNAL_BUTTON.instantiate() as Button
	btn.text = value
	btn.position = Vector2(x, y)
	btn.size = Vector2(w, h)
	btn.disabled = not enabled
	btn.add_theme_font_override("font", body_font)
	btn.add_theme_font_size_override("font_size", 16 if h >= 38 else 14)
	btn.material = palette_material
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if secondary:
		btn.modulate = Color("#b2bec3")
	btn.pressed.connect(action)
	parent.add_child(btn)
	return btn

func _text_button(parent: Node, value: String, x: float, y: float, w: float, h: float,
		action: Callable, active: bool = false) -> Button:
	var btn := JOURNAL_TEXT_BUTTON.instantiate() as Button
	btn.text = value
	btn.position = Vector2(x, y)
	btn.size = Vector2(w, h)
	btn.flat = true
	btn.add_theme_font_override("font", body_font)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", BLUE if active else INK)
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

# Connect the six real Button nodes supplied by journal_shell.tscn.
# Their art, exact positions, hitboxes and focus styles are editor-owned.
func _render_tabs() -> void:
	for index in range(PHYSICAL_TAB_PAGES.size()):
		var click := tab_host.get_node("ChapterTab" + str(index)) as Button
		click.mouse_entered.connect(_preview_tab.bind(index))
		click.mouse_exited.connect(_restore_tab_art)
		click.focus_entered.connect(_preview_tab.bind(index))
		click.focus_exited.connect(_restore_tab_art)
		click.pressed.connect(_turn_to.bind(str(PHYSICAL_TAB_PAGES[index])))

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
