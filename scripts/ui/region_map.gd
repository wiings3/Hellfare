extends Control
class_name RegionMap
## The Company's living map. Each expedition's real timer moves its crew:
## - the first 20% of the trip they walk the road out,
## - the middle 60% they work at the site (axes at the woods, picks at the mine),
## - the last 20% they walk home carrying the haul.
## Mercenaries with nothing to do wander around town. Roads are the Line2D guides
## under Roads/, named by site id; move their points in the editor to re-route.

const CREW_TOKEN := preload("res://scenes/journal/rows/map_crew.tscn")
const FRAMES := {
	"walk": [preload("res://assets/ui/art/crew/walk_0.png"), preload("res://assets/ui/art/crew/walk_1.png")],
	"carry": [preload("res://assets/ui/art/crew/carry_0.png"), preload("res://assets/ui/art/crew/carry_1.png")],
	"axe": [preload("res://assets/ui/art/crew/axe_0.png"), preload("res://assets/ui/art/crew/axe_1.png")],
	"pick": [preload("res://assets/ui/art/crew/pick_0.png"), preload("res://assets/ui/art/crew/pick_1.png")],
}
const SMOKE := preload("res://assets/ui/art/crew/smoke.png")
const GLINT := [preload("res://assets/ui/art/crew/glint_0.png"), preload("res://assets/ui/art/crew/glint_1.png")]
## Finds are made at work: the glint shows from this point of the trip.
const FOUND_AT := 0.5
## Puffs per chimney, and seconds for one puff to rise and fade.
const PUFFS := 3
const PUFF_LIFE := 4.5
const OUT := 0.2
const BACK := 0.8
## Gap between crew members walking in single file, in map pixels.
const SPACING := 6.0
## Most figures drawn for one crew, and for idle mercenaries in town.
const MAX_PER_CREW := 3
const MAX_IDLE := 4
const TOWN := Vector2(124, 207)
const TOWN_SPREAD := Vector2(17, 6)
const IDLE_SPEED := 5.0

## Calls describe.call(mission) for a token's tooltip.
var describe: Callable
var _roads: Dictionary = {}
var _tokens: Array[Dictionary] = []
var _idlers: Array[Dictionary] = []
var _anim: float = 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	for road in $Roads.get_children():
		var line := road as Line2D
		if line == null or line.points.size() < 2:
			continue
		var curve := Curve2D.new()
		for point in line.points:
			curve.add_point(point)
		_roads[str(line.name)] = curve
	for chimney in $Chimneys.get_children():
		for i in range(PUFFS):
			var puff := Sprite2D.new()
			puff.texture = SMOKE
			chimney.add_child(puff)

## Rebuild the figures from the company's expeditions and free mercenaries.
func show_company(missions: Array, free_mercs: int) -> void:
	for child in $Crews.get_children():
		child.queue_free()
	_tokens.clear()
	_idlers.clear()
	var idle: int = mini(free_mercs, MAX_IDLE)
	for mission in missions:
		var road: String = road_for(mission)
		var count: int = mini(maxi(1, (mission.get("ids", []) as Array).size()), MAX_PER_CREW)
		if road == "":
			idle += 1  # Guild work happens in town.
			continue
		var tool: String = "pick" if road == "harlow" or str(mission.get("trade", "")) == "mining" else "axe"
		var carriers: Array = []
		var ids: Array = mission.get("ids", [])
		for find in mission.get("finds", []):
			carriers.append(clampi(ids.find(str(find.get("finder", ""))), 0, count - 1))
		for i in range(count):
			var token := _add_token()
			token.tooltip_text = describe.call(mission) if describe.is_valid() else ""
			_tokens.append({"node": token, "mission": mission, "index": i, "road": road, "tool": tool, "carrying": carriers.has(i)})
	for i in range(mini(idle, MAX_IDLE)):
		var token := _add_token()
		token.tooltip_text = "Resting in Mossward."
		var spot: Vector2 = _town_spot()
		_idlers.append({"node": token, "pos": spot, "target": spot, "wait": _rng.randf_range(0.0, 3.0)})
	_process(0.0)

## Which road a mission's crew walks, or "" if they stay in town.
static func road_for(mission: Dictionary) -> String:
	match str(mission.get("region", "")):
		"harlow": return "harlow"
		"site": return str(mission.get("site", ""))
	return ""

