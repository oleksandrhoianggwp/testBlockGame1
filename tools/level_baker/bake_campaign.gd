extends SceneTree

const GeneratorScript = preload("res://core/generation/level_generator.gd")
const SolverScript = preload("res://core/solver/level_solver.gd")

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://data/campaign"))
	var generator = GeneratorScript.new()
	var campaign_count := generator.campaign_count()
	var report_lines: Array[String] = [
		"Lost & Sorted campaign validation",
		"Godot 4.7.2 | schema 2 | content version 2",
		"",
		"id result seed attempt items initial avg_select branching meaningful forced peak dead_ends nodes depth solve_ms difficulty"
	]
	var index: Array[Dictionary] = []
	var passed := 0
	var failed := 0
	var total_nodes := 0
	var total_attempts := 0
	var total_ms := 0
	var write_failures := 0
	for level_id in range(1, campaign_count + 1):
		var parameters: Dictionary = generator.campaign_parameters(level_id)
		var level: Dictionary = generator.generate_level(parameters)
		var validation := _validate_structure(level)
		var solver = SolverScript.new()
		solver.node_limit = 5000
		var result: Dictionary = solver.solve_level(level) if validation.is_empty() else {"solved": false, "reason": validation}
		var quality_ok := validation.is_empty() and generator._quality_passes(result, parameters)
		if quality_ok:
			passed += 1
		else:
			failed += 1
		total_nodes += int(result.get("nodes_explored", 0))
		total_attempts += int(level.get("generation_attempt", 0))
		total_ms += int(result.get("solve_ms", 0))
		if not _write_json("res://data/campaign/level_%03d.json" % level_id, level):
			write_failures += 1
		var entry := {
			"id": level_id,
			"world": level["world"],
			"seed": level["seed"],
			"layout": level["layout_template"],
			"generation_attempts": level["generation_attempt"],
			"quality": generator._quality_payload(result)
		}
		index.append(entry)
		report_lines.append("%02d %s %d %d %d %d %.2f %.2f %d %.3f %d %d %d %d %d %.3f" % [
			level_id, "PASS" if quality_ok else "FAIL:%s" % result.get("reason", validation),
			int(level["seed"]), int(level["generation_attempt"]), level["items"].size(),
			int(result.get("initial_selectable_count", 0)), float(result.get("average_selectable_count", 0.0)),
			float(result.get("average_branching_factor", 0.0)), int(result.get("meaningful_decision_count", 0)),
			float(result.get("forced_move_ratio", 1.0)), int(result.get("peak_expected_tray_pressure", 0)),
			int(result.get("dead_end_count", 0)), int(result.get("nodes_explored", 0)),
			int(result.get("solution_depth", 0)), int(result.get("solve_ms", 0)), float(result.get("difficulty_score", 0.0))
		])
	if not _write_json("res://data/campaign/index.json", {
		"schema_version": 2,
		"content_version": 2,
		"campaign_count": campaign_count,
		"world_count": generator.campaign_config().get("worlds", []).size(),
		"levels": index
	}):
		write_failures += 1
	report_lines.append("")
	report_lines.append("%d/%d levels passed solver and decision-quality thresholds" % [passed, campaign_count])
	report_lines.append("%d rejected" % failed)
	report_lines.append("%.2f average generation attempts" % (float(total_attempts) / float(maxi(1, campaign_count))))
	report_lines.append("%.2f average solver ms" % (float(total_ms) / float(maxi(1, campaign_count))))
	report_lines.append("%d inspected solver nodes" % total_nodes)
	if not _write_text("res://data/campaign/validation_report.txt", "\n".join(report_lines) + "\n"):
		write_failures += 1
	print("CAMPAIGN: %d/%d passed, %d failed, mean_attempts=%.2f, mean_ms=%.2f" % [passed, campaign_count, failed, float(total_attempts) / float(campaign_count), float(total_ms) / float(campaign_count)])
	if write_failures > 0:
		printerr("CAMPAIGN WRITE FAILURES: %d" % write_failures)
	quit(0 if failed == 0 and write_failures == 0 else 1)

func _validate_structure(level: Dictionary) -> String:
	if int(level.get("schema_version", 0)) != 2:
		return "invalid_schema"
	var ids: Dictionary = {}
	var counts: Dictionary = {}
	var transfer_destinations: Dictionary = {}
	var key_groups: Dictionary = {}
	for item: Dictionary in level.get("items", []):
		var item_id := String(item.get("id", ""))
		if item_id.is_empty() or ids.has(item_id):
			return "duplicate_or_empty_id"
		ids[item_id] = true
		var item_type := String(item.get("special_type", ""))
		if item_type == "key":
			key_groups[String(item.get("key_group", ""))] = true
		elif item_type == "transfer":
			for option: String in item.get("destination_options", []):
				transfer_destinations[option] = true
		else:
			var destination := String(item.get("destination_id", ""))
			counts[destination] = int(counts.get(destination, 0)) + 1
	for item: Dictionary in level.get("items", []):
		for blocker_id: String in item.get("blocker_ids", []):
			if not ids.has(blocker_id):
				return "dangling_blocker"
		var lock_group := String(item.get("lock_group", ""))
		if not lock_group.is_empty() and not key_groups.has(lock_group):
			return "lock_without_key"
	for destination: String in counts:
		if int(counts[destination]) % 3 != 0 and not transfer_destinations.has(destination):
			return "destination_not_tripled"
	return ""

func _write_json(path: String, value: Variant) -> bool:
	return _write_text(path, JSON.stringify(value, "  "))

func _write_text(path: String, content: String) -> bool:
	for attempt in 5:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_string(content)
			file.flush()
			file.close()
			return true
		OS.delay_msec(25 * (attempt + 1))
	push_error("Unable to write campaign artifact: %s (%s)" % [path, error_string(FileAccess.get_open_error())])
	return false
