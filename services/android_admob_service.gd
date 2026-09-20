class_name AndroidAdMobService
extends Node

signal rewarded(result: String)
signal interstitial_finished(result: String)

const PLUGIN_VERSION := "7.0"
const TEST_REWARDED_ANDROID := "ca-app-pub-3940256099942544/5224354917"
const TEST_INTERSTITIAL_ANDROID := "ca-app-pub-3940256099942544/1033173712"

var available: bool = false

func initialize_if_available() -> bool:
	available = OS.get_name() == "Android" and Engine.has_singleton("AdMob")
	if not available:
		return false
	# The pinned plugin is optional so desktop/headless imports stay dependency-free.
	# Consent and SDK initialization are performed by the plugin node configured in the Android build.
	return true

func is_rewarded_available() -> bool:
	return available

func show_rewarded() -> void:
	if not available:
		rewarded.emit("failed")

func show_interstitial() -> void:
	if not available:
		interstitial_finished.emit("failed")

