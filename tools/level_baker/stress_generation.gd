extends SceneTree

const GeneratorScript = preload("res://core/generation/level_generator.gd")
const SolverScript = preload("res://core/solver/level_solver.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var sample_count := maxi(1, int(args[0])) if not args.is_empty() else 10000
	var start_index := int(args[1]) if args.size() > 1 else 0
	var report_path := String(args[2]) if args.size() > 2 else "res://data/campaign/stress_report.json"
	var generator = GeneratorScript.new()
	var failures := 0
	var impossible := 0
	var total_attempts := 0
	var total_generation_ms := 0
	var total_branching := 0.0
	var total_initial := 0
	var total_forced := 0.0
	var totals := {"random_win_rate": 0.0, "greedy_win_rate": 0.0, "balanced_win_rate": 0.0, "average_simulated_pressure": 0.0, "meaningful_choice_score": 0.0}
	var world_totals := {}
	var solve_times: Array[int] = []
	var worst_nodes := 0
	var started := Time.get_ticks_msec()
	for index in sample_count:
		var level_number := 1 + (index + start_index) % generator.campaign_count()
		var parameters: Dictionary = generator.campaign_parameters(level_number, 700001 + (index + start_index) * 104729)
		var generation_started := Time.get_ticks_msec()
		var level: Dictionary = generator.generate_level(parameters)
		total_generation_ms += Time.get_ticks_msec() - generation_started
		total_attempts += int(level.get("generation_attempt", 0))
		var solver = SolverScript.new()
		solver.node_limit = 5000
		var result: Dictionary = solver.solve_level(level) if not level.get("generation_failed", false) else {"solved": false}
		var independent_solved := bool(result.get("solved", false))
		result.merge(level.get("quality", {}), true)
		solve_times.append(int(result.get("solve_ms", 0)))
		if not independent_solved:
			impossible += 1
			failures += 1
		elif not generator._quality_passes(result, parameters):
			failures += 1
		total_branching += float(result.get("average_branching_factor", 0.0))
		total_initial += int(result.get("initial_selectable_count", 0))
		total_forced += float(result.get("forced_move_ratio", 1.0))
		var world := str(parameters.get("world", 1))
		if not world_totals.has(world):
			world_totals[world] = {"samples": 0, "attempts": 0, "pressure": 0.0, "random": 0.0, "greedy": 0.0, "balanced": 0.0}
		world_totals[world]["samples"] += 1
		world_totals[world]["attempts"] += int(level.get("generation_attempt", 0))
		world_totals[world]["pressure"] += float(result.get("peak_expected_tray_pressure", 0))
		for profile: String in ["random", "greedy", "balanced"]:
			world_totals[world][profile] += float(result.get(profile + "_win_rate", 0.0))
		for metric: String in totals:
			totals[metric] += float(result.get(metric, 0.0))
		worst_nodes = maxi(worst_nodes, int(result.get("nodes_explored", 0)))
		if (index + 1) % 100 == 0:
			print("STRESS progress %d/%d failures=%d" % [index + 1, sample_count, failures])
	solve_times.sort()
	var elapsed := Time.get_ticks_msec() - started
	var report := {
		"schema_version": 3,
		"samples": sample_count,
		"generation_failures": failures,
		"generation_failure_rate": snappedf(float(failures) / float(sample_count), 0.0001),
		"impossible_boards": impossible,
		"average_generation_attempts": snappedf(float(total_attempts) / float(sample_count), 0.01),
		"average_generation_ms": snappedf(float(total_generation_ms) / float(sample_count), 0.01),
		"solver_ms_p50": _percentile(solve_times, 0.50),
		"solver_ms_p95": _percentile(solve_times, 0.95),
		"solver_ms_p99": _percentile(solve_times, 0.99),
		"average_branching_factor": snappedf(total_branching / float(sample_count), 0.01),
		"average_initial_selectable": snappedf(float(total_initial) / float(sample_count), 0.01),
		"average_forced_move_ratio": snappedf(total_forced / float(sample_count), 0.001),
		"worst_nodes_explored": worst_nodes,
		"elapsed_ms": elapsed
	}
	report["candidate_rejection_rate"] = snappedf(float(total_attempts - sample_count) / maxi(1, total_attempts), 0.0001)
	for metric: String in totals:
		report[metric] = snappedf(totals[metric] / sample_count, 0.001)
	for world: String in world_totals:
		var row: Dictionary = world_totals[world]
		for metric: String in ["pressure", "random", "greedy", "balanced"]:
			row[metric] = snappedf(float(row[metric]) / row["samples"], 0.001)
		row["rejection_rate"] = snappedf(float(row["attempts"] - row["samples"]) / row["attempts"], 0.001)
	report["worlds"] = world_totals
	var report_file := FileAccess.open(report_path, FileAccess.WRITE)
	report["start_index"] = start_index
	report["solver_times"] = solve_times if args.size() > 2 else []
	report_file.store_string(JSON.stringify(report, "  "))
	print("STRESS: %d candidates, %d failures, %d impossible, mean_attempts=%.2f, p95=%dms, branching=%.2f, elapsed=%.2fs" % [
		sample_count, failures, impossible, report["average_generation_attempts"], report["solver_ms_p95"], report["average_branching_factor"], float(elapsed) / 1000.0
	])
	quit(0 if failures == 0 else 1)

func _percentile(values: Array[int], fraction: float) -> int:
	if values.is_empty():
		return 0
	var index := clampi(int(ceil(fraction * float(values.size()))) - 1, 0, values.size() - 1)
	return values[index]
