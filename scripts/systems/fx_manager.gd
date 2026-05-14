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
