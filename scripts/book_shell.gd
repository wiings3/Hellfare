extends "res://scripts/game_actions.gd"
## Active Guildmaster journal: book shell, art, shared drawing primitives and tabs.
## Rebuild around the licensed BookUI sprites already supplied in assets/BookUI.
## No flattened interface image: each page remains live and interactive.


const SOURCE := "res://assets/BookUI/Pocket Inventory Series #7 Gems of Status v1.1/Sprites/"
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
# Tab icons and positions are editor-owned in journal_shell.tscn.
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

func _tab_strip_texture(full: Texture2D) -> AtlasTexture:
	var crop := AtlasTexture.new()
	crop.atlas = full
	crop.region = TAB_STRIP_REGION
	return crop

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
