class_name UpgradeSheet
extends Control
signal purchase_requested(zone: String)

func configure(zone: String, profile: Dictionary) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 4080
	var dim := ColorRect.new()
	dim.color = Color(0.09,0.13,0.24,.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed: queue_free())
	var card := PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	card.offset_left = 16; card.offset_right = -16
	card.offset_top = -418; card.offset_bottom = -26
	card.add_theme_stylebox_override("panel",UiKit.panel(UiKit.PAPER,28))
	add_child(card)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",7)
	scroll.add_child(column)
	var stage := int(profile.get("airport",{}).get(zone,0))
	var head := HBoxContainer.new()
	var title := UiKit.label(tr("airport."+zone),22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := UiKit.button("×",UiKit.PAPER,true)
	close.pressed.connect(queue_free)
	head.add_child(close)
	column.add_child(head)
	column.add_child(UiKit.label(tr("upgrade.stage") % [stage,mini(3,stage+1)],14,true))
	var previews := HBoxContainer.new()
	for s in [stage,mini(3,stage+1)]:
		var art := UiKit.art("res://assets/art/airport/%s_%d.svg" % [zone,s],104)
		art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		previews.add_child(art)
	column.add_child(previews)
	column.add_child(UiKit.label(tr("upgrade.visual."+zone),14,true))
	column.add_child(UiKit.label(tr("perk."+zone),14,true))
	var cost := AirportEconomy.cost(zone,stage)
	var buy := UiKit.button(tr("airport.complete") if stage >= 3 else tr("upgrade.buy") % cost,UiKit.GOLD)
	buy.disabled = stage >= 3 or int(profile.get("coins",0)) < cost
	buy.pressed.connect(func() -> void:
		purchase_requested.emit(zone)
		queue_free())
	column.add_child(buy)
	if stage < 3 and int(profile.get("coins",0)) < cost:
		column.add_child(UiKit.label(tr("upgrade.need_coins"),12,true))
