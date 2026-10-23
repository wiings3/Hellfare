extends PanelContainer
## A small window over the journal that can be dragged by its title bar and stays on the
## desk. Used by the private-message and trade windows (scenes/journal/widgets/).

@export var drag_bar: NodePath = ^"Margin/Body/TitleBar"

var _dragging: bool = false
var _grab: Vector2 = Vector2.ZERO

func _ready() -> void:
	var bar := get_node_or_null(drag_bar) as Control
	if bar != null:
		bar.gui_input.connect(_on_bar_input)

func _on_bar_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		_dragging = button.pressed
		_grab = _parent_mouse() - position
		return
	if event is InputEventMouseMotion and _dragging:
		move_to(_parent_mouse() - _grab)

## Place the window, kept fully inside its parent (the 960x540 stage).
func move_to(at: Vector2) -> void:
	var parent := get_parent() as Control
	var bounds: Vector2 = parent.size if parent != null else Vector2(960, 540)
	position = Vector2(clampf(at.x, 0.0, maxf(0.0, bounds.x - size.x)), clampf(at.y, 0.0, maxf(0.0, bounds.y - size.y))).round()

func _parent_mouse() -> Vector2:
	var parent := get_parent() as Control
	return parent.get_local_mouse_position() if parent != null else get_global_mouse_position()
