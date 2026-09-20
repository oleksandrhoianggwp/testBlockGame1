extends Node

signal rewarded(result: String)
signal interstitial_finished(result: String)

enum Mode { SUCCESS, CANCEL, LOAD_FAILURE, NO_FILL, INTERSTITIAL_FAILURE }

var mode: Mode = Mode.SUCCESS
var enabled: bool = OS.is_debug_build()

func is_rewarded_available() -> bool:
	return enabled and mode not in [Mode.LOAD_FAILURE, Mode.NO_FILL]

func show_rewarded() -> void:
	await get_tree().create_timer(0.15).timeout
	rewarded.emit("reward" if mode == Mode.SUCCESS else "cancel" if mode == Mode.CANCEL else "failed")

func show_interstitial() -> void:
	await get_tree().create_timer(0.15).timeout
	interstitial_finished.emit("shown" if mode == Mode.SUCCESS else "failed")

