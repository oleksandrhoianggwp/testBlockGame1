class_name TrayView
extends Control
var values: Array[String] = []
var capacity: int = 7
var codes: Dictionary = {}
var colors: Dictionary = {}
var dispatch_destination: String = ""
var dispatch_offset: float = 0.0
var glow: float = 0.0
var combo: int = 0

func _ready() -> void:
	custom_minimum_size.y = 105

func refresh(tray: Array[String], count: int, destination_codes: Dictionary, destination_colors: Dictionary) -> void:
	values = tray.duplicate()
	capacity = count
	codes = destination_codes
	colors = destination_colors
	dispatch_destination = ""
	dispatch_offset = 0
	glow = 0
	queue_redraw()

func _draw() -> void:
	draw_style_box(UiKit.panel(UiKit.NAVY,22,Color("6C8299"),2),Rect2(0,7,size.x,92))
	draw_line(Vector2(13,88),Vector2(size.x-13,88),UiKit.MINT,4,true)
	for x in range(20,int(size.x-12),18):
		draw_line(Vector2(x,91),Vector2(x+5,94),Color("61738E"),2)
	draw_string(ThemeDB.fallback_font,Vector2(0,25),tr("game.tray"),HORIZONTAL_ALIGNMENT_CENTER,size.x,12,UiKit.PAPER)
	var w := (size.x-24)/capacity
	for i in capacity:
		var rect := Rect2(12+i*w,36,w-4,42)
		draw_style_box(UiKit.panel(Color("364B68"),8),rect)
		if i < values.size():
			var dest: String = values[i]
			if dest == dispatch_destination:
				rect.position.x += dispatch_offset
				draw_style_box(UiKit.panel(Color(1,.85,.4,glow),8),rect.grow(3))
			var color := Color(String(colors.get(dest,"75cdb2")))
			draw_style_box(UiKit.panel(color,7),rect.grow(-2))
			draw_style_box(UiKit.panel(UiKit.PAPER,4),Rect2(rect.position+Vector2(3,12),Vector2(rect.size.x-6,23)))
			draw_string(ThemeDB.fallback_font,rect.position+Vector2(2,28),String(codes.get(dest,dest.to_upper())),HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-4,10,UiKit.INK)
	if not dispatch_destination.is_empty():
		draw_string(ThemeDB.fallback_font,Vector2(0,8),tr("game.combo") % combo,HORIZONTAL_ALIGNMENT_CENTER,size.x,14,UiKit.INK)

func target_global_position(index: int) -> Vector2:
	var w := (size.x-24)/capacity
	return global_position+Vector2(12+(clampi(index,0,capacity-1)+.5)*w,55)

func animate_dispatch(destination: String, value: int) -> void:
	dispatch_destination = destination
	combo = value
	glow = .8
	queue_redraw()
	if UiKit.reduced_motion: return
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: glow=v; queue_redraw(),.8,1.0,.12)
	tween.tween_method(func(v: float) -> void: dispatch_offset=v; queue_redraw(),0.0,size.x,.25).set_trans(Tween.TRANS_QUAD)
	await tween.finished
