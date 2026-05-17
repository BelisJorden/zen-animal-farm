extends Node

const GOLDEN_DURATION  := 15.0
const MIN_INTERVAL     := 5.0
const MAX_INTERVAL     := 15.0

const RARITY_WEIGHTS   := {"common": 9, "rare": 3, "mystic": 1}
const COIN_MULTIPLIERS := {"common": 50, "rare": 100, "mystic": 200}
const SHARD_CHANCES    := {"common": 0.10, "rare": 0.40, "mystic": 1.00}

var _placed_animals: Array[Node3D] = []
var _golden_animal:  Node3D        = null
var _golden_data                   = null   # AnimalData resource

var _active_golden_farm_id: String = ""
var _active_golden_col:     int    = -1
var _active_golden_row:     int    = -1
var _active_golden_type:    String = ""

var _spawn_timer:    Timer
var _golden_timer:   Timer
var _pulse_ring:     Node3D  = null
var _countdown_lbl:  Label3D = null
var _pulse_tween:    Tween   = null
var _input_area:     Area3D  = null
var _orig_mats:      Dictionary = {}
var _fx:             Node    = null


func _ready() -> void:
	_fx = get_node("/root/FXManager")
	EventBus.animal_placed.connect(_on_animal_placed)
	EventBus.animal_removed.connect(_on_animal_removed)

	_spawn_timer          = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.timeout.connect(_try_spawn)
	add_child(_spawn_timer)

	_golden_timer          = Timer.new()
	_golden_timer.one_shot = true
	_golden_timer.timeout.connect(_on_expired)
	add_child(_golden_timer)

	_start_spawn_timer()


# ── Public API ─────────────────────────────────────────────────────────────────

func is_active() -> bool:
	return _active_golden_farm_id != ""


func get_active_farm_id() -> String:
	return _active_golden_farm_id


func get_active_col() -> int:
	return _active_golden_col


func get_active_row() -> int:
	return _active_golden_row


# Called by farm.gd when it has the Node3D for the golden animal
func apply_visuals_to(node: Node3D) -> void:
	_golden_animal = node
	_apply_golden()
	EventBus.golden_animal_spawned.emit(_golden_animal, _active_golden_farm_id)


# ── Animal tracking ────────────────────────────────────────────────────────────

func _on_animal_placed(animal: Node) -> void:
	var a3d := animal as Node3D
	if a3d and a3d not in _placed_animals:
		_placed_animals.append(a3d)
	if not is_active() and _spawn_timer.is_stopped():
		_start_spawn_timer()


func _on_animal_removed(animal: Node) -> void:
	var a3d := animal as Node3D
	_placed_animals.erase(a3d)
	if _golden_animal == a3d:
		_cleanup()
		_start_spawn_timer()


func _start_spawn_timer() -> void:
	_spawn_timer.start(randf_range(MIN_INTERVAL, MAX_INTERVAL))


# ── Spawn logic ────────────────────────────────────────────────────────────────

func _try_spawn() -> void:
	if is_active():
		return
	var has_animals := false
	for farm_id in SaveSystem.placed_animals_per_farm:
		if not SaveSystem.placed_animals_per_farm[farm_id].is_empty():
			has_animals = true
			break
	if not has_animals:
		return
	_pick_and_spawn()


func _pick_and_spawn() -> void:
	# Build weighted list from ALL farms via SaveSystem data
	var weighted: Array = []
	for farm_id in SaveSystem.placed_animals_per_farm:
		for entry in SaveSystem.placed_animals_per_farm[farm_id]:
			var type: String = entry.get("type", "")
			if type.is_empty():
				continue
			var col: int = entry.get("col", -1)
			var row: int = entry.get("row", -1)
			if col < 0 or row < 0:
				continue
			var animal_data = AnimalRegistry.get_animal(type)
			var rarity: String = animal_data.rarity if animal_data else "common"
			var w: int = RARITY_WEIGHTS.get(rarity, 9)
			for _i in w:
				weighted.append({"farm_id": farm_id, "col": col, "row": row, "type": type})

	if weighted.is_empty():
		_start_spawn_timer()
		return

	var chosen: Dictionary = weighted[randi() % weighted.size()]
	_active_golden_farm_id = chosen["farm_id"]
	_active_golden_col     = chosen["col"]
	_active_golden_row     = chosen["row"]
	_active_golden_type    = chosen["type"]
	_golden_data           = AnimalRegistry.get_animal(_active_golden_type)

	_golden_timer.start(GOLDEN_DURATION)
	# Signal farm.gd (and farm_overview, hud) about golden spawn
	EventBus.golden_animal_spawned_on_farm.emit(_active_golden_farm_id)
	# farm.gd's _on_golden_animal_on_farm will call apply_visuals_to() if active farm matches


