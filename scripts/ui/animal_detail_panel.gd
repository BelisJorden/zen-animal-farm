extends Control

signal action_pressed(animal_id: String, context: String)

const AnimalData = preload("res://scripts/resources/animal_data.gd")

const LILA  := Color(0.58, 0.44, 0.78)
const DARK  := Color(0.22, 0.16, 0.32)
const SHEET_H := 330.0

const RARITY_COLORS := {
	"common": Color(0.533, 0.529, 0.502),
	"rare":   Color(0.482, 0.369, 0.655),
	"mystic": Color(0.941, 0.627, 0.188),
}

var _animal_id:   String = ""
var _context:     String = ""
var _backdrop:    ColorRect
var _sheet:       PanelContainer
var _preview:     Panel
var _name_lbl:    Label
var _badge_style: StyleBoxFlat
var _rarity_lbl:  Label
var _stats_lbl:   Label
var _ctx_lbl:     Label
var _action_btn:  Button


func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_backdrop()
	_build_sheet()


# ── Construction ───────────────────────────────────────────────────────────────

func _build_backdrop() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0.45)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = MOUSE_FILTER_STOP
	add_child(_backdrop)


func _build_sheet() -> void:
	_sheet = PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color                   = Color(0.99, 0.98, 0.97)
	s.corner_radius_top_left     = 24
	s.corner_radius_top_right    = 24
	s.content_margin_left        = 24
	s.content_margin_right       = 24
	s.content_margin_top         = 14
	s.content_margin_bottom      = 28
	_sheet.add_theme_stylebox_override("panel", s)
	_sheet.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_sheet.offset_top    = -(SHEET_H + 100)
	_sheet.offset_bottom = -100.0
	add_child(_sheet)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	_sheet.add_child(vbox)

	_add_handle(vbox)
	_add_top_row(vbox)

	_ctx_lbl = Label.new()
	_ctx_lbl.add_theme_font_size_override("font_size", 15)
	_ctx_lbl.add_theme_color_override("font_color", Color(0.40, 0.36, 0.50))
	vbox.add_child(_ctx_lbl)

	_add_action_row(vbox)


func _add_handle(parent: Control) -> void:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(0, 18)
	var bar := ColorRect.new()
	bar.color = Color(0.82, 0.80, 0.84)
	bar.custom_minimum_size = Vector2(40, 4)
	bar.set_anchors_preset(Control.PRESET_CENTER)
	wrap.add_child(bar)
	parent.add_child(wrap)


func _add_top_row(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	parent.add_child(row)

	# Preview panel
	_preview = Panel.new()
	_preview.custom_minimum_size = Vector2(108, 108)
	_preview.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_preview.size_flags_vertical   = Control.SIZE_SHRINK_BEGIN
	var ps := StyleBoxFlat.new()
	ps.bg_color                   = Color(0.95, 0.93, 0.90)
	ps.corner_radius_top_left     = 14
	ps.corner_radius_top_right    = 14
	ps.corner_radius_bottom_left  = 14
	ps.corner_radius_bottom_right = 14
	_preview.add_theme_stylebox_override("panel", ps)
	row.add_child(_preview)

	# Info column
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	row.add_child(col)

	_name_lbl = Label.new()
	_name_lbl.add_theme_font_size_override("font_size", 26)
	_name_lbl.add_theme_color_override("font_color", DARK)
	col.add_child(_name_lbl)

	# Rarity badge
	var badge := PanelContainer.new()
	badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_badge_style = StyleBoxFlat.new()
	_badge_style.corner_radius_top_left     = 8
	_badge_style.corner_radius_top_right    = 8
	_badge_style.corner_radius_bottom_left  = 8
	_badge_style.corner_radius_bottom_right = 8
	_badge_style.content_margin_left        = 10
	_badge_style.content_margin_right       = 10
	_badge_style.content_margin_top         = 3
	_badge_style.content_margin_bottom      = 3
	badge.add_theme_stylebox_override("panel", _badge_style)
	_rarity_lbl = Label.new()
	_rarity_lbl.add_theme_font_size_override("font_size", 12)
	_rarity_lbl.add_theme_color_override("font_color", Color.WHITE)
	badge.add_child(_rarity_lbl)
	col.add_child(badge)

	_stats_lbl = Label.new()
	_stats_lbl.add_theme_font_size_override("font_size", 14)
	_stats_lbl.add_theme_color_override("font_color", Color(0.40, 0.36, 0.50))
	_stats_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_stats_lbl)


