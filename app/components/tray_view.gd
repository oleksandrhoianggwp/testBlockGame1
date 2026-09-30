class_name TrayView
extends PanelContainer

var title_label: Label
var slots_row: HBoxContainer

func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel(Color("27324D"), 20, Color("4B5875"), 2))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	add_child(column)
	title_label = UiKit.label("", 13, true)
	title_label.add_theme_color_override("font_color", UiKit.PAPER)
	column.add_child(title_label)
	slots_row = HBoxContainer.new()
	slots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	slots_row.add_theme_constant_override("separation", 4)
	slots_row.custom_minimum_size.y = 47
	column.add_child(slots_row)

func refresh(tray: Array[String], capacity: int, codes: Dictionary, colors: Dictionary) -> void:
	title_label.text = "%s  %d/%d" % [tr("game.tray"), tray.size(), capacity]
	for child in slots_row.get_children():
		child.queue_free()
	for destination: String in tray:
		var tag := Label.new()
		tag.text = String(codes.get(destination, destination.to_upper()))
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tag.custom_minimum_size = Vector2(43, 42)
		tag.add_theme_font_size_override("font_size", 11)
		tag.add_theme_color_override("font_color", UiKit.INK)
		tag.add_theme_stylebox_override("normal", UiKit.panel(Color(String(colors.get(destination, "70809b"))), 10))
		slots_row.add_child(tag)
	for _slot in range(tray.size(), capacity):
		var empty := Label.new()
		empty.text = "·"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(38, 42)
		empty.add_theme_color_override("font_color", Color("A9B2C7"))
		empty.add_theme_stylebox_override("normal", UiKit.panel(Color("3A4662"), 10))
		slots_row.add_child(empty)

func target_global_position(slot_index: int) -> Vector2:
	if slots_row.get_child_count() == 0:
		return global_position + size * 0.5
	var safe_index := clampi(slot_index, 0, slots_row.get_child_count() - 1)
	return (slots_row.get_child(safe_index) as Control).get_global_rect().get_center()
