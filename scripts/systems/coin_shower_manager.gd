extends Node

const COIN_INTERVAL:    float = 600.0  # 10 min
const SPIRIT_INTERVAL:  float = 1800.0  # 30 min
const WINDOW_DURATION:  float = 300.0   # 5 min button stays visible

var coin_shower_ready:   bool   = false
var spirit_shower_ready: bool   = false
var pending_shower_type: String = "coin"  # read by CoinShowerGame in _ready()

var _coin_timer:          Timer = null
var _spirit_timer:        Timer = null
var _coin_window_timer:   Timer = null
var _spirit_window_timer: Timer = null


func _ready() -> void:
	_coin_timer          = _make_timer(COIN_INTERVAL,   _on_coin_timer_done)
	_spirit_timer        = _make_timer(SPIRIT_INTERVAL, _on_spirit_timer_done)
	_coin_window_timer   = _make_timer(WINDOW_DURATION, _on_coin_window_expired,   true)
	_spirit_window_timer = _make_timer(WINDOW_DURATION, _on_spirit_window_expired, true)
	_coin_timer.start()
	EventBus.quest_completed.connect(
		func(_id: String, _c: int, _s: int, _i: String): _check_start_spirit_timer()
	)


func _make_timer(wait: float, callback: Callable, one_shot: bool = false) -> Timer:
	var t := Timer.new()
	t.wait_time = wait
	t.one_shot  = one_shot
	t.timeout.connect(callback)
	add_child(t)
	return t


func is_spirit_shower_unlocked() -> bool:
	return QuestManager.completed_quests.size() >= 3


func _check_start_spirit_timer() -> void:
	if is_spirit_shower_unlocked() and _spirit_timer.is_stopped() and not spirit_shower_ready:
		_spirit_timer.wait_time = SPIRIT_INTERVAL
		_spirit_timer.start()


func _on_coin_timer_done() -> void:
	coin_shower_ready = true
	EventBus.coin_shower_available.emit()
	_coin_window_timer.start()


func _on_spirit_timer_done() -> void:
	if not is_spirit_shower_unlocked():
		_spirit_timer.wait_time = SPIRIT_INTERVAL
		_spirit_timer.start()
		return
	spirit_shower_ready = true
	EventBus.spirit_shower_available.emit()
	_spirit_window_timer.start()


func _on_coin_window_expired() -> void:
	coin_shower_ready = false
	EventBus.coin_shower_gone.emit()
	_coin_timer.wait_time = COIN_INTERVAL
	_coin_timer.start()


func _on_spirit_window_expired() -> void:
	spirit_shower_ready = false
	EventBus.spirit_shower_gone.emit()
	_spirit_timer.wait_time = SPIRIT_INTERVAL
	_spirit_timer.start()


func open_coin_shower() -> void:
	coin_shower_ready = false
	_coin_window_timer.stop()
	pending_shower_type = "coin"
	EventBus.coin_shower_gone.emit()


func open_spirit_shower() -> void:
	spirit_shower_ready = false
	_spirit_window_timer.stop()
	pending_shower_type = "spirit"
	EventBus.spirit_shower_gone.emit()


func on_shower_finished() -> void:
	if pending_shower_type == "coin":
		_coin_timer.wait_time = COIN_INTERVAL
		_coin_timer.start()
	else:
		_spirit_timer.wait_time = SPIRIT_INTERVAL
		_spirit_timer.start()


# ── Save / Load ────────────────────────────────────────────────────────────────

func save_state(cfg: ConfigFile) -> void:
	var now := int(Time.get_unix_time_from_system())

	var coin_next: int
	if coin_shower_ready:
		coin_next = 0  # already available
	elif not _coin_timer.is_stopped():
		coin_next = now + int(_coin_timer.time_left)
	else:
		coin_next = now

	var spirit_next: int
	if spirit_shower_ready:
		spirit_next = 0
	elif not _spirit_timer.is_stopped():
		spirit_next = now + int(_spirit_timer.time_left)
	else:
		spirit_next = now + int(SPIRIT_INTERVAL)

	cfg.set_value("coin_shower", "coin_next_time",   coin_next)
	cfg.set_value("coin_shower", "spirit_next_time", spirit_next)
	cfg.set_value("coin_shower", "coin_ready",       coin_shower_ready)
	cfg.set_value("coin_shower", "spirit_ready",     spirit_shower_ready)


func load_state(cfg: ConfigFile) -> void:
	var now := int(Time.get_unix_time_from_system())
	var coin_next: int   = cfg.get_value("coin_shower", "coin_next_time",   now + int(COIN_INTERVAL))
	var spirit_next: int = cfg.get_value("coin_shower", "spirit_next_time", now + int(SPIRIT_INTERVAL))
	coin_shower_ready   = cfg.get_value("coin_shower", "coin_ready",   false)
	spirit_shower_ready = cfg.get_value("coin_shower", "spirit_ready", false)

	_coin_timer.stop()
	_spirit_timer.stop()
	_coin_window_timer.stop()
	_spirit_window_timer.stop()

	# Coin shower
	if coin_shower_ready:
		_coin_window_timer.start()
	elif coin_next <= now:
		coin_shower_ready = true
		_coin_window_timer.start()
	else:
		_coin_timer.wait_time = float(coin_next - now)
		_coin_timer.start()

	# Spirit shower (only if unlocked)
	if is_spirit_shower_unlocked():
		if spirit_shower_ready:
			_spirit_window_timer.start()
		elif spirit_next <= now:
			spirit_shower_ready = true
			_spirit_window_timer.start()
		else:
			_spirit_timer.wait_time = float(spirit_next - now)
			_spirit_timer.start()
