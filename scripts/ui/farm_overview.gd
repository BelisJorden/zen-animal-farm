extends Control

const COLOR_LILA      := Color(0.58, 0.44, 0.78)
const COLOR_LILA_DARK := Color(0.42, 0.28, 0.65)
const COLOR_TEXT_DARK := Color(0.22, 0.16, 0.32)
const COLOR_DIM       := Color(0.22, 0.16, 0.32, 0.55)

var _cards: Dictionary = {}  # farm_id -> card VBoxContainer


func _ready() -> void:
	_build_ui()
	EventBus.farm_unlocked.connect(_on_farm_unlocked)
	EventBus.coins_changed.connect(_on_coins_changed)


func _build_ui() -> void:
	# ── Full-screen dim backdrop ──────────────────────────────────────────────
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.55)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	# ── Centered panel ────────────────────────────────────────────────────────
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left   = 24
	panel.offset_right  = -24
	panel.offset_top    = 80
	panel.offset_bottom = -80
	var ps := StyleBoxFlat.new()
	ps.bg_color                   = Color(0.97, 0.95, 0.99, 0.97)
	ps.corner_radius_top_left     = 20
	ps.corner_radius_top_right    = 20
	ps.corner_radius_bottom_left  = 20
	ps.corner_radius_bottom_right = 20
	ps.content_margin_left   = 20
	ps.content_margin_right  = 20
	ps.content_margin_top    = 16
	ps.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	# ── Header ────────────────────────────────────────────────────────────────
	var header := HBoxContainer.new()
	vbox.add_child(header)

	var back := Button.new()
	back.text = "< back"
	back.flat = true
	back.add_theme_font_size_override("font_size", 15)
	back.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	back.custom_minimum_size = Vector2(80, 0)
	back.pressed.connect(queue_free)
	header.add_child(back)

	var title := Label.new()
	title.text = "your farms"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(80, 0)
	header.add_child(spacer)

	# ── Horizontal scroll of farm cards ──────────────────────────────────────
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(row)

	for farm in FarmManager.farms:
		var card := _build_card(farm)
		_cards[farm.id] = card
		row.add_child(card)


func _build_card(farm: FarmData) -> VBoxContainer:
	var unlocked := FarmManager.is_unlocked(farm.id)
	var active   := FarmManager.active_farm_id == farm.id

	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(200, 0)
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_constant_override("separation", 10)

	# ── Gradient preview ──────────────────────────────────────────────────────
	var preview := PanelContainer.new()
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var prev_style := StyleBoxFlat.new()
	prev_style.bg_color                   = farm.background_mid
	prev_style.corner_radius_top_left     = 14
	prev_style.corner_radius_top_right    = 14
	prev_style.corner_radius_bottom_left  = 14
	prev_style.corner_radius_bottom_right = 14
	preview.add_theme_stylebox_override("panel", prev_style)
	card.add_child(preview)

	var preview_content := VBoxContainer.new()
	preview_content.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_content.add_theme_constant_override("separation", 4)
	preview.add_child(preview_content)

	var farm_name := Label.new()
	farm_name.text = farm.name
	farm_name.add_theme_font_size_override("font_size", 18)
	farm_name.add_theme_color_override("font_color", Color.WHITE)
	farm_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	farm_name.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	preview_content.add_child(farm_name)

	if not unlocked:
		var lock_lbl := Label.new()
		lock_lbl.text = "locked"
		lock_lbl.add_theme_font_size_override("font_size", 13)
		lock_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_content.add_child(lock_lbl)

	if active:
		var active_lbl := Label.new()
		active_lbl.text = "active"
		active_lbl.add_theme_font_size_override("font_size", 12)
		active_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
		active_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_content.add_child(active_lbl)

	# ── Action button ─────────────────────────────────────────────────────────
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 15)
	card.add_child(btn)
	card.set_meta("action_btn", btn)

	_refresh_card_button(farm, btn)
	return card


func _refresh_card_button(farm: FarmData, btn: Button) -> void:
	var unlocked := FarmManager.is_unlocked(farm.id)
	var active   := FarmManager.active_farm_id == farm.id

	var sb_n := StyleBoxFlat.new()
	var sb_h := StyleBoxFlat.new()
	var sb_p := StyleBoxFlat.new()
	var sb_d := StyleBoxFlat.new()
	for sb in [sb_n, sb_h, sb_p, sb_d]:
		sb.corner_radius_top_left     = 12
		sb.corner_radius_top_right    = 12
		sb.corner_radius_bottom_left  = 12
		sb.corner_radius_bottom_right = 12
	sb_d.bg_color = Color(0.7, 0.7, 0.7, 0.5)

	if active:
		btn.text     = "current farm"
		btn.disabled = true
		sb_d.bg_color = Color(0.58, 0.44, 0.78, 0.5)
		btn.add_theme_stylebox_override("disabled", sb_d)
		btn.add_theme_color_override("font_color_disabled", Color.WHITE)
	elif unlocked:
		btn.text     = "visit"
		btn.disabled = false
		sb_n.bg_color = COLOR_LILA
		sb_h.bg_color = Color(0.65, 0.50, 0.84)
		sb_p.bg_color = COLOR_LILA_DARK
		btn.add_theme_stylebox_override("normal",  sb_n)
		btn.add_theme_stylebox_override("hover",   sb_h)
		btn.add_theme_stylebox_override("pressed", sb_p)
		btn.add_theme_color_override("font_color", Color.WHITE)
		if not btn.pressed.is_connected(_visit_farm.bind(farm.id)):
			btn.pressed.connect(_visit_farm.bind(farm.id))
	else:
		var can_afford := GameState.coins >= farm.unlock_cost
		btn.text     = "unlock  ◎ %d" % farm.unlock_cost
		btn.disabled = not can_afford
		if can_afford:
			sb_n.bg_color = Color(0.22, 0.60, 0.35)
			sb_h.bg_color = Color(0.28, 0.68, 0.42)
			sb_p.bg_color = Color(0.18, 0.50, 0.30)
			btn.add_theme_stylebox_override("normal",  sb_n)
			btn.add_theme_stylebox_override("hover",   sb_h)
			btn.add_theme_stylebox_override("pressed", sb_p)
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			btn.add_theme_stylebox_override("disabled", sb_d)
			btn.add_theme_color_override("font_color_disabled", Color(0.5, 0.5, 0.5))
		if not btn.pressed.is_connected(_unlock_farm.bind(farm.id)):
			btn.pressed.connect(_unlock_farm.bind(farm.id))


func _visit_farm(farm_id: String) -> void:
	FarmManager.set_active_farm(farm_id)
	queue_free()


func _unlock_farm(farm_id: String) -> void:
	if FarmManager.unlock_farm(farm_id):
		_refresh_all_cards()


func _refresh_all_cards() -> void:
	for farm in FarmManager.farms:
		if _cards.has(farm.id):
			var card: VBoxContainer = _cards[farm.id]
			var btn: Button = card.get_meta("action_btn")
			_refresh_card_button(farm, btn)


func _on_farm_unlocked(_farm_id: String) -> void:
	_refresh_all_cards()


func _on_coins_changed(_amount: int) -> void:
	_refresh_all_cards()
