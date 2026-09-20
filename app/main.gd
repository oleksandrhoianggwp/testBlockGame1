extends Control

const GameStateScript = preload("res://core/gameplay/game_state.gd")
const GeneratorScript = preload("res://core/generation/level_generator.gd")
const SolverScript = preload("res://core/solver/level_solver.gd")

const COLORS := {
	"ink": Color("18223b"), "navy": Color("0f1730"), "sky": Color("dff3f4"),
	"paper": Color("fffaf0"), "coral": Color("ef6f6c"), "gold": Color("f6bd60"),
	"mint": Color("72c7a5"), "blue": Color("4d8fe8"), "muted": Color("718096")
}
const DEST_COLORS := {
	"par": "e95d72", "tyo": "ef8d43", "iev": "f3c34f", "rom": "57b87a",
	"cai": "2bb7a8", "sel": "3fa6d8", "syd": "5d7be7", "rio": "9b70d9",
	"osl": "4d8cbf", "yto": "d968a7", "lim": "b8894e", "nbo": "718f47"
}
const DEST_SYMBOLS := {"par":"◆", "tyo":"◉", "iev":"✦", "rom":"∩", "cai":"▲", "sel":"門", "syd":"◒", "rio":"☀", "osl":"❄", "yto":"⌃", "lim":"▰", "nbo":"♣"}
const DEST_CODES := {"par":"PAR", "tyo":"TYO", "iev":"IEV", "rom":"ROM", "cai":"CAI", "sel":"SEL", "syd":"SYD", "rio":"RIO", "osl":"OSL", "yto":"YTO", "lim":"LIM", "nbo":"NBO"}
const WORLD_NAMES := ["Local Terminal", "International Terminal", "Cargo Terminal", "Midnight Hub", "Skyport"]
const AIRPORT_OBJECTS := ["entrance", "seating", "checkin", "cafe", "departures", "runway"]
const AIRPORT_COSTS := [100, 150, 220]

var game_state = GameStateScript.new()
var generator = GeneratorScript.new()
var current_screen: String = "home"
var current_mode: String = "campaign"
var current_level: int = 1
var endless_round: int = 0
var endless_score: int = 0
var continue_used: bool = false
var root_panel: Control
var board_control: Control
var tray_row: HBoxContainer
var status_label: Label
var tutorial_label: Label
var priority_label: Label
var transition_locked: bool = false

func _ready() -> void:
	_apply_locale()
	_apply_theme()
	AudioService.apply_settings()
	show_home()
	if "--capture-screens" in OS.get_cmdline_user_args():
		call_deferred("_capture_store_screens")

func _apply_locale() -> void:
	var language := String(SaveService.data.get("settings", {}).get("language", ""))
	if language.is_empty():
		language = "uk" if OS.get_locale_language() == "uk" else "en"
	TranslationServer.set_locale(language)

func _apply_theme() -> void:
	var app_theme := Theme.new()
	app_theme.default_font_size = int(18 * float(SaveService.data.get("settings", {}).get("text_scale", 1.0)))
	app_theme.set_color("font_color", "Label", COLORS.ink)
	app_theme.set_color("font_color", "Button", COLORS.ink)
	app_theme.set_font_size("font_size", "Button", 18)
	app_theme.set_constant("outline_size", "Label", 0)
	theme = app_theme

func _clear_screen() -> void:
	for child in get_children():
		child.queue_free()
	root_panel = null
	board_control = null
	tray_row = null
	status_label = null
	tutorial_label = null
	priority_label = null

func _screen_base(background: Color = COLORS.sky) -> VBoxContainer:
	_clear_screen()
	var bg := ColorRect.new()
	bg.color = background
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 20)
	safe.add_theme_constant_override("margin_right", 20)
	safe.add_theme_constant_override("margin_top", 24)
	safe.add_theme_constant_override("margin_bottom", 24)
	add_child(safe)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	safe.add_child(column)
	root_panel = safe
	return column

