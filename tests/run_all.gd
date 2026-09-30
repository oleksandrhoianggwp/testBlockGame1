extends SceneTree

const GameStateScript = preload("res://core/gameplay/game_state.gd")
const GeneratorScript = preload("res://core/generation/level_generator.gd")
const SolverScript = preload("res://core/solver/level_solver.gd")
const SaveServiceScript = preload("res://services/save_service.gd")

var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	print("Lost & Sorted automated tests")
	_test_tray_and_matching()
	_test_blockers_mystery_and_geometry()
	_test_locks_and_priority()
	_test_undo_exactness()
	_test_extra_slot_and_shuffle()
	_test_generator_quality_and_determinism()
	_test_boring_board_rejection()
	_test_destination_counts_and_transfer()
	_test_seed_contracts()
	_test_campaign_files_and_progression()
	_test_save_migration()
	_test_generated_solver_integration()
	print("TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _expect(condition: bool, name: String) -> void:
	if condition:
		passed += 1
		print("PASS ", name)
	else:
		failed += 1
		printerr("FAIL ", name)

func _simple_level(destinations: Array[String], capacity: int = 7) -> Dictionary:
	var items: Array[Dictionary] = []
	for index in destinations.size():
		items.append({"id": "i%d" % index, "destination_id": destinations[index], "destination_options": [], "blocker_ids": [], "special_type": "", "lock_group": "", "region": 0})
	return {"id": 1, "seed": 1, "tray_capacity": capacity, "items": items, "mechanics": {"priority": {}, "belt_jam": {}, "vip": {}}}

func _test_tray_and_matching() -> void:
	var state = GameStateScript.new()
	state.load_level(_simple_level(["par", "par", "par"]))
	_expect(state.select_item("i0")["matches"] == 0, "tray insert has no premature match")
	state.select_item("i1")
	var event: Dictionary = state.select_item("i2")
	_expect(event["matches"] == 1 and state.tray.is_empty(), "exact triplet resolves")
	_expect(state.phase == state.Phase.WON, "empty board and tray wins")
	state.load_level(_simple_level(["par", "par", "par"], 3))
	state.select_item("i0"); state.select_item("i1")
	_expect(state.select_item("i2")["won"], "match resolves before capacity loss")
	state.load_level(_simple_level(["par", "tyo"], 2))
	state.select_item("i0")
	_expect(state.select_item("i1")["lost"], "full tray loses after resolution")

func _test_blockers_mystery_and_geometry() -> void:
	var generator = GeneratorScript.new()
	var level: Dictionary = generator.generate_level(generator.campaign_parameters(20, 220020))
	var state = GameStateScript.new()
	state.load_level(level)
	var available := state.accessible_item_ids()
	var destinations: Dictionary = {}
	for item_id: String in available:
		for destination: String in state.destination_options(item_id):
			destinations[destination] = true
	_expect(available.size() >= 4 and destinations.size() >= 2, "several different destinations are selectable simultaneously")
	var geometric := true
	for item: Dictionary in level["items"]:
		for blocker_id: String in item.get("blocker_ids", []):
			var blocker: Dictionary = {}
			for candidate: Dictionary in level["items"]:
				if String(candidate["id"]) == blocker_id:
					blocker = candidate
					break
			if blocker.is_empty() or not generator._overlaps(item, blocker):
				geometric = false
	_expect(geometric, "blocker graph comes from geometric overlap")
	var mystery_has_choice := false
	for item_id: String in available:
		if String(state.items[item_id].get("special_type", "")) == "mystery" and bool(state.items[item_id].get("revealed", false)) and available.size() > 1:
			mystery_has_choice = true
	_expect(mystery_has_choice, "accessible mystery reveals while other choices remain")

func _test_locks_and_priority() -> void:
	var generator = GeneratorScript.new()
	var lock_level: Dictionary = generator.generate_level(generator.campaign_parameters(31, 310031))
	var lock_result: Dictionary = SolverScript.new().solve_level(lock_level)
	_expect(lock_result["solved"] and int(lock_level["mechanics"]["locks"]) > 0, "locks and keys cannot deadlock generated level")
	var priority_level: Dictionary = generator.generate_level(generator.campaign_parameters(46, 460046))
	var priority_result: Dictionary = SolverScript.new().solve_level(priority_level)
	_expect(priority_result["solved"] and not priority_level["mechanics"]["priority"].is_empty(), "priority objective is achievable")

func _test_undo_exactness() -> void:
	var level := _simple_level(["par", "par", "par", "tyo", "tyo", "tyo"])
	level["mechanics"]["priority"] = {"destination_id": "tyo", "moves": 8}
	level["mechanics"]["belt_jam"] = {"region": 2, "moves": 2}
	var state = GameStateScript.new()
	state.load_level(level)
	var before := state.to_snapshot()
	state.select_item("i0")
	var undone := state.undo()
	var after := state.to_snapshot()
	var exact: bool = before["items"] == after["items"] and before["tray"] == after["tray"] \
		and before["priority_moves"] == after["priority_moves"] and before["jam_moves"] == after["jam_moves"] \
		and before["move_count"] == after["move_count"] and before["phase"] == after["phase"]
	_expect(undone and exact, "undo restores exact pre-move board state")

func _test_extra_slot_and_shuffle() -> void:
	var state = GameStateScript.new()
	state.load_level(_simple_level(["par", "par", "par", "tyo", "tyo", "tyo"]))
	_expect(state.activate_extra_slot() and state.tray_capacity == 8 and not state.activate_extra_slot(), "extra slot applies once")
	var generator = GeneratorScript.new()
	var level: Dictionary = generator.generate_level(generator.campaign_parameters(25, 250025))
	state.load_level(level)
	var shuffled := state.shuffle_remaining()
	level["items"] = state.items.values()
	var solved := SolverScript.new().solve_level(level)
	_expect(shuffled and solved["solved"], "shuffle keeps the level solver-solvable")

func _test_generator_quality_and_determinism() -> void:
	var generator = GeneratorScript.new()
	var parameters := generator.campaign_parameters(40, 404040)
	var one: Dictionary = generator.generate_level(parameters)
	var two: Dictionary = generator.generate_level(parameters)
	_expect(JSON.stringify(one) == JSON.stringify(two), "generator is deterministic for a seed")
	var quality: Dictionary = one["quality"]
	_expect(bool(quality["solved"]), "generated level is solvable")
	_expect(float(quality["average_branching_factor"]) >= 2.8 and int(quality["meaningful_decision_count"]) >= 8, "generated board has meaningful decision complexity")
	_expect(int(quality["nodes_explored"]) > int(quality["solution_depth"]), "validation distinguishes branching from linear depth")

func _test_boring_board_rejection() -> void:
	var level := _simple_level(["par", "par", "par", "tyo", "tyo", "tyo"])
	level["items"][1]["blocker_ids"] = ["i0"]
	level["items"][2]["blocker_ids"] = ["i1"]
	level["items"][3]["blocker_ids"] = ["i2"]
	level["items"][4]["blocker_ids"] = ["i3"]
	level["items"][5]["blocker_ids"] = ["i4"]
	var result: Dictionary = SolverScript.new().solve_level(level)
	var parameters := {"id": 20, "mode": "campaign"}
	_expect(result["solved"] and not GeneratorScript.new()._quality_passes(result, parameters), "generator rejects nearly-linear boring board")

func _test_destination_counts_and_transfer() -> void:
	var generator = GeneratorScript.new()
	var level: Dictionary = generator.generate_level(generator.campaign_parameters(68, 680068))
	var counts: Dictionary = {}
	var transfer_destinations: Dictionary = {}
	for item: Dictionary in level["items"]:
		if String(item.get("special_type", "")) == "key":
			continue
		if String(item.get("special_type", "")) == "transfer":
			for option: String in item.get("destination_options", []):
				transfer_destinations[option] = true
		else:
			var destination := String(item["destination_id"])
			counts[destination] = int(counts.get(destination, 0)) + 1
	var counts_valid := true
	for destination: String in counts:
		if int(counts[destination]) % 3 != 0 and not transfer_destinations.has(destination):
			counts_valid = false
	_expect(counts_valid, "destination counts are tripled unless explicitly transfer-special")
	var transfer_level := _simple_level(["par", "par"])
	transfer_level["items"].append({"id": "t", "destination_id": "par", "destination_options": ["par", "rom"], "blocker_ids": [], "special_type": "transfer", "lock_group": "", "region": 0})
	var state = GameStateScript.new()
	state.load_level(transfer_level)
	state.select_item("i0"); state.select_item("i1")
	var requires_choice := not bool(state.select_item("t").get("ok", false))
	var selected: Dictionary = state.select_item("t", "par")
	_expect(requires_choice and selected["won"], "transfer baggage requires and applies a valid destination choice")

func _test_seed_contracts() -> void:
	var service = SaveServiceScript.new()
	service.data = service.defaults()
	var first := service.campaign_seed(7, 7007, false)
	var retry := service.campaign_seed(7, 9999, false)
	service.data["campaign_seeds"].erase("7")
	var replay := service.campaign_seed(7, 9999, false)
	_expect(first == retry and replay != first, "retry uses persisted campaign seed and cleared replay can regenerate")
	var generator = GeneratorScript.new()
	var daily_one: Dictionary = generator.generate_daily("2026-09-30", "salt")
	var daily_two: Dictionary = generator.generate_daily("2026-09-30", "salt")
	var daily_other: Dictionary = generator.generate_daily("2026-10-01", "salt")
	_expect(JSON.stringify(daily_one) == JSON.stringify(daily_two) and daily_one["seed"] != daily_other["seed"], "Daily uses deterministic date seed")
	var shift_one: Dictionary = generator.generate_shift(424242, 5)
	var shift_two: Dictionary = generator.generate_shift(424242, 5)
	var shift_other: Dictionary = generator.generate_shift(424242, 6)
	_expect(JSON.stringify(shift_one) == JSON.stringify(shift_two) and shift_one["seed"] != shift_other["seed"], "Airport Shift is reproducible from run seed and round")
	service.free()

func _test_campaign_files_and_progression() -> void:
	var generator = GeneratorScript.new()
	var count := generator.campaign_count()
	var valid := count == 75
	for level_id in range(1, count + 1):
		var path := "res://data/campaign/level_%03d.json" % level_id
		if not FileAccess.file_exists(path):
			valid = false
			break
		var level = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(level) != TYPE_DICTIONARY or int(level.get("id", 0)) != level_id:
			valid = false
			break
	_expect(valid and not FileAccess.file_exists("res://data/campaign/level_076.json"), "data-driven campaign contains exactly 75 stages")
	var service = SaveServiceScript.new()
	service.data = service.defaults()
	service.complete_level(1, 3, 500, 50, count, false)
	var unlocked_second := int(service.data["current_level"]) == 2
	service.complete_level(count, 3, 500, 50, count, false)
	_expect(unlocked_second and int(service.data["current_level"]) == count, "campaign unlock progression respects configured count")
	service.free()

func _test_save_migration() -> void:
	var service = SaveServiceScript.new()
	var old := {
		"save_version": 1,
		"current_level": 150,
		"coins": 321,
		"levels": {"1": {"completed": true, "stars": 2, "best_score": 100}},
		"airport_progress": {"1": {"seating": 2, "departures": 1}},
		"endless": {"high_score": 777}
	}
	var migrated: Dictionary = service.migrate(old)
	_expect(migrated["save_version"] == 2 and migrated["current_level"] == 75 and migrated["campaign_seeds"].is_empty(), "save migration resets stale seeds and maps campaign progress")
	_expect(migrated["airport_progress"]["1"]["baggage"] == 2 and migrated["shift"]["high_score"] == 777, "save migration preserves airport and endless value in new schema")
	var merged := service.defaults()
	service._merge_known(merged, {"levels": {"3": {"completed": true, "stars": 2}}, "campaign_seeds": {"4": 4444}})
	_expect(merged["levels"].has("3") and merged["campaign_seeds"].get("4") == 4444, "save loading preserves dynamic progress and seed keys")
	service.free()

func _test_generated_solver_integration() -> void:
	var generator = GeneratorScript.new()
	var all_won := true
	for level_id in [1, 15, 16, 30, 31, 45, 46, 60, 61, 75]:
		var level: Dictionary = generator.generate_level(generator.campaign_parameters(level_id, level_id * 99173))
		var solver = SolverScript.new()
		var result: Dictionary = solver.solve_level(level)
		var state = GameStateScript.new()
		state.load_level(level)
		for encoded: String in result["solution"]:
			var action: Dictionary = solver.decode_action(encoded)
			state.select_item(String(action["item_id"]), String(action["destination_id"]))
		if state.phase != state.Phase.WON:
			all_won = false
	_expect(all_won, "solver solutions win representative levels across all tiers")
