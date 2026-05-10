extends Node3D

const AnimalData      = preload("res://scripts/resources/animal_data.gd")
const AnimalRegistry  = preload("res://scripts/autoloads/AnimalRegistry.gd")
const TAP_MAX_PIXELS  := 12.0
const PAN_SENSITIVITY := 0.012

@onready var camera:       Camera3D  = $Camera3D
@onready var grid:         Node3D    = $Grid
@onready var animals_root: Node3D    = $Animals
@onready var placing_ui              = $PlacingLayer/PlacingUI

var _placing_mode     := false
var _selected_animal: AnimalData = null
var _ghost: MeshInstance3D = null

var _drag_start  := Vector2.ZERO
var _cam_start   := Vector3.ZERO
var _is_dragging := false


func _ready() -> void:
	_build_world_base()
	placing_ui.visible = false
	placing_ui.animal_selection_changed.connect(_on_animal_selected)
	placing_ui.cancelled.connect(_exit_placing_mode)
	EventBus.placing_mode_entered.connect(_enter_placing_mode)
	EventBus.placing_mode_exited.connect(_exit_placing_mode)
	EventBus.tab_changed.connect(_on_tab_changed)


func _build_world_base() -> void:
	var island_mat := StandardMaterial3D.new()
	island_mat.albedo_color = Color(0.38, 0.60, 0.26)
	island_mat.roughness    = 0.95
	var island := MeshInstance3D.new()
	var island_mesh := BoxMesh.new()
	island_mesh.size = Vector3(3.4, 0.2, 3.4)
	island.mesh = island_mesh
	island.material_override = island_mat
	island.position = Vector3(0.0, -0.25, 0.0)
	add_child(island)


# ── Input ──────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_start  = event.position
			_cam_start   = camera.position
			_is_dragging = true
		else:
			_is_dragging = false
			if event.position.distance_to(_drag_start) < TAP_MAX_PIXELS:
				_handle_tap(event.position)

	elif event is InputEventMouseMotion and _is_dragging:
		_pan(event.position)

	elif event is InputEventScreenTouch:
		if event.pressed:
			_drag_start  = event.position
			_cam_start   = camera.position
			_is_dragging = true
		else:
			_is_dragging = false
			if event.position.distance_to(_drag_start) < TAP_MAX_PIXELS:
				_handle_tap(event.position)

	elif event is InputEventScreenDrag:
		_pan(event.position)


func _pan(screen_pos: Vector2) -> void:
	var delta  := screen_pos - _drag_start
	var right  := camera.global_basis.x
	var fwd    := Vector3(-right.z, 0.0, right.x).normalized()
	var scale  := camera.size / get_viewport().get_visible_rect().size.y
	camera.position = _cam_start + (-right * delta.x + fwd * delta.y) * scale


func _handle_tap(screen_pos: Vector2) -> void:
	var origin := camera.project_ray_origin(screen_pos)
	var end    := origin + camera.project_ray_normal(screen_pos) * 300.0
	var query  := PhysicsRayQueryParameters3D.create(origin, end)
	var hit    := get_world_3d().direct_space_state.intersect_ray(query)

	if hit.is_empty() or not hit.collider.has_method("set_highlighted"):
		return

	var tile = hit.collider
	if _placing_mode:
		_try_place(tile)
	else:
		grid.clear_highlights()
		tile.set_highlighted(true, true)
		EventBus.tile_selected.emit(tile.grid_pos)


# ── Placing mode ───────────────────────────────────────────────────────────────

func _enter_placing_mode(animal_dict: Dictionary) -> void:
	var animal: AnimalData = AnimalRegistry.get_animal(animal_dict.get("name", ""))
	if not animal:
		return
	_placing_mode    = true
	_selected_animal = animal
	placing_ui.open(animal)
	placing_ui.visible = true
	grid.highlight_free(true)
	_spawn_ghost(animal)


func _exit_placing_mode() -> void:
	if not _placing_mode:
		return
	_placing_mode    = false
	_selected_animal = null
	placing_ui.visible = false
	grid.clear_highlights()
	if _ghost:
		_ghost.queue_free()
		_ghost = null
	EventBus.placing_mode_exited.emit()


func _on_animal_selected(animal: AnimalData) -> void:
	_selected_animal = animal
	if _ghost:
		_ghost.queue_free()
	_spawn_ghost(animal)


func _spawn_ghost(animal: AnimalData) -> void:
	_ghost = MeshInstance3D.new()
	var mesh   := SphereMesh.new()
	mesh.radius = 0.18
	mesh.height = 0.36
	_ghost.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color         = animal.color
	mat.albedo_color.a       = 0.50
	mat.transparency         = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost.material_override = mat
	add_child(_ghost)
	_ghost.visible = false


func _try_place(tile) -> void:
	if tile.is_occupied or not _selected_animal:
		return
	if not GameState.remove_from_inventory(_selected_animal.id):
		return
	tile.is_occupied = true
	tile.set_highlighted(false)
	_spawn_animal(tile.position, _selected_animal)
	EventBus.animal_placed.emit(tile)
	_exit_placing_mode()


func _spawn_animal(tile_pos: Vector3, animal: AnimalData) -> void:
	var node: Node3D
	if animal.scene_path != "":
		var res := load(animal.scene_path)
		if res is PackedScene:
			node = res.instantiate()
		else:
			var mesh_inst := MeshInstance3D.new()
			mesh_inst.mesh = res
			node = mesh_inst
	else:
		var mesh_inst := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.18
		mesh.height = 0.36
		mesh_inst.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = animal.color
		mesh_inst.material_override = mat
		node = mesh_inst
	node.position = tile_pos + Vector3(0, 0.25, 0)
	node.rotation_degrees.y = 180.0
	animals_root.add_child(node)
	var timer := Timer.new()
	timer.wait_time = animal.coin_rate
	timer.autostart = true
	timer.timeout.connect(func(): EventBus.coins_earned.emit(animal.coin_amount))
	node.add_child(timer)
	_anim_spawn(node, animal.scale)
	_anim_bob(node)


func _anim_spawn(node: Node3D, target_scale: float = 1.0) -> void:
	node.scale = Vector3.ZERO
	var t := create_tween()
	t.tween_property(node, "scale", Vector3.ONE * target_scale, 0.30) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _anim_bob(node: Node3D) -> void:
	var base_y := node.position.y
	var t := create_tween().set_loops()
	t.tween_property(node, "position:y", base_y + 0.03, 1.1) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(node, "position:y", base_y - 0.03, 1.1) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


# ── Tab handler ────────────────────────────────────────────────────────────────

func _on_tab_changed(tab: String) -> void:
	match tab:
		"build":
			if not _placing_mode:
				EventBus.placing_mode_entered.emit({"name": "chicken"})
		_:
			if _placing_mode:
				_exit_placing_mode()
