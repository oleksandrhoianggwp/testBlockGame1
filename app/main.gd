extends Control

const GameStateScript = preload("res://core/gameplay/game_state.gd")
const GeneratorScript = preload("res://core/generation/level_generator.gd")
const DEST_CODES := {"par":"PAR", "tyo":"TYO", "iev":"IEV", "rom":"ROM", "cai":"CAI", "sel":"SEL", "syd":"SYD", "rio":"RIO", "osl":"OSL", "yto":"YTO", "lim":"LIM", "nbo":"NBO"}
const AIRPORT_ZONES := ["entrance", "checkin", "baggage", "security", "cafe", "tower", "runway"]
const AIRPORT_COSTS := [100, 150, 220]

var game_state = GameStateScript.new()
var generator = GeneratorScript.new()
var current_screen: String = "home"
var current_mode: String = "campaign"
var current_level: int = 1
var current_definition: Dictionary = {}
var current_screen_node: Control
var gameplay_screen: GameplayScreen
var transition_locked: bool = false
var free_undo_available: bool = false
var mystery_reveal_available: bool = false
var continue_used: bool = false
var last_result_won: bool = false
var last_stars: int = 0
var last_reward: int = 0

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
	app_theme.set_color("font_color", "Label", UiKit.INK)
	app_theme.set_color("font_color", "Button", UiKit.INK)
	theme = app_theme

func _show_screen(node: Control, screen_id: String) -> void:
	current_screen = screen_id
	if is_instance_valid(current_screen_node):
		current_screen_node.queue_free()
	current_screen_node = node
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(node)

func show_home() -> void:
	var screen := HomeScreen.new()
	var world := int(generator.world_for_level(int(SaveService.data.get("current_level", 1))).get("id", 1))
	screen.setup(SaveService.data, world)
	screen.route_requested.connect(_on_home_route)
	_show_screen(screen, "home")
	LocalAnalytics.log_event("screen", {"name": "home"})

func _on_home_route(route: String) -> void:
	AudioService.play_sfx("button")
	match route:
		"continue": start_campaign_level(int(SaveService.data.get("current_level", 1)))
		"play": show_campaign()
		"daily": start_daily()
		"airport": show_airport()
		"shift": show_shift()
		"settings": show_settings()

func show_campaign() -> void:
	var screen := CampaignScreen.new()
	screen.setup(SaveService.data, generator.campaign_config())
	screen.back_requested.connect(show_home)
	screen.level_selected.connect(start_campaign_level)
	_show_screen(screen, "campaign")

func start_campaign_level(level_id: int) -> void:
	current_mode = "campaign"
	current_level = clampi(level_id, 1, generator.campaign_count())
	continue_used = false
	var seed_value := SaveService.campaign_seed(current_level)
	var parameters := generator.campaign_parameters(current_level, seed_value)
	current_definition = generator.generate_level(parameters)
	_load_gameplay(current_definition)

func start_daily() -> void:
	current_mode = "daily"
	current_level = 10000
	continue_used = false
	var date := Time.get_date_string_from_system()
	SaveService.data["daily"]["last_played_date"] = date
	SaveService.save_profile()
	current_definition = generator.generate_daily(date, "lost-sorted-v2-daily")
	_load_gameplay(current_definition)

func show_shift() -> void:
	var screen := ShiftScreen.new()
	screen.setup(SaveService.data)
	screen.back_requested.connect(show_home)
	screen.start_requested.connect(_start_or_resume_shift)
	_show_screen(screen, "shift")

func _start_or_resume_shift() -> void:
	if int(SaveService.data["shift"].get("active_seed", 0)) <= 0:
		SaveService.begin_shift()
	current_mode = "shift"
	current_level = 20000 + maxi(1, int(SaveService.data["shift"].get("round", 1)))
	continue_used = false
	_start_shift_round()

func _start_shift_round() -> void:
	var run_seed := int(SaveService.data["shift"].get("active_seed", 0))
	if run_seed <= 0:
		run_seed = SaveService.begin_shift()
	var round_number := maxi(1, int(SaveService.data["shift"].get("round", 1)))
	current_level = 20000 + round_number
	current_definition = generator.generate_shift(run_seed, round_number)
	_load_gameplay(current_definition)

