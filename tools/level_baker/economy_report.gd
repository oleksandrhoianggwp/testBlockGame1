extends SceneTree

func _initialize() -> void:
	var economy = preload("res://core/progression/airport_economy.gd")
	var generator = preload("res://core/generation/level_generator.gd").new()
	var service = preload("res://services/save_service.gd").new()
	service.persistence_enabled = false
	service.data = service.defaults()
	var income := 200
	var purchased := 0
	var upgrade_levels: Array[int] = []
	for level in range(1,76):
		var parameters: Dictionary = generator.campaign_parameters(level)
		var stars := 3 if level%2 == 1 else 2
		var reward := 40+stars*10+(15 if parameters["priority_enabled"] else 0)
		var wallet := int(service.data["coins"])
		service.complete_level(level,stars,1000,reward,75,false)
		income += int(service.data["coins"])-wallet
		while economy.affordable(service.data["airport"],int(service.data["coins"])):
			var cheapest := 99999
			var zone := ""
			for id: String in economy.ZONES:
				var stage := int(service.data["airport"].get(id,0))
				var cost: int = economy.cost(id,stage)
				if stage < 3 and cost < cheapest:
					cheapest = cost; zone = id
			if not service.purchase_airport_upgrade(0,zone,[],false): break
			purchased += 1
			upgrade_levels.append(level)
	var report := {"baseline_total_renovation_cost":7*(100+150+220)*15,"global_total_renovation_cost":economy.total_cost(),"campaign_income_with_initial_wallet":income,"upgrades_purchased":purchased,"total_upgrade_stages":21,"completion_percent":economy.progress(service.data["airport"]),"campaign_levels_per_upgrade":snappedf(75.0/maxi(1,purchased),.01),"upgrade_levels":upgrade_levels,"remaining_wallet":service.data["coins"],"assumption":"alternating 2/3 stars; first clears; priority success; cheapest upgrade policy; no Daily/Shift/replays"}
	var file := FileAccess.open("res://data/campaign/economy_report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("ECONOMY: ",JSON.stringify(report))
	service.free()
	quit()
