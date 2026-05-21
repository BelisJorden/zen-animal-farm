extends Control

signal action_pressed(animal_id: String, context: String)

const AnimalData = preload("res://scripts/resources/animal_data.gd")
var selected_farm_id: String = ""

const LILA  := Color(0.58, 0.44, 0.78)
const DARK  := Color(0.22, 0.16, 0.32)
const SHEET_H_BASE := 330.0
const SHEET_H_FARM := 460.0

const RARITY_COLORS := {
	"common": Color(0.533, 0.529, 0.502),
	"rare":   Color(0.482, 0.369, 0.655),
	"mystic": Color(0.941, 0.627, 0.188),
}

var _animal_id:   String = ""
var _context:     String = ""
var _col:         int    = -1
var _row:         int    = -1
var _backdrop:    ColorRect
var _sheet:       PanelContainer
var _preview:     Panel
var _name_lbl:    Label
var _badge_style: StyleBoxFlat
var _rarity_lbl:  Label
var _stats_lbl:   Label
var _ctx_lbl:     Label
var _action_btn:  Button
var _acc_section:   VBoxContainer = null
var _acc_btns:      Array[Button] = []
var _hint_lbl:      Label  = null
var _hint_tween:    Tween  = null
var _tile_selected: bool   = false
var _block_close:   bool   = false


func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_backdrop()
	_build_sheet()
	EventBus.accessory_equipped.connect(func(_f: String, _c: int, _r: int, _a: String) -> void:
		if visible: _refresh_stats())
	EventBus.accessory_unequipped.connect(func(_f: String, _c: int, _r: int) -> void:
		if visible: _refresh_stats())
	EventBus.tab_changed.connect(func(tab: String) -> void:
		if tab == "farm" and visible and _context == "placing":
			close())
	EventBus.tile_selected.connect(func(_c: int, _r: int, _p: Vector3) -> void:
		_tile_selected = true)
	EventBus.tile_deselected.connect(func() -> void:
		_tile_selected = false)


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
	_sheet.offset_top    = -(SHEET_H_FARM + 100)
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

	_add_accessory_section(vbox)
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

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	row.add_child(col)

	_name_lbl = Label.new()
	_name_lbl.add_theme_font_size_override("font_size", 26)
	_name_lbl.add_theme_color_override("font_color", DARK)
	col.add_child(_name_lbl)

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


func _add_accessory_section(parent: Control) -> void:
	_acc_section = VBoxContainer.new()
	_acc_section.add_theme_constant_override("separation", 8)
	_acc_section.visible = false
	parent.add_child(_acc_section)

	var sep := ColorRect.new()
	sep.color = Color(0.85, 0.83, 0.88)
	sep.custom_minimum_size = Vector2(0, 1)
	_acc_section.add_child(sep)

	var header := Label.new()
	header.text = "accessoire"
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", Color(0.50, 0.45, 0.60))
	_acc_section.add_child(header)

	# Buttons added dynamically in _populate_accessory_section()


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
	var as_: StyleBoxFlat = _pill_style(LILA)
	var as_dis := _pill_style(Color(0.72, 0.70, 0.76))
	for state in ["normal", "hover", "pressed", "focus"]:
		_action_btn.add_theme_stylebox_override(state, as_)
	_action_btn.add_theme_stylebox_override("disabled", as_dis)
	_action_btn.add_theme_color_override("font_color", Color.WHITE)
	_action_btn.add_theme_color_override("font_color_disabled", Color(0.88, 0.86, 0.92))
	_action_btn.add_theme_font_size_override("font_size", 16)
	_action_btn.pressed.connect(func():
		if _context == "placing" and not _tile_selected:
			_show_place_hint()
			return
		action_pressed.emit(_animal_id, _context)
	)
	row.add_child(_action_btn)

	_hint_lbl = Label.new()
	_hint_lbl.text                    = "Select a tile on the farm first"
	_hint_lbl.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_font_size_override("font_size", 11)
	_hint_lbl.add_theme_color_override("font_color", Color(0.9, 0.4, 0.2))
	_hint_lbl.modulate.a              = 0.0
	parent.add_child(_hint_lbl)


