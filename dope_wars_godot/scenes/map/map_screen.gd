extends Control
## Dope Wars Atlanta — Map Screen
## Canonical 1000x1000 coordinate space from the Flutter pixel map.
## All connection/location data loaded from GameState singleton.

@onready var gs: Node = get_node("/root/GameState")

var _pulse_time: float = 0.0

# Map-to-screen transform
const WORLD_CENTER := Vector2(508, 390)
const SCREEN_CENTER := Vector2(270, 500)
const SCALE: float = 0.77
const DOT_RADIUS: float = 18.0

# UI elements
var _day_label: Label
var _cash_label: Label
var _location_label: Label
var _info_label: Label

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = ThemeConst.BG_DARK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# === Top Bar (44px) ===
	var top_bar := ColorRect.new()
	top_bar.color = ThemeConst.BAR_BG
	top_bar.size = Vector2(540, 44)
	add_child(top_bar)

	var top_hbox := HBoxContainer.new()
	top_hbox.position = Vector2(12, 0)
	top_hbox.size = Vector2(516, 44)
	add_child(top_hbox)

	_location_label = Label.new()
	_location_label.text = "📍 " + gs.current_location
	_location_label.add_theme_color_override("font_color", ThemeConst.NEON_GREEN)
	_location_label.add_theme_font_size_override("font_size", 13)
	top_hbox.add_child(_location_label)

	var sp1 := Control.new()
	sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(sp1)

	_day_label = Label.new()
	_day_label.text = "Day %d/%d" % [gs.day, gs.max_days]
	_day_label.add_theme_color_override("font_color", ThemeConst.NEON_YELLOW)
	_day_label.add_theme_font_size_override("font_size", 11)
	top_hbox.add_child(_day_label)

	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(sp2)

	_cash_label = Label.new()
	_cash_label.text = "$" + _fmt_num(gs.money)
	_cash_label.add_theme_color_override("font_color", ThemeConst.NEON_GREEN)
	_cash_label.add_theme_font_size_override("font_size", 14)
	top_hbox.add_child(_cash_label)

	# === Info label (bottom area) ===
	_info_label = Label.new()
	_info_label.add_theme_color_override("font_color", ThemeConst.TEXT_DIM)
	_info_label.add_theme_font_size_override("font_size", 11)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.position = Vector2(0, 916)
	_info_label.size = Vector2(540, 20)
	_info_label.text = "Tap a connected location to travel"
	add_child(_info_label)

	# === Bottom Nav (52px) ===
	_build_nav_bar()

func _build_nav_bar() -> void:
	var nav := ColorRect.new()
	nav.color = ThemeConst.BAR_BG
	nav.position = Vector2(0, 908)
	nav.size = Vector2(540, 52)
	add_child(nav)

	var nav_hbox := HBoxContainer.new()
	nav_hbox.position = Vector2(0, 908)
	nav_hbox.size = Vector2(540, 52)
	nav_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_hbox.add_theme_constant_override("separation", 20)
	add_child(nav_hbox)

	var buy_btn := _nav_btn("💰 BUY")
	buy_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/shop/shop.tscn"))
	nav_hbox.add_child(buy_btn)
	nav_hbox.add_child(_nav_btn("🗺️  MAP"))
	nav_hbox.add_child(_stub_btn("🎒 INVENTORY"))

