@tool
extends HBoxContainer
## Row of diamond pips (e.g. scout level 2/3, danger 3/4). value < 0 shows all pips as unknown.

const PIP_ON := preload("res://assets/ui/kit/pip_on.png")
const PIP_OFF := preload("res://assets/ui/kit/pip_off.png")
const PIP_GOLD := preload("res://assets/ui/kit/pip_gold.png")

@export var value: int = 1:
	set(v):
		value = v
		_rebuild()
@export var max_value: int = 3:
	set(v):
		max_value = v
		_rebuild()
@export var gold: bool = false:
	set(v):
		gold = v
		_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	if not is_node_ready():
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for i in range(max_value):
		var pip := TextureRect.new()
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if value < 0:
			pip.texture = PIP_OFF
		elif i < value:
			pip.texture = PIP_GOLD if gold else PIP_ON
		else:
			pip.texture = PIP_OFF
		add_child(pip)
