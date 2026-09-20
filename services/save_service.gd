extends Node

const SAVE_VERSION := 1
const SAVE_PATH := "user://lost_sorted_save.json"
const BACKUP_PATH := "user://lost_sorted_save.backup.json"
const TEMP_PATH := "user://lost_sorted_save.tmp"

var data: Dictionary = {}

func _ready() -> void:
	load_profile()

func defaults() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"current_level": 1,
		"coins": 200,
		"boosters": {"undo": 3, "shuffle": 3, "extra_slot": 2},
		"levels": {},
		"worlds": {},
		"airport_progress": {},
		"daily": {"last_rewarded_date": "", "last_played_date": "", "streak": 0, "best_scores": {}},
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
	if version <= SAVE_VERSION:
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

func complete_level(level_id: int, stars: int, score: int, coins_earned: int) -> void:
	var key := str(level_id)
	var previous: Dictionary = data["levels"].get(key, {})
	var first_clear := previous.is_empty()
	data["levels"][key] = {"stars": maxi(stars, int(previous.get("stars", 0))), "best_score": maxi(score, int(previous.get("best_score", 0))), "completed": true}
	data["current_level"] = maxi(int(data["current_level"]), mini(150, level_id + 1))
	data["coins"] = int(data["coins"]) + coins_earned + (20 if first_clear else 0)
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
		add_booster(["undo", "shuffle", "extra_slot"][(world + object_id.length()) % 3])
	else:
		save_profile()
	return true

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
			_merge_known(target[key], source[key])
		elif typeof(source[key]) == typeof(target[key]) or target[key] == null:
			target[key] = source[key]

