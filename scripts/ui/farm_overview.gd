extends Control

const COLOR_LILA      := Color(0.58, 0.44, 0.78)
const COLOR_LILA_DARK := Color(0.42, 0.28, 0.65)
const COLOR_TEXT_DARK := Color(0.22, 0.16, 0.32)
const COLOR_TEXT_DIM  := Color(0.22, 0.16, 0.32, 0.55)
const COLOR_GREEN     := Color(0.22, 0.60, 0.35)
const COLOR_GREEN_H   := Color(0.28, 0.68, 0.42)
const COLOR_GREEN_P   := Color(0.18, 0.50, 0.30)

const OUTER_MARGIN := 16.0
const CARD_GAP     := 16.0

const CARD_COLORS: Dictionary = {
	"zen":     [Color(0.60, 0.78, 0.44), Color(0.38, 0.60, 0.26)],
	"fantasy": [Color(0.20, 0.10, 0.42), Color(0.36, 0.10, 0.58)],
}
const CARD_ICONS: Dictionary = {
	"zen":     "🌿",
	"fantasy": "✨",
}

var _cards:         Dictionary = {}  # farm_id -> Control (wrapper)
var _grid:          GridContainer   = null
var _confirm_panel: Control         = null
var _pending_farm:  FarmData        = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	EventBus.farm_unlocked.connect(_on_farm_unlocked)
	EventBus.coins_changed.connect(_on_coins_changed)


# ── Full-screen layout ────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader = load("res://assets/shaders/gradient_background.gdshader")
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("color_top",         Color(0.76, 0.68, 0.88))
		mat.set_shader_parameter("color_mid",         Color(0.82, 0.72, 0.85))
		mat.set_shader_parameter("color_bottom",      Color(0.94, 0.84, 0.78))
		mat.set_shader_parameter("vignette_strength", 0.0)
		bg.material = mat
	else:
		bg.color = Color(0.82, 0.72, 0.85)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	root.add_child(_build_header())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left",   int(OUTER_MARGIN))
	margin.add_theme_constant_override("margin_right",  int(OUTER_MARGIN))
	margin.add_theme_constant_override("margin_top",    int(OUTER_MARGIN))
	margin.add_theme_constant_override("margin_bottom", int(OUTER_MARGIN))
	scroll.add_child(margin)

	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", int(CARD_GAP))
	_grid.add_theme_constant_override("v_separation", int(CARD_GAP))
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(_grid)

	for farm in FarmManager.farms:
		var card := _build_card(farm)
		_cards[farm.id] = card
		_grid.add_child(card)


func _build_header() -> Control:
	var panel := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color               = Color(1, 1, 1, 0.18)
	s.content_margin_left    = 16
	s.content_margin_right   = 16
	s.content_margin_top     = 52
	s.content_margin_bottom  = 14
	panel.add_theme_stylebox_override("panel", s)

	var hbox := HBoxContainer.new()
	panel.add_child(hbox)

	var back := Button.new()
	back.text = "← back"
	back.flat = true
	back.add_theme_font_size_override("font_size", 15)
	back.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	back.custom_minimum_size = Vector2(80, 0)
	back.pressed.connect(queue_free)
	hbox.add_child(back)

	var title := Label.new()
	title.text = "your farms"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(spacer)

	return panel


# ── Card building ─────────────────────────────────────────────────────────────

func _get_card_size() -> float:
	var vp_w := get_viewport_rect().size.x
	if vp_w < 100.0:
		vp_w = 650.0
	return floor((vp_w - OUTER_MARGIN * 2.0 - CARD_GAP) / 2.0)


