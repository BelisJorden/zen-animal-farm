extends Control

const GAME_DURATION := 15.0
const COIN_SIZE     := Vector2(60.0, 60.0)

const COLOR_GOLD  := Color(0.94, 0.63, 0.05)
const COLOR_LILA  := Color(0.58, 0.44, 0.78)
const COLOR_WHITE := Color(1.0,  1.0,  1.0)

var _is_spirit: bool  = false
var _score:     int   = 0
var _time_left: float = GAME_DURATION
var _running:   bool  = false
var _spawn_acc: float = 0.0
var _active_coins: Array = []

var _spawn_interval: float = 0.5
var _fall_speed:     float = 250.0
var _double_spawn:   bool  = false

var _score_label:  Label   = null
var _timer_label:  Label   = null
var _coin_layer:   Control = null
var _result_panel: Control = null


func _ready() -> void:
	_is_spirit = CoinShowerManager.pending_shower_type == "spirit"
	_calc_difficulty()
	_build_ui()
	_running = true


func _calc_difficulty() -> void:
	var total := 0
	for fid in SaveSystem.placed_animals_per_farm:
		total += SaveSystem.placed_animals_per_farm[fid].size()
	if total >= 16:
		_spawn_interval = 0.25
		_fall_speed     = 450.0
		_double_spawn   = true
	elif total >= 5:
		_spawn_interval = 0.35
		_fall_speed     = 350.0
	else:
		_spawn_interval = 0.5
		_fall_speed     = 250.0


func _build_ui() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Gradient background
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	var gradient := Gradient.new()
	if _is_spirit:
		gradient.set_color(0, Color(0.12, 0.04, 0.24))
		gradient.set_color(1, Color(0.22, 0.08, 0.38))
	else:
		gradient.set_color(0, Color(0.06, 0.05, 0.20))
		gradient.set_color(1, Color(0.12, 0.08, 0.30))
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient  = gradient
	grad_tex.fill_from = Vector2(0.5, 0.0)
	grad_tex.fill_to   = Vector2(0.5, 1.0)
	bg.texture = grad_tex
	add_child(bg)

	# Clouds decoration
	var clouds := Label.new()
	clouds.text = "☁  ☁    ☁  ☁   ☁"
	clouds.add_theme_color_override("font_color", Color(1, 1, 1, 0.15))
	clouds.add_theme_font_size_override("font_size", 52)
	clouds.set_anchors_preset(Control.PRESET_TOP_WIDE)
	clouds.offset_top    = 20
	clouds.offset_bottom = 90
	clouds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(clouds)

	# Top bar: timer (left) + score (right)
	var top_bar := HBoxContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_left   = 28
	top_bar.offset_right  = -28
	top_bar.offset_top    = 36
	top_bar.offset_bottom = 108
	top_bar.add_theme_constant_override("separation", 0)
	add_child(top_bar)

	_timer_label = Label.new()
	_timer_label.text = "%ds" % int(GAME_DURATION)
	_timer_label.add_theme_font_size_override("font_size", 52)
	_timer_label.add_theme_color_override("font_color", COLOR_WHITE)
	_timer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_timer_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_LEFT
	top_bar.add_child(_timer_label)

	_score_label = Label.new()
	var symbol := "✦" if _is_spirit else "◎"
	_score_label.text = "%s 0" % symbol
	_score_label.add_theme_font_size_override("font_size", 38)
	_score_label.add_theme_color_override("font_color", COLOR_GOLD)
	_score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_score_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
	top_bar.add_child(_score_label)

	# Bottom hint
	var hint := Label.new()
	hint.text = "Tap the %s!" % symbol
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.50))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top    = -64
	hint.offset_bottom = -20
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)

	# Coin layer (input passthrough)
	_coin_layer = Control.new()
	_coin_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_coin_layer.mouse_filter = MOUSE_FILTER_PASS
	add_child(_coin_layer)

	# Result panel (hidden until game ends)
	_result_panel = Control.new()
	_result_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_panel.visible     = false
	_result_panel.mouse_filter = MOUSE_FILTER_STOP
	add_child(_result_panel)


func _process(delta: float) -> void:
	if not _running:
		return

	_time_left -= delta
	var display_secs: int = maxi(0, int(ceil(_time_left)))
	_timer_label.text = "%ds" % display_secs

	if _time_left <= 5.0:
		_timer_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))

	if _time_left <= 0.0:
		_end_game()
		return

	_spawn_acc += delta
	if _spawn_acc >= _spawn_interval:
		_spawn_acc = 0.0
		_spawn_coin()
		if _double_spawn:
			_spawn_coin()


