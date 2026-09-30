class_name RewardPopup
extends Control

func play(origin: Vector2, target: Vector2) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	AudioService.play_sfx("coin")
	if UiKit.reduced_motion:
		queue_free()
		return
	for i in 7:
		var coin := Panel.new()
		coin.add_theme_stylebox_override("panel",UiKit.panel(UiKit.GOLD,11))
		coin.position = origin+Vector2(i*5,0)
		coin.size = Vector2(22,22)
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(coin)
		var mark := TextureRect.new()
		mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mark.texture = load("res://assets/icons/coin.svg")
		mark.position = Vector2(4,4)
		mark.size = Vector2(14,14)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		coin.add_child(mark)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(coin,"position",target,.6).set_delay(i*.04).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(coin,"modulate:a",0.0,.18).set_delay(.48+i*.04)
	create_tween().tween_callback(queue_free).set_delay(1.0)
