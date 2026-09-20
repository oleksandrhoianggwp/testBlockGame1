class_name LocalAnalytics
extends RefCounted

const LOG_PATH := "user://qa_events.jsonl"

static func log_event(event_name: String, payload: Dictionary = {}) -> void:
	if not OS.is_debug_build():
		return
	var row := {"event": event_name, "unix_time": Time.get_unix_time_from_system(), "payload": payload}
	var file := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	else:
		file.seek_end()
	if file != null:
		file.store_line(JSON.stringify(row))

