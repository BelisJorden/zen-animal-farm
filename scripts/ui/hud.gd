extends Control

const COLOR_LILA      := Color(0.58, 0.44, 0.78)
const COLOR_LILA_DARK := Color(0.42, 0.28, 0.65)
const COLOR_TAB_ACTIVE := Color(0.482, 0.369, 0.655)
const COLOR_WHITE     := Color(1.00, 1.00, 1.00)
const COLOR_TEXT_DARK := Color(0.28, 0.20, 0.38)

@onready var top_panel:      PanelContainer = $TopPanel
@onready var avatar:         PanelContainer = $TopPanel/TopRow/PlayerInfo/Avatar
@onready var avatar_letter:  Label          = $TopPanel/TopRow/PlayerInfo/Avatar/AvatarLetter
@onready var name_label:     Label          = $TopPanel/TopRow/PlayerInfo/PlayerDetails/NameLabel
@onready var level_day:      Label          = $TopPanel/TopRow/PlayerInfo/PlayerDetails/LevelDayLabel
@onready var coin_label:     Label          = $TopPanel/TopRow/CoinCounter/CoinAmountLabel
@onready var notif_popup:    PanelContainer = $NotificationPopup
@onready var notif_label:    Label          = $NotificationPopup/NotifLabel
@onready var quest_bar:      PanelContainer = $QuestBar
@onready var quest_label:    Label          = $QuestBar/QuestContent/QuestLabel
@onready var quest_progress: ProgressBar    = $QuestBar/QuestContent/QuestProgress
@onready var bottom_nav:     PanelContainer = $BottomNav

var _tabs: Array[Button] = []
var _active_tab: String = "farm"


func _ready() -> void:
	_tabs = [
		$BottomNav/TabRow/FarmTab,
		$BottomNav/TabRow/BuildTab,
		$BottomNav/TabRow/EggTab,
		$BottomNav/TabRow/CareTab,
		$BottomNav/TabRow/MoreTab,
	]
	_style_panels()
	_style_progress_bar()
	_setup_tabs()
	_connect_signals()
	_refresh_player_info()
	_refresh_coins(GameState.coins)
	_set_active_tab("farm")


# ── Styling ────────────────────────────────────────────────────────────────────

func _style_panels() -> void:
	top_panel.add_theme_stylebox_override("panel", _flat_box(Color(0, 0, 0, 0.30), 0))

	var avatar_style := _flat_box(COLOR_LILA_DARK, 24)
	avatar_style.content_margin_left   = 0
	avatar_style.content_margin_right  = 0
	avatar_style.content_margin_top    = 0
	avatar_style.content_margin_bottom = 0
	avatar.add_theme_stylebox_override("panel", avatar_style)

	var notif_style := _flat_box(Color(0.42, 0.28, 0.65, 0.90), 20)
	notif_style.content_margin_left   = 14
	notif_style.content_margin_right  = 14
	notif_style.content_margin_top    = 8
	notif_style.content_margin_bottom = 8
	notif_popup.add_theme_stylebox_override("panel", notif_style)

	var quest_style := _flat_box(Color(1, 1, 1, 0.93), 16, 0, 0)
	quest_style.content_margin_left   = 18
	quest_style.content_margin_right  = 18
	quest_style.content_margin_top    = 10
	quest_style.content_margin_bottom = 10
	quest_bar.add_theme_stylebox_override("panel", quest_style)

	var nav_style := _flat_box(Color(0.98, 0.97, 0.95, 1.0), 0)
	nav_style.content_margin_left   = 6
	nav_style.content_margin_right  = 6
	nav_style.content_margin_top    = 8
	nav_style.content_margin_bottom = 8
	bottom_nav.add_theme_stylebox_override("panel", nav_style)


func _style_progress_bar() -> void:
	var fill := _flat_box(COLOR_LILA, 4)
	var bg   := _flat_box(Color(0.88, 0.84, 0.92), 4)
	quest_progress.add_theme_stylebox_override("fill", fill)
	quest_progress.add_theme_stylebox_override("background", bg)


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
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover",  _flat_box(COLOR_TAB_ACTIVE if active else Color(1,1,1,0.08), 10))
	btn.add_theme_stylebox_override("pressed", _flat_box(COLOR_LILA_DARK if active else Color(1,1,1,0.14), 10))
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
	EventBus.quest_progress_updated.connect(_on_quest_updated)
	EventBus.notification_requested.connect(show_notification)
	EventBus.placing_mode_entered.connect(func(_d): _set_placing_mode(true))
	EventBus.placing_mode_exited.connect(func(): _set_placing_mode(false))


# ── Data refresh ───────────────────────────────────────────────────────────────

func _refresh_player_info() -> void:
	name_label.text  = GameState.player_name
	level_day.text   = "lv.%d · dag %d" % [GameState.level, GameState.day]
	avatar_letter.text = GameState.player_name.left(1).to_upper()


func _refresh_coins(amount: int) -> void:
	coin_label.text = str(amount)


func _on_quest_updated(_quest_id: String, current: int, target: int) -> void:
	quest_label.text       = "collect %d spirit shards · %d/%d" % [target, current, target]
	quest_progress.max_value = float(target)
	quest_progress.value     = float(current)


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
			_open_overlay("res://scenes/ui/Shop.tscn")
		"care":
			show_notification("coming soon")
		_:
			EventBus.tab_changed.emit(tab_name)


func _open_overlay(scene_path: String) -> void:
	# HUD lives at FarmScreen/HUDLayer/HUD — parent chain reaches FarmScreen
	get_parent().get_parent().open_overlay(scene_path)


func _set_placing_mode(active: bool) -> void:
	quest_bar.visible  = not active
	bottom_nav.visible = not active
