extends Node

const SAVE_PATH := "user://zenfarm_save.cfg"

# Placed animals loaded from disk; farm.gd reads this in _ready() via restore_farm()
var placed_animals_to_restore: Array = []


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		save_game()


# ── Save ──────────────────────────────────────────────────────────────────────

func save_game() -> void:
	var cfg := ConfigFile.new()

	cfg.set_value("gamestate", "coins",         GameState.coins)
	cfg.set_value("gamestate", "spirit_shards",  GameState.spirit_shards)

	var unplaced_types: Array = []
	for entry in GameState.unplaced_animals:
		unplaced_types.append(entry.get("type", ""))
	cfg.set_value("inventory", "unplaced",        unplaced_types)
	cfg.set_value("inventory", "purchased_types", GameState.purchased_animal_types)

	cfg.set_value("farm", "placed", placed_animals_to_restore)

	QuestManager.save_state(cfg)

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

	placed_animals_to_restore = cfg.get_value("farm", "placed", [])

	QuestManager.load_state(cfg)
	return true


# Called by farm.gd._ready() — emits farm_data_loaded so farm.gd can respawn animals
func restore_farm() -> void:
	EventBus.farm_data_loaded.emit(placed_animals_to_restore)


# Called by farm.gd after each placement
func register_placed_animal(col: int, row: int, type: String) -> void:
	placed_animals_to_restore.append({"col": col, "row": row, "type": type})
	save_game()


# ── Defaults (fresh start) ────────────────────────────────────────────────────

func _apply_defaults() -> void:
	placed_animals_to_restore = []
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
