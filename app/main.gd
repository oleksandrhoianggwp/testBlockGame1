extends Control

const GameStateScript = preload("res://core/gameplay/game_state.gd")
const GeneratorScript = preload("res://core/generation/level_generator.gd")
const DEST_CODES := {"par":"PAR", "tyo":"TYO", "iev":"IEV", "rom":"ROM", "cai":"CAI", "sel":"SEL", "syd":"SYD", "rio":"RIO", "osl":"OSL", "yto":"YTO", "lim":"LIM", "nbo":"NBO"}
const AIRPORT_ZONES := ["entrance", "checkin", "baggage", "security", "cafe", "tower", "runway"]

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
var tutorial_queue: Array[Dictionary] = []
var active_tutorial: String = ""

func _ready() -> void:
	if "--capture-screens" in OS.get_cmdline_user_args() or "--qa-flow" in OS.get_cmdline_user_args():
		SaveService.persistence_enabled = false
		SaveService.data = SaveService.defaults()
		SaveService.data["settings"]["language"] = "en" if "--english" in OS.get_cmdline_user_args() else "uk"
		if "--large-text" in OS.get_cmdline_user_args(): SaveService.data["settings"]["text_scale"] = 1.2
		if "--capture-screens" in OS.get_cmdline_user_args():
			SaveService.data["current_level"] = 23
			SaveService.data["coins"] = 670
			SaveService.data["airport"] = {"entrance":2,"checkin":1,"baggage":2,"security":1,"cafe":2,"tower":1,"runway":1}
			if "--fully-upgraded" in OS.get_cmdline_user_args():
				for zone: String in AIRPORT_ZONES: SaveService.data["airport"][zone] = 3
			SaveService.data["shift"].merge({"active_seed":424242,"round":4,"earnings":350,"awaiting_decision":true,"high_score":1850},true)
			for id in ["pickup","match","blocking","tray","mystery","locks","priority","transfer"]: SaveService.complete_tutorial(id,false)
	_apply_locale()
	_apply_theme()
	AudioService.apply_settings()
	show_home()
	if "--capture-screens" in OS.get_cmdline_user_args():
		call_deferred("_capture_store_screens")
	if "--qa-flow" in OS.get_cmdline_user_args():
		call_deferred("_qa_player_flow")

func _apply_locale() -> void:
	var language := String(SaveService.data.get("settings", {}).get("language", ""))
	if language.is_empty():
		language = "uk" if OS.get_locale_language() == "uk" else "en"
	TranslationServer.set_locale(language)

func _apply_theme() -> void:
	UiKit.text_scale = float(SaveService.data["settings"].get("text_scale", 1.0))
	UiKit.reduced_motion = bool(SaveService.data["settings"].get("reduced_motion", false))
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
		"play", "campaign": show_campaign()
		"daily": show_daily()
		"airport": show_airport()
		"shift": show_shift()
		"settings": show_settings()

func show_campaign() -> void:
	var screen := CampaignScreen.new()
	screen.setup(SaveService.data, generator.campaign_config())
	screen.back_requested.connect(show_home)
	screen.level_selected.connect(start_campaign_level)
	screen.route_requested.connect(_on_home_route)
	_show_screen(screen, "campaign")

func start_campaign_level(level_id: int) -> void:
	current_mode = "campaign"
	current_level = clampi(level_id, 1, generator.campaign_count())
	continue_used = false
	var seed_value := SaveService.campaign_seed(current_level)
	var parameters := generator.campaign_parameters(current_level, seed_value)
	current_definition = await _generate(parameters)
	if current_definition.is_empty(): return
	_load_gameplay(current_definition)

