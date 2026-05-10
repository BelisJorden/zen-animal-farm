extends Control

@onready var ui_layer: CanvasLayer = $UILayer


func open_overlay(scene_path: String) -> void:
	for child in ui_layer.get_children():
		child.queue_free()
	ui_layer.add_child(load(scene_path).instantiate())