func _build_card(farm: FarmData) -> Control:
	var unlocked := FarmManager.is_unlocked(farm.id)
	var active   := FarmManager.active_farm_id == farm.id
	var cs       := _get_card_size()

	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(cs, cs)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Background panel
	var colors: Array = CARD_COLORS.get(farm.theme, [Color(0.5, 0.5, 0.5), Color(0.35, 0.35, 0.35)])
	var bg_col := (colors[0] as Color).lerp(colors[1] as Color, 0.45)
	var bg_style := _make_card_style(bg_col)
	var bg_panel := PanelContainer.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	wrapper.add_child(bg_panel)

	# Content
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	bg_panel.add_child(content)

	var top_space := Control.new()
	top_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(top_space)

	var icon_lbl := Label.new()
	icon_lbl.text = CARD_ICONS.get(farm.theme, "🏡")
	icon_lbl.add_theme_font_size_override("font_size", 52)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = farm.name
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	name_lbl.add_theme_constant_override("shadow_offset_y", 2)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.clip_text = true
	content.add_child(name_lbl)

	# Status badge
	if active:
		var pill := _make_pill("active", Color(0.58, 0.44, 0.78, 0.90))
		var center := CenterContainer.new()
		center.add_child(pill)
		content.add_child(center)
	elif not unlocked:
		var lock_row := HBoxContainer.new()
		lock_row.alignment = BoxContainer.ALIGNMENT_CENTER
		lock_row.add_theme_constant_override("separation", 4)
		var li := Label.new()
		li.text = "🔒"
		li.add_theme_font_size_override("font_size", 13)
		lock_row.add_child(li)
		var pl := Label.new()
		pl.text = "%s ◎" % _fmt(farm.unlock_cost)
		pl.add_theme_font_size_override("font_size", 13)
		pl.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		lock_row.add_child(pl)
		content.add_child(lock_row)

	var bot_space := Control.new()
	bot_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(bot_space)

	# Action button
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 14)
	_style_btn(btn, farm)
	btn.pressed.connect(func(): _on_card_pressed(farm))
	wrapper.set_meta("action_btn", btn)
	content.add_child(btn)

	# Lock overlay (dim + centered lock icon)
	if not unlocked:
		var overlay := Control.new()
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.38)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(dim)
		var lock_center := CenterContainer.new()
		lock_center.set_anchors_preset(Control.PRESET_FULL_RECT)
		lock_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var big_lock := Label.new()
		big_lock.text = "🔒"
		big_lock.add_theme_font_size_override("font_size", 44)
		big_lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_center.add_child(big_lock)
		overlay.add_child(lock_center)
		wrapper.set_meta("lock_overlay", overlay)
		wrapper.add_child(overlay)

	return wrapper


