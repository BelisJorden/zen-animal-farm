extends Control

const AnimalData             = preload("res://scripts/resources/animal_data.gd")
const AnimalDetailPanelScene = preload("res://scenes/ui/components/AnimalDetailPanel.tscn")

const LILA      := Color(0.58, 0.44, 0.78)
const LILA_DARK := Color(0.42, 0.31, 0.60)
const GOLD      := Color(1.00, 0.82, 0.20)
const DARK      := Color(0.22, 0.16, 0.32)

const CATEGORIES := ["decor", "tiles", "animals", "seeds", "bundles"]

const SHOP_ITEMS: Dictionary = {
	"decor": [
		{"name": "fox lantern",  "price": 120, "currency": "coin", "color": Color(1.00, 0.85, 0.45)},
		{"name": "koi tile",     "price":  80, "currency": "coin", "color": Color(0.40, 0.70, 0.85)},
		{"name": "mossy rock",   "price":  60, "currency": "coin", "color": Color(0.45, 0.62, 0.35)},
		{"name": "sakura tree",  "price":   3, "currency": "gem",  "color": Color(0.95, 0.75, 0.82)},
		{"name": "paper crane",  "price": 150, "currency": "coin", "color": Color(0.90, 0.90, 0.92)},
		{"name": "shrine gate",  "price":   5, "currency": "gem",  "color": Color(0.55, 0.42, 0.72)},
	],
	"tiles": [
		{"name": "stone path",   "price":  40, "currency": "coin", "color": Color(0.70, 0.68, 0.65)},
		{"name": "flower bed",   "price":  90, "currency": "coin", "color": Color(0.85, 0.65, 0.75)},
		{"name": "koi pond",     "price":   4, "currency": "gem",  "color": Color(0.35, 0.60, 0.80)},
		{"name": "sand garden",  "price":  55, "currency": "coin", "color": Color(0.88, 0.82, 0.68)},
		{"name": "moss tile",    "price":  70, "currency": "coin", "color": Color(0.42, 0.60, 0.36)},
		{"name": "zen tile",     "price":   6, "currency": "gem",  "color": Color(0.68, 0.58, 0.80)},
	],
	# animals category is loaded dynamically from AnimalRegistry
	"seeds": [
		{"name": "cherry blossom","price":  50, "currency": "coin", "color": Color(0.95, 0.75, 0.82)},
		{"name": "bamboo",        "price":  35, "currency": "coin", "color": Color(0.45, 0.72, 0.38)},
		{"name": "lotus",         "price":   2, "currency": "gem",  "color": Color(0.85, 0.65, 0.75)},
		{"name": "pine bonsai",   "price":  80, "currency": "coin", "color": Color(0.28, 0.48, 0.28)},
	],
	"bundles": [
		{"name": "starter pack",  "price":  10, "currency": "gem",  "color": Color(0.80, 0.65, 0.90)},
		{"name": "zen garden",    "price":  15, "currency": "gem",  "color": Color(0.45, 0.72, 0.55)},
		{"name": "shrine bundle", "price":  12, "currency": "gem",  "color": Color(0.58, 0.44, 0.78)},
		{"name": "cozy farm",     "price":  20, "currency": "gem",  "color": Color(0.85, 0.65, 0.45)},
	],
}

var _category := "decor"
var _purchased: Array[String] = []
var _buy_buttons: Dictionary = {}   # Button -> item Dictionary
var _detail_panel = null

var _tab_active:    StyleBoxFlat
var _tab_idle:      StyleBoxEmpty
var _card_normal:   StyleBoxFlat
var _card_owned:    StyleBoxFlat
var _price_coin:    StyleBoxFlat
var _price_gem:     StyleBoxFlat
var _price_disabled: StyleBoxFlat

@onready var coin_label:    Label        = $MainLayout/HeaderBar/CoinRow/CoinLabel
@onready var tab_row:       HBoxContainer = $MainLayout/CategoryTabs
@onready var section_label: Label        = $MainLayout/ShopScroll/ShopPad/ShopContent/SectionLabel
@onready var item_grid:     GridContainer = $MainLayout/ShopScroll/ShopPad/ShopContent/ItemGrid
@onready var featured:      PanelContainer = $MainLayout/ShopScroll/ShopPad/ShopContent/FeaturedBanner


