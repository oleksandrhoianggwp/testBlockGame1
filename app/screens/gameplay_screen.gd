class_name GameplayScreen
extends Control

signal luggage_requested(item_id: String, view: LuggageView)
signal booster_requested(booster_id: String)
signal pause_requested

const DEST_COLORS := {
	"par": "E95D72", "tyo": "EF8D43", "iev": "F3C34F", "rom": "57B87A",
	"cai": "2BB7A8", "sel": "3FA6D8", "syd": "5D7BE7", "rio": "9B70D9",
	"osl": "4D8CBF", "yto": "D968A7", "lim": "B8894E", "nbo": "718F47"
}
const DEST_CODES := {"par":"PAR", "tyo":"TYO", "iev":"IEV", "rom":"ROM", "cai":"CAI", "sel":"SEL", "syd":"SYD", "rio":"RIO", "osl":"OSL", "yto":"YTO", "lim":"LIM", "nbo":"NBO"}
const WORLD_BACKGROUNDS := ["regional", "international", "cargo", "midnight", "skyport"]

var definition: Dictionary = {}
var game_state
var profile: Dictionary = {}
var mode_title: String = ""
var status_label: Label
var objective: FlightObjective
var board_control: Control
var tray_view: TrayView
var booster_row: HBoxContainer
var luggage_nodes: Dictionary = {}
var transition_locked: bool = false
var free_undo_available: bool = false
var reveal_available: bool = false
var tutorial: TutorialOverlay
var booster_help_seen: Dictionary = {}
var booster_nodes: Dictionary = {}

func setup(level_definition: Dictionary, state, profile_data: Dictionary, title_text: String) -> void:
	definition = level_definition
	game_state = state
	profile = profile_data
	mode_title = title_text
	_build_once()
	call_deferred("refresh")

func _build_once() -> void:
	var world_index := clampi(int(definition.get("world", 1)) - 1, 0, 4)
	var background_path := "res://assets/art/backgrounds/%s.svg" % WORLD_BACKGROUNDS[world_index]
	var background_color: Color = [Color("DDF2EE"), Color("DFEEFA"), Color("E9E1D5"), Color("151E3E"), Color("E6E5FA")][world_index]
	var safe := UiKit.screen_background(self, background_color, background_path)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	safe.add_child(column)
	var top := HBoxContainer.new()
	var pause := UiKit.button("Ⅱ", UiKit.PAPER, true)
	pause.custom_minimum_size = Vector2(48, 46)
	pause.pressed.connect(func() -> void: pause_requested.emit())
	top.add_child(pause)
	status_label = UiKit.label(mode_title, 17, true)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_stylebox_override("normal", UiKit.panel(Color(1, 1, 1, 0.82), 15))
	top.add_child(status_label)
	var coins := UiKit.label("● %d" % int(profile.get("coins", 0)), 15, true)
	coins.custom_minimum_size = Vector2(76, 46)
	coins.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coins.add_theme_stylebox_override("normal", UiKit.panel(Color("FFF1BE"), 15))
	top.add_child(coins)
	column.add_child(top)
	objective = FlightObjective.new()
	column.add_child(objective)
	board_control = Control.new()
	board_control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_control.custom_minimum_size.y = 390
	board_control.clip_contents = false
	board_control.resized.connect(_position_luggage)
	column.add_child(board_control)
	tray_view = TrayView.new()
	column.add_child(tray_view)
	booster_row = HBoxContainer.new()
	booster_row.alignment = BoxContainer.ALIGNMENT_CENTER
	booster_row.add_theme_constant_override("separation", 14)
	column.add_child(booster_row)
	for item: Dictionary in definition.get("items", []):
		var view := LuggageView.new()
		view.name = String(item["id"]).validate_node_name()
		view.size = Vector2(96, 88)
		view.pressed.connect(func(id := String(item["id"]), node := view) -> void:
			if not transition_locked:
				luggage_requested.emit(id, node))
		board_control.add_child(view)
		luggage_nodes[String(item["id"])] = view

func refresh() -> void:
	if not is_instance_valid(board_control) or game_state == null:
		return
	status_label.text = mode_title
	var remaining := 0
	for item: Dictionary in game_state.items.values():
		if not bool(item.get("removed", false)) and String(item.get("special_type", "")) != "key": remaining += 1
	var priority_text := ""
	if not game_state.priority_destination.is_empty() and not game_state.priority_completed:
		priority_text = "%s %s  •  %d %s" % [tr("game.priority"), DEST_CODES.get(game_state.priority_destination, game_state.priority_destination.to_upper()), game_state.priority_moves, tr("game.moves")]
	var event_id := String(definition.get("shift_event", ""))
	if not event_id.is_empty():
		var event_text := tr("shift.event.%s" % event_id)
		priority_text = event_text if priority_text.is_empty() else event_text + "  •  " + priority_text
	if priority_text.is_empty(): priority_text = tr("game.flights_remaining") % int(ceil((remaining+game_state.tray.size())/3.0))
	if game_state.jam_moves > 0: priority_text += "  •  " + tr("game.jam_moves") % game_state.jam_moves
	objective.set_objective(priority_text, true)
	for item_id: String in luggage_nodes:
		var view: LuggageView = luggage_nodes[item_id]
		var item: Dictionary = game_state.items[item_id]
		view.visible = not bool(item.get("removed", false))
		if view.visible:
			var visual_item := item.duplicate()
			if String(item.get("lock_group", "")) in game_state.unlocked_groups: visual_item["lock_group"] = ""
			view.configure(visual_item, game_state.is_selectable(item_id), DEST_CODES, DEST_COLORS)
	_position_luggage()
	tray_view.refresh(game_state.tray, game_state.tray_capacity, DEST_CODES, DEST_COLORS)
	_refresh_boosters()