func _generate(parameters: Dictionary) -> Dictionary:
	var loading := Control.new()
	var safe := UiKit.screen_background(loading, UiKit.SKY)
	var text := UiKit.label(tr("game.preparing"), 22, true)
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	safe.add_child(text)
	_show_screen(loading, "loading")
	await get_tree().process_frame
	var worker := Thread.new()
	if parameters.has("run_seed"):
		worker.start(generator.generate_shift.bind(int(parameters["run_seed"]), int(parameters["round"])))
	else:
		worker.start(generator.generate_level.bind(parameters))
	while worker.is_alive():
		await get_tree().process_frame
	var definition: Dictionary = worker.wait_to_finish()
	if definition.get("generation_failed", false):
		UiKit.toast(loading, tr("game.generation_retry"))
		var widened := parameters.duplicate(true)
		widened["retry_budget"] = 384
		worker = Thread.new()
		if parameters.has("run_seed"):
			worker.start(generator.generate_shift.bind(int(parameters["run_seed"]), int(parameters["round"]),384))
		else:
			worker.start(generator.generate_level.bind(widened))
		while worker.is_alive(): await get_tree().process_frame
		definition = worker.wait_to_finish()
		if definition.get("generation_failed", false):
			show_home()
			UiKit.toast(current_screen_node, tr("game.generation_failed"))
			return {}
	return definition

func show_daily() -> void:
	var screen := DailyScreen.new()
	screen.setup(SaveService.data, Time.get_date_string_from_system())
	screen.back_requested.connect(show_home)
	screen.start_requested.connect(start_daily)
	_show_screen(screen, "daily")

func start_daily() -> void:
	current_mode = "daily"
	current_level = 10000
	continue_used = false
	var date := Time.get_date_string_from_system()
	SaveService.data["daily"]["last_played_date"] = date
	SaveService.save_profile()
	var seed_value := int(hash(date + "lost-sorted-v3-daily")) & 0x7fffffff
	var parameters: Dictionary = generator.campaign_parameters(generator.campaign_count() - 8, seed_value)
	parameters["id"] = 10000
	parameters["mode"] = "daily"
	current_definition = await _generate(parameters)
	if current_definition.is_empty(): return
	current_definition["date_key"] = date
	_load_gameplay(current_definition)

func show_shift() -> void:
	var screen := ShiftScreen.new()
	screen.setup(SaveService.data)
	screen.back_requested.connect(show_home)
	screen.start_requested.connect(_start_or_resume_shift)
	screen.route_requested.connect(_on_home_route)
	screen.cash_out_requested.connect(_cash_out_shift)
	_show_screen(screen, "shift")

func _start_or_resume_shift() -> void:
	if int(SaveService.data["shift"].get("active_seed", 0)) <= 0:
		SaveService.begin_shift()
	current_mode = "shift"
	current_level = 20000 + maxi(1, int(SaveService.data["shift"].get("round", 1)))
	continue_used = false
	if bool(SaveService.data["shift"].get("awaiting_decision", false)):
		last_result_won = true
		last_stars = 0
		last_reward = 0
		show_result(true, "")
	else:
		await _start_shift_round()

func _start_shift_round() -> void:
	var run_seed := int(SaveService.data["shift"].get("active_seed", 0))
	if run_seed <= 0:
		run_seed = SaveService.begin_shift()
	var round_number := maxi(1, int(SaveService.data["shift"].get("round", 1)))
	current_level = 20000 + round_number
	current_definition = await _generate({"run_seed":run_seed,"round":round_number})
	if current_definition.is_empty(): return
	if current_definition.get("generation_failed", false):
		show_shift()
		UiKit.toast(current_screen_node, tr("game.generation_failed"))
		return
	_load_gameplay(current_definition)
	var snapshot: Dictionary = SaveService.data["shift"].get("board_snapshot", {})
	if not snapshot.is_empty() and int(snapshot.get("seed_value", -1)) == game_state.seed_value:
		game_state.from_snapshot(snapshot)
		game_state.history.assign(SaveService.data["shift"].get("board_history", []))
		free_undo_available = bool(SaveService.data["shift"].get("free_undo", false))
		mystery_reveal_available = bool(SaveService.data["shift"].get("free_reveal", false))
		gameplay_screen.set_runtime_perks(free_undo_available, mystery_reveal_available)
		gameplay_screen.refresh()

func _cash_out_shift() -> void:
	var amount := SaveService.cash_out_shift()
	AudioService.play_sfx("cash_out")
	HapticsService.pulse(65, 0.65)
	show_shift()
	UiKit.toast(current_screen_node, tr("shift.banked") % amount)

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
	call_deferred("_prepare_tutorials")
	gameplay_screen.event_intro()
	LocalAnalytics.log_event("level_start", {"level": current_level, "seed": game_state.seed_value, "mode": current_mode, "quality": definition.get("quality", {})})