func _load_gameplay(definition: Dictionary) -> void:
	game_state.load_level(definition)
	var perks: Dictionary = SaveService.data.get("airport_perks", {})
	if not game_state.priority_destination.is_empty():
		game_state.priority_moves += int(perks.get("priority_move", 0))
	free_undo_available = int(perks.get("undo_charge", 0)) > 0
	mystery_reveal_available = int(perks.get("mystery_reveal", 0)) > 0
	transition_locked = false
	var title_text := "%s %d" % [tr("game.level"), current_level]
	if current_mode == "daily":
		title_text = tr("menu.daily")
	elif current_mode == "shift":
		title_text = "%s %d" % [tr("shift.round"), int(definition.get("shift_round", 1))]
	gameplay_screen = GameplayScreen.new()
	gameplay_screen.setup(definition, game_state, SaveService.data, title_text)
	gameplay_screen.set_runtime_perks(free_undo_available, mystery_reveal_available)
	gameplay_screen.luggage_requested.connect(_on_luggage_requested)
	gameplay_screen.booster_requested.connect(_use_booster)
	gameplay_screen.pause_requested.connect(_show_pause)
	_show_screen(gameplay_screen, "gameplay")
	LocalAnalytics.log_event("level_start", {"level": current_level, "seed": game_state.seed_value, "mode": current_mode, "quality": definition.get("quality", {})})

func _on_luggage_requested(item_id: String, view: LuggageView) -> void:
	if transition_locked or not game_state.is_selectable(item_id):
		HapticsService.pulse(30, 0.25)
		return
	var options := game_state.destination_options(item_id)
	if String(game_state.items[item_id].get("special_type", "")) == "transfer" and options.size() > 1:
		var chooser := PopupMenu.new()
		chooser.title = tr("transfer.choose")
		for index in options.size():
			var destination := String(options[index])
			chooser.add_item("%s  %s" % [DEST_CODES.get(destination, destination.to_upper()), tr("destination.%s" % _destination_name_key(destination))], index)
		chooser.id_pressed.connect(func(index: int) -> void:
			_commit_luggage(item_id, view, String(options[index]))
			chooser.queue_free())
		chooser.popup_hide.connect(func() -> void:
			if is_instance_valid(chooser): chooser.queue_free())
		add_child(chooser)
		chooser.position = Vector2i(int(size.x * 0.5 - 120), int(size.y * 0.55))
		chooser.popup(Rect2i(chooser.position, Vector2i(240, 110)))
		return
	_commit_luggage(item_id, view, String(options[0]) if not options.is_empty() else "")

func _commit_luggage(item_id: String, view: LuggageView, destination: String) -> void:
	if transition_locked:
		return
	transition_locked = true
	game_state.phase = game_state.Phase.ANIMATING
	AudioService.play_sfx("pickup")
	HapticsService.pulse()
	await gameplay_screen.animate_pickup(view, bool(SaveService.data["settings"].get("reduced_motion", false)))
	game_state.phase = game_state.Phase.PLAYING
	var event: Dictionary = game_state.select_item(item_id, destination)
	if not bool(event.get("ok", false)):
		transition_locked = false
		gameplay_screen.finish_transition()
		return
	if int(event.get("matches", 0)) > 0:
		AudioService.play_sfx("match")
		HapticsService.pulse(50, 0.65)
		await gameplay_screen.play_match_juice(bool(SaveService.data["settings"].get("reduced_motion", false)), game_state.combo)
	elif bool(event.get("key", false)):
		AudioService.play_sfx("unlock")
	transition_locked = false
	if bool(event.get("won", false)):
		_on_level_won()
	elif bool(event.get("lost", false)):
		_on_level_lost(String(event.get("loss_reason", "tray")))
	else:
		gameplay_screen.finish_transition()