func _make_card_style(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color                   = bg
	s.corner_radius_top_left     = 16
	s.corner_radius_top_right    = 16
	s.corner_radius_bottom_left  = 16
	s.corner_radius_bottom_right = 16
	s.shadow_color  = Color(0, 0, 0, 0.22)
	s.shadow_size   = 8
	s.shadow_offset = Vector2(0, 3)
	s.content_margin_left   = 12
	s.content_margin_right  = 12
	s.content_margin_top    = 10
	s.content_margin_bottom = 10
	return s


func _make_pill(text: String, col: Color) -> PanelContainer:
	var pc := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color                   = col
	s.corner_radius_top_left     = 10
	s.corner_radius_top_right    = 10
	s.corner_radius_bottom_left  = 10
	s.corner_radius_bottom_right = 10
	s.content_margin_left   = 10
	s.content_margin_right  = 10
	s.content_margin_top    = 3
	s.content_margin_bottom = 3
	pc.add_theme_stylebox_override("panel", s)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	pc.add_child(lbl)
	return pc


func _make_sb(col: Color, radius: int = 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color                   = col
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	return s


# ── Button state ──────────────────────────────────────────────────────────────

func _style_btn(btn: Button, farm: FarmData) -> void:
	var unlocked := FarmManager.is_unlocked(farm.id)
	var active   := FarmManager.active_farm_id == farm.id

	if active:
		btn.text     = "current farm"
		btn.disabled = true
		btn.add_theme_stylebox_override("disabled", _make_sb(Color(0.58, 0.44, 0.78, 0.5)))
		btn.add_theme_color_override("font_color_disabled", Color.WHITE)
	elif unlocked:
		btn.text     = "visit"
		btn.disabled = false
		btn.add_theme_stylebox_override("normal",  _make_sb(COLOR_LILA))
		btn.add_theme_stylebox_override("hover",   _make_sb(Color(0.65, 0.50, 0.84)))
		btn.add_theme_stylebox_override("pressed", _make_sb(COLOR_LILA_DARK))
		btn.add_theme_color_override("font_color", Color.WHITE)
	else:
		var can_afford := GameState.coins >= farm.unlock_cost
		btn.text     = "unlock  ◎ %s" % _fmt(farm.unlock_cost)
		btn.disabled = not can_afford
		if can_afford:
			btn.add_theme_stylebox_override("normal",  _make_sb(COLOR_GREEN))
			btn.add_theme_stylebox_override("hover",   _make_sb(COLOR_GREEN_H))
			btn.add_theme_stylebox_override("pressed", _make_sb(COLOR_GREEN_P))
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			btn.add_theme_stylebox_override("disabled", _make_sb(Color(0.55, 0.55, 0.55, 0.45)))
			btn.add_theme_color_override("font_color_disabled", Color(0.75, 0.75, 0.75))


func _refresh_all_btns() -> void:
	for farm in FarmManager.farms:
		if not _cards.has(farm.id):
			continue
		var wrapper: Control = _cards[farm.id]
		var btn: Button = wrapper.get_meta("action_btn", null)
		if btn:
			_style_btn(btn, farm)


# ── Actions ───────────────────────────────────────────────────────────────────

func _on_card_pressed(farm: FarmData) -> void:
	if FarmManager.active_farm_id == farm.id:
		return
	if FarmManager.is_unlocked(farm.id):
		_visit_farm(farm.id)
	else:
		_show_confirm(farm)


func _visit_farm(farm_id: String) -> void:
	FarmManager.set_active_farm(farm_id)
	queue_free()


# ── Unlock confirmation dialog ─────────────────────────────────────────────────

func _show_confirm(farm: FarmData) -> void:
	if _confirm_panel:
		_confirm_panel.queue_free()
	_pending_farm = farm

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.50)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	_confirm_panel = backdrop

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)

	var dialog := PanelContainer.new()
	dialog.custom_minimum_size = Vector2(300, 0)
	var ds := StyleBoxFlat.new()
	ds.bg_color                   = Color(0.98, 0.96, 1.00)
	ds.corner_radius_top_left     = 20
	ds.corner_radius_top_right    = 20
	ds.corner_radius_bottom_left  = 20
	ds.corner_radius_bottom_right = 20
	ds.content_margin_left   = 24
	ds.content_margin_right  = 24
	ds.content_margin_top    = 24
	ds.content_margin_bottom = 20
	dialog.add_theme_stylebox_override("panel", ds)
	center.add_child(dialog)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	dialog.add_child(vbox)

	var title := Label.new()
	title.text = "Unlock %s?" % farm.name
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var body := Label.new()
	body.text = "Costs %s ◎" % _fmt(farm.unlock_cost)
	body.add_theme_font_size_override("font_size", 15)
	body.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(body)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.add_theme_font_size_override("font_size", 15)
	cancel.add_theme_stylebox_override("normal",  _make_sb(Color(0.88, 0.84, 0.92)))
	cancel.add_theme_stylebox_override("hover",   _make_sb(Color(0.80, 0.74, 0.88)))
	cancel.add_theme_stylebox_override("pressed", _make_sb(Color(0.72, 0.64, 0.82)))
	cancel.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	cancel.pressed.connect(_close_confirm)
	btn_row.add_child(cancel)

	var unlock_btn := Button.new()
	unlock_btn.text = "Unlock"
	unlock_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unlock_btn.add_theme_font_size_override("font_size", 15)
	unlock_btn.add_theme_stylebox_override("normal",  _make_sb(COLOR_GREEN))
	unlock_btn.add_theme_stylebox_override("hover",   _make_sb(COLOR_GREEN_H))
	unlock_btn.add_theme_stylebox_override("pressed", _make_sb(COLOR_GREEN_P))
	unlock_btn.add_theme_color_override("font_color", Color.WHITE)
	unlock_btn.pressed.connect(_confirm_unlock)
	btn_row.add_child(unlock_btn)

	# Entrance animation
	dialog.modulate.a = 0.0
	dialog.scale = Vector2(0.88, 0.88)
	dialog.pivot_offset = Vector2(150, 0)
	var t := create_tween().set_parallel(true)
	t.tween_property(dialog, "modulate:a", 1.0, 0.18)
	t.tween_property(dialog, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _close_confirm() -> void:
	if _confirm_panel:
		_confirm_panel.queue_free()
		_confirm_panel = null
	_pending_farm = null


func _confirm_unlock() -> void:
	if not _pending_farm:
		_close_confirm()
		return
	var farm := _pending_farm
	_close_confirm()
	FarmManager.unlock_farm(farm.id)


# ── Unlock animation ──────────────────────────────────────────────────────────

func _anim_unlock(farm_id: String) -> void:
	if not _cards.has(farm_id):
		return
	var wrapper: Control = _cards[farm_id]
	var overlay: Control = wrapper.get_meta("lock_overlay", null)
	if overlay:
		var t := create_tween()
		t.tween_property(overlay, "modulate:a", 0.0, 0.35)
		t.tween_callback(func(): overlay.queue_free())


# ── Signal handlers ───────────────────────────────────────────────────────────

func _on_farm_unlocked(farm_id: String) -> void:
	_anim_unlock(farm_id)
	_refresh_all_btns()


func _on_coins_changed(_amount: int) -> void:
	_refresh_all_btns()


# ── Helpers ───────────────────────────────────────────────────────────────────

func _fmt(n: int) -> String:
	# Format 2000 → "2.000"
	var s := str(n)
	var result := ""
	var count  := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "." + result
		result = s[i] + result
		count += 1
	return result
