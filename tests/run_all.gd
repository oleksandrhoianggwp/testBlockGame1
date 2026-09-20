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
	_test_blockers_and_mystery()
	_test_locks_and_key_undo()
	_test_priority()
	_test_undo_variants()
	_test_extra_slot_and_shuffle()
	_test_generator_determinism()
	_test_solver()
	_test_daily_seed()
	_test_campaign_files()
	_test_save_contract()
	_test_economy_guard()
	_test_scripted_integration_win()
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
		items.append({"id": "i%d" % index, "destination_id": destinations[index], "blocker_ids": [], "special_type": "", "lock_group": ""})
	return {"id": 1, "seed": 1, "tray_capacity": capacity, "items": items, "mechanics": {"priority": {}}}

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
	_expect(state.select_item("i2")["won"], "pending match resolves before capacity loss")
	var snapshot := state.to_snapshot()
	snapshot["phase"] = state.Phase.PLAYING
	snapshot["tray"] = ["par", "par", "par", "par", "par", "par"]
	state.from_snapshot(snapshot)
	_expect(state._resolve_matches() == 2 and state.tray.is_empty(), "multiple restored triplets resolve in batches")
	state.load_level(_simple_level(["par", "tyo"], 2))
	state.select_item("i0")
	_expect(state.select_item("i1")["lost"], "full tray loses after resolution")

func _test_blockers_and_mystery() -> void:
	var level := _simple_level(["par", "par", "par", "tyo", "tyo", "tyo"])
	level["items"][3]["blocker_ids"] = ["i0", "i1", "i2"]
	level["items"][3]["special_type"] = "mystery"
	var state = GameStateScript.new()
	state.load_level(level)
	_expect(not state.is_selectable("i3") and not state.items["i3"]["revealed"], "blocker hides mystery")
	state.select_item("i0"); state.select_item("i1"); state.select_item("i2")
	_expect(state.is_selectable("i3") and state.items["i3"]["revealed"], "mystery reveals when accessible")

func _test_locks_and_key_undo() -> void:
	var level := _simple_level(["par", "par", "par"])
	for item in level["items"]:
		item["lock_group"] = "a"
	level["items"].append({"id": "key", "destination_id": "", "blocker_ids": [], "special_type": "key", "key_group": "a", "lock_group": ""})
	var state = GameStateScript.new()
	state.load_level(level)
	_expect(not state.is_selectable("i0"), "locked luggage cannot be selected")
	state.select_item("key")
	_expect(state.is_selectable("i0") and state.tray.is_empty(), "key unlocks without using tray")
	_expect(state.is_selectable("i1") and state.is_selectable("i2"), "one key unlocks multiple locks")
	_expect(state.undo() and not state.is_selectable("i0"), "undo restores key lock state")

func _test_priority() -> void:
	var level := _simple_level(["par", "par", "par", "tyo", "tyo", "tyo"])
	level["mechanics"]["priority"] = {"destination_id": "par", "moves": 3}
	var state = GameStateScript.new()
	state.load_level(level)
	state.select_item("i0")
	_expect(state.priority_moves == 2, "normal luggage decrements priority moves")
	state.undo()
	_expect(state.priority_moves == 3 and state.tray.is_empty(), "undo restores priority counter")
	state.load_level(level)
	state.select_item("i0"); state.select_item("i1"); state.select_item("i2")
	_expect(state.priority_completed and state.phase != state.Phase.LOST, "priority triplet succeeds at deadline")
	state.load_level(level)
	state.select_item("i3"); state.select_item("i4"); state.select_item("i5")
	_expect(state.phase == state.Phase.LOST and state.loss_reason == "priority", "priority deadline fails")

func _test_undo_variants() -> void:
	var state = GameStateScript.new()
	state.load_level(_simple_level(["par", "par", "par", "tyo", "tyo", "tyo"]))
	state.select_item("i0")
	_expect(state.undo() and state.tray.is_empty() and not state.items["i0"]["removed"], "undo restores normal move")
	state.select_item("i0"); state.select_item("i1"); state.select_item("i2")
	_expect(state.tray.is_empty() and state.undo() and state.tray.size() == 2, "undo restores move that caused match")
	state.activate_extra_slot()
	state.select_item("i2")
	state.undo()
	_expect(state.extra_slot_active and state.tray_capacity == 8, "undo preserves Extra Slot state")