func _use_booster(booster: String) -> void:
	if transition_locked or game_state.phase != game_state.Phase.PLAYING:
		return
	var success := false
	var paid := false
	if booster == "reveal":
		if mystery_reveal_available:
			success = game_state.reveal_one_mystery()
			mystery_reveal_available = not success
	else:
		var use_free := booster == "undo" and free_undo_available
		if not use_free:
			paid = SaveService.spend_booster(booster)
			if not paid:
				return
		match booster:
			"undo": success = game_state.undo()
			"shuffle": success = game_state.shuffle_remaining()
			"extra_slot": success = game_state.activate_extra_slot()
		if success and use_free:
			free_undo_available = false
	if not success and paid:
		SaveService.add_booster(booster)
	elif success:
		AudioService.play_sfx("booster")
		LocalAnalytics.log_event("booster_used", {"booster": booster, "level": current_level})
	gameplay_screen.profile = SaveService.data
	gameplay_screen.set_runtime_perks(free_undo_available, mystery_reveal_available)
	gameplay_screen.refresh()

func _on_level_won() -> void:
	AudioService.play_sfx("win")
	HapticsService.pulse(90, 0.8)
	last_result_won = true
	last_stars = 3 if game_state.boosters_used <= 1 and game_state.peak_tray <= 5 and not continue_used else 2 if game_state.boosters_used <= 2 else 1
	last_reward = 40 + last_stars * 10 + (15 if game_state.priority_completed and not game_state.priority_destination.is_empty() else 0)
	if current_mode == "campaign":
		SaveService.complete_level(current_level, last_stars, game_state.score, last_reward, generator.campaign_count())
	elif current_mode == "daily":
		_reward_daily(last_reward)
	else:
		var event_id := String(current_definition.get("shift_event", ""))
		var event_bonus := 35 if event_id == "vip_baggage" and game_state.vip_completed and game_state.boosters_used == 0 else 0
		last_reward += event_bonus
		SaveService.data["coins"] = int(SaveService.data["coins"]) + last_reward
		SaveService.advance_shift(game_state.score, event_id)
	LocalAnalytics.log_event("level_win", {"level": current_level, "score": game_state.score, "stars": last_stars})
	show_result(true, "")

func _reward_daily(reward: int) -> void:
	var date := Time.get_date_string_from_system()
	if String(SaveService.data["daily"].get("last_rewarded_date", "")) != date:
		SaveService.data["daily"]["streak"] = _updated_streak(date)
		SaveService.data["daily"]["last_rewarded_date"] = date
		SaveService.data["coins"] = int(SaveService.data["coins"]) + reward
		SaveService.data["daily"]["best_scores"][date] = maxi(game_state.score, int(SaveService.data["daily"]["best_scores"].get(date, 0)))
		SaveService.save_profile()

func _on_level_lost(reason: String) -> void:
	AudioService.play_sfx("lose")
	last_result_won = false
	last_stars = 0
	last_reward = 0
	LocalAnalytics.log_event("level_fail", {"level": current_level, "reason": reason, "tray_peak": game_state.peak_tray})
	show_result(false, reason)

func show_result(won: bool, reason: String) -> void:
	var screen := ResultScreen.new()
	var percent := _airport_progress_percent()
	var challenge_complete: bool = (game_state.priority_completed and not game_state.priority_destination.is_empty()) or (game_state.vip_completed and not game_state.vip_destination.is_empty())
	screen.setup(won, current_mode, last_stars, last_reward, game_state.score, reason, percent, challenge_complete)
	screen.action_requested.connect(_on_result_action)
	_show_screen(screen, "result")

func _on_result_action(action: String) -> void:
	match action:
		"home":
			if current_mode == "shift" and not last_result_won:
				SaveService.end_shift()
			show_home()
		"retry":
			if current_mode == "campaign" and last_result_won:
				start_campaign_level(current_level)
			elif current_mode == "shift" and last_result_won:
				_start_shift_round()
			else:
				_load_gameplay(current_definition)
		"continue":
			if current_mode == "campaign":
				if current_level < generator.campaign_count():
					start_campaign_level(current_level + 1)
				else:
					show_home()
			elif current_mode == "shift":
				_start_shift_round()
			else:
				show_home()

