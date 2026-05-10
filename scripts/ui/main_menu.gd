extends Control

const COLOR_WHITE     := Color(1.00, 1.00, 1.00)
const COLOR_LILA_DARK := Color(0.42, 0.28, 0.65)

@onready var background:    ColorRect          = $Background
@onready var animal_holder: Node3D             = $MarginContainer/VBoxContainer/AnimalContainer/AnimalViewport/AnimalHolder
@onready var cam:           Camera3D           = $MarginContainer/VBoxContainer/AnimalContainer/AnimalViewport/Camera3D
@onready var light:         DirectionalLight3D = $MarginContainer/VBoxContainer/AnimalContainer/AnimalViewport/DirectionalLight3D
@onready var begin_btn:     Button             = $MarginContainer/VBoxContainer/ButtonsContainer/BeginButton
@onready var settings_btn:  Button             = $MarginContainer/VBoxContainer/ButtonsContainer/SettingsButton
@onready var credits_btn:   Button             = $MarginContainer/VBoxContainer/ButtonsContainer/CreditsButton


func _ready() -> void:
	_setup_3d()
	_style_buttons()
	begin_btn.pressed.connect(_on_begin)
	settings_btn.pressed.connect(_on_settings)
	credits_btn.pressed.connect(_on_credits)
	_entrance_fade()
	_bob_loop()


# --- Background ---

func set_gradient(top_color: Color, bottom_color: Color) -> void:
	var mat := background.material as ShaderMaterial
	mat.set_shader_parameter("color_top",    top_color)
	mat.set_shader_parameter("color_bottom", bottom_color)


# --- 3D preview ---

func _setup_3d() -> void:
	cam.position = Vector3(4.0, 4.0, 4.0)
	cam.look_at(Vector3.ZERO, Vector3.UP)
	light.rotation_degrees = Vector3(-50, 30, 0)

	var island_mat := StandardMaterial3D.new()
	island_mat.albedo_color = Color(0.42, 0.72, 0.35)
	animal_holder.get_node("Island").material_override = island_mat

	var animal_mat := StandardMaterial3D.new()
	animal_mat.albedo_color = Color(0.94, 0.74, 0.52)
	animal_holder.get_node("AnimalPlaceholder").material_override = animal_mat


# --- Button styling ---

func _style_buttons() -> void:
	_primary_style(begin_btn)
	_secondary_style(settings_btn)
	_secondary_style(credits_btn)


func _primary_style(btn: Button) -> void:
	var s := _rounded_box(COLOR_LILA_DARK, 32)
	var h := _rounded_box(Color(0.50, 0.36, 0.72), 32)
	var p := _rounded_box(Color(0.34, 0.21, 0.56), 32)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color", COLOR_WHITE)


func _secondary_style(btn: Button) -> void:
	var s := _rounded_box(Color(1, 1, 1, 0.18), 28)
	var h := _rounded_box(Color(1, 1, 1, 0.30), 28)
	var p := _rounded_box(Color(1, 1, 1, 0.10), 28)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color", COLOR_WHITE)


func _rounded_box(color: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	return s


# --- Animations ---

func _entrance_fade() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)


func _bob_loop() -> void:
	var t := create_tween().set_loops()
	t.tween_property(animal_holder, "position:y",  0.08, 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(animal_holder, "position:y", -0.08, 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _squish(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	var t := create_tween()
	t.tween_property(btn, "scale", Vector2(1.1, 0.9),  0.07).set_ease(Tween.EASE_OUT)
	t.tween_property(btn, "scale", Vector2.ONE,         0.14).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)


# --- Button handlers ---

func _on_begin() -> void:
	_squish(begin_btn)
	# get_tree().change_scene_to_file("res://scenes/world/Farm.tscn")


func _on_settings() -> void:
	_squish(settings_btn)


func _on_credits() -> void:
	_squish(credits_btn)