func _on_luggage_requested(item_id: String, view: LuggageView) -> void:
	if transition_locked or not game_state.is_selectable(item_id):
		HapticsService.pulse(30, 0.25)
		return
	var options := game_state.destination_options(item_id)
	if String(game_state.items[item_id].get("special_type", "")) == "transfer" and options.size() > 1:
		var chooser := Control.new()
		chooser.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var dim := ColorRect.new()
		dim.color = Color(.09,.13,.24,.45)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		chooser.add_child(dim)
		var card := PanelContainer.new()
		card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		card.position = size*.5-Vector2(165,140)
		card.size = Vector2(330,280)
		card.add_theme_stylebox_override("panel",UiKit.panel(UiKit.PAPER,26))
		var choices := VBoxContainer.new()
		choices.add_theme_constant_override("separation",10)
		card.add_child(choices)
		choices.add_child(UiKit.label(tr("transfer.choose"),22,true))
		for option: String in options:
			var destination_button := UiKit.button("%s  %s" % [DEST_CODES.get(option,option.to_upper()),tr("destination.%s" % _destination_name_key(option))],UiKit.GOLD)
			destination_button.pressed.connect(func(dest := option) -> void:
				chooser.queue_free()
				_commit_luggage(item_id,view,dest))
			choices.add_child(destination_button)
		var cancel := UiKit.button(tr("menu.back"),UiKit.PAPER,true)
		cancel.pressed.connect(chooser.queue_free)
		choices.add_child(cancel)
		chooser.add_child(card)
		add_child(chooser)
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
	var preview: Array[String] = game_state.tray.duplicate()
	if String(game_state.items[item_id].get("special_type", "")) != "key": preview.append(destination)
	var event: Dictionary = game_state.select_item(item_id, destination)
	if not bool(event.get("ok", false)):
		transition_locked = false
		gameplay_screen.finish_transition()
		return
	if int(event.get("matches", 0)) > 0:
		gameplay_screen.tray_view.refresh(preview, game_state.tray_capacity, DEST_CODES, GameplayScreen.DEST_COLORS)
		AudioService.play_sfx("combo" if game_state.combo > 1 else "match")
		HapticsService.pulse(50, 0.65)
		await gameplay_screen.tray_view.animate_dispatch(destination, game_state.combo)
		await gameplay_screen.play_match_juice(bool(SaveService.data["settings"].get("reduced_motion", false)), game_state.combo)
	elif bool(event.get("key", false)):
		AudioService.play_sfx("key")
	transition_locked = false
	_advance_tutorial(event)
	if bool(event.get("won", false)):
		_on_level_won()
	elif bool(event.get("lost", false)):
		_on_level_lost(String(event.get("loss_reason", "tray")))
	else:
		gameplay_screen.finish_transition()
		_remember_shift()

func _remember_shift() -> void:
	if current_mode == "shift" and game_state.phase == game_state.Phase.PLAYING:
		SaveService.remember_shift(game_state.to_snapshot(), game_state.history, free_undo_available, mystery_reveal_available)

func _prepare_tutorials() -> void:
	tutorial_queue.clear()
	active_tutorial = ""
	if current_mode == "campaign":
		if current_level == 1: tutorial_queue.append({"id":"pickup", "key":"tutorial.pickup"}); tutorial_queue.append({"id":"match", "key":"tutorial.match"})
		if current_level == 2: tutorial_queue.append({"id":"blocking", "key":"tutorial.blocking"})
		if current_level == 3: tutorial_queue.append({"id":"tray", "key":"tutorial.tray"})
	for mechanic: String in ["mystery", "locks", "priority", "transfer"]:
		var value: Variant = current_definition.get("mechanics", {}).get(mechanic, 0)
		if (typeof(value) == TYPE_DICTIONARY and not value.is_empty()) or (typeof(value) == TYPE_INT and int(value) > 0):
			tutorial_queue.append({"id":mechanic, "key":"tutorial."+mechanic})
	_next_tutorial()

