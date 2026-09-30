class_name ResultScreen
extends Control

signal action_requested(action: String)

func setup(won: bool, mode: String, stars: int, reward: int, score: int, reason: String, renovation_percent: int, challenge_complete: bool) -> void:
	var safe := UiKit.screen_background(self, Color("DDF2EE") if won else Color("F5DDDD"))
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	safe.add_child(column)
	var stamp := UiKit.label("✓" if won else "!", 68, true)
	stamp.add_theme_color_override("font_color", UiKit.MINT if won else UiKit.CORAL)
	column.add_child(stamp)
	column.add_child(UiKit.label(tr("game.win") if won else tr("game.lose"), 30, true))
	var card_text := ""
	if won:
		card_text = "%s\n%s %d\n%s +%d" % ["★".repeat(stars), tr("game.score"), score, tr("game.coins"), reward]
		if challenge_complete:
			card_text += "\n◆ " + tr("result.challenge_complete")
		card_text += "\n%s %d%%" % [tr("result.renovation"), renovation_percent]
	else:
		card_text = tr("game.priority_failed") if reason == "priority" else tr("game.tray_full")
	var card := UiKit.label(card_text, 20, true)
	card.add_theme_stylebox_override("normal", UiKit.panel(UiKit.PAPER, 24))
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	column.add_child(card)
	if won:
		var continue_button := UiKit.button(tr("menu.continue"), UiKit.CORAL)
		continue_button.pressed.connect(func() -> void: action_requested.emit("continue"))
		column.add_child(continue_button)
	var retry := UiKit.button(tr("menu.retry"), UiKit.GOLD if not won else UiKit.PAPER)
	retry.pressed.connect(func() -> void: action_requested.emit("retry"))
	column.add_child(retry)
	var home := UiKit.button(tr("menu.home"), UiKit.PAPER)
	home.pressed.connect(func() -> void: action_requested.emit("home"))
	column.add_child(home)
