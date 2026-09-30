class_name UiKit
extends RefCounted

const INK := Color("17223D")
const NAVY := Color("24334E")
const SKY := Color("DDEFF4")
const PAPER := Color("FFF8EB")
const CORAL := Color("F06F6C")
const GOLD := Color("F7C75A")
const MINT := Color("75CDB2")
const BLUE := Color("5B91E8")
const MUTED := Color("70809B")
static var text_scale: float = 1.0
static var reduced_motion: bool = false

static func panel(color: Color = PAPER, radius: int = 18, border: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	box.shadow_color = Color(0.09, 0.13, 0.24, 0.13)
	box.shadow_size = 5
	box.shadow_offset = Vector2(0, 4)
	box.border_color = border
	box.set_border_width_all(border_width)
	return box

static func label(value: String, font_size: int = 18, centered: bool = false) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_color_override("font_color", INK)
	node.add_theme_font_size_override("font_size", int(font_size * text_scale))
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if centered: node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return node

static func button(value: String, color: Color = PAPER, compact: bool = false) -> Button:
	var node := Button.new()
	node.text = value
	node.custom_minimum_size = Vector2(44, 48 if compact else 56)
	node.add_theme_font_size_override("font_size", int((14 if compact else 18) * text_scale))
	node.add_theme_color_override("font_color", INK)
	node.add_theme_stylebox_override("normal", panel(color))
	node.add_theme_stylebox_override("hover", panel(color.lightened(0.04)))
	node.add_theme_stylebox_override("pressed", panel(color.darkened(0.07)))
	node.add_theme_stylebox_override("disabled", panel(color.darkened(0.1)))
	node.button_down.connect(func() -> void:
		if reduced_motion or not node.is_inside_tree(): return
		node.pivot_offset = node.size * 0.5
		node.create_tween().tween_property(node, "scale", Vector2.ONE * 0.96, 0.08))
	node.button_up.connect(func() -> void:
		if not node.is_inside_tree(): return
		node.create_tween().tween_property(node, "scale", Vector2.ONE, 0.10))
	return node

static func icon_button(id: String, color: Color = PAPER) -> Button:
	var node := button("", color, true)
	node.custom_minimum_size = Vector2(48, 48)
	node.icon = load("res://assets/icons/%s.svg" % id)
	node.add_theme_constant_override("icon_max_width", 25)
	return node

static func art(path: String, height: float) -> TextureRect:
	var node := TextureRect.new()
	node.texture = load(path)
	node.custom_minimum_size.y = height
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func screen_background(host: Control, color: Color, texture_path: String = "") -> MarginContainer:
	var bg := ColorRect.new()
	bg.color = color
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(bg)
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		var picture := art(texture_path, 0)
		picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		host.add_child(picture)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for key in ["left","right","top","bottom"]:
		safe.add_theme_constant_override("margin_" + key, 18 if key != "bottom" else 22)
	host.add_child(safe)
	if OS.get_name() == "Android":
		var rect := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		var viewport := host.get_viewport_rect().size
		if screen.x > 0 and screen.y > 0:
			safe.add_theme_constant_override("margin_top", maxi(18, int(rect.position.y * viewport.y / screen.y) + 8))
			safe.add_theme_constant_override("margin_bottom", maxi(22, int((screen.y - rect.end.y) * viewport.y / screen.y) + 8))
			safe.add_theme_constant_override("margin_left", maxi(18, int(rect.position.x * viewport.x / screen.x) + 8))
			safe.add_theme_constant_override("margin_right", maxi(18, int((screen.x - rect.end.x) * viewport.x / screen.x) + 8))
	return safe

static func header(title_text: String, coins: int = -1, show_back: bool = true) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var back: Button
	if show_back:
		back = button("‹", PAPER, true)
		back.custom_minimum_size = Vector2(48,48)
		row.add_child(back)
	var title := label(title_text, 20, true)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.custom_minimum_size.y = 48
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_stylebox_override("normal", panel(Color(1,.98,.92,.90),14))
	row.add_child(title)
	var currency: Label
	if coins >= 0:
		currency = label("● %d" % coins, 16, true)
		currency.custom_minimum_size = Vector2(84,48)
		currency.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		currency.add_theme_stylebox_override("normal", panel(GOLD))
		row.add_child(currency)
	return {"root":row,"back":back,"currency":currency,"title":title}

static func navigation(active: String, callback: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for id: String in ["campaign","airport","shift"]:
		var tab := button(TranslationServer.translate("nav." + id), MINT if id == active else PAPER, true)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_font_size_override("font_size", int(12 * text_scale))
		tab.icon = load("res://assets/icons/%s.svg" % id)
		tab.add_theme_constant_override("icon_max_width", 20)
		tab.pressed.connect(func(route := id) -> void: callback.call(route))
		row.add_child(tab)
	return row

static func progress_bar(percent: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.value = percent
	bar.show_percentage = false
	bar.custom_minimum_size.y = 12
	bar.add_theme_stylebox_override("background", panel(Color("BFCFD1"), 6))
	bar.add_theme_stylebox_override("fill", panel(MINT, 6))
	return bar

static func toast(host: Control, value: String) -> void:
	var card := PanelContainer.new()
	card.z_index = 4070
	card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	card.offset_left = 20; card.offset_right = -20
	card.offset_top = -150; card.offset_bottom = -85
	card.add_theme_stylebox_override("panel", panel(PAPER, 18))
	card.add_child(label(value, 15, true))
	host.add_child(card)
	card.create_tween().tween_callback(card.queue_free).set_delay(3.0)

static func flight_banner(host: Control, value: String) -> void:
	var card := PanelContainer.new()
	card.z_index = 4085
	card.anchor_left = 0.0; card.anchor_right = 1.0
	card.anchor_top = .5; card.anchor_bottom = .5
	card.offset_left = 22; card.offset_right = -22
	card.offset_top = -70; card.offset_bottom = 70
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel",panel(PAPER,24,GOLD,2))
	host.add_child(card)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	var plane := art("res://assets/icons/plane.svg",50)
	plane.custom_minimum_size.x = 50
	row.add_child(plane)
	var caption := label(value,22,true)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(caption)
	if not reduced_motion:
		plane.create_tween().tween_property(plane,"rotation",.18,.4).set_trans(Tween.TRANS_SINE)
		card.modulate.a = 0.0
		card.create_tween().tween_property(card,"modulate:a",1.0,.25)
	card.create_tween().tween_callback(card.queue_free).set_delay(2.3)
