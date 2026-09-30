extends SceneTree

func _initialize() -> void:
	call_deferred("_render")

func _render() -> void:
	for kind in ["feature", "logo"]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(1024,500) if kind == "feature" else Vector2i(800,240)
		viewport.transparent_bg = kind == "logo"
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var art := TextureRect.new()
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.texture = load(("res://assets/art/feature_background.png" if ResourceLoader.exists("res://assets/art/feature_background.png") else "res://store/feature_graphic.svg") if kind == "feature" else "res://assets/art/logo.svg")
		art.size = viewport.size
		viewport.add_child(art)
		var title := Label.new()
		title.text = "LOST & SORTED" if kind == "feature" else "LOST &\nSORTED"
		title.position = Vector2(48,25) if kind == "feature" else Vector2(210,15)
		title.add_theme_font_size_override("font_size",61 if kind == "feature" else 73)
		title.add_theme_color_override("font_color",Color("17223d"))
		viewport.add_child(title)
		if kind == "feature":
			var tagline := Label.new()
			tagline.text = "SORT. FLY. BUILD."
			tagline.position = Vector2(52,116)
			tagline.add_theme_font_size_override("font_size",24)
			tagline.add_theme_color_override("font_color",Color("4b7187"))
			viewport.add_child(tagline)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := viewport.get_texture().get_image()
		picture.save_png("res://store/feature_graphic.png" if kind == "feature" else "res://assets/art/logo.png")
		if kind == "logo": picture.save_png("res://assets/art/splash.png")
		viewport.queue_free()
	# Store posters frame actual screenshots; native screen pixels are unchanged.
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://store/presentation"))
	for entry in [["gameplay","SORT YOUR NEXT FLIGHT"],["airport","BUILD YOUR AIRPORT"],["campaign","75 STAGES. FIVE WORLDS."],["shift","BANK IT. OR RISK IT."],["daily","A NEW FLIGHT EVERY DAY"]]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(1080,1920)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var bg := ColorRect.new()
		bg.color = Color("17223d"); bg.size = viewport.size
		viewport.add_child(bg)
		var title := Label.new()
		title.text = entry[1]
		title.position = Vector2(60,80); title.size = Vector2(960,170)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size",58)
		title.add_theme_color_override("font_color",Color("fff8eb"))
		viewport.add_child(title)
		var shot := TextureRect.new()
		shot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var screenshot := Image.new()
		var source := FileAccess.get_file_as_bytes("res://store/screenshots/%s.png" % entry[0])
		if screenshot.load_png_from_buffer(source) != OK:
			push_error("Unable to load actual screenshot: "+entry[0]); quit(1); return
		shot.texture = ImageTexture.create_from_image(screenshot)
		shot.position = Vector2(108,290); shot.size = Vector2(864,1536)
		viewport.add_child(shot)
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://store/presentation/%s.png" % entry[0])
		viewport.queue_free()
	print("STORE ART PASS: feature 1024x500, logo, splash, 5 actual-game posters")
	await process_frame
	await process_frame
	quit()
