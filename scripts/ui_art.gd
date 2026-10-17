extends Control
## Procedural illustrations for the management UI; entirely authored in Godot.
## These are intentionally decorative only. Never encode game state in artwork.

var kind: String = "lowlands"
var accent: Color = Color("#be9a60")
var variant: int = 0

const BG := Color("#192321")
const DUSK := Color("#263831")
const FADE := Color("#080f11")
const MIST := Color("#7f978c")
const BRASS := Color("#c7a46b")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 2.0 or h < 2.0:
		return
	if kind == "portrait":
		_draw_portrait(w, h)
		return
	# Artwork uses normalized coordinates so it looks sharp at any size.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(w / 400.0, h / 180.0))
	draw_rect(Rect2(0, 0, 400, 180), BG)
	draw_rect(Rect2(0, 0, 400, 65), Color("#293d3b"))
	draw_polygon(PackedVector2Array([Vector2(0,126), Vector2(80,68), Vector2(132,109), Vector2(220,45), Vector2(310,99), Vector2(400,53), Vector2(400,180), Vector2(0,180)]), PackedColorArray([Color("#354846")]))
	draw_polygon(PackedVector2Array([Vector2(0,153), Vector2(93,111), Vector2(169,137), Vector2(267,81), Vector2(364,127), Vector2(400,106), Vector2(400,180), Vector2(0,180)]), PackedColorArray([Color("#283a37")]))
	draw_circle(Vector2(315, 34), 23, Color("#b9a27c",0.14))
	draw_circle(Vector2(315, 34), 13, Color("#ddc99c",0.27))
	if kind == "lowlands" or kind == "banner":
		_draw_tree(42, 132, 0.92)
		_draw_tree(91, 147, 1.19)
		_draw_tree(155, 142, 0.78)
		_draw_tree(350, 147, 1.14)
		_draw_tree(385, 146, 0.75)
		draw_rect(Rect2(225, 116, 40, 42), Color("#172a25"))
		draw_polygon(PackedVector2Array([Vector2(216,116),Vector2(245,91),Vector2(271,116)]), PackedColorArray([Color("#152a24")]))
		draw_rect(Rect2(235, 130, 11, 28), Color("#56604a"))
	elif kind == "ironworks":
		draw_rect(Rect2(104, 96, 133, 85), Color("#12201e"))
		draw_polygon(PackedVector2Array([Vector2(96,97), Vector2(169,44), Vector2(240,97)]), PackedColorArray([Color("#101e1c")]))
		draw_rect(Rect2(158, 108, 41, 60), Color("#0c1718"))
		for i in 5:
			draw_line(Vector2(112 + i*28, 94), Vector2(112 + i*28, 158), Color("#56645b"), 4)
		draw_line(Vector2(116, 115), Vector2(225, 115), Color("#56645b"), 5)
		draw_circle(Vector2(301, 146), 10, Color("#87bcb5",0.50))
		draw_circle(Vector2(318, 139), 5, Color("#c8e2d3",0.7))
	elif kind == "ashen":
		draw_polygon(PackedVector2Array([Vector2(145,145),Vector2(168,62),Vector2(195,56),Vector2(219,147)]),PackedColorArray([Color("#111d1e")]))
		draw_rect(Rect2(136, 101, 95, 58), Color("#152524"))
		draw_polygon(PackedVector2Array([Vector2(130,102),Vector2(183,78),Vector2(235,102)]),PackedColorArray([Color("#101a19")]))
		for i in 4:
			draw_rect(Rect2(144+i*26, 104, 7, 50), Color("#465753"))
		draw_circle(Vector2(184, 71), 20, Color("#c7a46b",0.14))
		draw_circle(Vector2(184, 71), 7, Color("#ebce91",0.38))
		draw_line(Vector2(0,166),Vector2(400,166), Color("#c09b61",0.15),3)
	# Dim the bottom edge for readable foreground copy.
	draw_polygon(PackedVector2Array([Vector2(0,144),Vector2(400,134),Vector2(400,180),Vector2(0,180)]),PackedColorArray([FADE]))
	draw_rect(Rect2(0,175,400,5), Color("#c7a46b",0.26))
	draw_set_transform(Vector2.ZERO)

func _draw_tree(x: float, y: float, scale_factor: float) -> void:
	var c: Color = Color("#142723")
	var points := PackedVector2Array([
		Vector2(x-20*scale_factor,y), Vector2(x,y-72*scale_factor),
		Vector2(x+20*scale_factor,y)])
	draw_polygon(points, PackedColorArray([c]))
	draw_polygon(PackedVector2Array([
		Vector2(x-15*scale_factor,y-26*scale_factor),Vector2(x,y-92*scale_factor),
		Vector2(x+15*scale_factor,y-26*scale_factor)]),PackedColorArray([Color("#1a3029")]))
	draw_rect(Rect2(x-2*scale_factor,y-7*scale_factor,4*scale_factor,28*scale_factor),Color("#101c1b"))

func _draw_portrait(w: float, h: float) -> void:
	draw_rect(Rect2(0,0,w,h), Color("#26362f"))
	draw_polygon(PackedVector2Array([
		Vector2(0,h),Vector2(w*0.17,h*0.63),Vector2(w*0.5,h*0.52),
		Vector2(w*0.83,h*0.63),Vector2(w,h)]), PackedColorArray([Color("#3e4a43")]))
	var skin := Color("#bd9a75") if variant % 2 == 0 else Color("#97765e")
	draw_circle(Vector2(w*0.5,h*0.40), w*0.21, skin)
	draw_polygon(PackedVector2Array([
		Vector2(w*0.28,h*0.34),Vector2(w*0.35,h*0.14),Vector2(w*0.59,h*0.16),
		Vector2(w*0.71,h*0.35),Vector2(w*0.62,h*0.25),Vector2(w*0.38,h*0.26)]),
		PackedColorArray([Color("#171d1c") if variant % 3 == 0 else Color("#51463a")]))
	draw_line(Vector2(w*0.38,h*0.43),Vector2(w*0.44,h*0.43),Color("#1d2523"),2)
	draw_line(Vector2(w*0.56,h*0.43),Vector2(w*0.62,h*0.43),Color("#1d2523"),2)
	draw_line(Vector2(w*0.45,h*0.56),Vector2(w*0.58,h*0.56),Color("#4c3530"),1.6)
	draw_line(Vector2(w*0.05,h*0.88),Vector2(w*0.95,h*0.88),BRASS.darkened(0.25),2)
