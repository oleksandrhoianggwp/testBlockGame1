class_name AirportEconomy
extends RefCounted

const ZONES := ["entrance", "checkin", "baggage", "security", "cafe", "tower", "runway"]
static var _config: Dictionary = {}

static func config() -> Dictionary:
	if _config.is_empty():
		_config = JSON.parse_string(FileAccess.get_file_as_string("res://data/configs/economy.json"))
	return _config

static func cost(zone: String, stage: int) -> int:
	if zone not in ZONES or stage < 0 or stage >= 3:
		return 0
	return int(config()["upgrade_costs"][zone][stage])

static func total_cost() -> int:
	var total := 0
	for zone in ZONES:
		for stage in 3:
			total += cost(zone, stage)
	return total

static func progress(airport: Dictionary) -> int:
	var stages := 0
	for zone in ZONES:
		stages += clampi(int(airport.get(zone, 0)), 0, 3)
	return int(round(float(stages) / 21.0 * 100.0))

static func perks(airport: Dictionary) -> Dictionary:
	return {"undo_charge": int(int(airport.get("baggage", 0)) == 3),
		"mystery_reveal": int(int(airport.get("security", 0)) == 3),
		"priority_move": 1 if int(airport.get("tower", 0)) == 3 else 0,
		"first_clear_bonus": 10 if int(airport.get("cafe", 0)) == 3 else 0,
		"performance_bonus": 5 if int(airport.get("checkin", 0)) == 3 else 0}

static func affordable(airport: Dictionary, coins: int) -> bool:
	for zone in ZONES:
		var stage := int(airport.get(zone, 0))
		if stage < 3 and coins >= cost(zone, stage):
			return true
	return false

static func shift_multiplier(round_number: int) -> float:
	return minf(float(config()["shift_multiplier_cap"]), 1.0 + maxi(0, round_number - 1) * float(config()["shift_multiplier_step"]))
