extends SceneTree

func _initialize() -> void:
	var report := {"schema_version":3,"samples":0,"generation_failures":0,"impossible_boards":0,"worst_nodes_explored":0,"elapsed_ms":0,"worlds":{}}
	var metric_keys := ["average_generation_ms","average_branching_factor","average_initial_selectable","average_forced_move_ratio","random_win_rate","greedy_win_rate","balanced_win_rate","average_simulated_pressure","meaningful_choice_score"]
	for key in metric_keys: report[key] = 0.0
	var times: Array[int] = []
	var attempts := 0
	for part in 4:
		var path := "res://build/stress-part-%d.json" % part
		if not FileAccess.file_exists(path):
			push_error("Missing stress shard: "+path); quit(1); return
		var shard: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		if int(shard.get("samples",0)) != 2500 or int(shard.get("start_index",-1)) != part*2500:
			push_error("Invalid or overlapping stress shard"); quit(1); return
		report["samples"] += int(shard["samples"])
		report["generation_failures"] += int(shard["generation_failures"])
		report["impossible_boards"] += int(shard["impossible_boards"])
		report["worst_nodes_explored"] = maxi(int(report["worst_nodes_explored"]),int(shard["worst_nodes_explored"]))
		report["elapsed_ms"] = maxi(int(report["elapsed_ms"]),int(shard["elapsed_ms"]))
		for key in metric_keys: report[key] += float(shard[key])*2500
		for value in shard["solver_times"]: times.append(int(value))
		for world: String in shard["worlds"]:
			var row: Dictionary = shard["worlds"][world]
			attempts += int(row["attempts"])
			if not report["worlds"].has(world): report["worlds"][world] = {"samples":0,"attempts":0,"pressure":0.0,"random":0.0,"greedy":0.0,"balanced":0.0}
			var target: Dictionary = report["worlds"][world]
			target["samples"] += int(row["samples"]); target["attempts"] += int(row["attempts"])
			for key in ["pressure","random","greedy","balanced"]: target[key] += float(row[key])*int(row["samples"])
	if times.size() != 10000:
		push_error("Stress solver sample count differs from 10000"); quit(1); return
	for key in metric_keys: report[key] = snappedf(float(report[key])/10000.0,0.001)
	for world: String in report["worlds"]:
		var row: Dictionary = report["worlds"][world]
		for key in ["pressure","random","greedy","balanced"]: row[key] = snappedf(float(row[key])/int(row["samples"]),.001)
		row["rejection_rate"] = snappedf(1.0-float(row["samples"])/int(row["attempts"]),.001)
	times.sort()
	report["solver_ms_p50"] = times[4999]; report["solver_ms_p95"] = times[9499]; report["solver_ms_p99"] = times[9899]
	report["total_candidates"] = attempts
	report["candidate_rejection_rate"] = snappedf(1.0-10000.0/attempts,.0001)
	report["average_generation_attempts"] = snappedf(attempts/10000.0,.01)
	report["generation_failure_rate"] = report["generation_failures"]/10000.0
	report["validation_execution"] = "4 processes, 2500 unique seeds each, contiguous non-overlapping seed indices, raw solver times merged"
	var file := FileAccess.open("res://data/campaign/stress_report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("MERGED STRESS: ",JSON.stringify(report))
	quit(0 if int(report["generation_failures"]) == 0 and int(report["impossible_boards"]) == 0 else 1)
