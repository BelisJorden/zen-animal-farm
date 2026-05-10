extends Control

signal animal_selection_changed(data: Dictionary)
signal cancelled

const CARD_W := 82
const CARD_H := 82
const LILA   := Color(0.58, 0.44, 0.78)

const DEMO_ANIMALS: Array[Dictionary] = [
	{"name": "chicken", "color": Color(0.95, 0.90, 0.70), "scene": "res://assets/models/animals/chicken.obj", "scale": 0.5, "coin_rate": 5.0},
	{"name": "fox",    "color": Color(0.85, 0.45, 0.15)},
	{"name": "crane",  "color": Color(0.92, 0.92, 0.92)},
	{"name": "tanuki", "color": Color(0.52, 0.38, 0.24)},
	{"name": "cat",    "color": Color(0.70, 0.65, 0.60)},
	{"name": "deer",   "color": Color(0.80, 0.60, 0.42)},
]

@onready var title_label:   Label          = $TopBar/TitleLabel
@onready var cancel_btn:    Button         = $TopBar/CancelBtn
@onready var animals_label: Label          = $BottomPanel/Content/SubheaderRow/AnimalsLabel
@onready var card_row:      HBoxContainer  = $BottomPanel/Content/AnimalScroll/AnimalCardRow
@onready var bottom_panel:  PanelContainer = $BottomPanel
@onready var filter_btn:    Button         = $BottomPanel/Content/SubheaderRow/FilterBtn

var _active_card: PanelContainer = null
var _active_name: String = ""


func _ready() -> void:
	cancel_btn.pressed.connect(func(): cancelled.emit())
	_style_ui()
	EventBus.inventory_changed.connect(_on_inventory_changed)


func open(animal_data: Dictionary) -> void:
	_active_name     = animal_data.get("name", "")
	title_label.text = "placing · " + _active_name
	_build_cards(_active_name)


# ── Styling ────────────────────────────────────────────────────────────────────

func _style_ui() -> void:
	var empty := StyleBoxEmpty.new()
	cancel_btn.add_theme_stylebox_override("normal",  empty)
	cancel_btn.add_theme_stylebox_override("hover",   empty)
	cancel_btn.add_theme_stylebox_override("pressed", empty)
	cancel_btn.add_theme_color_override("font_color",       Color(0.80, 0.20, 0.20))
	cancel_btn.add_theme_color_override("font_color_hover", Color(1.0, 0.30, 0.30))

	var panel_s := StyleBoxFlat.new()
	panel_s.bg_color              = Color(0.99, 0.98, 0.96, 0.97)
	panel_s.corner_radius_top_left  = 22
	panel_s.corner_radius_top_right = 22
	panel_s.content_margin_left   = 20
	panel_s.content_margin_right  = 20
	panel_s.content_margin_top    = 18
	panel_s.content_margin_bottom = 18
	bottom_panel.add_theme_stylebox_override("panel", panel_s)

	var filter_s := StyleBoxFlat.new()
	filter_s.bg_color                     = Color(1, 1, 1, 0.0)
	filter_s.corner_radius_top_left       = 12
	filter_s.corner_radius_top_right      = 12
	filter_s.corner_radius_bottom_left    = 12
	filter_s.corner_radius_bottom_right   = 12
	filter_s.border_color                 = Color(0.72, 0.68, 0.76)
	filter_s.border_width_left            = 1
	filter_s.border_width_right           = 1
	filter_s.border_width_top             = 1
	filter_s.border_width_bottom          = 1
	filter_s.content_margin_left          = 12
	filter_s.content_margin_right         = 12
	filter_s.content_margin_top           = 4
	filter_s.content_margin_bottom        = 4
	filter_btn.add_theme_stylebox_override("normal", filter_s)
	filter_btn.add_theme_stylebox_override("hover",  filter_s.duplicate())
	filter_btn.add_theme_color_override("font_color", Color(0.42, 0.36, 0.52))


# ── Animal cards ───────────────────────────────────────────────────────────────

func _build_cards(active_name: String) -> void:
	for child in card_row.get_children():
		child.queue_free()
	_active_card = null

	var counts: Dictionary = {}
	for entry in GameState.unplaced_animals:
		var t: String = entry["type"]
		counts[t] = counts.get(t, 0) + 1

	for type_name in GameState.purchased_animal_types:
		var data: Dictionary = _find_animal_data(type_name)
		if data.is_empty():
			continue
		var count: int = counts.get(type_name, 0)
		var selected: bool = type_name == active_name and count > 0
		var card := _make_card(data, selected, count)
		card_row.add_child(card)
		if selected:
			_active_card = card

	animals_label.text = "your animals · %d unplaced" % GameState.unplaced_animals.size()


func _find_animal_data(type_name: String) -> Dictionary:
	for d in DEMO_ANIMALS:
		if d["name"] == type_name:
			return d
	return {}


func _make_card(data: Dictionary, selected: bool, count: int) -> PanelContainer:
	var available: bool = count > 0

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(CARD_W + 12, CARD_H + 34)
	panel.mouse_filter        = Control.MOUSE_FILTER_STOP
	_apply_card_style(panel, selected)

	var vbox := VBoxContainer.new()
	vbox.alignment    = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var preview := ColorRect.new()
	preview.custom_minimum_size = Vector2(CARD_W - 2, CARD_H - 2)
	var col: Color               = data["color"]
	col.a                        = 1.0 if available else 0.30
	preview.color                = col
	preview.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(preview)

	var lbl := Label.new()
	lbl.text                 = data["name"]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.85 if available else 0.35))
	vbox.add_child(lbl)

	var count_lbl := Label.new()
	count_lbl.text                 = "×%d" % count
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	count_lbl.add_theme_font_size_override("font_size", 11)
	count_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9 if available else 0.35))
	vbox.add_child(count_lbl)

	if available:
		panel.gui_input.connect(func(e: InputEvent) -> void:
			if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) \
			or (e is InputEventScreenTouch and e.pressed):
				_select_card(data, panel)
		)
	return panel


func _apply_card_style(panel: PanelContainer, selected: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color                    = Color(0.22, 0.18, 0.28)
	s.corner_radius_top_left      = 10
	s.corner_radius_top_right     = 10
	s.corner_radius_bottom_left   = 10
	s.corner_radius_bottom_right  = 10
	s.content_margin_left         = 6
	s.content_margin_right        = 6
	s.content_margin_top          = 6
	s.content_margin_bottom       = 6
	if selected:
		s.border_color        = LILA
		s.border_width_left   = 3
		s.border_width_right  = 3
		s.border_width_top    = 3
		s.border_width_bottom = 3
	panel.add_theme_stylebox_override("panel", s)


func _on_inventory_changed() -> void:
	_build_cards(_active_name)


func _select_card(data: Dictionary, panel: PanelContainer) -> void:
	_active_name     = data["name"]
	title_label.text = "placing · " + _active_name
	if _active_card:
		_apply_card_style(_active_card, false)
	_active_card = panel
	_apply_card_style(panel, true)
	animal_selection_changed.emit(data)
