extends SceneTree

const GeneratorScript = preload("res://core/generation/level_generator.gd")
const SolverScript = preload("res://core/solver/level_solver.gd")

func _initialize() -> void:
	var generator = GeneratorScript.new()
	var failures := 0
	var total_nodes := 0
	var worst_nodes := 0
	var worst_ms := 0
	for index in 1000:
		var level_number := 4 + (index % 147)
		var parameters: Dictionary = generator.campaign_parameters(level_number)
		parameters["id"] = 30000 + index
		parameters["seed"] = 700001 + index * 104729
		var result: Dictionary = SolverScript.new().solve_level(generator.generate_level(parameters))
		if not bool(result["solved"]):
			failures += 1
		total_nodes += int(result["nodes"])
		worst_nodes = maxi(worst_nodes, int(result["nodes"]))
		worst_ms = maxi(worst_ms, int(result["solve_ms"]))
	print("STRESS: 1000 candidates, %d failures, mean_nodes=%.2f, worst_nodes=%d, worst_ms=%d" % [failures, float(total_nodes) / 1000.0, worst_nodes, worst_ms])
	quit(0 if failures == 0 else 1)

