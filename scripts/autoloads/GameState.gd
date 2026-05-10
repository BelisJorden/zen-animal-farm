extends Node

signal coins_changed(new_amount: int)
signal spirit_shards_changed(new_amount: int)

var coins: int = 0:
	set(value):
		coins = max(0, value)
		coins_changed.emit(coins)
		EventBus.coins_changed.emit(coins)

var spirit_shards: int = 0:
	set(value):
		spirit_shards = max(0, value)
		spirit_shards_changed.emit(spirit_shards)

func _ready() -> void:
	EventBus.coins_earned.connect(add_coins)
	coins = 100
	spirit_shards = 5
	for i in 5:
		add_to_inventory({"name": "chicken"})


var player_name: String = "Yumi"
var day: int = 1
var level: int = 1

var farms: Array[Dictionary] = []
var animals: Array[Dictionary] = []
var unlocked_items: Array[String] = []
var unplaced_animals: Array[Dictionary] = []       # [{"type": "chicken", "id": "..."}]
var purchased_animal_types: Array[String] = []     # ordered list of ever-bought types


func add_to_inventory(animal_data: Dictionary) -> void:
	var type_name: String = animal_data["name"]
	var id := "%d_%s" % [Time.get_ticks_msec(), type_name]
	unplaced_animals.append({"type": type_name, "id": id})
	if not type_name in purchased_animal_types:
		purchased_animal_types.append(type_name)
	EventBus.inventory_changed.emit()


func remove_from_inventory(type_name: String) -> bool:
	for i in unplaced_animals.size():
		if unplaced_animals[i]["type"] == type_name:
			unplaced_animals.remove_at(i)
			EventBus.inventory_changed.emit()
			return true
	return false


func add_coins(amount: int) -> void:
	coins += amount


func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	return true


func add_spirit_shards(amount: int) -> void:
	spirit_shards += amount


func spend_spirit_shards(amount: int) -> bool:
	if spirit_shards < amount:
		return false
	spirit_shards -= amount
	return true