func _spawn_coin() -> void:
	var vp     := get_viewport_rect().size
	var symbol := "✦" if _is_spirit else "◎"

	var coin := Button.new()
	coin.text       = symbol
	coin.flat       = false
	coin.focus_mode = FOCUS_NONE
	coin.add_theme_font_size_override("font_size", 28)
	coin.add_theme_color_override("font_color", COLOR_WHITE)
	coin.custom_minimum_size = COIN_SIZE
	coin.pivot_offset        = COIN_SIZE / 2.0

	var sn := StyleBoxFlat.new()
	sn.bg_color = Color(0.97, 0.72, 0.10, 0.90) if not _is_spirit else Color(0.50, 0.28, 0.82, 0.90)
	var r := int(COIN_SIZE.x / 2)
	sn.corner_radius_top_left     = r
	sn.corner_radius_top_right    = r
	sn.corner_radius_bottom_left  = r
	sn.corner_radius_bottom_right = r
	coin.add_theme_stylebox_override("normal",  sn)
	coin.add_theme_stylebox_override("hover",   sn)
	coin.add_theme_stylebox_override("pressed", sn)

	var start_x := randf_range(4.0, vp.x - COIN_SIZE.x - 4.0)
	coin.position = Vector2(start_x, -COIN_SIZE.y)
	_coin_layer.add_child(coin)
	_active_coins.append(coin)

	var distance := vp.y + COIN_SIZE.y * 2.0
	var duration := distance / _fall_speed

	var fall := create_tween()
	fall.tween_property(coin, "position:y", vp.y + COIN_SIZE.y, duration) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	fall.tween_callback(func():
		_active_coins.erase(coin)
		if is_instance_valid(coin):
			coin.queue_free()
	)

	coin.button_down.connect(func():
		if not _running:
			return
		_on_coin_tapped(coin, fall)
	)


func _on_coin_tapped(coin: Button, fall_tween: Tween) -> void:
	if not is_instance_valid(coin):
		return
	_active_coins.erase(coin)
	fall_tween.kill()

	_score += 1
	var symbol := "✦" if _is_spirit else "◎"
	_score_label.text = "%s %d" % [symbol, _score]

	var burst := create_tween()
	burst.set_parallel(true)
	burst.tween_property(coin, "scale",       Vector2(1.5, 1.5), 0.14).set_ease(Tween.EASE_OUT)
	burst.tween_property(coin, "modulate:a",  0.0,               0.14)
	burst.finished.connect(func():
		if is_instance_valid(coin):
			coin.queue_free()
	)

	_pop_score_label()


func _pop_score_label() -> void:
	var t := create_tween()
	t.tween_property(_score_label, "scale", Vector2(1.28, 1.28), 0.07).set_ease(Tween.EASE_OUT)
	t.tween_property(_score_label, "scale", Vector2.ONE,          0.13).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _end_game() -> void:
	_running = false
	set_process(false)
	_timer_label.text = "0s"

	var fade := create_tween()
	fade.tween_property(_coin_layer, "modulate:a", 0.0, 0.25)

	await get_tree().create_timer(0.55).timeout

	for coin in _active_coins.duplicate():
		if is_instance_valid(coin):
			coin.queue_free()
	_active_coins.clear()

	_show_result()


func _show_result() -> void:
	_result_panel.visible = true

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.70)
	_result_panel.add_child(overlay)

	var card := VBoxContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left   = -165
	card.offset_right  =  165
	card.offset_top    = -195
	card.offset_bottom =  195
	card.add_theme_constant_override("separation", 18)
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	_result_panel.add_child(card)

	# "Time's up!"
	var title := Label.new()
	title.text = "Time's up!"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 0.80))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(title)

	# Reward
	var reward_amount: int
	var reward_text: String
	if _is_spirit:
		reward_amount = max(1, _score * 2)
		reward_text   = "+%d ✦" % reward_amount
	else:
		var per_coin: int = maxi(10, int(AnimalProductionManager.coins_per_second * 30.0))
		reward_amount = _score * per_coin
		reward_text   = "+%d ◎" % reward_amount

	var reward_lbl := Label.new()
	reward_lbl.text = reward_text
	reward_lbl.add_theme_font_size_override("font_size", 60)
	reward_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_lbl.modulate.a = 0.0
	card.add_child(reward_lbl)

	# Flavor
	var flavor := Label.new()
	if _score >= 20:
		flavor.text = "Amazing! 🎉"
	elif _score >= 10:
		flavor.text = "Great catch!"
	else:
		flavor.text = "Nice start!"
	flavor.add_theme_font_size_override("font_size", 22)
	flavor.add_theme_color_override("font_color", Color(1, 1, 1, 0.70))
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(flavor)

	# Collect button
	var collect_btn := Button.new()
	collect_btn.text               = "Collect"
	collect_btn.custom_minimum_size = Vector2(170, 56)
	collect_btn.focus_mode         = FOCUS_NONE
	var btn_bg := Color(0.94, 0.63, 0.05) if not _is_spirit else COLOR_LILA
	var bs := _round_box(btn_bg, 28)
	collect_btn.add_theme_stylebox_override("normal",  bs)
	collect_btn.add_theme_stylebox_override("hover",   bs)
	collect_btn.add_theme_stylebox_override("pressed", _round_box(btn_bg.darkened(0.15), 28))
	collect_btn.add_theme_color_override("font_color", COLOR_WHITE)
	collect_btn.add_theme_font_size_override("font_size", 22)
	collect_btn.button_down.connect(func(): _collect(reward_amount))
	card.add_child(collect_btn)

	# Animate in
	card.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(card, "modulate:a", 1.0, 0.30)
	var t2 := create_tween()
	t2.tween_property(reward_lbl, "modulate:a", 1.0, 0.45).set_delay(0.15)


func _collect(reward_amount: int) -> void:
	if _is_spirit:
		GameState.add_spirit_shards(reward_amount)
	else:
		EventBus.coins_earned.emit(reward_amount)
	CoinShowerManager.on_shower_finished()
	queue_free()


func _round_box(color: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color                   = color
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	return s
