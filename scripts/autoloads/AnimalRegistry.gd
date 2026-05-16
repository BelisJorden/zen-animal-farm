extends Node

const AnimalData = preload("res://scripts/resources/animal_data.gd")

const ANIMAL_PATHS := [
	"res://data/animals/chicken.tres",
	"res://data/animals/sheep.tres",
	"res://data/animals/pig.tres",
	"res://data/animals/dragon.tres",
]

var _animals: Dictionary = {}


func _ready() -> void:
	for path in ANIMAL_PATHS:
		var animal = load(path)
		if animal:
			_animals[animal.id] = animal


func get_animal(id: String):
	return _animals.get(id, null)


func get_all() -> Array:
	return _animals.values()
