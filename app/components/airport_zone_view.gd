class_name AirportZoneView
extends Button

var zone_id: String = ""
var stage: int = 0
var texture: Texture2D
var show_name: bool = true

func configure(zone: String, value: int, labels: bool = true) -> void:
	zone_id = zone
	stage = clampi(value,0,3)
	show_name = labels
	texture = load("res://assets/art/airport/%s_%d.svg" % [zone,stage])
	flat = true
	text = ""
	focus_mode = Control.FOCUS_NONE
	for key in ["normal","hover","pressed","focus"]:
		add_theme_stylebox_override(key, StyleBoxEmpty.new())
	queue_redraw()

func _draw() -> void:
	if texture == null: return
	draw_texture_rect(texture, Rect2(0,0,size.x,size.y-22),false)
	if show_name:
		draw_style_box(UiKit.panel(Color(1,0.98,0.92,0.92),8),Rect2(5,size.y-25,size.x-10,23))
		draw_string(ThemeDB.fallback_font,Vector2(5,size.y-9),tr("airport."+zone_id),HORIZONTAL_ALIGNMENT_CENTER,size.x-10,11,UiKit.INK)
	draw_circle(Vector2(size.x-16,20),9,UiKit.GOLD if stage < 3 else UiKit.MINT)
	draw_string(ThemeDB.fallback_font,Vector2(size.x-22,24),str(stage),HORIZONTAL_ALIGNMENT_CENTER,12,11,UiKit.INK)