func _nav_btn(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeConst.CARD_INNER
	style.border_color = ThemeConst.NEON_GREEN
	style.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", ThemeConst.NEON_GREEN)
	btn.add_theme_font_size_override("font_size", 12)
	return btn

func _stub_btn(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeConst.CARD_INNER
	style.border_color = ThemeConst.TEXT_DIM
	style.border_color.a = 0.3
	style.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", ThemeConst.TEXT_DIM)
	btn.add_theme_font_size_override("font_size", 12)
	btn.disabled = true
	return btn

func _process(delta: float) -> void:
	_pulse_time += delta
	queue_redraw()

func _draw() -> void:
	_draw_grid()
	_draw_connection_lines()
	_draw_location_dots()

func _world_to_screen(world_pos: Vector2) -> Vector2:
	return SCREEN_CENTER + (world_pos - WORLD_CENTER) * SCALE

func _draw_grid() -> void:
	var grid_color := ThemeConst.CARD_DARK
	grid_color.a = 0.1
	for row in range(0, 1001, 50):
		var p1 := _world_to_screen(Vector2(0, row))
		var p2 := _world_to_screen(Vector2(1000, row))
		if p1.y < 44 or p1.y > 908:
			continue
		draw_line(p1, p2, grid_color, 0.5)
	for col in range(0, 1001, 50):
		var p1 := _world_to_screen(Vector2(col, 0))
		var p2 := _world_to_screen(Vector2(col, 1000))
		if p1.x < 0 or p1.x > 540:
			continue
		draw_line(p1, p2, grid_color, 0.5)

func _draw_connection_lines() -> void:
	var current: String = gs.current_location
	var conns: Array = gs.get_connections(current)
	
	for loc_name in gs.LOCATIONS:
		var from_scr: Vector2 = _world_to_screen(gs.LOCATIONS[loc_name].coords)
		for neighbor in gs.get_connections(loc_name):
			if loc_name > neighbor:
				continue  # draw each edge once
			var to_scr: Vector2 = _world_to_screen(gs.LOCATIONS[neighbor].coords)
			var connected: bool = (loc_name == current and neighbor in conns) or \
				(neighbor == current and loc_name in conns)
			
			var line_color := ThemeConst.NEON_GREEN if connected else ThemeConst.BORDER_DIM
			line_color.a = 0.4 if connected else 0.2
			draw_line(from_scr, to_scr, line_color, 1.5 if connected else 1.0)

func _draw_location_dots() -> void:
	var current: String = gs.current_location
	var conns: Array = gs.get_connections(current)
	
	for loc_name in gs.LOCATIONS:
		var is_current: bool = loc_name == current
		var is_linked: bool = loc_name in conns
		var scr_pos := _world_to_screen(gs.LOCATIONS[loc_name].coords)
		var accent: Color = gs.LOC_ACCENTS.get(loc_name, Color("#ffffff"))
		
		if scr_pos.x < -30 or scr_pos.x > 570 or scr_pos.y < 14 or scr_pos.y > 938:
			continue
		
		# Sizing
		var outer_r: float = 18.0 if is_current else (16.0 if is_linked else 11.0)
		var inner_r: float = 7.0 if is_current else (5.0 if is_linked else 3.0)
		
		# Glow circle (current location only — pulsing)
		if is_current:
			var pr := 22.0 + sin(_pulse_time * 3.0) * 4.0
			var glow_color := accent
			glow_color.a = 0.15 - sin(_pulse_time * 3.0) * 0.05
			draw_circle(scr_pos, pr, glow_color)
			# Ring (stroke simulation via layered circles)
			var ring_color := accent
			ring_color.a = 0.3 + sin(_pulse_time * 3.0) * 0.15
			draw_circle(scr_pos, pr, ring_color)
			# Re-draw fill over center to create ring effect
			var fill_over := Color("#0f0b1a")
			fill_over.a = 1.0
			draw_circle(scr_pos, pr - 2.0, fill_over)
		
		# Border ring (stroke simulation via layered circles)
		var stroke_color := accent
		stroke_color.a = 1.0 if is_current else (0.8 if is_connected else 0.3)
		draw_circle(scr_pos, outer_r, stroke_color)
		
		# Inner fill
		var fill_color := accent
		fill_color.a = 0.25 if is_current else (0.20 if is_connected else 0.10)
		draw_circle(scr_pos, outer_r - 2.0, fill_color)
		
		# Inner dot
		var dot_color: Color = Color("ccffdd") if is_current else accent
		if not is_current and not is_linked:
			dot_color.a = 0.4
		draw_circle(scr_pos, inner_r, dot_color)
		
		# Label
		var label_color: Color = Color("ffffff") if is_current else (accent if is_linked else Color("606070"))
		var font_size: int = 12 if is_current else (11 if is_linked else 10)
		var label_pos := Vector2(scr_pos.x, scr_pos.y + outer_r + 14.0)
		var label_w: float = loc_name.length() * (font_size * 0.6 + 2.0)
		
		var bg_color := Color("#0f0b1a")
		bg_color.a = 0.75
		draw_rect(Rect2(label_pos.x - label_w / 2 - 4, label_pos.y - 2, label_w + 8, font_size + 6), bg_color)
		draw_string(ThemeDB.fallback_font, label_pos + Vector2(-label_w / 2, font_size + 2),
			loc_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		var pos: Vector2 = event.position
		for loc_name in gs.LOCATIONS:
			var scr_pos := _world_to_screen(gs.LOCATIONS[loc_name].coords)
			if pos.distance_to(scr_pos) <= DOT_RADIUS:
				_on_loc_tap(loc_name)
				return

func _on_loc_tap(loc_name: String) -> void:
	var current: String = gs.current_location
	
	if loc_name == current:
		_info_label.text = "📍 You are here"
		return
	
	if not gs.travel_to(loc_name):
		_info_label.text = "🚫 No route to " + loc_name
		return
	
	# Update UI
	_location_label.text = "📍 " + loc_name
	_day_label.text = "Day %d/%d" % [gs.day, gs.max_days]
	_cash_label.text = "$" + _fmt_num(gs.money)
	
	if gs.get_debt() > 0:
		_info_label.text = "📍 Arrived. Debt: $%d" % gs.get_debt()
	else:
		_info_label.text = "📍 Arrived at " + loc_name

static func _fmt_num(n: int) -> String:
	var s := str(n)
	var result := ""
	for i in range(s.length(), 0, -1):
		if (s.length() - i) % 3 == 0 and i != s.length():
			result = "," + result
		result = s[i-1] + result
	return result
