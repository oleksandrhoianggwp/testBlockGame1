class_name AirportScene
extends Control

signal zone_selected(zone: String)
const ZONES := ["entrance","checkin","baggage","security","cafe","tower","runway"]
const POINTS := [Vector2(.37,.69),Vector2(.35,.50),Vector2(.21,.32),Vector2(.50,.35),Vector2(.78,.53),Vector2(.79,.20),Vector2(.61,.83)]
var views: Dictionary = {}
var profile: Dictionary = {}
var compact: bool = false

func configure(data: Dictionary, small: bool = false) -> void:
	profile = data
	compact = small
	custom_minimum_size.y = 330 if small else (280 if UiKit.text_scale > 1.0 else 320)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	for zone: String in ZONES:
		var node := AirportZoneView.new()
		node.configure(zone,int(data.get("airport",{}).get(zone,0)),not small)
		node.pressed.connect(func(id := zone) -> void: zone_selected.emit(id))
		add_child(node)
		views[zone] = node
	resized.connect(_layout)
	call_deferred("_layout")
	set_process(not UiKit.reduced_motion)

func _layout() -> void:
	for i in ZONES.size():
		var node: AirportZoneView = views[ZONES[i]]
		node.size = Vector2(size.x * (.40 if ZONES[i] == "runway" else .31), size.y * .27)
		node.position = POINTS[i] * size - node.size * .5
		node.z_index = i + 1
	queue_redraw()

func _draw() -> void:
	var ground := PackedVector2Array([size*Vector2(.02,.46),size*Vector2(.63,.07),size*Vector2(.98,.49),size*Vector2(.49,.97)])
	var shadow := PackedVector2Array()
	for p in ground: shadow.append(p+Vector2(0,9))
	draw_colored_polygon(shadow,Color(0.09,0.13,0.24,.12))
	draw_colored_polygon(ground,Color("E8E3D2"))
	for i in range(1,7):
		var offset := float(i)*.08
		draw_line(size*Vector2(.08+offset,.49-offset*.5),size*Vector2(.52+offset,.91-offset*.5),Color(1,.98,.92,.38),1.0,true)
	draw_polyline(PackedVector2Array([size*Vector2(.05,.48),size*Vector2(.49,.94),size*Vector2(.96,.51)]),Color("B7C7BC"),5,true)
	draw_polyline(PackedVector2Array([size*Vector2(.08,.70),size*Vector2(.47,.45),size*Vector2(.87,.68)]),Color("DFD6C2"),22,true)
	draw_polyline(PackedVector2Array([size*Vector2(.08,.70),size*Vector2(.47,.45),size*Vector2(.87,.68)]),UiKit.PAPER,2,true)
	draw_line(size*Vector2(.47,.45),size*Vector2(.77,.25),Color("DFD6C2"),14,true)
	# Small original airplane silhouette at the gate, behind the zone controls.
	var plane_origin := size*Vector2(.79,.83)
	var silhouette := PackedVector2Array([Vector2(-27,4),Vector2(-10,-2),Vector2(-6,-27),Vector2(0,-31),Vector2(5,-2),Vector2(29,8),Vector2(29,13),Vector2(5,9),Vector2(3,26),Vector2(13,31),Vector2(13,35),Vector2(0,31),Vector2(-12,35),Vector2(-12,31),Vector2(-3,26),Vector2(-5,9),Vector2(-27,9)])
	var projected := PackedVector2Array()
	for p in silhouette: projected.append(plane_origin+p.rotated(-.55))
	draw_colored_polygon(projected,UiKit.PAPER)
	draw_polyline(projected,Color("6F8A9C"),1,true)
	draw_line(plane_origin+Vector2(1,16).rotated(-.55),plane_origin+Vector2(0,30).rotated(-.55),UiKit.CORAL,5,true)
	for p in [Vector2(.08,.53),Vector2(.15,.77),Vector2(.86,.74),Vector2(.89,.40)]:
		draw_circle(p*size,10,Color("67AE92"))
		draw_circle(p*size-Vector2(3,4),7,UiKit.MINT)
	var t := float(Time.get_ticks_msec())/1000.0
	var position := size*Vector2(.12 + fmod(t*.012,.25),.68)
	draw_style_box(UiKit.panel(UiKit.GOLD,4),Rect2(position,Vector2(22,12)))
	draw_circle(position+Vector2(5,12),3,UiKit.INK)
	draw_circle(position+Vector2(18,12),3,UiKit.INK)

func _process(_delta: float) -> void:
	queue_redraw()

func reveal(zone: String) -> void:
	var node: AirportZoneView = views[zone]
	node.configure(zone,int(profile["airport"].get(zone,0)),not compact)
	if UiKit.reduced_motion: return
	node.pivot_offset = node.size*.5
	var tween := create_tween()
	tween.tween_property(node,"scale",Vector2.ONE*1.12,.18)
	tween.tween_property(node,"scale",Vector2.ONE,.35).set_trans(Tween.TRANS_BACK)
	for i in 14:
		var particle := ColorRect.new()
		particle.color = UiKit.GOLD if i%2 == 0 else UiKit.MINT
		particle.size = Vector2(6,6)
		particle.position = node.position + node.size*.5
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle.z_index = 30
		add_child(particle)
		var fx := create_tween().set_parallel(true)
		fx.tween_property(particle,"position",particle.position+Vector2(cos(i)*70,sin(i)*60),.55)
		fx.tween_property(particle,"modulate:a",0.0,.55)
		fx.chain().tween_callback(particle.queue_free)
