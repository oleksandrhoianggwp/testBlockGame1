class_name LevelGenerator
extends RefCounted

const SolverScript = preload("res://core/solver/level_solver.gd")
const SimulatorScript = preload("res://core/solver/difficulty_simulator.gd")
const CAMPAIGN_PATH := "res://data/configs/campaign.json"
const DESTINATIONS := ["par", "tyo", "iev", "rom", "cai", "sel", "syd", "rio", "osl", "yto", "lim", "nbo"]
const LAYOUTS := ["terminal_rows", "carousel", "split_belt", "gate_cluster", "runway_cross", "cargo_bays"]
const SHIFT_EVENTS := ["priority_flight", "lost_tag", "belt_jam", "vip_baggage", "heavy_load"]
const STACK_ANCHORS := [
	Vector2(0.20, 0.27), Vector2(0.50, 0.24), Vector2(0.80, 0.27),
	Vector2(0.20, 0.54), Vector2(0.50, 0.51), Vector2(0.80, 0.54),
	Vector2(0.35, 0.39), Vector2(0.65, 0.39), Vector2(0.50, 0.66)
]

var _campaign_cache: Dictionary = {}

func campaign_config() -> Dictionary:
	if _campaign_cache.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(CAMPAIGN_PATH))
		_campaign_cache = parsed if typeof(parsed) == TYPE_DICTIONARY else {"worlds": []}
	return _campaign_cache.duplicate(true)

func campaign_count() -> int:
	var count := 0
	for world: Dictionary in campaign_config().get("worlds", []):
		count += int(world.get("stage_count", 0))
	return count

func world_for_level(level_id: int) -> Dictionary:
	var cursor := 0
	for world: Dictionary in campaign_config().get("worlds", []):
		var stage_count := int(world.get("stage_count", 0))
		if level_id <= cursor + stage_count:
			var result := world.duplicate(true)
			result["first_level"] = cursor + 1
			result["last_level"] = cursor + stage_count
			result["local_level"] = level_id - cursor
			return result
		cursor += stage_count
	return {}

func campaign_parameters(level_id: int, seed_override: int = -1) -> Dictionary:
	var count := campaign_count()
	var safe_level := clampi(level_id, 1, maxi(1, count))
	var world := world_for_level(safe_level)
	var local_level := int(world.get("local_level", 1))
	var stage_count := int(world.get("stage_count", 15))
	var progress := float(local_level - 1) / float(maxi(1, stage_count - 1))
	var group_range: Array = world.get("groups", [4, 6])
	var destination_range: Array = world.get("destinations", [3, 4])
	var group_count := int(round(lerpf(float(group_range[0]), float(group_range[1]), progress)))
	var destination_count := int(round(lerpf(float(destination_range[0]), float(destination_range[1]), progress)))
	var world_id := int(world.get("id", 1))
	var mechanic := String(world.get("mechanic", "basic"))
	var seed_value := seed_override if seed_override >= 0 else 17011 + safe_level * 7919
	var parameters := {
		"id": safe_level,
		"world": world_id,
		"local_level": local_level,
		"seed": seed_value,
		"content_version": int(campaign_config().get("content_version", 2)),
		"tray_capacity": 7,
		"group_count": group_count,
		"destination_count": clampi(destination_count, 3, group_count),
		"stack_count": clampi(5 + int(progress * 2.0) + int(world_id >= 4), 5, 8),
		"layout_template": LAYOUTS[(safe_level + world_id) % LAYOUTS.size()],
		"difficulty": snappedf(float(safe_level - 1) / float(maxi(1, count - 1)), 0.001),
		"mystery_count": 0,
		"lock_enabled": false,
		"priority_enabled": false,
		"transfer_enabled": false,
		"challenge": local_level in [8, 15]
	}
	if world_id >= 2:
		parameters["mystery_count"] = clampi(1 + int(local_level / 4), 1, 4)
	if world_id >= 3:
		parameters["lock_enabled"] = true
	if world_id >= 4 or local_level == 15:
		parameters["priority_enabled"] = true
	if world_id >= 5:
		parameters["transfer_enabled"] = local_level >= 3
	if mechanic == "mystery":
		parameters["mystery_count"] = maxi(2, int(parameters["mystery_count"]))
	return parameters

