extends Node3D

const GRID_SIZE   := 5
const TILE_SIZE   := 0.7
const GRID_ORIGIN := Vector3(-1.75, 0, -1.75)

var _occupied:    Dictionary = {}   # "col,row" -> true
var _markers:     Dictionary = {}   # "col,row" -> MeshInstance3D
var _decal:       Decal  = null
var _decal_tween: Tween  = null
var _selected_col: int   = -1
var _selected_row: int   = -1


func _ready() -> void:
	_decal = _make_decal()
	add_child(_decal)

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

	var center := tile_center(col, row)
	_decal.position = Vector3(center.x, 0.5, center.z)

	if _decal_tween:
		_decal_tween.kill()

	if not _decal.visible:
		_decal.visible  = true
		_decal.modulate = Color(1, 1, 1, 0)
		_decal_tween = create_tween()
		_decal_tween.tween_property(_decal, "modulate", Color(1, 1, 1, 0.85), 0.15)
	# already visible on another tile: position already updated above, no fade needed


func deselect_tile() -> void:
	if not _decal.visible:
		return
	_selected_col = -1
	_selected_row = -1
	if _decal_tween:
		_decal_tween.kill()
	_decal_tween = create_tween()
	_decal_tween.tween_property(_decal, "modulate", Color(1, 1, 1, 0), 0.10)
	_decal_tween.tween_callback(func(): _decal.visible = false)


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

func _make_decal() -> Decal:
	var decal := Decal.new()
	decal.size            = Vector3(TILE_SIZE * 0.85, 1.0, TILE_SIZE * 0.85)
	decal.texture_albedo  = _make_circle_texture()
	decal.modulate        = Color(1, 1, 1, 0)
	decal.visible         = false
	return decal


func _make_circle_texture() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var dx:    float = (x - 31.5) / 32.0
			var dy:    float = (y - 31.5) / 32.0
			var d:     float = sqrt(dx * dx + dy * dy)
			var alpha: float = clamp(exp(-d * d * 2.5), 0.0, 1.0)
			img.set_pixel(x, y, Color(0.78, 0.60, 0.95, alpha))
	return ImageTexture.create_from_image(img)


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


func _on_tile_input(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _idx: int, area: Area3D) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventScreenTouch and event.pressed):
		var col: int = area.get_meta("col")
		var row: int = area.get_meta("row")
		EventBus.tile_tapped.emit(col, row, tile_center(col, row))
