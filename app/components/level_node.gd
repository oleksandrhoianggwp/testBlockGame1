class_name LevelNode
extends Button

var level_id: int = 0

func configure(id: int, stars: int, unlocked: bool, hard: bool, milestone: bool) -> void:
	level_id = id
	disabled = not unlocked
	custom_minimum_size = Vector2(72 if hard else 62, 62)
	text = "%d\n%s" % [id, "★".repeat(stars) if stars > 0 else ("◆" if milestone else "")]
	add_theme_font_size_override("font_size", 13)
	var color := UiKit.CORAL if hard else UiKit.GOLD if milestone else UiKit.PAPER
	if not unlocked:
		color = Color("CCD5DF")
	add_theme_stylebox_override("normal", UiKit.panel(color, 31, UiKit.INK if unlocked else Color("9AA7B5"), 3))
	add_theme_stylebox_override("hover", UiKit.panel(color.lightened(0.05), 31, UiKit.INK, 3))
	add_theme_stylebox_override("pressed", UiKit.panel(color.darkened(0.08), 31, UiKit.INK, 3))
	add_theme_stylebox_override("disabled", UiKit.panel(color, 31, Color("9AA7B5"), 2))
