class_name LevelSolver
extends RefCounted

const GameStateScript = preload("res://core/gameplay/game_state.gd")

var nodes_explored: int = 0
var max_depth: int = 0
var node_limit: int = 200000
var started_ms: int = 0
var visited: Dictionary = {}
var solution: Array[String] = []

func solve_level(definition: Dictionary) -> Dictionary:
	nodes_explored = 0
	max_depth = 0
	visited.clear()
	solution.clear()
	started_ms = Time.get_ticks_msec()
	var state = GameStateScript.new()
	state.load_level(definition)
	var solved := _search(state, 0)
	return {
		"solved": solved,
		"nodes": nodes_explored,
		"max_depth": max_depth,
		"solution": solution.duplicate(),
		"solve_ms": Time.get_ticks_msec() - started_ms,
		"branching_estimate": snappedf(float(nodes_explored) / float(maxi(1, max_depth)), 0.01),
		"reason": "" if solved else ("node_limit" if nodes_explored >= node_limit else "no_solution")
	}

func _search(state, depth: int) -> bool:
	if state.phase == state.Phase.WON:
		return true
	if state.phase == state.Phase.LOST or nodes_explored >= node_limit:
		return false
	nodes_explored += 1
	max_depth = maxi(max_depth, depth)
	var key := _canonical_key(state)
	if visited.has(key):
		return false
	visited[key] = true
	var moves: Array[String] = state.accessible_item_ids()
	moves.sort_custom(func(a: String, b: String) -> bool: return _move_score(state, a) > _move_score(state, b))
	for item_id: String in moves:
		var next_state = GameStateScript.new()
		next_state.from_snapshot(state.to_snapshot())
		next_state.phase = next_state.Phase.PLAYING
		var result: Dictionary = next_state.select_item(item_id)
		if not result.get("ok", false):
			continue
		if _search(next_state, depth + 1):
			solution.push_front(item_id)
			return true
	return false

func _move_score(state, item_id: String) -> int:
	var item: Dictionary = state.items[item_id]
	if String(item.get("special_type", "")) == "key":
		return 1000
	var destination := String(item.get("destination_id", ""))
	var count: int = state.tray.count(destination)
	var score: int = count * 200
	if destination == state.priority_destination and not state.priority_completed:
		score += 600
	for candidate: Dictionary in state.items.values():
		if item_id in candidate.get("blocker_ids", []):
			score += 10
	return score

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
	return "|".join(remaining) + "#" + ",".join(tray_copy) + "#" + ",".join(groups) + "#" + str(state.priority_moves) + "#" + str(state.priority_completed)
