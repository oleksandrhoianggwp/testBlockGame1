extends SceneTree

# Render the actual main scene at exact mobile pixels without Windows desktop
# work-area clamping. This is layout evidence, not a hardware/device benchmark.
func _initialize() -> void:
	var pixels := Vector2i(1080,2400)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--viewport="):
			var parts := argument.trim_prefix("--viewport=").split("x")
			pixels = Vector2i(int(parts[0]),int(parts[1]))
	var viewport := SubViewport.new()
	viewport.size = pixels
	viewport.size_2d_override = Vector2i(432,roundi(float(pixels.y)*432.0/pixels.x))
	viewport.size_2d_override_stretch = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main: Control = load("res://app/main.tscn").instantiate()
	viewport.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
