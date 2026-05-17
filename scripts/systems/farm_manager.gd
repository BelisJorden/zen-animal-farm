extends Node

const FARM_PATHS: Array = [
	"res://data/farms/farm_1.tres",
	"res://data/farms/farm_2.tres",
]

var farms:          Array  = []
var unlocked_farms: Array  = ["farm_1"]
var active_farm_id: String = "farm_1"


func _ready() -> void:
	for path in FARM_PATHS:
		var farm = load(path)
		if farm:
			farms.append(farm)


func get_farm(id: String) -> FarmData:
	for farm in farms:
		if farm.id == id:
			return farm
	return null


func get_active_farm() -> FarmData:
	return get_farm(active_farm_id)


func is_unlocked(id: String) -> bool:
	return id in unlocked_farms


func unlock_farm(id: String) -> bool:
	var farm := get_farm(id)
	if not farm:
		return false
	if is_unlocked(id):
		return true
	if not GameState.spend_coins(farm.unlock_cost):
		return false
	unlocked_farms.append(id)
	EventBus.farm_unlocked.emit(id)
	SaveSystem.save_game()
	return true


func set_active_farm(id: String) -> void:
	if not is_unlocked(id):
		return
	active_farm_id = id
	EventBus.farm_changed.emit(id)
	SaveSystem.save_game()


func get_unlocked_farms() -> Array:
	var result := []
	for farm in farms:
		if is_unlocked(farm.id):
			result.append(farm)
	return result


func switch_to_next_farm() -> void:
	var unlocked := get_unlocked_farms()
	if unlocked.size() <= 1:
		EventBus.farm_switch_bounced.emit()
		return
	var idx := 0
	for i in unlocked.size():
		if unlocked[i].id == active_farm_id:
			idx = i
			break
	set_active_farm(unlocked[(idx + 1) % unlocked.size()].id)


func switch_to_prev_farm() -> void:
	var unlocked := get_unlocked_farms()
	if unlocked.size() <= 1:
		EventBus.farm_switch_bounced.emit()
		return
	var idx := 0
	for i in unlocked.size():
		if unlocked[i].id == active_farm_id:
			idx = i
			break
	set_active_farm(unlocked[(idx - 1 + unlocked.size()) % unlocked.size()].id)


func save_state(cfg: ConfigFile) -> void:
	cfg.set_value("farm_manager", "unlocked", unlocked_farms)
	cfg.set_value("farm_manager", "active",   active_farm_id)


func load_state(cfg: ConfigFile) -> void:
	unlocked_farms = Array(cfg.get_value("farm_manager", "unlocked", ["farm_1"]))
	active_farm_id = cfg.get_value("farm_manager", "active",   "farm_1")
