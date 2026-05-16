extends Node3D

const GRID_SIZE   := 5
const TILE_SIZE   := 0.7
const GRID_ORIGIN := Vector3(-1.75, 0, -1.75)

var _occupied:     Dictionary = {}   # "col,row" -> true
var _markers:      Dictionary = {}   # "col,row" -> MeshInstance3D
var _selected_col: int = -1
var _selected_row: int = -1

@onready var _tile_highlight: Node2D = $"../HighlightLayer/TileHighlight2D"


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
			area.input_ray_pickable = false

			var marker := _make_marker()
			area.add_child(marker)
			_markers["%d,%d" % [col, row]] = marker

			add_child(area)


# ── Public API ────────────────────────────────────────────────────────────────

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


func select_tile(col: int, row: int) -> void:
	_selected_col = col
	_selected_row = row
	_tile_highlight.show_at(tile_center(col, row))


func deselect_tile() -> void:
	if not _tile_highlight.visible:
		return
	_selected_col = -1
	_selected_row = -1
	_tile_highlight.hide_highlight()


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


# ── Private ───────────────────────────────────────────────────────────────────

func _make_marker() -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh      := BoxMesh.new()
	mesh.size      = Vector3(TILE_SIZE * 0.85, 0.04, TILE_SIZE * 0.85)
	mesh_inst.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color            = Color(1.0, 0.25, 0.25, 0.75)
	mat.transparency            = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode            = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	mesh_inst.visible           = false
	return mesh_inst
