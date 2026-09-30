class_name TutorialOverlay
extends Control
var target: Control
var tutorial_id: String = ""
var message: Label
var pulse: float = 0.0

func configure(id: String, text_key: String, focus: Control) -> void:
	tutorial_id = id
	target = focus
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 4090
	message = UiKit.label(tr(text_key),16,true)
	message.add_theme_stylebox_override("normal",UiKit.panel(UiKit.PAPER,18,UiKit.GOLD,2))
	message.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	message.offset_left = 22; message.offset_right = -22
	message.offset_top = 104; message.offset_bottom = 170
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(message)
	set_process(true)

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(target): return
	var rect := target.get_global_rect()
	rect.position -= global_position
	var padding := 5.0 if UiKit.reduced_motion else 5.0 + sin(pulse*5.0)*3.0
	rect = rect.grow(padding)
	draw_style_box(UiKit.panel(Color(1,1,1,0),16,UiKit.GOLD,3),rect)
	if not UiKit.reduced_motion:
		var p := rect.get_center()+Vector2(14,rect.size.y*.5+10)
		draw_circle(p,9,UiKit.PAPER)
		draw_line(p,p+Vector2(0,-16),UiKit.INK,4,true)
