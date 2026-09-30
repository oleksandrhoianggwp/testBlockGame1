class_name LuggageView
extends Button

var item_id: String = ""
var destination_code: String = ""
var secondary_code: String = ""
var suitcase_color: Color = UiKit.CORAL
var special_type: String = ""
var variant: int = 0
var selectable: bool = true
var revealed: bool = true
var locked: bool = false

func _ready() -> void:
	flat = true
	text = ""
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(104, 72)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	queue_redraw()

func configure(item: Dictionary, can_select: bool, codes: Dictionary, colors: Dictionary) -> void:
	item_id = String(item.get("id", ""))
	special_type = String(item.get("special_type", ""))
	var destination := String(item.get("destination_id", ""))
	destination_code = String(codes.get(destination, destination.to_upper()))
	secondary_code = ""
	if special_type == "transfer":
		var options: Array = item.get("destination_options", [])
		if options.size() > 1:
			destination_code = String(codes.get(String(options[0]), String(options[0]).to_upper()))
			secondary_code = String(codes.get(String(options[1]), String(options[1]).to_upper()))
	suitcase_color = Color(String(colors.get(destination, "70809b")))
	variant = abs(item_id.hash()) % 6
	selectable = can_select
	revealed = bool(item.get("revealed", true))
	locked = not String(item.get("lock_group", "")).is_empty() and not can_select
	disabled = not can_select
	modulate = Color.WHITE if can_select else Color(0.82, 0.86, 0.91, 0.88)
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(5, 9, size.x - 10, size.y - 14)
	if selectable:
		draw_rect(Rect2(rect.position + Vector2(0, 5), rect.size), Color(0.06, 0.10, 0.18, 0.24), true)
	var body := UiKit.panel(suitcase_color, 15, UiKit.INK, 3)
	match variant:
		1:
			rect = Rect2(10, 5, size.x - 20, size.y - 10)
		2:
			rect = Rect2(3, 14, size.x - 6, size.y - 20)
		3:
			rect = Rect2(12, 7, size.x - 24, size.y - 10)
		4:
			body.corner_radius_top_left = 28
			body.corner_radius_top_right = 28
		5:
			rect = Rect2(5, 4, size.x - 10, size.y - 8)
	draw_style_box(body, rect)
	if special_type == "key":
		draw_circle(rect.get_center(), 19, UiKit.GOLD)
		draw_circle(rect.get_center() + Vector2(-5, 0), 6, UiKit.PAPER, false, 4)
		draw_line(rect.get_center() + Vector2(5, 0), rect.get_center() + Vector2(24, 0), UiKit.INK, 6)
		draw_line(rect.get_center() + Vector2(17, 0), rect.get_center() + Vector2(17, 10), UiKit.INK, 5)
		return
	# Handles, shell ribs and wheels make every silhouette read as luggage.
	draw_arc(Vector2(size.x * 0.5, rect.position.y + 1), 14, PI, TAU, 14, UiKit.INK, 4)
	for rib_x in [0.25, 0.75]:
		draw_line(Vector2(rect.position.x + rect.size.x * rib_x, rect.position.y + 10), Vector2(rect.position.x + rect.size.x * rib_x, rect.end.y - 8), Color(1, 1, 1, 0.22), 3)
	draw_circle(Vector2(rect.position.x + 18, rect.end.y + 1), 3, UiKit.INK)
	draw_circle(Vector2(rect.end.x - 18, rect.end.y + 1), 3, UiKit.INK)
	var tag := Rect2(rect.end.x - 52, rect.position.y + 13, 44, 31 if secondary_code.is_empty() else 39)
	draw_style_box(UiKit.panel(UiKit.PAPER, 6, UiKit.INK, 2), tag)
	var shown := "???" if not revealed else destination_code
	if not secondary_code.is_empty() and revealed:
		shown += "\n" + secondary_code
	var font := ThemeDB.fallback_font
	var baseline := tag.position + Vector2(0, 20)
	draw_string(font, baseline, shown, HORIZONTAL_ALIGNMENT_CENTER, tag.size.x, 13 if secondary_code.is_empty() else 11, UiKit.INK)
	if locked:
		draw_circle(Vector2(rect.position.x + 18, rect.position.y + 18), 13, UiKit.NAVY)
		draw_string(font, Vector2(rect.position.x + 7, rect.position.y + 23), "L", HORIZONTAL_ALIGNMENT_CENTER, 22, 13, UiKit.PAPER)

func set_interaction_enabled(value: bool) -> void:
	selectable = value
	disabled = not value
	queue_redraw()
