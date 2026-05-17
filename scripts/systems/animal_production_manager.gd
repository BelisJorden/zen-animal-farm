extends Node

var all_placed:       Dictionary = {}  # farm_id -> Array[{type, col, row}]
var _timers:          Dictionary = {}  # "farm_id:col,row" -> Timer
var coins_per_second: float      = 0.0


func _ready() -> void:
	EventBus.accessory_equipped.connect(func(_f: String, _c: int, _r: int, _a: String) -> void:
		recalculate_cps())
	EventBus.accessory_unequipped.connect(func(_f: String, _c: int, _r: int) -> void:
		recalculate_cps())


func load_all_farms(placed_per_farm: Dictionary) -> void:
	for t in _timers.values():
		t.queue_free()
	_timers.clear()
	all_placed.clear()
	for farm_id in placed_per_farm:
		for entry in placed_per_farm[farm_id]:
			var type: String = entry.get("type", "")
			var col: int     = entry.get("col",  -1)
			var row: int     = entry.get("row",  -1)
			if type.is_empty() or col < 0 or row < 0:
				continue
			if not all_placed.has(farm_id):
				all_placed[farm_id] = []
			all_placed[farm_id].append({"type": type, "col": col, "row": row})
			_create_timer(farm_id, col, row, type)
	recalculate_cps()


func register_animal(farm_id: String, col: int, row: int, type: String) -> void:
	if not all_placed.has(farm_id):
		all_placed[farm_id] = []
	all_placed[farm_id].append({"type": type, "col": col, "row": row})
	_create_timer(farm_id, col, row, type)
	recalculate_cps()


func _create_timer(farm_id: String, col: int, row: int, type: String) -> void:
	var animal = AnimalRegistry.get_animal(type)
	if not animal:
		return
	var key := "%s:%d,%d" % [farm_id, col, row]
	if _timers.has(key):
		_timers[key].queue_free()
	var t := Timer.new()
	t.wait_time = float(animal.coin_rate)
	t.autostart = true
	var base_amt: int = animal.coin_amount
	t.timeout.connect(func():
		var amt := base_amt
		var acc_id := GameState.get_accessory(farm_id, col, row)
		if acc_id != "":
			var acc = AccessoryRegistry.get_accessory(acc_id)
			if acc and acc.coin_bonus_percent > 0.0:
				amt = int(base_amt * (1.0 + acc.coin_bonus_percent))
		EventBus.coins_earned.emit(amt)
		EventBus.animal_coin_produced.emit(farm_id, col, row, amt)
	)
	add_child(t)
	_timers[key] = t


func recalculate_cps() -> void:
	var total: float = 0.0
	for farm_id in all_placed:
		for entry in all_placed[farm_id]:
			var animal = AnimalRegistry.get_animal(entry.get("type", ""))
			if not animal:
				continue
			var col: int = entry.get("col", -1)
			var row: int = entry.get("row", -1)
			var base: float = float(animal.coin_amount) / float(animal.coin_rate)
			var acc_id := GameState.get_accessory(farm_id, col, row)
			if acc_id != "":
				var acc = AccessoryRegistry.get_accessory(acc_id)
				if acc and acc.coin_bonus_percent > 0.0:
					base *= (1.0 + acc.coin_bonus_percent)
			total += base
	coins_per_second = total
	EventBus.coins_per_second_changed.emit(total)
