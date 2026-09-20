class_name LevelGenerator
extends RefCounted

const DESTINATIONS := ["par", "tyo", "iev", "rom", "cai", "sel", "syd", "rio", "osl", "yto", "lim", "nbo"]
const LAYOUTS := ["pyramid", "wings", "diamond", "double_stack", "spiral", "terminals", "bridge", "cross", "split_islands", "staircase", "ring", "compact_box", "fan", "twin_towers", "runway"]

func campaign_parameters(level_id: int) -> Dictionary:
	var world := int((level_id - 1) / 30) + 1
	var local_level := (level_id - 1) % 30 + 1
	var group_count := 2 if level_id == 1 else (3 if level_id == 2 else clampi(3 + int((level_id - 1) / 15), 3, 12))
	var destination_count := clampi(2 + int((level_id - 1) / 18), 2, mini(10, group_count))
	var mystery_count := 0
	var lock_count := 0
	var priority_enabled := false
	if level_id >= 31:
		mystery_count = clampi(1 + int((level_id - 31) / 24), 1, 4) * 3
	if level_id >= 61:
		lock_count = 3
	if level_id >= 91:
		priority_enabled = true
	return {
		"id": level_id, "world": world, "local_level": local_level,
		"seed": 17011 + level_id * 7919, "content_version": 1,
		"tray_capacity": 7, "group_count": group_count,
		"destination_count": destination_count,
		"layout_template": LAYOUTS[(level_id - 1) % LAYOUTS.size()],
		"difficulty": snappedf(float(level_id - 1) / 149.0, 0.001),
		"mystery_count": mystery_count, "lock_count": lock_count,
		"priority_enabled": priority_enabled
	}

func generate_level(parameters: Dictionary) -> Dictionary:
	var level_id := int(parameters["id"])
	var rng := RandomNumberGenerator.new()
	rng.seed = int(parameters["seed"])
	var group_count := int(parameters["group_count"])
	var destination_count := mini(int(parameters["destination_count"]), group_count)
	var destination_pool: Array[String] = []
	var offset := int(rng.randi_range(0, DESTINATIONS.size() - 1))
	for index in destination_count:
		destination_pool.append(DESTINATIONS[(offset + index) % DESTINATIONS.size()])
	var group_destinations: Array[String] = []
	for group_index in group_count:
		group_destinations.append(destination_pool[group_index % destination_pool.size()])
	var items: Array[Dictionary] = []
	var previous_group_ids: Array[String] = []
	var mystery_remaining := int(parameters.get("mystery_count", 0))
	var lock_enabled := int(parameters.get("lock_count", 0)) > 0
	for group_index in group_count:
		var current_group_ids: Array[String] = []
		for item_index in 3:
			current_group_ids.append("l%03d_g%02d_%d" % [level_id, group_index, item_index])
		for item_index in 3:
			var item_id := current_group_ids[item_index]
			var point := _layout_point(String(parameters["layout_template"]), group_index, item_index, group_count)
			var special := ""
			if mystery_remaining > 0 and group_index > 0:
				special = "mystery"
				mystery_remaining -= 1
			var item := {
				"id": item_id, "destination_id": group_destinations[group_index],
				"position": point, "rotation": rng.randf_range(-7.0, 7.0),
				"scale": 1.0, "z_index": group_count - group_index,
				"blocker_ids": previous_group_ids.duplicate(),
				"special_type": special, "special_data": {},
				"lock_group": "cargo_a" if lock_enabled and group_index == 1 else ""
			}
			items.append(item)
		previous_group_ids = current_group_ids
	if lock_enabled:
		items.append({
			"id": "key_%03d" % level_id, "destination_id": "", "position": [0.5, 0.12],
			"rotation": 0.0, "scale": 1.0, "z_index": group_count + 1,
			"blocker_ids": [], "special_type": "key", "special_data": {},
			"key_group": "cargo_a", "lock_group": ""
		})
	var priority: Dictionary = {}
	if bool(parameters.get("priority_enabled", false)):
		priority = {"destination_id": group_destinations[0], "moves": 6}
	return {
		"schema_version": 1, "id": level_id, "world": parameters["world"],
		"seed": parameters["seed"], "content_version": 1,
		"tray_capacity": parameters["tray_capacity"], "layout_template": parameters["layout_template"],
		"difficulty": parameters["difficulty"], "items": items,
		"mechanics": {"mystery": int(parameters.get("mystery_count", 0)), "locks": int(parameters.get("lock_count", 0)), "priority": priority}
	}

func generate_daily(date_key: String, salt: String) -> Dictionary:
	var seed_value := int(hash(date_key + salt)) & 0x7fffffff
	var params := campaign_parameters(118)
	params["id"] = 10000
	params["seed"] = seed_value
	params["world"] = 4
	return generate_level(params)

func _layout_point(layout: String, group_index: int, item_index: int, group_count: int) -> Array[float]:
	var layer := float(group_index) / float(maxi(1, group_count - 1))
	var x_positions := [0.24, 0.5, 0.76]
	var x := float(x_positions[item_index])
	var y := 0.24 + fmod(float(group_index), 5.0) * 0.105
	match layout:
		"wings": x += (-0.05 if item_index == 0 else (0.05 if item_index == 2 else 0.0)) * sin(layer * PI)
		"diamond": x += (layer - 0.5) * (0.10 if item_index == 0 else -0.10 if item_index == 2 else 0.0)
		"double_stack": y = 0.25 + float(group_index % 4) * 0.12
		"spiral": x += sin(layer * TAU) * 0.08
		"terminals": x = [0.2, 0.5, 0.8][item_index]
		"bridge": y += 0.04 * absf(float(item_index - 1))
		"cross": x = 0.5 if group_index % 2 == 0 else x
		"split_islands": x += -0.07 if group_index % 2 == 0 else 0.07
		"staircase": x += (float(group_index % 3) - 1.0) * 0.04
		"ring": x += cos((float(group_index * 3 + item_index) / float(group_count * 3)) * TAU) * 0.08
		"compact_box": x = [0.3, 0.5, 0.7][item_index]
		"fan": x += (layer - 0.5) * (float(item_index) - 1.0) * 0.10
		"twin_towers": x = [0.3, 0.5, 0.7][item_index] if group_index % 2 == 0 else [0.23, 0.5, 0.77][item_index]
		"runway": y = 0.22 + layer * 0.45
		_: pass
	return [clampf(x, 0.12, 0.88), clampf(y, 0.18, 0.72)]