func _next_tutorial() -> void:
	if not is_instance_valid(gameplay_screen): return
	gameplay_screen.clear_tutorial()
	while not tutorial_queue.is_empty():
		var step: Dictionary = tutorial_queue.pop_front()
		if SaveService.tutorial_seen(step["id"]): continue
		var available := game_state.accessible_item_ids()
		if available.is_empty(): return
		active_tutorial = step["id"]
		var focus: String = available[0]
		for id: String in available:
			if String(game_state.items[id].get("special_type", "")) == active_tutorial or (active_tutorial == "locks" and String(game_state.items[id].get("special_type", "")) == "key"):
				focus = id
		gameplay_screen.show_tutorial(active_tutorial, step["key"], focus)
		return
	active_tutorial = ""

func _advance_tutorial(event: Dictionary) -> void:
	if active_tutorial.is_empty(): return
	if active_tutorial == "match" and int(event.get("matches", 0)) == 0: return
	SaveService.complete_tutorial(active_tutorial)
	_next_tutorial()

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
		AudioService.play_sfx("reveal" if booster == "reveal" else "booster")
		LocalAnalytics.log_event("booster_used", {"booster": booster, "level": current_level})
	gameplay_screen.profile = SaveService.data
	gameplay_screen.set_runtime_perks(free_undo_available, mystery_reveal_available)
	gameplay_screen.refresh()
	_remember_shift()

func _on_level_won() -> void:
	var unlocked_world := ""
	AudioService.play_sfx("win")
	HapticsService.pulse(90, 0.8)
	last_result_won = true
	last_stars = 3 if game_state.boosters_used <= 1 and game_state.peak_tray <= 5 and not continue_used else 2 if game_state.boosters_used <= 2 else 1
	last_reward = 40 + last_stars * 10 + (15 if game_state.priority_completed and not game_state.priority_destination.is_empty() else 0)
	if current_mode == "campaign":
		var coins_before := int(SaveService.data["coins"])
		SaveService.complete_level(current_level, last_stars, game_state.score, last_reward, generator.campaign_count())
		last_reward = int(SaveService.data["coins"]) - coins_before
		if last_reward > 0 and current_level < generator.campaign_count() and int(generator.world_for_level(current_level).get("local_level", 1)) == 15:
			AudioService.play_sfx("world_unlock")
			unlocked_world = tr(String(generator.world_for_level(current_level+1).get("name_key","")))
	elif current_mode == "daily":
		_reward_daily(last_reward)
	else:
		var event_id := String(current_definition.get("shift_event", ""))
		var event_bonus := 35 if event_id == "vip_baggage" and game_state.vip_completed and game_state.boosters_used == 0 else 0
		last_reward += event_bonus
		last_reward = SaveService.advance_shift(game_state.score, event_id, last_reward)
	LocalAnalytics.log_event("level_win", {"level": current_level, "score": game_state.score, "stars": last_stars})
	show_result(true, "")
	if not unlocked_world.is_empty(): UiKit.flight_banner(current_screen_node,tr("world.unlocked")+"\n"+unlocked_world)

func _reward_daily(reward: int) -> void:
	var date := Time.get_date_string_from_system()
	SaveService.data["daily"]["best_scores"][date] = maxi(game_state.score, int(SaveService.data["daily"]["best_scores"].get(date, 0)))
	if String(SaveService.data["daily"].get("last_rewarded_date", "")) != date:
		SaveService.data["daily"]["streak"] = _updated_streak(date)
		SaveService.data["daily"]["last_rewarded_date"] = date
		SaveService.data["coins"] = int(SaveService.data["coins"]) + reward
	else:
		last_reward = 0
	SaveService.save_profile()

func _on_level_lost(reason: String) -> void:
	AudioService.play_sfx("lose")
	last_result_won = false
	last_stars = 0
	last_reward = 0
	if current_mode == "shift": last_reward = SaveService.cash_out_shift(true)
	LocalAnalytics.log_event("level_fail", {"level": current_level, "reason": reason, "tray_peak": game_state.peak_tray})
	show_result(false, reason)

