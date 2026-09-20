class_name SortingGameState
extends RefCounted

enum Phase { LOADING, INTRO, PLAYING, ANIMATING, RESOLVING, PAUSED, WON, LOST }

var level_id: int = 0
var seed_value: int = 0
var phase: Phase = Phase.LOADING
var items: Dictionary = {}
var tray: Array[String] = []
var tray_capacity: int = 7
var base_capacity: int = 7
var score: int = 0
var combo: int = 0
var peak_tray: int = 0
var boosters_used: int = 0
var extra_slot_active: bool = false
var unlocked_groups: Array[String] = []
var priority_destination: String = ""
var priority_moves: int = -1
var priority_completed: bool = false
var loss_reason: String = ""
var history: Array[Dictionary] = []

func load_level(definition: Dictionary) -> void:
	level_id = int(definition.get("id", 0))
	seed_value = int(definition.get("seed", 0))
	tray_capacity = int(definition.get("tray_capacity", 7))
	base_capacity = tray_capacity
	items.clear()
	for raw_item: Dictionary in definition.get("items", []):
		var item := raw_item.duplicate(true)
		item["removed"] = bool(item.get("removed", false))
		item["revealed"] = not bool(item.get("special_type", "") == "mystery")
		items[String(item["id"])] = item
	tray.clear()
	score = 0
	combo = 0
	peak_tray = 0
	boosters_used = 0
	extra_slot_active = false
	unlocked_groups.clear()
	var priority: Dictionary = definition.get("mechanics", {}).get("priority", {})
	priority_destination = String(priority.get("destination_id", ""))
	priority_moves = int(priority.get("moves", -1))
	priority_completed = priority_destination.is_empty()
	loss_reason = ""
	history.clear()
	phase = Phase.PLAYING
	_reveal_accessible_mysteries()

func is_selectable(item_id: String) -> bool:
	if phase != Phase.PLAYING or not items.has(item_id):
		return false
	var item: Dictionary = items[item_id]
	if bool(item.get("removed", false)):
		return false
	var lock_group := String(item.get("lock_group", ""))
	if not lock_group.is_empty() and lock_group not in unlocked_groups:
		return false
	for blocker_id: String in item.get("blocker_ids", []):
		if items.has(blocker_id) and not bool(items[blocker_id].get("removed", false)):
			return false
	return true

func accessible_item_ids() -> Array[String]:
	var result: Array[String] = []
	for item_id: String in items:
		if is_selectable(item_id):
			result.append(item_id)
	result.sort()
	return result

func select_item(item_id: String) -> Dictionary:
	if not is_selectable(item_id):
		return {"ok": false, "reason": "blocked"}
	history.append(to_snapshot())
	if history.size() > 10:
		history.pop_front()
	phase = Phase.RESOLVING
	var item: Dictionary = items[item_id]
	item["removed"] = true
	items[item_id] = item
	var event := {"ok": true, "item_id": item_id, "key": false, "matches": 0, "won": false, "lost": false}
	if String(item.get("special_type", "")) == "key":
		var group := String(item.get("key_group", ""))
		if not group.is_empty() and group not in unlocked_groups:
			unlocked_groups.append(group)
		event["key"] = true
	else:
		tray.append(String(item.get("destination_id", "")))
		peak_tray = maxi(peak_tray, tray.size())
		if priority_moves >= 0 and not priority_completed:
			priority_moves -= 1
		event["matches"] = _resolve_matches()
	_reveal_accessible_mysteries()
	_evaluate_end_state()
	event["won"] = phase == Phase.WON
	event["lost"] = phase == Phase.LOST
	event["loss_reason"] = loss_reason
	if phase == Phase.RESOLVING:
		phase = Phase.PLAYING
	return event

func _resolve_matches() -> int:
	var total := 0
	var changed := true
	while changed:
		changed = false
		var counts: Dictionary = {}
		for destination: String in tray:
			counts[destination] = int(counts.get(destination, 0)) + 1
		var destinations := counts.keys()
		destinations.sort()
		for destination: String in destinations:
			if int(counts[destination]) >= 3:
				for _i in range(3):
					tray.erase(destination)
				total += 1
				combo += 1
				score += 100 + maxi(0, combo - 1) * 20
				if destination == priority_destination:
					priority_completed = true
					score += maxi(0, priority_moves) * 10
				changed = true
				break
	if total == 0:
		combo = 0
	return total

