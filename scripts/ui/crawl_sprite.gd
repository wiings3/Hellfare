extends TextureRect
## One fighter on the crawl screen, animated from the strips in assets/ui/crawl/dusk/
## (<key>_<anim>.png, square cells side by side; tools/import_duskwarden.py writes them).
## Idle loops; attack, skill and hurt play once and fall back to idle; death holds its last frame.

const DIR := "res://assets/ui/crawl/dusk/"
const FPS := {"idle": 6.0, "attack": 12.0, "skill": 12.0, "hurt": 12.0, "death": 8.0}

static var _cache: Dictionary = {}

var key: String = ""
var anim: String = "idle"
var dead: bool = false
var _frames: Array = []
var _t: float = 0.0

## The frames of one animation (empty if the fighter doesn't have it).
static func frames_for(fighter: String, which: String) -> Array:
	var id: String = fighter + "_" + which
	if _cache.has(id):
		return _cache[id]
	var out: Array = []
	var path: String = DIR + id + ".png"
	if ResourceLoader.exists(path):
		var sheet := load(path) as Texture2D
		var h: int = sheet.get_height()
		for i in range(sheet.get_width() / h):
			var frame := AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(i * h, 0, h, h)
			out.append(frame)
	_cache[id] = out
	return out

## Cell size in pixels (64 for most fighters, 128 for the big bosses).
static func cell_of(fighter: String) -> int:
	var f: Array = frames_for(fighter, "idle")
	return int((f[0] as AtlasTexture).region.size.y) if not f.is_empty() else 64

static func has(fighter: String) -> bool:
	return not frames_for(fighter, "idle").is_empty()

## Show this fighter, alive or fallen. Changing either starts the right animation.
func show_fighter(fighter: String, is_dead: bool) -> void:
	if fighter == key and is_dead == dead:
		return
	var was: String = key
	key = fighter
	dead = is_dead
	if dead:
		# Fallen before the screen opened: lie there without replaying the fall.
		play("death")
		if was == "":
			_t = 999.0
	else:
		play("idle")

func play(which: String) -> void:
	if dead and which != "death":
		return
	var f: Array = frames_for(key, which)
	if f.is_empty():
		return
	anim = which
	_frames = f
	_t = 0.0
	texture = f[0]

func _process(delta: float) -> void:
	if _frames.size() < 2:
		return
	_t += delta
	var i: int = int(_t * float(FPS.get(anim, 10.0)))
	if anim == "idle":
		texture = _frames[i % _frames.size()]
	elif i < _frames.size():
		texture = _frames[i]
	elif anim == "death":
		texture = _frames.back()
	else:
		play("idle")
