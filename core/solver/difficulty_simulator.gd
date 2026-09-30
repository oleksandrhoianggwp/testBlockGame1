class_name DifficultySimulator
extends RefCounted

const State = preload("res://core/gameplay/game_state.gd")

func analyze(definition: Dictionary, runs: int = 8) -> Dictionary:
	var result := {}
	var failed_pressure := 0.0
	var failed_moves := 0.0
	var failures := 0
	var pressure := 0.0
	for profile: String in ["random", "greedy", "balanced"]:
		var wins := 0
		for run in runs:
			var rng := RandomNumberGenerator.new()
			rng.seed = int(definition.get("layout_seed", definition.get("seed", 1))) + run * 9176 + profile.hash()
			var state = State.new()
			state.record_history = false
			state.load_level(definition)
			for _move in definition.get("items", []).size() + 1:
				if state.phase != state.Phase.PLAYING:
					break
				var actions := _actions(state)
				if actions.is_empty():
					break
				var chosen: Dictionary = actions[int(rng.randi() % actions.size())]
				if profile != "random":
					var best := -INF
					for action: Dictionary in actions:
						var value := _score(state, action, profile) + rng.randf() * 0.35
						if value > best:
							best = value
							chosen = action
				state.select_item(chosen["id"], chosen["dest"])
			pressure += state.peak_tray
			if state.phase == state.Phase.WON:
				wins += 1
			else:
				failures += 1
				failed_pressure += state.peak_tray
				failed_moves += state.move_count
		result["%s_win_rate" % profile] = snappedf(float(wins) / runs, 0.001)
	result["average_failure_pressure"] = snappedf(failed_pressure / maxi(1, failures), 0.01)
	result["average_moves_to_failure"] = snappedf(failed_moves / maxi(1, failures), 0.01)
	result["average_simulated_pressure"] = snappedf(pressure / (runs * 3), 0.01)
	result["simulation_runs_per_profile"] = runs
	return result

func _actions(state) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	for id: String in state.accessible_item_ids():
		if String(state.items[id].get("special_type", "")) == "key":
			actions.append({"id": id, "dest": ""})
		else:
			for dest: String in state.destination_options(id):
				actions.append({"id": id, "dest": dest})
	return actions

func _score(state, action: Dictionary, profile: String) -> float:
	var dest: String = action["dest"]
	if dest.is_empty():
		return 8.0
	var value := float(state.tray.count(dest)) * 5.0
	if profile == "balanced":
		if dest == state.priority_destination and not state.priority_completed:
			value += 4.0 + 6.0 / maxi(1, state.priority_moves)
		var exposed := 0
		for id: String in state.accessible_item_ids():
			if dest in state.destination_options(id):
				exposed += 1
		value += exposed * 1.3
		for item: Dictionary in state.items.values():
			if not bool(item.get("removed", false)) and action["id"] in item.get("blocker_ids", []):
				value += 0.65
		if String(state.items[action["id"]].get("special_type", "")) == "transfer" and dest == String(state.items[action["id"]].get("destination_id", "")):
			value += 2.0
	return value
