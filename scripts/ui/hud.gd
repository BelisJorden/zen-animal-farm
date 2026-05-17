extends Control

const AnimalDetailPanelScene = preload("res://scenes/ui/components/AnimalDetailPanel.tscn")

const COLOR_LILA       := Color(0.58, 0.44, 0.78)
const COLOR_LILA_DARK  := Color(0.42, 0.28, 0.65)
const COLOR_TAB_ACTIVE := Color(0.482, 0.369, 0.655)
const COLOR_WHITE      := Color(1.00, 1.00, 1.00)
const COLOR_TEXT_DARK  := Color(0.28, 0.20, 0.38)
const COLOR_TEXT_DIM   := Color(0.28, 0.20, 0.38, 0.55)

@onready var coin_label:  Label          = $CoinCounter/CoinRow/CoinAmountLabel
@onready var cps_label:   Label          = $CoinCounter/CpsLabel
@onready var notif_popup: PanelContainer = $NotificationPopup
@onready var notif_label: Label          = $NotificationPopup/NotifLabel
@onready var quest_bar:   PanelContainer = $QuestBar
@onready var quest_list:  VBoxContainer  = $QuestBar/QuestScroll/QuestList
@onready var bottom_nav:  PanelContainer = $BottomNav

var _tabs: Array[Button] = []
var _active_tab: String  = "farm"

var _golden_bar:       PanelContainer = null
var _golden_cnt_label: Label          = null
var _golden_remaining: int            = 0
var _golden_tick:      Timer          = null
var _animal_panel                     = null


func _ready() -> void:
	_tabs = [
		$BottomNav/TabRow/FarmTab,
		$BottomNav/TabRow/BuildTab,
		$BottomNav/TabRow/EggTab,
		$BottomNav/TabRow/ShopTab,
		$BottomNav/TabRow/MoreTab,
	]
	_style_panels()
	_setup_tabs()
	_connect_signals()
	_setup_golden_bar()
	_setup_farms_btn()
	_setup_animal_panel()
	_refresh_coins(GameState.coins)
	_refresh_cps(AnimalProductionManager.coins_per_second)
	_set_active_tab("farm")
	_rebuild_quest_cards()


# ── Styling ────────────────────────────────────────────────────────────────────

func _style_panels() -> void:
	var notif_style := _flat_box(Color(0.42, 0.28, 0.65, 0.90), 20)
	notif_style.content_margin_left   = 14
	notif_style.content_margin_right  = 14
	notif_style.content_margin_top    = 8
	notif_style.content_margin_bottom = 8
	notif_popup.add_theme_stylebox_override("panel", notif_style)

	var quest_style := _flat_box(Color(1, 1, 1, 0.93), 16, 0, 0)
	quest_style.content_margin_left   = 14
	quest_style.content_margin_right  = 14
	quest_style.content_margin_top    = 10
	quest_style.content_margin_bottom = 10
	quest_bar.add_theme_stylebox_override("panel", quest_style)

	var nav_style := _flat_box(Color(0.98, 0.97, 0.95, 1.0), 0)
	nav_style.content_margin_left   = 6
	nav_style.content_margin_right  = 6
	nav_style.content_margin_top    = 8
	nav_style.content_margin_bottom = 8
	bottom_nav.add_theme_stylebox_override("panel", nav_style)


