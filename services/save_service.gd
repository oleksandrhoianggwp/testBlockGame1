extends Node

const SAVE_VERSION := 2
const CAMPAIGN_CONTENT_VERSION := 2
const SAVE_PATH := "user://lost_sorted_save.json"
const BACKUP_PATH := "user://lost_sorted_save.backup.json"
const TEMP_PATH := "user://lost_sorted_save.tmp"

var data: Dictionary = {}

func _ready() -> void:
	load_profile()

func defaults() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"campaign_content_version": CAMPAIGN_CONTENT_VERSION,
		"current_level": 1,
		"campaign_seeds": {},
		"coins": 200,
		"boosters": {"undo": 3, "shuffle": 3, "extra_slot": 2},
		"levels": {},
		"worlds": {},
		"airport_progress": {},
		"airport_perks": {"undo_charge": 0, "mystery_reveal": 0, "priority_move": 0, "first_clear_bonus": 0},
		"daily": {"last_rewarded_date": "", "last_played_date": "", "streak": 0, "best_scores": {}},
		"shift": {"high_score": 0, "active_seed": 0, "round": 0, "score": 0, "last_event": ""},
		"endless": {"high_score": 0},
		"tutorials": {},
		"settings": {"master_sound": true, "music": true, "sfx": true, "haptics": true, "reduced_motion": false, "text_scale": 1.0, "language": ""},
		"consent": {"ads_enabled": false, "privacy_options_required": false}
	}

func load_profile() -> void:
	var loaded := _read_json(SAVE_PATH)
	if loaded.is_empty():
		loaded = _read_json(BACKUP_PATH)
	data = defaults()
	if not loaded.is_empty():
		_merge_known(data, migrate(loaded))
	else:
		save_profile()

func migrate(source: Dictionary) -> Dictionary:
	var migrated := source.duplicate(true)
	var version := int(migrated.get("save_version", 1))
	if version < 2:
		var old_levels: Dictionary = migrated.get("levels", {})
		var new_levels: Dictionary = {}
		for old_key: String in old_levels:
			var old_id := int(old_key)
			var new_id := clampi(int(ceil(float(old_id) / 2.0)), 1, 75)
			var old_record: Dictionary = old_levels[old_key]
			var current: Dictionary = new_levels.get(str(new_id), {})
			new_levels[str(new_id)] = {
				"completed": bool(old_record.get("completed", false)) or bool(current.get("completed", false)),
				"stars": maxi(int(old_record.get("stars", 0)), int(current.get("stars", 0))),
				"best_score": maxi(int(old_record.get("best_score", 0)), int(current.get("best_score", 0)))
			}
		migrated["levels"] = new_levels
		migrated["current_level"] = clampi(int(ceil(float(int(migrated.get("current_level", 1))) / 2.0)), 1, 75)
		migrated["campaign_seeds"] = {}
		migrated["campaign_content_version"] = CAMPAIGN_CONTENT_VERSION
		var old_airport: Dictionary = migrated.get("airport_progress", {})
		for world_key: String in old_airport:
			var progress: Dictionary = old_airport[world_key]
			if progress.has("seating") and not progress.has("baggage"):
				progress["baggage"] = progress["seating"]
			if progress.has("departures") and not progress.has("tower"):
				progress["tower"] = progress["departures"]
		migrated["airport_progress"] = old_airport
		var old_endless: Dictionary = migrated.get("endless", {})
		migrated["shift"] = {"high_score": int(old_endless.get("high_score", 0)), "active_seed": 0, "round": 0, "score": 0, "last_event": ""}
	version = 2
	if int(migrated.get("campaign_content_version", 0)) != CAMPAIGN_CONTENT_VERSION:
		migrated["campaign_seeds"] = {}
		migrated["campaign_content_version"] = CAMPAIGN_CONTENT_VERSION
	migrated["save_version"] = SAVE_VERSION
	return migrated

func save_profile() -> bool:
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Unable to open temporary save file: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file.close()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(BACKUP_PATH)
		var backup_error := DirAccess.rename_absolute(SAVE_PATH, BACKUP_PATH)
		if backup_error != OK:
			push_warning("Could not rotate save backup: %s" % error_string(backup_error))
	var error := DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH)
	if error != OK:
		push_error("Could not commit save: %s" % error_string(error))
		return false
	return true

func campaign_seed(level_id: int, entropy: int = -1, persist: bool = true) -> int:
	var key := str(level_id)
	if data["campaign_seeds"].has(key):
		return int(data["campaign_seeds"][key])
	var seed_value := entropy
	if seed_value < 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(Time.get_ticks_usec()) ^ int(Time.get_unix_time_from_system()) ^ (level_id * 104729)
		seed_value = int(rng.randi() & 0x7fffffff)
	data["campaign_seeds"][key] = maxi(1, seed_value)
	if persist:
		save_profile()
	return int(data["campaign_seeds"][key])