func _panel(color: Color = COLORS.paper, radius: float = 22.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = int(radius)
	box.corner_radius_top_right = int(radius)
	box.corner_radius_bottom_left = int(radius)
	box.corner_radius_bottom_right = int(radius)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box

func _make_label(text_value: String, size: int = 18, centered: bool = false) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", int(size * float(SaveService.data["settings"].get("text_scale", 1.0))))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _make_button(text_value: String, action: Callable, color: Color = COLORS.paper) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 54)
	button.add_theme_stylebox_override("normal", _panel(color, 16))
	button.add_theme_stylebox_override("hover", _panel(color.lightened(0.06), 16))
	button.add_theme_stylebox_override("pressed", _panel(color.darkened(0.08), 16))
	button.pressed.connect(func() -> void:
		AudioService.play_sfx("button")
		action.call()
	)
	return button

func _header(column: VBoxContainer, title_text: String, show_back: bool = true) -> void:
	var row := HBoxContainer.new()
	if show_back:
		var back := _make_button("‹", _go_back, COLORS.paper)
		back.custom_minimum_size = Vector2(54, 54)
		row.add_child(back)
	var title := _make_label(title_text, 28, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var coins := _make_label("◉ %d" % int(SaveService.data["coins"]), 18, true)
	coins.custom_minimum_size = Vector2(88, 54)
	row.add_child(coins)
	column.add_child(row)

func show_home() -> void:
	current_screen = "home"
	var column := _screen_base(Color("dff3f4"))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 18
	column.add_child(spacer)
	var logo := TextureRect.new()
	logo.custom_minimum_size = Vector2(0, 150)
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists("res://assets/art/logo.svg"):
		logo.texture = load("res://assets/art/logo.svg")
	column.add_child(logo)
	var title := _make_label(tr("app.title"), 34, true)
	column.add_child(title)
	var progress := _make_label("%s %d  •  %s %d" % [tr("game.level"), int(SaveService.data["current_level"]), tr("game.coins"), int(SaveService.data["coins"])], 17, true)
	progress.modulate = COLORS.muted
	column.add_child(progress)
	column.add_child(_make_button(tr("menu.play"), show_campaign, COLORS.coral))
	column.add_child(_make_button(tr("menu.daily"), show_daily, COLORS.gold))
	var endless := _make_button(tr("menu.endless"), start_endless, COLORS.mint)
	if int(SaveService.data["current_level"]) <= 20:
		endless.text += "  🔒"
		endless.tooltip_text = tr("endless.locked")
	column.add_child(endless)
	var bottom := GridContainer.new()
	bottom.columns = 3
	bottom.add_theme_constant_override("separation", 10)
	for item in [[tr("menu.airport"), show_airport], [tr("menu.settings"), show_settings], [tr("menu.info"), show_credits]]:
		var button := _make_button(item[0], item[1], COLORS.paper)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.add_theme_font_size_override("font_size", 12)
		bottom.add_child(button)
	column.add_child(bottom)
	LocalAnalytics.log_event("session_start", {"screen": "home"})

func show_campaign() -> void:
	current_screen = "campaign"
	var column := _screen_base(Color("edf5f0"))
	_header(column, tr("campaign.title"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var worlds := VBoxContainer.new()
	worlds.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	worlds.add_theme_constant_override("separation", 16)
	scroll.add_child(worlds)
	var unlocked_level := int(SaveService.data["current_level"])
	for world_index in 5:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _panel([Color("f8e2c1"), Color("dbeef5"), Color("e4dfd5"), Color("222c50"), Color("e2eef7")][world_index]))
		var section := VBoxContainer.new()
		panel.add_child(section)
		var heading := _make_label("%d. %s" % [world_index + 1, WORLD_NAMES[world_index]], 21)
		if world_index == 3:
			heading.add_theme_color_override("font_color", Color.WHITE)
		section.add_child(heading)
		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		section.add_child(grid)
		for local_index in 30:
			var level_id := world_index * 30 + local_index + 1
			var level_button := _make_button(str(level_id), func(id := level_id) -> void: start_campaign_level(id), COLORS.paper)
			level_button.custom_minimum_size = Vector2(55, 48)
			level_button.disabled = level_id > unlocked_level
			var saved: Dictionary = SaveService.data["levels"].get(str(level_id), {})
			if int(saved.get("stars", 0)) > 0:
				level_button.text = "%d\n%s" % [level_id, "★".repeat(int(saved["stars"]))]
			grid.add_child(level_button)
		worlds.add_child(panel)

func start_campaign_level(level_id: int) -> void:
	current_mode = "campaign"
	current_level = clampi(level_id, 1, 150)
	endless_round = 0
	endless_score = 0
	continue_used = false
	_load_and_show_level(_read_level(current_level))

func show_daily() -> void:
	current_mode = "daily"
	current_level = 10000
	continue_used = false
	var date := Time.get_date_string_from_system()
	SaveService.data["daily"]["last_played_date"] = date
	SaveService.save_profile()
	_load_and_show_level(generator.generate_daily(date, "lost-sorted-v1-daily"))

func start_endless() -> void:
	if int(SaveService.data["current_level"]) <= 20:
		_show_notice(tr("endless.locked"))
		return
	current_mode = "endless"
	current_level = 20000
	endless_round = 1
	endless_score = 0
	continue_used = false
	_start_endless_round()

func _start_endless_round() -> void:
	var parameters := generator.campaign_parameters(clampi(15 + endless_round * 4, 15, 145))
	parameters["id"] = 20000 + endless_round
	parameters["seed"] = 90210 + endless_round * 1337
	parameters["world"] = clampi(1 + int(endless_round / 5), 1, 5)
	_load_and_show_level(generator.generate_level(parameters))

func _read_level(level_id: int) -> Dictionary:
	var path := "res://data/campaign/level_%03d.json" % level_id
	if not FileAccess.file_exists(path):
		return generator.generate_level(generator.campaign_parameters(level_id))
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _load_and_show_level(definition: Dictionary) -> void:
	if definition.is_empty():
		_show_notice("Invalid level data")
		return
	game_state.load_level(definition)
	current_screen = "gameplay"
	LocalAnalytics.log_event("level_start", {"level": current_level, "seed": game_state.seed_value, "mode": current_mode})
	build_gameplay_screen()

func build_gameplay_screen() -> void:
	current_screen = "gameplay"
	var world := clampi(int((maxi(1, current_level) - 1) / 30), 0, 4)
	var backgrounds := [Color("dff3f4"), Color("e8f2f7"), Color("e9e1d5"), Color("101a38"), Color("e5eff9")]
	var column := _screen_base(backgrounds[world])
	var top := HBoxContainer.new()
	var pause := _make_button("Ⅱ", show_pause, COLORS.paper)
	pause.custom_minimum_size = Vector2(54, 50)
	top.add_child(pause)
	status_label = _make_label("%s %s  •  %s %d" % [tr("game.level"), str(current_level) if current_mode == "campaign" else current_mode.capitalize(), tr("game.score"), game_state.score], 19, true)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if world == 3:
		status_label.add_theme_color_override("font_color", Color.WHITE)
	top.add_child(status_label)
	var coins := _make_label("◉ %d" % int(SaveService.data["coins"]), 16, true)
	coins.custom_minimum_size = Vector2(82, 50)
	if world == 3:
		coins.add_theme_color_override("font_color", Color.WHITE)
	top.add_child(coins)
	column.add_child(top)
	priority_label = _make_label("", 15, true)
	priority_label.visible = not game_state.priority_destination.is_empty()
	priority_label.add_theme_stylebox_override("normal", _panel(COLORS.gold, 12))
	column.add_child(priority_label)
	board_control = Control.new()
	board_control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_control.custom_minimum_size.y = 380
	board_control.clip_contents = true
	column.add_child(board_control)
	var tray_panel := PanelContainer.new()
	tray_panel.add_theme_stylebox_override("panel", _panel(COLORS.paper, 18))
	var tray_column := VBoxContainer.new()
	tray_panel.add_child(tray_column)
	var tray_title := _make_label("%s  %d/%d" % [tr("game.tray"), game_state.tray.size(), game_state.tray_capacity], 15, true)
	tray_title.name = "TrayTitle"
	tray_column.add_child(tray_title)
	tray_row = HBoxContainer.new()
	tray_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tray_row.add_theme_constant_override("separation", 5)
	tray_row.custom_minimum_size.y = 50
	tray_column.add_child(tray_row)
	column.add_child(tray_panel)
	var booster_row := HBoxContainer.new()
	for booster in ["undo", "shuffle", "extra_slot"]:
		var count := int(SaveService.data["boosters"].get(booster, 0))
		var key := "booster.%s" % booster
		var button := _make_button("%s  ×%d" % [tr(key), count], func(id: String = booster) -> void: _use_booster(id), COLORS.mint)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = count <= 0 or (booster == "extra_slot" and game_state.extra_slot_active)
		button.add_theme_font_size_override("font_size", 13)
		booster_row.add_child(button)
	column.add_child(booster_row)
	tutorial_label = _make_label(_tutorial_text(), 14, true)
	tutorial_label.add_theme_stylebox_override("normal", _panel(Color("fff3c4"), 12))
	tutorial_label.visible = not tutorial_label.text.is_empty()
	column.add_child(tutorial_label)
	call_deferred("_refresh_gameplay_visuals")

func _refresh_gameplay_visuals() -> void:
	if not is_instance_valid(board_control) or not is_instance_valid(tray_row):
		return
	for child in board_control.get_children():
		child.queue_free()
	var visual_items: Array = game_state.items.values()
	visual_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("z_index", 0)) < int(b.get("z_index", 0)))
	for item: Dictionary in visual_items:
		if bool(item.get("removed", false)):
			continue
		var item_id := String(item["id"])
		var is_key := String(item.get("special_type", "")) == "key"
		var revealed := bool(item.get("revealed", true))
		var destination := String(item.get("destination_id", ""))
		var label := "🔑" if is_key else ("?\n???" if not revealed else "%s\n%s" % [DEST_SYMBOLS.get(destination, "◇"), DEST_CODES.get(destination, destination.to_upper())])
		if not String(item.get("lock_group", "")).is_empty() and String(item["lock_group"]) not in game_state.unlocked_groups:
			label = "🔒\n" + label
		var button := Button.new()
		button.text = label
		button.name = item_id
		button.custom_minimum_size = Vector2(88, 66)
		var color := COLORS.gold if is_key else Color(DEST_COLORS.get(destination, "718096"))
		button.add_theme_stylebox_override("normal", _panel(color, 15))
		button.add_theme_stylebox_override("hover", _panel(color.lightened(0.08), 15))
		button.add_theme_stylebox_override("pressed", _panel(color.darkened(0.10), 15))
		button.disabled = not game_state.is_selectable(item_id) or transition_locked
		button.modulate = Color.WHITE if not button.disabled else Color(0.75, 0.78, 0.82, 0.78)
		var point: Array = item.get("position", [0.5, 0.5])
		button.position = Vector2(float(point[0]) * maxi(1.0, board_control.size.x) - 44.0, float(point[1]) * maxi(1.0, board_control.size.y) - 33.0)
		button.rotation_degrees = float(item.get("rotation", 0.0))
		button.z_index = int(item.get("z_index", 0))
		button.pressed.connect(func() -> void: _select_luggage(item_id, button))
		board_control.add_child(button)
	for child in tray_row.get_children():
		child.queue_free()
	for destination: String in game_state.tray:
		var tag := Label.new()
		tag.text = "%s\n%s" % [DEST_SYMBOLS.get(destination, "◇"), DEST_CODES.get(destination, destination.to_upper())]
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tag.custom_minimum_size = Vector2(43, 44)
		tag.add_theme_font_size_override("font_size", 12)
		tag.add_theme_stylebox_override("normal", _panel(Color(DEST_COLORS.get(destination, "718096")), 10))
		tray_row.add_child(tag)
	for _slot in range(game_state.tray.size(), game_state.tray_capacity):
		var empty := Label.new()
		empty.text = "·"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(38, 44)
		empty.add_theme_stylebox_override("normal", _panel(Color("e7e5df"), 10))
		tray_row.add_child(empty)
	var title := tray_row.get_parent().get_node_or_null("TrayTitle") as Label
	if title:
		title.text = "%s  %d/%d" % [tr("game.tray"), game_state.tray.size(), game_state.tray_capacity]
	if status_label:
		status_label.text = "%s %s  •  %s %d" % [tr("game.level"), str(current_level) if current_mode == "campaign" else current_mode.capitalize(), tr("game.score"), game_state.score + endless_score]
	if priority_label and priority_label.visible:
		priority_label.text = "%s %s  •  %d %s" % [tr("game.priority"), DEST_CODES.get(game_state.priority_destination, game_state.priority_destination), game_state.priority_moves, tr("game.moves")]

func _select_luggage(item_id: String, button: Button) -> void:
	if transition_locked or not game_state.is_selectable(item_id):
		HapticsService.pulse(35, 0.25)
		return
	transition_locked = true
	game_state.phase = game_state.Phase.ANIMATING
	AudioService.play_sfx("pickup")
	HapticsService.pulse()
	var reduced := bool(SaveService.data["settings"].get("reduced_motion", false))
	if not reduced:
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(button, "scale", Vector2(0.82, 0.82), 0.10)
		tween.tween_property(button, "modulate:a", 0.25, 0.16)
		await tween.finished
	game_state.phase = game_state.Phase.PLAYING
	var event: Dictionary = game_state.select_item(item_id)
	if int(event.get("matches", 0)) > 0:
		AudioService.play_sfx("match")
		HapticsService.pulse(45, 0.6)
		await _play_match_juice()
	elif bool(event.get("key", false)):
		AudioService.play_sfx("unlock")
	transition_locked = false
	if bool(event.get("won", false)):
		_on_level_won()
	elif bool(event.get("lost", false)):
		_on_level_lost(String(event.get("loss_reason", "tray")))
	else:
		build_gameplay_screen()

func _use_booster(booster: String) -> void:
	if transition_locked or game_state.phase != game_state.Phase.PLAYING:
		return
	if not SaveService.spend_booster(booster):
		return
	var success := false
	match booster:
		"undo": success = game_state.undo()
		"shuffle": success = game_state.shuffle_remaining()
		"extra_slot": success = game_state.activate_extra_slot()
	if not success:
		SaveService.add_booster(booster)
	else:
		AudioService.play_sfx("booster")
		LocalAnalytics.log_event("booster_used", {"booster": booster, "level": current_level})
	build_gameplay_screen()

func _on_level_won() -> void:
	AudioService.play_sfx("win")
	HapticsService.pulse(90, 0.8)
	if current_mode == "endless":
		endless_score += game_state.score
		SaveService.data["endless"]["high_score"] = maxi(int(SaveService.data["endless"].get("high_score", 0)), endless_score)
		SaveService.save_profile()
		endless_round += 1
		show_result(true)
		return
	var stars := 3 if game_state.boosters_used <= 1 and game_state.peak_tray <= 5 and not continue_used else 2 if game_state.boosters_used <= 2 and not continue_used else 1
	var reward := 40 + stars * 10 + (15 if game_state.priority_completed and not game_state.priority_destination.is_empty() else 0)
	if current_mode == "campaign":
		SaveService.complete_level(current_level, stars, game_state.score, reward)
		if current_level in [1, 2, 3, 31, 61, 91]:
			SaveService.data["tutorials"][str(current_level)] = true
			SaveService.save_profile()
	else:
		var date := Time.get_date_string_from_system()
		if String(SaveService.data["daily"].get("last_rewarded_date", "")) != date:
			SaveService.data["daily"]["streak"] = _updated_streak(date)
			SaveService.data["daily"]["last_rewarded_date"] = date
			SaveService.data["coins"] = int(SaveService.data["coins"]) + reward
		SaveService.data["daily"]["best_scores"][date] = maxi(game_state.score, int(SaveService.data["daily"]["best_scores"].get(date, 0)))
		SaveService.save_profile()
	LocalAnalytics.log_event("level_win", {"level": current_level, "score": game_state.score, "stars": stars})
	show_result(true, stars, reward)

func _on_level_lost(reason: String) -> void:
	AudioService.play_sfx("lose")
	LocalAnalytics.log_event("level_fail", {"level": current_level, "reason": reason, "tray_peak": game_state.peak_tray})
	show_result(false)

func show_result(won: bool, stars: int = 0, reward: int = 0) -> void:
	current_screen = "result"
	var column := _screen_base(Color("dff3f4") if won else Color("f5dddd"))
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon := _make_label("✦" if won else "!", 68, true)
	column.add_child(icon)
	column.add_child(_make_label(tr("game.win") if won else tr("game.lose"), 30, true))
	if won:
		if current_mode == "endless":
			column.add_child(_make_label("%s %d  •  Round %d" % [tr("game.score"), endless_score, endless_round - 1], 20, true))
		else:
			column.add_child(_make_label("%s\n%s %d  •  %s +%d\n%s %d" % ["★".repeat(stars), tr("game.score"), game_state.score, tr("game.coins"), reward, tr("game.level"), current_level], 20, true))
		var next_action := _start_endless_round if current_mode == "endless" else (func() -> void: start_campaign_level(mini(150, current_level + 1))) if current_mode == "campaign" else show_home
		column.add_child(_make_button(tr("menu.continue"), next_action, COLORS.coral))
		column.add_child(_make_button(tr("menu.retry"), _retry_current, COLORS.paper))
	else:
		var reason := tr("game.priority_failed") if game_state.loss_reason == "priority" else tr("game.tray_full")
		column.add_child(_make_label(reason, 20, true))
		if not continue_used and AdService.is_rewarded_available():
			column.add_child(_make_button("▶  +1 slot & %s" % tr("menu.continue"), _rewarded_continue, COLORS.gold))
		column.add_child(_make_button(tr("menu.retry"), _retry_current, COLORS.coral))
	column.add_child(_make_button(tr("menu.home"), show_home, COLORS.paper))

func _rewarded_continue() -> void:
	AdService.show_rewarded()
	var result: String = await AdService.rewarded
	if result == "reward":
		continue_used = true
		game_state.tray_capacity += 1
		game_state.phase = game_state.Phase.PLAYING
		game_state.loss_reason = ""
		build_gameplay_screen()
	else:
		_show_notice("Reward was not granted")

func _retry_current() -> void:
	if current_mode == "campaign":
		start_campaign_level(current_level)
	elif current_mode == "daily":
		show_daily()
	else:
		endless_round = maxi(1, endless_round - 1)
		_start_endless_round()

func show_pause() -> void:
	if transition_locked:
		return
	game_state.phase = game_state.Phase.PAUSED
	current_screen = "pause"
	var column := _screen_base(Color("dfe7ef"))
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(_make_label("Paused", 32, true))
	column.add_child(_make_button(tr("menu.resume"), func() -> void: game_state.phase = game_state.Phase.PLAYING; build_gameplay_screen(), COLORS.coral))
	column.add_child(_make_button(tr("menu.retry"), _retry_current, COLORS.paper))
	column.add_child(_make_button(tr("menu.home"), show_home, COLORS.paper))

func show_airport() -> void:
	current_screen = "airport"
	var column := _screen_base(Color("e8f1e8"))
	_header(column, tr("airport.title"))
	var world := clampi(int((int(SaveService.data["current_level"]) - 1) / 30) + 1, 1, 5)
	var progress: Dictionary = SaveService.data["airport_progress"].get(str(world), {})
	var stages := 0
	for object_id in AIRPORT_OBJECTS:
		stages += int(progress.get(object_id, 0))
	column.add_child(_make_label("%s %d  •  %s %d%%" % [WORLD_NAMES[world - 1], world, tr("airport.progress"), int(float(stages) / 18.0 * 100.0)], 18, true))
	var scene_panel := PanelContainer.new()
	scene_panel.custom_minimum_size.y = 180
	scene_panel.add_theme_stylebox_override("panel", _panel(Color("c7e6ee"), 22))
	var skyline := HBoxContainer.new()
	skyline.alignment = BoxContainer.ALIGNMENT_CENTER
	for object_id in AIRPORT_OBJECTS:
		var stage := int(progress.get(object_id, 0))
		var preview := TextureRect.new()
		preview.custom_minimum_size = Vector2(55, 120)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.texture = load("res://assets/art/airport/%s_%d.svg" % [object_id, stage])
		preview.tooltip_text = tr("airport.%s" % object_id)
		skyline.add_child(preview)
	scene_panel.add_child(skyline)
	column.add_child(scene_panel)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for object_id in AIRPORT_OBJECTS:
		var stage := int(progress.get(object_id, 0))
		var text := "%s  %s" % [tr("airport.%s" % object_id), "★".repeat(stage) + "☆".repeat(3 - stage)]
		if stage < 3:
			text += "\n◉ %d" % (AIRPORT_COSTS[stage] * world)
		var button := _make_button(text, func(id: String = object_id) -> void:
			if SaveService.purchase_airport_upgrade(world, id, AIRPORT_COSTS):
				AudioService.play_sfx("renovation")
				HapticsService.pulse(70, 0.7)
			show_airport(), COLORS.paper)
		button.custom_minimum_size = Vector2(0, 78)
		grid.add_child(button)
	column.add_child(grid)

func show_settings() -> void:
	current_screen = "settings"
	var column := _screen_base(Color("edf0f7"))
	_header(column, tr("menu.settings"))
	var settings: Dictionary = SaveService.data["settings"]
	for entry in [["master_sound", "settings.sound"], ["music", "settings.music"], ["sfx", "settings.sfx"], ["haptics", "settings.haptics"], ["reduced_motion", "settings.motion"]]:
		var toggle := CheckButton.new()
		toggle.text = tr(entry[1])
		toggle.button_pressed = bool(settings.get(entry[0], true))
		toggle.custom_minimum_size.y = 52
		toggle.toggled.connect(func(value: bool, key: String = String(entry[0])) -> void:
			SaveService.data["settings"][key] = value
			SaveService.save_profile()
			AudioService.apply_settings())
		column.add_child(toggle)
	column.add_child(_make_button("%s: %s" % [tr("settings.language"), "Українська" if TranslationServer.get_locale().begins_with("uk") else "English"], _toggle_language, COLORS.paper))
	column.add_child(_make_button(tr("settings.text"), _toggle_text_scale, COLORS.paper))
	column.add_child(_make_button(tr("settings.replay"), func() -> void: SaveService.data["tutorials"] = {}; SaveService.save_profile(), COLORS.paper))
	if OS.is_debug_build():
		column.add_child(_make_button("Developer tools", show_debug_menu, Color("ffdca8")))

func show_debug_menu() -> void:
	if not OS.is_debug_build():
		show_home()
		return
	current_screen = "debug"
	var column := _screen_base(Color("f5e6cf"))
	_header(column, "Developer tools")
	column.add_child(_make_label("FPS %d  •  seed %d  •  state %s" % [Engine.get_frames_per_second(), game_state.seed_value, game_state.Phase.keys()[game_state.phase]], 14, true))
	var level_row := HBoxContainer.new()
	var picker := SpinBox.new()
	picker.min_value = 1
	picker.max_value = 150
	picker.value = clampi(current_level, 1, 150)
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_row.add_child(picker)
	level_row.add_child(_make_button("Load campaign level", func() -> void: start_campaign_level(int(picker.value)), COLORS.coral))
	column.add_child(level_row)
	var grid := GridContainer.new()
	grid.columns = 2
	for entry in [
		["+500 coins", func() -> void: SaveService.data["coins"] = int(SaveService.data["coins"]) + 500; SaveService.save_profile(); show_debug_menu()],
		["+3 boosters", func() -> void: SaveService.add_booster("undo", 3); SaveService.add_booster("shuffle", 3); SaveService.add_booster("extra_slot", 3); show_debug_menu()],
		["Reset tutorials", func() -> void: SaveService.data["tutorials"] = {}; SaveService.save_profile(); show_debug_menu()],
		["Clear save", func() -> void: SaveService.reset_profile(); show_debug_menu()],
		["Cycle mock ad", func() -> void: AdService.mode = (int(AdService.mode) + 1) % AdService.Mode.size(); show_debug_menu()],
		["Force win", func() -> void: game_state.phase = game_state.Phase.WON; show_result(true, 3, 0)],
		["Force tray loss", func() -> void: game_state.phase = game_state.Phase.LOST; game_state.loss_reason = "tray"; show_result(false)],
		["Inspect blockers", _debug_show_blockers],
		["Solve current", _debug_solve_current],
		["Open airport", show_airport],
		["Daily today", show_daily]
	]:
		var button := _make_button(entry[0], entry[1], COLORS.paper)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 13)
		grid.add_child(button)
	column.add_child(grid)