func _flat_box(color: Color, radius: int, radius_bl: int = -1, radius_br: int = -1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	var bl := radius_bl if radius_bl >= 0 else radius
	var br := radius_br if radius_br >= 0 else radius
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = bl
	s.corner_radius_bottom_right = br
	return s


# ── Tabs ───────────────────────────────────────────────────────────────────────

func _setup_tabs() -> void:
	for btn in _tabs:
		var id := _tab_id(btn)
		_apply_tab_style(btn, false)
		btn.pressed.connect(_on_tab_pressed.bind(id))


func _apply_tab_style(btn: Button, active: bool) -> void:
	var s := _flat_box(COLOR_TAB_ACTIVE if active else Color(0, 0, 0, 0), 10)
	btn.add_theme_stylebox_override("normal",  s)
	btn.add_theme_stylebox_override("hover",   _flat_box(COLOR_TAB_ACTIVE if active else Color(1,1,1,0.08), 10))
	btn.add_theme_stylebox_override("pressed", _flat_box(COLOR_LILA_DARK  if active else Color(1,1,1,0.14), 10))
	btn.add_theme_color_override("font_color", COLOR_WHITE if active else COLOR_TEXT_DARK)


func _set_active_tab(tab_name: String) -> void:
	_active_tab = tab_name
	for btn in _tabs:
		_apply_tab_style(btn, _tab_id(btn) == tab_name)


func _tab_id(btn: Button) -> String:
	return btn.name.to_lower().trim_suffix("tab")


# ── Signal connections ─────────────────────────────────────────────────────────

func _connect_signals() -> void:
	EventBus.coins_changed.connect(_refresh_coins)
	EventBus.coins_per_second_changed.connect(_refresh_cps)
	EventBus.notification_requested.connect(show_notification)
	EventBus.placing_mode_entered.connect(func(_d): _set_placing_mode(true))
	EventBus.placing_mode_exited.connect(func(): _set_placing_mode(false))
	EventBus.golden_animal_spawned.connect(_on_golden_spawned)
	EventBus.golden_animal_collected.connect(func(_c, _s): _hide_golden_bar())
	EventBus.golden_animal_expired.connect(_hide_golden_bar)
	EventBus.quests_updated.connect(_rebuild_quest_cards)
	EventBus.quest_progress_updated.connect(_on_quest_progress_updated)
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.animal_tapped.connect(_on_animal_tapped)


# ── Data refresh ───────────────────────────────────────────────────────────────

func _refresh_coins(amount: int) -> void:
	coin_label.text = str(amount)


func _refresh_cps(cps: float) -> void:
	cps_label.text = "%.1f/sec" % cps


# ── Quest cards ────────────────────────────────────────────────────────────────

func _rebuild_quest_cards() -> void:
	for child in quest_list.get_children():
		child.queue_free()

	var data := QuestManager.get_active_quest_data()
	for entry in data:
		_add_quest_card(entry["quest"], entry["progress"])


func _add_quest_card(quest: Dictionary, progress: int) -> void:
	var target: int = quest["target"]
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 4)
	card.set_meta("quest_id", quest["id"])

	# Row 1: title + rewards
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)

	var title_lbl := Label.new()
	title_lbl.text = quest["title"]
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.clip_text = true

	var reward_lbl := Label.new()
	var coins: int  = quest.get("reward_coins",  0)
	var shards: int = quest.get("reward_shards", 0)
	reward_lbl.text = "◎%d  ✦%d" % [coins, shards]
	reward_lbl.add_theme_font_size_override("font_size", 12)
	reward_lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM)

	top_row.add_child(title_lbl)
	top_row.add_child(reward_lbl)

	# Row 2: progress bar
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 6)
	bar.max_value   = float(target)
	bar.value       = float(mini(progress, target))
	bar.show_percentage = false
	bar.add_theme_stylebox_override("fill",       _flat_box(COLOR_LILA, 3))
	bar.add_theme_stylebox_override("background", _flat_box(Color(0.88, 0.84, 0.92), 3))
	bar.set_meta("bar_ref", true)

	# Row 3: progress text
	var prog_lbl := Label.new()
	prog_lbl.text = "%d / %d" % [mini(progress, target), target]
	prog_lbl.add_theme_font_size_override("font_size", 11)
	prog_lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM)

	card.add_child(top_row)
	card.add_child(bar)
	card.add_child(prog_lbl)
	quest_list.add_child(card)


func _on_quest_progress_updated(quest_id: String, current: int, target: int) -> void:
	for card in quest_list.get_children():
		if card.get_meta("quest_id", "") != quest_id:
			continue
		var bar: ProgressBar = card.get_child(1)
		bar.max_value = float(target)
		bar.value     = float(mini(current, target))
		var prog_lbl: Label = card.get_child(2)
		prog_lbl.text = "%d / %d" % [mini(current, target), target]
		break


func _on_quest_completed(quest_id: String, reward_coins: int, reward_shards: int, _item: String) -> void:
	var q := QuestManager.get_quest(quest_id)
	var title: String = q.get("title", quest_id)
	var msg := "✓ %s  +%d◎  +%d✦" % [title, reward_coins, reward_shards]
	show_notification(msg)


# ── Notification ───────────────────────────────────────────────────────────────

func show_notification(message: String) -> void:
	notif_label.text    = message
	notif_popup.visible = true
	notif_popup.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(notif_popup, "modulate:a", 1.0, 0.25)
	t.tween_interval(2.2)
	t.tween_property(notif_popup, "modulate:a", 0.0, 0.35)
	t.tween_callback(func(): notif_popup.visible = false)


# ── Tab handler ────────────────────────────────────────────────────────────────

func _on_tab_pressed(tab_name: String) -> void:
	_set_active_tab(tab_name)
	match tab_name:
		"egg":
			_open_overlay("res://scenes/ui/Hatchery.tscn")
		"more":
			_open_overlay("res://scenes/ui/More.tscn")
		"shop":
			_open_overlay("res://scenes/ui/Shop.tscn")
		_:
			EventBus.tab_changed.emit(tab_name)


func _open_overlay(scene_path: String) -> void:
	get_parent().get_parent().open_overlay(scene_path)


