extends Node3D

const GRID_SIZE   := 5
const TILE_SIZE   := 0.7
const GRID_ORIGIN := Vector3(-1.75, 0, -1.75)

var _occupied: Dictionary = {}          # "col,row" -> true
var _markers:  Dictionary = {}          # "col,row" -> MeshInstance3D


func _ready() -> void:
	for row in GRID_SIZE:
		for col in GRID_SIZE:
			var area := Area3D.new()
			area.set_meta("col", col)
			area.set_meta("row", row)

			var shape := CollisionShape3D.new()
			var box   := BoxShape3D.new()
			box.size   = Vector3(TILE_SIZE * 0.9, 0.3, TILE_SIZE * 0.9)
			shape.shape = box
			area.add_child(shape)
			area.position           = tile_center(col, row)
			area.position.y         = 0.1
			area.input_ray_pickable = true
			area.connect("input_event", _on_tile_input.bind(area))

			var marker := _make_marker()
			area.add_child(marker)
			_markers["%d,%d" % [col, row]] = marker

			add_child(area)


func tile_center(col: int, row: int) -> Vector3:
	return GRID_ORIGIN + Vector3(
		col * TILE_SIZE + TILE_SIZE / 2,
		0,
		row * TILE_SIZE + TILE_SIZE / 2
	)


func is_tile_free(col: int, row: int) -> bool:
	return not _occupied.has("%d,%d" % [col, row])


func occupy_tile(col: int, row: int) -> void:
	_occupied["%d,%d" % [col, row]] = true


func free_tile(col: int, row: int) -> void:
	_occupied.erase("%d,%d" % [col, row])


func shake_tile(col: int, row: int) -> void:
	var marker: MeshInstance3D = _markers.get("%d,%d" % [col, row])
	if not marker:
		return
	marker.visible = true
	marker.scale   = Vector3.ONE
	var t := create_tween()
	t.tween_property(marker, "scale", Vector3(1.4, 1.0, 1.4), 0.08).set_ease(Tween.EASE_OUT)
	t.tween_property(marker, "scale", Vector3(0.0, 1.0, 0.0), 0.20).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		marker.visible = false
		marker.scale   = Vector3.ONE
	)


func _make_marker() -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh      := BoxMesh.new()
	mesh.size      = Vector3(TILE_SIZE * 0.85, 0.04, TILE_SIZE * 0.85)
	mesh_inst.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color         = Color(1.0, 0.25, 0.25, 0.75)
	mat.transparency         = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode         = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	mesh_inst.visible        = false
	return mesh_inst


func _on_tile_input(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _idx: int, area: Area3D) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventScreenTouch and event.pressed):
		var col: int = area.get_meta("col")
		var row: int = area.get_meta("row")
		EventBus.tile_tapped.emit(col, row, tile_center(col, row))