func _debug_show_blockers() -> void:
	var lines: Array[String] = []
	for item_id: String in game_state.items:
		var item: Dictionary = game_state.items[item_id]
		if not bool(item.get("removed", false)):
			lines.append("%s <- %s" % [item_id, ",".join(item.get("blocker_ids", []))])
	_show_notice("\n".join(lines.slice(0, 12)) if not lines.is_empty() else "No active board")

func _debug_solve_current() -> void:
	if game_state.items.is_empty():
		_show_notice("No active board")
		return
	var definition := {"id": game_state.level_id, "seed": game_state.seed_value, "tray_capacity": game_state.base_capacity, "items": game_state.items.values(), "mechanics": {"priority": {"destination_id": game_state.priority_destination, "moves": game_state.priority_moves} if not game_state.priority_destination.is_empty() else {}}}
	var result: Dictionary = SolverScript.new().solve_level(definition)
	_show_notice("solved=%s nodes=%d depth=%d ms=%d\n%s" % [result["solved"], result["nodes"], result["max_depth"], result["solve_ms"], ", ".join(result["solution"].slice(0, 10))])

func _play_match_juice() -> void:
	if bool(SaveService.data["settings"].get("reduced_motion", false)):
		return
	var layer := Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	for index in 10:
		var dot := ColorRect.new()
		dot.color = [COLORS.coral, COLORS.gold, COLORS.mint, COLORS.blue][index % 4]
		dot.size = Vector2(9, 9)
		dot.position = size * Vector2(0.5, 0.62)
		layer.add_child(dot)
		var angle := TAU * float(index) / 10.0
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(dot, "position", dot.position + Vector2(cos(angle), sin(angle)) * 75.0, 0.18)
		tween.tween_property(dot, "modulate:a", 0.0, 0.18)
	await get_tree().create_timer(0.19).timeout
	layer.queue_free()

