extends SceneTree

const GeneratorScript = preload("res://core/generation/level_generator.gd")
const SolverScript = preload("res://core/solver/level_solver.gd")

func _initialize() -> void:
	var generator = GeneratorScript.new()
	var started := Time.get_ticks_msec()
	var args := OS.get_cmdline_user_args()
	var level_id := int(args[0]) if not args.is_empty() else 8
	var parameters: Dictionary = generator.campaign_parameters(level_id, 123456 + level_id * 104729)
	var level: Dictionary = generator.generate_level(parameters)
	var elapsed := Time.get_ticks_msec() - started
	print("PROFILE: level=%d solved=%s elapsed_ms=%d attempts=%d quality=%s" % [level_id, level.get("quality", {}).get("solved", false), elapsed, level.get("generation_attempt", 0), JSON.stringify(level.get("quality", {}))])
	quit(0 if level.get("quality", {}).get("solved", false) else 1)