func show_result(won: bool, reason: String) -> void:
	var screen := ResultScreen.new()
	var percent := _airport_progress_percent()
	var challenge_complete: bool = (game_state.priority_completed and not game_state.priority_destination.is_empty()) or (game_state.vip_completed and not game_state.vip_destination.is_empty())
	screen.setup(won, current_mode, last_stars, last_reward, game_state.score, reason, percent, challenge_complete, SaveService.data, game_state.tray)
	screen.action_requested.connect(_on_result_action)
	_show_screen(screen, "result")

func _on_result_action(action: String) -> void:
	match action:
		"airport": show_airport()
		"cash_out": _cash_out_shift()
		"home":
			if current_mode == "shift" and not last_result_won:
				SaveService.end_shift()
			show_home()
		"retry":
			if current_mode == "campaign" and last_result_won:
				start_campaign_level(current_level)
			elif current_mode == "shift":
				SaveService.begin_shift()
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
				SaveService.continue_shift()
				_start_shift_round()
			else:
				show_home()

func _show_pause() -> void:
	if transition_locked or game_state.phase != game_state.Phase.PLAYING:
		return
	_remember_shift()
	game_state.phase = game_state.Phase.PAUSED
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(.09,.13,.24,.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var card := PanelContainer.new()
	card.position = size*.5-Vector2(166,160)
	card.size = Vector2(332,320)
	card.add_theme_stylebox_override("panel",UiKit.panel(UiKit.PAPER,28))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",14)
	card.add_child(column)
	column.add_child(UiKit.label(tr("pause.title"),26,true))
	column.add_child(UiKit.label(tr("pause.message"),16,true))
	for action in ["resume","retry","home"]:
		var button := UiKit.button(tr("menu."+action),UiKit.CORAL if action == "resume" else UiKit.PAPER)
		button.pressed.connect(func(id := String(action)) -> void:
			overlay.queue_free()
			if id == "resume":
				game_state.phase = game_state.Phase.PLAYING
				gameplay_screen.refresh()
			elif id == "retry":
				_load_gameplay(current_definition)
			else: show_home())
		column.add_child(button)
	overlay.add_child(card)
	add_child(overlay)

func show_airport() -> void:
	var world := int(generator.world_for_level(int(SaveService.data.get("current_level", 1))).get("id", 1))
	var screen := AirportScreen.new()
	screen.setup(SaveService.data, world)
	screen.back_requested.connect(show_home)
	screen.route_requested.connect(_on_home_route)
	screen.upgrade_requested.connect(func(world_id: int, zone: String) -> void:
		if SaveService.purchase_airport_upgrade(world_id, zone):
			AudioService.play_sfx("renovation")
			HapticsService.pulse(70, 0.7)
			screen.refresh(zone))
	_show_screen(screen, "airport")

func show_settings() -> void:
	var screen := SettingsScreen.new()
	screen.setup(SaveService.data)
	screen.back_requested.connect(show_home)
	screen.setting_changed.connect(func(key: String, value: Variant) -> void:
		SaveService.data["settings"][key] = value
		SaveService.save_profile()
		AudioService.apply_settings()
		_apply_theme()
		if key == "text_scale":
			_apply_theme()
			show_settings())
	screen.language_requested.connect(_toggle_language)
	screen.tutorials_requested.connect(func() -> void:
		SaveService.replay_tutorials()
		start_campaign_level(1))
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
	return AirportEconomy.progress(SaveService.data.get("airport", {}))

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
	var output_directory := "res://store/screenshots"
	if "--device-audit" in OS.get_cmdline_user_args():
		var pixels := get_viewport().get_texture().get_size()
		output_directory = "res://build/device-%dx%d" % [pixels.x,pixels.y]
		if "--fully-upgraded" in OS.get_cmdline_user_args(): output_directory += "/fully-upgraded-large" if "--large-text" in OS.get_cmdline_user_args() else "/fully-upgraded"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory))
	var captures: Array = [
		["home", Callable(self, "show_home")],
		["campaign", Callable(self, "show_campaign")],
		["gameplay", func() -> void: await start_campaign_level(20)],
		["airport", Callable(self, "show_airport")],
		["daily", Callable(self, "show_daily")],
		["shift", Callable(self, "show_shift")]
	]
	for capture in captures:
		await capture[1].call()
		if current_screen != capture[0] or not is_instance_valid(current_screen_node) or current_screen_node.get_child_count() == 0:
			push_error("Screenshot screen failed to initialize: "+capture[0])
			get_tree().quit(1)
			return
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		var captured := get_viewport().get_texture().get_image()
		var saved := false
		for attempt in 10:
			if not captured.is_empty() and captured.save_png("%s/%s.png" % [output_directory,capture[0]]) == OK:
				saved = true
				break
			await get_tree().create_timer(.1*(attempt+1)).timeout
		if not saved:
			push_error("Screenshot write failed: "+capture[0])
			get_tree().quit(1)
			return
	print("SCREENSHOTS PASS: home, campaign, gameplay, airport, daily, shift")
	LuggageView.textures.clear()
	await get_tree().process_frame
	get_tree().quit()

