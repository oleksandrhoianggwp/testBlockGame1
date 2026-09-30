class_name ResultScreen
extends Control
signal action_requested(action: String)

func setup(won: bool, mode: String, stars: int, reward: int, _score: int, reason: String, percent: int, challenge: bool, profile: Dictionary = {}, tray: Array[String] = []) -> void:
	var safe := UiKit.screen_background(self,UiKit.SKY if won else Color("D8DEE8"))
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation",14)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	safe.add_child(scroll)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	var header := UiKit.header(tr("menu.shift") if mode == "shift" else tr("game.level"),int(profile.get("coins",0)),false)
	column.add_child(header["root"])
	if mode != "shift": column.add_child(UiKit.art("res://assets/icons/plane.svg",50))
	var stamp := UiKit.label(tr("result.cleared") if won else tr("result.closed") if reason == "priority" else tr("result.belt_full"),30,true)
	stamp.add_theme_color_override("font_color",UiKit.INK)
	stamp.add_theme_stylebox_override("normal",UiKit.panel(UiKit.MINT if won else UiKit.GOLD,20,UiKit.INK,2))
	column.add_child(stamp)
	if won and mode != "shift":
		var star_label := UiKit.label("★".repeat(stars)+"☆".repeat(3-stars),44,true)
		star_label.add_theme_color_override("font_color",UiKit.GOLD)
		column.add_child(star_label)
		column.add_child(UiKit.label(tr("result.reward") % reward,28,true))
		if challenge: column.add_child(UiKit.label(tr("result.challenge_complete"),16,true))
	elif not won:
		var belt := TrayView.new()
		column.add_child(belt)
		belt.call_deferred("refresh",tray,7,GameplayScreen.DEST_CODES,GameplayScreen.DEST_COLORS)
		column.add_child(UiKit.label(tr("game.priority_failed") if reason == "priority" else tr("result.no_room"),18,true))
	if mode == "shift" and won:
		var bank := ShiftBankPanel.new()
		bank.configure(profile.get("shift",{}))
		bank.cash_out_requested.connect(func() -> void: action_requested.emit("cash_out"))
		bank.continue_requested.connect(func() -> void: action_requested.emit("continue"))
		column.add_child(bank)
	else:
		column.add_child(UiKit.label(tr("result.airport_percent") % percent,16,true))
		column.add_child(UiKit.progress_bar(percent))
		if won and AirportEconomy.affordable(profile.get("airport",{}),int(profile.get("coins",0))):
			var visit := UiKit.button(tr("result.upgrade_ready"),UiKit.GOLD,true)
			visit.pressed.connect(func() -> void: action_requested.emit("airport"))
			column.add_child(visit)
		var next := UiKit.button(tr("menu.continue") if won else tr("menu.retry"),UiKit.CORAL)
		next.pressed.connect(func() -> void: action_requested.emit("continue" if won else "retry"))
		column.add_child(next)
		if won:
			var replay := UiKit.button(tr("result.replay"),UiKit.PAPER,true)
			replay.pressed.connect(func() -> void: action_requested.emit("retry"))
			column.add_child(replay)
	var home := UiKit.button(tr("menu.home"),UiKit.PAPER,true)
	home.pressed.connect(func() -> void: action_requested.emit("home"))
	column.add_child(home)
	if mode == "shift" and not won:
		column.add_child(UiKit.label(tr("shift.failure_paid") % reward,14,true))
	if not UiKit.reduced_motion:
		ready.connect(func() -> void:
			stamp.pivot_offset = stamp.size*.5
			stamp.scale = Vector2.ONE*1.15
			stamp.modulate.a = 0
			var tween := create_tween().set_parallel(true)
			tween.tween_property(stamp,"scale",Vector2.ONE,.4).set_trans(Tween.TRANS_BACK)
			tween.tween_property(stamp,"modulate:a",1.0,.2))
	if won:
		ready.connect(func() -> void:
			if mode != "shift": AudioService.play_sfx("star")
			if reward <= 0: return
			var reward_animation := RewardPopup.new()
			add_child(reward_animation)
			# Shift winnings stay unbanked; animate to earnings, not the wallet.
			reward_animation.play(size*.5,Vector2(size.x*.5,215) if mode == "shift" else Vector2(size.x-62,44)))