func generate_level(parameters: Dictionary) -> Dictionary:
	var base_seed := int(parameters.get("seed", 1))
	var best_level: Dictionary = {}
	var best_result: Dictionary = {}
	var budget := int(parameters.get("retry_budget", 96))
	for attempt in budget:
		var candidate_seed := base_seed + attempt * 104729
		var candidate := _build_candidate(parameters, candidate_seed, attempt)
		var solver = SolverScript.new()
		solver.node_limit = 350
		var result: Dictionary = solver.solve_level(candidate)
		if bool(result.get("solved", false)):
			result.merge(SimulatorScript.new().analyze(candidate, 6), true)
		candidate["quality"] = _quality_payload(result)
		if best_level.is_empty() or _quality_rank(result) > _quality_rank(best_result):
			best_level = candidate
			best_result = result
		if _quality_passes(result, parameters):
			return candidate
	push_error("Generation quality exhausted %d attempts: level=%d seed=%d best=%s" % [budget, int(parameters.get("id", 0)), base_seed, JSON.stringify(best_result)])
	return {"generation_failed": true, "seed": base_seed, "generation_attempt": budget, "quality": best_result}

func generate_daily(date_key: String, salt: String) -> Dictionary:
	var seed_value := int(hash(date_key + salt)) & 0x7fffffff
	var params := campaign_parameters(maxi(1, campaign_count() - 8), seed_value)
	params["id"] = 10000
	params["mode"] = "daily"
	var level := generate_level(params)
	level["date_key"] = date_key
	return level

func generate_shift(run_seed: int, round_number: int, retry_budget: int = 96) -> Dictionary:
	var round_seed := int(hash("%d:%d:airport-shift" % [run_seed, round_number])) & 0x7fffffff
	var rng := RandomNumberGenerator.new()
	rng.seed = round_seed
	var event_id: String = String(SHIFT_EVENTS[int(rng.randi() % SHIFT_EVENTS.size())])
	var stage := clampi(8 + round_number * 4, 8, campaign_count())
	var params := campaign_parameters(stage, round_seed)
	params["id"] = 20000 + round_number
	params["mode"] = "shift"
	params["shift_round"] = round_number
	params["shift_event"] = event_id
	params["retry_budget"] = retry_budget
	if event_id == "heavy_load":
		params["group_count"] = mini(11, int(params["group_count"]) + 1)
	if event_id == "lost_tag":
		params["mystery_count"] = maxi(3, int(params.get("mystery_count", 0)) + 2)
	if event_id == "priority_flight":
		params["priority_enabled"] = true
	var level := generate_level(params)
	level["shift_event"] = event_id
	level["shift_round"] = round_number
	return level

