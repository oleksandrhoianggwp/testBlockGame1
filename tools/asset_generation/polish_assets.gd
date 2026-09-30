extends RefCounted

const ZONES := ["entrance", "checkin", "baggage", "security", "cafe", "tower", "runway"]
const SHAPES := ["hard_shell", "cabin", "duffel", "backpack", "oversized", "travel_case"]
const PATHS := [
	"M30 28Q18 28 18 42V112Q18 126 32 126H120Q134 126 134 112V42Q134 28 120 28Z",
	"M46 14H108Q120 14 120 28V126H32V28Q32 14 46 14Z",
	"M34 50Q12 50 8 76L16 120Q18 130 36 130H116Q134 130 136 118L144 76Q138 50 118 50Z",
	"M72 14Q36 14 30 50L26 122Q26 134 40 134H112Q126 134 126 122L122 50Q116 14 80 14Z",
	"M18 24H130Q144 24 144 40V122Q144 134 130 134H18Q6 134 6 122V40Q6 24 18 24Z",
	"M94 12Q110 12 110 26L106 54Q134 64 136 88V116Q136 130 118 134H32Q18 130 18 116V92Q18 64 58 56L68 22Q70 12 84 12Z"
]

func generate() -> void:
	for folder in ["assets/art/airport", "assets/art/luggage", "assets/art/worlds", "assets/icons", "assets/audio", "store"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + folder))
	for i in SHAPES.size():
		var straps := "<path d='M48 54v65M110 54v65' stroke='#8f9bab' stroke-width='5'/>" if i == 2 else "<path d='M40 48v55M52 48v55M116 48v55' stroke='#c7d0dc' stroke-width='3'/>"
		if i == 3:
			straps = "<rect x='44' y='76' width='68' height='46' rx='12' fill='#b5c1d1'/><path d='M46 84h64M36 49l-14 12m96-12l14 12' stroke='#17223d' stroke-width='3'/>"
		var body := "<ellipse cx='78' cy='137' rx='66' ry='7' fill='#17223d' opacity='.14'/><path d='%s' fill='#f7fafc' stroke='#17223d' stroke-width='3'/><path d='%s' fill='none' stroke='#ffffff' stroke-width='1' transform='translate(-2,-2)' opacity='.7'/>%s<path d='M62 25V12q0-8 8-8h14q8 0 8 8v13' fill='none' stroke='#17223d' stroke-width='4'/><rect x='28' y='127' width='10' height='10' rx='3' fill='#17223d'/><rect x='115' y='127' width='10' height='10' rx='3' fill='#17223d'/>" % [PATHS[i], PATHS[i], straps]
		_write("res://assets/art/luggage/%s.svg" % SHAPES[i], _svg(152, 148, body))
	for zone in ZONES:
		for stage in 4:
			_write("res://assets/art/airport/%s_%d.svg" % [zone, stage], _zone(zone, stage))
	_icons()
	_brand()
	for i in 5:
		_write("res://assets/art/worlds/world_%d.svg" % (i+1), _world(i))
		_write("res://assets/art/backgrounds/%s.svg" % ["regional","international","cargo","midnight","skyport"][i], _background(i))
	_feature()

func _svg(w: int, h: int, body: String) -> String:
	return "<svg xmlns='http://www.w3.org/2000/svg' width='%d' height='%d' viewBox='0 0 %d %d'>%s</svg>" % [w,h,w,h,body]

