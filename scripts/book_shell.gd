extends "res://scripts/game_actions.gd"
## Active Guildmaster journal: book shell, tabs, page turns and the desk header.
## Layout lives in scenes/journal/journal_shell.tscn (960x540 stage, book at 1:1 art pixels).
## The BookUI sheets are pre-recoloured to oxblood in assets/ui/book/ (see tools/make_kit.py),
## so no runtime palette shader is needed and the parchment keeps its true colour.

const TAB_SHEETS := "res://assets/ui/book/tabs/"
const FLIP_FRAMES := "res://assets/ui/book/flip/"
const FLIP_FRAME_COUNT := 9
const PHYSICAL_TAB_PAGES := ["hq", "expeditions", "roster", "market", "finance", "ledger"]
# The tab strip region of a book sheet, repainted above page-turn frames so the
# chapter tabs never duck behind the turning parchment.
const TAB_STRIP_REGION := Rect2(84, 276, 44, 286)
const STAGE_SIZE := Vector2(960, 540)

# Ink palette shared by page scripts (matches assets/ui/theme/money_mercs.tres).
const INK := Color("#3d2824")
const INK_SOFT := Color("#7a584a")
const INK_FAINT := Color("#b08d75")
const OXBLOOD := Color("#802c38")
const GOOD := Color("#4a6a37")
const PAPER_LIGHT := Color("#eedcc7")
# Legacy names kept for older page code.
const BLUE := OXBLOOD
const BLUE_LIGHT := Color("#b04a52")
const PALE := PAPER_LIGHT

var stage: Control
var left_leaf: Control
var right_leaf: Control
var flip_art: TextureRect
var book_art: TextureRect
var tab_overlay: TextureRect
var tab_icons_layer: Control
var tab_book_textures: Array[Texture2D] = []
var tab_strip_textures: Array[Texture2D] = []
var flip_textures: Dictionary = {}
var title_label: Label
var money_label: Label
var worth_label: Label
var missions_label: Label
var toast: PanelContainer
var toast_label: Label
var current_flip: int = 0
var clear_notice_at: int = 0
var selected_market_item: String = "copper"
var selected_report_index: int = 0
var tab_host: Control

func _build_shell() -> void:
	stage = get_node("GuildmastersLogbook") as Control
	book_art = stage.get_node("Book") as TextureRect
	title_label = stage.get_node("Header/Title") as Label
	money_label = stage.get_node("Header/Purse/Row/Text/Gold") as Label
	worth_label = stage.get_node("Header/Purse/Row/Text/Worth") as Label
	missions_label = stage.get_node("Header/Field/Row/Text/Jobs") as Label
	toast = stage.get_node("Toast") as PanelContainer
	toast_label = stage.get_node("Toast/Message") as Label
	left_leaf = stage.get_node("LeftLeaf") as Control
	right_leaf = stage.get_node("RightLeaf") as Control
	tab_host = stage.get_node("ChapterTabHost") as Control
	flip_art = stage.get_node("PageFlip") as TextureRect
	tab_overlay = stage.get_node("PinnedBookTabs") as TextureRect
	tab_icons_layer = stage.get_node("ChapterIcons") as Control
	header_gold = money_label
	header_wealth = worth_label
	header_jobs = missions_label
	notice = toast_label
	tab_book_textures.clear()
	tab_strip_textures.clear()
	# Sheet 1 has no extended tab; sheets 2..7 extend tab 0..5.
	for i in range(1, 8):
		var sheet: Texture2D = load(TAB_SHEETS + str(i) + ".png")
		tab_book_textures.append(sheet)
		var strip := AtlasTexture.new()
		strip.atlas = sheet
		strip.region = TAB_STRIP_REGION
		tab_strip_textures.append(strip)
	for direction in ["page_flip_left", "page_flip_right"]:
		var frames: Array[Texture2D] = []
		for i in range(1, FLIP_FRAME_COUNT + 1):
			var tex: Texture2D = load(FLIP_FRAMES + direction + "/" + str(i) + ".png")
			if tex != null:
				frames.append(tex)
		flip_textures[direction] = frames
	_render_tabs()
	resized.connect(_fit_layout)
	_fit_layout()

## Centre the 960x540 stage. With the project's 960x540 base resolution and
## "expand" aspect, the stage is always drawn at 1:1 stage units; wider or taller
## windows only reveal more desk around it.
func _fit_layout() -> void:
	if not is_instance_valid(stage):
		return
	var viewport: Vector2 = get_viewport_rect().size
	var factor: float = minf(viewport.x / STAGE_SIZE.x, viewport.y / STAGE_SIZE.y)
	if factor >= 1.0:
		factor = floorf(factor)
	stage.scale = Vector2(factor, factor)
	stage.position = ((viewport - STAGE_SIZE * factor) * 0.5).floor()

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
	# These secondary pages belong to the Expeditions chapter.
	if page in ["harlow", "site", "contracts", "guildwork"]:
		return 1
	return PHYSICAL_TAB_PAGES.find(page)

func _restore_tab_art() -> void:
	_show_tab_art(_active_tab_index())

func _preview_tab(index: int) -> void:
	_show_tab_art(index)

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
	var direction: String = "page_flip_right" if _tab_index(destination) >= _tab_index(old) else "page_flip_left"
	_start_page_flip(direction)

func _tab_index(destination: String) -> int:
	var keys: Array = ["hq", "expeditions", "site", "harlow", "contracts", "guildwork", "roster", "market", "finance", "ledger"]
	return keys.find(destination)

func _start_page_flip(direction: String) -> void:
	current_flip += 1
	var frames: Array = flip_textures.get(direction, [])
	if frames.is_empty():
		return
	_animate_turn(current_flip, frames)

func _animate_turn(generation: int, frames: Array) -> void:
	for picture in frames:
		if generation != current_flip or not is_instance_valid(flip_art):
			return
		flip_art.texture = picture
		flip_art.visible = true
		await get_tree().create_timer(0.035).timeout
	if generation == current_flip:
		flip_art.visible = false
