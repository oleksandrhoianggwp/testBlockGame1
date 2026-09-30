class_name UiKit
extends RefCounted

const INK := Color("17213B")
const NAVY := Color("10182F")
const SKY := Color("DDF2EE")
const PAPER := Color("FFF9EF")
const CORAL := Color("F06F6A")
const GOLD := Color("F5BD57")
const MINT := Color("6FC6A3")
const BLUE := Color("4C8FE8")
const MUTED := Color("70809B")

static func panel(color: Color = PAPER, radius: int = 22, border: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	box.shadow_color = Color(0.08, 0.12, 0.22, 0.16)
	box.shadow_size = 7
	box.shadow_offset = Vector2(0, 4)
	if border_width > 0:
		box.border_color = border
		box.border_width_left = border_width
		box.border_width_top = border_width
		box.border_width_right = border_width
		box.border_width_bottom = border_width
	return box

static func label(text_value: String, size: int = 18, centered: bool = false) -> Label:
	var result := Label.new()
	result.text = text_value
	result.add_theme_color_override("font_color", INK)
	result.add_theme_font_size_override("font_size", size)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if centered:
		result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return result

static func button(text_value: String, color: Color = PAPER, compact: bool = false) -> Button:
	var result := Button.new()
	result.text = text_value
	result.custom_minimum_size = Vector2(0, 44 if compact else 56)
	result.add_theme_font_size_override("font_size", 14 if compact else 18)
	result.add_theme_color_override("font_color", INK)
	result.add_theme_stylebox_override("normal", panel(color, 16))
	result.add_theme_stylebox_override("hover", panel(color.lightened(0.05), 16))
	result.add_theme_stylebox_override("pressed", panel(color.darkened(0.08), 16))
	result.add_theme_stylebox_override("disabled", panel(color.darkened(0.03), 16))
	return result

static func screen_background(host: Control, color: Color, texture_path: String = "") -> MarginContainer:
	var background := ColorRect.new()
	background.color = color
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(background)
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		var art := TextureRect.new()
		art.texture = load(texture_path)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.modulate = Color(1, 1, 1, 0.65)
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.add_child(art)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 18)
	safe.add_theme_constant_override("margin_right", 18)
	safe.add_theme_constant_override("margin_top", 20)
	safe.add_theme_constant_override("margin_bottom", 16)
	host.add_child(safe)
	return safe

static func header(title_text: String, coins: int, show_back: bool = true) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var back: Button = null
	if show_back:
		back = button("‹", PAPER, true)
		back.custom_minimum_size = Vector2(48, 48)
		row.add_child(back)
	var title := label(title_text, 22, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.custom_minimum_size.x = 0
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title)
	var currency := label("● %d" % coins, 16, true)
	currency.custom_minimum_size = Vector2(82, 48)
	currency.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	currency.add_theme_stylebox_override("normal", panel(Color("FFF1BE"), 16))
	row.add_child(currency)
	return {"root": row, "back": back, "currency": currency, "title": title}