func _zone(zone: String, stage: int) -> String:
	var roof: String = ["#c8bdab", "#75cdb2", "#5b91e8", "#f7c75a"][stage]
	var w := 130 + stage * 20
	var h := 48 + stage * 6
	var x := 128 - w/2
	var body := "<ellipse cx='130' cy='174' rx='112' ry='14' fill='#17223d' opacity='.14'/>"
	if zone == "tower":
		var top := 100 - stage * 16
		body += "<path d='M104 166V%dL146 %dV150Z' fill='#e3d9c4'/><path d='M146 %dL166 %dV162L146 176Z' fill='#91a6ad'/><path d='M82 %dL132 %dL184 %dL134 %dZ' fill='%s'/><path d='M82 %dv30l52 24v-30z' fill='#62a9c1'/><path d='M134 %dv30l50-24v-30z' fill='#35657e'/><path d='M132 %dv-24' stroke='#17223d' stroke-width='3'/><circle cx='132' cy='%d' r='4' fill='#f06f6c'/>" % [top+34,top+10,top+10,top+30,top,top-24,top,top+24,roof,top,top+24,top-24,top-48]
	elif zone == "runway":
		body += "<path d='M18 130L192 46L240 74L66 166Z' fill='#46566a'/><path d='M36 133L208 51M65 155L236 75' stroke='#fff8eb' stroke-width='2'/><path d='M56 131l18-9m16-8l18-9m16-8l18-9m16-8l18-9' stroke='#fff8eb' stroke-width='4'/>"
		for j in 3 + stage * 3:
			body += "<circle cx='%d' cy='%d' r='3' fill='#f7c75a'/>" % [28+j*15,132-j*7]
		if stage >= 2:
			body += "<path d='M56 169L220 90' stroke='#c8bdab' stroke-width='10'/><path d='M85 164l15-8m20-10l15-8' stroke='#fff8eb' stroke-width='2'/>"
	else:
		body += "<path d='M%d 96L%d 58L%d 96L128 134Z' fill='%s'/><path d='M%d 96V%dL128 %dV134Z' fill='#fff8eb'/><path d='M128 134V%dL%d %dV96Z' fill='#9baeb7'/>" % [x,128,x+w,roof,x,96+h,134+h,134+h,x+w,96+h]
		for j in 2 + stage:
			body += "<path d='M%d %dv24l12 6v-24z' fill='#4c91af'/>" % [x+12+j*20,105+j*8]
		body += "<path d='M%d 101L128 137L%d 101' fill='none' stroke='#ffffff' stroke-width='3' opacity='.6'/>" % [x,x+w]
		match zone:
			"entrance": body += "<path d='M85 141v26l28 13v-26z' fill='#3b7089'/><path d='M76 129l44 20 20-10-44-20z' fill='#f7c75a'/><circle cx='58' cy='158' r='9' fill='#75cdb2'/><circle cx='151' cy='178' r='10' fill='#75cdb2'/>"
			"checkin": body += "<path d='M64 128l60 28 16-8-60-28z' fill='#f7c75a'/><path d='M64 128v18l60 28v-18z' fill='#f06f6c'/><path d='M83 121v-12l16 8v12' stroke='#17223d' stroke-width='3' fill='none'/>"
			"baggage": body += "<path d='M44 138l86 38 54-26-86-38z' fill='#17223d' stroke='#61758a' stroke-width='7'/><path d='M67 137l22 10 14-7-22-10z' fill='#f06f6c'/><path d='M122 157l19 9 14-7-19-9z' fill='#f7c75a'/>"
			"security": body += "<path d='M84 142v-30l34 16v30m-34-46l12-6 34 16v30' fill='none' stroke='#17223d' stroke-width='8'/><circle cx='93' cy='114' r='3' fill='#75cdb2'/>"
			"cafe": body += "<path d='M48 117l68 31 18-12-68-31z' fill='#f06f6c'/><path d='M58 111l8 20m16-9l8 20m16-8l8 20' stroke='#fff8eb' stroke-width='7'/><ellipse cx='159' cy='169' rx='18' ry='8' fill='#f7c75a'/><path d='M159 169v18' stroke='#17223d' stroke-width='3'/>"
		if stage >= 2:
			body += "<path d='M118 82l32-15 28 13-32 15z' fill='#68b1ce'/><path d='M123 81l28 12m-15-18l28 12' stroke='#ddeff4' stroke-width='2'/>"
		body += "<path d='M128 134V%d' stroke='#6f8a9c' stroke-width='2'/><path d='M%d %dL128 %dL%d %d' fill='none' stroke='#6f8a9c' stroke-width='3' opacity='.6'/>" % [134+h,x,96+h,134+h,x+w,96+h]
		if zone == "baggage" and stage >= 1:
			body += "<path d='M173 151v12l18-9v-12z' fill='#f7c75a'/><circle cx='181' cy='151' r='3' fill='#17223d'/>"
		if zone == "baggage" and stage >= 2:
			body += "<path d='M103 151v-26l27 12v27m-27-39l12-6 27 12v27' fill='none' stroke='#5b91e8' stroke-width='7'/><circle cx='122' cy='129' r='3' fill='#75cdb2'/>"
		if zone == "baggage" and stage == 3:
			body += "<path d='M62 148l65 29 37-18' fill='none' stroke='#75cdb2' stroke-width='5'/><path d='M166 120v-16l18 8v16' fill='none' stroke='#17223d' stroke-width='4'/>"
		if stage == 0:
			body += "<path d='M83 78l12 6-5 8 15 6' fill='none' stroke='#a99985' stroke-width='2'/><rect x='169' y='139' width='12' height='17' fill='#f7c75a'/>"
		else:
			body += "<path d='M%d 100L128 136' stroke='#f7c75a' stroke-width='4'/><path d='M145 119l13-6m7-3l13-6' stroke='#b2d9e8' stroke-width='3'/><ellipse cx='46' cy='173' rx='9' ry='4' fill='#c8bdab'/><path d='M46 173v-13' stroke='#17223d' stroke-width='3'/><circle cx='46' cy='157' r='9' fill='#75cdb2'/>" % x
		if stage == 3:
			body += "<circle cx='45' cy='169' r='5' fill='#f7c75a'/><circle cx='188' cy='139' r='5' fill='#f7c75a'/><path d='M182 137v-22' stroke='#17223d' stroke-width='3'/>"
	return _svg(256,210,body)

