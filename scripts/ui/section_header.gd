@tool
extends HBoxContainer
## Centred page section title flanked by rules, in the style of the BookUI pack.

@export var text: String = "Section":
	set(value):
		text = value
		if is_node_ready():
			($Title as Label).text = value

func _ready() -> void:
	($Title as Label).text = text
