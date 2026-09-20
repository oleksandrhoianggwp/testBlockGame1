extends Node

func pulse(duration_ms: int = 20, amplitude: float = 0.35) -> void:
	if SaveService.data.get("settings", {}).get("haptics", true) and OS.get_name() == "Android":
		Input.vibrate_handheld(duration_ms, amplitude)

