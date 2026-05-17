extends Control

@onready var ui_layer:      CanvasLayer = $UILayer
@onready var background:    ColorRect   = $Background
@onready var farm_container: SubViewportContainer = $FarmContainer


func _ready() -> void:
	EventBus.farm_changed.connect(_on_farm_changed)
	_apply_farm_gradient(FarmManager.get_active_farm())


func open_overlay(scene_path: String) -> void:
	for child in ui_layer.get_children():
		child.queue_free()
	ui_layer.add_child(load(scene_path).instantiate())


func _apply_farm_gradient(farm_data: FarmData) -> void:
	if not farm_data:
		return
	var mat: ShaderMaterial = background.material as ShaderMaterial
	if not mat:
		return
	mat.set_shader_parameter("color_top",    farm_data.background_top)
	mat.set_shader_parameter("color_mid",    farm_data.background_mid)
	mat.set_shader_parameter("color_bottom", farm_data.background_bottom)


func _on_farm_changed(farm_id: String) -> void:
	var farm_data: FarmData = FarmManager.get_farm(farm_id)
	if not farm_data:
		return
	# Fade out, update colours, fade in
	var t := create_tween()
	t.tween_property(farm_container, "modulate:a", 0.0, 0.18)
	t.tween_callback(func(): _apply_farm_gradient(farm_data))
	t.tween_property(farm_container, "modulate:a", 1.0, 0.22)
