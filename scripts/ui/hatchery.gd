extends Control

const LILA       := Color(0.58, 0.44, 0.78)
const LILA_LIGHT := Color(0.70, 0.58, 0.86)
const LILA_DARK  := Color(0.47, 0.35, 0.65)
const DARK       := Color(0.22, 0.16, 0.32)
const MAX_TAPS   := 5

var _taps   := 0
var _rarity := "rare"
var _dot_filled:  StyleBoxFlat
var _dot_empty:   StyleBoxFlat
var _pill_active: StyleBoxFlat
var _pill_idle:   StyleBoxFlat

@onready var egg_pivot:    Control      = $MainLayout/EggSection/EggCenter/EggPivot
@onready var status_label: Label        = $MainLayout/EggSection/StatusLabel
@onready var dots_row:     HBoxContainer = $MainLayout/EggSection/DotsCenter/DotsRow
@onready var common_btn:   Button       = $MainLayout/RarityRow/CommonBtn
@onready var rare_btn:     Button       = $MainLayout/RarityRow/RareBtn
@onready var mystic_btn:   Button       = $MainLayout/RarityRow/MysticBtn
@onready var tap_btn:      Button       = $MainLayout/BottomSection/TapBtn


func _ready() -> void:
	_build_styles()
	_update_dots()
	_update_rarity_buttons()
	egg_pivot.pivot_offset = egg_pivot.custom_minimum_size / 2.0
	tap_btn.pressed.connect(_on_tap_pressed)
	$MainLayout/HeaderBar/BackBtn.pressed.connect(_on_back_pressed)
	common_btn.pressed.connect(func(): _select_rarity("common"))
	rare_btn.pressed.connect(func():   _select_rarity("rare"))
	mystic_btn.pressed.connect(func(): _select_rarity("mystic"))


func _build_styles() -> void:
	_dot_filled  = _make_sb(LILA,                   8)
	_dot_empty   = _make_sb(Color(1, 1, 1, 0.35),   8)
	_pill_active = _make_sb(LILA,                   22)
	_pill_idle   = _make_sb(Color(1, 1, 1, 0.28),   22)

	var tap_n := _make_sb(LILA,       18)
	var tap_h := _make_sb(LILA_LIGHT, 18)
	var tap_p := _make_sb(LILA_DARK,  18)
	var tap_d := _make_sb(Color(0.58, 0.44, 0.78, 0.45), 18)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb: StyleBoxFlat
		match state:
			"normal":   sb = tap_n
			"hover":    sb = tap_h
			"disabled": sb = tap_d
			_:          sb = tap_p
		tap_btn.add_theme_stylebox_override(state, sb)


func _make_sb(color: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = color
	sb.corner_radius_top_left     = radius
	sb.corner_radius_top_right    = radius
	sb.corner_radius_bottom_left  = radius
	sb.corner_radius_bottom_right = radius
	return sb


func _update_dots() -> void:
	var i := 0
	for dot in dots_row.get_children():
		dot.add_theme_stylebox_override("panel", _dot_filled if i < _taps else _dot_empty)
		i += 1


func _update_rarity_buttons() -> void:
	for btn: Button in [common_btn, rare_btn, mystic_btn]:
		var rarity := btn.name.to_lower().replace("btn", "")
		var active  := rarity == _rarity
		var pill    := _pill_active if active else _pill_idle
		for state in ["normal", "hover", "pressed", "focus"]:
			btn.add_theme_stylebox_override(state, pill)
		btn.add_theme_color_override("font_color", Color.WHITE if active else DARK)


func _select_rarity(rarity: String) -> void:
	_rarity = rarity
	_update_rarity_buttons()


func _on_tap_pressed() -> void:
	if _taps >= MAX_TAPS:
		return
	_taps += 1
	_update_dots()
	_anim_shake()
	if _taps >= MAX_TAPS:
		_anim_crack()
	elif _taps == MAX_TAPS - 1:
		status_label.text = "one more tap!"
	else:
		status_label.text = "almost there..."


func _anim_shake() -> void:
	var ox := egg_pivot.position.x
	var t  := create_tween()
	t.tween_property(egg_pivot, "position:x", ox + 11.0, 0.05)
	t.tween_property(egg_pivot, "position:x", ox - 11.0, 0.06)
	t.tween_property(egg_pivot, "position:x", ox +  5.0, 0.04)
	t.tween_property(egg_pivot, "position:x", ox,        0.05)


func _anim_crack() -> void:
	status_label.text = "it hatched!"
	tap_btn.disabled  = true
	var t := create_tween()
	t.tween_property(egg_pivot, "scale", Vector2(1.25, 1.25), 0.18) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(egg_pivot, "scale", Vector2.ZERO, 0.22) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	t.tween_callback(_reset_egg)


func _reset_egg() -> void:
	_taps             = 0
	status_label.text = "almost there..."
	egg_pivot.scale   = Vector2.ONE
	tap_btn.disabled  = false
	_update_dots()


func _on_back_pressed() -> void:
	queue_free()
