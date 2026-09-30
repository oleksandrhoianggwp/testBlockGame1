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
	generate_svg_assets()
	generate_audio_assets()
	print("ASSETS PASS: 12 destination tags, 6 luggage silhouettes, 5 world backgrounds, 28 airport stages, UI/store icons, 17 WAV files")
	quit(0)

func generate_svg_assets() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/art/destinations"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/art/backgrounds"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/art/airport"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/art/luggage"))
	for destination in DESTINATIONS:
		var svg := """<svg xmlns="http://www.w3.org/2000/svg" width="256" height="176" viewBox="0 0 256 176">
<rect x="8" y="24" width="240" height="144" rx="30" fill="%s" stroke="#18223b" stroke-width="8"/>
<path d="M86 26V16c0-7 6-12 13-12h58c7 0 13 5 13 12v10" fill="none" stroke="#18223b" stroke-width="8"/>
<path d="M28 68h200M28 132h200" stroke="#ffffff" stroke-opacity=".38" stroke-width="6" stroke-dasharray="14 10"/>
<circle cx="72" cy="99" r="34" fill="#fffaf0"/><text x="72" y="113" text-anchor="middle" font-family="Arial,sans-serif" font-size="42" font-weight="700" fill="#18223b">%s</text>
<text x="174" y="109" text-anchor="middle" font-family="Arial,sans-serif" font-size="36" font-weight="800" fill="#18223b">%s</text>
</svg>""" % [destination[2], destination[3], destination[1]]
		_write_text("res://assets/art/destinations/%s.svg" % destination[0], svg)
	var world_colors := [["regional", "#dff3f4", "#72c7a5"], ["local", "#dff3f4", "#72c7a5"], ["international", "#e8f2f7", "#4d8fe8"], ["cargo", "#e9e1d5", "#b8894e"], ["midnight", "#101a38", "#f6bd60"], ["skyport", "#e5eff9", "#9b70d9"]]
	for index in world_colors.size():
		var world = world_colors[index]
		var svg := """<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1920" viewBox="0 0 1080 1920">
<defs><linearGradient id="sky" x2="0" y2="1"><stop stop-color="%s"/><stop offset="1" stop-color="#fff9ef"/></linearGradient></defs>
<rect width="1080" height="1920" fill="url(#sky)"/><circle cx="850" cy="240" r="130" fill="%s" opacity=".34"/>
<path d="M0 1180h1080v740H0z" fill="%s" opacity=".13"/><path d="M0 1370h1080" stroke="%s" stroke-width="18" opacity=".28"/>
<path d="M80 1040h920v300H80z" rx="54" fill="#fff9ef" opacity=".35"/><path d="M140 1100h180v140H140zm230 0h180v140H370zm230 0h180v140H600zm230 0h110v140H830z" fill="%s" opacity=".24"/>
<path d="M-80 1630L1160 1450" stroke="#fff9ef" stroke-width="90" opacity=".45"/><path d="M150 1585l150-22m120-20l150-22m120-20l150-22" stroke="%s" stroke-width="15" opacity=".55"/>
</svg>""" % [world[1], world[2], world[2], world[2], world[2], world[2]]
		_write_text("res://assets/art/backgrounds/%s.svg" % world[0], svg)
	var logo := """<svg xmlns="http://www.w3.org/2000/svg" width="800" height="300" viewBox="0 0 800 300">
<path d="M83 42h185a35 35 0 0135 35v154a35 35 0 01-35 35H83a35 35 0 01-35-35V77a35 35 0 0135-35z" fill="#ef6f6c" stroke="#18223b" stroke-width="14"/>
<circle cx="128" cy="152" r="42" fill="#fffaf0"/><path d="M106 152l17 18 34-42" fill="none" stroke="#18223b" stroke-width="12" stroke-linecap="round"/>
<path d="M216 119h54M216 153h54M216 187h54" stroke="#18223b" stroke-width="12" stroke-linecap="round"/>
<text x="348" y="134" font-family="Arial,sans-serif" font-weight="800" font-size="76" fill="#18223b">LOST &amp;</text><text x="348" y="218" font-family="Arial,sans-serif" font-weight="800" font-size="76" fill="#18223b">SORTED</text>
</svg>"""
	_write_text("res://assets/art/logo.svg", logo)
	var splash_image := Image.load_from_file("res://assets/art/logo.svg")
	if splash_image:
		splash_image.save_png("res://assets/art/splash.png")
	var icon := """<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512"><rect width="512" height="512" rx="112" fill="#18223b"/><path d="M112 115h288a48 48 0 0148 48v238a48 48 0 01-48 48H112a48 48 0 01-48-48V163a48 48 0 0148-48z" fill="#ef6f6c"/><circle cx="205" cy="282" r="78" fill="#fffaf0"/><path d="M165 282l31 32 62-78" fill="none" stroke="#18223b" stroke-width="23" stroke-linecap="round"/><path d="M175 116V89c0-18 14-32 32-32h98c18 0 32 14 32 32v27" fill="none" stroke="#f6bd60" stroke-width="22"/></svg>"""
	_write_text("res://assets/icons/app_icon.svg", icon)
	_write_text("res://assets/icons/adaptive_foreground.svg", icon)
	_write_text("res://assets/icons/monochrome.svg", icon.replace("#ef6f6c", "#ffffff").replace("#fffaf0", "#ffffff").replace("#f6bd60", "#ffffff"))
	_write_text("res://assets/icons/adaptive_background.svg", "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"512\" height=\"512\"><rect width=\"512\" height=\"512\" fill=\"#18223b\"/></svg>")
	for icon_name in ["undo", "shuffle", "extra_slot", "reveal", "coin", "star", "pause", "key", "lock"]:
		var initial: String = icon_name.substr(0, 1).to_upper()
		var simple := "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"128\" height=\"128\"><circle cx=\"64\" cy=\"64\" r=\"56\" fill=\"#f6bd60\" stroke=\"#18223b\" stroke-width=\"8\"/><text x=\"64\" y=\"82\" text-anchor=\"middle\" font-family=\"Arial\" font-weight=\"700\" font-size=\"52\" fill=\"#18223b\">%s</text></svg>" % initial
		_write_text("res://assets/icons/%s.svg" % icon_name, simple)
	var luggage_shapes := [
		["hard_shell", "M34 42h188a28 28 0 0128 28v118a28 28 0 01-28 28H34A28 28 0 016 188V70a28 28 0 0128-28z"],
		["cabin", "M52 30h152a24 24 0 0124 24v160H28V54a24 24 0 0124-24z"],
		["duffel", "M34 82h188l28 36-22 90H28L6 118z"],
		["backpack", "M56 38h144a34 34 0 0134 34v146H22V72a34 34 0 0134-34z"],
		["oversized", "M22 46h212a20 20 0 0120 20v150H2V66a20 20 0 0120-20z"],
		["travel_case", "M42 58h172l30 28v124H12V86z"]
	]
	for shape in luggage_shapes:
		var luggage_svg := """<svg xmlns="http://www.w3.org/2000/svg" width="256" height="240" viewBox="0 0 256 240"><path d="%s" fill="#ef6f6c" stroke="#18223b" stroke-width="8"/><path d="M91 44V24c0-9 7-16 16-16h42c9 0 16 7 16 16v20" fill="none" stroke="#18223b" stroke-width="8"/><path d="M70 66v126m116-126v126" stroke="#fff9ef" stroke-opacity=".35" stroke-width="7"/><rect x="142" y="88" width="74" height="52" rx="8" fill="#fff9ef" stroke="#18223b" stroke-width="6"/><circle cx="48" cy="220" r="8" fill="#18223b"/><circle cx="208" cy="220" r="8" fill="#18223b"/></svg>""" % shape[1]
		_write_text("res://assets/art/luggage/%s.svg" % shape[0], luggage_svg)
	var airport_objects := ["entrance", "checkin", "baggage", "security", "cafe", "tower", "runway"]
	for object_index in airport_objects.size():
		for stage in 4:
			var palette: String = String(["#9aa7ad", "#72c7a5", "#f6bd60", "#ef6f6c"][stage])
			var motif := ""
			match airport_objects[object_index]:
				"entrance": motif = "<path d=\"M52 132V82h46v50M64 105h22\" fill=\"none\" stroke=\"#fff9ef\" stroke-width=\"8\"/>"
				"checkin": motif = "<path d=\"M28 112h94M42 80h66v32H42z\" fill=\"none\" stroke=\"#fff9ef\" stroke-width=\"8\"/>"
				"baggage": motif = "<path d=\"M24 112h102M38 88h28v24H38zm48 0h28v24H86z\" fill=\"none\" stroke=\"#fff9ef\" stroke-width=\"7\"/>"
				"security": motif = "<path d=\"M75 68l34 14v24c0 22-15 35-34 42-19-7-34-20-34-42V82z\" fill=\"#fff9ef\" opacity=\".85\"/>"
				"cafe": motif = "<path d=\"M44 82h54v32a22 22 0 01-54 0zm54 8h16a14 14 0 010 28h-12\" fill=\"none\" stroke=\"#fff9ef\" stroke-width=\"8\"/>"
				"tower": motif = "<path d=\"M60 134l9-58h12l9 58M48 70h54l-8-22H56z\" fill=\"#fff9ef\" stroke=\"#18223b\" stroke-width=\"6\"/>"
				"runway": motif = "<path d=\"M28 128l38-74h18l38 74z\" fill=\"#45506b\"/><path d=\"M75 65v16m0 14v16\" stroke=\"#fff9ef\" stroke-width=\"5\"/>"
			var lights := ""
			for light_index in stage + 1:
				lights += "<circle cx=\"%d\" cy=\"142\" r=\"5\" fill=\"#fff9ef\"/>" % [48 + light_index * 18]
			var airport_svg := "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"150\" height=\"160\"><path d=\"M12 146V66l20-18h86l20 18v80z\" fill=\"%s\" stroke=\"#18223b\" stroke-width=\"7\"/>%s%s<path d=\"M24 150h102\" stroke=\"#18223b\" stroke-width=\"7\"/></svg>" % [palette, motif, lights]
			_write_text("res://assets/art/airport/%s_%d.svg" % [airport_objects[object_index], stage], airport_svg)
	var feature := """<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="500"><rect width="1024" height="500" fill="#dff3f4"/><path d="M0 420l210-150 170 90 190-210 220 190 234-170v330H0z" fill="#72c7a5"/><text x="70" y="145" font-family="Arial" font-size="82" font-weight="800" fill="#18223b">LOST &amp; SORTED</text><text x="76" y="220" font-family="Arial" font-size="34" fill="#18223b">Tap. Match. Clear the terminal.</text><path d="M720 80h220v280H720z" rx="40" fill="#ef6f6c" stroke="#18223b" stroke-width="12"/></svg>"""
	_write_text("res://store/feature_graphic.svg", feature)

func generate_audio_assets() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/audio"))
	var names := ["tap", "pickup", "insert", "match", "combo", "key", "unlock", "reveal", "warning", "priority", "coin", "button", "booster", "win", "lose", "renovation"]
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
		var sample := int(sin(TAU * frequency * float(index) / float(sample_rate)) * 32767.0 * volume * envelope)
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
