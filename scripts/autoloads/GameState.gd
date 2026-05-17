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
		EventBus.shards_changed.emit(spirit_shards)

func _ready() -> void:
	EventBus.coins_earned.connect(add_coins)


var farms: Array[Dictionary] = []
var animals: Array[Dictionary] = []
var unlocked_items: Array[String] = []
var unplaced_animals: Array[Dictionary] = []       # [{"type": "chicken", "id": "..."}]
var purchased_animal_types: Array[String] = []     # ordered list of ever-bought types
var animal_accessories: Dictionary = {}            # "farm_id:col,row" -> accessory_id
var owned_accessories: Array[String] = []          # list of owned accessory IDs


func equip_accessory(farm_id: String, col: int, row: int, accessory_id: String) -> void:
	var key := "%s:%d,%d" % [farm_id, col, row]
	animal_accessories[key] = accessory_id
	EventBus.accessory_equipped.emit(farm_id, col, row, accessory_id)


func unequip_accessory(farm_id: String, col: int, row: int) -> void:
	var key := "%s:%d,%d" % [farm_id, col, row]
	animal_accessories.erase(key)
	EventBus.accessory_unequipped.emit(farm_id, col, row)


func get_accessory(farm_id: String, col: int, row: int) -> String:
	return animal_accessories.get("%s:%d,%d" % [farm_id, col, row], "")


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


func reset_state() -> void:
	coins         = 0
	spirit_shards = 0
	unplaced_animals.clear()
	purchased_animal_types.clear()
	animal_accessories.clear()
	owned_accessories.clear()
	EventBus.coins_per_second_changed.emit(0.0)


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


func spend_shards(amount: int) -> bool:
	return spend_spirit_shards(amount)


func add_shards(amount: int) -> void:
	add_spirit_shards(amount)
