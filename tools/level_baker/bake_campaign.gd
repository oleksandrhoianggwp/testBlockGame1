extends SceneTree

const GeneratorScript = preload("res://core/generation/level_generator.gd")
const SolverScript = preload("res://core/solver/level_solver.gd")

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://data/campaign"))
	var generator = GeneratorScript.new()
	var solver = SolverScript.new()
	var report_lines: Array[String] = ["Lost & Sorted campaign validation", "Godot 4.7.2 | schema 1 | content version 1", ""]
	var index: Array[Dictionary] = []
	var seeds: Dictionary = {}
	var passed := 0
	var failed := 0
	var total_nodes := 0
	for level_id in range(1, 151):
		var parameters: Dictionary = generator.campaign_parameters(level_id)
		var level: Dictionary = generator.generate_level(parameters)
		var validation := _validate_structure(level)
		var result: Dictionary = solver.solve_level(level) if validation.is_empty() else {"solved": false, "reason": validation, "nodes": 0, "max_depth": 0, "solve_ms": 0, "solution": []}
		var seed_value := int(level["seed"])
		if seeds.has(seed_value):
			result["solved"] = false
			result["reason"] = "duplicate_seed"
		seeds[seed_value] = true
		if bool(result["solved"]):
			passed += 1
		else:
			failed += 1
		total_nodes += int(result.get("nodes", 0))
		_write_json("res://data/campaign/level_%03d.json" % level_id, level)
		index.append({"id": level_id, "world": level["world"], "seed": seed_value, "layout": level["layout_template"], "difficulty": level["difficulty"], "solver_nodes": result.get("nodes", 0), "solution_length": result.get("solution", []).size()})
		report_lines.append("Level %03d %s | seed=%d | layout=%s | nodes=%d | depth=%d | solve_ms=%d | difficulty=%.3f" % [level_id, "PASS" if result["solved"] else "FAIL", seed_value, level["layout_template"], result.get("nodes", 0), result.get("max_depth", 0), result.get("solve_ms", 0), level["difficulty"]])
	_write_json("res://data/campaign/index.json", {"schema_version": 1, "content_version": 1, "levels": index})
	report_lines.append("")
	report_lines.append("%d/150 levels validated" % passed)
	report_lines.append("%d impossible" % failed)
	report_lines.append("%d duplicate seeds" % (150 - seeds.size()))
	report_lines.append("%d total solver nodes" % total_nodes)
	var report_file := FileAccess.open("res://data/campaign/validation_report.txt", FileAccess.WRITE)
	report_file.store_string("\n".join(report_lines) + "\n")
	print("CAMPAIGN: %d/150 solved, %d failed, %d nodes" % [passed, failed, total_nodes])
	quit(0 if failed == 0 else 1)

func _validate_structure(level: Dictionary) -> String:
	if int(level.get("schema_version", 0)) != 1:
		return "invalid_schema"
	var ids: Dictionary = {}
	var counts: Dictionary = {}
	var key_groups: Dictionary = {}
	for item: Dictionary in level.get("items", []):
		var item_id := String(item.get("id", ""))
		if item_id.is_empty() or ids.has(item_id):
			return "duplicate_or_empty_id"
		ids[item_id] = true
		if String(item.get("special_type", "")) == "key":
			key_groups[String(item.get("key_group", ""))] = true
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
	for count: int in counts.values():
		if count % 3 != 0:
			return "destination_not_tripled"
	return ""

func _write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "  "))