## Where one crew member stands on the map at `progress` (0..1) of the trip, and what they do.
func place(road: String, progress: float, index: int) -> Dictionary:
	var curve: Curve2D = _roads.get(road)
	if curve == null:
		return {"pos": TOWN, "pose": "walk", "left": false}
	var length: float = curve.get_baked_length()
	if progress < OUT:
		var d: float = clampf(length * progress / OUT - SPACING * index, 0.0, length)
		var ahead: Vector2 = curve.sample_baked(minf(d + 2.0, length))
		var pos: Vector2 = curve.sample_baked(d)
		return {"pos": pos, "pose": "walk", "left": ahead.x < pos.x}
	if progress < BACK:
		var end: Vector2 = curve.sample_baked(length)
		var spot: Vector2 = end + Vector2(-7.0 * index, 3.0 * float(index % 2))
		return {"pos": spot, "pose": "work", "left": false}
	var home: float = clampf(length * (1.0 - (progress - BACK) / (1.0 - BACK)) + SPACING * index, 0.0, length)
	var toward: Vector2 = curve.sample_baked(maxf(home - 2.0, 0.0))
	var at: Vector2 = curve.sample_baked(home)
	return {"pos": at, "pose": "carry", "left": toward.x < at.x}

func _process(delta: float) -> void:
	_anim += delta
	var now: float = _now()
	for token in _tokens:
		var mission: Dictionary = token["mission"]
		var started: float = float(mission.get("started", now))
		var finish: float = float(mission.get("finish", now))
		var progress: float = clampf((now - started) / maxf(1.0, finish - started), 0.0, 1.0)
		var i: int = int(token["index"])
		var spot: Dictionary = place(str(token["road"]), progress, i)
		var node := token["node"] as TextureRect
		node.visible = progress < 1.0
		var glint := node.get_node("Glint") as TextureRect
		glint.visible = bool(token.get("carrying", false)) and progress >= FOUND_AT
		if glint.visible:
			glint.texture = GLINT[int(_anim * 3.0) % 2]
		var pose: String = str(spot["pose"])
		var frames: Array
		var frame: int
		if pose == "work":
			frames = FRAMES[token["tool"]]
			frame = int(_anim * 2.5 + float(i) * 0.6) % 2
		else:
			frames = FRAMES[pose]
			frame = int(_anim * 4.0 + float(i)) % 2
		_draw_token(node, spot["pos"], frames[frame], bool(spot["left"]))
	for idler in _idlers:
		var pos: Vector2 = idler["pos"]
		var target: Vector2 = idler["target"]
		var walking: bool = false
		if float(idler["wait"]) > 0.0:
			idler["wait"] = float(idler["wait"]) - delta
		elif pos.distance_to(target) > 0.5:
			pos = pos.move_toward(target, IDLE_SPEED * delta)
			walking = true
		else:
			idler["target"] = _town_spot()
			idler["wait"] = _rng.randf_range(1.5, 5.0)
		idler["pos"] = pos
		var frame: int = int(_anim * 4.0) % 2 if walking else 0
		_draw_token(idler["node"], pos, FRAMES["walk"][frame], target.x < pos.x)
	_drift_smoke()
	# Figures lower on the map are drawn in front.
	var order: Array = $Crews.get_children()
	order.sort_custom(func(a, b): return float(a.get_meta("feet", 0.0)) < float(b.get_meta("feet", 0.0)))
	for i in range(order.size()):
		if order[i].get_index() != i:
			$Crews.move_child(order[i], i)

## Smoke curls up from the town chimneys, each chimney slightly out of step.
func _drift_smoke() -> void:
	var c: int = 0
	for chimney in $Chimneys.get_children():
		c += 1
		var puffs: Array = chimney.get_children()
		for i in range(puffs.size()):
			var age: float = fposmod(_anim + float(i) * PUFF_LIFE / float(puffs.size()) + float(c) * 1.3, PUFF_LIFE) / PUFF_LIFE
			var puff := puffs[i] as Sprite2D
			puff.position = Vector2(round(sin(age * 5.0 + float(c)) * 1.5 + age * 3.0), round(-age * 10.0))
			puff.modulate.a = 1.0 - age

func _draw_token(node: TextureRect, feet: Vector2, texture: Texture2D, left: bool) -> void:
	node.texture = texture
	node.flip_h = left
	node.position = (feet - Vector2(4, 10)).round()
	node.set_meta("feet", feet.y)

func _add_token() -> TextureRect:
	var token := CREW_TOKEN.instantiate() as TextureRect
	$Crews.add_child(token)
	return token

func _town_spot() -> Vector2:
	return TOWN + Vector2(_rng.randf_range(-1.0, 1.0) * TOWN_SPREAD.x, _rng.randf_range(-1.0, 1.0) * TOWN_SPREAD.y)

## Smooth real time for animation; follows GameClock when a test or the simulator fixes it.
func _now() -> float:
	return float(GameClock.fixed) if GameClock.fixed >= 0 else Time.get_unix_time_from_system()
