class_name DailyScreen
extends Control
signal back_requested
signal start_requested

func setup(profile: Dictionary, date: String) -> void:
	var safe := UiKit.screen_background(self,UiKit.SKY,"res://assets/art/airport_atmosphere.png")
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",14)
	safe.add_child(column)
	var header := UiKit.header(tr("daily.today"),int(profile.get("coins",0)))
	header["back"].pressed.connect(func() -> void: back_requested.emit())
	column.add_child(header["root"])
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(space)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",UiKit.panel(UiKit.NAVY,26))
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation",12)
	card.add_child(details)
	for line in [tr("daily.board"),date,tr("daily.completed") if String(profile["daily"].get("last_rewarded_date","")) == date else tr("daily.ready"),tr("daily.best") % int(profile["daily"].get("best_scores",{}).get(date,0)),tr("daily.streak") % int(profile["daily"].get("streak",0)),tr("daily.reward")]:
		var label := UiKit.label(line,22 if line == tr("daily.board") else 16,true)
		label.add_theme_color_override("font_color",UiKit.GOLD if line == tr("daily.board") else UiKit.PAPER)
		details.add_child(label)
	column.add_child(card)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var start := UiKit.button(tr("daily.replay") if String(profile["daily"].get("last_rewarded_date","")) == date else tr("daily.start"),UiKit.CORAL)
	start.pressed.connect(func() -> void: start_requested.emit())
	column.add_child(start)