# ── Apply / remove golden visuals ─────────────────────────────────────────────

func _apply_golden() -> void:
	_golden_animal.set_meta("is_golden", true)
	_tint_meshes(_golden_animal)
	_spawn_ring()
	_spawn_countdown(ceili(_golden_timer.time_left))
	_start_pulse()
	_add_input_area()


func _clear_visual_only() -> void:
	# Removes 3D effects without stopping the timer or clearing session state
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	if is_instance_valid(_golden_animal):
		_golden_animal.set_meta("is_golden", false)
		_restore_meshes()
		var s: float = _golden_data.scale if _golden_data else 1.0
		_golden_animal.scale = Vector3.ONE * s
		if is_instance_valid(_countdown_lbl):
			_countdown_lbl.queue_free()
		if is_instance_valid(_pulse_ring):
			_pulse_ring.queue_free()
		if is_instance_valid(_input_area):
			_input_area.queue_free()
	_countdown_lbl = null
	_pulse_ring    = null
	_input_area    = null
	_golden_animal = null
	_orig_mats.clear()


func _cleanup() -> void:
	_golden_timer.stop()
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	if is_instance_valid(_golden_animal):
		_golden_animal.set_meta("is_golden", false)
		_restore_meshes()
		var s: float = _golden_data.scale if _golden_data else 1.0
		_golden_animal.scale = Vector3.ONE * s
		if is_instance_valid(_countdown_lbl):
			_countdown_lbl.queue_free()
		if is_instance_valid(_pulse_ring):
			_pulse_ring.queue_free()
		if is_instance_valid(_input_area):
			_input_area.queue_free()
	_countdown_lbl         = null
	_pulse_ring            = null
	_input_area            = null
	_golden_animal         = null
	_golden_data           = null
	_orig_mats.clear()
	_active_golden_farm_id = ""
	_active_golden_col     = -1
	_active_golden_row     = -1
	_active_golden_type    = ""


# ── Mesh tinting ───────────────────────────────────────────────────────────────

func _tint_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		_orig_mats[mi] = mi.material_override
		var mat                        := StandardMaterial3D.new()
		mat.albedo_color                = Color(1.0, 0.85, 0.20)
		mat.metallic                    = 0.6
		mat.roughness                   = 0.3
		mat.emission_enabled            = true
		mat.emission                    = Color(1.0, 0.70, 0.10)
		mat.emission_energy_multiplier  = 0.4
		mi.material_override            = mat
	for child in node.get_children():
		_tint_meshes(child)


func _restore_meshes() -> void:
	for key in _orig_mats.keys():
		if not is_instance_valid(key):
			continue
		var mi := key as MeshInstance3D
		if mi:
			mi.material_override = _orig_mats[key]
	_orig_mats.clear()


# ── Visual effects ─────────────────────────────────────────────────────────────

func _spawn_ring() -> void:
	var ring := Node3D.new()
	ring.name     = "GoldenRing"
	ring.position = Vector3(0, 0.05, 0)
	_golden_animal.add_child(ring)
	_pulse_ring = ring

	var angles := [0.0, 90.0, 180.0, 270.0]
	for angle in angles:
		var lbl           := Label3D.new()
		lbl.text           = "✦"
		lbl.billboard      = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test  = true
		lbl.modulate       = Color(1.0, 0.85, 0.20, 0.90)
		lbl.font_size      = 28
		lbl.pixel_size     = 0.01
		var rad            := deg_to_rad(angle)
		lbl.position       = Vector3(cos(rad) * 0.5, 0.0, sin(rad) * 0.5)
		ring.add_child(lbl)

	var t := ring.create_tween().set_loops()
	t.tween_property(ring, "scale", Vector3.ONE * 1.35, 0.65) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(ring, "scale", Vector3.ONE * 0.85, 0.65) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)


