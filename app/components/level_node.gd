class_name LevelNode
extends Button
var level_id: int = 0

func configure(id: int, stars: int, unlocked: bool, hard: bool, milestone: bool) -> void:
	level_id = id
	disabled = not unlocked
	custom_minimum_size = Vector2(66,66)
	text = "%d\n%s" % [id,"★".repeat(stars) if stars > 0 else ""]
	add_theme_font_size_override("font_size",16)
	add_theme_color_override("font_color",UiKit.INK)
	var color := UiKit.CORAL if hard else UiKit.GOLD if milestone else UiKit.PAPER
	if not unlocked: color = Color("A9BFCD")
	for key in ["normal","hover","pressed","disabled"]:
		add_theme_stylebox_override(key,UiKit.panel(color,18 if hard else 28,UiKit.PAPER,3))
	if milestone:
		icon = load("res://assets/icons/airport.svg" if id%15 == 10 else "res://assets/icons/star.svg")
		add_theme_constant_override("icon_max_width",16)
	if hard and unlocked and not UiKit.reduced_motion:
		ready.connect(func() -> void:
			pivot_offset = size*.5
			var tween := create_tween().set_loops()
			tween.tween_property(self,"scale",Vector2.ONE*1.035,.8)
			tween.tween_property(self,"scale",Vector2.ONE,.8))
