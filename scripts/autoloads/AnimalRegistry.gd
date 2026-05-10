extends RefCounted

const AnimalData = preload("res://scripts/resources/animal_data.gd")

static var _animals: Dictionary = {}
static var _initialized: bool = false


static func _ensure_init() -> void:
	if _initialized:
		return
	_initialized = true
	var dir := DirAccess.open("res://data/animals/")
	if not dir:
		push_error("AnimalRegistry: res://data/animals/ not found")
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var animal = load("res://data/animals/" + file_name)
			if animal:
				_animals[animal.id] = animal
		file_name = dir.get_next()
	dir.list_dir_end()


static func get_animal(id: String):
	_ensure_init()
	return _animals.get(id, null)


static func get_all() -> Array:
	_ensure_init()
	return _animals.values()
