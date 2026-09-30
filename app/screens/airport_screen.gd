class_name AirportScreen
extends Control

signal back_requested
signal upgrade_requested(world: int, zone: String)

const ZONES := ["entrance", "checkin", "baggage", "security", "cafe", "tower", "runway"]
const COSTS := [100, 150, 220]

func setup(profile: Dictionary, world: int) -> void:
	var safe := UiKit.screen_background(self, Color("DCEFEA"), "res://assets/art/backgrounds/regional.svg")
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	safe.add_child(column)
	var header := UiKit.header(tr("menu.airport"), int(profile.get("coins", 0)))
	(header["back"] as Button).pressed.connect(func() -> void: back_requested.emit())
	column.add_child(header["root"])
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var content_column := VBoxContainer.new()
	content_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_column.add_theme_constant_override("separation", 9)
	scroll.add_child(content_column)
	content_column.add_child(UiKit.label(tr("menu.airport"), 24, true))
	var progress: Dictionary = profile.get("airport_progress", {}).get(str(world), {})
	var stages := 0
	for zone in ZONES:
		stages += int(progress.get(zone, 0))
	content_column.add_child(UiKit.label("%s %d%%" % [tr("airport.progress"), int(float(stages) / 21.0 * 100.0)], 16, true))
	var scene_card := PanelContainer.new()
	scene_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scene_card.add_theme_stylebox_override("panel", UiKit.panel(Color("BFE2E5"), 28, Color("8BC9CD"), 2))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 8)
	scene_card.add_child(grid)
	for zone in ZONES:
		var stage := int(progress.get(zone, 0))
		var zone_button := Button.new()
		zone_button.custom_minimum_size = Vector2(102, 112)
		zone_button.text = ""
		var asset_path := "res://assets/art/airport/%s_%d.svg" % [zone, stage]
		var content := VBoxContainer.new()
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		var preview := TextureRect.new()
		preview.custom_minimum_size = Vector2(0, 68)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ResourceLoader.exists(asset_path):
			preview.texture = load(asset_path)
		content.add_child(preview)
		var zone_label := UiKit.label(tr("airport.%s" % zone), 10, true)
		zone_label.custom_minimum_size.y = 16
		zone_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(zone_label)
		var stars := UiKit.label("★".repeat(stage) + "☆".repeat(3 - stage), 10, true)
		stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(stars)
		zone_button.add_child(content)
		zone_button.add_theme_stylebox_override("normal", UiKit.panel(Color(1, 1, 1, 0.2), 18))
		zone_button.add_theme_stylebox_override("hover", UiKit.panel(Color(1, 1, 1, 0.42), 18, UiKit.GOLD, 2))
		zone_button.tooltip_text = tr("airport.complete") if stage >= 3 else "%s: ● %d" % [tr("airport.upgrade"), COSTS[stage] * world]
		zone_button.disabled = stage >= 3
		zone_button.pressed.connect(func(id := String(zone)) -> void: upgrade_requested.emit(world, id))
		grid.add_child(zone_button)
	content_column.add_child(scene_card)
	var perk := UiKit.label(tr("airport.perks_summary"), 13, true)
	perk.add_theme_stylebox_override("normal", UiKit.panel(Color("FFF1BE"), 14))
	content_column.add_child(perk)