func _icons() -> void:
	var symbols := {
		"undo":"<path d='M42 35H17l14-14M18 35q36-25 47 9t-33 23'/>",
		"shuffle":"<path d='M14 22h11l33 35h14m-12-12l12 12-12 12M14 58h11l33-35h14m-12-12l12 12-12 12'/>",
		"extra_slot":"<rect x='12' y='28' width='54' height='40' rx='7'/><path d='M33 15h33v31M58 11v22m-11-11h22'/>",
		"reveal":"<path d='M16 12h38l16 16v40H16Z'/><path d='M24 43q18-23 36 0-18 23-36 0'/><circle cx='42' cy='43' r='6'/>",
		"coin":"<circle cx='40' cy='40' r='28'/><path d='M40 22v36m-9-28h18m-18 20h18'/>",
		"star":"<path d='M40 10l9 20 23 3-17 16 5 23-20-12-20 12 5-23L8 33l23-3Z'/>",
		"pause":"<path d='M28 18v44M52 18v44'/>",
		"key":"<circle cx='28' cy='30' r='14'/><path d='M39 40l27 27m-9-9l9-9m-18 0l8-8'/>",
		"lock":"<rect x='20' y='33' width='40' height='34' rx='6'/><path d='M28 32V22q12-20 24 0v10m-12 16v8'/>",
		"settings":"<circle cx='40' cy='40' r='12'/><path d='M40 8v9m0 46v9M8 40h9m46 0h9M17 17l7 7m32 32l7 7m-46 0l7-7m32-32l7-7'/>",
		"campaign":"<path d='M14 62q40 4 30-22T66 14'/><circle cx='14' cy='62' r='5'/><circle cx='66' cy='14' r='5'/>",
		"airport":"<path d='M10 60h60M16 60V34l24-14 24 14v26M29 60V44h22v16M40 8v12'/>",
		"shift":"<path d='M18 25h42l-12-12m12 42H18l12 12'/><path d='M64 25q13 18 0 30M16 55Q3 38 16 25'/>",
		"plane":"<path d='M40 8l7 25 25 14v7l-26-5-2 18-4-5-4 5-2-18-26 5v-7l25-14Z'/>"
	}
	for key: String in symbols:
		_write("res://assets/icons/%s.svg" % key, _svg(80,80,"<g fill='none' stroke='#17223d' stroke-width='5' stroke-linecap='round' stroke-linejoin='round'>%s</g>" % symbols[key]))

