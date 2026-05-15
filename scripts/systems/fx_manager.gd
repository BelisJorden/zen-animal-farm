extends Node

var _fx_root: Node3D = null


func set_fx_root(root: Node3D) -> void:
	_fx_root = root


func spawn_coin_popup(world_pos: Vector3, amount: int) -> void:
	if not _fx_root:
		return
	var label := Label3D.new()
	label.text             = "+%d" % amount
	label.billboard        = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test    = true
	label.modulate         = Color(0.94, 0.63, 0.19, 1.0)
	label.font_size        = 45
	label.outline_size     = 6
	label.outline_modulate = Color(0.15, 0.08, 0.0, 1.0)
	label.pixel_size       = 0.01
	label.double_sided     = true
	label.top_level        = true
	label.position         = world_pos
	_fx_root.add_child(label)

	var t := label.create_tween()
	t.tween_property(label, "position:y", world_pos.y + 0.6, 0.8)
	t.parallel().tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.4)
	t.tween_callback(label.queue_free)


func spawn_coin_burst(world_pos: Vector3, amount: int) -> void:
	if not _fx_root:
		return
	var label              := Label3D.new()
	label.text              = "+%d ◎" % amount
	label.billboard         = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test     = true
	label.modulate          = Color(1.0, 0.85, 0.10, 1.0)
	label.font_size         = 72
	label.outline_size      = 9
	label.outline_modulate  = Color(0.30, 0.20, 0.0, 1.0)
	label.pixel_size        = 0.01
	label.double_sided      = true
	label.top_level         = true
	label.position          = world_pos + Vector3(0, 0.3, 0)
	_fx_root.add_child(label)
	var t := label.create_tween()
	t.tween_property(label, "position:y", world_pos.y + 1.5, 1.4)
	t.parallel().tween_property(label, "scale", Vector3(1.4, 1.4, 1.4), 0.25)
	t.parallel().tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.9)
	t.tween_callback(label.queue_free)

	var offsets := [Vector3(0.6, 0.2, 0.0), Vector3(-0.6, 0.15, 0.0), Vector3(0.0, 0.1, 0.6)]
	for off: Vector3 in offsets:
		var star              := Label3D.new()
		star.text              = "✦"
		star.billboard         = BaseMaterial3D.BILLBOARD_ENABLED
		star.no_depth_test     = true
		star.modulate          = Color(1.0, 0.85, 0.10, 0.9)
		star.font_size         = 40
		star.pixel_size        = 0.01
		star.double_sided      = true
		star.top_level         = true
		star.position          = world_pos
		_fx_root.add_child(star)
		var st := star.create_tween()
		st.tween_property(star, "position", world_pos + off, 0.9).set_ease(Tween.EASE_OUT)
		st.parallel().tween_property(star, "modulate:a", 0.0, 0.45).set_delay(0.45)
		st.tween_callback(star.queue_free)
