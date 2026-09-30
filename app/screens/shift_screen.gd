class_name ShiftScreen
extends Control
signal back_requested
signal route_requested(route: String)
signal start_requested
signal cash_out_requested

func setup(profile: Dictionary) -> void:
	var safe := UiKit.screen_background(self,UiKit.NAVY,"res://assets/art/backgrounds/midnight.svg")
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",14)
	safe.add_child(column)
	var header := UiKit.header(tr("shift.title"),int(profile.get("coins",0)))
	header["title"].add_theme_color_override("font_color",UiKit.INK)
	header["back"].pressed.connect(func() -> void: back_requested.emit())
	column.add_child(header["root"])
	var illustration := UiKit.art("res://assets/icons/plane.svg",80)
	illustration.modulate = UiKit.GOLD
	column.add_child(illustration)
	var shift: Dictionary = profile.get("shift",{})
	var title := UiKit.label(tr("shift.departures"),25,true)
	title.add_theme_color_override("font_color",UiKit.PAPER)
	column.add_child(title)
	var best := UiKit.label(tr("shift.best") % int(shift.get("high_score",0)),14,true)
	best.add_theme_color_override("font_color",UiKit.GOLD)
	column.add_child(best)
	var bank := ShiftBankPanel.new()
	bank.configure(shift,false)
	bank.cash_out_requested.connect(func() -> void: cash_out_requested.emit())
	column.add_child(bank)
	var helper := UiKit.label(tr("shift.description"),16,true)
	helper.add_theme_color_override("font_color",UiKit.PAPER)
	helper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(helper)
	var start := UiKit.button(tr("shift.resume") if int(shift.get("active_seed",0)) > 0 else tr("shift.start"),UiKit.CORAL)
	start.pressed.connect(func() -> void: start_requested.emit())
	column.add_child(start)
	column.add_child(UiKit.navigation("shift",func(id: String) -> void: route_requested.emit(id)))
