extends Node

var players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for index in 4:
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % index
		add_child(player)
		players.append(player)
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.volume_db = -24.0
	add_child(music_player)
	if ResourceLoader.exists("res://assets/audio/ambient.wav"):
		music_player.stream = load("res://assets/audio/ambient.wav")
		music_player.finished.connect(func() -> void:
			if SaveService.data.get("settings", {}).get("music", true):
				music_player.play())
	apply_settings()

func play_sfx(name: String) -> void:
	if not SaveService.data.get("settings", {}).get("master_sound", true) or not SaveService.data.get("settings", {}).get("sfx", true):
		return
	var path := "res://assets/audio/%s.wav" % name
	if not ResourceLoader.exists(path):
		return
	for player in players:
		if not player.playing:
			player.stream = load(path)
			player.play()
			return

func apply_settings() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), not bool(SaveService.data["settings"].get("master_sound", true)))
	if music_player:
		if bool(SaveService.data["settings"].get("music", true)) and not music_player.playing:
			music_player.play()
		elif not bool(SaveService.data["settings"].get("music", true)):
			music_player.stop()
