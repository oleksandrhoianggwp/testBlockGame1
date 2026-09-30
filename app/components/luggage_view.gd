class_name LuggageView
extends Button
const SHAPES := ["hard_shell","cabin","duffel","backpack","oversized","travel_case"]
static var textures: Dictionary = {}
var item_id: String = ""
var destination_code: String = ""
var secondary_code: String = ""
var suitcase_color: Color = UiKit.CORAL
var special_type: String = ""
var variant: int = 0
var selectable: bool = false
var revealed: bool = true
var locked: bool = false
var initialized: bool = false

func _ready() -> void:
	flat = true
	text = ""
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(96,88)
	for key in ["normal","hover","pressed","disabled","focus"]:
		add_theme_stylebox_override(key,StyleBoxEmpty.new())

func configure(item: Dictionary, can_select: bool, codes: Dictionary, colors: Dictionary) -> void:
	var becoming_available := initialized and not selectable and can_select
	item_id = String(item.get("id",""))
	special_type = String(item.get("special_type",""))
	var destination := String(item.get("destination_id",""))
	destination_code = String(codes.get(destination,destination.to_upper()))
	secondary_code = ""
	if special_type == "transfer":
		var options: Array = item.get("destination_options",[])
		if options.size() > 1:
			destination_code = String(codes.get(String(options[0]),String(options[0]).to_upper()))
			secondary_code = String(codes.get(String(options[1]),String(options[1]).to_upper()))
	suitcase_color = Color(String(colors.get(destination,"f7c75a")))
	variant = abs(item_id.hash())%6
	if not textures.has(variant):
		textures[variant] = load("res://assets/art/luggage/%s.svg" % SHAPES[variant])
	selectable = can_select
	revealed = bool(item.get("revealed",true))
	locked = not String(item.get("lock_group","")).is_empty()
	disabled = not can_select
	modulate = Color.WHITE if can_select else Color(.83,.85,.89,1)
	initialized = true
	if becoming_available and not UiKit.reduced_motion and is_inside_tree():
		pivot_offset = size*.5
		var tween := create_tween()
		tween.tween_property(self,"scale",Vector2.ONE*1.06,.08)
		tween.tween_property(self,"scale",Vector2.ONE,.12)
	else: scale = Vector2.ONE
	queue_redraw()

func _draw() -> void:
	if not textures.has(variant): return
	draw_texture_rect(textures[variant],Rect2(0,0,size.x,size.y),false,suitcase_color)
	if special_type == "key":
		draw_circle(size*.5,19,UiKit.GOLD)
		draw_texture_rect(load("res://assets/icons/key.svg"),Rect2(size*.5-Vector2(18,18),Vector2(36,36)),false)
		return
	var tag := Rect2(size.x*.53,size.y*.38,40,32 if secondary_code.is_empty() else 40)
	draw_line(tag.position-Vector2(7,8),tag.position+Vector2(7,4),UiKit.PAPER,2,true)
	draw_style_box(UiKit.panel(UiKit.PAPER,5,UiKit.INK,1),tag)
	draw_circle(tag.position+Vector2(5,5),2,UiKit.GOLD)
	var shown := "?" if not revealed else destination_code
	draw_string(ThemeDB.fallback_font,tag.position+Vector2(0,22),shown,HORIZONTAL_ALIGNMENT_CENTER,tag.size.x,12,UiKit.INK)
	if not secondary_code.is_empty() and revealed:
		draw_string(ThemeDB.fallback_font,tag.position+Vector2(0,36),secondary_code,HORIZONTAL_ALIGNMENT_CENTER,tag.size.x,10,UiKit.INK)
	# Color is supplemented by a stable pattern on the shell.
	var pattern: int = absi(destination_code.hash())%3
	for i in 3:
		if pattern == 0: draw_circle(Vector2(22+i*6,30),1.5,UiKit.PAPER)
		elif pattern == 1: draw_line(Vector2(19+i*6,26),Vector2(22+i*6,33),UiKit.PAPER,1.5)
		else: draw_rect(Rect2(19+i*6,29,3,3),UiKit.PAPER)
	if locked:
		draw_circle(Vector2(20,52),12,UiKit.NAVY)
		draw_texture_rect(load("res://assets/icons/lock.svg"),Rect2(10,42,20,20),false,UiKit.GOLD)

func set_interaction_enabled(value: bool) -> void:
	disabled = not value