func _spawn_countdown(start_secs: int = int(GOLDEN_DURATION)) -> void:
	_countdown_lbl                  = Label3D.new()
	_countdown_lbl.billboard        = BaseMaterial3D.BILLBOARD_ENABLED
	_countdown_lbl.no_depth_test    = true
	_countdown_lbl.modulate         = Color(1.0, 0.85, 0.20, 1.0)
	_countdown_lbl.font_size        = 52
	_countdown_lbl.outline_size     = 7
	_countdown_lbl.outline_modulate = Color(0.30, 0.20, 0.0, 1.0)
	_countdown_lbl.pixel_size       = 0.01
	_countdown_lbl.double_sided     = true
	_countdown_lbl.position         = Vector3(0, 1.2, 0)
	_golden_animal.add_child(_countdown_lbl)
	_tick_countdown(start_secs)


func _tick_countdown(remaining: int) -> void:
	if _golden_animal == null or not is_instance_valid(_countdown_lbl):
		return
	_countdown_lbl.text = "✦ %d" % remaining
	if remaining > 0:
		var t := create_tween()
		t.tween_interval(1.0)
		t.tween_callback(_tick_countdown.bind(remaining - 1))


func _start_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	var base: Vector3 = Vector3.ONE * (_golden_data.scale if _golden_data else 1.0)
	_pulse_tween = _golden_animal.create_tween().set_loops()
	_pulse_tween.tween_property(_golden_animal, "scale", base * 1.08, 0.5) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(_golden_animal, "scale", base, 0.5) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _add_input_area() -> void:
	_input_area                    = Area3D.new()
	_input_area.input_ray_pickable = true
	var cs    := CollisionShape3D.new()
	var box   := BoxShape3D.new()
	box.size   = Vector3(0.8, 1.2, 0.8)
	cs.shape   = box
	cs.position = Vector3(0, 0.4, 0)
	_input_area.add_child(cs)
	_golden_animal.add_child(_input_area)
	_input_area.input_event.connect(func(_cam, ev: InputEvent, _pos, _n, _s):
		if not is_instance_valid(_input_area):
			return
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			_input_area.get_viewport().set_input_as_handled()
			_collect()
		elif ev is InputEventScreenTouch and ev.pressed:
			_input_area.get_viewport().set_input_as_handled()
			_collect()
	)


# ── Collection & timeout ───────────────────────────────────────────────────────

func _collect() -> void:
	if not _golden_animal:
		return
	var node          := _golden_animal
	node.set_meta("tap_cooldown", true)
	var rarity:       String = _golden_data.rarity if _golden_data else "common"
	var base_coins:   int    = _golden_data.coin_amount if _golden_data else 1
	var coins_reward: int    = COIN_MULTIPLIERS.get(rarity, 50) * base_coins
	var shards_reward: int   = 1 if randf() < SHARD_CHANCES.get(rarity, 0.10) else 0
	GameState.add_coins(coins_reward)
	if shards_reward > 0:
		GameState.add_spirit_shards(shards_reward)
	if _fx:
		_fx.spawn_coin_burst(node.global_position, coins_reward)
	EventBus.golden_animal_collected.emit(coins_reward, shards_reward)
	_cleanup()
	_start_spawn_timer()
	get_tree().create_timer(0.5).timeout.connect(func():
		if is_instance_valid(node):
			node.set_meta("tap_cooldown", false)
	, CONNECT_ONE_SHOT)


func on_farm_leaving() -> void:
	# Called by farm.gd when leaving the active farm view; preserves golden session state
	_placed_animals.clear()
	_spawn_timer.stop()
	if _golden_animal != null:
		_clear_visual_only()


func force_cleanup() -> void:
	if is_active():
		EventBus.golden_animal_expired.emit()
		_cleanup()
	_placed_animals.clear()
	_spawn_timer.stop()


func _on_expired() -> void:
	EventBus.golden_animal_expired.emit()
	_cleanup()
	_start_spawn_timer()


func get_golden_time_remaining() -> float:
	return _golden_timer.time_left if not _golden_timer.is_stopped() else 0.0
