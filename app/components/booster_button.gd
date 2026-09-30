class_name BoosterButton
extends Button

var booster_id: String = ""

func configure(id: String, icon_path: String, count: int, available: bool) -> void:
	booster_id = id
	text = "×%d" % count
	tooltip_text = tr("booster.%s" % id)
	custom_minimum_size = Vector2(54, 54)
	disabled = not available
	add_theme_constant_override("icon_max_width", 26)
	if ResourceLoader.exists(icon_path):
		icon = load(icon_path)
	add_theme_font_size_override("font_size", 13)
	add_theme_stylebox_override("normal", UiKit.panel(UiKit.MINT, 27))
	add_theme_stylebox_override("hover", UiKit.panel(UiKit.MINT.lightened(0.06), 27))
	add_theme_stylebox_override("pressed", UiKit.panel(UiKit.MINT.darkened(0.08), 27))
	add_theme_stylebox_override("disabled", UiKit.panel(Color("CFD9D6"), 27))
