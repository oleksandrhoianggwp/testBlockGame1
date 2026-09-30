class_name SettingsScreen
extends Control

signal back_requested
signal setting_changed(key: String, value: Variant)
signal language_requested
signal tutorials_requested

func setup(profile: Dictionary) -> void:
	var safe := UiKit.screen_background(self, Color("EDF1F7"))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	safe.add_child(column)
	var header := UiKit.header(tr("menu.settings"), int(profile.get("coins", 0)))
	(header["back"] as Button).pressed.connect(func() -> void: back_requested.emit())
	column.add_child(header["root"])
	var settings: Dictionary = profile.get("settings", {})
	for entry in [["master_sound", "settings.sound"], ["music", "settings.music"], ["sfx", "settings.sfx"], ["haptics", "settings.haptics"], ["reduced_motion", "settings.motion"]]:
		var toggle := CheckButton.new()
		toggle.text = tr(entry[1])
		toggle.button_pressed = bool(settings.get(entry[0], true))
		toggle.custom_minimum_size.y = 54
		toggle.add_theme_font_size_override("font_size", 17)
		toggle.toggled.connect(func(value: bool, key := String(entry[0])) -> void: setting_changed.emit(key, value))
		column.add_child(toggle)
	var language := UiKit.button("%s: %s" % [tr("settings.language"), "Українська" if TranslationServer.get_locale().begins_with("uk") else "English"], UiKit.PAPER)
	language.pressed.connect(func() -> void: language_requested.emit())
	column.add_child(language)
	var text_scale := OptionButton.new()
	text_scale.add_item(tr("settings.text_normal"), 0)
	text_scale.add_item(tr("settings.text_large"), 1)
	text_scale.select(1 if float(settings.get("text_scale", 1.0)) > 1.1 else 0)
	text_scale.custom_minimum_size.y = 54
	text_scale.item_selected.connect(func(index: int) -> void: setting_changed.emit("text_scale", 1.2 if index == 1 else 1.0))
	column.add_child(text_scale)
	var replay := UiKit.button(tr("settings.replay"), UiKit.PAPER)
	replay.pressed.connect(func() -> void: tutorials_requested.emit())
	column.add_child(replay)
	var offline := UiKit.label(tr("privacy.summary"), 14, true)
	offline.add_theme_stylebox_override("normal", UiKit.panel(Color("DDF2EE"), 18))
	offline.size_flags_vertical = Control.SIZE_EXPAND_FILL
	offline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	column.add_child(offline)