func _set_placing_mode(active: bool) -> void:
	quest_bar.visible = not active
	if active:
		_set_active_tab("build")
	else:
		_set_active_tab("farm")


# ── Animal detail panel ────────────────────────────────────────────────────────

func _setup_animal_panel() -> void:
	_animal_panel = AnimalDetailPanelScene.instantiate()
	add_child(_animal_panel)


func _on_animal_tapped(animal_id: String, col: int, row: int) -> void:
	if _animal_panel:
		_animal_panel.show_panel(animal_id, "farm", col, row)


# ── Farms button ──────────────────────────────────────────────────────────────

func _setup_farms_btn() -> void:
	var btn := Button.new()
	btn.text = "⊞"
	btn.flat = false
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(0.58, 0.44, 0.78))
	btn.custom_minimum_size = Vector2(44, 44)

	var s := StyleBoxFlat.new()
	s.bg_color                   = Color(1, 1, 1, 0.88)
	s.corner_radius_top_left     = 12
	s.corner_radius_top_right    = 12
	s.corner_radius_bottom_left  = 12
	s.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("normal",  s)
	var sh := StyleBoxFlat.new()
	sh.bg_color                   = Color(0.92, 0.88, 0.98, 0.95)
	sh.corner_radius_top_left     = 12
	sh.corner_radius_top_right    = 12
	sh.corner_radius_bottom_left  = 12
	sh.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("hover",   sh)
	var sp := StyleBoxFlat.new()
	sp.bg_color                   = Color(0.82, 0.76, 0.94, 0.95)
	sp.corner_radius_top_left     = 12
	sp.corner_radius_top_right    = 12
	sp.corner_radius_bottom_left  = 12
	sp.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("pressed", sp)

	btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn.offset_left   = 16
	btn.offset_top    = 16
	btn.offset_right  = 60
	btn.offset_bottom = 60
	btn.pressed.connect(func(): _open_overlay("res://scenes/ui/FarmOverview.tscn"))
	add_child(btn)


# ── Golden animal indicator ────────────────────────────────────────────────────

func _setup_golden_bar() -> void:
	_golden_bar = PanelContainer.new()
	_golden_bar.visible = false

	var s := StyleBoxFlat.new()
	s.bg_color                   = Color(0.78, 0.55, 0.06, 0.93)
	s.corner_radius_top_left     = 14
	s.corner_radius_top_right    = 14
	s.corner_radius_bottom_left  = 14
	s.corner_radius_bottom_right = 14
	s.content_margin_left        = 14
	s.content_margin_right       = 14
	s.content_margin_top         = 7
	s.content_margin_bottom      = 7
	_golden_bar.add_theme_stylebox_override("panel", s)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 7)

	var icon := Label.new()
	icon.text = "✦ golden animal"
	icon.add_theme_color_override("font_color", Color(1.0, 0.97, 0.75))
	icon.add_theme_font_size_override("font_size", 17)

	var sep := Label.new()
	sep.text = "·"
	sep.add_theme_color_override("font_color", Color(1.0, 0.97, 0.75, 0.6))
	sep.add_theme_font_size_override("font_size", 17)

	_golden_cnt_label = Label.new()
	_golden_cnt_label.text = "15s"
	_golden_cnt_label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.75))
	_golden_cnt_label.add_theme_font_size_override("font_size", 17)

	hbox.add_child(icon)
	hbox.add_child(sep)
	hbox.add_child(_golden_cnt_label)
	_golden_bar.add_child(hbox)

	_golden_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_golden_bar.offset_left   = 155
	_golden_bar.offset_right  = -155
	_golden_bar.offset_top    = 16
	_golden_bar.offset_bottom = 16
	add_child(_golden_bar)

	_golden_tick           = Timer.new()
	_golden_tick.one_shot  = false
	_golden_tick.wait_time = 1.0
	_golden_tick.timeout.connect(_on_golden_tick)
	add_child(_golden_tick)


func _on_golden_spawned(_animal: Node, _farm_id: String) -> void:
	_golden_remaining = int(GoldenAnimalManager.GOLDEN_DURATION)
	_golden_cnt_label.text = "%ds" % _golden_remaining
	_golden_bar.visible    = true
	_golden_bar.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_golden_bar, "modulate:a", 1.0, 0.30)
	_golden_tick.start()


func _on_golden_tick() -> void:
	_golden_remaining = max(0, _golden_remaining - 1)
	_golden_cnt_label.text = "%ds" % _golden_remaining
	if _golden_remaining == 0:
		_golden_tick.stop()


func _hide_golden_bar() -> void:
	_golden_tick.stop()
	var t := create_tween()
	t.tween_property(_golden_bar, "modulate:a", 0.0, 0.30)
	t.tween_callback(func(): _golden_bar.visible = false)
