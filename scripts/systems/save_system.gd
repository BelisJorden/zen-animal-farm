extends Node

const SAVE_PATH := "user://zenfarm_save.cfg"

# Per-farm placed animals: { "farm_1": [{col, row, type}, ...], "farm_2": [...] }
var placed_animals_per_farm: Dictionary = {}


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		save_game()


# ── Save ──────────────────────────────────────────────────────────────────────

func save_game() -> void:
	var cfg := ConfigFile.new()

	cfg.set_value("gamestate", "coins",        GameState.coins)
	cfg.set_value("gamestate", "spirit_shards", GameState.spirit_shards)

	var unplaced_types: Array = []
	for entry in GameState.unplaced_animals:
		unplaced_types.append(entry.get("type", ""))
	cfg.set_value("inventory", "unplaced",        unplaced_types)
	cfg.set_value("inventory", "purchased_types", GameState.purchased_animal_types)

	for farm_id in placed_animals_per_farm:
		cfg.set_value("farms", farm_id, placed_animals_per_farm[farm_id])

	QuestManager.save_state(cfg)
	FarmManager.save_state(cfg)

	cfg.save(SAVE_PATH)


# ── Load ──────────────────────────────────────────────────────────────────────

func load_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		_apply_defaults()
		return false

	GameState.coins         = cfg.get_value("gamestate", "coins",        100)
	GameState.spirit_shards = cfg.get_value("gamestate", "spirit_shards", 10)

	GameState.unplaced_animals.clear()
	GameState.purchased_animal_types.clear()
	var unplaced_types: Array = cfg.get_value("inventory", "unplaced", [])
	for i in unplaced_types.size():
		var type_name: String = str(unplaced_types[i])
		if type_name.is_empty():
			continue
		var id := "%d_%s" % [i, type_name]
		GameState.unplaced_animals.append({"type": type_name, "id": id})
	GameState.purchased_animal_types = Array(cfg.get_value("inventory", "purchased_types", []))
	EventBus.inventory_changed.emit()

	# Migration from old single-farm save format
	placed_animals_per_farm.clear()
	var old_placed = cfg.get_value("farm", "placed", null)
	if old_placed != null:
		placed_animals_per_farm["farm_1"] = old_placed
	else:
		for farm in FarmManager.farms:
			placed_animals_per_farm[farm.id] = cfg.get_value("farms", farm.id, [])

	QuestManager.load_state(cfg)
	FarmManager.load_state(cfg)
	AnimalProductionManager.load_all_farms(placed_animals_per_farm)
	return true


func get_placed_animals(farm_id: String) -> Array:
	return placed_animals_per_farm.get(farm_id, [])


# Called by farm.gd._ready()
func restore_farm() -> void:
	var farm_id: String = FarmManager.active_farm_id
	EventBus.farm_data_loaded.emit(placed_animals_per_farm.get(farm_id, []))


# Called by farm.gd after each placement
func register_placed_animal(col: int, row: int, type: String) -> void:
	var farm_id: String = FarmManager.active_farm_id
	if not placed_animals_per_farm.has(farm_id):
		placed_animals_per_farm[farm_id] = []
	placed_animals_per_farm[farm_id].append({"col": col, "row": row, "type": type})
	AnimalProductionManager.register_animal(farm_id, col, row, type)
	save_game()


# ── Defaults (fresh start) ────────────────────────────────────────────────────

func _apply_defaults() -> void:
	placed_animals_per_farm = {}
	GameState.coins         = 100
	GameState.spirit_shards = 25
	GameState.unplaced_animals.clear()
	GameState.purchased_animal_types.clear()
	for _i in 5:
		GameState.add_to_inventory({"name": "chicken"})
	for _i in 5:
		GameState.add_to_inventory({"name": "sheep"})
	for _i in 5:
		GameState.add_to_inventory({"name": "pig"})
	QuestManager.active_quests.clear()
	QuestManager.completed_quests.clear()
	QuestManager.quest_progress.clear()
	QuestManager._fill_active_quests()
	AnimalProductionManager.load_all_farms({})
