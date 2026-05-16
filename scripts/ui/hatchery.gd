extends Control

const AnimalData = preload("res://scripts/resources/animal_data.gd")

const LILA       := Color(0.58, 0.44, 0.78)
const LILA_LIGHT := Color(0.70, 0.58, 0.86)
const LILA_DARK  := Color(0.47, 0.35, 0.65)
const DARK       := Color(0.22, 0.16, 0.32)

const EGG_COLOR_COMMON := Color(0.95, 0.93, 0.88)
const EGG_COLOR_RARE   := Color(0.6,  0.4,  0.9)
const EGG_COLOR_MYSTIC := Color(1.0,  0.75, 0.1)

const MAX_TAPS   := 5

const COST_COMMON := 3
const COST_RARE   := 8
const COST_MYSTIC := 20

const RARITY_COLORS := {
	"common": Color(0.533, 0.529, 0.502),
	"rare":   Color(0.482, 0.369, 0.655),
	"mystic": Color(0.941, 0.627, 0.188),
}

var _taps   := 0
var _rarity := "rare"
var _dot_filled:  StyleBoxFlat
var _dot_empty:   StyleBoxFlat
var _pill_active: StyleBoxFlat
var _pill_idle:   StyleBoxFlat
var _egg_style:       StyleBoxFlat
var _mystic_sparkle:  Control
var _sparkle_tween:   Tween
var _egg_color_tween: Tween

@onready var egg_pivot:    Control       = $MainLayout/EggSection/EggCenter/EggPivot
@onready var egg_panel:    Panel         = $MainLayout/EggSection/EggCenter/EggPivot/EggPanel
@onready var status_label: Label         = $MainLayout/EggSection/StatusLabel
@onready var dots_row:     HBoxContainer = $MainLayout/EggSection/DotsCenter/DotsRow
@onready var common_btn:   Button        = $MainLayout/RarityRow/CommonBtn
@onready var rare_btn:     Button        = $MainLayout/RarityRow/RareBtn
@onready var mystic_btn:   Button        = $MainLayout/RarityRow/MysticBtn
@onready var tap_btn:      Button        = $MainLayout/BottomSection/TapBtn
@onready var shard_label:  Label         = $MainLayout/HeaderBar/ShardCounter/ShardLabel


func _ready() -> void:
	_build_styles()
	_egg_style = StyleBoxFlat.new()
	_egg_style.corner_radius_top_left     = 70
	_egg_style.corner_radius_top_right    = 70
	_egg_style.corner_radius_bottom_left  = 56
	_egg_style.corner_radius_bottom_right = 56
	_egg_style.shadow_color  = Color(0.22, 0.16, 0.32, 0.13)
	_egg_style.shadow_size   = 12
	_egg_style.shadow_offset = Vector2(0, 5)
	egg_panel.add_theme_stylebox_override("panel", _egg_style)
	_update_dots()
	_update_rarity_buttons()
	_update_tap_btn_label()
	_update_egg_color(false)
	_refresh_shards(GameState.spirit_shards)
	SaveSystem.save_game()
	egg_pivot.pivot_offset = egg_pivot.custom_minimum_size / 2.0
	tap_btn.pressed.connect(_on_tap_pressed)
	$MainLayout/HeaderBar/BackBtn.pressed.connect(_on_back_pressed)
	common_btn.pressed.connect(func(): _select_rarity("common"))
	rare_btn.pressed.connect(func():   _select_rarity("rare"))
	mystic_btn.pressed.connect(func(): _select_rarity("mystic"))
	EventBus.shards_changed.connect(_refresh_shards)


# ── Styles ────────────────────────────────────────────────────────────────────

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


# ── UI updates ────────────────────────────────────────────────────────────────

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
	_update_tap_btn_label()
	_update_egg_color()


func _refresh_shards(amount: int) -> void:
	shard_label.text = "✦ %d" % amount


func _update_egg_color(animated: bool = true) -> void:
	var target: Color
	match _rarity:
		"rare":   target = EGG_COLOR_RARE
		"mystic": target = EGG_COLOR_MYSTIC
		_:        target = EGG_COLOR_COMMON
	if _egg_color_tween:
		_egg_color_tween.kill()
	if animated:
		_egg_color_tween = create_tween()
		var from := _egg_style.bg_color
		_egg_color_tween.tween_method(
			func(c: Color): _egg_style.bg_color = c,
			from, target, 0.3
		)
	else:
		_egg_style.bg_color = target
	_update_mystic_sparkle()


func _update_mystic_sparkle() -> void:
	if _rarity == "mystic":
		if _mystic_sparkle == null:
			_spawn_mystic_sparkle()
	else:
		if _mystic_sparkle != null:
			_mystic_sparkle.queue_free()
			_mystic_sparkle = null
		if _sparkle_tween:
			_sparkle_tween.kill()
			_sparkle_tween = null


