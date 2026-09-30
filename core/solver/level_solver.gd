class_name LevelSolver
extends RefCounted

const GameStateScript = preload("res://core/gameplay/game_state.gd")

var nodes_explored: int = 0
var search_nodes: int = 0
var probe_nodes: int = 0
var max_depth: int = 0
var node_limit: int = 200000
var started_ms: int = 0
var visited: Dictionary = {}
var solution: Array[String] = []
var dead_end_count: int = 0
var branch_total: int = 0
var branch_states: int = 0

func solve_level(definition: Dictionary, run_probe: bool = false) -> Dictionary:
	nodes_explored = 0
	search_nodes = 0
	probe_nodes = 0
	max_depth = 0
	visited.clear()
	solution.clear()
	dead_end_count = 0
	branch_total = 0
	branch_states = 0
	started_ms = Time.get_ticks_msec()
	var state = GameStateScript.new()
	state.load_level(definition)
	var initial_selectable := state.accessible_item_ids().size()
	var solved := _search(state, 0)
	var solve_path := solution.duplicate()
	if run_probe:
		_probe_complexity(definition)
	# Legal successor actions are scored even when the best candidate solves first.
	# Count those inspected candidates separately from expanded search states so a
	# branching board cannot masquerade as a linear one.
	nodes_explored = search_nodes + branch_total + probe_nodes
	var path_metrics := _analyze_solution(definition, solve_path) if solved else {
		"average_selectable_count": 0.0,
		"meaningful_decision_count": 0,
		"forced_move_ratio": 1.0,
		"peak_expected_tray_pressure": 0
	}
	var average_branching := float(branch_total) / float(maxi(1, branch_states))
	var difficulty := _difficulty_score(definition, path_metrics, average_branching)
	return {
		"solved": solved,
		"nodes": nodes_explored,
		"nodes_explored": nodes_explored,
		"search_nodes": search_nodes,
		"probe_nodes": probe_nodes,
		"max_depth": max_depth,
		"solution_depth": solve_path.size(),
		"solution": solve_path,
		"solve_ms": Time.get_ticks_msec() - started_ms,
		"average_branching_factor": snappedf(average_branching, 0.01),
		"branching_estimate": snappedf(average_branching, 0.01),
		"initial_selectable_count": initial_selectable,
		"average_selectable_count": path_metrics["average_selectable_count"],
		"meaningful_decision_count": path_metrics["meaningful_decision_count"],
		"forced_move_ratio": path_metrics["forced_move_ratio"],
		"peak_expected_tray_pressure": path_metrics["peak_expected_tray_pressure"],
		"dead_end_count": dead_end_count,
		"difficulty_score": difficulty,
		"reason": "" if solved else ("node_limit" if search_nodes >= node_limit else "no_solution")
	}

func _search(state, depth: int) -> bool:
	if state.phase == state.Phase.WON:
		return true
	if state.phase == state.Phase.LOST or search_nodes >= node_limit:
		dead_end_count += 1
		return false
	search_nodes += 1
	max_depth = maxi(max_depth, depth)
	var key := _canonical_key(state)
	if visited.has(key):
		return false
	visited[key] = true
	var actions := _available_actions(state)
	branch_total += actions.size()
	branch_states += 1
	if actions.is_empty():
		dead_end_count += 1
		return false
	actions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _move_score(state, a) > _move_score(state, b))
	for action: Dictionary in actions:
		var next_state = GameStateScript.new()
		next_state.from_snapshot(state.to_snapshot())
		next_state.phase = next_state.Phase.PLAYING
		var result: Dictionary = next_state.select_item(String(action["item_id"]), String(action.get("destination_id", "")))
		if not result.get("ok", false):
			continue
		if _search(next_state, depth + 1):
			solution.push_front(_encode_action(action))
			return true
	return false

func _available_actions(state) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	for item_id: String in state.accessible_item_ids():
		var options: Array[String] = state.destination_options(item_id)
		if String(state.items[item_id].get("special_type", "")) == "key":
			actions.append({"item_id": item_id, "destination_id": ""})
		elif options.is_empty():
			actions.append({"item_id": item_id, "destination_id": String(state.items[item_id].get("destination_id", ""))})
		else:
			for option: String in options:
				actions.append({"item_id": item_id, "destination_id": option})
	return actions

func _move_score(state, action: Dictionary) -> int:
	var item_id := String(action["item_id"])
	var item: Dictionary = state.items[item_id]
	if String(item.get("special_type", "")) == "key":
		return 1200
	var destination := String(action.get("destination_id", item.get("destination_id", "")))
	var count: int = state.tray.count(destination)
	var score_value: int = count * 900
	var exposed_matching := 0
	for candidate_id: String in state.accessible_item_ids():
		if destination in state.destination_options(candidate_id):
			exposed_matching += 1
	score_value += exposed_matching * 180
	if destination == state.priority_destination and not state.priority_completed:
		score_value += 420
	for candidate: Dictionary in state.items.values():
		if item_id in candidate.get("blocker_ids", []):
			score_value += 14
	if String(item.get("special_type", "")) == "transfer" and destination == String(item.get("destination_id", "")):
		score_value += 120
	return score_value