func _show_place_hint() -> void:
	if _hint_tween:
		_hint_tween.kill()
	_hint_lbl.modulate.a = 1.0
	_hint_tween = create_tween()
	_hint_tween.tween_interval(2.0)
	_hint_tween.tween_property(_hint_lbl, "modulate:a", 0.0, 0.5)


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

func show_panel(animal_id: String, context: String, col: int = -1, row: int = -1) -> void:
	_animal_id       = animal_id
	_context         = context
	_col             = col
	_row             = row
	selected_farm_id = FarmManager.active_farm_id
	var animal: AnimalData = AnimalRegistry.get_animal(animal_id)
	if not animal:
		return
	_populate(animal)
	_refresh_stats()
	var h := SHEET_H_FARM if context == "farm" else SHEET_H_BASE
	_sheet.offset_top  = -(h + 100)
	_sheet.offset_bottom = -100.0
	if visible:
		return
	visible = true
	_block_close = true
	get_tree().create_timer(0.20).timeout.connect(func(): _block_close = false)
	if _context == "placing":
		mouse_filter             = MOUSE_FILTER_IGNORE
		_backdrop.mouse_filter   = MOUSE_FILTER_PASS
		_backdrop.modulate.a     = 0.0
	else:
		mouse_filter             = MOUSE_FILTER_STOP
		_backdrop.mouse_filter   = MOUSE_FILTER_STOP
		_backdrop.modulate.a     = 0.0
	_sheet.offset_top = -100.0
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_sheet, "offset_top", -(h + 100), 0.22)
	t.parallel().tween_property(_backdrop, "modulate:a", 0.45 if _context != "placing" else 0.0, 0.22)


func close() -> void:
	if _block_close or not visible:
		return
	mouse_filter = MOUSE_FILTER_IGNORE
	var t := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_sheet, "offset_top", -100.0, 0.18)
	t.parallel().tween_property(_backdrop, "modulate:a", 0.0, 0.18)
	t.tween_callback(func(): visible = false)


# ── Stats refresh ──────────────────────────────────────────────────────────────

func _refresh_stats() -> void:
	var animal: AnimalData = AnimalRegistry.get_animal(_animal_id)
	if not animal:
		return
	var base_amount: int = animal.coin_amount
	if _context == "farm" and _col >= 0 and _row >= 0:
		var acc_id := GameState.get_accessory(selected_farm_id, _col, _row)
		if acc_id != "":
			var acc = AccessoryRegistry.get_accessory(acc_id)
			if acc and acc.coin_bonus_percent > 0.0:
				base_amount = int(base_amount * (1.0 + acc.coin_bonus_percent))
	var cps: float = float(base_amount) / float(animal.coin_rate)
	_stats_lbl.text = "+%d elke %.0f sec  ·  %.2f/sec" % [base_amount, animal.coin_rate, cps]


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
		var col_rect := ColorRect.new()
		col_rect.color = animal.color
		col_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_preview.add_child(col_rect)

	match _context:
		"shop":
			_ctx_lbl.text        = "prijs:  ◎ %d" % animal.price
			_action_btn.text     = "◎ %d  kopen" % animal.price
			_action_btn.disabled = GameState.coins < animal.price
			_action_btn.visible  = true
			_acc_section.visible = false
		"placing":
			var count := 0
			for entry in GameState.unplaced_animals:
				if entry["type"] == animal.id:
					count += 1
			_ctx_lbl.text        = "beschikbaar:  ×%d" % count
			_action_btn.text     = "plaatsen"
			_action_btn.disabled = count == 0
			_action_btn.visible  = true
			_acc_section.visible = false
		"farm":
			_ctx_lbl.text        = ""
			_action_btn.visible  = false
			_acc_section.visible = true
			_populate_accessory_section()