func _ready() -> void:
	_build_styles()
	featured.add_theme_stylebox_override("panel", _make_sb(LILA, 18))
	_update_tabs()
	_build_grid()
	$MainLayout/HeaderBar/BackBtn.pressed.connect(_on_back_pressed)
	for i in CATEGORIES.size():
		var btn: Button = tab_row.get_child(i)
		var cat: String = CATEGORIES[i]
		btn.pressed.connect(func(): _select_category(cat))
	EventBus.coins_changed.connect(_on_coins_changed)
	_on_coins_changed(GameState.coins)
	_detail_panel = AnimalDetailPanelScene.instantiate()
	add_child(_detail_panel)
	_detail_panel.action_pressed.connect(_on_detail_action)


func _build_styles() -> void:
	_tab_active  = _make_sb(Color(0.15, 0.12, 0.20), 20)
	_tab_idle    = StyleBoxEmpty.new()
	_card_normal = _make_sb(Color(1, 1, 1, 0.78), 14)

	_card_owned = StyleBoxFlat.new()
	_card_owned.bg_color                   = Color(1, 1, 1, 0.78)
	_card_owned.corner_radius_top_left     = 14
	_card_owned.corner_radius_top_right    = 14
	_card_owned.corner_radius_bottom_left  = 14
	_card_owned.corner_radius_bottom_right = 14
	_card_owned.border_width_left   = 2
	_card_owned.border_width_right  = 2
	_card_owned.border_width_top    = 2
	_card_owned.border_width_bottom = 2
	_card_owned.border_color        = LILA

	_price_coin     = _make_sb(Color(1.00, 0.82, 0.20), 12)
	_price_gem      = _make_sb(LILA, 12)
	_price_disabled = _make_sb(Color(0.78, 0.76, 0.80), 12)