func _probe_complexity(definition: Dictionary) -> void:
	var state = GameStateScript.new()
	state.load_level(definition)
	var seen: Dictionary = {}
	_probe_state(state, 0, 5, seen)

func _probe_state(state, depth: int, depth_limit: int, seen: Dictionary) -> void:
	if depth >= depth_limit or probe_nodes >= 350 or state.phase in [state.Phase.WON, state.Phase.LOST]:
		return
	var key := _canonical_key(state)
	if seen.has(key):
		return
	seen[key] = true
	probe_nodes += 1
	var actions := _available_actions(state)
	branch_total += actions.size()
	branch_states += 1
	for action: Dictionary in actions:
		if probe_nodes >= 350:
			break
		var next_state = GameStateScript.new()
		next_state.from_snapshot(state.to_snapshot())
		next_state.phase = next_state.Phase.PLAYING
		next_state.select_item(String(action["item_id"]), String(action.get("destination_id", "")))
		_probe_state(next_state, depth + 1, depth_limit, seen)

func _analyze_solution(definition: Dictionary, actions: Array[String]) -> Dictionary:
	var state = GameStateScript.new()
	state.load_level(definition)
	var selectable_total := 0
	var meaningful := 0
	var forced := 0
	var peak_pressure := 0
	for encoded: String in actions:
		var available := state.accessible_item_ids()
		selectable_total += available.size()
		if available.size() <= 1:
			forced += 1
		var visible_destinations: Dictionary = {}
		for item_id: String in available:
			for option: String in state.destination_options(item_id):
				visible_destinations[option] = true
		if available.size() >= 2 and visible_destinations.size() >= 2:
			meaningful += 1
		var action := decode_action(encoded)
		state.select_item(String(action["item_id"]), String(action.get("destination_id", "")))
		peak_pressure = maxi(peak_pressure, state.peak_tray)
	return {
		"average_selectable_count": snappedf(float(selectable_total) / float(maxi(1, actions.size())), 0.01),
		"meaningful_decision_count": meaningful,
		"forced_move_ratio": snappedf(float(forced) / float(maxi(1, actions.size())), 0.001),
		"peak_expected_tray_pressure": peak_pressure
	}

func _difficulty_score(definition: Dictionary, metrics: Dictionary, average_branching: float) -> float:
	var item_count := int(definition.get("items", []).size())
	var pressure := float(metrics.get("peak_expected_tray_pressure", 0)) / float(maxi(1, int(definition.get("tray_capacity", 7))))
	var forced_inverse := 1.0 - float(metrics.get("forced_move_ratio", 1.0))
	var mechanics: Dictionary = definition.get("mechanics", {})
	var mechanic_weight := 0.0
	for key in ["priority", "locks", "mystery", "transfer", "belt_jam", "vip"]:
		var value: Variant = mechanics.get(key, {})
		if (typeof(value) == TYPE_DICTIONARY and not value.is_empty()) or (typeof(value) == TYPE_INT and int(value) > 0):
			mechanic_weight += 0.04
	var score_value := 0.25 * clampf(float(item_count) / 30.0, 0.0, 1.0)
	score_value += 0.25 * clampf(average_branching / 7.0, 0.0, 1.0)
	score_value += 0.25 * pressure
	score_value += 0.15 * forced_inverse
	score_value += mechanic_weight
	return snappedf(clampf(score_value, 0.0, 1.0), 0.001)

func _encode_action(action: Dictionary) -> String:
	var item_id := String(action["item_id"])
	var destination := String(action.get("destination_id", ""))
	return item_id if destination.is_empty() else "%s@%s" % [item_id, destination]

func decode_action(encoded: String) -> Dictionary:
	var split := encoded.split("@", false, 1)
	return {"item_id": split[0], "destination_id": split[1] if split.size() > 1 else ""}

func _canonical_key(state) -> String:
	var remaining: Array[String] = []
	for item_id: String in state.items:
		var item: Dictionary = state.items[item_id]
		if not bool(item.get("removed", false)):
			remaining.append(item_id + ":" + String(item.get("destination_id", "")))
	remaining.sort()
	var tray_copy: Array[String] = state.tray.duplicate()
	tray_copy.sort()
	var groups: Array[String] = state.unlocked_groups.duplicate()
	groups.sort()
	return "|".join(remaining) + "#" + ",".join(tray_copy) + "#" + ",".join(groups) + "#" + str(state.priority_moves) + "#" + str(state.priority_completed) + "#" + str(state.jam_moves)