func _brand() -> void:
	var bag := "<path d='M184 153v-30q0-29 29-29h85q29 0 29 29v30' fill='none' stroke='#fff8eb' stroke-width='18'/><rect x='118' y='151' width='280' height='272' rx='52' fill='#f06f6c'/><path d='M348 155q50 0 50 50v169q0 49-50 49z' fill='#cd555d'/><path d='M145 192v166m27-166v166' stroke='#ffa09a' stroke-width='9'/><circle cx='165' cy='430' r='16' fill='#17223d'/><circle cx='350' cy='430' r='16' fill='#17223d'/><path d='M292 191l81 35-34 139-95-35z' fill='#fff8eb' stroke='#17223d' stroke-width='5'/><circle cx='310' cy='222' r='10' fill='#f7c75a'/><path d='M309 242l2 31 28 23-4 10-31-12-11 27-7-3 3-30-29-8 1-10 31-2 12-28z' fill='#17223d'/>"
	_write("res://assets/icons/app_icon.svg", _svg(512,512,"<rect width='512' height='512' rx='112' fill='#17223d'/><path d='M40 448h432' stroke='#75cdb2' stroke-width='18' stroke-dasharray='24 12'/>"+bag))
	_write("res://assets/icons/adaptive_foreground.svg", _svg(512,512,"<g transform='translate(68,68) scale(.74)'>"+bag+"</g>"))
	_write("res://assets/icons/adaptive_background.svg", _svg(512,512,"<rect width='512' height='512' fill='#17223d'/>"))
	_write("res://assets/icons/monochrome.svg", _svg(512,512,"<g fill='#fff'><path d='M184 154v-35q0-30 30-30h84q30 0 30 30v35h-20v-35q0-10-10-10h-84q-10 0-10 10v35z'/><rect x='118' y='151' width='280' height='272' rx='52'/><circle cx='165' cy='435' r='15'/><circle cx='350' cy='435' r='15'/></g>"))
	var logo := _svg(800,240,"<g transform='translate(-5,-34) scale(.48)'>"+bag+"</g><text x='212' y='100' font-family='sans-serif' font-weight='900' font-size='68' fill='#17223d'>LOST &amp;</text><text x='212' y='180' font-family='sans-serif' font-weight='900' font-size='78' fill='#17223d'>SORTED</text><path d='M217 202h414' stroke='#f7c75a' stroke-width='9'/>")
	_write("res://assets/art/logo.svg", logo)
	var splash := Image.load_from_file("res://assets/art/logo.svg")
	if splash: splash.save_png("res://assets/art/splash.png")

func _world(i: int) -> String:
	var colors := ["#cde7d6","#ddeff4","#e6d7b9","#17223d","#dbe4f3"]
	var body := "<rect width='432' height='1420' fill='%s'/><path d='M-20 180Q180 70 460 260v150q-280-150-480-50z' fill='#fff8eb' opacity='.2'/><path d='M20 1380Q360 1250 200 1050T210 650T210 220' fill='none' stroke='#fff8eb' stroke-width='42' opacity='.8'/><path d='M20 1380Q360 1250 200 1050T210 650T210 220' fill='none' stroke='#acbeba' stroke-width='2' stroke-dasharray='5 12'/>" % colors[i]
	for j in 8:
		var x := 8 if j % 2 == 0 else 280
		var y := 110 + j * 153
		var zone: String = ZONES[(j+i)%ZONES.size()]
		var raw := _zone(zone, mini(3,i))
		var inner := raw.substr(raw.find(">")+1).replace("</svg>","")
		body += "<g transform='translate(%d,%d) scale(.6)'>%s</g>" % [x,y,inner]
		if i == 3:
			body += "<circle cx='%d' cy='%d' r='4' fill='#f7c75a'/><circle cx='%d' cy='%d' r='3' fill='#75cdb2'/>" % [x+36,y+120,x+98,y+84]
		if i == 0:
			body += "<circle cx='%d' cy='%d' r='15' fill='#75cdb2'/><circle cx='%d' cy='%d' r='10' fill='#91d4b5'/>" % [x+52,y+136,x+45,y+129]
		elif i == 1:
			body += "<g transform='translate(%d,%d) scale(.6)'><path d='M90 0l7 36 56 18v10l-55-9-2 28 17 13v8l-24-10-23 10v-8l17-13-2-28-55 9V54l55-18Z' fill='#fff8eb' stroke='#6f8a9c' stroke-width='2'/><path d='M88 75v20' stroke='#f06f6c' stroke-width='6'/></g>" % [x,y+95]
		elif i == 2:
			body += "<g transform='translate(%d,%d)'><path d='M0 0l35-16 30 14-35 16z' fill='#f7c75a'/><path d='M0 0v23l30 14V14z' fill='#f06f6c'/><path d='M30 14v23l35-16V-2z' fill='#b7796c'/><path d='M6 8v17m8-14v17m8-14v17' stroke='#fff8eb' stroke-width='2'/><path d='M75 20h17v20H75zM82 20V2h5v30h12' fill='#f7c75a' stroke='#17223d' stroke-width='2'/><circle cx='78' cy='41' r='5' fill='#17223d'/><circle cx='94' cy='41' r='5' fill='#17223d'/></g>" % [x+20,y+116]
		elif i == 3:
			body += "<path d='M%d %dl-8 22m26-11l-8 22' stroke='#5b91e8' stroke-width='2' opacity='.25'/>" % [x+100,y+20]
		elif i == 4:
			body += "<path d='M%d %dl40-18 32 16-40 18z' fill='#5b91e8' stroke='#fff8eb' stroke-width='2'/><path d='M%d %dl37 17' stroke='#75cdb2' stroke-width='3'/>" % [x+35,y+120,x+47,y+115]
	return _svg(432,1420,body)

