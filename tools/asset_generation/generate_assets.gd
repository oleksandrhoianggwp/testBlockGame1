extends SceneTree

const DESTINATIONS := [
	["par", "PAR", "#e95d72", "◆"], ["tyo", "TYO", "#ef8d43", "●"],
	["iev", "IEV", "#f3c34f", "✦"], ["rom", "ROM", "#57b87a", "∩"],
	["cai", "CAI", "#2bb7a8", "▲"], ["sel", "SEL", "#3fa6d8", "門"],
	["syd", "SYD", "#5d7be7", "◒"], ["rio", "RIO", "#9b70d9", "☀"],
	["osl", "OSL", "#4d8cbf", "❄"], ["yto", "YTO", "#d968a7", "⌃"],
	["lim", "LIM", "#b8894e", "▰"], ["nbo", "NBO", "#718f47", "♣"]
]

func _initialize() -> void:
	preload("res://tools/asset_generation/polish_assets.gd").new().generate()
	generate_audio_assets()
	print("ASSETS PASS: suitcase branding, 6 luggage silhouettes, 5 illustrated worlds, 28 airport stages, pictogram icons, 20 WAV files")
	quit(0)

func generate_audio_assets() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/audio"))
	var names := ["tap", "pickup", "insert", "match", "combo", "key", "unlock", "reveal", "warning", "priority", "coin", "button", "booster", "win", "lose", "renovation", "star", "world_unlock", "cash_out"]
	for index in names.size():
		_write_tone("res://assets/audio/%s.wav" % names[index], 280.0 + index * 34.0, 0.09 + float(index % 3) * 0.025, 0.18)
	_write_tone("res://assets/audio/ambient.wav", 164.0, 2.0, 0.055)

func _write_tone(path: String, frequency: float, seconds: float, volume: float) -> void:
	var sample_rate := 22050
	var sample_count := int(seconds * sample_rate)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for index in sample_count:
		var envelope := minf(1.0, float(index) / 80.0) * (1.0 - float(index) / float(sample_count))
		var t := float(index) / sample_rate
		var sample := int((sin(TAU * frequency * t) * 0.65 + sin(TAU * frequency * 1.5 * t) * 0.2 + sin(TAU * frequency * 2.0 * t) * 0.15) * 32767.0 * volume * envelope * envelope)
		pcm.encode_s16(index * 2, sample)
	var wav := PackedByteArray()
	wav.resize(44 + pcm.size())
	for pair in [[0, "RIFF"], [8, "WAVE"], [12, "fmt "], [36, "data"]]:
		var bytes := String(pair[1]).to_ascii_buffer()
		for byte_index in 4:
			wav[int(pair[0]) + byte_index] = bytes[byte_index]
	wav.encode_u32(4, 36 + pcm.size())
	wav.encode_u32(16, 16)
	wav.encode_u16(20, 1)
	wav.encode_u16(22, 1)
	wav.encode_u32(24, sample_rate)
	wav.encode_u32(28, sample_rate * 2)
	wav.encode_u16(32, 2)
	wav.encode_u16(34, 16)
	wav.encode_u32(40, pcm.size())
	for index in pcm.size():
		wav[44 + index] = pcm[index]
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(wav)

func _write_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
