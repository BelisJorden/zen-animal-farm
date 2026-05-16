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

var _onboarding: Control = null
var _name_input: LineEdit = null
var _start_btn:  Button  = null


func _ready() -> void:
	_setup_3d()
	_style_buttons()
	_build_onboarding()
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


# --- Onboarding overlay ---

func _build_onboarding() -> void:
	_onboarding = Control.new()
	_onboarding.set_anchors_preset(Control.PRESET_FULL_RECT)
	_onboarding.visible = false
	add_child(_onboarding)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	_onboarding.add_child(dim)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(300, 0)
	var card_s := StyleBoxFlat.new()
	card_s.bg_color                   = Color(0.98, 0.97, 0.95)
	card_s.corner_radius_top_left     = 22
	card_s.corner_radius_top_right    = 22
	card_s.corner_radius_bottom_left  = 22
	card_s.corner_radius_bottom_right = 22
	card_s.content_margin_left        = 28
	card_s.content_margin_right       = 28
	card_s.content_margin_top         = 32
	card_s.content_margin_bottom      = 28
	card.add_theme_stylebox_override("panel", card_s)
	_onboarding.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	card.add_child(vbox)

	var title := Label.new()
	title.text = "wat is je naam?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", COLOR_LILA_DARK)
	vbox.add_child(title)

	_name_input = LineEdit.new()
	_name_input.placeholder_text = "naam..."
	_name_input.max_length = 12
	_name_input.custom_minimum_size = Vector2(0, 52)
	_name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_input.add_theme_font_size_override("font_size", 20)
	_name_input.add_theme_color_override("font_color", Color(0.22, 0.16, 0.32))
	_name_input.add_theme_color_override("caret_color", Color(0.58, 0.44, 0.78))
	var input_s := _rounded_box(COLOR_WHITE, 14)
	_name_input.add_theme_stylebox_override("normal", input_s)
	_name_input.add_theme_stylebox_override("focus",  _rounded_box(Color(0.92, 0.88, 0.98), 14))
	_name_input.text_changed.connect(_on_name_changed)
	vbox.add_child(_name_input)

	_start_btn = Button.new()
	_start_btn.text = "start"
	_start_btn.disabled = true
	_start_btn.custom_minimum_size = Vector2(0, 56)
	_start_btn.add_theme_font_size_override("font_size", 20)
	_primary_style(_start_btn)
	_start_btn.pressed.connect(_on_start_pressed)
	vbox.add_child(_start_btn)


func _on_name_changed(new_text: String) -> void:
	_start_btn.disabled = new_text.strip_edges().is_empty()


func _show_onboarding() -> void:
	_onboarding.visible = true
	_onboarding.modulate.a = 0.0
	create_tween().tween_property(_onboarding, "modulate:a", 1.0, 0.22)
	_name_input.grab_focus()


func _on_start_pressed() -> void:
	var name_val := _name_input.text.strip_edges()
	if name_val.is_empty():
		return
	GameState.player_name = name_val
	SaveSystem.save_game()
	get_tree().change_scene_to_file("res://scenes/world/FarmScreen.tscn")


# --- Button handlers ---

func _on_begin() -> void:
	_squish(begin_btn)
	await get_tree().create_timer(0.15).timeout
	if SaveSystem.load_game():
		get_tree().change_scene_to_file("res://scenes/world/FarmScreen.tscn")
	else:
		_show_onboarding()


func _on_settings() -> void:
	_squish(settings_btn)


func _on_credits() -> void:
	_squish(credits_btn)
