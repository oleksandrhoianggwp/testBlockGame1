class_name AirportScreen
extends Control
signal back_requested
signal route_requested(route: String)
signal upgrade_requested(world: int, zone: String)
var scene: AirportScene
var profile: Dictionary
var progress_label: Label
var bar: ProgressBar
var currency: Label
var perks_label: Label

func setup(data: Dictionary, _world: int) -> void:
	profile = data
	var safe := UiKit.screen_background(self,UiKit.SKY,"res://assets/art/airport_atmosphere.png")
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",9)
	safe.add_child(column)
	var head := UiKit.header(tr("airport.hub"),int(profile.get("coins",0)))
	head["back"].pressed.connect(func() -> void: back_requested.emit())
	currency = head["currency"]
	column.add_child(head["root"])
	progress_label = UiKit.label("",15,true)
	progress_label.add_theme_stylebox_override("normal",UiKit.panel(UiKit.PAPER,12))
	column.add_child(progress_label)
	bar = UiKit.progress_bar(0)
	column.add_child(bar)
	scene = AirportScene.new()
	scene.configure(profile)
	scene.zone_selected.connect(_open_sheet)
	column.add_child(scene)
	var perks := UiKit.label(tr("airport.tap_zone"),14,true)
	perks.add_theme_stylebox_override("normal",UiKit.panel(UiKit.PAPER,14))
	column.add_child(perks)
	perks_label = UiKit.label("",12,true)
	column.add_child(perks_label)
	column.add_child(UiKit.navigation("airport",func(id: String) -> void: route_requested.emit(id)))
	refresh()

func _open_sheet(zone: String) -> void:
	var sheet := UpgradeSheet.new()
	add_child(sheet)
	sheet.configure(zone,profile)
	sheet.purchase_requested.connect(func(id: String) -> void: upgrade_requested.emit(0,id))

func refresh(zone: String = "") -> void:
	var value := AirportEconomy.progress(profile.get("airport",{}))
	progress_label.text = tr("home.hub_progress") % value
	bar.value = value
	currency.text = "● %d" % int(profile.get("coins",0))
	var unlocked: Array[String] = []
	for id: String in AirportEconomy.ZONES:
		if int(profile.get("airport",{}).get(id,0)) == 3: unlocked.append(tr("perk.brief."+id))
	perks_label.text = " • ".join(unlocked)
	perks_label.visible = not unlocked.is_empty()
	if not zone.is_empty(): scene.reveal(zone)
