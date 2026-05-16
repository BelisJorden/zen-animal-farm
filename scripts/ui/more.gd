extends Control

const RED      := Color(0.82, 0.18, 0.18)
const RED_DARK := Color(0.62, 0.10, 0.10)
const DARK     := Color(0.22, 0.16, 0.32)
const WHITE    := Color(1.00, 1.00, 1.00)

var _confirm_overlay: Control = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg_scene := load("res://scenes/ui/components/Background.tscn") as PackedScene
	if bg_scene:
		add_child(bg_scene.instantiate())

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	root_vbox.add_child(_build_header())

	var content := _build_content()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(content)


func _build_header() -> PanelContainer:
	var header := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0.22)
	header.add_theme_stylebox_override("panel", s)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	header.add_child(row)

	var back_btn := Button.new()
	back_btn.text = "×"
	back_btn.flat = true
	back_btn.custom_minimum_size = Vector2(64, 56)
	back_btn.add_theme_font_size_override("font_size", 26)
	back_btn.add_theme_color_override("font_color", WHITE)
	back_btn.add_theme_color_override("font_hover_color", WHITE)
	back_btn.pressed.connect(queue_free)
	row.add_child(back_btn)

	var title := Label.new()
	title.text = "more"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", WHITE)
	row.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(64, 0)
	row.add_child(spacer)

	return header


func _build_content() -> ScrollContainer:
	var scroll := ScrollContainer.new()

	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left",   24)
	pad.add_theme_constant_override("margin_right",  24)
	pad.add_theme_constant_override("margin_top",    28)
	pad.add_theme_constant_override("margin_bottom", 40)
	scroll.add_child(pad)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	pad.add_child(vbox)

	# Push reset visually toward the bottom
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.55, 0.42, 0.72, 0.35))
	vbox.add_child(sep)

	var danger_lbl := Label.new()
	danger_lbl.text = "gevarenzone"
	danger_lbl.add_theme_font_size_override("font_size", 12)
	danger_lbl.add_theme_color_override("font_color", Color(RED.r, RED.g, RED.b, 0.60))
	vbox.add_child(danger_lbl)

	var reset_btn := Button.new()
	reset_btn.text = "reset progress"
	reset_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_btn.custom_minimum_size = Vector2(0, 56)
	reset_btn.add_theme_font_size_override("font_size", 17)
	reset_btn.add_theme_color_override("font_color",         RED)
	reset_btn.add_theme_color_override("font_hover_color",   RED)
	reset_btn.add_theme_color_override("font_pressed_color", RED)
	reset_btn.add_theme_stylebox_override("normal",  _make_sb(Color(1.0, 0.92, 0.92, 0.90), 14))
	reset_btn.add_theme_stylebox_override("hover",   _make_sb(Color(1.0, 0.85, 0.85, 0.95), 14))
	reset_btn.add_theme_stylebox_override("pressed", _make_sb(Color(0.95, 0.78, 0.78, 0.95), 14))
	reset_btn.pressed.connect(_show_confirm)
	vbox.add_child(reset_btn)

	return scroll


func _make_sb(color: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color                   = color
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	return s


func _show_confirm() -> void:
	if _confirm_overlay:
		return

	_confirm_overlay = Control.new()
	_confirm_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_confirm_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	_confirm_overlay.add_child(dim)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(290, 0)
	card.add_theme_stylebox_override("panel", _make_sb(Color(0.98, 0.97, 0.95), 22))
	_confirm_overlay.add_child(card)

	var outer_pad := MarginContainer.new()
	outer_pad.add_theme_constant_override("margin_left",   28)
	outer_pad.add_theme_constant_override("margin_right",  28)
	outer_pad.add_theme_constant_override("margin_top",    30)
	outer_pad.add_theme_constant_override("margin_bottom", 26)
	card.add_child(outer_pad)

	var inner_vbox := VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 16)
	outer_pad.add_child(inner_vbox)

	var title_lbl := Label.new()
	title_lbl.text = "reset progress?"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 21)
	title_lbl.add_theme_color_override("font_color", DARK)
	inner_vbox.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = "Al je dieren, coins en voortgang\ngaan definitief verloren."
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(DARK, 0.65))
	inner_vbox.add_child(desc_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	inner_vbox.add_child(btn_row)

	var cancel_btn := Button.new()
	cancel_btn.text = "annuleer"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.custom_minimum_size = Vector2(0, 52)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.add_theme_color_override("font_color", DARK)
	cancel_btn.add_theme_stylebox_override("normal",  _make_sb(Color(0.88, 0.86, 0.92), 14))
	cancel_btn.add_theme_stylebox_override("hover",   _make_sb(Color(0.81, 0.78, 0.87), 14))
	cancel_btn.add_theme_stylebox_override("pressed", _make_sb(Color(0.75, 0.72, 0.82), 14))
	cancel_btn.pressed.connect(func():
		_confirm_overlay.queue_free()
		_confirm_overlay = null
	)
	btn_row.add_child(cancel_btn)

	var reset_confirm_btn := Button.new()
	reset_confirm_btn.text = "reset"
	reset_confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_confirm_btn.custom_minimum_size = Vector2(0, 52)
	reset_confirm_btn.add_theme_font_size_override("font_size", 16)
	reset_confirm_btn.add_theme_color_override("font_color", WHITE)
	reset_confirm_btn.add_theme_stylebox_override("normal",  _make_sb(RED, 14))
	reset_confirm_btn.add_theme_stylebox_override("hover",   _make_sb(Color(0.90, 0.24, 0.24), 14))
	reset_confirm_btn.add_theme_stylebox_override("pressed", _make_sb(RED_DARK, 14))
	reset_confirm_btn.pressed.connect(_do_reset)
	btn_row.add_child(reset_confirm_btn)

	_confirm_overlay.modulate.a = 0.0
	create_tween().tween_property(_confirm_overlay, "modulate:a", 1.0, 0.18)


func _do_reset() -> void:
	DirAccess.remove_absolute(OS.get_user_data_dir() + "/zenfarm_save.cfg")
	GameState.reset_state()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
