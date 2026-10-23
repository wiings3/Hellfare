@tool
extends PanelContainer
## Small framed statistic: icon, caption and a large value.

@export var caption: String = "Caption":
	set(v):
		caption = v
		_apply()
@export var value: String = "0":
	set(v):
		value = v
		_apply()
@export var icon: Texture2D:
	set(v):
		icon = v
		_apply()
## "", "accent" (oxblood) or "good" (green) value colour.
@export_enum("normal", "accent", "good") var tone: String = "normal":
	set(v):
		tone = v
		_apply()

func _ready() -> void:
	_apply()

func _apply() -> void:
	if not is_node_ready():
		return
	($Row/Text/Caption as Label).text = caption
	var value_label := $Row/Text/Value as Label
	value_label.text = value
	match tone:
		"accent": value_label.theme_type_variation = &"LabelBigAccent"
		"good": value_label.theme_type_variation = &"LabelBig"
		_: value_label.theme_type_variation = &"LabelBig"
	if tone == "good":
		value_label.add_theme_color_override("font_color", Color("#4a6a37"))
	else:
		value_label.remove_theme_color_override("font_color")
	var icon_rect := $Row/Icon as TextureRect
	icon_rect.texture = icon
	icon_rect.visible = icon != null