func set_runtime_perks(free_undo: bool, reveal: bool) -> void:
	free_undo_available = free_undo
	reveal_available = reveal

func _position_luggage() -> void:
	if game_state == null or not is_instance_valid(board_control):
		return
	for item_id: String in luggage_nodes:
		var view: LuggageView = luggage_nodes[item_id]
		var item: Dictionary = game_state.items[item_id]
		var point: Array = item.get("position", [0.5, 0.5])
		view.position = Vector2(float(point[0]) * board_control.size.x - view.size.x * 0.5, float(point[1]) * board_control.size.y - view.size.y * 0.5)
		view.rotation_degrees = float(item.get("rotation", 0.0))
		view.z_index = int(item.get("z_index", 0))

func _refresh_boosters() -> void:
	for booster_id in ["undo", "shuffle", "extra_slot", "reveal"]:
		var count := int(profile.get("boosters", {}).get(booster_id, 0))
		if booster_id == "undo" and free_undo_available:
			count += 1
		if not booster_nodes.has(booster_id):
			var node := BoosterButton.new()
			node.pressed.connect(func(id := String(booster_id)) -> void:
				if not SaveService.tutorial_seen("booster_"+id):
					SaveService.complete_tutorial("booster_"+id)
					UiKit.toast(self,tr("booster.help."+id))
					return
				booster_requested.emit(id))
			booster_row.add_child(node)
			booster_nodes[booster_id] = node
		var button: BoosterButton = booster_nodes[booster_id]
		if booster_id == "reveal": count = int(reveal_available)
		button.configure(booster_id,"res://assets/icons/%s.svg" % booster_id,count,count>0 and not (booster_id == "extra_slot" and game_state.extra_slot_active))
		button.visible = booster_id != "reveal" or reveal_available

func _has_hidden_mystery() -> bool:
	for item: Dictionary in game_state.items.values():
		if String(item.get("special_type", "")) == "mystery" and not bool(item.get("removed", false)) and not bool(item.get("revealed", false)):
			return true
	return false

func animate_pickup(view: LuggageView, reduced_motion: bool) -> void:
	transition_locked = true
	for node: LuggageView in luggage_nodes.values():
		node.set_interaction_enabled(false)
	if reduced_motion:
		return
	view.z_index = 4000
	var lift := create_tween()
	lift.set_parallel(true)
	lift.tween_property(view, "scale", Vector2(1.10, 1.10), 0.09).set_trans(Tween.TRANS_BACK)
	lift.tween_property(view, "position:y", view.position.y - 10.0, 0.09)
	await lift.finished
	var target := tray_view.target_global_position(game_state.tray.size()) - view.size * 0.5
	var travel := create_tween()
	travel.set_parallel(true)
	travel.tween_property(view, "global_position", target, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	travel.tween_property(view, "scale", Vector2(0.48, 0.48), 0.20)
	travel.tween_property(view, "rotation_degrees", 0.0, 0.20)
	await travel.finished
	AudioService.play_sfx("insert")

func show_tutorial(id: String, key: String, item_id: String) -> void:
	if is_instance_valid(tutorial): tutorial.queue_free()
	tutorial = TutorialOverlay.new()
	add_child(tutorial)
	tutorial.configure(id,key,luggage_nodes.get(item_id, tray_view))

func clear_tutorial() -> void:
	if is_instance_valid(tutorial): tutorial.queue_free()
	tutorial = null

func event_intro() -> void:
	var id := String(definition.get("shift_event", ""))
	if id.is_empty(): return
	var banner := UiKit.label(tr("shift.event."+id),24,true)
	banner.add_theme_color_override("font_color",UiKit.GOLD)
	banner.add_theme_stylebox_override("normal",UiKit.panel(UiKit.NAVY,20))
	banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	banner.offset_left = 20; banner.offset_right = -20
	banner.offset_top = 175; banner.offset_bottom = 275
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.z_index = 4080
	add_child(banner)
	create_tween().tween_callback(banner.queue_free).set_delay(1.4)

func finish_transition() -> void:
	transition_locked = false
	refresh()

func play_match_juice(reduced_motion: bool, combo: int) -> void:
	if reduced_motion:
		return
	var layer := Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var count := clampi(10 + combo * 2, 10, 20)
	for index in count:
		var ticket := ColorRect.new()
		ticket.color = [UiKit.CORAL, UiKit.GOLD, UiKit.MINT, UiKit.BLUE][index % 4]
		ticket.size = Vector2(8, 14)
		ticket.position = size * Vector2(0.5, 0.73)
		layer.add_child(ticket)
		var angle := TAU * float(index) / float(count)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(ticket, "position", ticket.position + Vector2(cos(angle), sin(angle)) * (65.0 + combo * 5.0), 0.24)
		tween.tween_property(ticket, "rotation", angle * 1.8, 0.24)
		tween.tween_property(ticket, "modulate:a", 0.0, 0.24)
	await get_tree().create_timer(0.25).timeout
	layer.queue_free()
