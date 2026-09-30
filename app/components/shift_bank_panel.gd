class_name ShiftBankPanel
extends PanelContainer
signal cash_out_requested
signal continue_requested

func configure(shift: Dictionary, allow_continue: bool = true) -> void:
	add_theme_stylebox_override("panel",UiKit.panel(UiKit.NAVY,24))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	add_child(column)
	var title := UiKit.label(tr("shift.earnings"),14,true)
	title.add_theme_color_override("font_color",UiKit.PAPER)
	column.add_child(title)
	var earnings := UiKit.label("● %d" % int(shift.get("earnings",0)),36,true)
	earnings.add_theme_color_override("font_color",UiKit.GOLD)
	column.add_child(earnings)
	var multiplier := UiKit.label(tr("shift.next_multiplier") % AirportEconomy.shift_multiplier(maxi(1,int(shift.get("round",1)))),15,true)
	multiplier.add_theme_color_override("font_color",UiKit.PAPER)
	column.add_child(multiplier)
	var cash := UiKit.button(tr("shift.cash_out"),UiKit.GOLD)
	cash.disabled = int(shift.get("earnings",0)) <= 0
	cash.pressed.connect(func() -> void: cash_out_requested.emit())
	column.add_child(cash)
	if allow_continue:
		var next := UiKit.button(tr("shift.continue"),UiKit.CORAL)
		next.pressed.connect(func() -> void: continue_requested.emit())
		column.add_child(next)
	var risk := UiKit.label(tr("shift.risk"),13,true)
	risk.add_theme_color_override("font_color",UiKit.PAPER)
	column.add_child(risk)
