extends SceneTree

const GeneratorScript = preload("res://core/generation/level_generator.gd")
const SolverScript = preload("res://core/solver/level_solver.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var sample_count := maxi(1, int(args[0])) if not args.is_empty() else 10000
	var generator = GeneratorScript.new()
	var failures := 0
	var impossible := 0
	var total_attempts := 0
	var total_generation_ms := 0
	var total_branching := 0.0
	var total_initial := 0
	var total_forced := 0.0
	var solve_times: Array[int] = []
	var worst_nodes := 0
	var started := Time.get_ticks_msec()
	for index in sample_count:
		var level_number := 1 + index % generator.campaign_count()
		var parameters: Dictionary = generator.campaign_parameters(level_number, 700001 + index * 104729)
		var generation_started := Time.get_ticks_msec()
		var level: Dictionary = generator.generate_level(parameters)
		total_generation_ms += Time.get_ticks_msec() - generation_started
		total_attempts += int(level.get("generation_attempt", 0))
		var solver = SolverScript.new()
		solver.node_limit = 1500
		var result: Dictionary = solver.solve_level(level)
		solve_times.append(int(result.get("solve_ms", 0)))
		if not bool(result.get("solved", false)):
			impossible += 1
			failures += 1
		elif not generator._quality_passes(result, parameters):
			failures += 1
		total_branching += float(result.get("average_branching_factor", 0.0))
		total_initial += int(result.get("initial_selectable_count", 0))
		total_forced += float(result.get("forced_move_ratio", 1.0))
		worst_nodes = maxi(worst_nodes, int(result.get("nodes_explored", 0)))
		if (index + 1) % 1000 == 0:
			print("STRESS progress %d/%d failures=%d" % [index + 1, sample_count, failures])
	solve_times.sort()
	var elapsed := Time.get_ticks_msec() - started
	var report := {
		"schema_version": 2,
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
	var report_file := FileAccess.open("res://data/campaign/stress_report.json", FileAccess.WRITE)
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
