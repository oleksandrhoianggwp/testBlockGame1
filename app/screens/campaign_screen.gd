class_name CampaignScreen
extends Control
signal back_requested
signal level_selected(level_id: int)
signal route_requested(route: String)

func setup(profile: Dictionary, config: Dictionary) -> void:
	var safe := UiKit.screen_background(self,UiKit.SKY)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",9)
	safe.add_child(column)
	var header := UiKit.header(tr("campaign.title"),int(profile.get("coins",0)))
	header["back"].pressed.connect(func() -> void: back_requested.emit())
	column.add_child(header["root"])
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var journey := VBoxContainer.new()
	journey.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journey.add_theme_constant_override("separation",0)
	scroll.add_child(journey)
	var unlocked := int(profile.get("current_level",1))
	var cursor := 0
	for world: Dictionary in config.get("worlds",[]):
		var scene := Control.new()
		scene.custom_minimum_size = Vector2(0,1380)
		scene.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var backdrop := UiKit.art("res://assets/art/worlds/world_%d.svg" % int(world["id"]),0)
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		backdrop.stretch_mode = TextureRect.STRETCH_SCALE
		scene.add_child(backdrop)
		var heading := UiKit.label(tr(String(world["name_key"])),24,true)
		heading.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		heading.offset_top = 20; heading.offset_bottom = 74
		heading.add_theme_stylebox_override("normal",UiKit.panel(UiKit.PAPER,18))
		scene.add_child(heading)
		for local in range(1,int(world["stage_count"])+1):
			var id := cursor+local
			var node := LevelNode.new()
			var record: Dictionary = profile.get("levels",{}).get(str(id),{})
			node.configure(id,int(record.get("stars",0)),id<=unlocked,local in [8,15],local in [5,10,15])
			node.size = Vector2(70,66)
			node.position = Vector2(160+sin(local*.85)*72,94+(local-1)*82)
			node.pressed.connect(func(level := id) -> void: level_selected.emit(level))
			scene.add_child(node)
			if local in [5,8,10,15]:
				var key := "campaign.reward" if local == 5 else "campaign.hard" if local == 8 else "campaign.milestone" if local == 10 else "campaign.rush"
				var caption := UiKit.label(tr(key),12,true)
				caption.position = node.position+Vector2(-35,61)
				caption.size = Vector2(140,18)
				caption.autowrap_mode = TextServer.AUTOWRAP_OFF
				caption.add_theme_font_size_override("font_size",11)
				caption.add_theme_stylebox_override("normal",UiKit.panel(UiKit.PAPER,8))
				scene.add_child(caption)
		if cursor >= unlocked:
			var fog := ColorRect.new()
			fog.color = Color(.87,.94,.95,.45)
			fog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
			scene.add_child(fog)
			var barrier := UiKit.label(tr("campaign.future"),18,true)
			barrier.position = Vector2(48,110); barrier.size = Vector2(290,50)
			barrier.add_theme_stylebox_override("normal",UiKit.panel(UiKit.GOLD,16))
			scene.add_child(barrier)
		journey.add_child(scene)
		cursor += int(world["stage_count"])
	column.add_child(UiKit.navigation("campaign",func(id: String) -> void: route_requested.emit(id)))
	call_deferred("_scroll_to",scroll,unlocked)

func _scroll_to(scroll: ScrollContainer, level: int) -> void:
	await get_tree().process_frame
	scroll.scroll_vertical = maxi(0,int((level-1)/15)*1380 + ((level-1)%15)*82-180)