func _build_candidate(parameters: Dictionary, layout_seed: int, attempt: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = layout_seed
	var group_count := int(parameters.get("group_count", 4))
	var stack_count := clampi(int(parameters.get("stack_count", 6)), 5, STACK_ANCHORS.size())
	var destination_count := clampi(int(parameters.get("destination_count", 3)), 3, mini(group_count, DESTINATIONS.size()))
	var destination_pool: Array[String] = []
	for destination: String in DESTINATIONS:
		destination_pool.append(destination)
	_shuffle(destination_pool, rng)
	destination_pool = destination_pool.slice(0, destination_count)
	var group_destinations: Array[String] = []
	for index in group_count:
		group_destinations.append(destination_pool[index % destination_pool.size()])
	_shuffle(group_destinations, rng)
	var stacks: Array[Array] = []
	for _index in stack_count:
		stacks.append([])
	var items: Array[Dictionary] = []
	var transfer_group := clampi(2 + int(rng.randi() % maxi(1, group_count - 2)), 0, group_count - 1)
	var mystery_budget := int(parameters.get("mystery_count", 0))
	for group_index in group_count:
		var candidate_stacks: Array[int] = []
		for stack_index in stack_count:
			candidate_stacks.append(stack_index)
		_shuffle(candidate_stacks, rng)
		candidate_stacks.sort_custom(func(a: int, b: int) -> bool: return stacks[a].size() < stacks[b].size())
		var selected_stacks := candidate_stacks.slice(0, 3)
		for item_index in 3:
			var destination := group_destinations[group_index]
			var item_type := ""
			var options: Array[String] = []
			if bool(parameters.get("transfer_enabled", false)) and group_index == transfer_group and item_index == 2:
				item_type = "transfer"
				options = [destination, destination_pool[(destination_pool.find(destination) + 1) % destination_pool.size()]]
			elif mystery_budget > 0 and group_index > 0 and item_index == int(group_index % 3):
				item_type = "mystery"
				mystery_budget -= 1
			var stack_index := int(selected_stacks[item_index])
			var item := {
				"id": "l%05d_g%02d_%d" % [int(parameters.get("id", 0)), group_index, item_index],
				"destination_id": destination,
				"destination_options": options,
				"group_index": group_index,
				"stack_index": stack_index,
				"region": stack_index % 3,
				"position": [],
				"size": [0.255, 0.125],
				"rotation": rng.randf_range(-6.0, 6.0),
				"scale": rng.randf_range(0.94, 1.04),
				"z_index": 0,
				"blocker_ids": [],
				"special_type": item_type,
				"special_data": {},
				"lock_group": ""
			}
			stacks[stack_index].append(item)
			items.append(item)
	# Physical stack order is independent of destination group order. A seeded
	# partial scramble increases with world; it creates exposure tradeoffs while
	# keeping early boards approachable. Every resulting candidate is validated.
	var world_id := int(parameters.get("world", 1))
	for stack: Array in stacks:
		if rng.randf() < 0.10 + world_id * 0.08:
			_shuffle(stack, rng)
	if bool(parameters.get("lock_enabled", false)):
		var lock_group_index := clampi(2 + int(rng.randi() % maxi(1, group_count - 2)), 2, group_count - 1)
		for item: Dictionary in items:
			if int(item["group_index"]) == lock_group_index:
				item["lock_group"] = "cargo_%d" % lock_group_index
		var key_stack := int(rng.randi() % stack_count)
		items.append({
			"id": "key_%05d" % int(parameters.get("id", 0)), "destination_id": "",
			"destination_options": [], "group_index": -1, "stack_index": key_stack,
			"region": key_stack % 3, "position": [0.5, 0.13], "size": [0.17, 0.10],
			"rotation": 0.0, "scale": 1.0, "z_index": 2000, "blocker_ids": [],
			"special_type": "key", "special_data": {},
			"key_group": "cargo_%d" % lock_group_index, "lock_group": ""
		})
	_position_and_block(items, stacks, rng, String(parameters.get("layout_template", "terminal_rows")))
	var priority: Dictionary = {}
	if bool(parameters.get("priority_enabled", false)):
		var priority_group := clampi(2 + int(rng.randi() % mini(3, maxi(1, group_count - 2))), 2, group_count - 1)
		priority = {"destination_id": group_destinations[priority_group], "moves": clampi(priority_group * 3 + 5, 8, 30)}
	var belt_jam: Dictionary = {}
	var vip: Dictionary = {}
	var event_id := String(parameters.get("shift_event", ""))
	if event_id == "belt_jam":
		belt_jam = {"region": int(rng.randi() % 3), "moves": 3}
	if event_id == "vip_baggage":
		vip = {"destination_id": group_destinations[clampi(1 + int(rng.randi() % maxi(1, group_count - 1)), 1, group_count - 1)], "bonus": 35}
	return {
		"schema_version": 2,
		"id": int(parameters.get("id", 0)),
		"world": int(parameters.get("world", 1)),
		"local_level": int(parameters.get("local_level", 1)),
		"seed": int(parameters.get("seed", 1)),
		"layout_seed": layout_seed,
		"generation_attempt": attempt + 1,
		"content_version": int(parameters.get("content_version", 2)),
		"tray_capacity": int(parameters.get("tray_capacity", 7)),
		"layout_template": String(parameters.get("layout_template", "terminal_rows")),
		"difficulty_template": float(parameters.get("difficulty", 0.0)),
		"items": items,
		"mechanics": {
			"mystery": int(parameters.get("mystery_count", 0)),
			"locks": 1 if bool(parameters.get("lock_enabled", false)) else 0,
			"transfer": 1 if bool(parameters.get("transfer_enabled", false)) else 0,
			"priority": priority,
			"belt_jam": belt_jam,
			"vip": vip
		}
	}

func _position_and_block(items: Array[Dictionary], stacks: Array[Array], rng: RandomNumberGenerator, layout: String) -> void:
	for stack_index in stacks.size():
		var anchor: Vector2 = Vector2(STACK_ANCHORS[stack_index])
		if layout == "carousel":
			var angle := TAU * float(stack_index) / float(stacks.size())
			anchor = Vector2(0.5 + cos(angle) * 0.29, 0.43 + sin(angle) * 0.22)
		elif layout == "split_belt":
			anchor.x += -0.035 if stack_index % 2 == 0 else 0.035
		elif layout == "runway_cross":
			anchor.y += (float(stack_index % 3) - 1.0) * 0.025
		for depth in stacks[stack_index].size():
			var item: Dictionary = stacks[stack_index][depth]
			var point: Vector2 = anchor + Vector2(rng.randf_range(-0.012, 0.012), float(depth) * 0.009)
			item["position"] = [clampf(point.x, 0.12, 0.88), clampf(point.y, 0.16, 0.72)]
			item["z_index"] = 1000 - depth * 10 - stack_index
	for item: Dictionary in items:
		if String(item.get("special_type", "")) == "key":
			continue
		var blockers: Array[String] = []
		for candidate: Dictionary in items:
			if candidate == item or String(candidate.get("special_type", "")) == "key":
				continue
			if int(candidate.get("z_index", 0)) > int(item.get("z_index", 0)) and _overlaps(item, candidate):
				blockers.append(String(candidate["id"]))
		blockers.sort()
		item["blocker_ids"] = blockers

func _overlaps(a: Dictionary, b: Dictionary) -> bool:
	var ap: Array = a.get("position", [0.5, 0.5])
	var bp: Array = b.get("position", [0.5, 0.5])
	var asize: Array = a.get("size", [0.25, 0.125])
	var bsize: Array = b.get("size", [0.25, 0.125])
	return absf(float(ap[0]) - float(bp[0])) < (float(asize[0]) + float(bsize[0])) * 0.43 and absf(float(ap[1]) - float(bp[1])) < (float(asize[1]) + float(bsize[1])) * 0.43

func _quality_passes(result: Dictionary, parameters: Dictionary) -> bool:
	if not bool(result.get("solved", false)):
		return false
	var onboarding := int(parameters.get("id", 1)) <= 3 and String(parameters.get("mode", "campaign")) == "campaign"
	var min_initial := 3 if onboarding else 4
	var min_branching := 2.2 if onboarding else 2.8
	var depth := maxi(1, int(result.get("solution_depth", 0)))
	var world := int(parameters.get("world", 1))
	var pressure_floor := 3 if world == 1 else 4 if world <= 3 else 5
	if bool(parameters.get("challenge", false)) and world >= 3:
		pressure_floor = 5
	var structural := int(result.get("initial_selectable_count", 0)) >= min_initial \
		and float(result.get("average_branching_factor", 0.0)) >= min_branching \
		and int(result.get("meaningful_decision_count", 0)) >= int(ceil(depth * (0.25 if onboarding else 0.45))) \
		and float(result.get("forced_move_ratio", 1.0)) <= (0.35 if onboarding else 0.20) \
		and float(result.get("meaningful_choice_score", 0.0)) >= (0.35 if onboarding else 0.48) \
		and int(result.get("peak_expected_tray_pressure", 0)) >= pressure_floor \
		and int(result.get("peak_expected_tray_pressure", 0)) <= (4 if world == 1 and not bool(parameters.get("challenge", false)) else 6)
	if not structural:
		return false
	if result.has("random_win_rate"):
		if world >= 4 and float(result["balanced_win_rate"]) < 0.33:
			return false
		if world >= 4 and float(result["random_win_rate"]) > 0.5:
			return false
		if bool(parameters.get("challenge", false)) and world >= 2 and float(result["greedy_win_rate"]) > 0.85:
			return false
	return true

func _quality_payload(result: Dictionary) -> Dictionary:
	var keys := [
		"solved", "solution_depth", "nodes_explored", "average_branching_factor",
		"initial_selectable_count", "average_selectable_count", "meaningful_decision_count",
		"forced_move_ratio", "peak_expected_tray_pressure", "dead_end_count",
		"difficulty_score", "meaningful_choice_score", "random_win_rate", "greedy_win_rate",
		"balanced_win_rate", "average_failure_pressure", "average_moves_to_failure",
		"average_simulated_pressure", "simulation_runs_per_profile"
	]
	var payload: Dictionary = {}
	for key: String in keys:
		payload[key] = result.get(key)
	return payload

func _quality_rank(result: Dictionary) -> float:
	if result.is_empty() or not bool(result.get("solved", false)):
		return -1000.0
	return float(result.get("average_branching_factor", 0.0)) * 10.0 \
		+ float(result.get("meaningful_decision_count", 0)) \
		- float(result.get("forced_move_ratio", 1.0)) * 20.0

func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := int(rng.randi_range(0, index))
		var value = values[index]
		values[index] = values[swap_index]
		values[swap_index] = value
