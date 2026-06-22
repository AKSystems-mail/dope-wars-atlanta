extends Control
## Buckhead Shop Screen
## Full dark-neon shop UI built programmatically.
## MAP button → map screen. Stats bar shows cash/day/debt.

@onready var gs: Node = get_node("/root/GameState")

const ITEMS := [
	{"name": "Blunts", "emoji": "🚬", "price": 75, "weight": 1, "key": "blunts"},
	{"name": "Shrooms", "emoji": "🍄", "price": 55, "weight": 2, "key": "shrooms"},
	{"name": "Powda", "emoji": "❄️", "price": 47, "weight": 1, "key": "powda"},
]

var cash_label: Label
var capacity_label: Label
var day_label: Label
var debt_label: Label

func _ready() -> void:
	setup_ui()
	gs.money_changed.connect(_on_money_changed)
	gs.inventory_changed.connect(_on_inventory_changed)

func setup_ui() -> void:
	# === Background ===
	var bg := ColorRect.new()
	bg.color = ThemeConst.BG_DARK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# === Top Bar (cash left, day center, cash right) ===
	var top_bar := Panel.new()
	top_bar.custom_minimum_size = Vector2(0, 44)
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = ThemeConst.BAR_BG
	top_bar.add_theme_stylebox_override("panel", top_style)
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	add_child(top_bar)

	var top_hbox := HBoxContainer.new()
	top_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_hbox.add_theme_constant_override("separation", 8)
	top_bar.add_child(top_hbox)

	# Location (dynamic from game state)
	var loc_label := Label.new()
	loc_label.text = "📍 " + gs.current_location
	loc_label.add_theme_color_override("font_color", ThemeConst.TEXT_BODY)
	loc_label.add_theme_font_size_override("font_size", 12)
	top_hbox.add_child(loc_label)

	var sp1 := Control.new()
	sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(sp1)

	# Day
	day_label = Label.new()
	day_label.text = "Day %d/%d" % [gs.day, gs.max_days]
	day_label.add_theme_color_override("font_color", ThemeConst.NEON_YELLOW)
	day_label.add_theme_font_size_override("font_size", 12)
	top_hbox.add_child(day_label)

	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(sp2)

	# Cash
	cash_label = Label.new()
	cash_label.text = "$" + _fmt_num(gs.money)
	cash_label.add_theme_color_override("font_color", ThemeConst.CASH_GREEN)
	cash_label.add_theme_font_size_override("font_size", 14)
	top_hbox.add_child(cash_label)

	# === Location Header ===
	var loc_vbox := VBoxContainer.new()
	loc_vbox.set_anchors_and_offset_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 44)
	loc_vbox.add_theme_constant_override("separation", 2)
	add_child(loc_vbox)

	var header_label := Label.new()
	header_label.text = "「 " + gs.current_location.to_upper() + " 」"
	header_label.add_theme_color_override("font_color", ThemeConst.NEON_YELLOW)
	header_label.add_theme_font_size_override("font_size", 22)
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loc_vbox.add_child(header_label)

	var loc_descs := {
		"Buckhead": "The Councilman runs this spot",
		"Midtown": "Tech money meets street hustle",
		"Cobb County": "Suburban sprawl, quiet markets",
		"West End": "Arts district — sketchy deals",
		"Little Five Points": "Counterculture capital",
		"Decatur": "Music scene, deep inventory",
	}
	var desc_label := Label.new()
	desc_label.text = loc_descs.get(gs.current_location, "Atlanta's underground market")
	desc_label.add_theme_color_override("font_color", ThemeConst.TEXT_DIM)
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loc_vbox.add_child(desc_label)

	# === Debt warning (shown when debt > 0) ===
	debt_label = Label.new()
	debt_label.add_theme_color_override("font_color", ThemeConst.RED)
	debt_label.add_theme_font_size_override("font_size", 11)
	debt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loc_vbox.add_child(debt_label)

	# === Shop Panel ===
	var shop_margin := MarginContainer.new()
	shop_margin.set_anchors_and_offset_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
	shop_margin.add_theme_constant_override("margin_left", 16)
	shop_margin.add_theme_constant_override("margin_right", 16)
	shop_margin.add_theme_constant_override("margin_top", 96)
	shop_margin.add_theme_constant_override("margin_bottom", 56)
	add_child(shop_margin)

	var shop_panel := Panel.new()
	var shop_style := StyleBoxFlat.new()
	shop_style.bg_color = ThemeConst.CARD_DARK
	shop_style.border_color = ThemeConst.NEON_GREEN
	shop_style.border_color.a = 0.3
	shop_style.set_border_width_all(1)
	shop_panel.add_theme_stylebox_override("panel", shop_style)
	shop_margin.add_child(shop_panel)

	var shop_vbox := VBoxContainer.new()
	shop_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_vbox.add_theme_constant_override("separation", 0)
	shop_panel.add_child(shop_vbox)

	# --- Shop Header ---
	var shop_header := Label.new()
	shop_header.text = "✦  S H O P  ✦"
	shop_header.add_theme_color_override("font_color", ThemeConst.NEON_GREEN)
	shop_header.add_theme_font_size_override("font_size", 15)
	shop_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_header.custom_minimum_size = Vector2(0, 32)
	shop_vbox.add_child(shop_header)

	# --- Councilman row ---
	var council_row := HBoxContainer.new()
	council_row.custom_minimum_size = Vector2(0, 36)
	council_row.add_theme_constant_override("separation", 8)
	shop_vbox.add_child(council_row)

	var council_bg := ColorRect.new()
	council_bg.color = ThemeConst.CARD_INNER
	council_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	council_row.add_child(council_bg)

	var c_icon := Label.new()
	c_icon.text = "🤵"
	c_icon.add_theme_font_size_override("font_size", 16)
	council_row.add_child(c_icon)

	var c_name := Label.new()
	c_name.text = "Councilman"
	c_name.add_theme_color_override("font_color", ThemeConst.TEXT_BODY)
	c_name.add_theme_font_size_override("font_size", 13)
	c_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	council_row.add_child(c_name)

	var c_arrow := Label.new()
	c_arrow.text = "→"
	c_arrow.add_theme_color_override("font_color", ThemeConst.NEON_GREEN)
	c_arrow.add_theme_font_size_override("font_size", 14)
	council_row.add_child(c_arrow)

	council_row.add_child(_divider())

	# --- Items ---
	for item in ITEMS:
		shop_vbox.add_child(_build_item_row(item))
		shop_vbox.add_child(_divider())

	# --- Bottom section (cash + capacity) ---
	var bottom_row := HBoxContainer.new()
	bottom_row.custom_minimum_size = Vector2(0, 36)
	bottom_row.add_theme_constant_override("separation", 8)
	shop_vbox.add_child(bottom_row)

	var cash_t := Label.new()
	cash_t.text = "Cash"
	cash_t.add_theme_color_override("font_color", ThemeConst.TEXT_DIM)
	cash_t.add_theme_font_size_override("font_size", 12)
	bottom_row.add_child(cash_t)

	var c_spacer := Control.new()
	c_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(c_spacer)

	capacity_label = Label.new()
	capacity_label.text = "Buy: %d/%d" % [0, 100]
	capacity_label.add_theme_color_override("font_color", ThemeConst.TEXT_DIM)
	capacity_label.add_theme_font_size_override("font_size", 12)
	bottom_row.add_child(capacity_label)

	# === Bottom Nav ===
	_build_nav_bar()

	_refresh_stats()

