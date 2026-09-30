class_name ShiftScreen
extends Control

signal back_requested
signal start_requested

func setup(profile: Dictionary) -> void:
	var safe := UiKit.screen_background(self, Color("17213B"), "res://assets/art/backgrounds/midnight.svg")
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 15)
	safe.add_child(column)
	var header := UiKit.header(tr("shift.title"), int(profile.get("coins", 0)))
	(header["back"] as Button).pressed.connect(func() -> void: back_requested.emit())
	column.add_child(header["root"])
	var icon := UiKit.label("✈  ∞", 54, true)
	icon.add_theme_color_override("font_color", UiKit.GOLD)
	column.add_child(icon)
	var shift: Dictionary = profile.get("shift", {})
	var card := UiKit.label("%s\n%s: %d\n%s: %d" % [tr("shift.description"), tr("shift.high_score"), int(shift.get("high_score", 0)), tr("shift.round"), maxi(1, int(shift.get("round", 1)))], 19, true)
	card.add_theme_stylebox_override("normal", UiKit.panel(Color("FFF9EF"), 24))
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	column.add_child(card)
	var events := UiKit.label(tr("shift.events_help"), 14, true)
	events.add_theme_color_override("font_color", UiKit.PAPER)
	column.add_child(events)
	var start := UiKit.button(tr("shift.resume") if int(shift.get("active_seed", 0)) > 0 else tr("shift.start"), UiKit.CORAL)
	start.pressed.connect(func() -> void: start_requested.emit())
	column.add_child(start)