func _spawn_mystic_sparkle() -> void:
	var orbit := Control.new()
	orbit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	orbit.position = Vector2(65, 95)  # center of EggPivot (130×190)
	orbit.size = Vector2.ZERO
	egg_pivot.add_child(orbit)
	_mystic_sparkle = orbit

	for i in 4:
		var lbl := Label.new()
		lbl.text = "✦"
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var angle := i * TAU / 4.0
		lbl.position = Vector2(cos(angle) * 72.0 - 8.0, sin(angle) * 72.0 - 8.0)
		orbit.add_child(lbl)

	_sparkle_tween = create_tween().set_loops()
	_sparkle_tween.tween_property(orbit, "rotation", TAU, 4.0) \
		.set_trans(Tween.TRANS_LINEAR)


func _update_tap_btn_label() -> void:
	tap_btn.text = "tap to crack  ✦ %d" % _shard_cost()


# ── Tap handler ───────────────────────────────────────────────────────────────

func _on_tap_pressed() -> void:
	if _taps >= MAX_TAPS:
		return
	if _taps == 0:
		if not GameState.spend_shards(_shard_cost()):
			_show_not_enough()
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


func _shard_cost() -> int:
	match _rarity:
		"rare":   return COST_RARE
		"mystic": return COST_MYSTIC
		_:        return COST_COMMON


# ── Animations ────────────────────────────────────────────────────────────────

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
	t.tween_callback(_hatch)


func _reset_egg() -> void:
	_taps             = 0
	status_label.text = "almost there..."
	egg_pivot.scale   = Vector2.ONE
	tap_btn.disabled  = false
	_update_dots()


# ── Gacha ─────────────────────────────────────────────────────────────────────

func _roll_rarity() -> String:
	var roll := randf()
	match _rarity:
		"mystic":
			return "mystic"
		"rare":
			return "mystic" if roll < 0.20 else "rare"
		_:
			if roll < 0.05:
				return "mystic"
			elif roll < 0.30:
				return "rare"
			return "common"


func _pick_animal(rarity: String) -> String:
	var pool := AnimalRegistry.get_all().filter(func(a): return a.rarity == rarity)
	if pool.is_empty():
		pool = AnimalRegistry.get_all().filter(func(a): return a.rarity == "common")
	if pool.is_empty():
		return "chicken"
	return pool[randi() % pool.size()].id


func _hatch() -> void:
	var rolled_rarity := _roll_rarity()
	var animal_id     := _pick_animal(rolled_rarity)
	GameState.add_to_inventory({"name": animal_id})
	EventBus.animal_hatched.emit(animal_id, rolled_rarity)
	_show_reveal(animal_id, rolled_rarity)


# ── Reveal overlay ────────────────────────────────────────────────────────────

func _show_reveal(animal_id: String, rarity: String) -> void:
	var animal: AnimalData = AnimalRegistry.get_animal(animal_id)

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.55)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	if animal and animal.image_path != "":
		var tex := TextureRect.new()
		tex.texture      = load(animal.image_path)
		tex.custom_minimum_size = Vector2(120, 120)
		tex.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(tex)

	var name_lbl := Label.new()
	name_lbl.text = animal.display_name if animal else animal_id
	name_lbl.add_theme_font_size_override("font_size", 36)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var badge := PanelContainer.new()
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bs := StyleBoxFlat.new()
	bs.bg_color                   = RARITY_COLORS.get(rarity, Color(0.55, 0.55, 0.55))
	bs.corner_radius_top_left     = 10
	bs.corner_radius_top_right    = 10
	bs.corner_radius_bottom_left  = 10
	bs.corner_radius_bottom_right = 10
	bs.content_margin_left        = 14
	bs.content_margin_right       = 14
	bs.content_margin_top         = 5
	bs.content_margin_bottom      = 5
	badge.add_theme_stylebox_override("panel", bs)
	var rarity_lbl := Label.new()
	rarity_lbl.text = rarity
	rarity_lbl.add_theme_font_size_override("font_size", 15)
	rarity_lbl.add_theme_color_override("font_color", Color.WHITE)
	badge.add_child(rarity_lbl)
	vbox.add_child(badge)

	overlay.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(overlay, "modulate:a", 1.0, 0.30)
	t.tween_interval(2.5)
	t.tween_property(overlay, "modulate:a", 0.0, 0.30)
	t.tween_callback(func():
		overlay.queue_free()
		_reset_egg()
	)


func _show_not_enough() -> void:
	var lbl := Label.new()
	lbl.text = "niet genoeg ✦"
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.22))
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(lbl)
	lbl.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(lbl, "modulate:a", 1.0, 0.20)
	t.tween_interval(1.0)
	t.tween_property(lbl, "modulate:a", 0.0, 0.30)
	t.tween_callback(lbl.queue_free)


# ── Navigation ────────────────────────────────────────────────────────────────

func _on_back_pressed() -> void:
	queue_free()