func _qa_capture(id: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var directory := "res://build/qa-%s" % ("en" if TranslationServer.get_locale().begins_with("en") else "uk")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	get_viewport().get_texture().get_image().save_png(directory+"/"+id+".png")

func _qa_solve_current() -> bool:
	var solver := preload("res://core/solver/level_solver.gd").new()
	var result: Dictionary = solver.solve_level(current_definition)
	if not result.get("solved",false): return false
	for encoded: String in result["solution"]:
		var action: Dictionary = solver.decode_action(encoded)
		if not game_state.is_selectable(action["item_id"]): return false
		await _commit_luggage(action["item_id"],gameplay_screen.luggage_nodes[action["item_id"]],action["destination_id"])
	return game_state.phase == game_state.Phase.WON

func _qa_player_flow() -> void:
	var ok := true
	await _qa_capture("fresh-home")
	for level in [1,2,3]:
		await start_campaign_level(level)
		await _qa_capture("tutorial-%d" % level)
		ok = (await _qa_solve_current()) and ok
		await _qa_capture("win-%d" % level)
	ok = SaveService.tutorial_seen("pickup") and SaveService.tutorial_seen("match") and SaveService.tutorial_seen("blocking") and SaveService.tutorial_seen("tray") and ok
	show_airport()
	await _qa_capture("airport-before")
	(current_screen_node as AirportScreen)._open_sheet("baggage")
	await _qa_capture("upgrade-sheet")
	var sheet := current_screen_node.get_child(current_screen_node.get_child_count()-1) as UpgradeSheet
	sheet.purchase_requested.emit("baggage")
	sheet.queue_free()
	ok = int(SaveService.data["airport"].get("baggage",0)) == 1 and ok
	await _qa_capture("airport-after")
	show_campaign()
	await _qa_capture("campaign")
	await start_campaign_level(8)
	await _qa_capture("hard")
	ok = (await _qa_solve_current()) and ok
	show_daily()
	await _qa_capture("daily")
	await start_daily()
	await _qa_capture("daily-board")
	SaveService.begin_shift(424242)
	await _start_or_resume_shift()
	await _qa_capture("shift-board")
	ok = (await _qa_solve_current()) and ok
	await _qa_capture("shift-bank")
	var coins_before := int(SaveService.data["coins"])
	var earnings := int(SaveService.data["shift"]["earnings"])
	_cash_out_shift()
	ok = earnings > 0 and int(SaveService.data["coins"]) == coins_before+earnings and ok
	await _qa_capture("cash-out")
	show_settings()
	await _qa_capture("settings")
	SaveService.replay_tutorials()
	await start_campaign_level(1)
	await _qa_capture("tutorial-replay")
	ok = active_tutorial == "pickup" and ok
	var failed_definition: Dictionary = current_definition.duplicate(true)
	game_state.load_level(failed_definition)
	game_state.tray.assign(["par","tyo","iev","rom","cai","sel","syd"])
	_on_level_lost("tray")
	await _qa_capture("failure")
	print("PLAYER FLOW: ", "PASS" if ok else "FAIL", " locale=", TranslationServer.get_locale())
	LuggageView.textures.clear()
	await get_tree().process_frame
	get_tree().quit(0 if ok else 1)