func _populate_accessory_section() -> void:
	# Remove old dynamic buttons (keep first 2 children: sep + header)
	_acc_btns.clear()
	var children := _acc_section.get_children()
	for i in range(children.size() - 1, 1, -1):
		children[i].queue_free()

	var current_acc_id := GameState.get_accessory(selected_farm_id, _col, _row)

	# Current status label
	var status_lbl := Label.new()
	if current_acc_id != "":
		var acc: AccessoryData = AccessoryRegistry.get_accessory(current_acc_id)
		status_lbl.text = "op: %s" % (acc.name if acc else current_acc_id)
		status_lbl.add_theme_color_override("font_color", LILA)
	else:
		status_lbl.text = "geen accessoire"
		status_lbl.add_theme_color_override("font_color", Color(0.55, 0.52, 0.60))
	status_lbl.add_theme_font_size_override("font_size", 14)
	_acc_section.add_child(status_lbl)

	if GameState.owned_accessories.is_empty():
		var hint := Label.new()
		hint.text = "koop accessoires in de shop"
		hint.add_theme_font_size_override("font_size", 12)
		hint.add_theme_color_override("font_color", Color(0.60, 0.56, 0.65))
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_acc_section.add_child(hint)
		return

	# Row of owned accessory buttons
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	_acc_section.add_child(btn_row)

	# "Geen" button (remove accessory)
	if current_acc_id != "":
		var remove_btn := Button.new()
		remove_btn.text = "verwijder"
		remove_btn.add_theme_font_size_override("font_size", 12)
		var rs := _acc_btn_style(Color(0.91, 0.89, 0.94), false)
		for state in ["normal", "hover", "pressed", "focus"]:
			remove_btn.add_theme_stylebox_override(state, rs)
		remove_btn.add_theme_color_override("font_color", Color(0.55, 0.52, 0.60))
		remove_btn.pressed.connect(_on_unequip)
		btn_row.add_child(remove_btn)
		_acc_btns.append(remove_btn)

	for acc_id in GameState.owned_accessories:
		var acc: AccessoryData = AccessoryRegistry.get_accessory(acc_id)
		if not acc:
			continue
		var active := acc_id == current_acc_id
		var btn := Button.new()
		btn.text = acc.name
		btn.add_theme_font_size_override("font_size", 12)
		var bs := _acc_btn_style(LILA if active else Color(0.91, 0.89, 0.94), active)
		for state in ["normal", "hover", "pressed", "focus"]:
			btn.add_theme_stylebox_override(state, bs)
		var txt_col := Color.WHITE if active else DARK
		btn.add_theme_color_override("font_color", txt_col)
		var cap_id := acc_id
		btn.pressed.connect(func(): _on_equip(cap_id))
		btn_row.add_child(btn)
		_acc_btns.append(btn)


func _acc_btn_style(color: Color, active: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color                   = color
	s.corner_radius_top_left     = 10
	s.corner_radius_top_right    = 10
	s.corner_radius_bottom_left  = 10
	s.corner_radius_bottom_right = 10
	s.content_margin_left        = 10
	s.content_margin_right       = 10
	s.content_margin_top         = 8
	s.content_margin_bottom      = 8
	if active:
		s.border_width_left   = 2
		s.border_width_right  = 2
		s.border_width_top    = 2
		s.border_width_bottom = 2
		s.border_color        = Color(0.42, 0.31, 0.60)
	return s


func _on_equip(acc_id: String) -> void:
	if _col < 0 or _row < 0:
		return
	GameState.equip_accessory(selected_farm_id, _col, _row, acc_id)
	SaveSystem.save_game()
	_populate_accessory_section()


func _on_unequip() -> void:
	if _col < 0 or _row < 0:
		return
	GameState.unequip_accessory(selected_farm_id, _col, _row)
	SaveSystem.save_game()
	_populate_accessory_section()
