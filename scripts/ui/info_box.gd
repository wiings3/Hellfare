@tool
extends PanelContainer
## Framed note with a sign icon, used for hints, warnings and empty states.

const SIGNS := {
	"alert": preload("res://assets/ui/kit/sign_alert.png"),
	"coin": preload("res://assets/ui/kit/sign_coin.png"),
	"check": preload("res://assets/ui/kit/sign_check.png"),
	"cross": preload("res://assets/ui/kit/sign_cross.png"),
	"plus": preload("res://assets/ui/kit/sign_plus.png"),
	"home": preload("res://assets/ui/kit/sign_home.png"),
}

@export_multiline var text: String = "Note":
	set(v):
		text = v
		_apply()
@export_enum("alert", "coin", "check", "cross", "plus", "home") var icon_kind: String = "alert":
	set(v):
		icon_kind = v
		_apply()

func _ready() -> void:
	_apply()

func _apply() -> void:
	if not is_node_ready():
		return
	($Row/Text as Label).text = text
	($Row/Sign as TextureRect).texture = SIGNS.get(icon_kind, SIGNS["alert"])
