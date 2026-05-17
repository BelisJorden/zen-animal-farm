extends Node3D

const AnimalData      = preload("res://scripts/resources/animal_data.gd")
const PAN_SENSITIVITY := 0.012
const TAP_MAX_PIXELS  := 12.0
const SWIPE_MIN_PX    := 80.0   # minimum horizontal pixels to count as swipe

@onready var camera:       Camera3D = $Camera3D
@onready var animals_root: Node3D   = $AnimalLayer
@onready var placing_ui             = $PlacingLayer/PlacingUI
@onready var tile_layer:   Node3D   = $TileLayer

var _placing_mode     := false
var _selected_animal: AnimalData = null
var _ghost: MeshInstance3D = null

var _drag_start      := Vector2.ZERO
var _cam_start       := Vector3.ZERO
var _is_dragging     := false
var _swipe_handled   := false

var _selected_tile_col: int     = -1
var _selected_tile_row: int     = -1
var _selected_tile_pos: Vector3 = Vector3.ZERO

var _bob_tweens:     Dictionary = {}  # Node3D -> Tween
var _animal_at_tile: Dictionary = {}  # "col,row" -> Node3D

var _current_island:    Node3D = null
var _fantasy_orbit:     Node3D = null
var _fantasy_tween:     Tween  = null


func _ready() -> void:
	FXManager.set_fx_root(animals_root)
	placing_ui.visible = false
	placing_ui.animal_selection_changed.connect(_on_animal_selected)
	placing_ui.cancelled.connect(_exit_placing_mode)
	EventBus.placing_mode_entered.connect(_enter_placing_mode)
	EventBus.placing_mode_exited.connect(_exit_placing_mode)
	EventBus.tab_changed.connect(_on_tab_changed)
	EventBus.tile_tapped.connect(_on_tile_tapped)
	EventBus.farm_data_loaded.connect(_restore_placed_animals)
	EventBus.farm_changed.connect(_on_farm_changed)
	EventBus.animal_coin_produced.connect(_on_coin_produced)
	_spawn_island()
	SaveSystem.restore_farm.call_deferred()
	_update_fantasy_particles.call_deferred()
	_refresh_hud_on_load.call_deferred()


# ── Input ──────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_start    = event.position
			_cam_start     = camera.position
			_is_dragging   = true
			_swipe_handled = false
		else:
			_is_dragging = false
			if not _swipe_handled:
				var delta: Vector2 = event.position - _drag_start
				if _is_horizontal_swipe(delta):
					_swipe_handled = true
					_handle_swipe(delta.x)
				elif event.position.distance_to(_drag_start) < TAP_MAX_PIXELS:
					_handle_tap(event.position)

	elif event is InputEventMouseMotion and _is_dragging:
		_pan(event.position)

	elif event is InputEventScreenTouch:
		if event.pressed:
			_drag_start    = event.position
			_cam_start     = camera.position
			_is_dragging   = true
			_swipe_handled = false
		else:
			_is_dragging = false
			if not _swipe_handled:
				var delta: Vector2 = event.position - _drag_start
				if _is_horizontal_swipe(delta):
					_swipe_handled = true
					_handle_swipe(delta.x)
				elif event.position.distance_to(_drag_start) < TAP_MAX_PIXELS:
					_handle_tap(event.position)

	elif event is InputEventScreenDrag:
		_pan(event.position)


func _is_horizontal_swipe(delta: Vector2) -> bool:
	return abs(delta.x) >= SWIPE_MIN_PX and abs(delta.y) < abs(delta.x) * 0.7


func _handle_swipe(dx: float) -> void:
	if dx > 0:
		FarmManager.switch_to_prev_farm()
	else:
		FarmManager.switch_to_next_farm()


func _handle_tap(screen_pos: Vector2) -> void:
	var origin := camera.project_ray_origin(screen_pos)
	var dir    := camera.project_ray_normal(screen_pos)
	if abs(dir.y) < 0.001:
		return
	var t        := (0.1 - origin.y) / dir.y
	var world    := origin + dir * t
	var col      := int((world.x + 1.75) / 0.7)
	var row      := int((world.z + 1.75) / 0.7)
	if col < 0 or col >= 5 or row < 0 or row >= 5:
		return
	EventBus.tile_tapped.emit(col, row, Vector3(
		-1.75 + col * 0.7 + 0.35, 0.0, -1.75 + row * 0.7 + 0.35
	))


func _pan(screen_pos: Vector2) -> void:
	var delta := screen_pos - _drag_start
	var right := camera.global_basis.x
	var fwd   := Vector3(-right.z, 0.0, right.x).normalized()
	var scale := camera.size / get_viewport().get_visible_rect().size.y
	camera.position = _cam_start + (-right * delta.x + fwd * delta.y) * scale


# ── Farm switch ────────────────────────────────────────────────────────────────