func _evaluate_end_state() -> void:
	if not priority_completed and priority_moves <= 0:
		phase = Phase.LOST
		loss_reason = "priority"
		return
	var luggage_left := 0
	for item: Dictionary in items.values():
		if not bool(item.get("removed", false)) and String(item.get("special_type", "")) != "key":
			luggage_left += 1
	if luggage_left == 0 and tray.is_empty():
		phase = Phase.WON
		score += 250
		return
	if tray.size() >= tray_capacity:
		phase = Phase.LOST
		loss_reason = "tray"

func _reveal_accessible_mysteries() -> void:
	var previous_phase := phase
	phase = Phase.PLAYING
	for item_id: String in items:
		var item: Dictionary = items[item_id]
		if String(item.get("special_type", "")) == "mystery" and not bool(item.get("removed", false)) and is_selectable(item_id):
			item["revealed"] = true
			items[item_id] = item
	phase = previous_phase

func undo() -> bool:
	if history.is_empty() or phase not in [Phase.PLAYING, Phase.LOST]:
		return false
	var snapshot: Dictionary = history.pop_back()
	var remaining_history := history.duplicate(true)
	from_snapshot(snapshot)
	history = remaining_history
	boosters_used += 1
	return true

func activate_extra_slot() -> bool:
	if phase != Phase.PLAYING or extra_slot_active:
		return false
	extra_slot_active = true
	tray_capacity = base_capacity + 1
	boosters_used += 1
	return true

func shuffle_remaining() -> bool:
	if phase != Phase.PLAYING:
		return false
	var destinations: Array[String] = []
	var mapping: Dictionary = {}
	for item: Dictionary in items.values():
		if bool(item.get("removed", false)) or String(item.get("special_type", "")) == "key" or String(item.get("destination_id", "")) == priority_destination:
			continue
		var destination := String(item.get("destination_id", ""))
		if destination not in destinations:
			destinations.append(destination)
	if destinations.size() < 2:
		return false
	destinations.sort()
	for index in destinations.size():
		mapping[destinations[index]] = destinations[(index + 1) % destinations.size()]
	for item_id: String in items:
		var item: Dictionary = items[item_id]
		var destination := String(item.get("destination_id", ""))
		if not bool(item.get("removed", false)) and mapping.has(destination):
			item["destination_id"] = mapping[destination]
			items[item_id] = item
	boosters_used += 1
	return true

func to_snapshot() -> Dictionary:
	return {
		"level_id": level_id, "seed_value": seed_value, "phase": int(phase),
		"items": items.duplicate(true), "tray": tray.duplicate(),
		"tray_capacity": tray_capacity, "base_capacity": base_capacity,
		"score": score, "combo": combo, "peak_tray": peak_tray,
		"boosters_used": boosters_used, "extra_slot_active": extra_slot_active,
		"unlocked_groups": unlocked_groups.duplicate(),
		"priority_destination": priority_destination, "priority_moves": priority_moves,
		"priority_completed": priority_completed, "loss_reason": loss_reason
	}

func from_snapshot(snapshot: Dictionary) -> void:
	level_id = int(snapshot.get("level_id", 0))
	seed_value = int(snapshot.get("seed_value", 0))
	phase = int(snapshot.get("phase", Phase.PLAYING)) as Phase
	items = snapshot.get("items", {}).duplicate(true)
	tray.clear()
	for destination: String in snapshot.get("tray", []):
		tray.append(destination)
	tray_capacity = int(snapshot.get("tray_capacity", 7))
	base_capacity = int(snapshot.get("base_capacity", 7))
	score = int(snapshot.get("score", 0))
	combo = int(snapshot.get("combo", 0))
	peak_tray = int(snapshot.get("peak_tray", 0))
	boosters_used = int(snapshot.get("boosters_used", 0))
	extra_slot_active = bool(snapshot.get("extra_slot_active", false))
	unlocked_groups.clear()
	for group: String in snapshot.get("unlocked_groups", []):
		unlocked_groups.append(group)
	priority_destination = String(snapshot.get("priority_destination", ""))
	priority_moves = int(snapshot.get("priority_moves", -1))
	priority_completed = bool(snapshot.get("priority_completed", false))
	loss_reason = String(snapshot.get("loss_reason", ""))