func _show_pause() -> void:
	if transition_locked:
		return
	game_state.phase = game_state.Phase.PAUSED
	var dialog := ConfirmationDialog.new()
	dialog.title = tr("pause.title")
	dialog.dialog_text = tr("pause.message")
	dialog.ok_button_text = tr("menu.resume")
	dialog.cancel_button_text = tr("menu.home")
	dialog.add_button(tr("menu.retry"), false, "retry")
	dialog.confirmed.connect(func() -> void:
		game_state.phase = game_state.Phase.PLAYING
		gameplay_screen.refresh())
	dialog.canceled.connect(func() -> void: show_home())
	dialog.custom_action.connect(func(action: StringName) -> void:
		if String(action) == "retry":
			dialog.hide()
			_load_gameplay(current_definition))
	dialog.tree_exited.connect(func() -> void:
		if current_screen == "gameplay" and game_state.phase == game_state.Phase.PAUSED:
			game_state.phase = game_state.Phase.PLAYING
			gameplay_screen.refresh())
	add_child(dialog)
	dialog.popup_centered(Vector2i(320, 220))

func show_airport() -> void:
	var world := int(generator.world_for_level(int(SaveService.data.get("current_level", 1))).get("id", 1))
	var screen := AirportScreen.new()
	screen.setup(SaveService.data, world)
	screen.back_requested.connect(show_home)
	screen.upgrade_requested.connect(func(world_id: int, zone: String) -> void:
		if SaveService.purchase_airport_upgrade(world_id, zone, AIRPORT_COSTS):
			AudioService.play_sfx("renovation")
			HapticsService.pulse(70, 0.7)
		show_airport())
	_show_screen(screen, "airport")

func show_settings() -> void:
	var screen := SettingsScreen.new()
	screen.setup(SaveService.data)
	screen.back_requested.connect(show_home)
	screen.setting_changed.connect(func(key: String, value: Variant) -> void:
		SaveService.data["settings"][key] = value
		SaveService.save_profile()
		AudioService.apply_settings()
		if key == "text_scale":
			_apply_theme()
			show_settings())
	screen.language_requested.connect(_toggle_language)
	screen.tutorials_requested.connect(func() -> void:
		SaveService.data["tutorials"] = {}
		SaveService.save_profile())
	_show_screen(screen, "settings")

func _toggle_language() -> void:
	var language := "en" if TranslationServer.get_locale().begins_with("uk") else "uk"
	SaveService.data["settings"]["language"] = language
	SaveService.save_profile()
	TranslationServer.set_locale(language)
	show_settings()

func _destination_name_key(destination: String) -> String:
	return {"par":"paris", "tyo":"tokyo", "iev":"kyiv", "rom":"rome", "cai":"cairo", "sel":"seoul", "syd":"sydney", "rio":"rio", "osl":"oslo", "yto":"toronto", "lim":"lima", "nbo":"nairobi"}.get(destination, destination)

func _airport_progress_percent() -> int:
	var world := int(generator.world_for_level(clampi(current_level, 1, generator.campaign_count())).get("id", 1))
	var progress: Dictionary = SaveService.data.get("airport_progress", {}).get(str(world), {})
	var stages := 0
	for zone in AIRPORT_ZONES:
		stages += int(progress.get(zone, 0))
	return int(float(stages) / 21.0 * 100.0)

func _updated_streak(current_date: String) -> int:
	var current := int(SaveService.data["daily"].get("streak", 0))
	var previous := String(SaveService.data["daily"].get("last_rewarded_date", ""))
	if previous.is_empty():
		return 1
	var previous_unix := Time.get_unix_time_from_datetime_string(previous + "T00:00:00")
	var current_unix := Time.get_unix_time_from_datetime_string(current_date + "T00:00:00")
	return mini(7, current + 1) if current_unix - previous_unix == 86400 else 1

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current_screen == "gameplay":
			_show_pause()
		elif current_screen != "home":
			show_home()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and current_screen == "gameplay" and game_state.phase == game_state.Phase.PLAYING:
		call_deferred("_show_pause")

func _capture_store_screens() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://store/screenshots"))
	var captures: Array = [
		["home", Callable(self, "show_home")],
		["campaign", Callable(self, "show_campaign")],
		["gameplay", func() -> void: start_campaign_level(20)],
		["airport", Callable(self, "show_airport")],
		["daily", Callable(self, "start_daily")]
	]
	for capture in captures:
		capture[1].call()
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://store/screenshots/%s.png" % capture[0])
	print("SCREENSHOTS PASS: home, campaign, gameplay, airport, daily")
	get_tree().quit()