func _add_action_row(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var close_btn := Button.new()
	close_btn.text = "sluiten"
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cs := _pill_style(Color(0.91, 0.89, 0.94))
	for state in ["normal", "hover", "pressed", "focus"]:
		close_btn.add_theme_stylebox_override(state, cs)
	close_btn.add_theme_color_override("font_color", DARK)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(close)
	row.add_child(close_btn)

	_action_btn = Button.new()
	_action_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var as_ := _pill_style(LILA)
	var as_dis := _pill_style(Color(0.72, 0.70, 0.76))
	for state in ["normal", "hover", "pressed", "focus"]:
		_action_btn.add_theme_stylebox_override(state, as_)
	_action_btn.add_theme_stylebox_override("disabled", as_dis)
	_action_btn.add_theme_color_override("font_color", Color.WHITE)
	_action_btn.add_theme_color_override("font_color_disabled", Color(0.88, 0.86, 0.92))
	_action_btn.add_theme_font_size_override("font_size", 16)
	_action_btn.pressed.connect(func(): action_pressed.emit(_animal_id, _context))
	row.add_child(_action_btn)


func _pill_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color                   = color
	s.corner_radius_top_left     = 14
	s.corner_radius_top_right    = 14
	s.corner_radius_bottom_left  = 14
	s.corner_radius_bottom_right = 14
	s.content_margin_top         = 14
	s.content_margin_bottom      = 14
	return s


# ── Public API ─────────────────────────────────────────────────────────────────

func show_panel(animal_id: String, context: String) -> void:
	_animal_id = animal_id
	_context   = context
	var animal: AnimalData = AnimalRegistry.get_animal(animal_id)
	if not animal:
		return
	_populate(animal)
	if visible:
		return
	visible = true
	mouse_filter       = MOUSE_FILTER_STOP
	_sheet.offset_top  = -100.0
	_backdrop.modulate.a = 0.0
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_sheet, "offset_top", -(SHEET_H + 100), 0.22)
	t.parallel().tween_property(_backdrop, "modulate:a", 0.45, 0.22)


func close() -> void:
	if not visible:
		return
	mouse_filter = MOUSE_FILTER_IGNORE
	var t := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_sheet, "offset_top", -100.0, 0.18)
	t.parallel().tween_property(_backdrop, "modulate:a", 0.0, 0.18)
	t.tween_callback(func(): visible = false)


# ── Populate ───────────────────────────────────────────────────────────────────

func _populate(animal: AnimalData) -> void:
	_name_lbl.text = animal.display_name

	_rarity_lbl.text      = animal.rarity
	_badge_style.bg_color = RARITY_COLORS.get(animal.rarity, Color(0.55, 0.55, 0.55))

	var cps: float = float(animal.coin_amount) / float(animal.coin_rate)
	var rate_str: String
	if int(animal.coin_rate) == animal.coin_rate:
		rate_str = str(int(animal.coin_rate))
	else:
		rate_str = "%.1f" % animal.coin_rate
	_stats_lbl.text = "+%d elke %s sec  ·  %.2f/sec" % [animal.coin_amount, rate_str, cps]

	for child in _preview.get_children():
		child.queue_free()
	if animal.image_path != "":
		var tex := TextureRect.new()
		tex.texture      = load(animal.image_path)
		tex.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_preview.add_child(tex)
	else:
		var col := ColorRect.new()
		col.color = animal.color
		col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_preview.add_child(col)

	match _context:
		"shop":
			_ctx_lbl.text        = "prijs:  ◎ %d" % animal.price
			_action_btn.text     = "◎ %d  kopen" % animal.price
			_action_btn.disabled = GameState.coins < animal.price
		"placing":
			var count := 0
			for entry in GameState.unplaced_animals:
				if entry["type"] == animal.id:
					count += 1
			_ctx_lbl.text        = "beschikbaar:  ×%d" % count
			_action_btn.text     = "plaatsen"
			_action_btn.disabled = count == 0