func _build_item_row(item: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 40)
	row.add_theme_constant_override("separation", 6)

	var emoji := Label.new()
	emoji.text = item.emoji
	emoji.add_theme_font_size_override("font_size", 18)
	emoji.custom_minimum_size = Vector2(30, 0)
	row.add_child(emoji)

	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 1)
	row.add_child(info_vbox)

	var name_lbl := Label.new()
	name_lbl.text = item.name
	name_lbl.add_theme_color_override("font_color", ThemeConst.TEXT_BODY)
	name_lbl.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(name_lbl)

	var price_lbl := Label.new()
	var actual_price := _get_price(item)
	price_lbl.text = "$%d" % actual_price
	price_lbl.add_theme_color_override("font_color", ThemeConst.TEXT_DIM)
	price_lbl.add_theme_font_size_override("font_size", 11)
	info_vbox.add_child(price_lbl)

	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 2)
	row.add_child(btn_vbox)

	btn_vbox.add_child(_make_button("BUY", ThemeConst.NEON_GREEN, func():
		_on_buy(item.key, actual_price, item.weight)))

	btn_vbox.add_child(_make_button("SELL", ThemeConst.NEON_PINK, func():
		_on_sell(item.key, price_lbl)))

	return row

func _get_price(item: Dictionary) -> int:
	var base: int = item.price
	if gs.has_method("get_price_mod"):
		return int(base * gs.get_price_mod())
	return base