func _on_farm_changed(farm_id: String) -> void:
	_exit_placing_mode()
	_clear_farm()
	var placed := SaveSystem.get_placed_animals(farm_id)
	_restore_placed_animals(placed)
	_spawn_island()
	_update_fantasy_particles()


func _clear_farm() -> void:
	GoldenAnimalManager.force_cleanup()
	for tween in _bob_tweens.values():
		if tween:
			tween.kill()
	_bob_tweens.clear()
	_animal_at_tile.clear()
	for child in animals_root.get_children():
		child.queue_free()
	tile_layer.clear_all()
	_clear_tile_selection()


func _spawn_island() -> void:
	if _current_island and is_instance_valid(_current_island):
		_current_island.queue_free()
		_current_island = null
	var farm_data: FarmData = FarmManager.get_active_farm()
	if not farm_data or farm_data.island_scene.is_empty():
		return
	var scene = load(farm_data.island_scene)
	if not scene:
		return
	_current_island          = scene.instantiate()
	_current_island.name     = "FarmIsland"
	_current_island.scale    = Vector3.ONE
	_current_island.position = Vector3(0.1, -4.0, 0.0)
	add_child(_current_island)
	move_child(_current_island, 0)


# ── Fantasy particles ──────────────────────────────────────────────────────────

func _update_fantasy_particles() -> void:
	if _fantasy_tween:
		_fantasy_tween.kill()
		_fantasy_tween = null
	if _fantasy_orbit and is_instance_valid(_fantasy_orbit):
		_fantasy_orbit.queue_free()
		_fantasy_orbit = null

	var farm_data: FarmData = FarmManager.get_active_farm()
	if not farm_data or farm_data.theme != "fantasy":
		return

	_fantasy_orbit          = Node3D.new()
	_fantasy_orbit.position = Vector3(0.0, 1.5, 0.0)
	add_child(_fantasy_orbit)

	var colors := [
		Color(0.7, 0.3, 1.0, 0.9),
		Color(1.0, 0.8, 0.2, 0.9),
		Color(0.5, 0.2, 1.0, 0.8),
		Color(0.9, 0.5, 1.0, 0.9),
		Color(1.0, 0.6, 0.3, 0.8),
	]
	for i in 5:
		var lbl           := Label3D.new()
		lbl.text          = "✦"
		lbl.font_size     = 52
		lbl.modulate      = colors[i]
		lbl.billboard     = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = true
		var angle         := i * TAU / 5.0
		lbl.position      = Vector3(cos(angle) * 2.2, sin(i * 0.7) * 0.4, sin(angle) * 2.2)
		_fantasy_orbit.add_child(lbl)

	_fantasy_tween = create_tween().set_loops()
	_fantasy_tween.tween_property(_fantasy_orbit, "rotation:y", TAU, 10.0) \
		.set_trans(Tween.TRANS_LINEAR)


# ── Placing mode ───────────────────────────────────────────────────────────────

func _enter_placing_mode(animal_dict: Dictionary) -> void:
	var animal: AnimalData = AnimalRegistry.get_animal(animal_dict.get("name", ""))
	if not animal:
		return
	_placing_mode    = true
	_selected_animal = animal
	placing_ui.open(animal)
	placing_ui.visible = true
	_spawn_ghost(animal)


func _exit_placing_mode() -> void:
	if not _placing_mode:
		return
	_placing_mode    = false
	_selected_animal = null
	placing_ui.visible = false
	if _ghost:
		_ghost.queue_free()
		_ghost = null
	_clear_tile_selection()
	EventBus.placing_mode_exited.emit()


func _on_animal_selected(animal: AnimalData) -> void:
	_selected_animal = animal
	if _ghost:
		_ghost.queue_free()
	_spawn_ghost(animal)
	if _selected_tile_col >= 0:
		_place_on_selected_tile()


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


func _restore_placed_animals(placed: Array) -> void:
	for entry in placed:
		var col:  int    = entry.get("col", -1)
		var row:  int    = entry.get("row", -1)
		var type: String = entry.get("type", "")
		if col < 0 or row < 0 or type.is_empty():
			continue
		var animal: AnimalData = AnimalRegistry.get_animal(type)
		if not animal:
			continue
		if not tile_layer.is_tile_free(col, row):
			continue
		tile_layer.occupy_tile(col, row)
		var tile_pos := Vector3(-1.75 + col * 0.7 + 0.35, 0.0, -1.75 + row * 0.7 + 0.35)
		var node := _spawn_animal(tile_pos, animal, false)
		_animal_at_tile["%d,%d" % [col, row]] = node


