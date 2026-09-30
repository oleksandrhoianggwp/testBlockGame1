class_name SettingsScreen
extends Control
signal back_requested
signal setting_changed(key: String, value: Variant)
signal language_requested
signal tutorials_requested

func setup(profile: Dictionary) -> void:
	var safe := UiKit.screen_background(self,UiKit.PAPER)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	safe.add_child(column)
	var header := UiKit.header(tr("menu.settings"),-1)
	header["back"].pressed.connect(func() -> void: back_requested.emit())
	column.add_child(header["root"])
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",7)
	scroll.add_child(list)
	var settings: Dictionary = profile.get("settings",{})
	for group in [["audio",[["master_sound","settings.sound"],["music","settings.music"],["sfx","settings.sfx"]]],["accessibility",[["haptics","settings.haptics"],["reduced_motion","settings.motion"]]]]:
		list.add_child(UiKit.label(tr("settings.group."+String(group[0])),14))
		for entry in group[1]:
			var row := HBoxContainer.new()
			var name_label := UiKit.label(tr(entry[1]),17)
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row.add_child(name_label)
			var toggle := UiKit.button(tr("settings.on") if bool(settings.get(entry[0],true)) else tr("settings.off"),UiKit.MINT,true)
			toggle.toggle_mode = true
			toggle.button_pressed = bool(settings.get(entry[0],true))
			toggle.custom_minimum_size.x = 76
			toggle.toggled.connect(func(value: bool,key := String(entry[0]),node := toggle) -> void:
				node.text = tr("settings.on") if value else tr("settings.off")
				setting_changed.emit(key,value))
			row.add_child(toggle)
			list.add_child(row)
	var text_size := UiKit.button(tr("settings.text_large") if float(settings.get("text_scale",1)) <= 1.1 else tr("settings.text_normal"),UiKit.SKY,true)
	text_size.pressed.connect(func() -> void: setting_changed.emit("text_scale",1.15 if float(settings.get("text_scale",1)) <= 1.1 else 1.0))
	list.add_child(text_size)
	list.add_child(UiKit.label(tr("settings.group.language"),14))
	var language := UiKit.button(tr("settings.current_language"),UiKit.SKY,true)
	language.pressed.connect(func() -> void: language_requested.emit())
	list.add_child(language)
	list.add_child(UiKit.label(tr("settings.group.other"),14))
	var replay := UiKit.button(tr("settings.replay"),UiKit.SKY,true)
	replay.pressed.connect(func() -> void: tutorials_requested.emit())
	list.add_child(replay)
	for id: String in ["privacy","credits"]:
		var btn := UiKit.button(tr("settings."+id),UiKit.SKY,true)
		btn.pressed.connect(func(key := id) -> void:
			UiKit.toast(self,tr("privacy.summary") if key == "privacy" else tr("credits.body")))
		list.add_child(btn)
