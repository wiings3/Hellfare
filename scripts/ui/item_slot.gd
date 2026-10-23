@tool
extends PanelContainer
## Inventory-style slot showing an item icon and an optional count.

@export var icon: Texture2D:
	set(v):
		icon = v
		_apply()
## Count shown in the corner. -1 hides it; -2 shows "?" (unknown).
@export var count: int = -1:
	set(v):
		count = v
		_apply()
## Draw the slot as empty/faded (e.g. none in stock).
@export var dim: bool = false:
	set(v):
		dim = v
		_apply()

func _ready() -> void:
	_apply()

func _apply() -> void:
	if not is_node_ready():
		return
	var pic := $Icon as TextureRect
	pic.texture = icon
	pic.modulate = Color(1, 1, 1, 0.35) if dim else Color.WHITE
	theme_type_variation = &"EmptySlot" if dim else &"SlotPanel"
	var label := $Count as Label
	label.visible = count != -1
	label.text = "?" if count == -2 else str(count)