func _toggle_language() -> void:
	var language := "en" if TranslationServer.get_locale().begins_with("uk") else "uk"
	SaveService.data["settings"]["language"] = language
	SaveService.save_profile()
	TranslationServer.set_locale(language)
	show_settings()

func _toggle_text_scale() -> void:
	var scale := float(SaveService.data["settings"].get("text_scale", 1.0))
	SaveService.data["settings"]["text_scale"] = 1.2 if scale < 1.1 else 1.0
	SaveService.save_profile()
	_apply_theme()
	show_settings()

func show_credits() -> void:
	current_screen = "credits"
	var column := _screen_base(Color("f7f1e6"))
	_header(column, tr("menu.credits"))
	column.add_child(_make_label("Lost & Sorted\nVersion 1.0.0 (1)\n\nCreated with Godot Engine 4.7.2\nOriginal SVG art and procedural audio included in this repository.\nNo third-party runtime packages are bundled.", 17, true))
	var privacy := _make_label(tr("privacy.summary") + "\n\nSee docs/privacy-policy.html before publication. Publisher contact fields must be configured.", 16, true)
	privacy.add_theme_stylebox_override("normal", _panel(COLORS.paper, 18))
	privacy.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(privacy)

func _tutorial_text() -> String:
	if current_mode != "campaign":
		return ""
	if bool(SaveService.data["tutorials"].get(str(current_level), false)):
		return ""
	match current_level:
		1: return tr("tutorial.tap") + "\n" + tr("tutorial.match")
		2: return tr("tutorial.covered")
		3: return tr("tutorial.tray")
		31: return tr("tutorial.mystery")
		61: return tr("tutorial.key")
		91: return tr("tutorial.priority")
	return ""