func _spawn_animal(tile_pos: Vector3, animal: AnimalData, animate: bool = true) -> Node3D:
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
	node.position = tile_pos + Vector3(0.20, 0.25, 0.12)
	node.rotation_degrees.y = animal.spawn_rotation
	node.set_meta("animal_data", animal)
	node.set_meta("base_y", node.position.y)
	animals_root.add_child(node)
	EventBus.animal_placed.emit(node)
	if animate:
		_anim_spawn(node, animal.scale)
	else:
		node.scale = Vector3.ONE * animal.scale
	_anim_bob(node)
	return node


func _anim_spawn(node: Node3D, target_scale: float = 1.0) -> void:
	node.scale = Vector3.ZERO
	var t := create_tween()
	t.tween_property(node, "scale", Vector3.ONE * target_scale, 0.30) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _anim_bob(node: Node3D) -> void:
	var base_y: float = node.get_meta("base_y", node.position.y)
	var t := create_tween().set_loops()
	t.tween_property(node, "position:y", base_y + 0.03, 1.1) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(node, "position:y", base_y - 0.03, 1.1) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_bob_tweens[node] = t


# ── Tile tap & selection ──────────────────────────────────────────────────────

func _on_tile_tapped(col: int, row: int, world_pos: Vector3) -> void:
	if not tile_layer.is_tile_free(col, row):
		var node := _animal_at_tile.get("%d,%d" % [col, row]) as Node3D
		if node and is_instance_valid(node):
			_anim_tap(node)
		else:
			tile_layer.shake_tile(col, row)
		return
	_selected_tile_col = col
	_selected_tile_row = row
	_selected_tile_pos = world_pos
	tile_layer.select_tile(col, row)
	EventBus.tile_selected.emit(col, row, world_pos)
	if not _placing_mode:
		EventBus.placing_mode_entered.emit({"name": "chicken"})


func _place_on_selected_tile() -> void:
	if not tile_layer.is_tile_free(_selected_tile_col, _selected_tile_row):
		tile_layer.shake_tile(_selected_tile_col, _selected_tile_row)
		_clear_tile_selection()
		return
	if not GameState.remove_from_inventory(_selected_animal.id):
		return
	tile_layer.occupy_tile(_selected_tile_col, _selected_tile_row)
	var placed_node := _spawn_animal(_selected_tile_pos, _selected_animal)
	_animal_at_tile["%d,%d" % [_selected_tile_col, _selected_tile_row]] = placed_node
	SaveSystem.register_placed_animal(_selected_tile_col, _selected_tile_row, _selected_animal.id)
	_clear_tile_selection()


func _clear_tile_selection() -> void:
	if _selected_tile_col < 0:
		return
	_selected_tile_col = -1
	_selected_tile_row = -1
	tile_layer.deselect_tile()
	EventBus.tile_deselected.emit()


func _anim_tap(node: Node3D) -> void:
	if node.get_meta("tap_cooldown", false) or node.get_meta("is_golden", false):
		return
	node.set_meta("tap_cooldown", true)

	var animal: AnimalData = node.get_meta("animal_data", null)
	var base_scale: float  = animal.scale if animal else 1.0
	var base_y: float      = node.get_meta("base_y", node.position.y)
	var s                  := Vector3.ONE * base_scale

	var bob: Tween = _bob_tweens.get(node)
	if bob:
		bob.kill()
		_bob_tweens.erase(node)

	var t := node.create_tween()
	t.tween_property(node, "scale", Vector3(s.x * 1.2, s.y * 0.7, s.z * 1.2), 0.08) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(node, "position:y", base_y, 0.08)
	t.tween_property(node, "scale", Vector3(s.x * 0.85, s.y * 1.3, s.z * 0.85), 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(node, "position:y", base_y + 0.12, 0.12)
	t.tween_property(node, "scale", s, 0.10) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(node, "position:y", base_y, 0.10)
	t.tween_callback(func():
		node.set_meta("tap_cooldown", false)
		_anim_bob(node)
	)

	FXManager.spawn_tap_burst(node.global_position)
	EventBus.animal_tapped.emit(node)


# ── HUD refresh on load ───────────────────────────────────────────────────────

func _refresh_hud_on_load() -> void:
	EventBus.coins_changed.emit(GameState.coins)
	EventBus.coins_per_second_changed.emit(AnimalProductionManager.coins_per_second)
	EventBus.shards_changed.emit(GameState.spirit_shards)


# ── Coin popup for active farm ────────────────────────────────────────────────

func _on_coin_produced(farm_id: String, col: int, row: int, amount: int) -> void:
	if farm_id != FarmManager.active_farm_id:
		return
	var node := _animal_at_tile.get("%d,%d" % [col, row]) as Node3D
	if node and is_instance_valid(node):
		FXManager.spawn_coin_popup(node.global_position, amount)


# ── Tab handler ────────────────────────────────────────────────────────────────

func _on_tab_changed(tab: String) -> void:
	match tab:
		"build":
			if not _placing_mode:
				EventBus.placing_mode_entered.emit({"name": "chicken"})
		_:
			if _placing_mode:
				_exit_placing_mode()