func _make_sb(color: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = color
	sb.corner_radius_top_left     = radius
	sb.corner_radius_top_right    = radius
	sb.corner_radius_bottom_left  = radius
	sb.corner_radius_bottom_right = radius
	return sb


func _select_category(cat: String) -> void:
	_category = cat
	_update_tabs()
	_build_grid()


func _update_tabs() -> void:
	for i in CATEGORIES.size():
		var btn: Button = tab_row.get_child(i)
		var active: bool = CATEGORIES[i] == _category
		btn.add_theme_stylebox_override("normal",  _tab_active if active else _tab_idle)
		btn.add_theme_stylebox_override("hover",   _tab_active if active else _tab_idle)
		btn.add_theme_stylebox_override("pressed", _tab_active if active else _tab_idle)
		btn.add_theme_color_override("font_color", Color.WHITE if active else DARK)


func _build_grid() -> void:
	_buy_buttons.clear()
	for child in item_grid.get_children():
		child.queue_free()
	section_label.text = _category
	if _category == "animals":
		for animal in AnimalRegistry.get_all():
			var item := {
				"name":       animal.id,
				"price":      animal.price,
				"currency":   "coin",
				"color":      animal.color,
				"image_path": animal.image_path,
				"is_animal":  true,
			}
			item_grid.add_child(_make_card(item))
	else:
		var items: Array = SHOP_ITEMS.get(_category, [])
		for item in items:
			item_grid.add_child(_make_card(item))


func _make_card(item: Dictionary) -> Control:
	var owned:     bool = item["name"] in _purchased
	var is_gem:    bool = item["currency"] == "gem"
	var is_animal: bool = item.get("is_animal", false)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_owned if owned else _card_normal)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	# colour preview
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left",  8)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_top",   8)
	vbox.add_child(pad)

	var image_path: String = item.get("image_path", "")
	var preview := Panel.new()
	preview.custom_minimum_size = Vector2(0, 88)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg_color: Color = Color(0.96, 0.94, 0.92) if image_path != "" else item.get("color", Color.WHITE)
	preview.add_theme_stylebox_override("panel", _make_sb(bg_color, 10))
	pad.add_child(preview)

	if image_path != "":
		var tex_rect := TextureRect.new()
		tex_rect.texture      = load(image_path)
		tex_rect.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.layout_mode  = 1
		tex_rect.anchor_right  = 1.0
		tex_rect.anchor_bottom = 1.0
		preview.add_child(tex_rect)

	# name
	var name_lbl := Label.new()
	name_lbl.text = item["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", DARK)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	vbox.add_child(name_lbl)

	# price / owned / tap-to-detail
	if is_animal:
		var btn_pad := MarginContainer.new()
		btn_pad.add_theme_constant_override("margin_left",   8)
		btn_pad.add_theme_constant_override("margin_right",  8)
		btn_pad.add_theme_constant_override("margin_bottom", 8)
		btn_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(btn_pad)

		var price_lbl := Label.new()
		price_lbl.text = "o  %d" % item["price"]
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		price_lbl.add_theme_font_size_override("font_size", 13)
		price_lbl.add_theme_color_override("font_color", Color(0.20, 0.14, 0.06))
		price_lbl.add_theme_stylebox_override("normal", _price_coin)
		price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_pad.add_child(price_lbl)

		# Whole card opens the detail panel
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(func(e: InputEvent) -> void:
			if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) \
					or (e is InputEventScreenTouch and e.pressed):
				_detail_panel.show_panel(item["name"], "shop")
		)
	else:
		var btn_pad := MarginContainer.new()
		btn_pad.add_theme_constant_override("margin_left",   8)
		btn_pad.add_theme_constant_override("margin_right",  8)
		btn_pad.add_theme_constant_override("margin_bottom", 8)
		vbox.add_child(btn_pad)

		if owned:
			var lbl := Label.new()
			lbl.text = "owned"
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.add_theme_color_override("font_color", LILA)
			btn_pad.add_child(lbl)
		else:
			var price_btn := Button.new()
			price_btn.text = ("* " if is_gem else "o ") + str(item["price"])
			price_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			price_btn.add_theme_font_size_override("font_size", 13)
			var txt_col := DARK if is_gem else Color(0.20, 0.14, 0.06)
			price_btn.add_theme_color_override("font_color", txt_col)
			var pill := _price_gem if is_gem else _price_coin
			for state in ["normal", "hover", "pressed", "focus"]:
				price_btn.add_theme_stylebox_override(state, pill)
			price_btn.add_theme_stylebox_override("disabled", _price_disabled)
			price_btn.add_theme_color_override("font_color_disabled", Color(0.50, 0.48, 0.52))
			if not is_gem:
				_buy_buttons[price_btn] = item
				price_btn.disabled = GameState.coins < item["price"]
			price_btn.pressed.connect(func(): _on_buy(item, card, btn_pad, price_btn))
			btn_pad.add_child(price_btn)

	return card


func _on_buy(item: Dictionary, card: PanelContainer,
		btn_pad: MarginContainer, price_btn: Button) -> void:
	if item["currency"] == "coin" and not GameState.spend_coins(item["price"]):
		return
	_purchased.append(item["name"])
	_buy_buttons.erase(price_btn)
	GameState.add_to_inventory(item)
	SaveSystem.save_game()
	card.add_theme_stylebox_override("panel", _card_owned)
	price_btn.queue_free()
	var lbl := Label.new()
	lbl.text = "owned"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", LILA)
	btn_pad.add_child(lbl)


func _on_coins_changed(amount: int) -> void:
	coin_label.text = str(amount)
	for btn: Button in _buy_buttons:
		var item_data: Dictionary = _buy_buttons[btn]
		btn.disabled = amount < item_data["price"]


func _on_detail_action(animal_id: String, context: String) -> void:
	if context != "shop":
		return
	var animal: AnimalData = AnimalRegistry.get_animal(animal_id)
	if not animal:
		return
	if not GameState.spend_coins(animal.price):
		return
	GameState.add_to_inventory({"name": animal_id})
	SaveSystem.save_game()
	_detail_panel.close()


func _on_back_pressed() -> void:
	queue_free()