func _make_button(text: String, color: Color, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(60, 18)

	var normal := StyleBoxFlat.new()
	normal.bg_color = ThemeConst.BAR_BG
	normal.border_color = color
	normal.border_color.a = 0.6
	normal.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = ThemeConst.CARD_INNER
	hover.border_color = color
	hover.border_color.a = 1.0
	hover.set_border_width_all(1.5)
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 10)
	btn.pressed.connect(callback)
	return btn

func _build_nav_bar() -> void:
	var nav := Panel.new()
	nav.custom_minimum_size = Vector2(0, 52)
	var nav_style := StyleBoxFlat.new()
	nav_style.bg_color = ThemeConst.BAR_BG
	nav.add_theme_stylebox_override("panel", nav_style)
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	add_child(nav)

	var nav_hbox := HBoxContainer.new()
	nav_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	nav_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_hbox.add_theme_constant_override("separation", 12)
	nav.add_child(nav_hbox)

	nav_hbox.add_child(_nav_btn("💰 BUY", ThemeConst.NEON_GREEN, 1.0))

	var map_btn := _nav_btn("🗺️ MAP", ThemeConst.NEON_PURPLE, 1.0)
	map_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/map/map_screen.tscn"))
	nav_hbox.add_child(map_btn)

	nav_hbox.add_child(_nav_btn("🎒 INVENTORY", ThemeConst.NEON_YELLOW, 0.4))

func _nav_btn(text: String, color: Color, alpha: float) -> Button:
	var btn := Button.new()
	btn.text = text
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeConst.CARD_INNER
	style.border_color = color
	style.border_color.a = alpha
	style.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 11)
	return btn

func _divider() -> ColorRect:
	var line := ColorRect.new()
	line.color = ThemeConst.BORDER_DIM
	line.custom_minimum_size = Vector2(0, 1)
	return line

func _on_buy(key: String, price: int, weight: int) -> void:
	var total_weight: int = gs.get_current_weight()
	var owned: int = gs.inventory.get(key, {}).get("qty", 0)

	if gs.money < price:
		_show_flash("Not enough cash!")
		return
	if total_weight + weight > gs.capacity:
		_show_flash("No space!")
		return

	gs.money -= price
	gs.inventory[key] = {"qty": owned + 1, "weight": weight}
	gs.inventory = gs.inventory  # trigger setter

func _on_sell(key: String, price_label: Label) -> void:
	var owned: int = gs.inventory.get(key, {}).get("qty", 0)
	if owned <= 0:
		_show_flash("None to sell!")
		return

	var actual_price := int(price_label.text.trim_prefix("$"))
	var sell_price := actual_price / 2
	gs.money += sell_price
	if owned == 1:
		gs.inventory.erase(key)
	else:
		gs.inventory[key] = {"qty": owned - 1, "weight": gs.inventory[key].weight}
	gs.inventory = gs.inventory  # trigger setter

func _show_flash(text: String) -> void:
	print(text)
	var flash := Label.new()
	flash.text = text
	flash.add_theme_color_override("font_color", ThemeConst.RED)
	flash.add_theme_font_size_override("font_size", 16)
	flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flash.set_anchors_preset(Control.PRESET_CENTER)
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 1.2)
	tween.tween_callback(flash.queue_free)

func _on_money_changed(v: int) -> void:
	_refresh_stats()

func _on_inventory_changed(_items: Dictionary) -> void:
	var w: int = gs.get_current_weight()
	if capacity_label:
		capacity_label.text = "Buy: %d/%d" % [w, gs.capacity]

func _refresh_stats() -> void:
	if cash_label:
		cash_label.text = "$" + _fmt_num(gs.money)
	if day_label:
		day_label.text = "Day %d/%d" % [gs.day, gs.max_days]
	if debt_label:
		var debt := 0
		if gs.has_method("get_debt"):
			debt = gs.get_debt()
		debt_label.text = "⚠️ Debt: $%d (2%% daily interest)" % debt if debt > 0 else ""

static func _fmt_num(n: int) -> String:
	var s := str(n)
	var result := ""
	for i in range(s.length(), 0, -1):
		if (s.length() - i) % 3 == 0 and i != s.length():
			result = "," + result
		result = s[i-1] + result
	return result
