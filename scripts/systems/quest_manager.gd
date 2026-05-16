extends Node

const ALL_QUESTS: Array = [
	# Easy
	{"id": "place_3_animals",  "title": "Place animals",        "description": "Place 3 animals on your farm",        "type": "place_animals", "target": 3,    "reward_coins": 50,  "reward_shards": 2,  "reward_item": ""},
	{"id": "earn_200_coins",   "title": "Earn coins",           "description": "Earn 200 coins",                      "type": "earn_coins",    "target": 200,  "reward_coins": 30,  "reward_shards": 3,  "reward_item": ""},
	{"id": "hatch_1_egg",      "title": "Hatch an egg",         "description": "Hatch 1 egg in the hatchery",         "type": "hatch_eggs",    "target": 1,    "reward_coins": 40,  "reward_shards": 5,  "reward_item": ""},
	{"id": "tap_5_animals",    "title": "Tap animals",          "description": "Tap 5 animals on your farm",          "type": "tap_animals",   "target": 5,    "reward_coins": 25,  "reward_shards": 1,  "reward_item": ""},
	# Medium
	{"id": "place_10_animals", "title": "Place animals",        "description": "Place 10 animals on your farm",       "type": "place_animals", "target": 10,   "reward_coins": 150, "reward_shards": 5,  "reward_item": ""},
	{"id": "earn_1000_coins",  "title": "Earn coins",           "description": "Earn 1.000 coins",                    "type": "earn_coins",    "target": 1000, "reward_coins": 100, "reward_shards": 8,  "reward_item": ""},
	{"id": "hatch_5_eggs",     "title": "Hatch eggs",           "description": "Hatch 5 eggs in the hatchery",        "type": "hatch_eggs",    "target": 5,    "reward_coins": 200, "reward_shards": 10, "reward_item": ""},
	{"id": "collect_20_shards","title": "Collect spirit shards","description": "Collect 20 spirit shards",            "type": "collect_shards","target": 20,   "reward_coins": 300, "reward_shards": 5,  "reward_item": ""},
	# Hard
	{"id": "place_25_animals", "title": "Place animals",        "description": "Place 25 animals on your farm",       "type": "place_animals", "target": 25,   "reward_coins": 500, "reward_shards": 15, "reward_item": ""},
	{"id": "earn_5000_coins",  "title": "Earn coins",           "description": "Earn 5.000 coins",                    "type": "earn_coins",    "target": 5000, "reward_coins": 400, "reward_shards": 20, "reward_item": ""},
	{"id": "hatch_15_eggs",    "title": "Hatch eggs",           "description": "Hatch 15 eggs in the hatchery",       "type": "hatch_eggs",    "target": 15,   "reward_coins": 600, "reward_shards": 25, "reward_item": ""},
	{"id": "tap_50_animals",   "title": "Tap animals",          "description": "Tap 50 animals on your farm",         "type": "tap_animals",   "target": 50,   "reward_coins": 250, "reward_shards": 15, "reward_item": ""},
]

var active_quests:    Array      = []
var completed_quests: Array      = []
var quest_progress:   Dictionary = {}

var _last_known_shards: int = 0


func _ready() -> void:
	_last_known_shards = GameState.spirit_shards
	_fill_active_quests()
	EventBus.animal_placed.connect(_on_animal_placed)
	EventBus.coins_earned.connect(_on_coins_earned)
	EventBus.animal_hatched.connect(_on_animal_hatched)
	EventBus.animal_tapped.connect(_on_animal_tapped)
	EventBus.shards_changed.connect(_on_shards_changed)


func get_quest(id: String) -> Dictionary:
	for q in ALL_QUESTS:
		if q["id"] == id:
			return q
	return {}


func get_active_quest_data() -> Array:
	var result := []
	for id in active_quests:
		var q := get_quest(id)
		if not q.is_empty():
			result.append({"quest": q, "progress": quest_progress.get(id, 0)})
	return result


# ── Internal ──────────────────────────────────────────────────────────────────

func _fill_active_quests() -> void:
	while active_quests.size() < 3:
		var next := _next_available_quest()
		if next.is_empty():
			break
		active_quests.append(next)
		if not quest_progress.has(next):
			quest_progress[next] = 0
	EventBus.quests_updated.emit()


func _next_available_quest() -> String:
	for q in ALL_QUESTS:
		var id: String = q["id"]
		if id not in completed_quests and id not in active_quests:
			return id
	return ""


func _track_progress(quest_type: String, amount: int) -> void:
	for id in active_quests.duplicate():
		var q := get_quest(id)
		if q.get("type", "") != quest_type:
			continue
		quest_progress[id] = quest_progress.get(id, 0) + amount
		var current: int = quest_progress[id]
		var target:  int = q["target"]
		EventBus.quest_progress_updated.emit(id, current, target)
		if current >= target:
			_complete_quest(id)


func _complete_quest(id: String) -> void:
	var q := get_quest(id)
	if q.is_empty():
		return
	completed_quests.append(id)
	active_quests.erase(id)

	var coins:  int    = q.get("reward_coins",  0)
	var shards: int    = q.get("reward_shards", 0)
	var item:   String = q.get("reward_item",   "")

	GameState.add_coins(coins)
	if shards > 0:
		GameState.add_spirit_shards(shards)
	if not item.is_empty() and item not in GameState.unlocked_items:
		GameState.unlocked_items.append(item)

	EventBus.quest_completed.emit(id, coins, shards, item)
	_fill_active_quests()
	SaveSystem.save_game()


# ── Signal handlers ───────────────────────────────────────────────────────────

func _on_animal_placed(_animal: Node) -> void:
	_track_progress("place_animals", 1)


func _on_coins_earned(amount: int) -> void:
	_track_progress("earn_coins", amount)


func _on_animal_hatched(_id: String, _rarity: String) -> void:
	_track_progress("hatch_eggs", 1)


func _on_animal_tapped(_animal: Node) -> void:
	_track_progress("tap_animals", 1)


func _on_shards_changed(new_total: int) -> void:
	if new_total > _last_known_shards:
		_track_progress("collect_shards", new_total - _last_known_shards)
	_last_known_shards = new_total


# ── Save / Load ───────────────────────────────────────────────────────────────

func save_state(cfg: ConfigFile) -> void:
	cfg.set_value("quests", "active",    active_quests)
	cfg.set_value("quests", "completed", completed_quests)
	cfg.set_value("quests", "progress",  quest_progress)


func load_state(cfg: ConfigFile) -> void:
	active_quests    = Array(cfg.get_value("quests", "active",    []))
	completed_quests = Array(cfg.get_value("quests", "completed", []))
	quest_progress   = cfg.get_value("quests", "progress", {})
	_last_known_shards = GameState.spirit_shards
	_fill_active_quests()