func _background(i: int) -> String:
	var color: String = ["#ddeff4","#e2eff8","#efe4ce","#202d47","#e4eafa"][i]
	return _svg(432,768,"<rect width='432' height='768' fill='%s'/><path d='M0 140h432M0 460h432' stroke='#ffffff' opacity='.35' stroke-width='3'/><path d='M20 150v300m98-300v300m98-300v300m98-300v300m98-300v300' stroke='#6a97b0' opacity='.09' stroke-width='2'/><path d='M0 530l432-55v70L0 600z' fill='#fff8eb' opacity='.25'/><path d='M0 662l432-65' stroke='#f7c75a' stroke-width='3' opacity='.5'/>" % color)

func _feature() -> void:
	var body := "<rect width='1024' height='500' fill='#ddeff4'/><circle cx='900' cy='60' r='80' fill='#fff8eb'/><path d='M0 190h1024v170H0z' fill='#b9d9e5'/><path d='M50 0v335m180-335v335m180-335v335m180-335v335m180-335v335m180-335v335' stroke='#fff8eb' stroke-width='14'/><path d='M400 264h620l-75-26-7-70-30-13-17 83-223-18-60-69-28 5 28 91-203 8z' fill='#fff8eb'/><path d='M910 163l27 9 8 66-32 1z' fill='#f06f6c'/><path d='M0 350h1024v130H0z' fill='#17223d'/><path d='M0 370h1024M0 460h1024' stroke='#75cdb2' stroke-width='8'/><path d='M0 430h1024' stroke='#5b6c86' stroke-width='3' stroke-dasharray='12 15'/><text x='48' y='106' font-family='sans-serif' font-weight='900' font-size='64' fill='#17223d'>LOST &amp; SORTED</text><text x='52' y='153' font-family='sans-serif' font-weight='700' font-size='25' letter-spacing='5' fill='#4b7187'>SORT. FLY. BUILD.</text>"
	for j in 4:
		var colors := ["#f06f6c","#75cdb2","#5b91e8","#f7c75a"]
		body += "<g transform='translate(%d,%d) rotate(%d) scale(1.3)'><path d='%s' fill='%s' stroke='#17223d' stroke-width='4'/><path d='M64 27V13q0-8 10-8h14q10 0 10 8v14' stroke='#17223d' stroke-width='4' fill='none'/><rect x='76' y='58' width='49' height='38' rx='5' fill='#fff8eb'/><path d='M84 73h32m-32 8h32' stroke='#17223d' stroke-width='2'/></g>" % [450+j*126,245-j%2*30,-8+j*6,PATHS[j],colors[j]]
	_write("res://store/feature_graphic.svg",_svg(1024,500,body))
	var feature := Image.load_from_file("res://store/feature_graphic.svg")
	if feature: feature.save_png("res://store/feature_graphic.png")

func _write(path: String, content: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		push_error("Asset write failed: " + path)
		return
	file.store_string(content)
