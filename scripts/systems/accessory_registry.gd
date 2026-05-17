extends Node

const ACCESSORY_PATHS: Array = [
	"res://data/accessories/golden_crown.tres",
	"res://data/accessories/mystic_orb.tres",
	"res://data/accessories/wizard_hat.tres",
]

var ACCESSORIES: Dictionary = {}


func _ready() -> void:
	for path in ACCESSORY_PATHS:
		var acc = load(path)
		if acc:
			ACCESSORIES[acc.id] = acc


func get_accessory(id: String) -> AccessoryData:
	return ACCESSORIES.get(id, null)


func get_all() -> Array:
	return ACCESSORIES.values()
