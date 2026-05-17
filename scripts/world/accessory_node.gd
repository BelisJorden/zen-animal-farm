extends Node3D

var _tween: Tween


func setup(acc: AccessoryData) -> void:
	position = Vector3(0.0, 0.8, 0.0)

	if acc.model_path != "":
		var res = load(acc.model_path)
		if res is Mesh:
			var mi := MeshInstance3D.new()
			mi.mesh = res
			mi.scale = Vector3.ONE * 0.4
			add_child(mi)
		elif res is PackedScene:
			var node: Node3D = res.instantiate()
			node.scale = Vector3.ONE * 0.4
			add_child(node)
	else:
		_make_orb(acc)

	_start_rotate()


func _make_orb(acc: AccessoryData) -> void:
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	mi.mesh = sphere
	var mat := StandardMaterial3D.new()
	match acc.rarity:
		"mystic":
			mat.albedo_color               = Color(0.58, 0.44, 0.78)
			mat.emission_enabled           = true
			mat.emission                   = Color(0.40, 0.20, 0.60)
			mat.emission_energy_multiplier = 0.6
		"rare":
			mat.albedo_color = Color(1.0, 0.82, 0.20)
			mat.metallic     = 0.7
			mat.roughness    = 0.2
		_:
			mat.albedo_color = Color(0.80, 0.80, 0.85)
	mi.material_override = mat
	add_child(mi)

	var lbl := Label3D.new()
	lbl.text           = "✦"
	lbl.billboard      = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test  = true
	lbl.modulate       = Color(1.0, 0.85, 0.20, 0.85)
	lbl.font_size      = 20
	lbl.pixel_size     = 0.01
	lbl.position       = Vector3(0, 0.22, 0)
	add_child(lbl)


func _start_rotate() -> void:
	_tween = create_tween().set_loops()
	_tween.tween_property(self, "rotation:y", TAU, 4.0).set_trans(Tween.TRANS_LINEAR)
