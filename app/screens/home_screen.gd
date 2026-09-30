class_name HomeScreen
extends Control

signal route_requested(route: String)

const AIRPORT_ZONES := ["entrance", "checkin", "baggage", "security", "cafe", "tower", "runway"]

func setup(profile: Dictionary, current_world: int) -> void:
	var safe := UiKit.screen_background(self, UiKit.SKY, "res://assets/art/backgrounds/regional.svg")
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	safe.add_child(column)
	var header := HBoxContainer.new()
	var badge := UiKit.label("✈  %s %d" % [tr("game.level"), int(profile.get("current_level", 1))], 15)
	badge.add_theme_stylebox_override("normal", UiKit.panel(Color(1, 1, 1, 0.85), 16))
	badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(badge)
	var currency := CurrencyDisplay.new()
	currency.custom_minimum_size = Vector2(96, 46)
	header.add_child(currency)
	column.add_child(header)
	currency.call_deferred("set_amount", int(profile.get("coins", 0)))
	var logo := TextureRect.new()
	logo.custom_minimum_size = Vector2(0, 102)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture = load("res://assets/art/logo.svg")
	column.add_child(logo)
	var game_title := UiKit.label(tr("app.title"), 27, true)
	game_title.add_theme_color_override("font_color", UiKit.NAVY)
	column.add_child(game_title)
	var airport_card := PanelContainer.new()
	airport_card.custom_minimum_size.y = 220
	airport_card.add_theme_stylebox_override("panel", UiKit.panel(Color("CFEAE8"), 24, Color("A8D9D0"), 2))
	var scene := Control.new()
	airport_card.add_child(scene)
	var progress: Dictionary = profile.get("airport_progress", {}).get(str(current_world), {})
	for index in AIRPORT_ZONES.size():
		var zone: String = String(AIRPORT_ZONES[index])
		var stage := int(progress.get(zone, 0))
		var art := TextureRect.new()
		art.texture = load("res://assets/art/airport/%s_%d.svg" % [zone, stage]) if ResourceLoader.exists("res://assets/art/airport/%s_%d.svg" % [zone, stage]) else null
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.position = Vector2(4 + (index % 4) * 92, 12 + int(index / 4) * 98)
		art.size = Vector2(92, 96)
		scene.add_child(art)
	column.add_child(airport_card)
	var owner_label := UiKit.label(tr("home.airport_owned"), 12, true)
	owner_label.custom_minimum_size.y = 22
	column.add_child(owner_label)
	var continue_button := UiKit.button(tr("menu.continue"), UiKit.CORAL)
	continue_button.pressed.connect(func() -> void: route_requested.emit("continue"))
	column.add_child(continue_button)
	var daily := UiKit.button("☀  " + tr("menu.daily"), UiKit.GOLD)
	daily.pressed.connect(func() -> void: route_requested.emit("daily"))
	column.add_child(daily)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 7)
	for entry in [["play", "▶", "menu.play"], ["airport", "⌂", "menu.airport"], ["shift", "∞", "menu.shift"], ["settings", "⚙", "menu.settings"]]:
		var button := UiKit.button("%s\n%s" % [entry[1], tr(entry[2])], UiKit.PAPER, true)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 11)
		button.pressed.connect(func(route := String(entry[0])) -> void: route_requested.emit(route))
		nav.add_child(button)
	column.add_child(nav)