func _test_extra_slot_and_shuffle() -> void:
	var state = GameStateScript.new()
	state.load_level(_simple_level(["par", "par", "par", "tyo", "tyo", "tyo"]))
	_expect(state.activate_extra_slot() and state.tray_capacity == 8 and not state.activate_extra_slot(), "extra slot applies once")
	var before: Dictionary = {}
	for item in state.items.values(): before[item["destination_id"]] = int(before.get(item["destination_id"], 0)) + 1
	_expect(state.shuffle_remaining(), "shuffle succeeds with multiple destinations")
	var after: Dictionary = {}
	for item in state.items.values(): after[item["destination_id"]] = int(after.get(item["destination_id"], 0)) + 1
	_expect(before == after, "shuffle preserves destination counts")
	var definition := _simple_level(["par", "par", "par", "tyo", "tyo", "tyo"])
	var shuffled = GameStateScript.new()
	shuffled.load_level(definition)
	shuffled.shuffle_remaining()
	definition["items"] = shuffled.items.values()
	_expect(SolverScript.new().solve_level(definition)["solved"], "shuffled board remains solver-solvable")

func _test_generator_determinism() -> void:
	var generator = GeneratorScript.new()
	var one: Dictionary = generator.generate_level(generator.campaign_parameters(77))
	var two: Dictionary = generator.generate_level(generator.campaign_parameters(77))
	_expect(JSON.stringify(one) == JSON.stringify(two), "generator is deterministic")
	_expect(one["layout_template"] != generator.generate_level(generator.campaign_parameters(78))["layout_template"], "layout families vary")

func _test_solver() -> void:
	var solver = SolverScript.new()
	var solvable := solver.solve_level(_simple_level(["par", "par", "par"]))
	_expect(solvable["solved"] and solvable["solution"].size() == 3, "solver solves known fixture")
	var impossible := solver.solve_level(_simple_level(["par", "tyo"], 2))
	_expect(not impossible["solved"], "solver rejects impossible fixture")

func _test_daily_seed() -> void:
	var generator = GeneratorScript.new()
	var one: Dictionary = generator.generate_daily("2026-09-20", "salt")
	var two: Dictionary = generator.generate_daily("2026-09-20", "salt")
	var other: Dictionary = generator.generate_daily("2026-09-21", "salt")
	_expect(one["seed"] == two["seed"], "daily seed same for same date")
	_expect(one["seed"] != other["seed"], "daily seed differs by date")

func _test_campaign_files() -> void:
	var unique_seeds: Dictionary = {}
	var all_valid := true
	for level_id in range(1, 151):
		var path := "res://data/campaign/level_%03d.json" % level_id
		if not FileAccess.file_exists(path): all_valid = false; continue
		var level = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(level) != TYPE_DICTIONARY or int(level.get("id", 0)) != level_id: all_valid = false; continue
		unique_seeds[level["seed"]] = true
	_expect(all_valid and unique_seeds.size() == 150, "all 150 baked levels load with unique seeds")

func _test_save_contract() -> void:
	var service = SaveServiceScript.new()
	var defaults: Dictionary = service.defaults()
	_expect(defaults["coins"] == 200 and defaults["boosters"] == {"undo": 3, "shuffle": 3, "extra_slot": 2}, "fresh save defaults")
	var partial: Dictionary = service.migrate({"save_version": 1, "coins": 99})
	_expect(partial["save_version"] == 1 and partial["coins"] == 99, "save migration preserves data")
	service.free()

func _test_economy_guard() -> void:
	var service = SaveServiceScript.new()
	service.data = service.defaults()
	service.data["coins"] = 0
	_expect(not service.purchase_airport_upgrade(1, "entrance", [100, 150, 220]) and service.data["coins"] == 0, "economy prevents negative balance")
	service.free()

func _test_scripted_integration_win() -> void:
	var generator = GeneratorScript.new()
	var level: Dictionary = generator.generate_level(generator.campaign_parameters(31))
	var solved: Dictionary = SolverScript.new().solve_level(level)
	var state = GameStateScript.new()
	state.load_level(level)
	for item_id: String in solved["solution"]:
		state.select_item(item_id)
	_expect(state.phase == state.Phase.WON, "scripted campaign play reaches win")