func complete_level(level_id: int, stars: int, score: int, coins_earned: int, campaign_count: int = 75, persist: bool = true) -> void:
	var key := str(level_id)
	var previous: Dictionary = data["levels"].get(key, {})
	var first_clear := not bool(previous.get("completed", false))
	data["levels"][key] = {
		"stars": maxi(stars, int(previous.get("stars", 0))),
		"best_score": maxi(score, int(previous.get("best_score", 0))),
		"completed": true
	}
	data["current_level"] = maxi(int(data["current_level"]), mini(campaign_count, level_id + 1))
	data["campaign_seeds"].erase(key)
	var first_clear_bonus := int(data.get("airport_perks", {}).get("first_clear_bonus", 0)) if first_clear else 0
	data["coins"] = int(data["coins"]) + coins_earned + (20 if first_clear else 0) + first_clear_bonus
	if persist:
		save_profile()

func spend_booster(booster: String) -> bool:
	var count := int(data["boosters"].get(booster, 0))
	if count <= 0:
		return false
	data["boosters"][booster] = count - 1
	save_profile()
	return true

func add_booster(booster: String, amount: int = 1) -> void:
	data["boosters"][booster] = int(data["boosters"].get(booster, 0)) + amount
	save_profile()

func purchase_airport_upgrade(world: int, object_id: String, costs: Array) -> bool:
	var world_key := str(world)
	if not data["airport_progress"].has(world_key):
		data["airport_progress"][world_key] = {}
	var stage := int(data["airport_progress"][world_key].get(object_id, 0))
	if stage >= 3:
		return false
	var cost := int(costs[stage]) * world
	if int(data["coins"]) < cost:
		return false
	data["coins"] = int(data["coins"]) - cost
	data["airport_progress"][world_key][object_id] = stage + 1
	if stage + 1 == 3:
		_apply_milestone_perk(object_id)
	save_profile()
	return true

func _apply_milestone_perk(object_id: String) -> void:
	match object_id:
		"baggage": data["airport_perks"]["undo_charge"] = mini(1, int(data["airport_perks"].get("undo_charge", 0)) + 1)
		"security": data["airport_perks"]["mystery_reveal"] = mini(1, int(data["airport_perks"].get("mystery_reveal", 0)) + 1)
		"tower": data["airport_perks"]["priority_move"] = mini(2, int(data["airport_perks"].get("priority_move", 0)) + 1)
		"cafe": data["airport_perks"]["first_clear_bonus"] = mini(15, int(data["airport_perks"].get("first_clear_bonus", 0)) + 5)

func begin_shift(seed_override: int = -1) -> int:
	var seed_value := seed_override
	if seed_value < 0:
		seed_value = int(Time.get_ticks_usec() ^ int(Time.get_unix_time_from_system())) & 0x7fffffff
	data["shift"]["active_seed"] = maxi(1, seed_value)
	data["shift"]["round"] = 1
	data["shift"]["score"] = 0
	data["shift"]["last_event"] = ""
	save_profile()
	return int(data["shift"]["active_seed"])

func advance_shift(round_score: int, event_id: String) -> void:
	data["shift"]["score"] = int(data["shift"].get("score", 0)) + round_score
	data["shift"]["round"] = int(data["shift"].get("round", 1)) + 1
	data["shift"]["last_event"] = event_id
	data["shift"]["high_score"] = maxi(int(data["shift"].get("high_score", 0)), int(data["shift"]["score"]))
	save_profile()

func end_shift() -> void:
	data["shift"]["high_score"] = maxi(int(data["shift"].get("high_score", 0)), int(data["shift"].get("score", 0)))
	data["shift"]["active_seed"] = 0
	data["shift"]["round"] = 0
	data["shift"]["score"] = 0
	save_profile()

func reset_profile() -> void:
	data = defaults()
	save_profile()

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Ignoring malformed save at %s" % path)
		return {}
	return parsed

func _merge_known(target: Dictionary, source: Dictionary) -> void:
	for key: Variant in target.keys():
		if not source.has(key):
			continue
		if typeof(target[key]) == TYPE_DICTIONARY and typeof(source[key]) == TYPE_DICTIONARY:
			if (target[key] as Dictionary).is_empty():
				target[key] = (source[key] as Dictionary).duplicate(true)
			else:
				_merge_known(target[key], source[key])
		elif typeof(source[key]) == typeof(target[key]) or target[key] == null:
			target[key] = source[key]
