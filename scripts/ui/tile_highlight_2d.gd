extends Node2D

var _world_pos: Vector3  = Vector3.ZERO
var _camera:   Camera3D  = null


func _ready() -> void:
	visible = false


func show_at(pos: Vector3) -> void:
	_world_pos = pos
	visible    = true
	queue_redraw()


func hide_highlight() -> void:
	visible = false


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if not visible:
		return
	if not _camera:
		_camera = get_viewport().get_camera_3d()
	if not _camera:
		return
	var screen_pos := _camera.unproject_position(_world_pos + Vector3(0, 0.1, 0)) + Vector2(5, -6)
	var w := 38.0
	var h := 25.0
	var points := PackedVector2Array([
		screen_pos + Vector2(0, -h),
		screen_pos + Vector2(w,  0),
		screen_pos + Vector2(0,  h),
		screen_pos + Vector2(-w, 0),
	])
	draw_colored_polygon(points, Color(0.6, 0.4, 0.9, 0.5))
	draw_polyline(points + PackedVector2Array([points[0]]), Color(0.7, 0.5, 1.0, 0.8), 2.0)