func _updated_streak(current_date: String) -> int:
	var current := int(SaveService.data["daily"].get("streak", 0))
	var previous := String(SaveService.data["daily"].get("last_rewarded_date", ""))
	if previous.is_empty():
		return 1
	var previous_unix := Time.get_unix_time_from_datetime_string(previous + "T00:00:00")
	var current_unix := Time.get_unix_time_from_datetime_string(current_date + "T00:00:00")
	return mini(7, current + 1) if current_unix - previous_unix == 86400 else 1

func _show_notice(message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = tr("app.title")
	add_child(dialog)
	dialog.popup_centered(Vector2i(330, 170))

func _go_back() -> void:
	show_home()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current_screen == "gameplay":
			show_pause()
		elif current_screen == "pause":
			game_state.phase = game_state.Phase.PLAYING
			build_gameplay_screen()
		elif current_screen != "home":
			show_home()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and current_screen == "gameplay" and game_state.phase == game_state.Phase.PLAYING:
		game_state.phase = game_state.Phase.PAUSED
		call_deferred("show_pause")

func _capture_store_screens() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://store/screenshots"))
	var captures: Array = [
		["home", Callable(self, "show_home")],
		["campaign", Callable(self, "show_campaign")],
		["gameplay", func() -> void: start_campaign_level(31)],
		["airport", Callable(self, "show_airport")],
		["daily", Callable(self, "show_daily")]
	]
	for capture in captures:
		capture[1].call()
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		image.save_png("res://store/screenshots/%s.png" % capture[0])
	print("SCREENSHOTS PASS: home, campaign, gameplay, airport, daily")
	get_tree().quit()
