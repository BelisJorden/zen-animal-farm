extends Node

const COIN_INTERVAL:    float = 10.0    # seconden (10 voor testen, productie: 1800)
const SPIRIT_INTERVAL:  float = 1800.0  # 30 min
const WINDOW_DURATION:  float = 300.0   # 5 min knop zichtbaar

var coin_shower_ready:   bool   = false
var spirit_shower_ready: bool   = false
var pending_shower_type: String = "coin"  # gelezen door CoinShowerGame in _ready()

# Unix timestamps (int seconden) — 0 = inactief
var _coin_next_time:         int = 0
var _spirit_next_time:       int = 0
var _coin_window_end_time:   int = 0
var _spirit_window_end_time: int = 0


func _ready() -> void:
	var now := int(Time.get_unix_time_from_system())
	_coin_next_time   = now + int(COIN_INTERVAL)
	_spirit_next_time = now + int(SPIRIT_INTERVAL)
	EventBus.quest_completed.connect(
		func(_id: String, _c: int, _s: int, _i: String): _on_quest_completed_check()
	)


# _process checkt real-world klok elke frame — werkt ook na pauzeren/achtergrond
func _process(_delta: float) -> void:
	var now := int(Time.get_unix_time_from_system())

	# Coin shower: interval verstreken
	if not coin_shower_ready and _coin_next_time > 0 and now >= _coin_next_time:
		coin_shower_ready     = true
		_coin_next_time       = 0
		_coin_window_end_time = now + int(WINDOW_DURATION)
		EventBus.coin_shower_available.emit()

	# Coin shower: venster verlopen zonder tap
	if coin_shower_ready and _coin_window_end_time > 0 and now >= _coin_window_end_time:
		coin_shower_ready     = false
		_coin_window_end_time = 0
		_coin_next_time       = now + int(COIN_INTERVAL)
		EventBus.coin_shower_gone.emit()

	# Spirit shower: interval verstreken
	if is_spirit_shower_unlocked() and not spirit_shower_ready \
			and _spirit_next_time > 0 and now >= _spirit_next_time:
		spirit_shower_ready     = true
		_spirit_next_time       = 0
		_spirit_window_end_time = now + int(WINDOW_DURATION)
		EventBus.spirit_shower_available.emit()

	# Spirit shower: venster verlopen
	if spirit_shower_ready and _spirit_window_end_time > 0 and now >= _spirit_window_end_time:
		spirit_shower_ready     = false
		_spirit_window_end_time = 0
		_spirit_next_time       = now + int(SPIRIT_INTERVAL)
		EventBus.spirit_shower_gone.emit()


func is_spirit_shower_unlocked() -> bool:
	return QuestManager.completed_quests.size() >= 3


func _on_quest_completed_check() -> void:
	if is_spirit_shower_unlocked() and _spirit_next_time == 0 and not spirit_shower_ready:
		_spirit_next_time = int(Time.get_unix_time_from_system()) + int(SPIRIT_INTERVAL)


func open_coin_shower() -> void:
	coin_shower_ready     = false
	_coin_window_end_time = 0
	pending_shower_type   = "coin"
	EventBus.coin_shower_gone.emit()


func open_spirit_shower() -> void:
	spirit_shower_ready     = false
	_spirit_window_end_time = 0
	pending_shower_type     = "spirit"
	EventBus.spirit_shower_gone.emit()


func on_shower_finished() -> void:
	var now := int(Time.get_unix_time_from_system())
	if pending_shower_type == "coin":
		_coin_next_time = now + int(COIN_INTERVAL)
	else:
		_spirit_next_time = now + int(SPIRIT_INTERVAL)


# ── Save / Load ────────────────────────────────────────────────────────────────

func save_state(cfg: ConfigFile) -> void:
	cfg.set_value("coin_shower", "coin_next_time",    _coin_next_time)
	cfg.set_value("coin_shower", "spirit_next_time",  _spirit_next_time)
	cfg.set_value("coin_shower", "coin_window_end",   _coin_window_end_time)
	cfg.set_value("coin_shower", "spirit_window_end", _spirit_window_end_time)
	cfg.set_value("coin_shower", "coin_ready",        coin_shower_ready)
	cfg.set_value("coin_shower", "spirit_ready",      spirit_shower_ready)


func load_state(cfg: ConfigFile) -> void:
	var now := int(Time.get_unix_time_from_system())
	_coin_next_time         = cfg.get_value("coin_shower", "coin_next_time",    now + int(COIN_INTERVAL))
	_spirit_next_time       = cfg.get_value("coin_shower", "spirit_next_time",  now + int(SPIRIT_INTERVAL))
	_coin_window_end_time   = cfg.get_value("coin_shower", "coin_window_end",   0)
	_spirit_window_end_time = cfg.get_value("coin_shower", "spirit_window_end", 0)
	coin_shower_ready       = cfg.get_value("coin_shower", "coin_ready",  false)
	spirit_shower_ready     = cfg.get_value("coin_shower", "spirit_ready", false)
	# Spirit timer starten als unlocked maar nog geen timestamp ingesteld
	if is_spirit_shower_unlocked() and _spirit_next_time == 0 and not spirit_shower_ready:
		_spirit_next_time = now + int(SPIRIT_INTERVAL)
