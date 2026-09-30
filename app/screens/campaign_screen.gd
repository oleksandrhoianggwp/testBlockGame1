class_name CampaignScreen
extends Control

signal back_requested
signal level_selected(level_id: int)

func setup(profile: Dictionary, config: Dictionary) -> void:
	var safe := UiKit.screen_background(self, Color("EAF3F1"))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	safe.add_child(column)
	var header := UiKit.header(tr("campaign.title"), int(profile.get("coins", 0)))
	(header["back"] as Button).pressed.connect(func() -> void: back_requested.emit())
	column.add_child(header["root"])
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var journey := VBoxContainer.new()
	journey.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journey.add_theme_constant_override("separation", 0)
	scroll.add_child(journey)
	var unlocked_level := int(profile.get("current_level", 1))
	var cursor := 0
	for world: Dictionary in config.get("worlds", []):
		var world_card := PanelContainer.new()
		world_card.add_theme_stylebox_override("panel", UiKit.panel(Color(String(world.get("color", "DDF2EE"))), 24))
		var section := VBoxContainer.new()
		section.add_theme_constant_override("separation", 3)
		world_card.add_child(section)
		var heading := UiKit.label("%d  %s" % [int(world.get("id", 1)), tr(String(world.get("name_key", "")))], 22, true)
		if int(world.get("id", 1)) == 4:
			heading.add_theme_color_override("font_color", UiKit.PAPER)
		section.add_child(heading)
		var stage_count := int(world.get("stage_count", 0))
		for local_level in range(1, stage_count + 1):
			var level_id := cursor + local_level
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			var left_spacer := Control.new()
			left_spacer.custom_minimum_size.x = 48 if local_level % 2 == 0 else 128
			row.add_child(left_spacer)
			var node := LevelNode.new()
			var saved: Dictionary = profile.get("levels", {}).get(str(level_id), {})
			node.configure(level_id, int(saved.get("stars", 0)), level_id <= unlocked_level, local_level in [8, 15], local_level in [5, 10, 15])
			node.pressed.connect(func(id := level_id) -> void: level_selected.emit(id))
			row.add_child(node)
			var label := UiKit.label(tr("campaign.rush") if local_level == 15 else tr("campaign.hard") if local_level == 8 else "", 12)
			label.custom_minimum_size.x = 92
			row.add_child(label)
			section.add_child(row)
			if local_level < stage_count:
				var connector_row := HBoxContainer.new()
				connector_row.alignment = BoxContainer.ALIGNMENT_CENTER
				var connector := ColorRect.new()
				connector.color = UiKit.GOLD if level_id < unlocked_level else Color("B9C4CD")
				connector.custom_minimum_size = Vector2(5, 24)
				connector_row.add_child(connector)
				section.add_child(connector_row)
		journey.add_child(world_card)
		cursor += stage_count
		var transition := UiKit.label("✈", 25, true)
		transition.custom_minimum_size.y = 42
		journey.add_child(transition)
	call_deferred("_scroll_to_current", scroll, unlocked_level)

func _scroll_to_current(scroll: ScrollContainer, unlocked_level: int) -> void:
	await get_tree().process_frame
	# Approximate placement keeps the newest unlocked part visible without hiding context.
	scroll.scroll_vertical = maxi(0, (unlocked_level - 4) * 93)
